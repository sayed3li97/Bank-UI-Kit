# Security policy

Bank UI Kit is a presentation-layer Flutter library. The package under `lib/`
opens no network connections, performs no disk or keychain persistence, and
holds no credentials: there is no `dart:io` import, no HTTP client, and no
storage plugin anywhere in the published library. Every sensitive value a
widget renders (balance, PIN digit, OTP code, account number) is supplied by
the host app and returned to the host app through callbacks. That boundary defines
this policy: the kit renders and masks sensitive data on screen, and custody
of that data stays with the integrating bank.

## Reporting a vulnerability

Report vulnerabilities through coordinated disclosure. Do not open a public
issue for a security defect.

- Preferred channel: GitHub private vulnerability reporting on
  <https://github.com/sayed3li97/bank-ui-kit/security/advisories>. Reports
  there are access-controlled and visible only to maintainers.
- Email: <alkamelsayedali@gmail.com> with the subject prefix `[SECURITY]`.
- PGP: a maintainer PGP key is not yet published. Until it is, use the GitHub
  private advisory channel for any report containing exploit detail. A key
  and fingerprint will be added to this file before the 1.0.0 release.

Include the affected widget or file path, a minimal reproduction (a Flutter
`main.dart` that composes the widget is ideal), the observed and expected
behavior, and your assessment of impact. You will receive credit in the
advisory and the `CHANGELOG.md` entry unless you ask otherwise. Good-faith
research within this process will not be met with legal action.

Disclosure window: 90 days from acknowledgment, or the fix release date,
whichever comes first. We will coordinate the publication date with you.

## Response and fix SLAs

Severity is scored with CVSS v3.1, adjusted because this is a UI
library: information-exposure defects (masking, privacy overlay, clipboard)
are treated one band higher than raw CVSS suggests, because on-screen leakage
of financial data is the primary risk this package owns.

| Severity | CVSS v3.1 | Acknowledgment | Triage decision | Fix target |
|----------|-----------|----------------|-----------------|------------|
| Critical | 9.0 to 10.0 | 2 business days | 5 business days | Patch release within 14 days |
| High | 7.0 to 8.9 | 2 business days | 5 business days | Patch release within 30 days |
| Medium | 4.0 to 6.9 | 2 business days | 10 business days | Within 90 days |
| Low | 0.1 to 3.9 | 2 business days | 10 business days | Next scheduled minor release |

Every security fix ships with a regression test in `test/` and an entry in
`CHANGELOG.md` under a `Security` heading, per the Keep a Changelog format
the project already follows.

## Supported versions

| Version | Status |
|---------|--------|
| 0.1.x (current line, `main` branch) | Supported: security fixes and patches |
| Anything earlier | Not supported |

During the 0.x series, only the latest published minor receives security
fixes; a fix lands on `main` and ships as the next 0.x patch or minor. From
1.0.0 onward the commitment widens: the latest major receives fixes for all
severities, and the previous minor line receives Critical and High fixes for
6 months after it is superseded.

## Dependency pinning and audit policy

The runtime dependency surface is deliberately small: five packages, declared
in `pubspec.yaml` with caret constraints and resolved in the committed
`pubspec.lock`, which records a SHA-256 content hash for every package.

| Package | Constraint | Locked | Role |
|---------|------------|--------|------|
| `decimal` | `^3.0.0` | see `pubspec.lock` | Exact monetary arithmetic (`Money` model) |
| `intl` | `^0.20.1` | see `pubspec.lock` | Locale-aware formatting |
| `fl_chart` | `^0.70.0` | `0.70.2` | Line and pie rendering inside three chart wrappers |
| `collection` | `^1.19.0` | see `pubspec.lock` | List utilities |
| `qr` | `^3.0.2` | see `pubspec.lock` | Local QR matrix generation in `BankQrPayView`; pure Dart, no camera |

Audit process, current state: `.github/workflows/ci.yml` runs
`dart format --set-exit-if-changed`, `flutter analyze`, and
`flutter test --coverage` on every push and pull request against `main`, on a
pinned Flutter 3.27.1 toolchain. Committed direction: each release adds a
`dart pub outdated` review, and a scheduled CI job will fail the build when a
locked dependency gains a published security advisory.

### fl_chart pre-1.0 absorption commitment

