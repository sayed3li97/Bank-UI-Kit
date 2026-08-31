# bank_ui_kit Accessibility Conformance Report

**Product**: `bank_ui_kit` — a themeable Flutter UI component library for
mobile banking and fintech apps.
**Version covered**: 0.3.0
**Report date**: 2026-08-24
**Report version**: 2 (re-issued for 0.3.0; see [What changed since 0.2.0](#what-changed-since-020))
**Standards**: WCAG 2.1 Level A and AA; EN 301 549 V3.2.1 (2021-03)
**Author**: bank_ui_kit maintainers ·
[issue tracker](https://github.com/sayed3li97/bank-ui-kit/issues)
**Machine-readable source of truth**: [`openacr.yaml`](./openacr.yaml)
(GSA [OpenACR](https://github.com/GSA/openacr) format, catalog
`2.4-edition-wcag-2.1-508-eu-en`)

> **This is a self-assessment, not a third-party audit.** No independent
> accessibility firm has assessed this package. Read the
> [Evaluation methods](#evaluation-methods) section before you rely on any row
> in the tables below, and the [Known gaps](#known-gaps-and-roadmap) section
> before you decide this package is fit for your journey.

---

## Why this document exists

The European Accessibility Act (Directive (EU) 2019/882) has applied to
consumer banking services in the EU since 28 June 2025. Its technical standard
is EN 301 549, which incorporates WCAG 2.1 Level AA. Liability sits with the
**bank**, not with the component vendor — which is exactly why banks now ask
every vendor for a current Accessibility Conformance Report at intake.

Most open-source component libraries cannot produce one honestly, because they
have no evidence: no contrast gate, no tap-target gate, no accessible-label
gate, nothing that would fail a build. This package does have those gates, and
they run on every push. That is the only reason this report can be written
without guessing — and it is also the reason the report is candid about the
large areas where evidence does *not* exist.

## Scope of this report

**In scope.** The `bank_ui_kit` package at version 0.3.0: 173 widget classes
across four design presets (Studio, Bloom, Heritage, Voltage), each in light
and dark brightness, evaluated as **non-web software** — EN 301 549 chapter 11
— on the iOS and Android targets.

**Out of scope.** Flutter web and desktop builds. The example gallery compiles
for the web to produce screenshots, but no web build has been evaluated for
accessibility and none is claimed. EN 301 549 chapter 9 (Web) is therefore
reported as out of scope, not as conforming. Evaluating it means evaluating
Flutter's web semantics output, which is a separate exercise.

Section 508 chapters 3–6 are also out of scope for this edition. The WCAG
tables below are shared between the two standards, so a Section 508 edition
can be issued from the same evidence on request.

## Division of responsibility

This is the part a bank's accessibility lead should read twice.

A component library can only be conformant for the properties it owns:

| The kit owns | The bank composing the kit owns |
|---|---|
| Semantics a widget emits — name, role, state | Screen titles and window structure |
| Colour pairs its tokens produce, in 8 preset/brightness combinations | Any colour the bank overrides, and any colour behind kit content |
| Tap-target floors on kit controls | Focus order **across** a screen and between screens |
| Motion the kit plays, and its reduced-motion behaviour | Navigation structure, skip mechanisms, multiple ways to reach a screen |
| The vocabulary that makes identification consistent | Applying that vocabulary consistently across the journey |
| Strings the kit ships, via `BankUiStrings` | Locale declaration, translation, and all content strings |
| Confirm-before-commit *components* | Whether the money-movement **journey** actually has a review or reversal step |

Criteria in the second column appear in the tables below as **Not Applicable**
with the reason stated. They are never recorded as "Supports". Shipping this
kit does not make an application conformant, and this report does not transfer
any EAA obligation from the service provider to the package maintainers.

---

## Evaluation methods

Three methods were used, in decreasing order of strength.

### 1. Automated gates, run on every push and pull request

These run in CI (`.github/workflows/ci.yml`, Flutter 3.44.4). A failure blocks
the build.

| Gate | File | What it proves |
|---|---|---|
| Contrast | `test/accessibility_contrast_test.dart` | Every semantic colour role clears 4.5:1 for text and 3.0:1 for the muted "frozen" state, in **all eight** preset/brightness combinations — 92 test cases |
| Tap target + accessible label | `test/accessibility_widget_test.dart` | Flutter's `iOSTapTargetGuideline` and `labeledTapTargetGuideline` over a representative interactive composition |
| Audited controls | `test/accessibility_targets_test.dart` | Named controls hold 44 px in **both** dimensions. Two compositions carry that assertion: the first is LTR, light, Studio and holds the insight-card dismiss, the IBAN copy row, the country picker and the address-form edit button; the second repeats the insight card, the account card and the OTP field in RTL on Voltage dark. The consent tick boxes are measured separately, in LTR light. The same file also asserts that a consent gate that cannot be ticked yet reads as disabled; that a slider keeps its adjustable role, its value and both adjust actions; that the OTP field encodes focus with one signal and its error state is distinguishable without colour; that picker values are typographically distinct from placeholders; that the confidence meter is labelled and spelled out; and that the IBAN copy confirms **visibly and audibly** |
| Sheet presentation | `test/sheet_presentation_test.dart` | The grab handle renders and carries semantics, is omitted on non-draggable flows, and reduced motion collapses the sheet transition |
| Sheet handles | `test/sheet_handle_semantics_test.dart` | Each of the 14 sheet bodies that paints its own ground renders a handle whose semantics label is non-empty; `BankDisclosureConsentSheet` asked for `showHandle: false` still draws none; the handle stays centred under RTL |
| Identity stack | `test/identity_system_test.dart` | A tappable emblem inside `BankEmblemStack`, and its `+N` overflow disc, keep 44 px on both axes at the `xSmall` rung, which is the tightest one and the rung the size ladder documents for stacked rails; a group with nothing tappable in it stays exactly one disc tall |
| App chrome | `test/app_chrome_test.dart` | `BankSliverAppBar` announces its heading exactly once at both ends of the collapse, and carries exactly one header node, labelled, at each end |
| Async + skeleton states | `test/async_states_test.dart` | Reduced motion stops the shimmer ticker and drops the mask; a state change reaches the platform accessibility channel, and stays silent on first build and where the platform cannot announce |
| Tap-target token | `test/design_tokens_test.dart` | `BankTokens.minTapTarget` is pinned at 44 |
| Privacy semantics | `test/privacy_mask_test.dart` | The privacy mask changes what is **announced**, not only what is drawn — and no unmasked balance label leaks into the semantics tree |
| This report | `test/accessibility_conformance_test.dart` | Every claim below still matches the code and the gates; see [How this report is kept honest](#how-this-report-is-kept-honest) |

### 2. Source inspection

All 224 library files were inspected for the mechanisms named in the remarks:
285 `Semantics` constructors across 140 files, 142 button-role traits, 10 header
traits across 8 files, 24 selected/toggled state traits, 12 files using
`liveRegion`, 4 `SemanticsService.sendAnnouncement` call sites, 62
`excludeSemantics: true` arguments plus 44 `ExcludeSemantics` widgets across 28
files, `BankTokens.minTapTarget` referenced in 79 files, and the platform
reduced-motion preference read in 40 files.

**Counting methodology**, stated so every figure above can be reproduced from a
checkout:

- **Widget classes (173)** — public classes extending `StatelessWidget` or
  `StatefulWidget` in files reachable from the package's exported libraries
  (`core.dart`, `saving.dart`, `social.dart`, `investing.dart`, `credit.dart`).
  This is the same basis as the 164 reported at 0.2.0; the nine added in 0.3.0
  are `BankSheetHandle`, `BankSheetHeader`, `BankSheetSurface`,
  `BankAsyncContent`, `BankSkeletonBox`, `BankEmblemStack`,
  `BankSegmentedControl`, `BankCountryFlag`, and `BankSliverAppBar`. `BankSheet`
  and `BankDialog` also shipped in 0.3.0 but are static presentation helpers,
  not widgets, so they are outside this count.
- **Library files (224)** — every `.dart` file under `lib/`.
- **`Semantics` constructors (285)** — literal `Semantics(` call sites in
  `lib/`, matched on a word boundary so that `ExcludeSemantics(`,
  `MergeSemantics(` and `BlockSemantics(` are not swept in.
- **Traits** — named arguments passed to those constructors, counted by
  matching the constructor's own parentheses rather than by grepping the
  argument name. Counting a trait any other way produces a different number:
  the loose figure of "48 selection traits" that appeared in one row of the
  0.2.0 edition of this document counted every `selected:` and `toggled:`
  argument in `lib/`, most of which belong to the kit's own widget
  constructors rather than to a semantics node. That row is corrected to 24
  below. On the same basis the trait totals are 142 `button`, 10 `header`, 24
  `selected`/`toggled`, and 12 `liveRegion`.
- **`excludeSemantics` (62)** — literal `excludeSemantics: true` arguments
  anywhere in `lib/`, which includes the kit's own widget parameters as well
  as `Semantics` call sites. `ExcludeSemantics` widgets (44 across 28 files)
  are counted separately, on a word boundary.
- **Reduced motion (40 files)** — files reading `MediaQuery`'s reduced-motion
  preference through any of `MediaQuery.disableAnimationsOf`,
  `MediaQuery.maybeDisableAnimationsOf`,
  `MediaQuery.of(context).disableAnimations`, or
  `MediaQuery.maybeOf(context)?.disableAnimations`. The first three spellings
  alone return 34; the fourth accounts for the other six. The 0.2.0 edition
  counted only the first spelling and so understated it, and the 0.3.0 edition
  first printed the recipe without the fourth, so the stated greps returned 34
  against a printed 40. One further file, `bank_e_signature_pad.dart`, names
  the preference only in a doc comment saying it owns no animation, and is
  excluded.

### 3. Manual review

Manual code review of the mechanisms above across all 224 library files, plus
sighted visual review of the example gallery (`example/lib/gallery_main.dart`)
in all four presets in both light and dark — evidenced by the rendered
screenshots committed under `doc/screenshots/`. **No assistive technology was
involved in that review.**

### What was NOT done

Stated plainly, because these absences bound every claim in this report:

- **No screen-reader testing.** Not TalkBack, not VoiceOver, not any other
  assistive technology. Nothing in this report claims a label is *announced* —
  only that a semantics node exists carrying it.
- **No testing above 1.0 text scale**, and no text-scale golden coverage.
- **No landscape or 400%-zoom testing.**
- **No switch-control, voice-control, or braille-display testing.**
- **No third-party audit.**

Where a criterion's outcome depends on any of the above, it is reported as
*Partially Supports* with the gap named — never as *Supports*.

### Conformance terms

The five terms are those defined by the OpenACR catalog:

| Term | Meaning |
|---|---|
| **Supports** | The functionality has at least one method that meets the criterion without known defects |
| **Partially Supports** | Some functionality does not meet the criterion |
| **Does Not Support** | The majority of the functionality does not meet the criterion |
| **Not Applicable** | The criterion is not relevant to the product |
| **Not Evaluated** | Not used in this report at any level |

---

## Table 1: WCAG 2.1 Success Criteria, Level A

Reported for the **Software** component.

| Criterion | Level | Conformance | Remarks |
|---|---|---|---|
| 1.1.1 Non-text Content | A | Partially Supports | Icons are paired with visible text or wrapped in a labelled `Semantics` node; decorative art is removed with `excludeSemantics` (62 arguments plus 44 `ExcludeSemantics` widgets); `BankPressable.semanticLabel` announces a whole surface. `BankInsightCard`'s confidence indicator, formerly three unlabelled dots, now renders a visible confidence level inside a labelled node — gated by *"confidence meter is labelled, valued, and spelled out"* in `test/accessibility_targets_test.dart`. Gated by `labeledTapTargetGuideline`. **Gap**: the gate covers a representative composition, not all 173 widget classes, and no lint forbids an unlabelled `Icon`. **Gap**: ten icon-only `IconButton` call sites in `lib/` pass no `tooltip`, no `Icon(semanticLabel:)` and sit under no labelled `Semantics` ancestor, so they reach assistive technology as an unnamed button. They are the cancel in `BankBatchPaymentReviewSheet`, the remove-destination in `BankTravelNoticeForm`, the clear-search and the two helpful-vote buttons in `BankHelpFaqList`, the back, close and remove-evidence buttons in `BankDisputeWizardSheet`, the attach button in `BankSecureMessageThread`, and the more-actions button in `BankRecurringMerchantTile`. See roadmap item 20. **Gap**: `BankSpendingBreakdownChart` adds no semantics node unless the host passes `semanticLabel`, so it is silent by default — unlike `BankCashflowChart` and `BankBudgetGaugeWidget`, which synthesise a summary. |
| 1.2.1 Audio-only / Video-only | A | Not Applicable | No audio, video, or media player is shipped. Gated: the conformance test fails if a media-player API appears in `lib/`. |
| 1.2.2 Captions (Prerecorded) | A | Not Applicable | Nothing to caption; see 1.2.1. |
| 1.2.3 Audio Description or Media Alternative | A | Not Applicable | Nothing to describe; see 1.2.1. |
| 1.3.1 Info and Relationships | A | Partially Supports | 285 `Semantics` constructors carry role and state traits; composite tiles collapse to one node, so a transaction row reads as one sentence rather than five fragments. New in 0.3.0: every modal surface is presented through `BankSheet`/`BankDialog`, whose `BankSheetHeader` marks the sheet title with the `header` trait and whose `BankSheetHandle` gives the drag affordance a labelled node — gated by *"grab handle renders and carries semantics"* in `test/sheet_presentation_test.dart`. Closed in this edition: the 14 sheet bodies that paint their own ground previously drew a plain 40×4 `Container` and announced no handle; each now routes through `BankSheetHandle`, gated by `test/sheet_handle_semantics_test.dart`, which pumps all 14 standalone and asserts a labelled handle (roadmap item 18). Also closed in this edition: `BankAppBar` and `BankSliverAppBar` both mark the large-title tier as a heading, and `BankSliverAppBar` now suppresses the framework's own header wrapper in **every** large mode rather than only in the non-collapsing one, so the collapsing bar no longer leaves an unlabelled `header` node with an empty `namesRoute` in front of heading navigation while it is expanded. (`BankAppBar` was never affected: its tier sits in the `bottom` slot, outside the title slot the framework wraps.) Gated by *"leaves no anonymous heading behind the large title"* in `test/app_chrome_test.dart`. **Gap**: `BankTextField` renders its label and error as sibling `Text` widgets rather than through `InputDecoration`, so AT associates neither with the field. **Gap**: no widget sets the `textField` trait. |
| 1.3.2 Meaningful Sequence | A | Partially Supports | Layouts are built in reading order, so the default traversal matches the visual order. **Gap**: zero `FocusTraversalGroup` usages and no test asserting the resulting sequence. |
| 1.3.3 Sensory Characteristics | A | Supports | No kit-supplied instruction identifies a control by shape, size, colour, or position. **Evidence**: manual review of the `BankUiStrings` table plus a scan of every string literal in `lib/` for positional and sensory wording, which found none. No automated gate keeps it that way. |
| 1.4.1 Use of Color | A | Partially Supports | Money carries an explicit sign and currency; status carries label text next to colour; chart slices carry a text legend. Three colour-only signals were removed in 0.3.0: `BankOtpInput` keeps its fill constant and encodes focus as an added ring rather than a recolour, and signals error with a thickened border and a shake as well as the danger hue; the insight confidence indicator carries a text level beside its bars; and a chosen value in `BankCountryPicker` and `BankAddressForm` is now typographically distinct from a placeholder (weight 600 against 400). Gated by *"OTP error state is distinguishable without colour"* and *"picker values are typographically distinct from placeholders"* in `test/accessibility_targets_test.dart`. **Gap**: no gate proves colour is never the sole carrier across all 173 widget classes, and host-supplied chart series may rely on hue. |
| 1.4.2 Audio Control | A | Not Applicable | Nothing plays audio; see 1.2.1. |
| 2.1.1 Keyboard | A | Partially Supports | `BankPressable` wraps every tappable surface in `FocusableActionDetector` and maps Space and Enter to the tap callback; gated by a keyboard-activation test. **Gap**: the swipe-actioned rows built on `Dismissible` expose no keyboard equivalent, and the stories carousel's pause is press-and-hold only. The `Dismissible` count is **1 file**, not the 4 this report claimed at 0.2.0: that figure came from a substring scan that also matched the unrelated `isDismissible` sheet parameter. |
| 2.1.2 No Keyboard Trap | A | Partially Supports | No widget installs a focus scope that withholds focus. **Evidence: source inspection only**; no test walks focus into and out of each modal. |
| 2.1.4 Character Key Shortcuts | A | Not Applicable | The kit registers no keyboard shortcuts. Gated: the conformance test fails if `SingleActivator`, `CharacterActivator`, `Shortcuts`, or `CallbackShortcuts` appears in `lib/`. |
| 2.2.1 Timing Adjustable | A | Partially Supports | `BankSessionTimeoutDialog` takes the remaining time, exposes an extend action, and marks the countdown as a `liveRegion`; `BankOtpInput` exposes a resend countdown. **Gap**: the kit cannot enforce the 20-second warning or ten-extension rules — the host chooses the durations. |
| 2.2.2 Pause, Stop, Hide | A | Partially Supports | `BankStoriesCarousel` pauses while pressed and disables auto-advance under reduced motion; `BankOnboardingCarousel` defaults `autoAdvance` to false. **Closed in 0.3.0**: `BankSkeletonLoader` now reads `MediaQuery.maybeDisableAnimationsOf`, *stops* its controller rather than ignoring it, and drops the `ShaderMask` entirely — gated by *"reduced motion stops the ticker and drops the mask"* in `test/async_states_test.dart`. **Gap**: three widgets still start a repeating controller with no reduced-motion check at all — `BankVirtualCardWidget`, `BankLivenessCheckOverlay`, and `BankAsyncVerificationState`. **Gap**: the carousel pause has no AT-reachable control. |
| 2.3.1 Three Flashes or Below Threshold | A | Supports | Nothing flashes. The kit does contain repeating animations — the 1200 ms skeleton shimmer plus glow, pulse, sweep and wiggle controllers in nine other files — but the fastest of them that changes luminance is a 600 ms pulse, that is 1.7 cycles per second against the criterion's limit of three, and the one sub-333 ms repeat (the quick-actions edit wiggle, 150 ms reversed) is a `Transform.rotate`: motion, not flash. Gated: every motion duration token is asserted at ≥150 ms. **Correction**: the 0.2.0 edition described that 150 ms floor as proof that no animation can reach three cycles per second. It is not — a 150 ms period is 6.7 cycles per second — so the claim now rests on the per-animation review above. |
| 2.4.1 Bypass Blocks | A | Not Applicable | A component library ships no blocks repeated across screens. Skip mechanisms and landmark structure belong to the composing app. |
| 2.4.2 Page Titled | A | Not Applicable | The kit ships no screens or windows; `BankAppBar` renders the title the host passes it. |
| 2.4.3 Focus Order | A | Partially Supports | Within a widget the tree is built in reading order. **Gap**: zero `FocusTraversalGroup` usages, and order across a screen is the host's composition. |
| 2.4.4 Link Purpose (In Context) | A | Partially Supports | Controls that name an action take an explicit label, and `BankPressable.semanticLabel` lets a composite tile announce a whole surface in one sentence. **Gap**: the ten icon-only `IconButton`s listed in 1.1.1 expose no accessible name at all, so their purpose reaches assistive technology as "button". **Gap**: for everything else the purpose text is host-supplied and no gate checks that it describes a destination rather than repeating a generic verb. |
| 2.5.1 Pointer Gestures | A | Partially Supports | No multipoint gesture exists anywhere; gated by a source scan. **Gap**: the `Dismissible` swipe row (1 file) and press-and-hold pause are path- and duration-based gestures with no documented tap alternative. |
| 2.5.2 Pointer Cancellation | A | Supports | `BankPressable` activates on the up-event and cancels when the pointer leaves the target; no widget acts on a down-event. Gated by a behavioural test that presses, drags off, releases, and asserts the callback never fired. |
| 2.5.3 Label in Name | A | Partially Supports | Labels on single-purpose controls are the visible text. **Gap**: composite tiles using `excludeSemantics` replace visible text with a summary that can reorder it, no gate checks this, and **no voice-control review has been done** — this is the criterion most likely to fail one. |
| 2.5.4 Motion Actuation | A | Not Applicable | No function is operated by device motion; the package depends on no sensor plugin. |
| 3.1.1 Language of Page | A | Not Applicable | The kit declares no language of its own; strings and locale come from the host. |
| 3.2.1 On Focus | A | Supports | No widget navigates or submits on receiving focus; focus alters only the focus ring and state layer. The one focus-driven content change is `BankAddressForm`, which marks a field touched on focus **loss** so its validation message appears — a change of content on blur, not a change of context on focus. **Evidence: source inspection of every focus callback in `lib/`** — no automated gate. |
| 3.2.2 On Input | A | Partially Supports | Input widgets report through callbacks and never navigate on their own. **Gap**: `BankOtpInput` moves focus between cells as digits arrive and fires `onCompleted` the instant the last digit lands, so a change of context is initiated by typing; the kit offers no way to defer it. |
| 3.3.1 Error Identification | A | Partially Supports | `errorText` renders in the danger colour and tints the label and border, so the error is in text, not colour alone. **Gap**: it is a sibling `Text`, not `InputDecoration.errorText` and not a live region, so AT neither ties it to the field nor announces it. |
| 3.3.2 Labels or Instructions | A | Partially Supports | Persistent labels above fields rather than disappearing placeholders, plus a helper slot. **Gap**: same association gap as 3.3.1. |
| 4.1.1 Parsing | A | Not Applicable | Flutter composites a widget tree; there is no markup to parse. WCAG 2.2 removed this criterion for the same reason. |
| 4.1.2 Name, Role, Value | A | Partially Supports | 285 semantics nodes supply name, role, and state — 142 button, 10 header, 24 selected/toggled — and `BankPressable` emits button plus enabled state for every custom surface. Closed in this edition: three of the five slider surfaces used to sit inside `excludeSemantics: true`, which removed the framework's own slider node together with its role, its value, and its increase and decrease actions; `BankCardControlsPanel`, `BankCreditLimitAdjuster` and `BankTransferLimitManager` now merge their heading into that node instead of replacing it, gated by *"kit sliders keep the role, the value, and both adjustments"* in `test/accessibility_targets_test.dart`. **Gap**: the four sliders in `BankLoanCalculatorCard` and `BankSavingsProjectionCard` still exclude it and so report neither an adjustable role nor a value; see roadmap item 19. **Gap**: the ten icon-only buttons in 1.1.1 report a role with no name. **Gap**: no `textField` trait anywhere. **Gap**: nothing has been verified as actually announced by TalkBack or VoiceOver, which is the only evidence that would justify "Supports". |

## Table 2: WCAG 2.1 Success Criteria, Level AA

| Criterion | Level | Conformance | Remarks |
|---|---|---|---|
| 1.2.4 Captions (Live) | AA | Not Applicable | No live media; see 1.2.1. |
| 1.2.5 Audio Description | AA | Not Applicable | No video; see 1.2.1. |
| 1.3.4 Orientation | AA | Partially Supports | No widget locks or requests an orientation; gated by a `SystemChrome` scan. **Gap**: no layout has been tested in landscape, and several card faces carry fixed aspect ratios unchecked against a short viewport. |
| 1.3.5 Identify Input Purpose | AA | **Does Not Support** | Only `BankOtpInput` declares an autofill purpose (`AutofillHints.oneTimeCode`). `BankTextField`, `BankPhoneInputField`, `BankAmountInputField`, and `BankAddressForm` expose **no `autofillHints` parameter at all**, so a host cannot mark name, email, telephone, or address fields even if it wants to. See roadmap item 1. |
| 1.4.3 Contrast (Minimum) | AA | Partially Supports | Gated at ≥4.5:1 for `onSurface`, `onSurfaceVariant`, `onPrimary`, `onBackground`, `positiveBalance`, `negativeBalance`, and `pending` in all eight preset/brightness combinations — 92 test cases in that file — and independently recomputed by the conformance test. **Gap**: the gate measures token pairs, not rendered pixels; text over `cardSurfaceGradient` / `accentGradient` (Voltage, Bloom) and over `BankCardPattern` overlays is unmeasured, and host colours are ungated. |
| 1.4.4 Resize Text | AA | Partially Supports | All text is real text in logical pixels inheriting the platform scale; gated by a scan proving no `TextScaler` / `textScaleFactor` override. **Gap**: fixed-height cells clip above roughly 1.5× — `BankAmountKeypad` keys default to 56 px, `BankPinKeypad` uses a fixed square — and there is no text-scale golden coverage. |
| 1.4.5 Images of Text | AA | Supports | Every string is rendered as text; the package bundles only font assets, gated by an asset scan. Card network marks are vectors and are logotypes, which the criterion exempts. |
| 1.4.10 Reflow | AA | Partially Supports | Layouts are constraint-driven and scroll vertically. **Gap**: nothing has been measured at a 320 px equivalent width or 400% zoom — reflow is asserted from construction, not evidence. |
| 1.4.11 Non-text Contrast | AA | Partially Supports | The muted "frozen" state is gated at ≥3.0:1 in all eight combinations. **Gap**: two non-text contrasts are ungated and therefore not claimed — the hairline separator, and the keyboard focus ring, which paints `primary` at `BankTokens.focusRingOpacity` (0.4) over whatever sits behind it, so its composited ratio is unmeasured and may fall below 3.0:1 on some presets. |
| 1.4.12 Text Spacing | AA | Not Applicable | The kit offers no text-spacing adjustment mode and Flutter software exposes no user mechanism to override those properties. Per WCAG2ICT the criterion applies to non-web software only where the software supports them. |
| 1.4.13 Content on Hover or Focus | AA | Partially Supports | Hover and focus produce state-layer and focus-ring painting only, revealing no extra content; two `Tooltip`s inherit Material behaviour. **Gap**: neither they nor `BankPeekBalance` have been tested for dismissibility and persistence. |
| 2.4.5 Multiple Ways | AA | Not Applicable | The kit ships no set of screens and no navigation model. |
| 2.4.6 Headings and Labels | AA | Partially Supports | Controls that name an action take an explicit descriptive label, and 10 `header` traits across 8 files mark headings — four of them added in 0.3.0, so every branded modal title (`BankSheetHeader`) is a heading, as is the large title on both bars, in `BankSliverAppBar`'s expanded and collapsed states alike. **Gap**: the ten icon-only buttons in 1.1.1 carry no label. **Gap**: most section titles inside widget bodies are still plain `Text` without the trait, so heading navigation remains largely unavailable across the 173 widget classes. |
| 2.4.7 Focus Visible | AA | Partially Supports | `BankPressable` paints a 2 px focus ring outside the child's bounds, concentric with the surface, whenever the focus highlight is reported. `BankOtpInput` adopted the same ring in 0.3.0, replacing a recoloured border and fill, and reserves the ring's inset on every cell so the row does not shift as focus moves — gated by *"OTP encodes focus once and keeps the fill stable"* in `test/accessibility_targets_test.dart`. **Gap**: no gate asserts the ring appears on `BankPressable` itself, and its contrast is unmeasured (see 1.4.11) — "visible" is claimed for existence, not perceptibility. |
| 3.1.2 Language of Parts | AA | Not Applicable | The kit supplies no prose of its own and marks no language on any subtree. |
| 3.2.3 Consistent Navigation | AA | Not Applicable | Navigation repeated across screens is the app's structure. |
| 3.2.4 Consistent Identification | AA | Supports | Consistent identification is what this package exists to provide: one interaction grammar (`BankPressable`), one icon vocabulary (`BankIconSpec`), one string table (`BankUiStrings`), one pinned token set. **Scope**: the kit guarantees the vocabulary; applying it consistently across a journey is the host's job. |
| 3.3.3 Error Suggestion | AA | Partially Supports | `errorText` and `helper` slots exist for a suggestion, and OTP/PIN flows surface retry affordances. **Gap**: the kit supplies no suggestion text and cannot know what correction is valid. |
| 3.3.4 Error Prevention (Legal, Financial, Data) | AA | Partially Supports | The kit ships the confirm-before-commit vocabulary a financial transaction needs: `BankTransferReviewCard`, `BankTransactionPinSheet`, `BankScaApprovalSheet`, and a deliberate hold gesture on `BankPanicFreezeButton`. **Gap**: nothing can force a host to place a review or reversal step in the journey — and this criterion is judged on the journey. **For an EAA assessment this row is the bank's to answer.** |
| 4.1.3 Status Messages | AA | Partially Supports | 12 files mark status surfaces as `liveRegion` (toast banner, connectivity banner, OTP, session timeout, and others); four call sites push explicit announcements — the two carousels, plus `BankAsyncContent` for the skeleton-to-loaded transition and `BankHorizontalAccountCard` for the copy confirmation, both added in 0.3.0. `BankAsyncContent` stays silent on first build and where `MediaQuery.supportsAnnounceOf` is false. `test/async_states_test.dart` and `test/accessibility_targets_test.dart` capture the platform accessibility channel and assert the message is dispatched, so it is now **observed leaving the framework** rather than merely declared. **Gap**: dispatch is not speech — no screen-reader session has confirmed any of these is spoken, which is why this row is not *Supports*. **Gap**: inline error text still announces nothing. |

## EN 301 549 V3.2.1 chapters

Chapters 11.1–11.4 mirror the WCAG criteria in Tables 1 and 2 and are not
repeated. The full per-clause positions and remarks are in
[`openacr.yaml`](./openacr.yaml); the summary is below.

### Chapter 4: Functional performance

| Clause | Conformance | Summary |
|---|---|---|
| 4.2.1 Usage without vision | Partially Supports | Semantics nodes with names, roles, and live regions exist; **no screen-reader session has ever been run**, and field labels are unassociated (1.3.1). |
| 4.2.2 Usage with limited vision | Partially Supports | Contrast gated at 4.5:1 across eight combinations; light and dark ship for every preset. Keypads clip above ~1.5× scale. |
| 4.2.3 Usage without perception of colour | Partially Supports | Amounts carry sign and currency; statuses carry label text. OTP focus/error, confidence level, and picker values stopped relying on hue in 0.3.0 and are gated by `test/accessibility_targets_test.dart`; the rest is not gated. |
| 4.2.4 / 4.2.5 Hearing | Not Applicable | Nothing conveys information through sound. |
| 4.2.6 Vocal capability | Not Applicable | No function requires speech. |
| 4.2.7 Limited manipulation or strength | Partially Supports | 44 px target floor pinned and referenced in 79 files. Five controls were brought up to it in 0.3.0: the insight-card dismiss, the IBAN copy affordance, the address-form edit button, the consent tick boxes in `BankConsentModal` and `BankDisclosureConsentSheet` (a compact `VisualDensity` on a shrink-wrapped `Checkbox` had made them 32×32), and every tappable emblem inside `BankEmblemStack`, whose slot used to clamp the emblem back to the visual disc. The assertions are not uniform in coverage: the insight-card dismiss and the IBAN copy row are asserted in LTR light on Studio and again in RTL on Voltage dark; the address-form edit button and the consent tick boxes are asserted in LTR light on Studio only; the emblem stack is asserted by `test/identity_system_test.dart` at the `xSmall` rung, the tightest one. No simultaneous pointers. Swipe and hold gestures still have no alternative. |
| 4.2.8 Limited reach | Partially Supports | Target floor and spacing tokens; reach is a property of the composed screen. |
| 4.2.9 Photosensitive seizure triggers | Supports | Nothing flashes; the fastest luminance-changing repeat is a 600 ms pulse, 1.7 cycles per second. Motion-token floor gated; see the correction in 2.3.1. |
| 4.2.10 Limited cognition, language, learning | Partially Supports | Plain-language defaults, persistent labels, confirm-before-commit, reduced motion in 40 files. No cognitive review or user testing performed, and three widgets still animate through the preference (see 2.2.2). |
| 4.2.11 Privacy | **Supports** | The privacy mask changes what is **announced**, not only what is drawn: `BankBalanceText` announces "Balance hidden" instead of the amount, so a screen-reader user is not the only person in the room whose balance is spoken aloud. Gated by `test/privacy_mask_test.dart`, which asserts both the hidden label **and** that no unmasked balance label leaks. |

### Chapter 5: Generic requirements

Mostly not applicable: the kit is open functionality on platforms whose
accessibility services are available, and ships no hardware. Two clauses do
apply.

| Clause | Conformance | Summary |
|---|---|---|
| 5.2 Activation of accessibility features | Supports | No platform overrides are installed and no accessibility setting is intercepted; `MediaQuery.disableAnimations` is read in 40 files. |
| 5.3 Biometrics | Partially Supports | A non-biometric path ships alongside the biometric one (`BankPinKeypad`, `BankOtpInput` next to `BankBiometricPromptButton`, which only invokes a host callback and holds no biometric data). **Gap**: nothing requires the host to offer it — a bank shipping only the biometric button would not meet this clause, and that is the bank's choice. |
| 5.9 Simultaneous user actions | Supports | No interaction requires two pointers; gated by a multipoint-gesture scan. |

### Chapter 11: Software

This is the chapter a UI component library lives or dies by. Clauses 11.5.2.x
concern the accessibility-services bridge, which is implemented by the Flutter
framework — it converts the semantics tree this package builds into Android
`AccessibilityNodeInfo` and iOS `UIAccessibility` objects. The package's
contribution is the *content* of that tree.

**Because the end-to-end bridge has never been exercised with a screen reader,
no clause in 11.5.2 is claimed as fully supported.** That is the single most
important sentence in this report.

| Clause | Conformance | Summary |
|---|---|---|
| 11.5.1 Closed functionality | Not Applicable | Not closed functionality. |
| 11.5.2.1 – 11.5.2.4 Services, AT | Partially Supports | Framework-provided bridge fed by 285 semantics nodes across 140 files; not verified on device. |
| 11.5.2.5 Object information | Partially Supports | 142 button, 10 header, 24 selected/toggled traits. **Gap**: no `textField` trait anywhere. **Gap**: the two slider surfaces named in 11.5.2.7 report no adjustable role. |
| 11.5.2.6 Row, column, headers | Not Applicable | No data table or grid ships; gated by a `DataTable` scan. |
| 11.5.2.7 Values | Partially Supports | Values are exposed for balances, gauges, the OTP field, and for the sliders in `BankCardControlsPanel`, `BankCreditLimitAdjuster` and `BankTransferLimitManager`, which keep the framework's own slider node and are gated by *"kit sliders keep the role, the value, and both adjustments"* in `test/accessibility_targets_test.dart`. **Gap**: the four sliders in `BankLoanCalculatorCard` and `BankSavingsProjectionCard` are still wrapped in `excludeSemantics: true`, which removes the node that carries the value, so they announce a label and nothing else (roadmap item 19). **Gap**: no gate proves a value node exists for every value-bearing widget, and value changes are unobserved on device. |
| **11.5.2.8 Label relationships** | **Does Not Support** | The weakest area. `BankTextField` draws its label and error as sibling `Text` widgets rather than through `InputDecoration`, so **no programmatic relationship exists** between a field and its label or its error. This affects every input built on it. See roadmap item 2. |
| 11.5.2.9 Parent-child relationships | Partially Supports | Merged composite nodes are deliberate — one sentence, not five fragments — but over-merging can hide structure and has not been validated with a screen reader. |
| 11.5.2.10 Text | Partially Supports | Real text with bundled Arabic, Devanagari, and currency fallback fonts; unverified through an AT text API. |
| 11.5.2.11 / 11.5.2.12 Actions | Partially Supports | Tap and long-press map to semantics actions, and three of the five slider surfaces regained their increase and decrease actions in 0.3.0 (see 11.5.2.7). **Gap**: the `Dismissible` swipe actions in the one file that uses it expose no semantics action, so AT cannot list or invoke them. **Gap**: the four sliders in `BankLoanCalculatorCard` and `BankSavingsProjectionCard` still expose no adjust action, so those limits cannot be changed by assistive technology at all (roadmap item 19). |
| 11.5.2.13 / 11.5.2.14 Focus and selection | Partially Supports | Focus reported through `FocusableActionDetector`; 24 selected/toggled traits (the "48" printed here at 0.2.0 was a loose substring count — see [Counting methodology](#2-source-inspection)). No traversal groups; unobserved on device. |
| 11.5.2.15 – 11.5.2.17 Change notification | Partially Supports | 12 `liveRegion` files and 4 announcement call sites — observed reaching the platform channel by two gates, never observed being spoken. |
| 11.6.1 User control of accessibility features | Supports | The kit exposes no accessibility feature of its own and never overrides platform settings; gated by a `SystemChrome` scan. |
| 11.6.2 No disruption of accessibility features | Partially Supports | The `BankSkeletonLoader` defect this row carried at 0.2.0 is **fixed** and gated. **Gap**: the same defect survives in `BankVirtualCardWidget`, `BankLivenessCheckOverlay`, and `BankAsyncVerificationState`, which start repeating controllers without reading the preference at all — so the kit still disrupts a setting the user chose, and this row stays below *Supports*. |
| 11.7 User preferences | Partially Supports | Platform text scale, brightness, and reduced motion (40 files, now including the skeleton loader and the sheet transition) are honoured. **Gap**: `MediaQuery.boldText`, `MediaQuery.highContrast`, and `MediaQuery.accessibleNavigation` are read nowhere, so users who set bold text or high contrast get no adaptation. **Gap**: the three widgets named in 11.6.2. |
| 11.8 Authoring tools | Not Applicable | The kit is not an authoring tool. |

### Chapter 12: Documentation and support services

| Clause | Conformance | Summary |
|---|---|---|
| 12.1.1 Accessibility and compatibility features | Supports | Documented and versioned with the code: this report, `doc/enterprise/accessibility-conformance.md`, `doc/enterprise/design-tokens.md` — including the open gaps. |
| 12.1.2 / 12.2.4 Accessible documentation | Partially Supports | Plain Markdown with heading structure and text link labels. **Gap**: never tested with a screen reader, and the SVG diagrams in `doc/diagrams` carry no text alternative. |
| 12.2.2 Information on accessibility features | Supports | Published at the same URL as the source, gaps and dates included. |
| 12.2.3 Effective communication | Partially Supports | Text-based support through the public issue tracker. **Gap**: no alternative channel for people for whom text is not accessible. |

### Chapters not applicable or out of scope

Chapter 6 (two-way voice), 7 (video), 8 (hardware), 10 (non-web documents),
and 13 (relay / emergency services) do not apply to this package. Chapter 9
(Web) is **out of scope for this edition** — see [Scope](#scope-of-this-report).

---

## Known gaps and roadmap

Every item below is a gap this report names in a table above. They are ordered
by how much they cost a real user, not by how easy they are to fix. All fixes
are **additive** under the package's API rules: new constructor parameters are
optional with token defaults, and no public member is removed or renamed.

Numbering is stable across editions, so an item keeps its number for its whole
life. **A target of v0.3.0 was reachable only while 0.3.0 was unreleased. It is
this release, so every item still open has been re-targeted to v0.4.0 rather
than left pointing at a version that has already shipped.**

| # | Gap | Criteria affected | Fix | Target |
|---|---|---|---|---|
| 1 | No input widget except `BankOtpInput` can declare an autofill purpose | 1.3.5 (Does Not Support) | Optional `autofillHints` parameter on `BankTextField`, `BankPhoneInputField`, `BankAmountInputField`, `BankAddressForm` | v0.4.0 (was v0.3.0) |
| 2 | `BankTextField` label and error are unassociated sibling `Text` widgets | 1.3.1, 3.3.1, 3.3.2, 4.1.2, 11.5.2.8 (Does Not Support) | Route label and error through `InputDecoration`, keeping the current visual treatment; announce errors as a live region | v0.4.0 (was v0.3.0) |
| 3 | **No screen-reader testing has ever been performed** | 4.1.2, 4.1.3, 4.2.1, all of 11.5.2 | Manual TalkBack and VoiceOver passes over the example gallery in all four presets; findings filed as `accessibility` issues | v0.4.0 (was v0.3.0) |
| 19 | Four sliders in `BankLoanCalculatorCard` and `BankSavingsProjectionCard` sit inside `excludeSemantics: true`, so the limit they set cannot be read or changed by assistive technology | 4.1.2, 11.5.2.5, 11.5.2.7, 11.5.2.11, 11.5.2.12 | Apply the pattern the other three slider surfaces adopted in 0.3.0: merge the heading into the framework's slider node instead of replacing it, and extend the *"kit sliders keep the role, the value, and both adjustments"* gate to both files | v0.4.0 |
| 5 | Fixed-height keypad cells clip above ~1.5× text scale; no text-scale coverage | 1.4.4, 4.2.2 | Scale-aware minimum heights, verified by goldens at 1.0 / 1.3 / 1.5 / 2.0 | v0.4.0 (was v0.3.0) |
| 6 | Focus-ring and hairline contrast unmeasured | 1.4.11, 2.4.7 | Measure the composited ring against every preset background; raise `focusRingOpacity` or switch to an opaque ring where it fails; add the measurement to the contrast gate | v0.4.0 (was v0.3.0) |
| 7 | No explicit focus traversal; zero `FocusTraversalGroup` | 1.3.2, 2.4.3, 11.5.2.13 | Traversal groups for keypads, sheets, and the bottom nav, with keyboard-order assertions | v0.4.0 (was v0.3.0) |
| 8 | The swipe-actioned row (`Dismissible`, 1 file) has no keyboard or AT equivalent | 2.1.1, 2.5.1, 11.5.2.11, 11.5.2.12 | Expose the same actions as semantics actions and as a visible affordance | v0.4.0 (was v0.3.0) |
| 20 | Ten icon-only `IconButton`s in `lib/` expose no accessible name | 1.1.1, 2.4.4, 2.4.6, 4.1.2, 11.5.2.5 | A `tooltip` or a themed `semanticLabel` parameter on each, consistent with the labelled icon controls elsewhere in the kit, plus a `labeledTapTargetGuideline` composition that covers the ten surfaces | v0.4.0 |
| 9 | `MediaQuery.boldText` / `highContrast` / `accessibleNavigation` unread | 11.7 | Read them in the theme resolver; a high-contrast token variant per preset | v0.4.0 |
| 10 | Section titles lack the `header` trait (9 traits across 8 files, out of 173 widget classes) | 2.4.6 | `header: true` on every widget that renders a section title | v0.4.0 |
| 11 | Charts: `BankSpendingBreakdownChart` is silent by default | 1.1.1 | Synthesise a default semantic summary, matching `BankCashflowChart` | v0.4.0 |
| 12 | Contrast is gated on token pairs, not rendered pixels | 1.4.3 | Extend the gate to text drawn over `cardSurfaceGradient` and `BankCardPattern` overlays | v0.4.0 |
| 13 | No reflow, landscape, or 400%-zoom evaluation | 1.3.4, 1.4.10 | Layout tests at a 320 px equivalent width and in landscape | v0.4.0 |
| 14 | No voice-control review of merged composite labels | 2.5.3 | Voice-control pass; ensure every accessible name starts with its visible label | v0.4.0 |
| 15 | **No independent audit** | The whole report | Commission a WCAG 2.1 AA and EN 301 549 assessment of the example gallery across four presets, both brightnesses, iOS and Android; publish the report, the resulting ACR, and the remediation log in this directory | v0.4.0 |
| 17 | Three widgets start repeating animations without reading reduced motion: `BankVirtualCardWidget`, `BankLivenessCheckOverlay`, `BankAsyncVerificationState` | 2.2.2, 4.2.10, 11.6.2, 11.7 | Apply the `BankSkeletonLoader` pattern — read the preference in `didChangeDependencies` and stop the controller | v0.4.0 |
| 16 | Flutter web target unevaluated | EN 301 549 chapter 9 | Evaluate Flutter's web semantics output and issue a web edition, or state permanently that the web target is unsupported for accessibility | Unscheduled |

### Closed in this edition

| # | Gap | Criteria affected | How it was closed | Enforcing gate |
|---|---|---|---|---|
| 4 | `BankSkeletonLoader` ignored the reduced-motion preference | 2.2.2, 11.6.2, 11.7 | Reads `MediaQuery.maybeDisableAnimationsOf`, *stops* the controller instead of ignoring it, and drops the `ShaderMask` | *"reduced motion stops the ticker and drops the mask"*, `test/async_states_test.dart` |
| 18 | 14 of the 23 `BankSheet.show` call sites passed `showHandle: false` and drew their own 40×4 bar with no semantics node | 1.1.1, 1.3.1 | All 14 bodies now render `BankSheetHandle`, which carries the non-empty default label `BankSheet.defaultHandleSemanticLabel` | `test/sheet_handle_semantics_test.dart`, which pumps all 14 standalone and asserts a labelled handle |

Neither closure upgrades a row to *Supports*. Item 17 above is the same
reduced-motion defect in three other widgets, found while reconciling this
edition, so 2.2.2, 11.6.2 and 11.7 stay at *Partially Supports* with the gap
re-pointed rather than removed; 1.1.1 and 1.3.1 keep the unrelated gaps named
in their own rows.

Item 18 was still printed as open in the 0.3.0 draft of this table after the
fix had landed, while row 1.3.1 and `openacr.yaml` recorded it as closed. That
is the failure mode this section exists to prevent, so it is recorded here
rather than quietly corrected.

A date that slips is re-dated here by pull request, not silently missed. Until
item 15 lands, this document remains a self-assessment and should be weighted
accordingly.

## What changed since 0.2.0

This edition reconciles every row against the code as it stands at 0.3.0. Nothing
below rests on a screen-reader session, because none has been run.

**Fixes that landed, each now behind a gate.** `BankSkeletonLoader` honours
reduced motion (2.2.2, 11.6.2, 11.7). The insight-card dismiss, the IBAN copy
affordance, and the address-form edit button reach 44×44 (4.2.7). The IBAN copy
shows a visible confirmation *and* dispatches an announcement (4.1.3).
`BankOtpInput` encodes focus with a single ring over a stable fill, and its
error state no longer depends on hue (1.4.1, 2.4.7). The confidence indicator is
a labelled text equivalent rather than three unlabelled dots (1.1.1, 1.4.1).
Selected values in the country picker and address form are typographically
distinct from placeholders (1.4.1). `BankSheet`/`BankDialog` centralise modal
presentation with a labelled grab handle and a `header`-marked title, and the
app bars mark their large-title tier as a heading (1.3.1, 2.4.6, 4.1.2).
`BankAsyncContent` announces the skeleton-to-loaded transition (4.1.3).

**Fixes that landed later in the same release**, found while reconciling this
edition and gated before it shipped. All 14 hand-rolled sheet handles route
through `BankSheetHandle`, closing roadmap item 18 (1.1.1, 1.3.1). Three of the
five slider surfaces stopped excluding the framework's slider node, so their
role, value, and adjust actions survive (4.1.2, 11.5.2.5, 11.5.2.7, 11.5.2.11,
11.5.2.12); the other two are roadmap item 19. The consent tick boxes in
`BankConsentModal` and `BankDisclosureConsentSheet` grew from 32×32 to the 44 px
floor, and a consent gate that cannot be ticked yet paints its outline at the
disabled opacity again instead of at full strength (4.2.7). Tappable emblems
inside `BankEmblemStack` keep the tap target `BankEmblem` promises rather than
being clamped to the visual disc (4.2.7). `BankSliverAppBar` suppresses the
framework's header wrapper in its collapsing mode as well, so heading navigation
no longer finds an unnamed heading beside the title (1.3.1, 2.4.6). The insight
card's confidence wording no longer ellipsizes on a 360 pt phone, and the
horizontal account card's back face scrolls instead of overflowing at a raised
text scale, so the text equivalents 1.1.1 and 1.4.1 rest on stay readable.

**Claims that were wrong for reasons unrelated to those fixes**, corrected here:
the `Dismissible` gap was reported as 4 files when the widget appears in 1 (the
old count matched the unrelated `isDismissible` parameter); one row printed 48
selection traits where the rest of the report printed 24; the shimmer is 1200 ms,
not 1400 ms; the package contains two `Tooltip`s, not one; 2.3.1's stated
reasoning — that a 150 ms token floor prevents three cycles per second — is
arithmetically false and has been replaced with a per-animation review; 2.4.4
and 2.4.6 asserted an explicit label on every interactive widget, which the ten
icon-only buttons now named in 1.1.1 contradict; 4.2.7 asserted that all
three enlarged controls are checked in RTL and dark when only two of them are;
and the reduced-motion recipe under [Counting
methodology](#2-source-inspection) named three of the four spellings the kit
uses, so it returned 34 against a printed 40.

**Inventory.** 173 widget classes, up from 164: `BankSheetHandle`,
`BankSheetHeader`, `BankSheetSurface`, `BankAsyncContent`, `BankSkeletonBox`,
`BankEmblemStack`, `BankSegmentedControl`, `BankCountryFlag`, and
`BankSliverAppBar`. `BankSheet` and `BankDialog` also shipped but are static
presentation helpers, not widgets, and are excluded from that count.

## How this report is kept honest

An ACR is worth publishing only while every sentence in it is still true. A
document that drifts from the code is worse than no document, because it
converts a credibility asset into a liability at the exact moment somebody
checks.

`test/accessibility_conformance_test.dart` runs on every push and enforces
five properties:

1. **No silent drift.** The report's product version tracks `pubspec.yaml`, its
   criteria set is asserted to be exactly WCAG 2.1 Level A + AA (so an
   inconvenient row cannot be quietly deleted), and **every file path cited as
   evidence must still exist**. Renaming a widget file breaks the build rather
   than turning a remark into fiction.
2. **No unbacked "Supports".** Every criterion claimed as *Supports* must be
   registered against either a named automated gate that runs in that same
   test, or an explicit manual-review marker. Adding a *Supports* row without
   doing one of those two things fails the build. The registry is also checked
   in reverse: a stale entry for a row that no longer claims support fails too.
3. **The gates still hold.** The test re-verifies contrast across all eight
   preset/brightness combinations using an **independently reimplemented** WCAG
   formula (a guard that shares an implementation with the thing it guards
   agrees with it even when both are wrong), the 44 px tap-target token, the
   150 ms motion floor, the "we ship none of this" source scans behind every
   *Not Applicable* row, and two behavioural claims — pointer cancellation and
   keyboard activation — driven against real widgets.
4. **No self-contradiction.** No roadmap item may appear in the open table and
   in "Closed in this edition" at the same time, and no open item may still be
   targeted at the version being shipped. The engineering companion,
   `doc/enterprise/accessibility-conformance.md`, is held to the same rule for
   its own G-numbered table. Both checks exist because a 0.3.0 draft of this
   report carried the sheet-handle gap as open and as closed at once.
5. **The printed figures are recomputed, and so are the recipes.** The
   library-file count, the `Semantics` constructor and trait counts, the
   tap-target file count, the reduced-motion file count, the modal-surface
   counts, and the widget-class count are derived from the tree on every run
   and matched against what this report, `openacr.yaml`, the companion
   document, the README, and the CHANGELOG each print. The counting recipes in
   [Counting methodology](#2-source-inspection) are executed as written, so a
   recipe that no longer reproduces its own figure fails the build rather than
   waiting for a reviewer to run it.

Validating `openacr.yaml` against the upstream GSA schema needs the network and
a Node toolchain, so it is a release-time step rather than a CI gate:

```bash
git clone https://github.com/GSA/openacr && cd openacr && npm ci
npx ts-node src/openacr.ts validate -f <path>/doc/enterprise/acr/openacr.yaml
```

## Feedback

If you find an error, an overclaim, or a gap this report misses, open an issue
at <https://github.com/sayed3li97/bank-ui-kit/issues>. Corrections are made by
pull request against this file and `openacr.yaml` together, and both are
re-issued with every minor release.

## Legal disclaimer

This report is provided in good faith and describes the package as analysed at
version 0.3.0 on the date shown. It is a self-assessment, not a legally-binding
conformance claim, and it does not transfer any obligation under Directive (EU)
2019/882 from the service provider to the package maintainers. Conformance of a
deployed banking application depends on how these components are composed,
themed, localised, and populated with content, none of which the package
controls.

Licensed CC-BY-4.0, independently of the package's own licence, so it can be
quoted in procurement documents.
