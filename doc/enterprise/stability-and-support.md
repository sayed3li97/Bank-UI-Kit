# Stability and support

This document is the dependency contract. It answers the question an
architecture review actually asks before a component library enters a
banking codebase: if we take this dependency, what can change under us, how
much warning do we get, and what happens if the project stops.

It is deliberately narrow. Release mechanics, the publish and attestation
pipeline, the roadmap, and the Flutter support window live in
[versioning-and-releases.md](./versioning-and-releases.md). Who maintains the
project, how changes are reviewed, and the IP provenance live in
[GOVERNANCE.md](../../GOVERNANCE.md). Vulnerability handling lives in
[SECURITY.md](../../SECURITY.md). This file covers what those three do not:
what counts as a breaking change for a UI kit, how long you get to react to
one, what 1.0 will mean, which versions are supported, and what an adopter
can do about a single-maintainer project.

Scope: the `bank_ui_kit` package at version 0.2.0 (`pubspec.yaml`), 164
widget classes plus the headless flow controllers under
`lib/src/controllers/`, reachable through six entry points
(`bank_ui_kit.dart`, `core.dart`, `saving.dart`, `social.dart`,
`investing.dart`, `credit.dart`).

Where this project has not reached a stated target, this document says so.
No support SLA, service commitment, or vendor relationship is created by the
MIT license, and nothing below should be read as one.

## The public surface

The compatibility promise covers exactly this:

1. Every symbol exported by the six barrel files, including its constructor
   parameters, their types, their optionality, and their default values.
2. The theming contract: `BankThemeData`, `BankTokens`, `BankPreset`, the
   `toJson` / `fromJson` schema, and the `withBankTheme` extension.
3. The `Money` type and `BankMoneyFormatter` output for a given amount,
   currency, and locale.
4. The observable behaviour of the headless controllers: the step sequence,
   the sealed status hierarchy, and which mutations notify listeners.
