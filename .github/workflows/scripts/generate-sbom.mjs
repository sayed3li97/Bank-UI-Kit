#!/usr/bin/env node
// Deterministic SBOM generator for the bank_ui_kit Dart/Flutter package.
//
// Why this lives here and not in `tool/`: it is a CI-only script with no
// runtime relationship to the published package, and keeping it beside the
// workflow that runs it means the SBOM logic and its invocation are reviewed
// together. GitHub only scans `.github/workflows/*.yml`, so nothing in this
// `scripts/` subdirectory is interpreted as a workflow.
//
// Why hand-rolled rather than Syft/CycloneDX-CLI: the Dart ecosystem's
// authoritative resolution record is `pubspec.lock`, which carries the
// SHA-256 archive digest of every hosted package. Generic scanners either
// miss it or emit a fresh UUID and wall-clock timestamp per run, which makes
// two SBOMs of the same commit differ. Every value written here is derived
// from the inputs, so the same commit plus the same resolution always
// produces byte-identical output.
//
// Inputs
//   --deps      <path>  `flutter pub deps --json` output (dependency graph)
//   --lock      <path>  pubspec.lock (exact versions + SHA-256 digests)
//   --pubspec   <path>  pubspec.yaml (root package identity)
//   --out       <dir>   output directory
//   --repo-url  <url>   canonical repository URL, e.g. https://github.com/o/r
//   --commit    <sha>   full commit SHA the SBOM describes
//   --created   <iso>   RFC 3339 timestamp; use the commit's committer date
//                       so the document is not a function of wall-clock time
//   --license   <id>    optional SPDX licence identifier for the root package;
//                       omitted means NOASSERTION
//
// Outputs (in --out)
//   <name>-<version>.spdx.json   SPDX 2.3   (ISO/IEC 5962:2021)
//   <name>-<version>.cdx.json    CycloneDX 1.6

import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const GENERATOR_NAME = 'bank-ui-kit-sbom-generator';
const GENERATOR_VERSION = '1.0.0';

// ---------------------------------------------------------------------------
// Argument handling
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const eq = token.indexOf('=');
    if (eq !== -1) {
      args[token.slice(2, eq)] = token.slice(eq + 1);
    } else {
      args[token.slice(2)] = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));
for (const required of ['deps', 'lock', 'pubspec', 'out', 'repo-url', 'commit', 'created']) {
  if (!args[required]) {
    console.error(`generate-sbom: missing required argument --${required}`);
    process.exit(2);
  }
}

// ---------------------------------------------------------------------------
// Minimal YAML readers
//
// Both files are machine-written by pub with fixed two-space indentation and
// a closed set of keys, so a targeted reader is more predictable here than a
// vendored YAML parser would be — and it keeps this script dependency-free,
// which is the point of a supply-chain artifact.
// ---------------------------------------------------------------------------

function unquote(value) {
  const trimmed = value.trim();
  if (trimmed.length >= 2) {
    const first = trimmed[0];
    const last = trimmed[trimmed.length - 1];
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      return trimmed.slice(1, -1);
    }
  }
  return trimmed;
}

/// Reads the top-level scalar keys of pubspec.yaml (name, version, ...).
function readPubspec(path) {
  const fields = {};
  for (const raw of readFileSync(path, 'utf8').split(/\r?\n/)) {
    if (!raw || raw.startsWith('#') || /^\s/.test(raw)) continue;
    const match = raw.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (match && match[2].trim() !== '') fields[match[1]] = unquote(match[2]);
  }
  return fields;
}

