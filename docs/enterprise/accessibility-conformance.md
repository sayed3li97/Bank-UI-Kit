# Accessibility Conformance Statement

This document states what `bank_ui_kit` v0.1.0 conforms to under WCAG 2.1
Level AA and EN 301 549, how that conformance is measured, where it falls
short today, and the dated plan to close each gap. It follows the same rule
as `docs/enterprise/versioning-and-releases.md`: where the kit has not yet
reached a stated target, this document says so and gives the committed
direction, not an aspiration dressed as fact.

Scope: the 141 exported widgets across the four presets in
`lib/src/theme/presets/` (Studio, Bloom, Heritage, Voltage), each in light
and dark brightness. All figures below are measured against the source in
this repository, not against a design specification.

## Current position in one paragraph

Screen-reader semantics are systematically built in: 259 `Semantics`
constructors across 121 of the 192 library files, 111 `button: true` traits,
56 state traits (`selected`, `toggled`, `header`, `textField`), and live
regions in 11 files. Tap targets are governed by a single token,
`BankTokens.minTapTarget = 44` (`lib/src/theme/tokens.dart`), consumed in 64
files. Text contrast passes AA in all eight preset/brightness combinations
for body text; three specific color pairs fail and are listed with dates
below. What does not exist yet: automated accessibility assertions in
`test/`, text-scale golden coverage, explicit focus-traversal management,
and an independent audit. Each has a committed milestone.

## Per-component conformance matrix

Two kit-wide rules apply before the per-component rows:

1. Composite widgets collapse to a single announced node via
   `Semantics(label: ..., excludeSemantics: true)`, so a transaction row
   reads as one sentence, not five fragments. Example:
   `lib/src/transactions/bank_transaction_list_tile.dart` announces
   merchant, amount, and status as one label.
2. User-facing strings, including semantic labels such as the privacy mask,
   route through `BankUiStrings` (`lib/src/scope/bank_ui_strings.dart`), so
   adopters can localize announcements, including Arabic with
   Eastern Arabic-Indic numerals (`lib/src/theme/numeral_style.dart`).

Representative rows; the same construction patterns govern the full set.

| Component (source) | Semantics | Focus order | Contrast | Tap targets | Dynamic type |
|---|---|---|---|---|---|
| `BankBalanceText` (`lib/src/accounts/bank_balance_text.dart`) | Single node, "Balance: {amount}"; announces "Balance hidden" when `BankUiScope.privacyEnabled` | Non-interactive | `onSurface` on `surface`, 11.37:1 to 17.01:1 across presets | N/A | Inherits `MediaQuery` scaling; single line ellipsizes |
| `BankTransactionListTile` (`lib/src/transactions/bank_transaction_list_tile.dart`) | One merged label: merchant, amount, status | Default reading order | Amount colors on light surfaces are a known gap (see below) | Full-width tile | Inherits scaling |
| `BankAmountKeypad` (`lib/src/transfers/bank_amount_keypad.dart`) | Every key labeled: digits, "Delete", "Decimal point"; display announces `{currency} {amount}` | Row-major, matches visual order | Key glyphs use `onSurface` on `surfaceVariant` | 88 x 56 px keys, above the 44 px floor | Fixed-height cells; does not grow with scale (gap G5) |
| `BankPinKeypad` (`lib/src/auth/bank_pin_keypad.dart`) | Digit, delete, and biometric keys labeled | Telephone-keypad order | As above | Above 44 px floor | Fixed-height cells (gap G5) |
| `BankOtpInput` (`lib/src/auth/bank_otp_input.dart`) | `liveRegion` announces state changes; resend control labeled with countdown | Input then resend | Preset text roles | Resend meets 44 px | Inherits scaling |
| `BankToastBanner` (`lib/src/states/bank_toast_banner.dart`) | `liveRegion: true` while visible, so toasts are announced without focus | Transient; does not steal focus | Preset text roles | Dismiss action meets 44 px | Inherits scaling |
| Sheet-based flows (`lib/src/saving/bank_pot_contribution_sheet.dart`, `lib/src/transactions/bank_transaction_filter_sheet.dart`) | Labeled controls; live regions for result states | Top-to-bottom within sheet | Preset text roles | Chips and steppers constrained to `BankTokens.minTapTarget` | Inherits scaling |