5. The rendered appearance of a widget under a stock preset, in the sense
   defined under [visual defaults](#visual-defaults-are-part-of-the-contract).

Anything under `lib/src/` that no barrel re-exports is internal. It can be
renamed, split, or deleted in a patch release. The example app under
`example/`, the screenshot tooling under `tool/`, the golden baselines under
`test/golden/`, and every file under `doc/` are outside the promise as well,
though changes to `doc/` that contradict a shipped behaviour are treated as
defects.

## What counts as a breaking change

Three categories break an adopter, and only the first is the one most
libraries bother to write down.

### API breaks

- Removing or renaming an exported symbol, including enum values and
  extension members.
- Adding a value to an exported enum. Dart 3 checks switch exhaustiveness,
  so a new value breaks an adopter who switches over the enum without a
  default case. This is treated as breaking even though many libraries do
  not.
- Adding a required constructor parameter, or making an existing optional
  parameter required.
- Narrowing a parameter type, widening a return type, or changing a
  parameter's declared nullability from nullable to non-nullable.
- Moving a symbol between barrels, because an adopter importing `core.dart`
  loses it even though the package still exports it somewhere.
- Raising the declared Dart or Flutter floor in `pubspec.yaml`.
- Adding an abstract member to an exported class an adopter can implement or
  extend.

### Behavioural breaks

- Changing which callback fires, in what order, or with what argument, for
  an unchanged sequence of user input.
- Changing a controller's step order, its terminal states, or the conditions
  under which it reports validity or completion.
- Changing rounding, grouping, symbol placement, or minor-unit handling in
  `Money` or `BankMoneyFormatter` for an input that already produced output.
- Changing what privacy mode masks, or what a widget exposes to the
  semantics tree.
- Changing validation outcomes, for example which IBAN or PAN strings the
  masked input accepts.

### Visual defaults are part of the contract

This is the category that actually bites, and this project has shipped two
releases that changed it, so the policy is written from experience rather
than from principle.

A visual break is any change that alters what an adopter sees on screen when
they have not asked for it. Concretely, in a stock preset with no
constructor overrides, a change to any of the following is breaking:

| Change | Example from this project |
|---|---|
| A token colour value | `positiveBalance` moved from a 2.26:1 green to an AA-compliant emerald in 0.1.0 |
| A preset's resolved colour for a role | Bloom light `onPrimary` moved from white to dark ink in 0.1.0 |
| Default spacing, padding, or size of a component | `BankAccountCard` lost its fixed 70 to 90 px band and became content-sized in 0.2.0 |
| Default radius or shape | Any preset radius change, since it cascades to every surface reading it |
| Default elevation, shadow, or hairline | The dark-mode depth system adopted across 30+ card surfaces in 0.2.0 |
| Default font family or type scale | `displayFontFamily` per preset in 0.2.0 (Heritage moved to a serif display face, Bloom to Fredoka) |
| Default motion duration or curve on an existing animation | A duration token change, which every widget reading it inherits |
| Default composition of a component's own chrome | The Visa, Mastercard, and Amex marks replacing the synthetic text treatment in 0.2.0 |

Both 0.1.0 and 0.2.0 shipped as minors under 0.x, which SemVer permits
pre-1.0, and both recorded what moved in `CHANGELOG.md`. After 1.0 the same
changes would require a major.

Why this matters more for a UI kit than for a typical library: an adopting
bank's own golden tests, brand sign-off, and app-store screenshots are all
downstream of these values. A colour token that moves by one shade fails a
bank's visual regression suite exactly as loudly as a deleted method fails
its compiler, and it does so without any analyzer warning to precede it.

### What is not a breaking change

Stated so the policy stays usable rather than paralysing:

- Adding an optional constructor parameter whose default reproduces the
  previous behaviour and appearance.
- Adding a new widget, a new token with a default, a new named constructor,
  or a new preset.
- Fixing a rendering defect that no reasonable adopter depended on, for
  example text that fractured mid-word or a control that fell below the
  44 px tap target. These are recorded in `CHANGELOG.md` under Fixed with
  the visual difference described.
- Changing anything under `lib/src/` that no barrel exports.
- Regenerating screenshots, goldens, or docs.
- Accessibility corrections required to hold a stated conformance claim, at
  patch or minor level pre-1.0 only, and always named in the changelog with
  the before and after value. From 1.0 these follow the visual-default
  procedure below rather than shipping silently.

## Deprecation policy

The API deprecation mechanics are specified in
[versioning-and-releases.md](./versioning-and-releases.md#deprecation-policy):
an `@Deprecated` annotation naming the replacement and the removing version,
a changelog entry with before and after samples, a minimum grace window of
one full minor pre-1.0 and one full major after, and renames shipped as
forwarding declarations.

This document adds two things to that policy.

### The window in wall-clock time

A version-count window is unusable for planning if releases are irregular.
The floor is therefore both: a deprecated symbol survives at least one full
minor version **and** at least 90 days from the release that deprecated it,
whichever is longer. If the release cadence slips, the clock does not.

### Deprecating a visual default

An `@Deprecated` annotation cannot be attached to a colour. From 1.0, a
change to any value in the [visual defaults](#visual-defaults-are-part-of-the-contract)
table follows this procedure instead:

1. The new value ships in a major release, never in a minor or a patch.
2. The changelog entry names the old value, the new value, and the single
   `copyWith` or `BankThemeData.custom` argument that restores the old one,
   so an adopter who has brand sign-off on the old appearance can pin it in
   one line rather than forking.
3. Where the change is structural rather than a token value, for example a
   component's default layout, the previous behaviour stays reachable
   through an optional constructor parameter for the length of the major.
4. The affected golden baselines are listed by name in the changelog, so an
   adopter can predict which of their own goldens will move.

Current position: this procedure is policy, not yet practice. It has not
been exercised, because the two default-changing releases predate it. The
first release that changes a visual default after 1.0 is the test of it.

### Pinning guidance for adopters

Until 1.0, pin exactly. A caret constraint on a 0.x version accepts a minor
that SemVer allows to break you:

```yaml
dependencies:
  bank_ui_kit: 0.2.0   # exact, no caret, while the package is pre-1.0
```

From 1.0, `^1.2.0` is safe against everything in this document except the
things a major release is allowed to change.

If you run your own golden or visual-regression tests against screens built
from kit widgets, pin exactly regardless of version, and treat a kit upgrade
as a change that lands in its own pull request with the golden diff visible.
That is the workflow the changelog is written to support.

## What 1.0 will mean

1.0 is an API and appearance freeze that a set of criteria gates, rather
than a date on a plan. Those criteria are listed below with their status as
of 2026-08-24.
[versioning-and-releases.md](./versioning-and-releases.md#the-10-api-freeze)
holds the four API-completeness criteria and the dated roadmap; this list is
the full gate, and where an item duplicates that document it is marked.

| # | Criterion | Status |
|---|-----------|--------|
| 1 | The top-10 journey controllers are exported, each with a sealed status hierarchy and step enum, covered in `test/controllers_test.dart` (see the roadmap) | Not met: 2 of the top 10 shipped |
| 2 | The deprecation policy has been exercised end to end at least once, so the grace window is proven rather than theoretical (see the roadmap) | Not met: `lib/` contains no `@Deprecated` annotations |
| 3 | The visual-default procedure above has been exercised at least once, including the one-line restore recipe in the changelog | Not met |
| 4 | Every exported symbol has dartdoc and an entry in `doc/component-reference.md` (see the roadmap) | Partially met |
| 5 | A second maintainer with merge rights, named in `.github/CODEOWNERS` | Not met: bench of one |
| 6 | pub.dev publication under a verified publisher with at least two uploader accounts | Not met: the publish pipeline exists (`.github/workflows/publish.yml`, trusted publishing over OIDC, no stored credentials); the second uploader does not |
| 7 | DCO sign-off enforced in CI, and branch protection requiring a review distinct from the author | Not met |
| 8 | The accessibility conformance report reissued against the frozen API, with the known-gaps list current | Partially met: [ACR](./acr/ACR.md) published for 0.2.0 |
| 9 | An OpenSSF Scorecard result published continuously, with no unaddressed high-severity check | Partially met: [`scorecard.yml`](../../.github/workflows/scorecard.yml) publishes weekly |
| 10 | SBOM and signed build provenance attached to every release, not only to the latest | Met for the current pipeline: [`sbom.yml`](../../.github/workflows/sbom.yml) and the provenance job in `release.yml` |
| 11 | A published upgrade guide from the last 0.x to 1.0, covering every visual default that moved across the 0.x line | Not met |

Criteria, not a date. The roadmap in
[versioning-and-releases.md](./versioning-and-releases.md#12-month-roadmap-july-2026-to-june-2027)
carries the dates the maintainer plans against, and a slipped date is
re-dated there through a pull request. If a date arrives and a criterion
above is unmet, the date moves. 1.0 does not ship on an unmet gate.

## Supported versions and patches

Current position, pre-1.0: **only the most recent released version is
supported.** There is no back-porting to 0.1.x, and there will not be. An
adopter on an older 0.x who reports a defect will be asked to reproduce on
the current version.

| Version | Status | Fixes |
|---------|--------|-------|
| 0.2.0 | Current | Defect and security fixes |
| 0.1.0 and earlier | Superseded | None. Upgrade to current |

Response times are the ones stated elsewhere and are not restated as new
promises: regressions in a released version are triaged within 5 business
days (`GOVERNANCE.md`), a confirmed regression targets a patch within 10
business days (`versioning-and-releases.md`), and security reports follow
the severity clocks in `SECURITY.md`. Those are maintainer intentions
published in the open, not contractual service levels. Nothing in the MIT
license obliges anyone to meet them.

From 1.0 the support window widens to the policy already committed in
[GOVERNANCE.md](../../GOVERNANCE.md#support-and-lts-policy): each minor
receives fixes until the next minor ships and security fixes for 12 months,
and one minor per year is designated LTS with 24 months of security and
critical-defect fixes.

Patch releases carry no API change and no visual-default change. If a fix
requires either, it is not a patch.

## Continuity if the project stops

### The current reality

One maintainer holds merge and release rights. The bus factor is one. There
is no company, no foundation, no legal entity, and no commercial support
contract standing behind this package. The license is MIT and the
contribution model is inbound equals outbound, so no single party can
relicense the work, and equally no single party owes anyone a fix.

An enterprise intake process that encodes the
[OpenSSF Concise Guide](https://best.openssf.org/Concise-Guide-for-Evaluating-Open-Source-Software)
will flag this project on exactly two counts: a 0.x version and a single
maintainer. Both flags are correct. This section is not an argument that
they are wrong. It is what an adopter can do about them today.

### What an adopter can do about it

Four things, all available today without asking anyone.

1. Fork rights are already yours. MIT grants the right to use, modify, and
redistribute, including inside a closed-source banking app, with no fee and
no negotiation. If the project stops, nothing needs to be renegotiated and
no escrow agreement needs to be triggered, because the escrow condition is
already satisfied: the complete source, tests, docs, and build tooling are
in the repository.

2. Nothing runs on private infrastructure. Build, test, token generation,
screenshots, SBOM, and provenance all run from files in the repository on
GitHub Actions. A fork reproduces the entire toolchain with `flutter pub
get`. There is no hosted service, no license server, no private registry,
and no binary blob in the package other than the OFL-licensed font files.

3. Vendoring is a supported consumption model. Mirror the repository into
internal git hosting and depend on the checkout by path, which removes both
pub.dev and GitHub from your build path:

   ```yaml
   dependencies:
     bank_ui_kit:
       path: third_party/bank_ui_kit
   ```

   Because widgets take data in through constructors and send events out
   through callbacks, with no state-management coupling anywhere in `lib/`,
   a vendored copy tracks upstream at low merge cost. Divergence
   concentrates in theme presets and in `BankUiStrings`, which is the same
   conclusion
   [GOVERNANCE.md](../../GOVERNANCE.md#commercial-support-and-fork-and-own)
   reaches from the licensing side.

4. Your design system outlives the Dart code. This is the mitigation that
is specific to this package. The tokens are not Dart constants. The source
of truth is `tokens/design-tokens.json` in W3C DTCG format, and every preset
is exported to `tokens/themes/*.json` in the same format, with
`BankThemeData.toJson` and `fromJson` making any brand a lossless round
trip. Those files are readable by Style Dictionary, Figma Variables
importers, and Tokens Studio, and they carry no dependency on this package,
on Flutter, or on Dart. If you abandon the widgets entirely, the design
decisions you paid for stay portable to whatever renders your app next. See
[design-tokens.md](./design-tokens.md).

Whichever of those you take, the upgrade path stays inspectable before you
commit to it. Every release carries a changelog section, an SBOM in SPDX 2.3
and CycloneDX 1.6, and a Sigstore-backed provenance attestation, so you can
diff what a version changed and verify that the artifact you fetched is the
one the pipeline built, both from outside the project. See
[supply-chain.md](./supply-chain.md).

### Committed direction

A single maintainer is a real risk and the mitigations above bound it rather
than remove it. The direction, restating what
[GOVERNANCE.md](../../GOVERNANCE.md#maintainer-bench) commits to rather than
adding new promises:

- A second maintainer with merge rights, named in `.github/CODEOWNERS`, is a
  1.0 gate (criterion 5 above), not a post-1.0 aspiration.
- Merge rights require six months of accepted contributions and sponsorship
  by an existing maintainer, so the bench grows from demonstrated
  contribution rather than by appointment.
- Two pub.dev uploader accounts so release capability never rests on one
  credential (criterion 6 above).
- If the lead maintainer is unresponsive for 60 days, merge and release
  rights pass to the most senior remaining maintainer. Until a bench exists,
  the MIT license is the backstop and a maintained fork needs no one's
  permission.
- Maintainers from more than one organisation is the target the OpenSSF
  guidance asks for, and the honest status is that the project has not
  reached it. Neutral governance, meaning a foundation or a multi-party
  steering arrangement, follows a second contributing organisation rather
  than preceding it. There is no second organisation today, so there is
  nothing yet for a neutral body to govern.

## Verifying any of this yourself

Every claim above is checkable from the repository. Nothing here needs to be
taken on the maintainer's word.

| Claim | Where to check |
|---|---|
| The public surface is what the barrels export | `lib/bank_ui_kit.dart` and the five module barrels |
| Breaking changes are recorded per release | `CHANGELOG.md`, one dated section per version |
| Accessibility gates are enforced rather than asserted | `.github/workflows/ci.yml`, and `test/accessibility_*_test.dart` |
| Tokens and Dart cannot drift | `dart run tool/generate_tokens.dart --check`, run in CI on every push |
| The dependency closure is what the SBOM says | `.github/workflows/sbom.yml`, and the SBOM artifact on any CI run |
| Releases are signed and attested | The provenance job in `.github/workflows/release.yml` |
| The maintainer bench is one person | `GOVERNANCE.md`, and the repository's contributor graph |
| The accessibility claims are self-assessed, not audited | [`acr/ACR.md`](./acr/ACR.md), which says so in its own opening |

This document is versioned with the repository. Changes to it land through
the same pull-request review and CI gates as code.
