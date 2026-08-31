#!/usr/bin/env node
// Checks the package's own SBOM against the OSV.dev vulnerability database.
//
// Why it reads the SBOM rather than pubspec.lock: the inventory a bank
// reviews and the inventory this scan covers must be the same list, or the
// SBOM stops being evidence of anything. Feeding the generated CycloneDX
// document back in makes that identity structural — if a component is
// missing from the SBOM it is also missing from the scan, and the counts in
// both job summaries disagree visibly.
//
// Dependency-free on purpose. A tool that exists to police the dependency
// closure should not enlarge it, and OSV's batch endpoint is a plain POST.
//
// Inputs
//   --sbom     <path>  CycloneDX 1.6 document from generate-sbom.mjs
//   --out      <path>  where to write the machine-readable JSON report
//   --fail-on  <mode>  runtime (default) | any | never
//                      `runtime` fails only on components that ship inside a
//                      host app; a finding in a test-only package is real but
//                      is not an exposure for an adopting bank, so it warns.
//
// Exit codes
//   0  no finding at or above --fail-on
//   1  finding at or above --fail-on
//   2  the scan could not be completed (OSV unreachable, bad input)

import { readFileSync, writeFileSync } from 'node:fs';

const OSV_BATCH = 'https://api.osv.dev/v1/querybatch';
const OSV_VULN = 'https://api.osv.dev/v1/vulns';
const BATCH_SIZE = 100;
const ATTEMPTS = 4;

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const eq = token.indexOf('=');
    if (eq !== -1) args[token.slice(2, eq)] = token.slice(eq + 1);
    else {
      args[token.slice(2)] = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));
if (!args.sbom) {
  console.error('osv-scan: missing required argument --sbom');
  process.exit(2);
}
const failOn = args['fail-on'] ?? 'runtime';
if (!['runtime', 'any', 'never'].includes(failOn)) {
  console.error(`osv-scan: --fail-on must be runtime, any, or never (got ${failOn})`);
  process.exit(2);
}

/// Transient failures against a public API are expected; a scheduled audit
/// that reports "clean" because one request timed out would be worse than
/// one that fails, so every retry is exhausted before giving up.
async function fetchJson(url, init, what) {
  let lastError = null;
  for (let attempt = 1; attempt <= ATTEMPTS; attempt += 1) {
    try {
      const response = await fetch(url, { ...init, signal: AbortSignal.timeout(30_000) });
      if (response.ok) return await response.json();
      // 4xx other than 429 will not improve by waiting.
      if (response.status < 500 && response.status !== 429) {
        throw new Error(`HTTP ${response.status}`);
      }
      lastError = new Error(`HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    if (attempt < ATTEMPTS) {
      await new Promise((resolve) => setTimeout(resolve, 1000 * 2 ** (attempt - 1)));
    }
  }
  throw new Error(`${what} failed after ${ATTEMPTS} attempts: ${lastError?.message}`);
}

// ---------------------------------------------------------------------------
// Read the inventory
// ---------------------------------------------------------------------------

let bom;
try {
  bom = JSON.parse(readFileSync(args.sbom, 'utf8'));
} catch (error) {
  console.error(`osv-scan: could not read ${args.sbom}: ${error.message}`);
  process.exit(2);
}
if (bom.bomFormat !== 'CycloneDX') {
  console.error(`osv-scan: ${args.sbom} is not a CycloneDX document`);
  process.exit(2);
}

// CycloneDX marks development-only components `excluded`; see cdxComponent in
// generate-sbom.mjs. Components without a purl are SDK-sourced (flutter,
// sky_engine) and have no OSV coordinate — they are counted, not queried, so
// the summary never implies coverage the scan does not have.
const components = (bom.components ?? []).map((component) => ({
  name: component.name,
  version: component.version,
  purl: component.purl ?? null,
  scope: component.scope === 'excluded' ? 'development' : 'runtime',
}));
const queryable = components.filter((component) => component.purl !== null);
const unqueryable = components.filter((component) => component.purl === null);

// ---------------------------------------------------------------------------
// Query OSV
// ---------------------------------------------------------------------------

const hits = new Map(); // component index -> vulnerability ids
try {
  for (let offset = 0; offset < queryable.length; offset += BATCH_SIZE) {
    const chunk = queryable.slice(offset, offset + BATCH_SIZE);
    const body = JSON.stringify({
      queries: chunk.map((component) => ({ package: { purl: component.purl } })),
    });
    const result = await fetchJson(
      OSV_BATCH,
      { method: 'POST', headers: { 'content-type': 'application/json' }, body },
      'OSV batch query',
    );
    const rows = result.results ?? [];
    if (rows.length !== chunk.length) {
      throw new Error(`OSV returned ${rows.length} results for ${chunk.length} queries`);
    }
    rows.forEach((row, index) => {
      const ids = (row.vulns ?? []).map((vuln) => vuln.id);
      if (ids.length > 0) hits.set(offset + index, ids);
    });
  }
} catch (error) {
  console.error(`osv-scan: ${error.message}`);
  process.exit(2);
}

// The batch endpoint returns bare ids. Detail is fetched only for the hits,
// which is normally an empty set, so a clean run costs one request per 100
// components and nothing more.
const details = new Map();
try {
  for (const ids of hits.values()) {
    for (const id of ids) {
      if (details.has(id)) continue;
      details.set(id, await fetchJson(`${OSV_VULN}/${encodeURIComponent(id)}`, {}, `OSV lookup ${id}`));
    }
  }
} catch (error) {
  console.error(`osv-scan: ${error.message}`);
  process.exit(2);
}

/// OSV records carry severity in several shapes depending on the source
/// database; the CVSS vector is the only one present often enough to report,
/// and `database_specific.severity` is GitHub's qualitative band.
function severityOf(vuln) {
  const qualitative = vuln?.database_specific?.severity;
  if (typeof qualitative === 'string' && qualitative !== '') return qualitative;
  const vector = (vuln?.severity ?? []).find((entry) => typeof entry.score === 'string');
  return vector ? vector.score : 'unspecified';
}

const findings = [...hits.entries()]
  .map(([index, ids]) => {
    const component = queryable[index];
    return {
      package: component.name,
      version: component.version,
      purl: component.purl,
      scope: component.scope,
      vulnerabilities: ids.sort().map((id) => ({
        id,
        summary: details.get(id)?.summary ?? '',
        severity: severityOf(details.get(id)),
        aliases: (details.get(id)?.aliases ?? []).slice().sort(),
        url: `https://osv.dev/vulnerability/${id}`,
      })),
    };
  })
  .sort((a, b) => a.package.localeCompare(b.package, 'en'));

