# Localization, RTL, and calendar guide

This document states what `bank_ui_kit` v0.1.0 does today for localization,
right-to-left layout, numerals, currency symbology, and calendars, and the
dated plan for what it does not do yet. It follows the same rule as
`doc/enterprise/accessibility-conformance.md`: every figure below is
measured against the source in this repository, and where the kit has not
reached a stated target, this document says so and gives the committed
milestone from `doc/enterprise/versioning-and-releases.md`.

## String inventory

The kit contains no baked-in, unreplaceable copy. Every user-facing string
sits in one of two overridable tiers:

1. Centralized strings, 55 fields. `BankUiStrings`
   (`lib/src/scope/bank_ui_strings.dart`) carries 55 English-default fields
   covering transaction statuses, account states, session-security dialogs,
   and shared actions. Widgets resolve them through
   `BankUiScope.of(context)` (`lib/src/scope/bank_ui_scope.dart`); a host
   app supplies one translated instance and every consumer updates.
2. Constructor defaults, 298 string literals across 62 widget files.
   Measured as `this.<field> = '<literal>'` under `lib/src/` outside
   `scope/`. 297 are user-facing English labels; the remaining one is the
   non-linguistic `digitChar = '#'` mask token in
   `lib/src/common/bank_masked_input_field.dart`. Of these, 25 are
   `*Template` fields carrying `{token}` placeholders (for example
   `counterTemplate = '{n} of {max} selected'` in
   `BankCashbackCategoryPicker`), interpolated at 22 `replaceAll` sites.

Known residue outside both tiers, listed so it can be closed rather than
discovered: `BankDateFormatter.formatRelative`
(`lib/src/common/money_formatter.dart`) hard-codes `just now`, `{n}m ago`,
`{n}h ago`, `{n}d ago`, and the `DateFormat` patterns in the same file
format month and weekday names in the `intl` default locale only.

The externalization plan moves the 297 constructor defaults into
`BankUiStrings`, organized by the existing 22 source domains, at v0.2.0
(2026-08-31). Constructor parameters remain and keep highest precedence, so
the resolution order becomes: explicit constructor argument, then
`BankUiScope` strings, then English default. This is additive; no existing
call site breaks. The `formatRelative` literals move in the same change.

## ICU MessageFormat / ARB bridge

Current position: templates use bare `{token}` placeholders with
single-string substitution and no plural, select, or gender branches.
`BankUiStrings.installmentMonths` (`'{n} months'`) documents that the host,
not the package, performs interpolation. This placeholder syntax is the
subset of ICU MessageFormat that ARB files and `gen-l10n` consume directly,
so today's strings round-trip into an ARB file without rewriting.

Committed direction, at v0.2.0 alongside the externalization:

- A generated `bank_ui_kit_en.arb` source-of-truth file with one entry per
  `BankUiStrings` field, including `@` metadata (description, placeholder
  types) for translation vendors.
- A `BankUiStrings` factory that adopters wire to their `gen-l10n` output
  (`AppLocalizations`), so the kit needs no `flutter_localizations`
  dependency of its own and imposes no l10n toolchain on hosts that do not
  want one. The zero-dependency `copyWith` path stays supported.
- Count-bearing keys (`installmentMonths`, `expiresTemplate`,
  `streakTemplate`, `errorsChipTemplate`, and peers) upgrade to ICU plural
  syntax in the ARB while the Dart API keeps accepting preformatted
  strings, so existing overrides keep working.
- String-freeze process for vendor round trips: strings freeze at each
  minor-release code cut (the dated milestones in
  `doc/enterprise/versioning-and-releases.md`); the ARB diff since the
  previous tag is the vendor handoff; translations land before tag; any
  post-freeze string change moves to the next release. Key renames follow
  the same deprecation grace window as API renames.

## Shipped-locale plan

Current position: the package ships English defaults only. There are no ARB
or translation files in the repository, and this document does not claim
otherwise. The 10 tier-1 locales below ship as reviewed ARB files starting
at v0.3.0 (2026-10-31) with Arabic first, completing by v0.5.0 (2027-02-28):

| Locale | Rationale |
|---|---|
| en | Source language, already complete in `BankUiStrings` |
| ar | RTL, Eastern Arabic-Indic numerals, 6 CLDR plural categories; pairs with the existing Islamic-finance mode and GCC currency registry |
| pl | Slavic plural rules (one/few/many/other); PLN already in `BankCurrencies` |
| de | Tier-1 EU market |
| fr | Tier-1 EU and North/West Africa |
| es | Tier-1 EU and Latin America |
| pt-BR | BRL already in `BankCurrencies` |
| tr | TRY already in `BankCurrencies` |
| zh-Hans | CJK coverage, zero-plural language |
| ja | CJK coverage, zero-decimal JPY already modeled |

Arabic and Polish are deliberate stress cases: together they exercise every
CLDR plural category the other eight locales would miss.

## Per-script font stacks