Focus order, stated honestly: the kit contains zero `FocusTraversalGroup`
usages. Traversal is Flutter's default reading-order policy, which matches
the visual order in every shipped layout because the widget tree is built in
reading order. Explicit traversal groups for composite widgets are gap G4.

## Contrast per preset per brightness

Ratios computed with the WCAG 2.1 relative-luminance formula from the
constants in `lib/src/theme/presets/{studio,bloom,heritage,voltage}.dart`.
AA thresholds: 4.5:1 normal text, 3.0:1 large text and UI components.

| Pair | Studio L | Studio D | Bloom L | Bloom D | Heritage L | Heritage D | Voltage L | Voltage D |
|---|---|---|---|---|---|---|---|---|
| `onSurface` / `surface` | 17.01 | 12.82 | 16.24 | 11.37 | 16.99 | 14.21 | 13.13 | 15.08 |
| `onSurfaceVariant` / `surface` | 5.99 | 6.33 | 4.83 | 6.43 | 4.96 | 7.44 | 5.84 | 6.71 |
| `onPrimary` / `primary` | 4.68 | 5.59 | **2.78** | 6.92 | 7.34 | **4.44** | 5.70 | 5.70 |

Body and secondary text pass 4.5:1 in all eight combinations. The two bold
figures fail and are gaps G1 and G2 below. Status colors
(`BankTokens.positiveBalance`, `pending` in `lib/src/theme/tokens.dart`)
measure 2.26:1 and 2.03:1 on white and are gap G3.

## Test methodology and CI gating

What runs today on every push and pull request
(`.github/workflows/ci.yml`, Flutter 3.27.1): `dart format` verification,
`flutter analyze`, the six suites under `test/`, and the example web build.
`test/widgets_smoke_test.dart` and `test/parity_widgets_smoke_test.dart`
pump components under all four presets, which catches layout exceptions but
does not assert accessibility properties.

Stated plainly: `test/` contains no `meetsGuideline` assertions and no
golden files today. The committed methodology, gated in CI so a regression
fails the build:

1. Guideline assertions (v0.2.0): `textContrastGuideline`,
   `androidTapTargetGuideline`, and `labeledTapTargetGuideline` via
   `flutter_test`'s `meetsGuideline`, run across all four presets in both
   brightnesses inside the existing preset loop pattern of
   `test/widgets_smoke_test.dart`.
2. Semantics assertions (v0.2.0): label-content checks for the merged-node
   components in the matrix above, extending the smoke suites.
3. Text-scale goldens (v0.3.0): golden baselines at `TextScaler` 1.0, 1.3,
   1.5, and 2.0 using the `alchemist ^0.10.0` dev dependency already in
   `pubspec.yaml`, on the same v0.3.0 golden-baseline milestone dated
   2026-10-31 in `docs/enterprise/versioning-and-releases.md`. Components
   that clip or overflow at 2.0 fail the build.

## Known gaps and remediation dates

Dates align with the release milestones in
`docs/enterprise/versioning-and-releases.md`. A date that slips is re-dated
here by pull request, not silently missed.

