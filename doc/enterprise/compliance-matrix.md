# Compliance responsibility matrix

This document states, claim by claim, what `bank_ui_kit` provides and what
the integrating bank must implement, so a due-diligence reviewer can trace
every compliance-adjacent statement to source under `lib/`.

The boundary follows from the architecture: the kit is a display and
interaction layer, a pure Dart package with five runtime dependencies
(`decimal`, `intl`, `fl_chart`, `collection`, `qr` per `pubspec.yaml`) and
zero platform channels. It never touches the network, storage, telephony,
or the platform window. Every regulatory control therefore splits into a
display-side duty the kit discharges and a policy, cryptographic, or
server-side duty the bank retains. Where the kit does not yet do something,
this document says so and gives the committed direction, following the same
rule as `doc/enterprise/versioning-and-releases.md`.

Terms: "Kit provides" means shipped and verifiable in `lib/` at 0.1.0;
"Host implements" means the bank's duty, wired through a kit callback or slot.

## Summary matrix

| Claim | Kit provides (0.1.0) | Host bank implements |
|---|---|---|
| SCA dynamic linking (PSD2) | `BankScaApprovalSheet`: amount and payee pinned, never privacy-masked, non-dismissible modal, 3 auth methods, typed verify callback, expiry countdown | Authentication-code generation bound to amount and payee, code invalidation on change, attempt limits and lockout, server-side expiry |
| Consent capture | `BankConsentModal`: accept gated on scroll-to-bottom plus explicit checkbox | Audit-record construction and retention; document versioning (typed event contract is planned, see section 2) |
| Consent dashboard | `BankConsentManagementList`: typed `BankConsent` model, confirmed revocation, revoked entries retained struck-through | Consent store, revocation API, expiry policy |
| CoP / VoP | `BankBeneficiary.isVerified` badge in `BankBeneficiaryPicker`; `BankTransferReviewCard` with `additionalInfo` slot for name-check copy | Name-check API call, match classification, liability wording, new-payee cooling-off |
| APP-fraud surfaces | `BankFraudAlertBanner` (resists accidental dismissal), `BankCallVerificationScreen` (anti-vishing), `BankPanicFreezeButton` (1,500 ms press-and-hold) | Fraud detection, risk scoring, payment holds, reimbursement handling |
| Deposit-protection notice | `BankMoneyProtectionBanner`: non-dismissible, scheme-configurable copy and logo | Correct scheme, coverage figures, eligibility wording, regulator sign-off |
| Privacy mode | `BankUiScope.privacyEnabled` consumed by 11 display components; `BankPrivacyToggle` control | Policy for when privacy is forced; preference persistence |
| Screenshot protection | `BankAppSwitcherPrivacyOverlay`: Dart-side blur or placeholder on app-switcher | `FLAG_SECURE` on Android, iOS capture handling, device-posture checks |
| Input integrity | `BankMaskedInputField`: ISO 13616 mod-97 for IBAN, Luhn for PAN | Server-side revalidation of everything |

## 1. PSD2 / SCA dynamic linking: display side only

Kit provides, verified in `lib/src/auth/bank_sca_approval_sheet.dart`:

- The amount and payee remain on screen for the entire authentication and
  cannot be scrolled away; the amount is deliberately rendered without the
  scope privacy mask even when `BankUiScopeData.privacyEnabled` is true.
- `BankScaApprovalSheet.show` sets `isDismissible: false` and
  `enableDrag: false`; the sheet resolves only `true` (approved) or `false`
  (rejected or expired), with no dismiss-without-decision path.
- Three methods (`BankScaMethod.biometric`, `.pin`, `.pushConfirm`) behind
  one typed callback, `BankScaApproveCallback = Future<bool>
  Function(BankScaMethod method, String? pin)`; a `false` return clears the
  PIN entry and surfaces the error state.
- An `expiresAt` countdown chip that auto-resolves `false` at zero.

Host implements, and the kit will never claim these:

