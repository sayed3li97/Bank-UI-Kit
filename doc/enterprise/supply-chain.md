# Supply-chain transparency

This document is written for the person on the other side of a bank's
open-source intake gate. It states exactly which supply-chain artifacts
`bank_ui_kit` produces, where to find them for a given release, how to verify
them yourself, and how they map to the evidence an EU financial entity has to
hold under DORA and NIS2.

It follows the same rule as the rest of `doc/enterprise/`: where the project
has not reached a stated target, it says so. Read the
[Not claimed](#not-claimed) section before you cite anything here in an
assessment.

**Trust level, stated first.** Everything below is *self-attested*. The
artifacts are produced by this repository's own GitHub Actions workflows and
signed with GitHub's OIDC identity, which makes them tamper-evident and
traceable to a public CI run. That is not the same as audited. No third party
has certified this project's build pipeline, no SLSA level has been assessed
by an external evaluator, and no penetration test or code audit has been
performed on the package. A reviewer should treat these artifacts as
verifiable claims by the maintainer, not as assurance from an auditor.

## The artifacts at a glance

| Artifact | Format | Produced by | Where it lives | Cadence |
|---|---|---|---|---|
| Bill of materials | SPDX 2.3 JSON | `.github/workflows/sbom.yml` | CI run artifact; GitHub Release asset | Every push, every PR, every release |
| Bill of materials | CycloneDX 1.6 JSON | same | same | same |
| Resolution record | `pubspec.lock` | same | same | same |
| Vulnerability scan | JSON + job summary | `osv-scan.mjs` in the same job | same | Every push and PR; weekly; at release |
| Build provenance | in-toto SLSA v1, Sigstore-signed | `actions/attest-build-provenance` in `release.yml` | GitHub attestations API for this repository | Every release |
| Asset checksums | `SHA256SUMS` | `release.yml` | GitHub Release asset | Every release |
| pub.dev archive digest | `pubdev-archive.sha256` | `release.yml` | GitHub Release asset | Every release, best effort |
| Security posture score | OpenSSF Scorecard SARIF | `.github/workflows/scorecard.yml` | Scorecard API, repository Security tab, run artifact | Weekly, on push to `main`, on branch-protection change |

The canonical location for a released version `X.Y.Z` is

```
https://github.com/sayed3li97/Bank-UI-Kit/releases/tag/vX.Y.Z
```

and an individual asset is at

```
https://github.com/sayed3li97/Bank-UI-Kit/releases/download/vX.Y.Z/bank_ui_kit-X.Y.Z.spdx.json
```

For an unreleased commit, the same documents are attached to that commit's CI
run under **Actions → CI → the run → Artifacts → `sbom`**, retained for 90
days.

## 1. The bill of materials

### Why two formats

SPDX 2.3 is ISO/IEC 5962:2021 and is what most procurement and OSPO
pipelines ingest. CycloneDX 1.6 is what OWASP Dependency-Track and most
vulnerability-correlation tooling consume natively. Both are generated from
one resolution by `.github/workflows/scripts/generate-sbom.mjs`, so they
describe the same closure and no reviewer has to convert between them and
argue about what the conversion lost.

### What is in it

The documents describe the **resolved** dependency closure, not the caret
constraints in `pubspec.yaml`. For every package they carry the exact
version, the pub source, the `pkg:pub/...` package URL, the SHA-256 digest
of the archive as recorded by pub, and the download location.

Two properties matter for review and are not standard in generated SBOMs:

- **Runtime versus development is computed, not guessed.** `pub deps --json`
  labels only *direct* dev dependencies as `dev`; a package pulled in solely
  by a dev dependency is labelled `transitive` and is indistinguishable from
  a runtime one. The generator walks the graph from the root's runtime
  dependencies and marks everything unreachable that way as development-only
  (`scope: excluded` in CycloneDX, `DEV_DEPENDENCY_OF` relationships in
  SPDX). At 0.2.0 that split is 15 runtime-reachable components against 17
  development-only ones. Only the first group reaches a host application.
- **Dependency edges are preserved**, so the document answers "why is this
  package here" and not only "is this package here".

### What is deliberately absent

Per-package licence fields are `NOASSERTION`. The generator does not open
package LICENSE files, and emitting a guess would be worse than emitting
nothing — a licence field a reviewer cannot trust is a licence field that
has to be re-checked by hand anyway, at which point the guess has only added
risk. Authoritative per-package licence metadata is published on pub.dev at
`https://pub.dev/packages/<name>/license`. The root package's own licence is
asserted: MIT, matching `LICENSE`.

### Determinism, and how to check it

Every value in both documents is derived from the inputs. The SPDX `created`
timestamp is the commit's committer date, not wall-clock time; the CycloneDX
`serialNumber` is a UUID derived by hash from the document namespace, not a
fresh random one; every collection is sorted. Two runs of the same commit
against the same resolution produce byte-identical documents.

That claim is checkable, which is why `pubspec.lock` ships inside the
artifact — it is the other half of the input:

```sh
gh release download vX.Y.Z --repo sayed3li97/Bank-UI-Kit --dir assets
git clone https://github.com/sayed3li97/Bank-UI-Kit && cd Bank-UI-Kit
git checkout vX.Y.Z
cp ../assets/pubspec.lock .
flutter pub get                       # honours the lockfile you just restored
flutter pub deps --json > /tmp/deps.json
node .github/workflows/scripts/generate-sbom.mjs \
  --deps /tmp/deps.json --lock pubspec.lock --pubspec pubspec.yaml \
  --out /tmp/sbom --repo-url https://github.com/sayed3li97/Bank-UI-Kit \
  --commit "$(git rev-parse HEAD)" \
  --created "$(date -u -d "$(git log -1 --format=%cI)" +%Y-%m-%dT%H:%M:%SZ)" \
  --license MIT
diff /tmp/sbom/bank_ui_kit-X.Y.Z.spdx.json assets/bank_ui_kit-X.Y.Z.spdx.json
```

An empty diff means the published SBOM is what this commit produces, and you
did not have to trust the CI run to establish it.

The scan report described next is **not** reproducible, by design: it records
what a vulnerability database said at a moment in time. Only the two SBOM
documents and `pubspec.lock` carry the byte-identical property.

## 2. Vulnerability scanning

`.github/workflows/scripts/osv-scan.mjs` queries [OSV.dev](https://osv.dev)
for every component **in the generated SBOM**. Scanning the SBOM rather than
the lockfile is the point: the inventory you review and the inventory that
gets scanned are the same list by construction, so they cannot drift apart.

| When | Trigger | On a finding |
|---|---|---|
| Every push and pull request | `ci.yml` | A runtime finding fails the build; a development-only finding annotates it |
| Weekly, Monday 05:17 UTC | `sbom.yml` schedule | Same |
| At release | `release.yml` | Recorded in `osv-report.json`, never gates the release |

The weekly run is the one that matters for continuous monitoring: a
commit-triggered scan can only report the database as it stood when the
commit landed, and most advisories are published against code that has not
changed.

Reading a report:

- `findings[].scope` is `runtime` or `development`. A development-only
  finding is real but is not an exposure for an adopting bank — nothing in
  `dev_dependencies` is compiled into a host application.
- `coverage.notQueryable` lists SDK-sourced components (`flutter`,
  `flutter_test`, `sky_engine`) that have no package-URL coordinate and so
  were not queried. Flutter SDK advisories are tracked through the Flutter
  release channel, not through this scan. The report states this rather than
  implying coverage it does not have.
- A finding is an advisory match on a resolved version. It is not a proven
  exploit path in this package, and triage follows `SECURITY.md`.

At the time of writing, the runtime closure has no known OSV advisory.

## 3. Build provenance

Every GitHub Release runs `actions/attest-build-provenance`, which produces
an in-toto SLSA v1 provenance statement for each release asset, signs it with
a short-lived Sigstore certificate bound to the workflow's OIDC identity, and
records it on this repository's attestations endpoint. There are no
long-lived signing keys to steal, because there is no signing key.

### Verifying an attestation

With GitHub CLI 2.49 or newer:

```sh
gh release download vX.Y.Z --repo sayed3li97/Bank-UI-Kit --dir assets
gh attestation verify assets/bank_ui_kit-X.Y.Z.spdx.json \
  --repo sayed3li97/Bank-UI-Kit \
  --signer-workflow sayed3li97/Bank-UI-Kit/.github/workflows/release.yml
```

Use `--signer-workflow`. Without it, `--repo` accepts an attestation signed
by *any* workflow in the repository; with it, you are asserting that this
specific file was signed by the release workflow and nothing else. That is
the check that has teeth.

To see the full statement, including the commit, the workflow run, and the
builder identity:

```sh
gh attestation verify assets/SHA256SUMS --repo sayed3li97/Bank-UI-Kit --format json
```

For an air-gapped review, fetch the bundle once and verify offline
afterwards with `gh attestation download` followed by
`gh attestation verify --bundle`.

### What the attestation does and does not prove

It proves that a named file, identified by digest, was produced by
`release.yml` in this repository at a named commit, on GitHub-hosted
infrastructure.

It does **not** cover the package archive that pub.dev serves.
`flutter pub get` fetches from pub.dev, and pub.dev builds and stores that
archive itself. This repository cannot honestly attest an artifact it did not
build. What `release.yml` does instead is query pub.dev for the digest it
reports for the released version and write it to `pubdev-archive.sha256`,
which *is* one of the attested files. That gives you a signed,
repository-issued statement of the digest to compare against whatever your
mirror or proxy actually fetched:

```sh
sha256sum ~/.pub-cache/.../bank_ui_kit-X.Y.Z.tar.gz
cat assets/pubdev-archive.sha256
```

This step is best effort. `publish.yml` runs in parallel with the signing
job, so if pub.dev has not served the version within ten minutes the release
proceeds without that file. Its absence is not a signal of tampering.

### Publication itself

`publish.yml` publishes to pub.dev over OIDC trusted publishing. No pub.dev
credential is stored in this repository — no token, no secret, no service
account. pub.dev accepts only a token minted for this workflow file on a tag
ref. That workflow is deliberately minimal and carries no supply-chain extras
of its own: the OIDC token pub.dev accepts is bound to the workflow, so extra
steps or permissions there would put the binding at risk for no gain. The
SBOM and provenance work happens in `release.yml` alongside it.

## 4. OpenSSF Scorecard

`.github/workflows/scorecard.yml` runs the official
`ossf/scorecard-action` weekly, on every push to `main`, and whenever a
branch-protection rule changes, and publishes the result to the public
Scorecard API. Results are readable three ways: the
[viewer](https://scorecard.dev/viewer/?uri=github.com/sayed3li97/Bank-UI-Kit),
the repository's **Security → Code scanning** tab as SARIF, and the run's
`scorecard-results` artifact. The live badge, recorded here so it can be
reproduced anywhere it is needed:

```markdown
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/sayed3li97/Bank-UI-Kit/badge)](https://scorecard.dev/viewer/?uri=github.com/sayed3li97/Bank-UI-Kit)
```

Both URLs start resolving after the first run with `publish_results: true`
lands on `main`; until then they 404, which is expected rather than a
failure.

Two checks are worth knowing this repository's position on before you read
the score:

- **Pinned-Dependencies.** Every third-party action in
  `.github/workflows/` is pinned by 40-character commit SHA with the tag
  recorded in a trailing comment, so a retagged or compromised release cannot
  silently enter a build. The one exception is
  `dart-lang/setup-dart/.github/workflows/publish.yml@v1`, which stays on the
  tag because that is the form pub.dev's trusted-publishing documentation
  specifies.
- **Token-Permissions.** No workflow grants a write permission at the top
  level; each widens per job, and only where a job genuinely writes.
  `ci.yml`, `pages.yml` and `release.yml` declare `permissions: contents:
  read` at the top level. `scorecard.yml` declares `permissions: read-all`,
  which the Scorecard API requires of any workflow publishing results.
  `sbom.yml` and `publish.yml` declare no top-level block and scope
  everything to the job — for `publish.yml` that is deliberate, since the
  OIDC token pub.dev accepts is bound to that workflow and its permission set
  should be exactly what trusted publishing needs and nothing more. The write
  grants in the repository are: `contents: write` and
  `actions: write` on the release job, `contents: write`, `id-token: write`
  and `attestations: write` on the signing job, `pages: write` and
  `id-token: write` on the Pages deploy, `security-events: write` and
  `id-token: write` on the Scorecard job, and `id-token: write` on the
  publish job.

Scorecard is a heuristic over repository configuration. A low score on
`Fuzzing` or `SAST` for a UI widget library is not the same finding it would
be for a cryptographic library, and the score should be read next to the
threat model in `SECURITY.md`, not instead of it.

## 5. What a reviewer should actually run

A complete intake pass on release `vX.Y.Z`, in the order the checks build on
each other:

```sh
# 1. Fetch every asset for the release.
gh release download vX.Y.Z --repo sayed3li97/Bank-UI-Kit --dir assets

# 2. Integrity: the manifest covers every other asset.
(cd assets && sha256sum -c SHA256SUMS)

# 3. Provenance: the manifest was signed by this repo's release workflow.
gh attestation verify assets/SHA256SUMS \
  --repo sayed3li97/Bank-UI-Kit \
  --signer-workflow sayed3li97/Bank-UI-Kit/.github/workflows/release.yml

# 4. Inventory: what ships inside a host app.
jq -r '.components[] | select(.scope=="required") | "\(.name) \(.version)"' \
  assets/bank_ui_kit-X.Y.Z.cdx.json

# 5. Posture at release time.
jq '.coverage, (.findings | length)' assets/osv-report.json
```

Steps 2 and 3 compose: the attestation covers `SHA256SUMS`, and
`SHA256SUMS` covers everything else, so verifying one signature establishes
the integrity of every asset.

## 6. Mapping to DORA and NIS2

### DORA (Regulation (EU) 2022/2554, applicable from 17 January 2025)

One clarification first, because it changes which articles apply. A freely
licensed library obtained without a contractual arrangement is generally not
an "ICT third-party service provider" under DORA, so the Article 28 register
of information and the Article 30 contractual-provisions requirements do not
attach to this package. What does attach is the financial entity's own ICT
risk management framework: this package becomes a component in *your* asset
inventory. The artifacts here exist to let you populate that inventory
without reverse-engineering the dependency tree.

| Your obligation | What this project supplies | What stays yours |
|---|---|---|
| Art. 8(1),(4): identify and document information and ICT assets; maintain and periodically update inventories | SPDX and CycloneDX inventory of the exact resolved closure, regenerated on every commit, attached to every release | Placing the package and its closure in your own asset register; classifying the business function it supports |
| RTS (CDR (EU) 2024/1774) Art. 10: track the usage of third-party libraries, including open-source libraries | The runtime/development split, so you register only what actually ships; dependency edges, so you can justify each entry | Deciding whether the function this supports is critical or important |
| RTS Art. 10: automated vulnerability scanning, at least weekly for critical or important functions | Weekly scheduled OSV scan of the published SBOM, plus a scan on every commit, with machine-readable output | Running your own scanner against your own build; the weekly cadence here supplements yours, it does not discharge it |
| RTS Art. 10: identify and update trustworthy information resources about vulnerabilities | OSV.dev aggregation, plus GitHub Security Advisories for this repository | Correlating findings against your deployed versions |
| RTS Art. 10: verify that providers handle vulnerabilities and report them in a timely manner | `SECURITY.md`: coordinated disclosure channel, named acknowledgment and triage windows, severity-banded fix targets, advisory publication | Evidencing that you performed the verification |
| RTS Art. 10: procedures for responsible disclosure of vulnerabilities | Private advisory channel and a stated disclosure window in `SECURITY.md` | Your own disclosure procedure |
| Art. 9: protection and prevention, including integrity of software in use | Sigstore-signed SLSA provenance on release assets; SHA-256 digest for every dependency archive; OIDC publication with no stored credentials | Verifying the attestation at ingest and pinning what you ingest |

### NIS2 (Directive (EU) 2022/2555)

For banks, DORA is *lex specialis* — NIS2 Article 4 defers to it, so an EU
credit institution should read the DORA row above and treat NIS2 as
applicable to non-financial adopters of this package.

| Your obligation | What this project supplies |
|---|---|
| Art. 21(2)(d): supply-chain security, including the security of direct suppliers | A published inventory, a stated security posture, a Scorecard result, and provenance you can verify without contacting the maintainer |
| Art. 21(2)(e): security in acquisition, development and maintenance, including vulnerability handling and disclosure | The coordinated-disclosure process and SLAs in `SECURITY.md`; the per-commit and weekly vulnerability scans |

### The honest limit of this mapping

These artifacts are inputs to your compliance evidence, not compliance
itself. No open-source project can discharge a financial entity's DORA
obligations, and this one does not claim to. What it can do is make sure that
when your OSPO asks "what is in it, is any of it known-vulnerable, and did
the artifact come from where it says it did", the answers are machine-
readable and independently checkable.

## Not claimed

Stated plainly, so nothing here is read as more than it is:

- **No external audit.** No third party has assessed this build pipeline, and
  no SLSA level has been certified by an evaluator. The provenance attestation
  demonstrates a GitHub-hosted build; it is not a graded assurance level.
- **No security audit of the code.** No penetration test or third-party code
  review has been performed on the package.
- **No signed git tags yet.** Release tags are created by CI with the built-in
  token. Provenance is anchored in the Sigstore attestation and the public
  workflow run, not in a maintainer GPG signature. `SECURITY.md` records the
  commitment to add signed tags.
- **The pub.dev archive is not attested by this repository**, for the reason
  given in section 3. The digest file is a mitigation, not a substitute.
- **Per-package licences are `NOASSERTION`** in both documents. Licence
  clearance remains a separate exercise.
- **Reproducible builds are not claimed for the package archive.** The two
  SBOM documents are byte-reproducible; the Dart package archive that pub.dev
  builds is not something this repository reproduces.
- **The Flutter SDK is outside the scanned surface.** It is recorded in the
  SBOM as an SDK-sourced component with no package-URL coordinate, and its
  advisories come through the Flutter release channel.

## Where to raise something

Vulnerabilities go through the coordinated-disclosure channel in
[`SECURITY.md`](../../SECURITY.md) — not the public issue tracker. Questions
about these artifacts, a verification that will not reproduce, or a format
your intake tooling cannot ingest are ordinary issues on the tracker.

Related reading: [`SECURITY.md`](../../SECURITY.md) for the threat model and
disclosure process, [`versioning-and-releases.md`](versioning-and-releases.md)
for how releases are cut, and [`compliance-matrix.md`](compliance-matrix.md)
for the claim-by-claim split between what the kit provides and what the host
bank implements.