/// Reads `packages:` and `sdks:` out of pubspec.lock.
///
/// Each package yields `{ dependency, source, version, sha256, url, ... }`.
/// `description` is a map for hosted and git sources and a bare scalar for
/// SDK sources, so both shapes are handled.
function readLock(path) {
  const packages = new Map();
  const sdks = new Map();
  let section = null;
  let current = null;
  let inDescription = false;

  for (const raw of readFileSync(path, 'utf8').split(/\r?\n/)) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    const indent = raw.length - raw.trimStart().length;
    const line = raw.trim();

    if (indent === 0) {
      section = line.replace(/:.*$/, '');
      current = null;
      inDescription = false;
      continue;
    }

    if (section === 'sdks' && indent === 2) {
      const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
      if (match) sdks.set(match[1], unquote(match[2]));
      continue;
    }

    if (section !== 'packages') continue;

    if (indent === 2) {
      current = line.replace(/:$/, '');
      packages.set(current, { name: current, dependency: '', source: '', version: '' });
      inDescription = false;
      continue;
    }

    if (!current) continue;
    const entry = packages.get(current);
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) continue;
    const key = match[1];
    const value = unquote(match[2]);

    if (indent === 4) {
      inDescription = key === 'description' && value === '';
      if (key === 'description' && value !== '') entry.descriptionScalar = value;
      else if (key !== 'description') entry[key] = value;
      continue;
    }

    if (indent === 6 && inDescription) {
      if (key === 'name') entry.hostedName = value;
      else if (key === 'resolved-ref') entry.resolvedRef = value;
      else entry[key] = value;
    }
  }

  return { packages, sdks };
}

// ---------------------------------------------------------------------------
// Dependency graph
// ---------------------------------------------------------------------------

/// Splits the resolved closure into runtime-reachable and development-only.
///
/// `pub deps --json` labels only *direct* dev dependencies with kind `dev`;
/// a package pulled in solely by a dev dependency is labelled `transitive`
/// and is indistinguishable from a runtime one without walking the graph.
/// Bank reviewers care about exactly that split, so it is computed here by a
/// breadth-first walk from the root's runtime dependencies.
function classify(deps) {
  const byName = new Map();
  let root = null;
  for (const pkg of deps.packages ?? []) {
    byName.set(pkg.name, pkg);
    if (pkg.kind === 'root') root = pkg;
  }
  if (!root) return { runtime: new Set(), edges: new Map(), devDirect: new Set(), root: null };

  const devDirect = new Set(root.devDependencies ?? []);
  const runtimeSeeds =
    root.directDependencies ?? (root.dependencies ?? []).filter((n) => !devDirect.has(n));

  const edges = new Map();
  for (const pkg of deps.packages ?? []) {
    const out = pkg.kind === 'root' ? (pkg.directDependencies ?? pkg.dependencies) : pkg.dependencies;
    edges.set(pkg.name, [...new Set(out ?? [])].sort());
  }

  const runtime = new Set();
  const queue = [...runtimeSeeds];
  while (queue.length > 0) {
    const name = queue.shift();
    if (runtime.has(name)) continue;
    runtime.add(name);
    for (const next of edges.get(name) ?? []) queue.push(next);
  }

  return { runtime, edges, devDirect, root: root.name };
}

// ---------------------------------------------------------------------------
// Identity helpers
// ---------------------------------------------------------------------------

/// SPDX element IDs allow only letters, digits, `.` and `-`, which excludes
/// the underscores that are idiomatic in Dart package names. Collisions after
/// substitution are resolved with a numeric suffix so IDs stay unique.
function spdxIdFactory() {
  const used = new Set();
  return (name, version) => {
    const base = `SPDXRef-Package-${`${name}-${version}`.replace(/[^A-Za-z0-9.-]/g, '-')}`;
    if (!used.has(base)) {
      used.add(base);
      return base;
    }
    for (let i = 2; ; i += 1) {
      const candidate = `${base}-${i}`;
      if (!used.has(candidate)) {
        used.add(candidate);
        return candidate;
      }
    }
  };
}

function purlFor(entry) {
  if (entry.source !== 'hosted') return null;
  const name = entry.hostedName ?? entry.name;
  const base = `pkg:pub/${encodeURIComponent(name)}@${encodeURIComponent(entry.version)}`;
  const url = entry.url ?? 'https://pub.dev';
  return url === 'https://pub.dev' ? base : `${base}?repository_url=${encodeURIComponent(url)}`;
}

