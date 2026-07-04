# White-Label and Multi-Brand Operating Model

This document states how a bank ships two or more brands from one
`bank_ui_kit` codebase: which visual decisions are brand-overridable today,
which become overridable on the dated roadmap, how dark mode is derived, how
a multi-brand app is structured, and how visual regressions are caught per
brand on every kit upgrade. It follows the same rule as
`docs/enterprise/versioning-and-releases.md`: where the kit has not yet
reached a stated target, it says so and gives the committed direction.

Scope: version 0.1.0, 141 exported widgets across six entry points, themed
through one `ThemeExtension` (`BankThemeData` in
`lib/src/theme/bank_theme_data.dart`) that widgets read at 177 call sites
via `BankThemeData.of(context)`.

## The no-fork customization guarantee

A brand is expressed as data, never as a source patch. The guarantee: every
visual decision a widget makes is either (a) a `BankThemeData` field
overridable through `BankThemeData.custom`, `copyWith`, or a preset, or
(b) a named constant in `lib/src/theme/tokens.dart` scheduled below to move
into the theme. No supported customization requires forking `lib/`, and any
branding need that does is treated as a defect in the theming contract, not
a limitation the adopter absorbs. `test/theme_test.dart` verifies that all
four presets (`studio`, `voltage`, `bloom`, `heritage` in
`lib/src/theme/extensions.dart`) register the extension correctly.

## Theming depth: current position and roadmap

`BankThemeData` carries 29 brand decisions today: 10 palette roles, 4
semantic financial colors (`positiveBalance`, `negativeBalance`, `pending`,
`frozen`), 4 shape radii, 3 elevation levels, 4 numeral text styles with
tabular figures, `fontFamily`, `accentGradient`, and the glow pair. The
remaining axes live in `BankTokens` as compile-time constants, which makes
them consistent but not yet per-brand. The plan moves each axis into the
theme extension, additively, on the release train defined in
`docs/enterprise/versioning-and-releases.md`:

| Axis | Current position | Committed direction |
|------|------------------|---------------------|
| Spacing and density | 10-stop 4 pt grid, `BankTokens.space1` to `space16`, package-global constants | `BankSpacingTheme` extension with a density multiplier (compact, standard, comfortable) so a brand sets density once; widgets migrate from `BankTokens` reads to theme reads with unchanged defaults |
| Motion | 4 durations (150, 250, 400, 600 ms) and 3 curves in `BankTokens` | `BankMotionTheme` with per-brand duration scale and curve set, plus a reduce-motion switch honoring `MediaQuery.disableAnimations` |
| Text theme | 12 named styles (`displayLarge` to `labelSmall`) in `BankTokens`; only the 4 numeral styles and `fontFamily` are theme-carried today | Full 16-style `BankTextTheme` on the extension; `withBankTheme` already applies `fontFamily` across `ThemeData.textTheme`, so font swapping works now |
| Icons | `BankIcons` (`lib/src/common/bank_icon_spec.dart`): 84 semantic roles mapped to Material Symbols outlined, plus `BankIcons.forCategoryName` | `BankIconTheme`: the same 84 role names resolved through the theme, so a brand supplies its own icon font or SVG set per role without touching call sites |
| Illustrations | Widget-level slots exist (`BankEmptyStateView.illustration`, capped at 180 px; `BankSharedGoalProgressCard.illustration`; `BankErrorStateView.icon`); the kit deliberately bundles no illustration assets | An illustration resolver on the theme: named slots (empty-transactions, error-network, onboarding-welcome, and the other states in `lib/src/states/`) mapped to per-brand builders, with the current explicit parameters kept as overrides |
| Per-component overrides | Widgets read the shared `BankThemeData`; no component-scoped theme objects | Component theme classes for the highest-variance surfaces first (`BankVirtualCardWidget`, `BankAppBar`, `BankBottomNavBar`, `BankTransactionListTile`), each nestable in the extension and defaulting to the shared tokens |

Every migration in this table is additive: existing `BankTokens` constants
remain valid, and the theme fields default to them, so 0.x adopters upgrade
without call-site changes.

## Dark derivation: replacing the generic grey path

Current position, stated plainly. The four presets hand-author their dark
palettes; `lib/src/theme/presets/heritage.dart` derives its dark surfaces
from the brand green (surface `0xFF17211C`, background `0xFF0E1613`), which
is the standard the kit holds itself to. `BankThemeData.custom`, however,
falls back to fixed neutral greys for any dark field the adopter omits:
surface `0xFF2C2C2E`, surfaceVariant `0xFF3A3A3C`, background `0xFF1C1C1E`,
outline `0xFF48484A` (`lib/src/theme/bank_theme_data.dart`). Those are iOS
system greys, serviceable and legible, but brand-agnostic: two banks that
only set `primary` get identical dark surfaces.

The committed dark-derivation spec replaces that path in the `custom`
factory, keeping explicit overrides authoritative:

1. Surface tonal ladder. Background, surface, and surfaceVariant become
   three steps of one ladder produced by blending 2 to 8 percent of the
   brand hue into near-black, the technique `heritage.dart` applies by
   hand. One brand color in, a coherent branded dark set out.
