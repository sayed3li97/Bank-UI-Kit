# Localization, RTL, and calendar guide

This document states what `bank_ui_kit` v0.4.0 does today for localization,
right-to-left layout, numerals, currency symbology, and calendars, and the
dated plan for what it does not do yet. It follows the same rule as
`doc/enterprise/accessibility-conformance.md`: every figure below is
measured against the source in this repository, and where the kit has not
reached a stated target, this document says so and gives the committed
milestone from `doc/enterprise/versioning-and-releases.md`.

## Message catalogue

The kit ships a real message catalogue as of 0.4.0.

`lib/l10n/bank_ui_kit_en.arb` holds 301 messages, each with an
`@description` for translation vendors and typed placeholders where the
message takes arguments. `lib/l10n/bank_ui_kit_ar.arb` carries all 301 in
Arabic. `flutter gen-l10n` (configured by `l10n.yaml`) compiles both into
`lib/src/l10n/`, which is committed: a package ships its generated
localizations rather than asking every host to run a codegen step.

Hosts install it like any delegate:

```dart
MaterialApp(
  localizationsDelegates: BankL10n.localizationsDelegates,
  supportedLocales: BankL10n.supportedLocales,
)
```

Installing nothing renders exactly the English 0.3.0 rendered.

### Resolution order

45 library files read copy through `BankStrings.of(context)`
(`lib/src/l10n/bank_strings.dart`), which resolves three sources and
returns the first that answers:

1. a `BankUiStrings` field the host **changed** from its shipped default
   and passed to `BankUiScope`;
2. the translation for the ambient locale, when the host installed
   `BankL10n.delegate`;
3. the built-in English.

The first rule is the one worth reading twice. A host that overrides two
terms and leaves the rest alone keeps its two terms in every language and
gets translations for everything else. Before 0.4.0 that was not
expressible: `BankUiStrings` fields are non-nullable with English defaults,
so a partial override was indistinguishable from a full one.

`BankStrings.override(value, shipped)` is the primitive that makes it work,
and it is public because widgets need it too: it returns `value` when the
caller changed it from `shipped` and `null` when they did not. Its one
false negative — a host that assigns exactly the shipped English — is
indistinguishable from assigning nothing and renders the same English on an
English device.

### String inventory

Two tiers, as before, now with a third source underneath them:

1. **Centralized strings, 56 fields.** `BankUiStrings`
   (`lib/src/scope/bank_ui_strings.dart`) still carries the English-default
   fields covering transaction statuses, account states, session-security
   dialogs, and shared actions. Every one now has a catalogue twin, so
   leaving a field alone gets it translated.
2. **Constructor defaults, 639 string literals across 117 files.** Measured
   as `this.<field> = '<literal>'` under `lib/src/` outside `scope/`; 12
   are non-linguistic tokens (`digitChar = '#'`, `'+{n}'`, `'●'`, `'0.00'`
   and peers). Overriding them works exactly as it did in 0.3.0.
3. **The catalogue**, consulted whenever the first two decline.

**Known gap, stated rather than discovered:** those 639 defaults do not
consult the catalogue yet, so a widget whose copy arrives only that way
renders English in an Arabic app. Closing them needs no API change —
`BankStrings.override` against a private constant is the whole pattern, and
`BankUpdatePromptSheet`, `BankAppGateScreen`, `BankScaApprovalSheet` and
`BankAlertPreferencesPanel` show it applied. The remaining files convert at
v0.5.0 (2027-02-28).

Residue closed in 0.4.0, listed here because the previous revision of this
document promised it: `BankDateFormatter.formatRelative` no longer
hard-codes `just now` / `{n}m ago` / `{n}h ago` / `{n}d ago`, and every
`DateFormat` call in the kit now takes the ambient locale rather than
formatting month and weekday names in the `intl` default.

## ICU MessageFormat

Count-bearing messages are ICU `plural` in the catalogue, which is what
lets Arabic carry all six CLDR categories — `zero`, `one`, `two`, `few`
(3–10), `many` (11–99), `other`. `test/localization_test.dart` asserts all
six for `installmentMonths`.

