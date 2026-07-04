# Project Governance and Support

This document states how Bank UI Kit is maintained, how changes are reviewed
and accepted, where the intellectual property comes from, and what an
enterprise adopter can rely on for support. It is written for procurement and
architecture review at regulated institutions. Where the project has not yet
reached a stated target, this document says so and gives the committed
direction rather than an aspiration dressed as fact.

Scope: the `bank_ui_kit` Flutter package at version 0.1.0 (see
`pubspec.yaml` and `CHANGELOG.md`), comprising 141 exported widgets in 185
Dart source files under `lib/src/`, six barrel entry points (`bank_ui_kit.dart`,
`core.dart`, `saving.dart`, `social.dart`, `investing.dart`, `credit.dart`),
and the example gallery and screenshot tooling under `example/` and `tool/`.

## Maintainer bench

Current position: the project has one maintainer with merge rights.

| Role | Person | Scope |
|------|--------|-------|
| Lead maintainer | Sayed Ali Alkamel (GitHub: `sayed3li97`) | All modules, releases, security |

Target: a bench of three or more named maintainers with merge rights before
the 1.0 release, with module-level ownership split along the directory
boundaries that already exist under `lib/src/` (for example `theme/`,
`payments/`, `investing/`, `islamic/`). Candidates are drawn from sustained
contributors; merge rights require six months of accepted contributions and
sponsorship by an existing maintainer.

CODEOWNERS mandate: the repository does not yet contain a
`.github/CODEOWNERS` file. One will be added as maintainers are appointed,
mapping each `lib/src/<module>/` directory, `lib/src/theme/`, and
`.github/workflows/` to named owners, so that GitHub enforces owner review on
every pull request touching those paths. Until then, the lead maintainer is
the owner of record for the entire tree.

## Decision and review process

Decisions are made in public on the GitHub issue tracker
(`https://github.com/sayed3li97/bank-ui-kit/issues`). Small changes are
decided by the reviewing maintainer; changes to the public API, the theming
contract in `lib/src/theme/bank_theme_data.dart` and `lib/src/theme/tokens.dart`,
or the `Money` type in `lib/src/models/money.dart` require an issue describing
the change and maintainer sign-off before implementation.

Every change lands through a pull request using
`.github/PULL_REQUEST_TEMPLATE.md` and must pass the CI gates defined in
`.github/workflows/ci.yml`: `dart format` verification, `flutter analyze`
with the strict `analysis_options.yaml` ruleset, the six test suites under
`test/` (including `widgets_smoke_test.dart` and
`parity_widgets_smoke_test.dart`), and a release build of the example web
harness. The conventions a reviewer checks against are written down in
`CONTRIBUTING.md`: token-driven theming, state-management-agnostic widgets,
`Money` for all amounts, RTL and semantics coverage.

Mandatory human review of AI-authored changes: a substantial share of this
codebase was authored with AI assistance, and the git history records this
with `Co-Authored-By` trailers naming the exact model on AI-assisted commits.
Policy: no AI-authored change reaches `main` without review by a human
maintainer. Today that reviewer is the lead maintainer, who reviews and
merges every pull request; AI tooling holds no credentials and no merge
rights. When the maintainer bench reaches two, branch protection on `main`
will additionally require one approving human review distinct from the
author, enforced by GitHub rather than by convention.

## Contribution licensing: DCO

