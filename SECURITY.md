# Security policy

Bank UI Kit is a presentation-layer Flutter library. The package under `lib/`
opens no network connections, performs no disk or keychain persistence, and
holds no credentials: there is no `dart:io` import, no HTTP client, and no
storage plugin anywhere in the published library. Every sensitive value a
widget renders (balance, PIN digit, OTP code, account number) is supplied by
the host app and returned to the host app through callbacks. That boundary defines
this policy: the kit renders and masks sensitive data on screen, and custody
of that data stays with the integrating bank.

Contents: [threat model](#threat-model) ·
[reporting](#reporting-a-vulnerability) · [SLAs](#response-and-fix-slas) ·
[supported versions](#supported-versions) ·
[dependencies](#dependency-pinning-and-audit-policy) ·
[supply-chain artifacts](#supply-chain-artifacts) ·
[sensitive components](#scope-sensitive-components)

## Threat model

Getting this right saves a reviewer the most time, so it comes first. The
package is a UI layer, which removes whole categories of risk and
concentrates what remains into one category.

**What the package does not do**, verifiable by grepping `lib/`:

| Capability | Present? | How to check |
|---|---|---|
| Network I/O | No | `lib/` imports only `dart:async`, `dart:collection`, `dart:math`, `dart:ui` — no `dart:io`, no HTTP client, no socket |
| Disk, keychain, or database persistence | No | No storage plugin, no platform channel, no file API in the dependency closure |
| Cryptography | No | No key generation, storage, derivation, or signing anywhere in `lib/` |
| Credential handling | No | No token, secret, or session is created or held by the kit |
| Code execution from data | No | No `dart:mirrors`, no `dart:ffi`, no dynamic code loading |
| Platform channels | No | No `MethodChannel`, `EventChannel`, or `BasicMessageChannel` in `lib/` |
| Camera or sensor access | No | `BankQrScannerOverlay` renders scanner chrome around a `cameraChild` the host supplies; the kit never opens a camera |
| Telemetry or analytics | No | The kit emits no events off-device; every callback is host-supplied |

The consequence for an assessment: memory-safety exploits, injection into a
backend, credential theft from storage, and transport downgrade are not
attack surfaces this package owns, because the code paths that would carry
them do not exist. Assess them against your host app and your backend.

**What is in scope**, because this is where a UI layer can actually harm a
bank's customer:

1. **On-screen disclosure of confidential data.** A balance that renders
   unmasked when privacy mode is on, an account number that shows more
   characters than the mask allows, a PIN digit that stays visible, a
   sensitive value surviving into a screenshot or the app switcher. This is
   the primary risk the package owns, and it is why the SLA table below
   scores information-exposure defects one band above raw CVSS.
2. **Confused-deputy interaction defects.** A confirmation control that can
   be triggered without the intent it claims to capture: a transfer approved
   by a tap the user did not mean to place, a destructive action reachable
   without its confirmation step, an SCA sheet that resolves without a
   decision.
3. **Data leaving the widget by a path the host did not choose.** Clipboard
   writes, autofill hints, semantics labels that read out a value that is
   visually masked, and anything that lands in a debug log.
4. **Denial of service in the render path.** Unbounded input that hangs or
   crashes a widget — a formatter that never terminates, a layout that
   overflows on a hostile string.

**What is out of scope for this policy** and belongs to the host app:
authentication and authorisation decisions, cryptographic operations,
transport security, session lifetime, server-side validation of anything a
widget collects, OS-level screen-capture controls (see
`BankAppSwitcherPrivacyOverlay` below), clipboard expiry, and jailbreak or
root detection. Also out of scope as code: the `example/` app, the screenshot
tooling in `tool/`, and the documentation build — report defects there as
ordinary issues.

`doc/enterprise/compliance-matrix.md` states the same boundary claim by
claim, with the kit-side and host-side duty for each.

## Reporting a vulnerability

Report vulnerabilities through coordinated disclosure. Do not open a public
issue for a security defect.

- Preferred channel: GitHub private vulnerability reporting on
  <https://github.com/sayed3li97/Bank-UI-Kit/security/advisories>. Reports
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

### Coordinated disclosure process

1. **Report** through one of the channels above.
2. **Acknowledgment** within the window in the SLA table, confirming receipt
   and naming the maintainer handling it.
3. **Triage** to a severity band, with the reasoning shared with you. If we
   disagree with your scoring, you will hear why and can contest it.
4. **Fix development** in a private fork or a draft security advisory, with a
   regression test. You are invited to review the fix before it ships.
5. **Release** as a patch or minor version, with a `CHANGELOG.md` entry under
   a `Security` heading.
6. **Publication** of a GitHub Security Advisory, which propagates to the
   GitHub Advisory Database and from there to OSV and to the scanners your
   adopters run. A CVE is requested through GitHub for anything rated High or
   Critical.
7. **Credit** to you in the advisory and the changelog, unless you decline.

Disclosure window: 90 days from acknowledgment, or the fix release date,
whichever comes first. We will coordinate the publication date with you. If a
defect is being actively exploited, we will move faster and say so.

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

Stated plainly, because a bank's third-party risk function will ask: this is
a maintainer commitment on a community project, not a contractual support
agreement, and there is no 24/7 on-call rotation behind it. Adopters needing
a contractual SLA should raise that with the maintainer directly.

Every security fix ships with a regression test in `test/` and an entry in
`CHANGELOG.md` under a `Security` heading, per the Keep a Changelog format
the project already follows.

## Supported versions

| Version | Status |
|---------|--------|
| 0.2.x (current line, `main` branch) | Supported: security fixes and patches |
| 0.1.x | End of life — upgrade to 0.2.x |
| 0.0.x | End of life — upgrade to 0.2.x |

During the 0.x series, only the latest published minor receives security
fixes; a fix lands on `main` and ships as the next 0.x patch or minor. From
1.0.0 onward the commitment widens: the latest major receives fixes for all
severities, and the previous minor line receives Critical and High fixes for
6 months after it is superseded.

Backporting to an unsupported line is not offered. The upgrade path within
0.x is documented per release in `CHANGELOG.md`, and
`doc/enterprise/versioning-and-releases.md` states the deprecation policy
that governs how breaking changes reach you.

## Dependency pinning and audit policy

The runtime dependency surface is deliberately small: five direct packages,
declared in `pubspec.yaml` with caret constraints. `pubspec.lock` is not
committed — correct for a published library, since an adopting app resolves
its own closure — so the authoritative resolution record is the copy of
`pubspec.lock` shipped inside every SBOM artifact, which carries a SHA-256
content hash for every package.

| Package | Constraint | Resolved at 0.2.0 | Role |
|---------|------------|-------------------|------|
| `decimal` | `^3.0.0` | 3.2.6 | Exact monetary arithmetic (`Money` model) |
| `intl` | `^0.20.1` | 0.20.3 | Locale-aware formatting |
| `fl_chart` | `^1.2.0` | 1.2.0 | Line and pie rendering inside three chart wrappers |
| `collection` | `^1.19.0` | 1.19.1 | List utilities |
| `qr` | `^4.0.0` | 4.0.0 | Local QR matrix generation in `BankMyQrCard` (`lib/src/payments/bank_qr_pay_view.dart`); pure Dart, no camera |

Resolved versions above are the closure at the 0.2.0 release; the SBOM for
any given release is authoritative. Across the full closure that is 15
runtime-reachable packages against 17 development-only ones — only the first
group reaches a host application.

Audit process, in force today:

- `.github/workflows/ci.yml` runs `dart format --set-exit-if-changed`,
  `flutter analyze`, the design-token sync check, and `flutter test
  --coverage` on every push and pull request against `main`, on a pinned
  Flutter 3.44.4 toolchain.
- The same CI run generates an SBOM and scans it against
  [OSV.dev](https://osv.dev). A published advisory affecting a
  **runtime** dependency fails the build. A development-only finding
  annotates the run without failing it, because nothing in
  `dev_dependencies` is compiled into an adopter's app.
- A scheduled scan runs weekly (Monday 05:17 UTC), which is what catches
  advisories published against code that has not changed since the last
  commit.
- Every release records its vulnerability posture in an `osv-report.json`
  release asset. That scan never blocks the release; it is evidence, not a
  gate.
- Every third-party GitHub Action is pinned by 40-character commit SHA, with
  the tag recorded in a trailing comment, so a retagged release cannot
  silently enter a build.

Committed direction, not yet in force: a `dart pub outdated` review recorded
in each release's notes.

### fl_chart absorption commitment

`fl_chart` reached 1.0 and the kit now resolves 1.2.0, so its API is under
SemVer. The kit contains the remaining risk structurally: `fl_chart` is
imported in exactly three files,
`lib/src/insights/bank_cashflow_chart.dart`,
`lib/src/insights/bank_spending_breakdown_chart.dart`, and
`lib/src/investing/bank_portfolio_performance_chart.dart`, and no `fl_chart`
type appears in any public constructor or is re-exported (the library has no
`export 'package:...'` statement at all). The commitment: `fl_chart` version
bumps, including breaking ones, are absorbed inside those three wrappers.
`BankCashflowChart`, `BankSpendingBreakdownChart`, and
`BankPortfolioPerformanceChart` keep their public APIs stable, and a
`fl_chart` upgrade never forces a code change in a host app.

## Supply-chain artifacts

[`doc/enterprise/supply-chain.md`](doc/enterprise/supply-chain.md) is the
full reviewer-facing account —
verification commands, determinism, and the mapping to DORA and NIS2
supplier expectations. The short version of where things live:

| Artifact | Where |
|---|---|
| SBOM (SPDX 2.3 and CycloneDX 1.6) | Release asset on `https://github.com/sayed3li97/Bank-UI-Kit/releases/tag/vX.Y.Z`; also a build artifact on every CI run |
| Resolved `pubspec.lock` | Inside the same SBOM artifact and release assets |
| Vulnerability scan report | `osv-report.json`, same locations |
| Build provenance attestation | GitHub attestations API for this repository; verify with `gh attestation verify` |
| Asset checksum manifest | `SHA256SUMS` release asset |
| OpenSSF Scorecard result | <https://scorecard.dev/viewer/?uri=github.com/sayed3li97/Bank-UI-Kit>, and the repository's Security → Code scanning tab |

### Release provenance and signing

Current state, accurate as of 0.2.0:

- The package is published to pub.dev at
  <https://pub.dev/packages/bank_ui_kit>, and also usable as a git
  dependency from <https://github.com/sayed3li97/Bank-UI-Kit>.
- Publication runs from `.github/workflows/publish.yml` over pub.dev
  **trusted publishing (OIDC)**. No pub.dev credential is stored in this
  repository — no token, no secret. pub.dev accepts only a short-lived token
  minted for that workflow file on a tag ref, so a release is traceable to a
  public CI run on the tagged commit.
- Each GitHub Release carries SBOM documents, the resolution record, the
  scan report, and a checksum manifest, each covered by a Sigstore-signed
  in-toto SLSA v1 build provenance attestation generated by
  `actions/attest-build-provenance`. There are no long-lived signing keys to
  compromise because there is no signing key.
- **Not yet in place: signed git tags.** Tags are created by CI with the
  built-in token. Provenance is anchored in the attestation and the public
  workflow run, not in a maintainer GPG signature. A maintainer key and its
  fingerprint will be published in this file before 1.0.0.
- **Not covered by the attestation: the pub.dev archive itself.** pub.dev
  builds and stores that archive, so this repository cannot honestly attest
  it. Instead, the release records pub.dev's reported digest in
  `pubdev-archive.sha256`, which *is* one of the attested files — giving you
  a signed statement of the digest to compare against what your mirror
  fetched. `doc/enterprise/supply-chain.md` explains the limits of this.

Lockfile hygiene: a resolution change is reviewed in pull requests like code.
The SBOM diff in each PR's own CI run is what makes a new package entering
the closure visible at review time rather than at intake.

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
  `BankAccountNumberFormatter.mask`
  (`lib/src/accounts/bank_account_number_text.dart`) reduces identifiers to
  the last four characters; `BankPeekBalance` shows labels and balances only,
  never account numbers; `BankMaskedInputField` covers masked free-text entry.
- Clipboard writers. Copying is opt-in per widget, and these are the
  components that call `Clipboard.setData`:

  | Component | File | What it copies |
  |---|---|---|
  | `BankAccountNumberText` | `lib/src/accounts/bank_account_number_text.dart` | The full unformatted identifier |
  | `BankSummaryStack` | `lib/src/common/bank_summary_stack.dart` | A copyable row's value |
  | `BankHorizontalAccountCard` | `lib/src/cards/bank_horizontal_account_card.dart` | The account identifier |
  | `BankReferralInviteCard` | `lib/src/subscriptions/bank_referral_invite_card.dart` | The referral code or link |
  | `BankAppGateScreen` | `lib/src/states/bank_app_gate_screen.dart` | The support reference code shown on a blocking gate |

  The kit does not auto-clear the clipboard after a timeout. Clipboard expiry
  policy belongs to the host app: on Android, `ClipData` marked sensitive and
  a scheduled clear; on iOS, `UIPasteboard` expiry.

Integration guidance for all of the above lives in the Auth & Security
section of `doc/component-reference.md`, with end-to-end flows (security
center, device management, step-up authentication) in
`doc/banking-journeys.md`. A consolidated security integration guide,
`doc/security-integration.md`, covering `FLAG_SECURE` wiring, clipboard
expiry, session timeout, and PIN-flow backend contracts, is planned for the
1.0.0 documentation set and is not yet written.