| ID | Gap | Evidence | Remediation | Date |
|---|---|---|---|---|
| G1 | Bloom light `onPrimary` on `primary` measures 2.78:1, below the 3.0:1 UI-component minimum | `lib/src/theme/presets/bloom.dart`, `#FF6B6B` under white | Darken Bloom light primary to reach 4.5:1; record as a breaking token change in `CHANGELOG.md` | v0.2.0, 2026-08-31 |
| G2 | Heritage dark `onPrimary` on `primary` measures 4.44:1; passes 3.0:1 for large text and components, fails 4.5:1 for normal text | `lib/src/theme/presets/heritage.dart` | Adjust `onPrimary` `#003822` toward higher contrast | v0.2.0, 2026-08-31 |
| G3 | `positiveBalance` (2.26:1) and `pending` (2.03:1) fail on light surfaces; amounts pair color with sign and text so information is not color-only, but the text itself is low-contrast | `lib/src/theme/tokens.dart` | Per-brightness status variants in `BankThemeData`, dark-shifted for light surfaces | v0.2.0, 2026-08-31 |
| G4 | No explicit focus traversal; zero `FocusTraversalGroup` in `lib/` | Repository-wide search | Traversal groups for keypads, sheets, and `BankBottomNavBar`; keyboard-order assertions in tests | v0.3.0, 2026-10-31 |
| G5 | Fixed-height cells (keypad keys at 88 x 56 px) do not grow with text scale above roughly 1.5 | `lib/src/transfers/bank_amount_keypad.dart`, `lib/src/auth/bank_pin_keypad.dart` | Scale-aware minimum heights; verified by the 2.0-scale goldens | v0.3.0, 2026-10-31 |
| G6 | No automated accessibility assertions in CI | `test/` contents | Methodology items 1 and 2 above, gated in `.github/workflows/ci.yml` | v0.2.0, 2026-08-31 |
| G7 | No independent audit | This document | Audit plan below | v0.4.0, 2026-12-31 |

## VPAT-style ACR skeleton

Compliance teams filing an Accessibility Conformance Report (VPAT 2.5, WCAG
edition, with the EN 301 549 tables) can start from the pre-filled positions
below. EN 301 549 clause 9 mirrors WCAG 2.1; clause 11 applies the same
criteria to non-web software, which is the relevant table for Flutter
mobile targets. Terms: Supports, Partially Supports, Does Not Support,
Not Applicable.

| Criterion (WCAG 2.1 / EN 301 549 clause 11 counterpart) | Level | Position at v0.1.0 | Remarks |
|---|---|---|---|
| 1.1.1 Non-text Content | A | Supports | Icons paired with text or wrapped in labeled `Semantics`; decorative art excluded via `excludeSemantics` |
| 1.3.1 Info and Relationships | A | Supports | Merged semantic nodes carry role traits (`button`, `header`, `textField`) |
| 1.4.1 Use of Color | A | Supports | Amounts carry sign and status text alongside color |
| 1.4.3 Contrast (Minimum) | AA | Partially Supports | Body text passes in all 8 preset/brightness pairs; G1, G2, G3 open until 2026-08-31 |
| 1.4.4 Resize Text | AA | Partially Supports | Text inherits platform scaling; fixed-height cells clip above ~1.5 (G5, due 2026-10-31) |
| 1.4.11 Non-text Contrast | AA | Partially Supports | Bloom light primary at 2.78:1 (G1) |
| 2.1.1 Keyboard | A | Supports | All interactive widgets are focusable Material controls |
| 2.4.3 Focus Order | A | Partially Supports | Default reading-order traversal; explicit groups due 2026-10-31 (G4) |
| 2.5.5 Target Size (AAA, reported for banking procurement) | AAA | Supports | `BankTokens.minTapTarget = 44`, enforced in 64 files |
| 4.1.2 Name, Role, Value | A | Supports | 259 `Semantics` nodes, state traits, live regions in 11 files |
| 4.1.3 Status Messages | AA | Supports | `liveRegion` in `BankToastBanner`, `BankOtpInput`, `BankConnectivityBanner`, `BankSessionTimeoutDialog`, others |

Positions marked Partially Supports convert to Supports when the referenced
gap closes; the ACR is re-issued with each minor release from v0.2.0.

## Independent audit plan and status

Status: no external audit has been performed as of v0.1.0. The committed
plan:

1. Internal pre-audit (by 2026-10-31, alongside v0.3.0): full run of the
   guideline assertions and text-scale goldens, plus manual TalkBack and
   VoiceOver passes over the 14 example screens in `example/lib/screens/`,
   with findings tracked as issues labeled `accessibility`.
2. External audit (by 2026-12-31, alongside v0.4.0): a WCAG 2.1 AA and
   EN 301 549 assessment of the example gallery
   (`example/lib/gallery_main.dart`) by an independent accessibility firm,
   covering all four presets in both brightnesses on iOS and Android.
3. Publication: the audit report, the resulting ACR, and the remediation
   log are published in this directory; unresolved findings enter the gap
   table above with dates.

This document is versioned with the repository; changes land through the
same pull-request review and CI gates as code.
