# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

## 0.3.0

Four themes: the trust artifacts an enterprise intake process asks for, the
token architecture finished end to end, a branded motion system, and the
remaining audit backlog cleared.

### Breaking

- **`BankSkeletonVariant` gained four values.** `listTile`, `card`,
  `balanceHero`, and `chart` were appended to the four the enum shipped with
  in 0.2.0. Dart 3 checks switch exhaustiveness, so a `switch` over the enum
  written against 0.2.0 with no `default` or wildcard arm stops compiling on
  upgrade (`non_exhaustive_switch_expression`). Adding a wildcard arm is the
  whole migration:

  ```dart
  // Before: compiles against 0.2.0, fails against 0.3.0.
  final caption = switch (variant) {
    BankSkeletonVariant.accountCard => 'Loading account',
    BankSkeletonVariant.transactionTile => 'Loading transactions',
    BankSkeletonVariant.potCard => 'Loading pots',
    BankSkeletonVariant.generic => 'Loading',
  };

  // After: compiles against both.
  final caption = switch (variant) {
    BankSkeletonVariant.accountCard => 'Loading account',
    BankSkeletonVariant.transactionTile => 'Loading transactions',
    BankSkeletonVariant.potCard => 'Loading pots',
    _ => 'Loading',
  };
  ```

  The original four keep their names and their declaration order, so a
  persisted index or name still resolves to the same variant. The full list
  and its order are pinned by `test/async_states_test.dart`, so a further
  addition cannot ship without another entry under this heading.

### Added

- **Accessibility Conformance Report** (`doc/enterprise/acr/ACR.md`): a
  per-component WCAG 2.1 A and AA plus EN 301 549 V3.2.1 report, with a
  machine-readable OpenACR source of truth beside it
  (`doc/enterprise/acr/openacr.yaml`, GSA catalog
  `2.4-edition-wcag-2.1-508-eu-en`). It is a self-assessment, states so on its
  first page, and names the areas where evidence does not exist.
- **Stability and support policy**
  (`doc/enterprise/stability-and-support.md`): the dependency contract. What
  counts as a breaking change for a UI kit, including the case that actually
  bites here: a default colour, size, elevation, font, or motion value
  moving without an analyzer warning. The deprecation window with a 90-day
  wall-clock floor, a procedure for retiring a visual default, pinning
  guidance, the supported-version policy, the 1.0 gate as an 11-point
  checklist with the current status of each criterion, and the continuity
  story for a single-maintainer project.
- **Supply-chain artifacts**: an SBOM built on every commit and every release
  in SPDX 2.3 and CycloneDX 1.6 from one resolution, scanned against OSV and
  reproducible byte for byte from the commit plus the lockfile shipped inside
  it (`.github/workflows/sbom.yml`); pub.dev publication over OIDC with no
  stored credential, bound to a tag ref (`.github/workflows/publish.yml`);
  Sigstore-backed SLSA build provenance attached to release artifacts
  (`.github/workflows/release.yml`); and a weekly OpenSSF Scorecard run
  (`.github/workflows/scorecard.yml`). Every third-party GitHub Action is
  pinned by commit SHA. Documented in `doc/enterprise/supply-chain.md`.

### Changed

- **README restructured for two readers.** The top third now answers what a
  bank or agency evaluator asks at intake, as a question-and-evidence table
  covering the ACR, the CI-enforced accessibility gates, the compliance
  split, the SBOM and provenance chain, the published Scorecard, and the
  stability contract, each linked to the document that carries the proof. The
  component catalogue, screenshots, and quick start are unchanged in
  substance. Counts corrected to 173 exported widget classes and 487 test
  cases, and the badges row gains Scorecard and pub.dev.
- `doc/enterprise/versioning-and-releases.md` now describes the release
  pipeline as implemented rather than as planned, and corrects the Flutter
  floor to 3.44.0 with CI on 3.44.4. Cross-links the new stability policy
  rather than restating it. The roadmap milestones are re-dated against what
  each release actually contained, and the four journey controllers that did
  not land in this one move to v0.4.0 rather than staying pointed at a
  version that has shipped.
- Documentation corrected where it lagged the code: injectable image
  resolution through `BankUiScopeData.imageResolver` ships, so the README no
  longer lists air-gapped image loading as a roadmap item.

