# Design tokens

Bank UI Kit treats design tokens as platform-neutral data rather than Dart-only
constants. One source of truth drives Flutter, Figma, native apps, and
server-delivered branding, and each of those reads the same token definitions.

There are two layers.

## 1. Global tokens: `tokens/design-tokens.json`

The single source of truth for the primitive/semantic scalar tokens (colours,
spacing, radius, motion durations, tap target). It is authored in the
[W3C Design Tokens Community Group (DTCG)](https://tr.designtokens.org/format/)
format, so any DTCG-aware tool (Style Dictionary, Figma Variables importers,
Tokens Studio) can consume it directly.

```jsonc
{
  "color":  { "positiveBalance": { "$type": "color", "$value": "#047857" } },
  "space":  { "4": { "$type": "dimension", "$value": "16px" } },
  "radius": { "full": { "$type": "dimension", "$value": "999px" } },
  "duration": { "base": { "$type": "duration", "$value": "250ms" } }
}
```

### Generation & drift guard

`tool/generate_tokens.dart` reads the JSON and writes the generated region of
`lib/src/theme/tokens.dart`. Composite tokens (text styles, easing curves,
elevation shadows) are hand-authored below the generated region and reference
these values.

```bash
dart run tool/generate_tokens.dart          # regenerate tokens.dart
dart run tool/generate_tokens.dart --check   # fail if JSON and Dart disagree
```

CI runs `--check` on every push, so the JSON and the Dart can never silently
diverge.

## 2. Brand/theme tokens: `BankThemeData.toJson` / `fromJson`

Where the global file defines primitives, a brand is a full `BankThemeData`
(colours, shape radii, elevations, gradient, flags). Any brand, including the
four built-in presets, serialises to and from JSON:

```dart
final json = BankPreset.heritage
    .apply(ThemeData.light(useMaterial3: true))
    .extension<BankThemeData>()!
    .toJson();
// { "version": 1, "colors": { "primary": "#006341FF", ... }, "radius": {...} }

final brand = BankThemeData.fromJson(json); // lossless round-trip
```

Colours are emitted as `#RRGGBBAA` hex, which Figma Variables and Style
Dictionary read directly. A few uses follow from this:

- Remote or server-driven branding: deliver a theme as JSON and rebuild it on
  the client with `fromJson`.
- Figma round-trips, using the same token set designers work with in Figma
  Variables.
- Multi-tenant white-label, where you store one JSON per tenant.

Composite numeral `TextStyle`s are structural typography, not brand knobs, so
they are not serialised; `fromJson` restores the `BankTokens` defaults.

### Exported theme token sets: `tokens/themes/`

All four presets × light/dark are exported to `tokens/themes/<preset>.<mode>.json`
as ready-to-consume brand token sets. They are generated, never hand-edited:

```bash
UPDATE_THEME_TOKENS=1 flutter test test/theme_export_test.dart   # regenerate
flutter test test/theme_export_test.dart                          # verify in sync
```

## What is not yet tokenised

Spacing, motion, the full type scale, icons, and shadows are currently package
globals on `BankTokens` rather than per-brand `ThemeExtension`s. Moving those
axes onto the theme (so white-labeling is full theming, not just recolour +
reshape) is the next step on the tokens roadmap; see
[versioning-and-releases.md](versioning-and-releases.md).
