# Versioning, Releases, and Roadmap

This document states how `bank_ui_kit` is versioned, how releases are cut and
distributed, which Flutter versions are supported, and what ships over the
next 12 months. It follows the same rule as `GOVERNANCE.md`: where the
project has not yet reached a stated target, it says so and gives the
committed direction, not an aspiration dressed as fact.

Scope: the package at version 0.1.0 (`pubspec.yaml`), 141 exported widgets
plus three headless flow controllers under `lib/src/controllers/`, surfaced
through six entry points (`bank_ui_kit.dart`, `core.dart`, `saving.dart`,
`social.dart`, `investing.dart`, `credit.dart`).

## Semantic Versioning commitment

`CHANGELOG.md` declares adherence to Semantic Versioning 2.0.0 and Keep a
Changelog, and every release to date is recorded there. The public API is
everything reachable through the six entry points; anything under `lib/src/`
not re-exported by them is internal and carries no compatibility promise.

- Pre-1.0 (today): under SemVer, 0.x minor releases may contain breaking
  changes. Each one is listed in `CHANGELOG.md` under a Breaking heading
  with the old symbol, the new symbol, and the mechanical rewrite required.
- From 1.0: MAJOR for any breaking change to an exported symbol, its
  parameters, or its documented behavior (including the theming contract in
  `lib/src/theme/bank_theme_data.dart` and `lib/src/theme/tokens.dart` and
  the `Money` type in `lib/src/models/money.dart`). MINOR for additive API.
  PATCH for fixes with no API change.

### Deprecation policy

Binding from the first API retirement, and mandatory from 1.0:

1. Every breaking change is preceded by a minor release in which the old
   symbol carries an `@Deprecated` annotation whose message names the
   replacement and the earliest version that removes it, so the Dart
   analyzer surfaces the migration in the adopter's own CI.
2. The same minor's `CHANGELOG.md` entry carries migration notes: a
   before/after code sample for each deprecated symbol.
3. Minimum grace window: one full minor version. A symbol deprecated in
   N.M is not removed before N.(M+2) pre-1.0, and not before (N+1).0
   after the API freeze.
4. Renames ship as forwarding declarations during the grace window, so
   adopters upgrade the dependency first and migrate call sites second.

Current position, stated plainly: `lib/` contains zero `@Deprecated`
annotations today because no exported API has yet been retired. The policy
above is how the first retirement will be executed, and reviewers enforce it
through the pull-request process described in `GOVERNANCE.md`.

## Release process: pub.dev and signed tags

Current position: the package is consumed as a git dependency on
`https://github.com/sayed3li97/bank-ui-kit`. It has not yet been published
to pub.dev and the repository carries no release tags; `pubspec.yaml`
contains no `publish_to: none` marker, so publication requires no packaging
changes.

Committed process, first exercised at v0.2.0:

1. Version bump in `pubspec.yaml` and a dated `CHANGELOG.md` section,
   landed by pull request like any code change.
2. CI green on `.github/workflows/ci.yml`: `dart format` verification,
   `flutter analyze` against `analysis_options.yaml`, the six suites under
   `test/` (including `controllers_test.dart`, `widgets_smoke_test.dart`,
   and `parity_widgets_smoke_test.dart`), and the example web build.
3. `dart pub publish --dry-run` plus a pana score check as a release gate.
4. An annotated, cryptographically signed git tag `vX.Y.Z` on the release
   commit, pushed to GitHub with a GitHub Release whose notes are the
   changelog section verbatim. Tag signatures let an adopter verify that
   the tag was cut by a release key holder, not merely by anyone with push
   access.
5. `dart pub publish` to pub.dev under a verified publisher, with at least
   two uploader accounts so release capability never rests with a single
   credential (the same bus-factor rule `GOVERNANCE.md` applies to merge
   rights).

Every release re-verifies the license inventory of the five runtime
dependencies (`decimal`, `intl`, `fl_chart`, `collection`, `qr`).

## Release cadence

- During 0.x: a minor release approximately every 8 weeks, tracked by the
  dated milestones below. Patch releases ship as needed: within 10 business
  days for a confirmed regression in a released minor, faster for security
  issues.
- From 1.0: quarterly minors, patches on the same regression clock, and the
  LTS designation defined in `GOVERNANCE.md` (one minor per year with 24
  months of security and critical-defect fixes).

Dates in this document are targets the maintainer plans against; scope moves
before quality does. A milestone that slips is re-dated in this file through
a pull request, not silently missed.

## Supported Flutter versions