- **Design-token architecture completed**: the DTCG source now carries a
  12-rung neutral ramp, surface and ink tiers, border roles, a six-rung
  icon-size ladder, an opacity ladder, and an elevation-tier enumeration.
  `BankThemeData.custom` and `fromJson` read their greys from these tokens
  instead of hard-coding them, with no behaviour change. Typography gains a
  line-height ladder on every text style and caps-tracking tokens.
- **Branded sheet presentation** (`BankSheet`, `BankDialog`): all 31 modal
  surfaces in the kit (23 `BankSheet.show` call sites and 8 `BankDialog.show`)
  now present with the theme's radius, a brand-derived
  scrim, a grab handle with semantics, an optional shared header,
  keyboard-aware insets, and token motion that collapses under reduced
  motion. No stock `showModalBottomSheet` or `showDialog` call remains in
  `lib/`.
- **`BankAsyncContent`** plus skeleton shapes built from the kit's real
  anatomy, so loading, error, empty, and content are one switch rather than
  a host-assembled pile of grey rectangles.
- **`BankSliverAppBar`** and app-bar title modes (`standard`, `large`,
  `collapsing`), and an opt-in per-step help affordance on
  `BankStepProgressIndicator` for regulated journeys.
- **Identity system**: `BankEmblem` gains a size ladder, theme-derived tints
  that measure their own contrast to clear AA on any hue, an inset ring
  slot, and `BankEmblemStack` with +N overflow.

### Deprecated

- **`BankValueDiffRow.previousLabel` and `BankValueDiffRow.newLabel`**, and
  the same two parameters on `BankValueDiffList`. Both `BankValueDiffStyle`
  variants now render one grammar, old value then arrow then new value, so
  the `'Previous'` / `'New'` microlabels are gone from the output and passing
  a value has no effect. There is no replacement parameter: the old-to-new
  relationship is carried by the struck value and the arrow, and what
  assistive technology says about the row is localised through
  `semanticLabel`. `BankValueDiffList` no longer forwards either parameter to
  its rows, so the analyzer warning reaches the call site that set it rather
  than being swallowed. Both are removed in 0.5.0.

  ```dart
  // 0.2.0: two captioned lines, 'Précédent 5 000,00 €' / 'Nouveau 8 000,00 €'.
  BankValueDiffRow(
    label: 'Limite',
    oldMoney: previous,
    newMoney: next,
    style: BankValueDiffStyle.stacked,
    previousLabel: 'Précédent',
    newLabel: 'Nouveau',
  )

  // 0.3.0: '5 000,00 € → 8 000,00 €', the old value struck through.
  BankValueDiffRow(
    label: 'Limite',
    oldMoney: previous,
    newMoney: next,
    style: BankValueDiffStyle.stacked,
    semanticLabel: 'Limite passe de 5 000,00 € à 8 000,00 €',
  )
  ```

### Fixed

- **Accessibility**: every interactive target named in the audit now reaches
  the kit's 44 px minimum without inflating its glyph (insight-card dismiss,
  IBAN copy, address-form edit, the consent tick boxes in
  `BankConsentModal` and `BankDisclosureConsentSheet`, and every tappable
  emblem inside `BankEmblemStack`); the IBAN copy affordance confirms
  visually and announces to assistive technology; OTP cells encode focus with
  one signal instead of swapping both fill and border; picker values are
  typographically distinct from placeholders; the insight card's confidence
  dots are labelled instead of reading as broken pagination.
- **Semantics that were being thrown away**: the 14 sheet bodies that paint
  their own ground drew a bare 40×4 bar and announced no handle, and now
  route through `BankSheetHandle`; the sliders in `BankCardControlsPanel`,
  `BankCreditLimitAdjuster` and `BankTransferLimitManager` sat inside
  `excludeSemantics: true`, which deleted the framework's slider node
  together with its role, its value and its increase and decrease actions, so
  the limit could not be changed by assistive technology at all, and now
  merge their heading into that node instead of replacing it; a consent
  checkbox the user cannot tick yet paints its outline at the disabled
  opacity again rather than at full strength; and `BankSliverAppBar` in its
  collapsing mode no longer leaves an unnamed heading with an empty
  `namesRoute` beside the large title. The sliders in
  `BankLoanCalculatorCard` and `BankSavingsProjectionCard` still exclude
  their node; that is item 19 on the ACR roadmap.