function downloadLocationFor(entry) {
  if (entry.source === 'hosted') {
    const name = entry.hostedName ?? entry.name;
    const url = (entry.url ?? 'https://pub.dev').replace(/\/+$/, '');
    return `${url}/api/archives/${name}-${entry.version}.tar.gz`;
  }
  if (entry.source === 'git' && entry.url) {
    return entry.resolvedRef ? `git+${entry.url}@${entry.resolvedRef}` : `git+${entry.url}`;
  }
  return 'NOASSERTION';
}

/// A UUID derived from the document namespace rather than randomly generated,
/// so re-running the build does not change the CycloneDX serial number.
function deterministicUuid(seed) {
  const hex = createHash('sha256').update(seed).digest('hex');
  const bytes = hex.slice(0, 32).split('');
  bytes[12] = '5'; // version 5-shaped: name-based
  bytes[16] = '8'; // RFC 4122 variant
  const v = bytes.join('');
  return `${v.slice(0, 8)}-${v.slice(8, 12)}-${v.slice(12, 16)}-${v.slice(16, 20)}-${v.slice(20, 32)}`;
}

// ---------------------------------------------------------------------------
// Build the package list
// ---------------------------------------------------------------------------

const pubspec = readPubspec(args.pubspec);
const lock = readLock(args.lock);
let deps = { packages: [] };
try {
  // The Flutter wrapper can prepend first-run notices to pub's stdout, so
  // start reading at the opening brace rather than at byte zero.
  const raw = readFileSync(args.deps, 'utf8');
  const start = raw.indexOf('{');
  if (start === -1) throw new Error('no JSON object found');
  deps = JSON.parse(raw.slice(start));
} catch (error) {
  // Enrichment only. Losing the graph costs the DEPENDS_ON relationships and
  // the runtime/dev split, not the inventory itself, so a shape change in a
  // future SDK degrades the SBOM instead of failing the build.
  console.error(`generate-sbom: could not read the dependency graph (${error.message}); ` +
    'falling back to a flat inventory from pubspec.lock.');
}

const graph = classify(deps);
const rootName = pubspec.name ?? graph.root ?? 'unknown';
const rootVersion = pubspec.version ?? '0.0.0';

const entries = [...lock.packages.values()]
  .map((entry) => ({
    ...entry,
    scope: graph.runtime.size === 0 || graph.runtime.has(entry.name) ? 'runtime' : 'development',
    direct: /^direct/.test(entry.dependency ?? ''),
  }))
  .sort((a, b) => a.name.localeCompare(b.name, 'en') || a.version.localeCompare(b.version, 'en'));

const nextSpdxId = spdxIdFactory();
const rootSpdxId = nextSpdxId(rootName, rootVersion);
const spdxIds = new Map([[rootName, rootSpdxId]]);
for (const entry of entries) spdxIds.set(entry.name, nextSpdxId(entry.name, entry.version));

const rootPurl = `pkg:pub/${encodeURIComponent(rootName)}@${encodeURIComponent(rootVersion)}`;
const bomRefs = new Map([[rootName, rootPurl]]);
for (const entry of entries) {
  bomRefs.set(entry.name, purlFor(entry) ?? `pkg:generic/${entry.name}@${entry.version || '0.0.0'}`);
}

const repoUrl = args['repo-url'].replace(/\/+$/, '');
const namespace = `${repoUrl}/sbom/${rootName}/${rootVersion}/${args.commit}`;
const rootLicense = args.license && args.license !== '' ? args.license : null;

// ---------------------------------------------------------------------------
// SPDX 2.3
// ---------------------------------------------------------------------------

const sdkNote = [...lock.sdks.entries()]
  .sort(([a], [b]) => a.localeCompare(b, 'en'))
  .map(([name, constraint]) => `${name} ${constraint}`)
  .join(', ');