`BankUiStrings.installmentMonths` remains a `{n}` template and structurally
cannot express six categories; a host that supplies one still gets
substitution, and a host that does not gets the plural. That asymmetry is
the reason the catalogue exists rather than more `String` fields.

Escaping is off (`use-escaping: false` in `l10n.yaml`). No message in the
catalogue needs a literal brace, and turning escaping on would make every
"we can't" and "you're" an unmatched-quote lexing error for translators.

### Freeze process

Strings freeze at each minor-release code cut (the dated milestones in
`doc/enterprise/versioning-and-releases.md`); the ARB diff since the
previous tag is the vendor handoff; translations land before tag; any
post-freeze string change moves to the next release. Key renames follow the
same deprecation grace window as API renames.

### CI gates

Three, deliberately separate, in `.github/workflows/ci.yml`:

- `dart run tool/check_l10n.dart` — fails on a message with no
  `@description`, a key missing from any locale, a key present in a locale
  but not the template, or a placeholder a translation dropped. A
  translator can break this without touching Dart, which is why it does not
  depend on codegen.
- `flutter gen-l10n` followed by `git diff --exit-code` — proves the
  committed Dart matches the ARB.
- `dart run tool/generate_l10n_facade.dart --check` — proves the resolution
  facade was regenerated after a catalogue change.

## Shipped-locale plan

Current position: **English and Arabic**, at full key parity.

The Arabic is machine-assisted and has **not** been reviewed by a native
speaker or a banking-terminology reviewer. It is committed so the mechanism
is exercised by a real second language — six plural categories,
right-to-left script, Arabic comma — not because it is ready to put in
front of customers. Treat it as a starting point for a translation vendor.

The remaining tier-1 locales ship as reviewed ARB files by v0.6.0
(2027-04-30):

| Locale | Status | Rationale |
|---|---|---|
| en | Shipped, source language | — |
| ar | Shipped, machine-assisted, pending native review | RTL, Eastern Arabic-Indic numerals, 6 CLDR plural categories; pairs with the existing Islamic-finance mode and GCC currency registry |
| pl | Planned | Slavic plural rules (one/few/many/other); PLN already in `BankCurrencies` |
| de | Planned | Tier-1 EU market |
| fr | Planned | Tier-1 EU and North/West Africa |
| es | Planned | Tier-1 EU and Latin America |
| pt-BR | Planned | BRL already in `BankCurrencies` |
| tr | Planned | TRY already in `BankCurrencies` |
| zh-Hans | Planned | CJK coverage, zero-plural language |
| ja | Planned | CJK coverage, zero-decimal JPY already modeled |

Arabic and Polish are the deliberate stress cases: together they exercise
every CLDR plural category the other eight would miss.

Country names, currency names, and Hijri month names stay English and are
**not** in the catalogue. Those belong to CLDR, and shipping our own 249
country names would be a worse asset than not shipping them.

## Per-script font stacks

Current position: the package bundles four Latin families (Space Grotesk,
Nunito, Fredoka, Noto Serif Display) plus glyph-coverage subsets for
currency symbols, Arabic, and Devanagari under `lib/src/assets/fonts/`.

The token text styles in `lib/src/theme/tokens.dart` intentionally omit
`fontFamily`, so any widget outside a preset inherits the platform font,
which already provides Arabic and CJK glyph fallback on iOS and Android.
Presets apply their brand family through `BankThemeData.fontFamily`
(`lib/src/theme/extensions.dart`), and Flutter falls back to platform fonts
for glyphs the Latin families lack.

`kBankFontFallback` supplies the bundled coverage subsets, and
`test/flutter_test_config.dart` registers them under their
package-qualified names so goldens render real glyphs rather than tofu.

Committed direction, v0.5.0: documented per-script stacks for long-form
Arabic (Noto Naskh Arabic) and CJK (Noto Sans SC/TC/JP), plus guidance on
keeping tabular-figure numerals in the `numeralHero` through `numeralSmall`
styles when a fallback engages.

## Hijri (Umm al-Qura) dual-calendar support