2. Elevation overlays. In dark mode, raised surfaces read the existing
   `elevationLow`, `elevationMedium`, and `elevationHigh` fields and apply
   a white overlay stepped per level, instead of relying on shadows that
   have no contrast against dark backgrounds.
3. Dark-appropriate shadows. `BankTokens.shadowCard`, `shadowFloating`,
   and `shadowHero` are tinted with light-mode ink (`0x101828`) and are
   correct only on light surfaces. The spec adds dark counterparts with
   higher-alpha pure black and shorter blur, selected by brightness, and
   keeps the `useGlow` path (`voltage` preset) as the third rendering mode.

Acceptance for this work is contrast-checked: every ladder step must hold
the ratios documented in `docs/enterprise/accessibility-conformance.md`.

## Multi-brand reference: two brands, one codebase

What ships today: one example app (`example/lib/main.dart`) that runs all
four presets behind a runtime switcher, plus a second full dashboard
(`example/lib/demo/heritage_dashboard.dart` beside
`demo/home_dashboard.dart`) proving that the same widget set renders two
distinct brand identities. Brand state is two objects: the `ThemeData`
produced by `BankPreset.apply` and the `BankUiScopeData` in
`lib/src/scope/bank_ui_scope.dart` (strings, numeral style, privacy mode,
`islamicFinanceMode`). The example switches brands at runtime; it is not
yet split into build flavors.

The committed reference structure, targeted with the v0.3.0 theming work:

1. `brands/retail.dart` and `brands/premier.dart`, each exporting one
   `BankThemeData` pair (light, dark) and one `BankUiScopeData`.
2. A `--dart-define=BRAND` switch in `main.dart` selecting the brand
   config, paired with Android `productFlavors` and iOS schemes so each
   brand builds to its own application id, launcher icon, and store entry.
3. Everything below `MaterialApp` identical between brands: screens under
   `example/lib/screens/` contain zero brand conditionals today, and the
   reference keeps that property as an enforced review rule.

The two-dashboard example is the walkthrough to read now: `HomeDashboard`
under `studio` and `HeritageDashboard` under `heritage` share every widget
(`BankAccountCard`, `BankQuickActionsGrid`, `BankTransactionListTile`) and
differ only in theme and scope data.

## Visual regression: per-brand report on every kit upgrade

Current position. The repository runs a deterministic capture pipeline, not
yet a diff gate. `example/lib/screenshot_harness.dart` renders any screen or
any single gallery component from URL parameters
(`?component=BankBalanceText&preset=studio&dark=0`), and
`tools/screenshots.mjs` drives headless Chromium via Playwright across the
full matrix: 30 screen-level shots (the home dashboard in all 4 presets in
light and dark, 14 journey screens, and cross-preset spot checks) plus 114
components in 4 preset variants, written under `docs/screenshots/` and
`docs/screenshots/components/<preset>/`. Reruns are reproducible, which is
the property a diff workflow needs. `alchemist ^0.10.0` is already pinned
in `pubspec.yaml` dev dependencies; no golden baseline is committed yet.

Committed workflow, due with the v0.3.0 golden baseline (2026-10-31 on the
release table in `docs/enterprise/versioning-and-releases.md`):

1. Golden tests via `alchemist` for every widget in the component registry
   (`example/lib/gallery/component_registry.dart`), executed once per
   brand theme the adopter registers, in light and dark.
2. On each kit version bump, CI re-renders the matrix and diffs against
   the previous baseline per brand, failing on any pixel delta above the
   configured threshold.
3. The output is a per-brand HTML report: changed component, before,
   after, diff mask, so a brand owner reviews an upgrade in minutes and
   intentional changes are accepted by re-recording the baseline in the
   same pull request.

Adopters can run the capture matrix today against their own themes by
pointing the harness at a custom preset; the diff and report layers are the
scheduled additions.

## Segment theming recipe

Theming is subtree-scoped, so one brand can present differently per
customer segment inside one running app. The shipped Islamic-banking
segment is the worked example. To present a Shariah-compliant product area
inside a conventional retail app:

```dart
final base = Theme.of(context);
final segment = BankPreset.heritage.apply(base);

Theme(
  data: segment,
  child: BankUiScope(
    initialData: const BankUiScopeData(islamicFinanceMode: true),
    child: const IslamicProductsSection(),
  ),
);
```

Inside that subtree, widgets pick up the heritage palette and gold accent
(`BankHeritageTheme.gold`), `BankShariahBadge`
(`lib/src/common/bank_shariah_badge.dart`) renders compliance marks, and
rate labels switch to profit-rate terminology through
`BankUiScopeData.islamicFinanceMode`. The same mechanics serve a premium
tier: start from the ambient theme, adjust tokens with
`copyWith(accentGradient: ..., cardRadius: ...)`, and re-wrap via
`withBankTheme`; because `BankThemeData` implements `lerp`, transitions
between segment themes animate through Flutter's standard theme animation.
The forthcoming per-component overrides deepen this recipe; they do not
change its shape.
