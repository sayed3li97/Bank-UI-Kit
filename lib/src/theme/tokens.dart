import 'package:flutter/widgets.dart';

/// The ISO 7810 ID-1 card aspect ratio (85.6mm x 53.98mm ≈ 1.586), the real
/// proportion of a physical bank card. Payment-card widgets default to this so
/// they read as authentic cards and share one source of truth in a carousel.
const double kBankCardAspectRatio = 1.586;

/// Glyph-coverage fallback font families, applied as `fontFamilyFallback` on
/// every Bank UI Kit text style and preset theme.
///
/// The primary brand font (Space Grotesk / Nunito / a host font) covers Latin;
/// these bundled Noto subsets fill the gaps so currency symbols (₹ ₩ ₫ ₿),
/// Arabic script (ر.س, د.إ), and Arabic-Indic / Persian / Devanagari numerals
/// (٠١٢ ۰۱۲ ०१२) render everywhere — offline, on web without a CDN, and on
/// devices lacking those system fonts. Names are package-qualified so they
/// resolve to the fonts bundled in this package.
const List<String> kBankFontFallback = [
  'packages/bank_ui_kit/NotoSansArabic',
  'packages/bank_ui_kit/NotoSansDevanagari',
  'packages/bank_ui_kit/NotoSansCurrency',
];

/// Design tokens for the Bank UI Kit design system.
///
/// The scalar tokens are **generated** from the platform-neutral W3C DTCG
/// source at `tokens/design-tokens.json` — the single source of truth that also
/// feeds Figma and other platforms. Regenerate with
/// `dart run tool/generate_tokens.dart`; CI fails if the two drift. The
/// generated region covers:
///
/// - semantic colour roles (balances, status, card networks);
/// - the achromatic [neutral0]–[neutral950] ramp, and the
///   surface / ink / border roles cut from it ([surfaceBase], [inkMuted],
///   [borderOutline], …) — so a widget needing "one tier above the canvas"
///   names the tier instead of reaching for a hex;
/// - the [space1]–[space16] grid, radius tiers, and the
///   [iconXSmall]–[iconHero] size ladder;
/// - motion durations, the [lineHeightTight]–[lineHeightAiry] ladder, and
///   [trackingCaps] / [trackingCapsWide] / [trackingNumeralGroup];
/// - the [alphaFaint]–[alphaSecondaryInk] ladder, so a translucent wash picks
///   a rung rather than inventing a decimal;
/// - the [elevationTierFlat]–[elevationTierHero] stacking ranks.
///
/// Composite tokens (easing curves, text styles, numeral styles, and elevation
/// shadows) are hand-authored below the generated region and reference the
/// generated values. Per-brand theme tokens are serialised separately via
/// `BankThemeData.toJson` into `tokens/themes/` (see `test/theme_export_test`).
///
/// The surface / ink / border roles here are the *neutral* defaults a brand
/// starts from: `BankThemeData.custom` seeds its palette from them, and every
/// preset overrides them with its own brand-tinted equivalents.
class BankTokens {
  const BankTokens._();

  // --- GENERATED TOKENS: do not edit by hand (source: tokens/design-tokens.json) ---

  // Colour roles
  /// Positive balances on light surfaces (emerald-700, AA).
  static const Color positiveBalance = Color(0xFF047857);

  /// Negative / overdue amounts on light surfaces (AA).
  static const Color negativeBalance = Color(0xFFC62828);

  /// Pending states on light surfaces (amber-700, AA).
  static const Color pending = Color(0xFFB45309);

  /// Positive balances on dark surfaces (emerald-400, AA).
  static const Color positiveBalanceDark = Color(0xFF34D399);

  /// Negative amounts on dark surfaces (red-400, AA).
  static const Color negativeBalanceDark = Color(0xFFF87171);

  /// Pending states on dark surfaces (amber-400, AA).
  static const Color pendingDark = Color(0xFFFBBF24);

  /// Frozen / suspended accounts or cards.
  static const Color frozen = Color(0xFF8E8E93);

  /// System-level success feedback on light surfaces (emerald-700, AA). Unified
  /// with positiveBalance so one green family reads as "good" everywhere.
  static const Color success = Color(0xFF047857);