`fl_chart` is pre-1.0, so its minor releases may break APIs. The kit contains
that risk structurally: `fl_chart` is imported in exactly three files,
`lib/src/insights/bank_cashflow_chart.dart`,
`lib/src/insights/bank_spending_breakdown_chart.dart`, and
`lib/src/investing/bank_portfolio_performance_chart.dart`, and no `fl_chart`
type appears in any public constructor or is re-exported (the library has no
`export 'package:...'` statement at all). The commitment: `fl_chart` version
bumps, including breaking ones, are absorbed inside those three wrappers.
`BankCashflowChart`, `BankSpendingBreakdownChart`, and
`BankPortfolioPerformanceChart` keep their public APIs stable, and a
`fl_chart` upgrade never forces a code change in a host app.

## Release provenance and signing

Current state: the package is distributed as source from
<https://github.com/sayed3li97/bank-ui-kit>. There is no pub.dev release yet,
no signed git tags, and no generated provenance attestation. Integrators
today should pin a commit SHA in their `pubspec.yaml` git dependency.

Committed plan for the first pub.dev release and every release after it:

1. Every release is a signed, annotated git tag (`vX.Y.Z`) created by a
   maintainer key whose fingerprint is published in this file.
2. Publication to pub.dev runs from the GitHub Actions workflow, not from a
   developer laptop, so the artifact is traceable to a public CI run on the
   tagged commit.
3. The release notes reference the `CHANGELOG.md` section and enumerate any
   `Security` entries with their advisory IDs.
4. `pubspec.lock` hash changes are reviewed in pull requests like code; a
   lockfile-only change never lands without a stated reason.

## Scope: sensitive components

Defects in the following components are triaged as security reports, not
functional bugs, because they render or route confidential data.

- PIN entry: `BankPinKeypad` and `BankPinDots` (`lib/src/auth/`),
  `BankCardPinManager` (`lib/src/cards/bank_card_pin_manager.dart`), and
  `BankTransactionPinSheet` (`lib/src/transfers/`). The keypad is stateless;
  digits flow to the host through `onDigit` and the host owns the PIN string.
  `BankCardPinManager` holds entered digits in widget state only for the
  duration of its three-step flow and hands them to the host's `onSubmit`.
  The kit never logs, persists, or transmits a PIN.
- One-time codes: `BankOtpInput` (`lib/src/auth/bank_otp_input.dart`) uses
  `AutofillHints.oneTimeCode` and exposes `BankOtpInputController.clear()` so
  hosts can wipe a code after a failed verification.
- Privacy overlay: `BankAppSwitcherPrivacyOverlay`
  (`lib/src/auth/bank_app_switcher_privacy_overlay.dart`) blurs (sigma 12,
  dark scrim) or replaces content when the app lifecycle becomes `inactive`
  or `paused`. Boundary to understand: this is widget-level obscuration. It
  does not set Android `FLAG_SECURE` and does not block iOS screen capture;
  banks requiring OS-level capture protection must add it in the host app.
- Masking and privacy mode: `BankUiScope.privacyEnabled` with
  `BankPrivacyToggle` masks every `BankBalanceText`;
  `BankAccountNumberFormatter.mask` reduces identifiers to the last four
  characters; `BankPeekBalance` shows labels and balances only, never
  account numbers; `BankMaskedInputField` covers masked free-text entry.
- Clipboard writers: exactly four components call `Clipboard.setData`:
  `BankAccountNumberText` (copies the full unformatted identifier),
  `BankSummaryStack` copyable rows, `BankHorizontalAccountCard`, and
  `BankReferralInviteCard`. Copying is opt-in per widget. The kit does not
  auto-clear the clipboard after a timeout; clipboard expiry policy belongs
  to the host app, and a dedicated guide section below covers it.

Integration guidance for all of the above lives in the Auth & Security
section of `doc/component-reference.md`, with end-to-end flows (security
center, device management, step-up authentication) in
`doc/banking-journeys.md`. A consolidated security integration guide,
`doc/security-integration.md`, covering FLAG_SECURE wiring, clipboard
expiry, session timeout, and PIN-flow backend contracts, is committed for
the 1.0.0 documentation set.

Out of scope for this policy: the `example/` app, the screenshot tooling in
`tool/`, and the documentation build. Report defects there as regular
issues on the tracker.