- Declared floor (`pubspec.yaml`): Flutter 3.27.0 and Dart 3.5.0, upper
  bound Dart <4.0.0. CI (`.github/workflows/ci.yml`) exercises Flutter
  3.27.1 stable on every push and pull request.
- Support window: each release supports the Flutter stable current at
  release time plus the declared floor; the floor is raised only in a minor
  release and recorded in `CHANGELOG.md`.
- 30-day new-stable commitment: within 30 days of each new Flutter stable,
  the kit is re-validated against it (analyze, full test suites, example
  web build) and either a compatible release or a written statement of the
  incompatibility and its fix timeline is published. This restates the
  commitment already made in `GOVERNANCE.md`.

## The 1.0 API freeze

1.0 is a contract event, not a marketing event. It ships when all of the
following hold, and not before:

1. The top-10 journey controllers (table below) are exported, each with a
   sealed status hierarchy and step enum in the pattern
   `BankTransferFlowController` establishes in
   `lib/src/controllers/bank_transfer_flow_controller.dart`, and covered in
   `test/controllers_test.dart`.
2. The deprecation policy has been exercised at least once end to end, so
   the grace-window machinery is proven rather than theoretical.
3. Enterprise gates are in force: DCO sign-off checked in CI, a
   `.github/CODEOWNERS` file with named module owners, branch protection
   requiring a human review distinct from the author, and pub.dev
   publication under a verified publisher with two uploaders.
4. Every exported symbol has dartdoc and an entry in
   `docs/component-reference.md`.

After 1.0, the exported API changes only through the deprecation policy, and
breaking changes require a major release.

## 12-month roadmap: July 2026 to June 2027

The top-10 journeys are the first ten entries of
`docs/banking-journeys.md`, in its order. Two controllers exist today;
the remaining eight names below are planned and follow the shipped naming
pattern. Each controller lands with the kit widgets it drives already in
place (for example `BankOtpInput`, `BankPinKeypad`, and
`BankBiometricPromptButton` for login, `BankAmountKeypad` for top-up,
`BankBeneficiaryPicker` for transfers, `BankBillPayTile` for bills,
`BankMyQrCard` for QR receive).

| # | Journey (docs/banking-journeys.md) | Controller | Status |
|---|-----------------------------------|------------|--------|
| 1 | Onboarding + KYC | `BankKycFlowController` | Shipped, 0.1.0 |
| 2 | Login / re-auth | `BankAuthFlowController` | Planned, v0.2.0 |
| 3 | Add money / top-up | `BankTopUpFlowController` | Planned, v0.2.0 |
| 4 | P2P transfer | `BankP2pFlowController` | Planned, v0.3.0 |
| 5 | Domestic bank transfer | `BankTransferFlowController` | Shipped, 0.1.0 |
| 6 | International remittance | `BankRemittanceFlowController` | Planned, v0.3.0 |
| 7 | Bill payment | `BankBillPayFlowController` | Planned, v0.4.0 |
| 8 | QR pay | `BankQrPayFlowController` | Planned, v0.4.0 |
| 9 | QR receive | `BankQrReceiveFlowController` | Planned, v0.4.0 |
| 10 | Card issuance | `BankCardIssuanceFlowController` | Planned, v0.5.0 |

Dated milestones, including the enterprise gates from `GOVERNANCE.md`:

| Date | Release | Deliverables |
|------|---------|--------------|
| 2026-08-31 | v0.2.0 | First signed tag; pub.dev publication under a verified publisher; DCO check in CI; controllers #2 and #3 |
| 2026-10-31 | v0.3.0 | Controllers #4 and #6; `.github/CODEOWNERS` with a second named maintainer; golden-test baseline using the `alchemist` dev dependency already in `pubspec.yaml` |
| 2026-12-31 | v0.4.0 | Controllers #7, #8, #9; second pub.dev uploader; branch protection requiring author-distinct human review |
| 2027-02-28 | v0.5.0 | Controller #10; full API review pass with any renames landed as `@Deprecated` forwards under the grace-window policy |
| 2027-04-30 | v1.0.0-rc.1 | API freeze candidate; migration notes complete; no new API until 1.0 |
| 2027-06-30 | v1.0.0 | API freeze in force; first LTS-designated line per `GOVERNANCE.md`; three-maintainer bench target |

The journey catalog lists 30 journeys; controllers beyond the top 10 (for
example card disputes and savings automation, where
`BankIncomeSorterController` already covers income splitting) are scheduled
after 1.0 as minor releases, additive by construction.

This document is versioned with the repository; changes to it land through
the same pull-request review and CI gates as code.