  /// System-level success feedback on dark surfaces (emerald-400, AA).
  static const Color successDark = Color(0xFF34D399);

  /// System-level warning feedback on light surfaces (amber-700, AA). Unified
  /// with pending.
  static const Color warning = Color(0xFFB45309);

  /// System-level warning feedback on dark surfaces (amber-400, AA).
  static const Color warningDark = Color(0xFFFBBF24);

  /// System-level danger / destructive-action on light surfaces (AA). Unified
  /// with negativeBalance.
  static const Color danger = Color(0xFFC62828);

  /// System-level danger / destructive-action on dark surfaces (red-400, AA).
  static const Color dangerDark = Color(0xFFF87171);

  /// Investment gain on light surfaces. Same family as positiveBalance /
  /// success — one green per screen.
  static const Color investmentGain = Color(0xFF047857);

  /// Investment gain on dark surfaces (emerald-400, AA).
  static const Color investmentGainDark = Color(0xFF34D399);

  /// Investment loss on light surfaces. Same family as negativeBalance /
  /// danger.
  static const Color investmentLoss = Color(0xFFC62828);

  /// Investment loss on dark surfaces (red-400, AA).
  static const Color investmentLossDark = Color(0xFFF87171);

  /// Available credit headroom. Same family as positiveBalance / success.
  static const Color creditAvailable = Color(0xFF047857);

  /// Credit already utilised. Same family as pending / warning.
  static const Color creditUsed = Color(0xFFB45309);

  /// Mastercard brand mark: red circle.
  static const Color networkMastercardRed = Color(0xFFEB001B);

  /// Mastercard brand mark: amber circle.
  static const Color networkMastercardAmber = Color(0xFFF79E1B);

  /// Mastercard brand mark: the overlapping-lens blend colour.
  static const Color networkMastercardBlend = Color(0xFFFF5F00);

  /// American Express brand blue.
  static const Color networkAmexBlue = Color(0xFF2E77BC);

