# Accessibility conformance statement

> **The formal artifact is [`acr/ACR.md`](./acr/ACR.md)**, with the
> machine-readable source of truth in [`acr/openacr.yaml`](./acr/openacr.yaml)
> (GSA [OpenACR](https://github.com/GSA/openacr) format, WCAG 2.1 + EN 301 549
> catalog). Hand that pair to a procurement or accessibility reviewer. This
> page is the engineering companion: how conformance is measured in this
> repository, what the current numbers are, and where the kit falls short.

This document states what `bank_ui_kit` v0.3.0 conforms to under WCAG 2.1
Level AA and EN 301 549, how that conformance is measured, where it falls
short today, and the dated plan to close each gap. It follows the same rule
as `doc/enterprise/versioning-and-releases.md`: where the kit has not yet
reached a stated target, this document says so and gives the committed
direction, not an aspiration dressed as fact.

Scope: the 173 exported widget classes across the four presets in
`lib/src/theme/presets/` (Studio, Bloom, Heritage, Voltage), each in light
and dark brightness. All figures below are measured against the source in
this repository, not against a design specification.

## Why an ACR, and who owns what

The European Accessibility Act (Directive (EU) 2019/882) has applied to
consumer banking services in the EU since 28 June 2025. Its technical standard
is EN 301 549, which incorporates WCAG 2.1 Level AA. **Liability sits with the
bank**, not with the component vendor — which is why banks now ask every vendor
for a current Accessibility Conformance Report at intake.

That division is the single most important thing to understand about this kit's
conformance position:

| The kit owns | The bank composing the kit owns |
|---|---|
| The semantics each widget emits — name, role, state | Screen titles and window structure |
| The colour pairs its tokens produce, in all 8 preset/brightness combinations | Any colour the bank overrides, and any colour placed behind kit content |
| Tap-target floors on kit controls | Focus order **across** a screen and between screens |
| The motion it plays, and its reduced-motion behaviour | Navigation structure, skip mechanisms, multiple ways to reach a screen |
| The vocabulary that makes identification consistent | Applying that vocabulary consistently across a journey |
| The strings it ships, via `BankUiStrings` | Locale declaration, translation, and all content strings |
| Confirm-before-commit *components* | Whether the money-movement **journey** has a review or reversal step |

Shipping accessible components does not make an application conformant. The ACR
records every criterion in the right-hand column as *Not Applicable* with the
reason stated, rather than claiming credit the kit has not earned.

## Current position in one paragraph

Screen-reader semantics are systematically built in: 285 `Semantics`
constructors across 140 of the 224 library files, 142 `button` traits,
24 `selected`/`toggled` state traits, 10 `header` traits across 8 files, and
live regions in 12 files. Those figures are counted the way
[`acr/ACR.md`](./acr/ACR.md#2-source-inspection) states, by matching each
`Semantics` constructor's own parentheses and reading its named arguments, so
the two documents print the same numbers from the same pass. Tap targets are
governed by a single token, `BankTokens.minTapTarget = 44`
(`lib/src/theme/tokens.dart`), referenced in 79
files and pinned by `test/design_tokens_test.dart`. Colour contrast now passes
AA in **all eight** preset/brightness combinations for every semantic text
role — the three colour gaps this document carried at v0.1.0 are closed and the
numbers are below. Eleven automated suites gate accessibility and the claims
made about it. What
still does not exist: **any screen-reader testing at all**, text-scale golden
coverage, explicit focus-traversal management, associated field labels, and an
independent audit. Each is a numbered roadmap item in
[`acr/ACR.md`](./acr/ACR.md#known-gaps-and-roadmap).

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
| `BankTransactionListTile` (`lib/src/transactions/bank_transaction_list_tile.dart`) | One merged label: merchant, amount, status | Default reading order | Amount colours pass AA on both canvases in all 8 combinations | Full-width tile | Inherits scaling |
| `BankPressable` (`lib/src/common/bank_pressable.dart`) | `button` + `enabled` on every wrapped surface; optional `semanticLabel` | Enter/Space activate via `FocusableActionDetector`; 2 px focus ring drawn outside the child | State layer at theme opacities | Wraps the host surface | Inherits scaling |
| `BankAmountKeypad` (`lib/src/transfers/bank_amount_keypad.dart`) | Every key labeled: digits, "Delete", "Decimal point"; display announces `{currency} {amount}` | Row-major, matches visual order | Key glyphs use `onSurface` on `surfaceVariant` | Keys default to 56 px height, above the 44 px floor | Fixed-height cells; does not grow with scale (gap G5) |
| `BankPinKeypad` (`lib/src/auth/bank_pin_keypad.dart`) | Digit, delete, and biometric keys labeled | Telephone-keypad order | As above | Above 44 px floor | Fixed square keys (gap G5) |
| `BankTextField` (`lib/src/common/bank_text_field.dart`) | **Label and error render as sibling `Text` widgets, not through `InputDecoration` — no programmatic association (gap G8)** | Standard Material focus | Error tint from `BankTokens.danger` | Material default height | Inherits scaling |
| `BankOtpInput` (`lib/src/auth/bank_otp_input.dart`) | `liveRegion` announces state changes; resend control labeled with countdown; `AutofillHints.oneTimeCode` | Input then resend | Preset text roles | Resend meets 44 px | Inherits scaling |
| `BankToastBanner` (`lib/src/states/bank_toast_banner.dart`) | `liveRegion: true` while visible, so toasts are announced without focus | Transient; does not steal focus | Preset text roles | Dismiss action meets 44 px | Inherits scaling |
| Sheet-based flows (`lib/src/saving/bank_pot_contribution_sheet.dart`, `lib/src/transactions/bank_transaction_filter_sheet.dart`) | Labeled controls; live regions for result states | Top-to-bottom within sheet | Preset text roles | Chips and steppers constrained to `BankTokens.minTapTarget` | Inherits scaling |

Focus order: the kit contains zero `FocusTraversalGroup`
usages. Traversal is Flutter's default reading-order policy, which matches
the visual order in every shipped layout because the widget tree is built in
reading order. Explicit traversal groups for composite widgets are gap G4.

**Announcement is declared, never observed.** Every row above describes a
semantics node that exists in the tree. No row claims that a screen reader
speaks it, because no TalkBack or VoiceOver session has been run against this
kit (gap G9).

## Contrast per preset per brightness

Ratios computed with the WCAG 2.1 relative-luminance formula from the
resolved `BankThemeData` of each preset, and re-derived on every CI run by
`test/accessibility_contrast_test.dart` (92 test cases) and independently by
`test/accessibility_conformance_test.dart`. AA thresholds: 4.5:1 normal text,
3.0:1 large text and UI components.

| Pair | Studio L | Studio D | Bloom L | Bloom D | Heritage L | Heritage D | Voltage L | Voltage D |
|---|---|---|---|---|---|---|---|---|
| `onSurface` / `surface` | 17.01 | 12.82 | 16.24 | 11.37 | 16.99 | 14.21 | 13.13 | 15.08 |
| `onSurfaceVariant` / `surface` | 5.99 | 6.33 | 4.83 | 6.43 | 4.96 | 7.44 | 5.84 | 6.71 |
| `onPrimary` / `primary` | 4.68 | 5.59 | 5.85 | 6.92 | 7.34 | 5.29 | 5.70 | 5.70 |
| `onBackground` / `background` | 16.28 | 15.30 | 15.56 | 12.87 | 15.85 | 15.80 | 15.12 | 16.87 |
| `positiveBalance` / `surface` | 5.48 | 7.28 | 5.48 | 6.69 | 5.48 | 5.55 | 7.71 | 8.85 |
| `negativeBalance` / `surface` | 5.62 | 5.06 | 5.62 | 4.65 | 5.62 | 5.97 | 5.36 | 6.15 |
| `pending` / `surface` | 5.02 | 8.38 | 5.02 | 7.71 | 5.02 | 9.90 | 8.88 | 10.19 |
| `frozen` / `surface` | 3.26 | 4.29 | 3.26 | 3.95 | 3.26 | 5.07 | 4.54 | 5.22 |

Every text pair clears 4.5:1 in every combination; the tightest is 4.65:1
(Bloom dark `negativeBalance`). The muted `frozen` state clears the 3.0:1
non-text floor everywhere, tightest at 3.26:1. Gaps G1, G2, and G3 from the
v0.1.0 edition of this document are **closed**.

What these numbers do *not* cover, and why 1.4.3 is still reported as
*Partially Supports*: the gate measures **token pairs, not rendered pixels**.
Text drawn over `cardSurfaceGradient` or `accentGradient` (Voltage, Bloom) and
over the generative `BankCardPattern` overlays is unmeasured, and colours an
adopter supplies are not gated at all. The keyboard focus ring is a second
ungated non-text contrast: it paints `primary` at `BankTokens.focusRingOpacity`
(0.4) over whatever sits behind it, so its composited ratio is unknown (gap G6).

## Test methodology and CI gating

What runs today on every push and pull request
(`.github/workflows/ci.yml`, Flutter 3.44.4): `dart format` verification,
`flutter analyze`, design-token sync, the full suite under `test/`, and the
example web build.

Eleven suites gate accessibility specifically. They are the same eleven listed
as automated gates in [`acr/ACR.md`](./acr/ACR.md#evaluation-methods), stated
here as what fails the build rather than as what each one proves:

| Suite | What fails the build |
|---|---|
| `test/accessibility_contrast_test.dart` | Any semantic colour role dropping below 4.5:1 for text, or the `frozen` state below 3.0:1, in any of the 8 preset/brightness combinations |
| `test/accessibility_widget_test.dart` | `iOSTapTargetGuideline` or `labeledTapTargetGuideline` failing on a representative interactive composition |
| `test/accessibility_targets_test.dart` | An individually audited control dropping below 44 px on either axis, a consent gate that cannot be ticked yet rendering as though it can, a slider losing its role, its value or its adjust actions, the OTP field encoding focus twice or signalling error by hue alone, a picker value reading like a placeholder, the confidence meter losing its wording, or the IBAN copy stopping its visible or audible confirmation |
| `test/sheet_presentation_test.dart` | The grab handle losing its semantics, appearing on a non-draggable flow, or the sheet transition ignoring reduced motion |
| `test/sheet_handle_semantics_test.dart` | Any of the 14 sheet bodies that paints its own ground rendering a handle with an empty semantics label |
| `test/identity_system_test.dart` | A tappable emblem inside `BankEmblemStack` falling below 44 px on either axis at the tightest rung, or a purely decorative group growing past one disc |
| `test/app_chrome_test.dart` | `BankSliverAppBar` announcing its heading more than once, or carrying a second, unlabelled header node beside the title |
| `test/async_states_test.dart` | The skeleton ticker running under reduced motion, or a state change failing to reach the platform accessibility channel |
| `test/design_tokens_test.dart` | `BankTokens.minTapTarget` drifting from 44, or interaction tokens drifting from the DTCG source |
| `test/privacy_mask_test.dart` | The privacy mask changing the pixels without changing the announced label, or an unmasked balance leaking into the semantics tree |
| `test/accessibility_conformance_test.dart` | Any claim in the ACR ceasing to match the code — see below |

`test/widgets_smoke_test.dart` and `test/parity_widgets_smoke_test.dart` pump
components under all four presets, which catches layout exceptions but does not
assert accessibility properties.

### How the ACR is kept truthful

`test/accessibility_conformance_test.dart` is the ratchet that stops the ACR
from drifting into fiction. It parses `acr/openacr.yaml` offline — no network,
no YAML dependency — and enforces five properties:

1. **No silent drift.** The report's product version tracks `pubspec.yaml`, the
   criteria set is asserted to be exactly WCAG 2.1 Level A + AA (so an
   inconvenient row cannot be quietly deleted), and every file path cited as
   evidence must still exist. Renaming a widget file fails the build rather
   than turning a remark into fiction.
2. **No unbacked "Supports".** Every criterion claimed as *Supports* must be
   registered against either a named automated gate that runs in the same test,
   or an explicit manual-review marker. Adding a *Supports* row without doing
   one of those two things fails the build, and a stale registry entry fails it
   too.
3. **The gates still hold.** Contrast is recomputed across all eight
   combinations with an independently reimplemented WCAG formula, alongside the
   44 px tap-target token, the 150 ms motion floor, source scans behind every
   *Not Applicable* row (no media player, no keyboard shortcuts, no
   `SystemChrome`, no `DataTable`, no `TextScaler` override, no multipoint
   gestures, no non-font assets), and two behavioural claims driven against
   real widgets: pointer cancellation and keyboard activation.
4. **No self-contradiction.** No roadmap item may sit in the ACR's open table
   and in its closed table at once, no open item may still be targeted at the
   version being shipped, and the G-numbered table in this document is held to
   the same rule.
5. **The printed figures are recomputed.** The library-file, `Semantics`,
   trait, tap-target, reduced-motion, modal-surface, and widget-class counts
   are derived from the tree on every run and matched against what this
   document, the ACR, `openacr.yaml`, the README, and the CHANGELOG each
   print. That is what keeps this page and the ACR reporting one inventory
   rather than two.

### Committed additions

1. Text-scale goldens (v0.4.0): golden baselines at `TextScaler` 1.0, 1.3,
   1.5, and 2.0, on the v0.4.0 milestone dated 2026-12-31 in
   `doc/enterprise/versioning-and-releases.md`. Components
   that clip or overflow at 2.0 fail the build.
2. Keyboard-traversal assertions (v0.4.0), landing with the traversal groups
   in gap G4.
3. Rendered-pixel contrast for text over gradients and pattern overlays
   (v0.4.0), extending the existing contrast gate.

Items 1 and 2 were dated v0.3.0 in the previous edition. 0.3.0 has shipped
without them, so they are re-dated here rather than left pointing at a
released version. That is the same rule the ACR applies to its own roadmap.

## Known gaps and remediation dates

Dates align with the release milestones in
`doc/enterprise/versioning-and-releases.md`. A date that slips is re-dated
here by pull request, not silently missed. The same gaps appear, numbered
differently and mapped to individual EN 301 549 clauses, in
[`acr/ACR.md`](./acr/ACR.md#known-gaps-and-roadmap). The **ACR item** column
gives that mapping, so the two documents can be diffed row by row instead of
compared by eye.

Every row that was still open when 0.3.0 shipped is dated v0.4.0, 2026-12-31.
A v0.3.0 target was reachable only while 0.3.0 was unreleased; leaving one in
place would point a reader at a version that has already shipped. This is the
rule the ACR states for its own roadmap, applied here to the same gaps.

| ID | Gap | ACR item | Evidence | Remediation | Date |
|---|---|---|---|---|---|
| G1 | ~~Bloom light `onPrimary` on `primary` at 2.78:1~~ | — | Closed at v0.2.0; now 5.85:1 | — | Done |
| G2 | ~~Heritage dark `onPrimary` on `primary` at 4.44:1~~ | — | Closed at v0.2.0; now 5.29:1 | — | Done |
| G3 | ~~`positiveBalance` and `pending` failing on light surfaces~~ | — | Closed at v0.2.0; per-brightness variants, all ≥ 5.02:1 | — | Done |
| G4 | No explicit focus traversal; zero `FocusTraversalGroup` in `lib/` | 7 | Repository-wide search | Traversal groups for keypads, sheets, and `BankBottomNavBar`; keyboard-order assertions in tests | v0.4.0, 2026-12-31 |
| G5 | Fixed-height cells do not grow with text scale above roughly 1.5 | 5 | `lib/src/transfers/bank_amount_keypad.dart` (56 px keys), `lib/src/auth/bank_pin_keypad.dart` (fixed square) | Scale-aware minimum heights, verified by the 2.0-scale goldens | v0.4.0, 2026-12-31 |
| G6 | Focus-ring and hairline contrast unmeasured | 6 | `BankTokens.focusRingOpacity = 0.4` composited over an unknown background | Measure the composited ring against every preset background; raise the opacity or use an opaque ring where it fails; add to the contrast gate | v0.4.0, 2026-12-31 |
| G7 | No independent audit | 15 | This document | Audit plan below | v0.4.0, 2026-12-31 |
| G8 | `BankTextField` label and error are unassociated sibling `Text` widgets, so assistive technology ties neither to the field | 2 | `lib/src/common/bank_text_field.dart` | Route both through `InputDecoration`, keeping the visual treatment; announce errors as a live region | v0.4.0, 2026-12-31 |
| G9 | No screen-reader testing has ever been performed | 3 | `test/` contains no assistive-technology assertions, and none is possible in a headless suite | Manual TalkBack and VoiceOver passes over the example gallery in all four presets, findings filed as `accessibility` issues | v0.4.0, 2026-12-31 |
| G10 | No input widget except `BankOtpInput` can declare an autofill purpose (WCAG 1.3.5 **Does Not Support**) | 1 | `AutofillHints` appears in one file | Optional `autofillHints` parameter on `BankTextField`, `BankPhoneInputField`, `BankAmountInputField`, `BankAddressForm` | v0.4.0, 2026-12-31 |
| G11 | ~~`BankSkeletonLoader` ignores the reduced-motion preference and shimmers regardless~~ | 4 | Closed at v0.3.0: `lib/src/states/bank_skeleton_loader.dart` reads `MediaQuery.maybeDisableAnimationsOf`, stops its controller, and drops the `ShaderMask` | — | Done |
| G12 | `MediaQuery.boldText`, `highContrast`, and `accessibleNavigation` are read nowhere | 9 | Repository-wide search | Read them in the theme resolver; a high-contrast token variant per preset | v0.4.0, 2026-12-31 |
| G13 | Section titles inside widget bodies lack the `header` trait; the kit carries 10 `header` traits across 8 files, against 173 widget classes | 10 | Named-argument count over every `Semantics` constructor in `lib/` | `header: true` on every widget rendering a section title | v0.4.0, 2026-12-31 |
| G14 | The swipe-actioned row (`Dismissible`, **1 file**, `lib/src/notifications/bank_in_app_notification_center.dart`) has no keyboard or assistive-technology equivalent | 8 | Repository-wide search. The "4 files" this row printed at v0.3.0 came from a substring scan that also matched the unrelated `isDismissible` sheet parameter | Expose the same actions as semantics actions and as a visible affordance | v0.4.0, 2026-12-31 |
| G15 | Four sliders in `BankLoanCalculatorCard` and `BankSavingsProjectionCard` sit inside `excludeSemantics: true`, so the limit they set can be neither read nor changed by assistive technology | 19 | `lib/src/credit/bank_loan_calculator_card.dart`, `lib/src/saving/bank_savings_projection_card.dart` | Apply the pattern the other three slider surfaces adopted in 0.3.0, and extend the slider gate in `test/accessibility_targets_test.dart` to both files | v0.4.0, 2026-12-31 |
| G16 | Ten icon-only `IconButton`s expose no accessible name | 20 | `lib/src/business/bank_batch_payment_review_sheet.dart`, `lib/src/cards/bank_travel_notice_form.dart`, `lib/src/support/bank_help_faq_list.dart` (3), `lib/src/support/bank_dispute_wizard_sheet.dart` (3), `lib/src/support/bank_secure_message_thread.dart`, `lib/src/insights/bank_recurring_merchant_tile.dart` | A `tooltip` or a themed `semanticLabel` on each, plus a `labeledTapTargetGuideline` composition covering them | v0.4.0, 2026-12-31 |
| G17 | ~~14 sheet bodies drew their own 40×4 grab bar with no semantics node~~ | 18 | Closed at v0.3.0: all 14 route through `BankSheetHandle`, gated by `test/sheet_handle_semantics_test.dart` | — | Done |

~~G-numbered rows struck through~~ are closed; they are kept so a reader can
audit what this document claimed before and what happened to it. G11 and G17
closed in this release. G11 in particular was still printed as open in the
0.3.0 draft of this table after the fix had landed and after the ACR had
recorded it as closed, which is the drift this pair of documents exists to
prevent, so it is noted rather than quietly corrected.

## Formal ACR

The VPAT-style skeleton this document used to carry has been replaced by a real
report:

- **[`acr/ACR.md`](./acr/ACR.md)** — human-readable, VPAT-style: product
  identity, evaluation methods, conformance tables for WCAG 2.1 Level A and AA
  and the EN 301 549 chapters that apply to a component library, and a
  labelled known-gaps roadmap.
- **[`acr/openacr.yaml`](./acr/openacr.yaml)** — machine-readable, in the GSA
  OpenACR schema against the `2.4-edition-wcag-2.1-508-eu-en` catalog, so a
  procurement system can diff it against another vendor's report instead of
  reading prose.

Both are re-issued with every minor release, and both are gated by
`test/accessibility_conformance_test.dart`.

The headline positions, so a reader knows what to expect before opening it:
most criteria are *Partially Supports* with the mechanism and the gap both
named; two are *Does Not Support* (WCAG 1.3.5 Identify Input Purpose, EN 301
549 clause 11.5.2.8 Label relationships); and *Supports* is used only where an
automated gate proves it or the reason is structural. **No claim anywhere in
the ACR depends on screen-reader behaviour**, because none has been tested.

## Independent audit plan and status

Status: **no external audit has been performed** as of v0.3.0. Everything in
the ACR is a self-assessment by the maintainers. The committed plan:

1. Internal pre-audit (by 2026-12-31, alongside v0.4.0): text-scale goldens
   plus manual TalkBack and VoiceOver passes over the example screens in
   `example/lib/screens/`, with findings tracked as issues labeled
   `accessibility`. This closes G9 and converts the 11.5.2 clauses in the ACR
   from "declared" to "observed", in whichever direction the evidence points.
   It was dated alongside v0.3.0 in the previous edition and did not happen,
   so it moves rather than staying pinned to a released version.
2. External audit (by 2026-12-31, alongside v0.4.0): a WCAG 2.1 AA and
   EN 301 549 assessment of the example gallery
   (`example/lib/gallery_main.dart`) by an independent accessibility firm,
   covering all four presets in both brightnesses on iOS and Android.
3. Publication: the audit report, the resulting re-issued ACR, and the
   remediation log are published in `acr/`; unresolved findings enter the gap
   table above with dates.

This document is versioned with the repository; changes land through the
same pull-request review and CI gates as code.