Current position: the package bundles three Latin
families (Space Grotesk, Nunito, Fredoka) under `lib/src/assets/fonts/`.
The token text styles in `lib/src/theme/tokens.dart` intentionally omit
`fontFamily`, so any widget outside a preset inherits the platform font,
which already provides Arabic and CJK glyph fallback on iOS and Android.
Presets apply their brand family through `BankThemeData.fontFamily`
(`lib/src/theme/extensions.dart`), and Flutter falls back to platform fonts
for glyphs the Latin families lack. There is no `fontFamilyFallback` token
in `BankThemeData` today; the only fallback wiring in the repository is the
screenshot harness (`example/lib/screenshot_harness.dart`), which applies
`fontFamilyFallback: ['NotoSansArabic']` with the subset bundled in
`example/pubspec.yaml`, because the headless capture browser cannot fetch
the web engine's remote Noto fonts.

Committed direction, v0.2.0: a `fontFamilyFallback` field on
`BankThemeData`, threaded through `preset.apply()` and
`BankThemeData.custom()`, with documented per-script stacks: Arabic
(Noto Sans Arabic, with Noto Naskh Arabic for long-form text) and CJK
(Noto Sans SC/TC/JP), plus guidance on keeping tabular-figure numerals in
the `numeralHero` through `numeralSmall` styles when a fallback engages.

## Hijri (Umm al-Qura) dual-calendar support

Current position: not implemented. All dates render Gregorian through
`BankDateFormatter` (`lib/src/common/money_formatter.dart`). The Islamic
banking domain ships today (`lib/src/islamic/bank_zakat_calculator.dart`,
`lib/src/islamic/bank_donation_hub_card.dart`), and zakat's hawl period is
defined on the lunar year, which is exactly where a Gregorian-only kit
falls short for KSA and GCC deployments.

Committed direction, v0.4.0 (2026-12-31): a `calendar` field on
`BankUiScopeData` with `gregorian`, `hijriUmmAlQura`, and `dual` modes,
backed by Umm al-Qura tabular conversion inside the package so behavior
does not depend on platform ICU versions. First consumers:
`BankTransactionGroupHeader` date headers, `BankStatementListTile` periods,
and zakat due dates, with dual rendering in the form
`15 Muharram 1448 AH (30 June 2026)` and month names sourced from
`BankUiStrings` so they translate with everything else.

## Arabic number formatting and the SAR symbol

`NumeralStyle.easternArabicIndic` (`lib/src/theme/numeral_style.dart`)
converts formatted output to Eastern Arabic-Indic digits after `intl`
formatting, preserving structure; it is scope-wide via
`BankUiScopeData.numeralStyle` and covered by `test/numeral_style_test.dart`
and `test/money_test.dart`. Known limit: separators pass through
unchanged, so output today uses U+002C and U+002E, not the Arabic decimal
separator U+066B and thousands separator U+066C, because
`BankMoneyFormatter` (`lib/src/common/money_formatter.dart`) calls
`NumberFormat.decimalPatternDigits` without a locale. Committed at v0.2.0:
a locale parameter on `BankMoneyFormatter.format` so `ar` output carries
locale-correct separators, with the digit-conversion path unchanged.

Currency symbology is registry-driven: 56 currencies in `BankCurrencies`
(`lib/src/models/bank_currency.dart`) with ISO 4217 minor units (6 entries
at three decimals, 6 at zero). The 10 Arabic-script symbols are wrapped in
FSI/PDI directional isolates (U+2068/U+2069) via
`BankCurrency.embeddableSymbol`, so they compose correctly inside LTR
amounts. SAR defaults to the traditional abbreviation because the official
riyal symbol (U+20C1, adopted by SAMA in 2025, Unicode 17) is still absent
from most shipped fonts and would render as a placeholder box; apps whose
bundled font carries the glyph opt in with one documented
`BankCurrencies.register` call, quoted in the source at
`lib/src/models/bank_currency.dart`.

## RTL verification status and golden-test evidence

What the source shows: 66 `EdgeInsetsDirectional` usages across 52 files;
masked account numbers deliberately pinned LTR under RTL
(`lib/src/accounts/bank_account_number_text.dart`,
`bank_account_card.dart`, `bank_account_switcher.dart`,
`bank_product_item_tile.dart`); direction-aware widgets that read
`Directionality.of(context)`
(`lib/src/onboarding/bank_step_progress_indicator.dart`,
`lib/src/insights/bank_financial_health_score.dart`,
`lib/src/onboarding/bank_onboarding_carousel.dart`).
Six physical-edge sites remain
(`bank_pin_keypad.dart`, `bank_portfolio_performance_chart.dart`,
`bank_in_app_notification_center.dart`, `bank_plan_comparison_table.dart`
twice, `bank_insight_card.dart`); all six convert to directional
equivalents at v0.2.0.

What verification exists today: RTL review is manual,
through the screenshot harness's `dir=rtl` query parameter
(`example/lib/screenshot_harness.dart`) with the bundled NotoSansArabic
fallback. The 6 files under `test/` (41 tests) pump LTR only, the
checked-in `doc/screenshots/` set contains no RTL captures, and
`tools/screenshots.mjs` does not yet drive `dir=rtl`. There are no golden
tests in the repository yet; `alchemist ^0.10.0` is already in
`pubspec.yaml` dev dependencies for this purpose. The committed evidence
package lands with the v0.3.0 golden baseline (2026-10-31): an RTL golden
matrix per preset for the money-rendering and form widgets, RTL variants in
the Playwright capture matrix committed under `doc/screenshots/`, and an
`ar` pseudo-locale smoke pass over the externalized `BankUiStrings`.