  // Neutral ramp
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF5F5F5);
  static const Color neutral100 = Color(0xFFF2F2F7);
  static const Color neutral200 = Color(0xFFE5E5EA);
  static const Color neutral300 = Color(0xFFD1D1D6);
  static const Color neutral400 = Color(0xFFAEAEB2);
  static const Color neutral500 = Color(0xFF8E8E93);
  static const Color neutral600 = Color(0xFF636366);
  static const Color neutral700 = Color(0xFF48484A);
  static const Color neutral800 = Color(0xFF3A3A3C);
  static const Color neutral900 = Color(0xFF2C2C2E);
  static const Color neutral950 = Color(0xFF1C1C1E);

  // Surface tiers
  /// The app canvas everything else sits on (neutral-100).
  static const Color surfaceSunken = Color(0xFFF2F2F7);

  /// Dark-mode app canvas (neutral-950).
  static const Color surfaceSunkenDark = Color(0xFF1C1C1E);

  /// Default card / tile surface, one tier above the canvas (neutral-0).
  static const Color surfaceBase = Color(0xFFFFFFFF);

  /// Dark-mode card / tile surface (neutral-900).
  static const Color surfaceBaseDark = Color(0xFF2C2C2E);

  /// Sheets, menus, popovers floating above a card. Identical to base on light:
  /// the tier reads through the shadow, not a tint.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Dark-mode floating surface (neutral-800) — lighter than base, because dark
  /// surfaces cannot borrow depth from a shadow.
  static const Color surfaceRaisedDark = Color(0xFF3A3A3C);

  // On-surface ink tiers
  /// Primary ink: titles, amounts, body copy (neutral-950).
  static const Color inkStrong = Color(0xFF1C1C1E);

  /// Dark-mode primary ink (neutral-50).
  static const Color inkStrongDark = Color(0xFFF5F5F5);

  /// Secondary ink: captions, metadata, supporting copy (neutral-600, AA on
  /// surface.base).
  static const Color inkMuted = Color(0xFF636366);

  /// Dark-mode secondary ink (neutral-400, AA on surface.baseDark).
  static const Color inkMutedDark = Color(0xFFAEAEB2);

  /// Tertiary ink: placeholders and disabled labels (neutral-500). Below AA for
  /// body text by design — never use it for content.
  static const Color inkFaint = Color(0xFF8E8E93);

  /// Dark-mode tertiary ink. The same mid-grey works both ways: it is the one
  /// rung equidistant from both canvases.
  static const Color inkFaintDark = Color(0xFF8E8E93);

  // Border & divider roles
  /// Component outline: inputs, chips, unselected containers (neutral-200).
  static const Color borderOutline = Color(0xFFE5E5EA);

  /// Dark-mode component outline (neutral-700).
  static const Color borderOutlineDark = Color(0xFF48484A);

  /// Rule between rows: primary ink at 8 % alpha. Translucent so it picks up
  /// whatever brand surface is behind it.
  static const Color borderDivider = Color(0x141C1C1E);

  /// Dark-mode rule: primary ink at 14 % alpha — low-luminance contrast
  /// compresses, so dark needs more alpha for the same perceived separation.
  static const Color borderDividerDark = Color(0x24F5F5F5);

  // Spacing (4 pt grid)
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // Border-radius tiers
  static const double radiusSmall = 4;
  static const double radiusMedium = 12;
  static const double radiusLarge = 20;
  static const double radiusXLarge = 28;

  /// Fully-pill / circular shapes (chips, FABs).
  static const double radiusFull = 999;

  // Icon size ladder
  /// Inline with bodySmall / caption: chevrons and status pips inside dense
  /// rows.
  static const double iconXSmall = 14;

  /// Inline with bodyMedium: leading glyphs in list rows and chips.
  static const double iconSmall = 16;

  /// The default UI icon: list-tile trailing affordances, button leading icons.
  static const double iconMedium = 20;

  /// App-bar actions and primary controls (Material's own default).
  static const double iconLarge = 24;

  /// Feature glyphs inside avatars, emblems, and quick-action rings.
  static const double iconXLarge = 32;

  /// Empty-state and success illustrations — the only rung that carries a
  /// screen on its own.
  static const double iconHero = 40;

  // Motion: durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationBase = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationXSlow = Duration(milliseconds: 600);

  // Typography: line-height ladder
  /// Hero numerals: a balance figure is one line, so leading is dead space.
  static const double lineHeightTight = 1.1;

  /// Headlines and large numerals — display text that rarely wraps.
  static const double lineHeightSnug = 1.2;

  /// Labels, captions, and small numerals: single-line UI text.
  static const double lineHeightNormal = 1.3;

  /// bodySmall — dense supporting copy.
  static const double lineHeightRelaxed = 1.4;

  /// bodyMedium — the default reading measure.
  static const double lineHeightLoose = 1.5;

  /// bodyLarge — long-form copy (terms, disclosures).
  static const double lineHeightAiry = 1.6;

  // Typography: tracking (letter-spacing)
  /// The standard ALL-CAPS micro-label (section headers, status pills) at
  /// caption / labelSmall size.
  static const double trackingCaps = 0.8;

  /// ALL-CAPS micro-labels on a card face, where the fill is large and the
  /// label needs to read as engraved.
  static const double trackingCapsWide = 1.2;

  /// Grouped digit runs — card numbers, reference and voucher codes — where the
  /// space is the grouping.
  static const double trackingNumeralGroup = 2.4;

  // Accessibility & sizing
  /// Minimum touch/tap target (WCAG 2.5.5 AAA / iOS HIG).
  static const double minTapTarget = 44;

  /// Below this available width, metric tiles switch to their compact layout.
  static const double tileCompactBreakpoint = 168;

  // Interaction states
  /// Hover state-layer opacity over interactive surfaces (M3-aligned).
  static const double stateLayerHoverOpacity = 0.08;

  /// Pressed state-layer opacity over interactive surfaces.
  static const double stateLayerPressedOpacity = 0.12;

  /// Keyboard-focus state-layer opacity over interactive surfaces.
  static const double stateLayerFocusOpacity = 0.12;

  /// Opacity applied to disabled interactive content (M3-aligned).
  static const double disabledOpacity = 0.38;

  /// Stroke width of the keyboard-focus ring, in logical px.
  static const double focusRingWidth = 2;

  /// Opacity of the primary-coloured keyboard-focus ring.
  static const double focusRingOpacity = 0.4;

  /// Scale applied to a pressable surface while pressed.
  static const double pressScale = 0.98;

  // Alpha ladder
  /// Barely-there wash: card-face pattern inks, decorative tints.
  static const double alphaFaint = 0.06;

  /// Hairline-strength wash: dividers on light surfaces, resting brand tints.
  static const double alphaSubtle = 0.08;

  /// Resting fill of a tinted container (a brand-coloured chip or badge at
  /// rest).
  static const double alphaSoft = 0.1;

  /// Selected / pressed fill of a tinted container.
  static const double alphaMuted = 0.12;

  /// Emphasised tinted fill — the loudest a translucent brand wash gets before
  /// it should become an opaque colour instead.
  static const double alphaStrong = 0.16;

  /// Half-strength: scrims behind modals, and ink that is deliberately
  /// recessive.
  static const double alphaScrim = 0.5;

  /// Supporting ink on a brand-coloured surface (card-face micro-labels), where
  /// a separate grey would fight the fill.
  static const double alphaSecondaryInk = 0.7;

  // Visual effects
  /// Saturation multiplier for frozen card faces (desaturated, not greyed out).
  static const double frozenCardSaturation = 0.35;

  // Elevation tiers (stacking ranks)
  /// Inset or flush surfaces, separated by a hairline alone.
  static const int elevationTierFlat = 0;

  /// Resting cards and tiles.
  static const int elevationTierCard = 1;

  /// Sheets, pickers, popovers — surfaces that overlay resting content.
  static const int elevationTierFloating = 2;

  /// Payment-card faces and feature banners: the one surface per screen allowed
  /// to sit highest.
  static const int elevationTierHero = 3;

  // --- END GENERATED TOKENS ---

  // ---------------------------------------------------------------------------
  // Motion: easing curves
  // ---------------------------------------------------------------------------

  /// General-purpose easing for UI transitions.
  static const Curve curveStandard = Curves.easeInOut;

  /// High-energy easing for primary actions and hero elements.
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Easing for elements entering the screen from off-canvas.
  static const Curve curveDecelerate = Curves.decelerate;

  // ---------------------------------------------------------------------------
  // Typography scale: system fonts
  //
  // Font files are registered in pubspec.yaml but may be stubs in CI.
  // All styles intentionally omit `fontFamily` so the system font is used,
  // making every constant truly `const` and safe to reference from tests.
  //
  // Every style pins `height` to a rung of the line-height ladder. Left
  // unset, Flutter falls back to the loaded font's own metrics, so the same
  // 18 px headline occupies a different box under Space Grotesk, Nunito, and
  // whatever the host device substitutes — which is why vertical rhythm used
  // to drift between presets rather than within one.
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: lineHeightTight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: lineHeightTight,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: lineHeightSnug,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: lineHeightSnug,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: lineHeightNormal,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: lineHeightSnug,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: lineHeightNormal,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: lineHeightNormal,
  );

  /// Hero monetary numeral: large balance displays.
  static const TextStyle numeralHero = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: lineHeightTight,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Large monetary numeral: card balances and summary rows.
  static const TextStyle numeralLarge = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: lineHeightSnug,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Medium monetary numeral: list items and sub-totals.
  static const TextStyle numeralMedium = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: lineHeightSnug,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Small monetary numeral: dense tables and secondary figures.
  static const TextStyle numeralSmall = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: lineHeightNormal,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Sentence-case caption for compact metric tiles and dense metadata.
  ///
  /// Deliberately tracks at `0`: extra letter-spacing is reserved for
  /// all-caps micro-labels ([captionCaps]) — positive tracking on sentence-case
  /// text looks loose, and it breaks cursive joining in Arabic script.
  static const TextStyle caption = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: lineHeightNormal,
  );

  /// [caption] prepared for an ALL-CAPS micro-label: section headers, status
  /// pills, and the "AVAILABLE BALANCE" class of label.
  ///
  /// Exists so the eight hand-rolled `letterSpacing` values that used to sit
  /// on top of [caption] collapse to one decision. Pair it with an uppercased
  /// string — tracking this positive on sentence case reads as a mistake, and
  /// on Arabic script it severs the cursive joins.
  static const TextStyle captionCaps = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: trackingCaps,
    height: lineHeightNormal,
  );

  /// [captionCaps] widened for a micro-label sitting on a card face, where the
  /// fill is large and the label needs to read as engraved rather than typed.
  static const TextStyle captionCapsWide = TextStyle(
    fontFamilyFallback: kBankFontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: trackingCapsWide,
    height: lineHeightNormal,
  );

  // ---------------------------------------------------------------------------
  // Elevation shadows
  //
  // Premium surfaces take depth from soft, layered, low-alpha shadows -
  // never from visible hairline borders. All shadows are tinted with a
  // blue-grey ink (0x101828) so they read as ambient light, not dirt.
  // ---------------------------------------------------------------------------

  /// Resting card shadow: barely-there ambient + soft key light.
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Hovering / floating elements: sheets, pickers, popovers.
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Hero surfaces (virtual cards, feature banners).
  static const List<BoxShadow> shadowHero = [
    BoxShadow(
      color: Color(0x29101828),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Elevation shadows: dark-mode variants
  //
  // On dark surfaces the blue-grey ink tint disappears into the background,
  // so dark shadows are pure-black occlusion at higher alpha — depth reads
  // as blocked light, not as a colour cast.
  // ---------------------------------------------------------------------------

  /// Dark-surface counterpart of [shadowCard].
  static const List<BoxShadow> shadowCardDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Dark-surface counterpart of [shadowFloating].
  static const List<BoxShadow> shadowFloatingDark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Dark-surface counterpart of [shadowHero].
  static const List<BoxShadow> shadowHeroDark = [
    BoxShadow(
      color: Color(0x8C000000),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  /// The resting card shadow appropriate for [b]:
  /// [shadowCardDark] on dark surfaces, [shadowCard] on light ones.
  static List<BoxShadow> shadowCardFor(Brightness b) =>
      b == Brightness.dark ? shadowCardDark : shadowCard;

  /// The floating-element shadow appropriate for [b]:
  /// [shadowFloatingDark] on dark surfaces, [shadowFloating] on light ones.
  static List<BoxShadow> shadowFloatingFor(Brightness b) =>
      b == Brightness.dark ? shadowFloatingDark : shadowFloating;

  /// The hero-surface shadow appropriate for [b]:
  /// [shadowHeroDark] on dark surfaces, [shadowHero] on light ones.
  static List<BoxShadow> shadowHeroFor(Brightness b) =>
      b == Brightness.dark ? shadowHeroDark : shadowHero;

  /// Re-inks [shadows] with [tint], preserving each layer's alpha, blur, and
  /// offset.
  ///
  /// A brand's shadow ink is the one part of the lighting model that is
  /// legitimately brand-specific — a warm palette casts a warm shadow, and the
  /// default blue-grey reads as a foreign cool cast under it. The *geometry*
  /// stays shared, so surfaces still agree on how far off the page they sit;
  /// only the hue moves. Alpha is taken from the original layer, never from
  /// [tint], so a caller cannot accidentally make the shadow opaque by
  /// passing a solid colour.
  static List<BoxShadow> tintShadows(List<BoxShadow> shadows, Color tint) => [
        for (final s in shadows)
          BoxShadow(
            color: tint.withValues(alpha: s.color.a),
            blurRadius: s.blurRadius,
            spreadRadius: s.spreadRadius,
            offset: s.offset,
            blurStyle: s.blurStyle,
          ),
      ];

  // ---------------------------------------------------------------------------
  // Hairlines
  //
  // Where a separation is too subtle for a shadow (list dividers, table
  // rules), use a 1 px hairline derived from the ambient onSurface colour
  // instead of a fixed grey, so it works on any brand surface.
  // ---------------------------------------------------------------------------

  /// Width of hairline separators, in logical px.
  static const double hairlineWidth = 1;

  /// Hairline colour derived from [onSurface] for surfaces of brightness [b].
  ///
  /// Dark surfaces need a slightly stronger alpha for the same perceived
  /// separation (low-luminance contrast compresses).
  static Color hairlineColor(Color onSurface, Brightness b) =>
      onSurface.withValues(alpha: b == Brightness.dark ? 0.14 : 0.08);
}