Current position: implemented for conversion and dual rendering.
`BankHijriDate` (`lib/src/common/bank_hijri_date.dart`) does tabular Umm
al-Qura conversion inside the package, so behaviour does not depend on
platform ICU versions, and `BankDateFormatter.formatDual` renders
`30 Jun 2026 (15 Muharram 1448 AH)` with digits converted through
`NumeralStyle`.

Known gap: there is no `calendar` field on `BankUiScopeData`, so dual
rendering is per-call rather than scope-wide, and Hijri month names are
English transliterations passed as a `hijriMonthNames` argument rather than
catalogue messages. Both close at v0.5.0 (2027-02-28), at which point
`BankTransactionGroupHeader`, `BankStatementListTile`, and the zakat due
date become the first scope-driven consumers.

## Arabic number formatting and the SAR symbol

`NumeralStyle.easternArabicIndic` (`lib/src/theme/numeral_style.dart`)
converts formatted output to Eastern Arabic-Indic digits after `intl`
formatting, preserving structure; it is scope-wide via
`BankUiScopeData.numeralStyle` and covered by `test/numeral_style_test.dart`
and `test/money_test.dart`.

`BankMoneyFormatter.format` takes a `locale`, and kit widgets pass
`context.bankLocale`, so grouping and separators follow the app locale
(German `1.234,56`, French `1 234,56`, Indian lakh grouping `1,23,456`).

**Do not apply `NumeralStyle` to machine identifiers.** Arabic-Indic digits
are bidi class AN, which UAX #9 rule W7 never retypes to L, so a card
number or sort code rendered in Arabic-Indic digits reverses its group
order in *both* directions and inside a directional isolate. No markup
repairs it. `BankAccountNumberText` and `BankPhoneInputField` therefore
render identifiers in ASCII digits regardless of scope numeral style;
amounts, dates, and counts still convert. `test/bidi_identifier_test.dart`
measures this with `getBoxesForRange`.

Currency symbology is registry-driven: 59 currencies in `BankCurrencies`
(`lib/src/models/bank_currency.dart`) with ISO 4217 minor units. The
Arabic-script symbols are wrapped in FSI/PDI directional isolates
(U+2068/U+2069) via `BankCurrency.embeddableSymbol`, so they compose
correctly inside LTR amounts. SAR defaults to the traditional abbreviation
because the official riyal symbol (U+20C1, adopted by SAMA in 2025,
Unicode 17) is still absent from most shipped fonts and would render as a
placeholder box; apps whose bundled font carries the glyph opt in with one
documented `BankCurrencies.register` call.

## RTL verification status and evidence

What the source shows: 107 `EdgeInsetsDirectional` usages across 61 files;
grouped machine identifiers isolated with LRI/PDI or pinned LTR
(`lib/src/common/bank_bidi.dart` and its call sites); direction-aware
widgets that read `Directionality.of(context)`
(`lib/src/onboarding/bank_step_progress_indicator.dart`,
`lib/src/insights/bank_financial_health_score.dart`,
`lib/src/onboarding/bank_onboarding_carousel.dart`,
`lib/src/common/bank_period_selector.dart`).

Three files still use physical-edge insets
(`bank_pin_keypad.dart`, `bank_portfolio_performance_chart.dart`,
`bank_cashflow_chart.dart`); all three convert at v0.5.0.

What verification exists today:

- `test/golden/preset_goldens_test.dart` includes an RTL balance tile with
  Arabic copy and a currency-and-script no-tofu case, rendered with the
  bundled font fallbacks.
- `test/bidi_identifier_test.dart` measures glyph positions under
  `TextDirection.rtl` rather than asserting on strings, so it catches
  reordering that a `contains` check would miss.
- `test/localization_test.dart` pumps widgets under `Locale('ar')` with the
  delegates installed and asserts both that Arabic renders and that English
  is byte-for-byte unchanged.
- The showcase (`example/lib/showcase/showcase.dart`) has a real language
  switch: picking العربية changes the language *and* the direction, rather
  than mirroring an English layout.

Known gap: `doc/screenshots/` contains no RTL captures, and
`tool/screenshots.mjs` does not drive the harness's `dir=rtl` parameter.
An RTL capture matrix lands at v0.5.0.