const runtimeFindings = findings.filter((finding) => finding.scope === 'runtime');
const devFindings = findings.filter((finding) => finding.scope === 'development');

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

const report = {
  scannedAt: new Date().toISOString(),
  source: {
    document: args.sbom,
    serialNumber: bom.serialNumber ?? null,
    component: bom.metadata?.component?.purl ?? null,
  },
  coverage: {
    components: components.length,
    queried: queryable.length,
    notQueryable: unqueryable.map((component) => `${component.name}@${component.version}`),
  },
  findings,
};
if (args.out) writeFileSync(args.out, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

const subject = bom.metadata?.component;
console.log(`### Vulnerability scan for \`${subject?.name ?? 'package'}\` ${subject?.version ?? ''}`);
console.log('');
console.log('| Metric | Value |');
console.log('| --- | --- |');
console.log(`| Components in SBOM | ${components.length} |`);
console.log(`| Queried against OSV | ${queryable.length} |`);
console.log(`| Not queryable (SDK-sourced, no purl) | ${unqueryable.length} |`);
console.log(`| Runtime findings | ${runtimeFindings.length} |`);
console.log(`| Development-only findings | ${devFindings.length} |`);
console.log('');

if (findings.length === 0) {
  console.log('No known vulnerability affects any resolved dependency at the scanned versions.');
} else {
  console.log('| Package | Version | Scope | Advisory | Severity | Summary |');
  console.log('| --- | --- | --- | --- | --- | --- |');
  for (const finding of findings) {
    for (const vuln of finding.vulnerabilities) {
      const summary = vuln.summary.replace(/\|/g, '\\|').slice(0, 120);
      console.log(
        `| \`${finding.package}\` | ${finding.version} | ${finding.scope} | ` +
          `[${vuln.id}](${vuln.url}) | ${vuln.severity} | ${summary} |`,
      );
    }
  }
}
console.log('');
console.log(
  `Scanned against <https://osv.dev> on ${report.scannedAt}. ` +
    'A finding here is an advisory match on a resolved version, not a proven exploit path; ' +
    'triage follows the process in SECURITY.md.',
);

if (unqueryable.length > 0) {
  console.error(
    `::notice::${unqueryable.length} SDK-sourced component(s) have no OSV coordinate and were not queried: ` +
      `${report.coverage.notQueryable.join(', ')}. Flutter SDK advisories are tracked through the Flutter release channel.`,
  );
}
for (const finding of devFindings) {
  for (const vuln of finding.vulnerabilities) {
    console.error(
      `::warning::${vuln.id} affects development-only dependency ${finding.package}@${finding.version}; ` +
        'it is not part of any shipped host app.',
    );
  }
}
for (const finding of runtimeFindings) {
  for (const vuln of finding.vulnerabilities) {
    console.error(`::error::${vuln.id} affects runtime dependency ${finding.package}@${finding.version}.`);
  }
}

const shouldFail =
  (failOn === 'runtime' && runtimeFindings.length > 0) ||
  (failOn === 'any' && findings.length > 0);
process.exit(shouldFail ? 1 : 0);
