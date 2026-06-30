# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Custom theming API: `BankThemeData.custom()` factory (only `primary` +
  `brightness` required) and the `ThemeData.withBankTheme()` extension for
  wiring a bespoke theme without a preset.
- Revolut-style full-app demo dashboard (`example/lib/demo/`) composed entirely
  from kit widgets, plus shared illustration-free sample data.
- URL-driven screenshot harness (`example/lib/screenshot_harness.dart`) and a
  Playwright generator (`tools/screenshots.mjs`) that render the real widgets
  to PNGs for the documentation.
- Open-source scaffolding: MIT `LICENSE`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, GitHub Actions CI, and issue/PR templates.
- Documentation screenshots for every module across the three presets.

### Fixed
- **The package did not compile** (770 analyzer errors). Corrected sibling-module
  import depths in 23 widget files, aligned `decimal`/`collection` constraints,
  fixed `tokens.dart` (missing `animation` import for `Curve`/`Curves`),
  `income_sorter_controller` (`Decimal.round` vs removed `toDecimal`),
  `pot_contribution_sheet` (missing `NumeralStyleX` import), and undefined
  duration tokens.
- Brand fonts declared in each preset are now actually applied to the Material
  text themes (previously bundled but never used). Replaced empty (0-byte) font
  stubs with real Space Grotesk, Fredoka, and Nunito files.
- Rewrote all 14 example showcase screens to compile against the real widget and
  model APIs.

## 0.1.0

- Initial release of Bank UI Kit.
- Core module: accounts, transactions, transfers, cards, authentication, security, states.
- Saving module: pots, round-ups, income sorter.
- Social module: peer-to-peer payments, transaction splitting, joint accounts.
- Investing module: multi-currency wallets, holdings, buy/sell, charts.
- Credit module: installment plans, credit limit gauge, repayment schedules, perks.
- Three design presets: BankVoltageTheme, BankStudioTheme (default), BankBloomTheme.
- Light and dark mode for every preset, WCAG 2.1 AA contrast.
- First-class RTL support across all widgets.
- BankUiScope for cross-cutting privacy toggle and preset selection.
- BankUiStrings localization escape hatch.
- NumeralStyle for Western and Eastern Arabic-Indic digits.
- Headless flow controllers: BankKycFlowController, BankTransferFlowController, BankIncomeSorterController.
