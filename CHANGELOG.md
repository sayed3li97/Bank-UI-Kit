# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

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
- A **flagship reference app** ("Meridian") in the example, composed entirely
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