function spdxPackage(entry) {
  const purl = purlFor(entry);
  const pkg = {
    SPDXID: spdxIds.get(entry.name),
    name: entry.name,
    versionInfo: entry.version || 'NOASSERTION',
    downloadLocation: downloadLocationFor(entry),
    filesAnalyzed: false,
    supplier: entry.source === 'sdk' ? 'Organization: Google LLC (Flutter SDK)' : 'NOASSERTION',
    originator: 'NOASSERTION',
    // The generator reads no LICENSE files, so asserting a licence here would
    // be a guess. Per-package licence metadata is published on pub.dev; see
    // doc/enterprise/supply-chain.md for why this is deliberately empty.
    licenseConcluded: 'NOASSERTION',
    licenseDeclared: 'NOASSERTION',
    copyrightText: 'NOASSERTION',
    primaryPackagePurpose: 'LIBRARY',
  };
  if (entry.sha256) {
    pkg.checksums = [{ algorithm: 'SHA256', checksumValue: entry.sha256 }];
  }
  if (purl) {
    pkg.externalRefs = [
      { referenceCategory: 'PACKAGE-MANAGER', referenceType: 'purl', referenceLocator: purl },
    ];
  }
  pkg.comment =
    `pub source: ${entry.source || 'unknown'}; resolution: ${entry.dependency || 'unknown'}; ` +
    `scope: ${entry.scope}`;
  return pkg;
}

const spdxRelationships = [
  { spdxElementId: 'SPDXRef-DOCUMENT', relationshipType: 'DESCRIBES', relatedSpdxElement: rootSpdxId },
];
for (const [from, targets] of [...graph.edges.entries()].sort(([a], [b]) => a.localeCompare(b, 'en'))) {
  const fromId = spdxIds.get(from);
  if (!fromId) continue;
  for (const to of targets) {
    const toId = spdxIds.get(to);
    if (!toId) continue;
    spdxRelationships.push({
      spdxElementId: fromId,
      relationshipType: 'DEPENDS_ON',
      relatedSpdxElement: toId,
    });
  }
}
for (const name of [...graph.devDirect].sort((a, b) => a.localeCompare(b, 'en'))) {
  const id = spdxIds.get(name);
  if (id) {
    spdxRelationships.push({
      spdxElementId: id,
      relationshipType: 'DEV_DEPENDENCY_OF',
      relatedSpdxElement: rootSpdxId,
    });
  }
}

const spdx = {
  spdxVersion: 'SPDX-2.3',
  dataLicense: 'CC0-1.0',
  SPDXID: 'SPDXRef-DOCUMENT',
  name: `${rootName}-${rootVersion}`,
  documentNamespace: namespace,
  creationInfo: {
    created: args.created,
    creators: [`Tool: ${GENERATOR_NAME}-${GENERATOR_VERSION}`],
    comment:
      `Resolved dependency closure of ${rootName} ${rootVersion} at commit ${args.commit}. ` +
      `SDK constraints: ${sdkNote || 'unspecified'}. Licence fields are NOASSERTION by design: ` +
      'this generator does not inspect package LICENSE files.',
  },
  documentDescribes: [rootSpdxId],
  packages: [
    {
      SPDXID: rootSpdxId,
      name: rootName,
      versionInfo: rootVersion,
      downloadLocation: `${repoUrl}.git`,
      filesAnalyzed: false,
      supplier: 'NOASSERTION',
      originator: 'NOASSERTION',
      licenseConcluded: 'NOASSERTION',
      licenseDeclared: rootLicense ?? 'NOASSERTION',
      copyrightText: 'NOASSERTION',
      primaryPackagePurpose: 'LIBRARY',
      homepage: pubspec.homepage ?? repoUrl,
      description: pubspec.description ?? '',
      sourceInfo: `Built from ${repoUrl} at commit ${args.commit}.`,
      externalRefs: [
        { referenceCategory: 'PACKAGE-MANAGER', referenceType: 'purl', referenceLocator: rootPurl },
      ],
    },
    ...entries.map(spdxPackage),
  ],
  relationships: spdxRelationships,
};