- Generation of the authentication code specific to the amount and payee
  (RTS (EU) 2018/389 Article 5(1)) and its invalidation when either changes;
  the sheet displays what the host binds and performs no cryptography.
- Failed-attempt counting and lockout. Article 4(3)(b) caps consecutive
  failures at five; the sheet deliberately does not count attempts, so the
  count lives where it can be enforced.
- Server-side expiry: the countdown is a display, the timeout that matters
  is enforced in the authorization backend.
- Channel security, device binding, and out-of-band code delivery.

`BankTransferLimitManager` (`lib/src/payments/bank_transfer_limit_manager.dart`)
follows the same split: the host presents the SCA challenge for limit
raises; the widget only surfaces the request.

## 2. Consent capture and audit receipts

Kit provides: `BankConsentModal` (`lib/src/onboarding/bank_consent_modal.dart`)
gates the accept action behind two explicit conditions, scrolled to the
bottom of the terms and a checked acknowledgement box.
`BankConsentManagementList` (`lib/src/onboarding/bank_consent_management_list.dart`)
renders granted open-banking consents from a typed `BankConsent` model
(`id`, `granteeName`, `scopes`, `grantedAt`, `state`, `expiresAt`), puts
revocation behind a confirmation dialog wired to
`Future<bool> Function(String consentId)`, warns inside 14 days of expiry,
and keeps revoked entries struck-through for audit visibility.

Current position: `onAccept` and `onDecline` on
`BankConsentModal` are `VoidCallback`s; no typed consent event with
document id, version, and acceptance instant is emitted yet, so
constructing and retaining the audit receipt is a host duty today.
Committed direction: an additive typed consent-event payload (document id,
version, UTC accepted-at, locale), targeted at v0.3.0 (2026-10-31); until
it ships, the README may not use the phrase "audit receipts".

## 3. CoP / VoP and APP-fraud surfaces

Kit provides: the `isVerified` field on `BankBeneficiary`
(`lib/src/models/beneficiary.dart`), rendered as a verified badge in
`BankBeneficiaryPicker`; the confirm-before-send `BankTransferReviewCard`
with an `additionalInfo` slot for name-check or liability copy;
`BankFraudAlertBanner` (`lib/src/states/bank_fraud_alert_banner.dart`),
which offers no swipe-to-dismiss and keeps the protective action primary;
`BankCallVerificationScreen`, an anti-vishing status surface whose state is
always supplied by the host because the package never inspects telephony;
and `BankPanicFreezeButton` with a 1,500 ms press-and-hold default. The
full Confirmation of Payee journey (match, close match, no match, mismatch
liability copy, first-payee scam interstitial) is specified in
`doc/banking-journeys.md`.

Current position: no tri-state name-check result widget and no
scam-questionnaire interstitial ship at 0.1.0; `isVerified` is binary.
Committed direction: both components, targeted at v0.4.0 (2026-12-31).
Host implements regardless: the CoP (Pay.UK) or VoP (EPC) API call, match
classification, liability wording, cooling-off for new payees, risk
scoring, payment holds, and reimbursement handling.

## 4. Deposit-protection notices

Kit provides: `BankMoneyProtectionBanner`
(`lib/src/common/bank_money_protection_banner.dart`), deliberately
non-dismissible so the notice cannot be closed away, with `schemeName`
interpolation, a full `message` override for localisation, a 24 x 24
`schemeLogo` slot for the official mark, subtle and prominent
treatments, and a merged semantics label for screen readers.

Host implements: correct scheme and coverage figures (FSCS GBP 85,000 in
the UK; EUR 100,000 under EU deposit-guarantee schemes; GCC schemes per
national regulator), eligibility qualifications, placement per regulator
guidance, and sign-off of the final wording. The default copy is an
English template, not approved wording.

## 5. Privacy mode: exact scope