- **Money rendering**: a currency symbol written in a right-to-left script is
  wrapped in an FSI/PDI isolate so its letters cannot retype the European
  digits beside them. For the ten currencies that have one (SAR, AED, QAR,
  KWD, BHD, OMR, JOD, IQD, TND, MAD), the
  no-break space between the symbol and the digits was packed inside that
  isolate. A no-break space is a CS neutral, so surrounded by
  Arabic letters it resolved right-to-left with them and reordered to the far
  side of the symbol: `BankMoneyFormatter.format(currencyCode: 'BHD', ...)`
  rendered ` د.ب1,234.567`, a stray leading space and the marker glued to the
  first digit, instead of `د.ب 1,234.567`. The gap now sits outside the
  isolate on the digits' side, which is where it holds its place in an
  English paragraph and an Arabic one alike. `splitMajorMinor` carries the
  corrected atom too.
- **`BankPrizeDrawCard`** formatted `prizeAmount` and its semantic summary
  with the ambient `Intl.defaultLocale` rather than the app locale, so a
  de-DE app rendered `USD 500,000` and a German reader parsed it as five
  hundred. Both now resolve `context.bankLocale`, matching every other money
  surface in the kit.
- **Two layouts that overflowed their box**: the insight card's confidence
  wording competed with a `Spacer` for the action row's slack and ellipsized
  to "High confid…" on a 360 pt phone, defeating the point of replacing the
  dots with words; and the horizontal account card's back face, whose height
  is fixed by the card aspect ratio, overflowed once an account carried both
  an IBAN and a sort code on a narrow device or at a raised text scale. The
  meter now takes the whole slack, and the back face degrades by scrolling
  rather than by clipping.
- **Skeleton shimmer** travelled a darker band over flat slabs, in phase
  across every tile, and never entered the placeholder shapes. It now sweeps
  a lighter band through the shapes with per-tile phase offsets, and stops
  entirely under reduced motion.
- **Brand contracts honoured, and consulted by the widgets rather than only
  declared on the theme**: Bloom's warm shadow tint reaches every kit surface
  rather than dying on a `Card.elevation` sentinel or on a direct
  `BankTokens.shadow*` call, so two resting cards on one screen no longer
  drop differently coloured shadows; Studio dark's primary CTA no longer
  reads as disabled; and `BankThemeData.gradientReach` is now read at the
  twelve surfaces that used to paint the accent gradient raw, so under
  Voltage the violet-to-cyan sweep stays full strength on hero card faces and
  drops to the same hues at a rationed alpha on supporting headers, promo
  strips and icon rings. `BankHorizontalAccountCard`'s theme-gradient face
  still reads the gradient directly; it is a hero surface, the tier
  `gradientReach` never rations, so it renders identically either way.
  `test/policy_adoption_test.dart` asserts both policies on the painted
  decorations of a rendered tree rather than on the theme methods, so a call
  site that drops back to `theme.accentGradient` or `BankTokens.shadow*` raw
  fails CI.
- **Chrome**: the app bar's 18 px title and grey 12 px subtitle become a
  real hierarchy; the connectivity banner adopts the toast treatment with a
  single left edge.
- **Component cluster**: receipt ink is legible on themed paper in every
  preset, the plan comparison table scrolls with a closed emphasis border,
  bill-pay rows share a trailing column, value-diff rows follow one grammar
  and colour by meaning, the period selector is content-sized with real
  chevron targets, transfer review gives the amount the hierarchy it needs,
  the SCA sheet drops to one accent, statement rows no longer leak a
  midnight timestamp, stock Material controls are themed, and CTA copy is
  consistently sentence case.

## 0.2.0

A premium-quality overhaul driven by a full visual and code audit against
Backbase-class design systems: 7 systemic themes, 76 ranked defects, the top
24 fixed in this release.

### Added

- **Interaction states everywhere**: new `BankPressable` wrapper gives cards,
  tiles, keypads, and quick actions pressed-scale, hover/focus state layers,
  a keyboard focus ring, and button semantics; state-layer opacities and
  press scale are theme tokens.
- **Dark-mode depth system**: dark shadow variants with `Brightness`
  resolvers plus hairline edge tokens, adopted across 30+ card surfaces
  through one internal resolver; Material `Card` elevations migrated to the
  token language.
- **Brand voices per preset**: `displayFontFamily` (Heritage gets a bundled
  Noto Serif Display face, Bloom uses Fredoka), `cardSurfaceGradient`, and
  generative `BankCardPattern` overlays (mesh, lattice, arcs, grid), all
  serialised in theme JSON.
- **Real network marks**: vector Visa wordmark, token-driven Mastercard
  lens, and Amex tile replace the synthetic italic faux-bold text, with a
  `markBuilder` escape hatch for licensed artwork; shared metallic
  `BankCardChip` and a single PAN treatment across all card widgets.
