# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

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