// ---------------------------------------------------------------------------
// CycloneDX 1.6
// ---------------------------------------------------------------------------

function cdxComponent(entry) {
  const purl = purlFor(entry);
  const component = {
    type: 'library',
    'bom-ref': bomRefs.get(entry.name),
    name: entry.name,
    version: entry.version || '0.0.0',
    // CycloneDX has no "development" scope; `excluded` is the conventional
    // marker for a component that is not part of the shipped artifact.
    scope: entry.scope === 'runtime' ? 'required' : 'excluded',
  };
  if (purl) component.purl = purl;
  if (entry.sha256) component.hashes = [{ alg: 'SHA-256', content: entry.sha256 }];
  const download = downloadLocationFor(entry);
  if (download !== 'NOASSERTION') {
    component.externalReferences = [{ type: 'distribution', url: download }];
  }
  component.properties = [
    { name: 'pub:source', value: entry.source || 'unknown' },
    { name: 'pub:dependency', value: entry.dependency || 'unknown' },
  ];
  return component;
}

const cdxDependencies = [];
const allNames = new Set([rootName, ...entries.map((e) => e.name)]);
for (const name of [...allNames].sort((a, b) => a.localeCompare(b, 'en'))) {
  const dependsOn = (graph.edges.get(name) ?? [])
    .filter((target) => bomRefs.has(target))
    .map((target) => bomRefs.get(target))
    .sort((a, b) => a.localeCompare(b, 'en'));
  cdxDependencies.push({ ref: bomRefs.get(name), dependsOn });
}

const cyclonedx = {
  bomFormat: 'CycloneDX',
  specVersion: '1.6',
  serialNumber: `urn:uuid:${deterministicUuid(namespace)}`,
  version: 1,
  metadata: {
    timestamp: args.created,
    tools: {
      components: [
        { type: 'application', name: GENERATOR_NAME, version: GENERATOR_VERSION },
      ],
    },
    component: {
      type: 'library',
      'bom-ref': rootPurl,
      name: rootName,
      version: rootVersion,
      purl: rootPurl,
      description: pubspec.description ?? '',
      ...(rootLicense ? { licenses: [{ license: { id: rootLicense } }] } : {}),
      externalReferences: [
        { type: 'vcs', url: `${repoUrl}.git` },
        { type: 'website', url: pubspec.homepage ?? repoUrl },
      ],
    },
    properties: [
      { name: 'bank_ui_kit:commit', value: args.commit },
      { name: 'bank_ui_kit:sdk-constraints', value: sdkNote },
    ],
  },
  components: entries.map(cdxComponent),
  dependencies: cdxDependencies,
};

// ---------------------------------------------------------------------------
// Emit
// ---------------------------------------------------------------------------

mkdirSync(args.out, { recursive: true });
const spdxFile = `${rootName}-${rootVersion}.spdx.json`;
const cdxFile = `${rootName}-${rootVersion}.cdx.json`;
writeFileSync(join(args.out, spdxFile), `${JSON.stringify(spdx, null, 2)}\n`, 'utf8');
writeFileSync(join(args.out, cdxFile), `${JSON.stringify(cyclonedx, null, 2)}\n`, 'utf8');

const runtimeCount = entries.filter((e) => e.scope === 'runtime').length;
const directCount = entries.filter((e) => e.direct).length;
console.log(`### SBOM for \`${rootName}\` ${rootVersion}`);
console.log('');
console.log('| Metric | Value |');
console.log('| --- | --- |');
console.log(`| Commit | \`${args.commit}\` |`);
console.log(`| Resolved packages | ${entries.length} |`);
console.log(`| Runtime-reachable | ${runtimeCount} |`);
console.log(`| Development-only | ${entries.length - runtimeCount} |`);
console.log(`| Direct dependencies | ${directCount} |`);
console.log(`| SPDX 2.3 | \`${spdxFile}\` |`);
console.log(`| CycloneDX 1.6 | \`${cdxFile}\` |`);