- **`BankSegmentedControl`**: theme-driven segmented control (no M3
  checkmark, 44 px minimum, labels never fracture mid-word).
- **`BankCountryFlag`**: tofu-proof country indicator (crafted ISO chip by
  default, emoji opt-in, global `flagBuilder` override on `BankUiScope`).
- **Money presentation API**: `trimZeroCents`, `splitMajorMinor`, deliberate
  unknown-code fallback; balance count-up animation; amounts scale down
  instead of ellipsizing.
- Theme-derived chart palette generation, portfolio-chart axes and themed
  tooltips, honest gauge/meter readouts, and an animated price ticker.

### Fixed

- Blank CTA labels on state views, banners, sheets, and rewards cards (brand
  font now survives `ButtonStyle.textStyle`).
- `BankAccountCard`: dead 70-90 px band removed (content-sized), resting
  shadow restored in all presets, frozen state desaturates instead of
  stamping a snowflake over the balance, status chips use the unified
  semantic ramps.
- Mid-word wrapping and truncation: onboarding stepper labels, product
  category tiles, segmented controls, balance-tile captions, and money
  amounts no longer fracture or ellipsize at the kit's own demo widths.
- Flip button no longer collides with network marks (reserved directional
  corner, verified LTR + RTL); premium card surfaces keep their hero shadow.
- One green/red/amber family kit-wide: semantic status, investment, and
  credit colours unified onto the AA financial ramps with dark variants
  (previously a mix of Apple, Tailwind, and Material palettes).
- Loan APR unit footgun: `annualRate` documented and asserted as a fraction
  with a formatting helper (no more 890% demo APRs); catalog rates read
  "From 5.9% APR" in order.
- Transaction rows: amount carries the row's optical weight, credits are
  positive-green with an explicit plus, debits stay neutral; joint tiles no
  longer leak amounts through privacy mode.
- Example app demo data reads credibly (consistent phone country/number,
  humanized labels, internally consistent representative examples), overlay
  components are captured open, and component screenshots crop to content.

## 0.1.0

Turns the kit from a widget library into a **design system**: tokens become
platform-neutral data, money formats per locale, and accessibility is enforced
in CI.

### Added

- **W3C DTCG design-token source of truth** (`tokens/design-tokens.json`): the
  scalar tokens (colours, spacing, radius, motion, tap target) now generate
  `lib/src/theme/tokens.dart` via `tool/generate_tokens.dart`, with a CI drift
  guard (`--check`). Composite tokens (text styles, curves, shadows) stay
  hand-authored and reference the generated values.
- **`BankThemeData.toJson()` / `.fromJson()`**: any brand (including the four
  presets) serialises to/from JSON (`#RRGGBBAA` hex) for Figma Variables,
  native platforms, and server-driven / remote branding. All presets are
  exported to `tokens/themes/` (regenerate via `test/theme_export_test.dart`).
- **Locale-aware money formatting**: `BankMoneyFormatter.format`/`formatSign`
  accept a `locale` so grouping and separators follow the market (German
  `1.234.567,89`, French `1 234 567,89`, Indian lakh `12,34,567.89`). Core
  money widgets resolve it from `Localizations` automatically; the new
  `BuildContext.bankLocale` extension exposes it for direct formatter calls.
- **Accessibility & visual-regression gates in CI**: a WCAG contrast test
  (89 assertions across every preset × light/dark), tap-target (44 px) and
  accessible-label guideline checks, and Flutter-native golden tests across
  presets × brightness × direction.
- **Bundled glyph-coverage fallback fonts** (`kBankFontFallback`): OFL Noto
  subsets for currency symbols (₹ ₩ ₫ ₿ Ξ …), Arabic script, Latin-Extended
  (ł, č …), and Arabic-Indic / Persian / Devanagari numerals, wired as
  `fontFamilyFallback` on every text style and theme, so every script the kit
  advertises renders, even offline / on web without a CDN.
- `doc/enterprise/design-tokens.md` documenting the token pipeline.

### Changed

- **Fixed WCAG AA contrast defects** shipping in default presets: Bloom light
  `onPrimary` (2.78:1 → dark ink), Heritage dark `onPrimary` (4.44:1), and the
  financial semantic colours (`positiveBalance` 2.26:1, `pending` 2.03:1,
  `negativeBalance`). Semantic colours are now brightness-aware (AA-compliant
  emerald/red/amber on light surfaces, lighter variants on dark), applied
  automatically by `BankThemeData.custom()`.