Kit provides: `BankUiScopeData.privacyEnabled`
(`lib/src/scope/bank_ui_scope.dart`), flipped by `BankPrivacyToggle` or
`BankUiScopeController.setPrivacy` and consumed by 11 display components,
including `BankBalanceText` (masks to `BankUiStrings.balanceHidden`,
default '••••'), `BankAccountNumberText`, `BankAccountSwitcher`,
`BankSummaryStack`, `BankPeekBalance`, and `BankCashflowChart`.

Scope limits: this is an in-process visual mask, not
encryption and not an access control. `BankTransactionListTile` amounts do
not mask at 0.1.0, and `BankScaApprovalSheet` never masks because dynamic
linking requires the customer to see the amount. The host decides when
privacy is forced (before authentication, say) and persists the preference.

## 6. FLAG_SECURE and screenshot protection

Kit provides: `BankAppSwitcherPrivacyOverlay`
(`lib/src/auth/bank_app_switcher_privacy_overlay.dart`), a Dart-side
lifecycle observer that covers the child with a sigma-12 blur and scrim,
or a full placeholder, when `AppLifecycleState` becomes inactive or
paused, and absorbs pointer events while obscured.

Current position: the package sets no platform window
flags. It cannot and does not set Android `FLAG_SECURE`, does not block
screenshots or screen recording, and does not control the OS snapshot
beyond what the overlay paints before suspension. Host implements:
`FLAG_SECURE` in the Android activity, iOS screen-capture handling, and
root or jailbreak posture. There is no plan to add platform channels;
zero native code is a supply-chain property this document keeps.

## Per-jurisdiction notes

- EU: section 1 maps to RTS (EU) 2018/389 Articles 4 and 5; the kit covers
  the Article 5 display duty only. GDPR records of consent are host duties
  per section 2. Deposit notices use the EUR 100,000 DGS figure.
- UK: CoP responsibilities split per section 3. APP-fraud mandatory
  reimbursement (PSR rules in force since 7 October 2024) is entirely
  host-side, with the kit supplying the warning surfaces. FSCS wording
  rides on `BankMoneyProtectionBanner`. Consumer Duty comprehensibility is
  a host copy duty; every user-facing string in the kit is a constructor
  parameter or a `BankUiStrings` override.
- GCC: every widget is built and tested under RTL;
  `NumeralStyle.easternArabicIndic` renders Arabic-Indic numerals;
  `islamicFinanceMode` swaps APR for profit-rate labels; `BankShariahBadge`
  and the Heritage preset cover Sharia presentation; `BankEidLoginButton`
  surfaces national-eID login. Arabic copy and SAMA or CBUAE wording are
  host duties via the same overrides.

## What the README may and may not claim

May claim, with the qualifiers shown:

1. "Implements the PSD2 dynamic-linking display pattern: amount and payee
   stay visible and unmasked during authentication" (`BankScaApprovalSheet`).
2. "Open-banking consent capture and management surfaces"
   (`BankConsentModal`, `BankConsentManagementList`).
3. "Deposit-protection notice component with scheme-configurable copy."
4. "Privacy mode masks balances across 11 components."
5. "IBAN mod-97 and PAN Luhn checksum validation" (`BankMaskedInputField`).
6. "App-switcher privacy overlay", described as blur-on-background and
   nothing stronger, and "built to WCAG 2.1 AA targets" (no third-party
   audit exists at 0.1.0, so "certified" is excluded).

May not claim, until the named gap closes or ever:

1. "PSD2 compliant" or "SCA compliant". Compliance attaches to the bank's
   end-to-end flow, never to a widget.
2. "Prevents screenshots", "FLAG_SECURE", or any capture-blocking claim.
3. "Audit receipts" before the typed consent event ships (section 2).
4. "Confirmation of Payee support" in the present tense before the
   tri-state result component ships (section 3).
5. Attempt limits, lockout, fraud detection, or any server-enforced control.

One current README phrase, "Compliance-grade by default", exceeds this
policy and will be revised to "compliance-ready display layer" in the next
README change. This matrix is versioned with the repository; changes land
through the same pull-request review and CI gates as code.