Current position: `CONTRIBUTING.md` establishes inbound-equals-outbound
licensing (contributions are accepted under the project's MIT `LICENSE`), but
sign-off is not yet machine-enforced.

Committed direction: the project will adopt the Developer Certificate of
Origin (DCO 1.1) before the 1.0 release. Every commit will require a
`Signed-off-by` trailer, checked in CI, certifying that the contributor has
the right to submit the work under MIT. The project uses DCO rather than a
CLA: copyright stays with contributors, which removes a negotiation step for
corporate contributors and leaves no single party able to relicense the work.

## IP provenance

- License: MIT, copyright Sayed Ali and Bank UI Kit contributors (`LICENSE`).
  Adopters receive the full rights to use, modify, and redistribute,
  including in closed-source banking applications.
- AI-assisted authorship: the project discloses, rather than obscures, that
  code was produced with AI assistance under human direction and review. The
  provenance trail is the git history itself: `Co-Authored-By` trailers
  identify the model per commit, and the merge record identifies the human
  who reviewed and accepted each change. All AI-assisted output was released
  by the maintainer as original work under MIT; no copyleft-licensed source
  was supplied to the tooling as input.
- Runtime dependencies (`pubspec.yaml`): `decimal`, `intl`, `fl_chart`,
  `collection`, and `qr`, all under permissive licenses (MIT, BSD, Apache
  2.0). Dev-only: `flutter_lints`, `alchemist`. A license inventory is
  re-verified at every release.
- Bundled assets: the only binary assets in the package are the Space
  Grotesk, Fredoka, and Nunito font files under `lib/src/assets/fonts/`, each
  distributed under the SIL Open Font License 1.1, which permits bundling.
  Per the policy in `CONTRIBUTING.md`, no illustrations or brand imagery are
  committed; widgets expose `Widget? illustration` slots the host app fills.

## Bus-factor mitigation and succession

Current bus factor: one. The mitigations below bound the impact.

1. No private infrastructure. Build, test, and documentation generation run
   entirely from the repository: GitHub Actions (`.github/workflows/ci.yml`),
   the screenshot pipeline (`example/lib/screenshot_harness.dart` plus
   `tool/screenshots.mjs`), and docs under `doc/`. Any fork reproduces the
   full toolchain with `flutter pub get`.
2. Written-down knowledge. Architecture conventions live in
   `CONTRIBUTING.md`; the component contract is documented per widget with
   parameter tables in `doc/component-reference.md` (1,000+ lines); flow
   coverage is mapped in `doc/banking-journeys.md`.
3. Succession: if the lead maintainer is unresponsive for 60 days, merge and
   release rights pass to the most senior remaining maintainer. Until the
   bench exists, the MIT license is the backstop: any adopter may continue a
   maintained fork without permission or negotiation.
4. Distribution: the package is consumed today as a git dependency.
   Publication to pub.dev under a verified publisher, with at least two
   uploaders, is planned alongside the maintainer-bench expansion so that
   release capability never rests with a single account.

## Support and LTS policy

Current position: 0.1.0 is pre-1.0. Under the Semantic Versioning policy
stated in `CHANGELOG.md`, 0.x minor releases may contain breaking changes,
each recorded in the changelog. No long-term-support commitment attaches to
0.x, and the document will not pretend otherwise.

Committed policy from 1.0:

- Each minor release receives bug fixes until the next minor ships, and
  security and critical-defect fixes for 12 months from its release date.
- One minor per year is designated LTS, with security and critical-defect
  fixes for 24 months and a published upgrade guide to the next LTS.
- Flutter SDK compatibility (currently Flutter 3.27+ / Dart 3.5+, pinned in
  `pubspec.yaml` and exercised in CI on Flutter 3.27.1) is re-validated
  against each stable Flutter release within 30 days.
- Defect intake is the public issue tracker; regressions in released minors
  are triaged within 5 business days.

## Commercial support and fork-and-own

- Source escrow is unnecessary by construction: the complete source,
  documentation, tests, and build tooling are in this repository under MIT.
  An enterprise adopter can vendor the package, mirror the repository into
  internal git hosting, and own the fork outright from day one, with no
  binary components and no license fees. This is the strongest form of
  escrow available and it is already in force.
- Commercial support: paid engagements for integration, custom theming
  beyond the four shipped presets (`BankStudioTheme`, `BankVoltageTheme`,
  `BankBloomTheme`, `BankHeritageTheme` under `lib/src/theme/presets/`),
  priority defect SLAs,
  and private LTS branches are available by direct agreement with the lead
  maintainer. Initiate contact through the issue tracker or the maintainer's
  GitHub profile; terms are negotiated per engagement and are not bundled
  into the open-source license.
- Fork-and-own with re-sync: because widgets are pure (data in via
  constructors, events out via callbacks, no state-management dependency), a
  bank's fork can track upstream with low merge cost; divergence is expected
  to concentrate in theme presets and strings (`BankUiStrings` in
  `lib/src/scope/`).

This document is versioned with the repository; changes to governance land
through the same pull-request and review process as code.