### Removed

- `alchemist` dev dependency, which never compiled against Flutter 3.44 (missing
  `Canvas` methods) and is replaced by Flutter-native golden tests.

## 0.0.3

Adds a product-origination surface and a complete reference app.

### Added

- **Products & applications module** (`lib/src/products/`): `BankProductCard`
  (rate hero, feature list, badges, dual call to action),
  `BankProductCategoryTile` (catalogue grid), `BankEligibilityResultCard`
  (soft-search outcome with a no-credit-impact reassurance),
  `BankOfferSummaryCard` (firm or indicative offer with the regulatory
  representative example), `BankRatioGauge` (LTV / DTI / LTI affordability
  bands), `BankDisclosureConsentSheet` (pre-contract disclosures and
  no-dark-pattern consents), and `BankESignaturePad` (typed or drawn,
  timestamped signature). Every visual decision is an optional constructor
  parameter defaulting to the active theme.
- Headless `BankApplicationController`: a seven-step application state
  machine (eligibility, customise, offer, documents, disclosures, sign,
  decision) with validity and completion tracking, exported from `core.dart`.
- A **reference app** ("Meridian") in the example, composed entirely
  from kit widgets: product catalogue, product detail with a
  conventional/Shariah toggle, the end-to-end Auto Finance application, and a
  servicing view. Run it with `flutter run -t lib/flagship_main.dart`.
- A consolidated banking-products reference in
  `doc/research/banking-products.md`.

### Fixed

- `BankEligibilityResultCard`'s primary action now sets its label colour
  explicitly so the call to action stays legible under every preset.

## 0.0.2

Maintenance release: clears the pub.dev analysis findings for a clean score.

### Changed

- Upgraded `fl_chart` to `^1.2.0` and `qr` to `^4.0.0` (both now on their
  latest majors). The QR view adopts the `qr` 4.x `QrPayload` API.
- Raised the Flutter floor to `>=3.44.0` and migrated every deprecated
  API to its current replacement: Switch `activeColor` to
  `activeThumbColor`, `SemanticsService.announce` to `sendAnnouncement`,
  `SizeTransition.axisAlignment` to `alignment`, `Matrix4.scale` to
  `scaleByDouble`, and `DropdownButtonFormField.value` to `initialValue`.

No public API changes; widgets render and behave exactly as before.

## 0.0.1

Initial public release: 140+ composable banking widgets across 22 domains,
four built-in design languages, and one theming engine.

### Components

- Accounts and balances, cards (virtual, physical, disposable, family),
  transactions, transfers and payments, savings and goals, social and
  joint accounts, investing, credit and lending, rewards, Islamic banking,
  onboarding and KYC, business banking, insights, notifications, support,
  and app gate and degraded states (maintenance, offline, force update,
  device and network security blocks, waiting room).
- Currency engine: 50+ currencies with correct symbols, minor units
  (3-decimal Gulf currencies, 0-decimal JPY and KRW, crypto precision),
  symbol placement, and bidi-isolated right-to-left symbols.
- Hijri (Umm al-Qura) calendar support with dual-calendar formatting.

### Theming and design

- Four presets: Studio (default), Voltage, Bloom, and Heritage
  (Islamic-banking ready), each in light and dark.
- Custom theming: `BankThemeData.custom()` (only `primary` and `brightness`
  required) and the `ThemeData.withBankTheme()` extension.
- Every widget's colours, shapes, depth, text styles, icons, strings, and
  animation timing are overridable through optional constructor parameters
  that default to the theme.

### Cross-cutting

- Privacy mode: `BankBalanceText` and every money surface mask through
  `BankUiScope`, verified by a mask-proof test across the render and
  semantics trees.
- First-class RTL across all widgets, with Western and Eastern
  Arabic-Indic numerals via `NumeralStyle`.
- `BankUiStrings` localization escape hatch; no `gen-l10n` dependency.
- Lossless `Decimal`-backed `Money` type; no `double` touches an amount.
- Headless flow controllers (`BankKycFlowController`,
  `BankTransferFlowController`, `BankIncomeSorterController`) that never
  touch the network.

### Quality

- `flutter analyze` clean on the package and the example app.
- Unit and widget tests across presets, both brightnesses, and RTL.
- Semantics on every control and 44 px minimum touch targets.
- Interactive component gallery and a full demo dashboard in `example/`.
