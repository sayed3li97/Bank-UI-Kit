import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'card_pattern.dart';
import 'tokens.dart';

/// A [ThemeExtension] that carries every Bank UI Kit design decision:
/// brand colours, semantic colours, shape radii, elevation levels,
/// numeral typography, and optional glow / gradient decorations.
///
/// ---
///
/// ## Using a built-in preset (recommended starting point)
///
/// ```dart
/// import 'package:bank_ui_kit/core.dart';
///
/// MaterialApp(
///   theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
///   darkTheme: BankPreset.studio.apply(ThemeData.dark(useMaterial3: true)),
/// );
/// ```
///
/// Available presets: `BankPreset.studio`, `BankPreset.voltage`,
/// `BankPreset.bloom`.
///
/// ---
///
/// ## Creating a fully custom theme
///
/// Use [BankThemeData.custom]: supply your brand colour and brightness;
/// every other field is optional with sensible neutral defaults:
///
/// ```dart
/// final myBankTheme = BankThemeData.custom(
///   primary: const Color(0xFF6750A4),
///   brightness: Brightness.light,
///   // optionally override individual tokens:
///   cardRadius: const BorderRadius.all(Radius.circular(20)),
///   useGlow: true,
///   glowColor: const Color(0x336750A4),
/// );
///
/// MaterialApp(
///   theme: ThemeData.light(useMaterial3: true).withBankTheme(myBankTheme),
/// );
/// ```
///
/// The `withBankTheme` extension (on [ThemeData]) wires the extension into
/// Flutter's theme system and synchronises the Material [ColorScheme] to
/// your palette.
///
/// ---
///
/// ## Tweaking a preset
///
/// Start from any preset and override individual fields with [copyWith]:
///
/// ```dart
/// final tweaked = BankPreset.bloom
///     .apply(ThemeData.light(useMaterial3: true))
///     .extension<BankThemeData>()!
///     .copyWith(
///       primary: const Color(0xFFE91E63),
///       cardRadius: const BorderRadius.all(Radius.circular(24)),
///     );
///
/// MaterialApp(
///   theme: ThemeData.light(useMaterial3: true).withBankTheme(tweaked),
/// );
/// ```
///
/// ---
///
/// Retrieve from the nearest [BuildContext] inside any widget with
/// [BankThemeData.of].
@immutable
class BankThemeData extends ThemeExtension<BankThemeData> {
  const BankThemeData({
    required this.primary,
    required this.primaryVariant,
    required this.onPrimary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.outline,
    required this.positiveBalance,
    required this.negativeBalance,
    required this.pending,
    required this.frozen,
    required this.cardRadius,
    required this.buttonRadius,
    required this.sheetRadius,
    required this.chipRadius,
    required this.elevationLow,
    required this.elevationMedium,
    required this.elevationHigh,
    required this.numeralHero,
    required this.numeralLarge,
    required this.numeralMedium,
    required this.numeralSmall,
    required this.useGlow,
    this.accentGradient,
    this.fontFamily,
    this.glowColor,
    this.displayFontFamily,
    this.cardSurfaceGradient,
    this.cardPattern = BankCardPattern.none,
    this.cardPatternColor,
    this.stateLayerHoverOpacity = BankTokens.stateLayerHoverOpacity,
    this.stateLayerPressedOpacity = BankTokens.stateLayerPressedOpacity,
    this.stateLayerFocusOpacity = BankTokens.stateLayerFocusOpacity,
    this.disabledOpacity = BankTokens.disabledOpacity,
    this.pressScale = BankTokens.pressScale,
  });

  // ---------------------------------------------------------------------------
  // Custom-theme factory
  // ---------------------------------------------------------------------------

  /// Creates a [BankThemeData] from a brand [primary] colour and [brightness],
  /// with every other token derived automatically.
  ///
  /// Override any individual field to match your brand: fields you omit
  /// receive sensible neutral defaults that work for both light and dark modes.
  ///
  /// ### Minimal example
  ///
  /// ```dart
  /// final myTheme = BankThemeData.custom(
  ///   primary: const Color(0xFF0052CC),
  ///   brightness: Brightness.light,
  /// );
  ///
  /// MaterialApp(
  ///   theme: ThemeData.light(useMaterial3: true).withBankTheme(myTheme),
  /// );
  /// ```
  ///
  /// ### Full override example
  ///
  /// ```dart
  /// final myTheme = BankThemeData.custom(
  ///   primary: const Color(0xFF0052CC),
  ///   brightness: Brightness.dark,
  ///   cardRadius: const BorderRadius.all(Radius.circular(20)),
  ///   buttonRadius: const BorderRadius.all(Radius.circular(30)),
  ///   useGlow: true,
  ///   glowColor: const Color(0x440052CC),
  ///   fontFamily: 'MyBrandFont',
  ///   accentGradient: const LinearGradient(
  ///     colors: [Color(0xFF0052CC), Color(0xFF00B8D9)],
  ///   ),
  /// );
  /// ```
  factory BankThemeData.custom({
    required Color primary,
    required Brightness brightness,
    Color? primaryVariant,
    Color? onPrimary,
    Color? surface,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? background,
    Color? onBackground,
    Color? outline,
    Color? positiveBalance,
    Color? negativeBalance,
    Color? pending,
    Color? frozen,
    Gradient? accentGradient,
    BorderRadius? cardRadius,
    BorderRadius? buttonRadius,
    BorderRadius? sheetRadius,
    BorderRadius? chipRadius,
    double elevationLow = 1,
    double elevationMedium = 4,
    double elevationHigh = 8,
    TextStyle? numeralHero,
    TextStyle? numeralLarge,
    TextStyle? numeralMedium,
    TextStyle? numeralSmall,
    String? fontFamily,
    bool useGlow = false,
    Color? glowColor,
    String? displayFontFamily,
    Gradient? cardSurfaceGradient,
    BankCardPattern cardPattern = BankCardPattern.none,
    Color? cardPatternColor,
    double stateLayerHoverOpacity = BankTokens.stateLayerHoverOpacity,
    double stateLayerPressedOpacity = BankTokens.stateLayerPressedOpacity,
    double stateLayerFocusOpacity = BankTokens.stateLayerFocusOpacity,
    double disabledOpacity = BankTokens.disabledOpacity,
    double pressScale = BankTokens.pressScale,
  }) {
    final isDark = brightness == Brightness.dark;

    // Derive a slightly lighter/darker variant of the primary colour.
    final derivedPrimaryVariant = Color.lerp(
      primary,
      isDark ? Colors.white : Colors.black,
      0.18,
    )!;

    // Pick a legible on-primary based on perceived luminance.
    final derivedOnPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return BankThemeData(
      primary: primary,
      primaryVariant: primaryVariant ?? derivedPrimaryVariant,
      onPrimary: onPrimary ?? derivedOnPrimary,
      surface: surface ??
          (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF)),
      surfaceVariant: surfaceVariant ??
          (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
      onSurface: onSurface ??
          (isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E)),
      onSurfaceVariant: onSurfaceVariant ??
          (isDark ? const Color(0xFFAEAEB2) : const Color(0xFF636366)),
      background: background ??
          (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
      onBackground: onBackground ??
          (isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E)),
      outline: outline ??
          (isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA)),
      // Financial colours are brightness-aware so custom brands stay legible
      // (WCAG AA) in both modes without the caller having to tune them.
      positiveBalance: positiveBalance ??
          (isDark
              ? BankTokens.positiveBalanceDark
              : BankTokens.positiveBalance),
      negativeBalance: negativeBalance ??
          (isDark
              ? BankTokens.negativeBalanceDark
              : BankTokens.negativeBalance),
      pending:
          pending ?? (isDark ? BankTokens.pendingDark : BankTokens.pending),
      frozen: frozen ?? BankTokens.frozen,
      accentGradient: accentGradient,
      cardRadius: cardRadius ?? const BorderRadius.all(Radius.circular(12)),
      buttonRadius: buttonRadius ?? const BorderRadius.all(Radius.circular(12)),
      sheetRadius:
          sheetRadius ?? const BorderRadius.vertical(top: Radius.circular(20)),
      chipRadius: chipRadius ?? const BorderRadius.all(Radius.circular(8)),
      elevationLow: elevationLow,
      elevationMedium: elevationMedium,
      elevationHigh: elevationHigh,
      numeralHero: numeralHero ?? BankTokens.numeralHero,
      numeralLarge: numeralLarge ?? BankTokens.numeralLarge,
      numeralMedium: numeralMedium ?? BankTokens.numeralMedium,
      numeralSmall: numeralSmall ?? BankTokens.numeralSmall,
      fontFamily: fontFamily,
      useGlow: useGlow,
      glowColor: glowColor,
      displayFontFamily: displayFontFamily,
      cardSurfaceGradient: cardSurfaceGradient,
      cardPattern: cardPattern,
      cardPatternColor: cardPatternColor,
      stateLayerHoverOpacity: stateLayerHoverOpacity,
      stateLayerPressedOpacity: stateLayerPressedOpacity,
      stateLayerFocusOpacity: stateLayerFocusOpacity,
      disabledOpacity: disabledOpacity,
      pressScale: pressScale,
    );
  }

  // ---------------------------------------------------------------------------
  // Brand & surface colours
  // ---------------------------------------------------------------------------

  final Color primary;
  final Color primaryVariant;
  final Color onPrimary;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color background;
  final Color onBackground;
  final Color outline;

  // ---------------------------------------------------------------------------
  // Semantic / financial colours
  // ---------------------------------------------------------------------------

  final Color positiveBalance;
  final Color negativeBalance;
  final Color pending;
  final Color frozen;

  // ---------------------------------------------------------------------------
  // Decoration
  // ---------------------------------------------------------------------------

  /// Optional accent gradient used across interactive surfaces.
  /// `null` in Studio and Bloom presets.
  final Gradient? accentGradient;

  /// Dedicated card-face surface gradient for payment-card widgets.
  ///
  /// Unlike [accentGradient] (which colours buttons, gauges, and other
  /// accents), this gradient is tuned specifically for the large card face:
  /// hue-neighbouring stops on a subtle diagonal that never desaturate to
  /// grey at the midpoint. `null` falls back to [accentGradient] / primary.
  final Gradient? cardSurfaceGradient;

  /// Generative pattern stamped onto card faces; [BankCardPattern.none]
  /// leaves the face as the plain gradient / colour.
  final BankCardPattern cardPattern;

  /// Ink colour for [cardPattern], typically [onPrimary] at 6–10 % alpha.
  /// `null` lets renderers derive a low-alpha default from [onPrimary].
  final Color? cardPatternColor;

  // ---------------------------------------------------------------------------
  // Shape
  // ---------------------------------------------------------------------------

  final BorderRadius cardRadius;
  final BorderRadius buttonRadius;

  /// Sheet radius is typically top-only via [BorderRadius.vertical].
  final BorderRadius sheetRadius;
  final BorderRadius chipRadius;

  // ---------------------------------------------------------------------------
  // Elevation
  // ---------------------------------------------------------------------------

  final double elevationLow;
  final double elevationMedium;
  final double elevationHigh;

  // ---------------------------------------------------------------------------
  // Numeral typography
  // ---------------------------------------------------------------------------

  final TextStyle numeralHero;
  final TextStyle numeralLarge;
  final TextStyle numeralMedium;
  final TextStyle numeralSmall;

  // ---------------------------------------------------------------------------
  // Font
  // ---------------------------------------------------------------------------

  /// Font family name registered in pubspec.yaml, or `null` for system font.
  final String? fontFamily;

  /// Optional brand display / headline face, applied to the display and
  /// large-headline text-theme slots on top of [fontFamily].
  ///
  /// `null` means the brand speaks with a single voice: [fontFamily] is used
  /// everywhere. See [applyDisplayFontTo] for the exact slots affected.
  final String? displayFontFamily;

  // ---------------------------------------------------------------------------
  // Interaction states
  // ---------------------------------------------------------------------------

  /// State-layer opacity while hovered (over [onSurface] or a custom overlay).
  final double stateLayerHoverOpacity;

  /// State-layer opacity while pressed.
  final double stateLayerPressedOpacity;

  /// State-layer opacity while keyboard-focused.
  final double stateLayerFocusOpacity;

  /// Opacity applied to disabled interactive content.
  final double disabledOpacity;

  /// Scale applied to pressable surfaces while pressed.
  final double pressScale;

  // ---------------------------------------------------------------------------
  // Glow (Voltage-only)
  // ---------------------------------------------------------------------------

  /// Whether to render box-shadow glows instead of Material elevations.
  final bool useGlow;

  /// The colour of the glow shadow. Only meaningful when [useGlow] is `true`.
  final Color? glowColor;

  // ---------------------------------------------------------------------------
  // Convenience accessor
  // ---------------------------------------------------------------------------

  /// Retrieves the [BankThemeData] from the nearest [BuildContext].
  ///
  /// Throws a [StateError] if no [BankThemeData] extension is registered on
  /// the ambient [Theme].
  static BankThemeData of(BuildContext context) =>
      Theme.of(context).extension<BankThemeData>()!;

  /// Re-applies [displayFontFamily] to the display / large-headline slots of
  /// [textTheme] (displayLarge/Medium/Small and headlineLarge/Medium).
  ///
  /// Presets and `withBankTheme` call this after the body font has been
  /// wired via `TextTheme.apply(fontFamily: ...)` so brands can pair an
  /// expressive display face with a workhorse body face. Returns [textTheme]
  /// unchanged when [displayFontFamily] is `null`.
  TextTheme applyDisplayFontTo(TextTheme textTheme) {
    final family = displayFontFamily;
    if (family == null) return textTheme;
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontFamily: family),
      displayMedium: textTheme.displayMedium?.copyWith(fontFamily: family),
      displaySmall: textTheme.displaySmall?.copyWith(fontFamily: family),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontFamily: family),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontFamily: family),
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialisation (data-driven & remote branding)
  // ---------------------------------------------------------------------------

  /// Serialises the **brand contract** — every colour, shape radius, elevation,
  /// gradient, and flag — to a plain JSON map. Colours use `#RRGGBBAA` hex so
  /// the output is a Figma-Variables / Style-Dictionary-friendly token set.
  ///
  /// This is the theme half of the design-token story: `tokens.json` is the
  /// global source of truth (see [BankTokens]); [toJson] exports any *brand*
  /// (including the built-in presets) so a bank can round-trip a theme to a
  /// server or design tool. Reconstruct with [BankThemeData.fromJson].
  ///
  /// Composite numeral [TextStyle]s are structural typography, not brand knobs,
  /// so they are not serialised; [BankThemeData.fromJson] restores the
  /// [BankTokens] defaults.
  Map<String, dynamic> toJson() => {
        'version': 1,
        'colors': {
          'primary': _hex(primary),
          'primaryVariant': _hex(primaryVariant),
          'onPrimary': _hex(onPrimary),
          'surface': _hex(surface),
          'surfaceVariant': _hex(surfaceVariant),
          'onSurface': _hex(onSurface),
          'onSurfaceVariant': _hex(onSurfaceVariant),
          'background': _hex(background),
          'onBackground': _hex(onBackground),
          'outline': _hex(outline),
          'positiveBalance': _hex(positiveBalance),
          'negativeBalance': _hex(negativeBalance),
          'pending': _hex(pending),
          'frozen': _hex(frozen),
          if (glowColor != null) 'glowColor': _hex(glowColor!),
          if (cardPatternColor != null)
            'cardPatternColor': _hex(cardPatternColor!),
        },
        'radius': {
          'card': cardRadius.topLeft.x,
          'button': buttonRadius.topLeft.x,
          'sheet': sheetRadius.topLeft.x,
          'chip': chipRadius.topLeft.x,
        },
        'elevation': {
          'low': elevationLow,
          'medium': elevationMedium,
          'high': elevationHigh,
        },
        'interaction': {
          'stateLayerHoverOpacity': stateLayerHoverOpacity,
          'stateLayerPressedOpacity': stateLayerPressedOpacity,
          'stateLayerFocusOpacity': stateLayerFocusOpacity,
          'disabledOpacity': disabledOpacity,
          'pressScale': pressScale,
        },
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (displayFontFamily != null) 'displayFontFamily': displayFontFamily,
        'useGlow': useGlow,
        if (cardPattern != BankCardPattern.none)
          'cardPattern': cardPattern.name,
        if (accentGradient is LinearGradient)
          'accentGradient': _gradientToJson(accentGradient! as LinearGradient),
        if (cardSurfaceGradient is LinearGradient)
          'cardSurfaceGradient':
              _gradientToJson(cardSurfaceGradient! as LinearGradient),
      };

  /// Rebuilds a [BankThemeData] from the map produced by [toJson].
  ///
  /// Unknown / missing keys fall back to neutral defaults, so partial
  /// (e.g. server-delivered) payloads are safe.
  factory BankThemeData.fromJson(Map<String, dynamic> json) {
    final colors =
        (json['colors'] as Map?)?.cast<String, dynamic>() ?? const {};
    final radius =
        (json['radius'] as Map?)?.cast<String, dynamic>() ?? const {};
    final elev =
        (json['elevation'] as Map?)?.cast<String, dynamic>() ?? const {};
    final interaction =
        (json['interaction'] as Map?)?.cast<String, dynamic>() ?? const {};

    Color c(String key, Color fallback) =>
        colors[key] is String ? _parseHex(colors[key] as String) : fallback;
    BorderRadius r(String key, BorderRadius fallback) => radius[key] is num
        ? BorderRadius.all(Radius.circular((radius[key] as num).toDouble()))
        : fallback;
    double e(String key, double fallback) =>
        elev[key] is num ? (elev[key] as num).toDouble() : fallback;
    double i(String key, double fallback) => interaction[key] is num
        ? (interaction[key] as num).toDouble()
        : fallback;

    final sheetR = radius['sheet'] is num
        ? BorderRadius.vertical(
            top: Radius.circular((radius['sheet'] as num).toDouble()),
          )
        : const BorderRadius.vertical(top: Radius.circular(20));

    return BankThemeData(
      primary: c('primary', const Color(0xFF000000)),
      primaryVariant: c('primaryVariant', const Color(0xFF000000)),
      onPrimary: c('onPrimary', const Color(0xFFFFFFFF)),
      surface: c('surface', const Color(0xFFFFFFFF)),
      surfaceVariant: c('surfaceVariant', const Color(0xFFF2F2F7)),
      onSurface: c('onSurface', const Color(0xFF1C1C1E)),
      onSurfaceVariant: c('onSurfaceVariant', const Color(0xFF636366)),
      background: c('background', const Color(0xFFF2F2F7)),
      onBackground: c('onBackground', const Color(0xFF1C1C1E)),
      outline: c('outline', const Color(0xFFE5E5EA)),
      positiveBalance: c('positiveBalance', BankTokens.positiveBalance),
      negativeBalance: c('negativeBalance', BankTokens.negativeBalance),
      pending: c('pending', BankTokens.pending),
      frozen: c('frozen', BankTokens.frozen),
      accentGradient: json['accentGradient'] is Map
          ? _gradientFromJson(
              (json['accentGradient'] as Map).cast<String, dynamic>(),
            )
          : null,
      cardRadius: r('card', const BorderRadius.all(Radius.circular(12))),
      buttonRadius: r('button', const BorderRadius.all(Radius.circular(12))),
      sheetRadius: sheetR,
      chipRadius: r('chip', const BorderRadius.all(Radius.circular(8))),
      elevationLow: e('low', 1),
      elevationMedium: e('medium', 4),
      elevationHigh: e('high', 8),
      numeralHero: BankTokens.numeralHero,
      numeralLarge: BankTokens.numeralLarge,
      numeralMedium: BankTokens.numeralMedium,
      numeralSmall: BankTokens.numeralSmall,
      fontFamily: json['fontFamily'] as String?,
      useGlow: json['useGlow'] as bool? ?? false,
      glowColor: colors['glowColor'] is String
          ? _parseHex(colors['glowColor'] as String)
          : null,
      displayFontFamily: json['displayFontFamily'] as String?,
      cardSurfaceGradient: json['cardSurfaceGradient'] is Map
          ? _gradientFromJson(
              (json['cardSurfaceGradient'] as Map).cast<String, dynamic>(),
            )
          : null,
      cardPattern: json['cardPattern'] is String
          ? BankCardPattern.values.asNameMap()[json['cardPattern']] ??
              BankCardPattern.none
          : BankCardPattern.none,
      cardPatternColor: colors['cardPatternColor'] is String
          ? _parseHex(colors['cardPatternColor'] as String)
          : null,
      stateLayerHoverOpacity:
          i('stateLayerHoverOpacity', BankTokens.stateLayerHoverOpacity),
      stateLayerPressedOpacity:
          i('stateLayerPressedOpacity', BankTokens.stateLayerPressedOpacity),
      stateLayerFocusOpacity:
          i('stateLayerFocusOpacity', BankTokens.stateLayerFocusOpacity),
      disabledOpacity: i('disabledOpacity', BankTokens.disabledOpacity),
      pressScale: i('pressScale', BankTokens.pressScale),
    );
  }

  static String _hex(Color c) {
    final v = c.toARGB32();
    final a = (v >> 24) & 0xFF;
    final r = (v >> 16) & 0xFF;
    final g = (v >> 8) & 0xFF;
    final b = v & 0xFF;
    String h(int x) => x.toRadixString(16).padLeft(2, '0');
    return '#${h(r)}${h(g)}${h(b)}${h(a)}'.toUpperCase();
  }

  static Color _parseHex(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = '${h}FF'; // RRGGBB -> opaque RRGGBBAA
    final r = int.parse(h.substring(0, 2), radix: 16);
    final g = int.parse(h.substring(2, 4), radix: 16);
    final b = int.parse(h.substring(4, 6), radix: 16);
    final a = int.parse(h.substring(6, 8), radix: 16);
    return Color.fromARGB(a, r, g, b);
  }

  static Map<String, dynamic> _gradientToJson(LinearGradient g) => {
        'type': 'linear',
        'begin': [(g.begin as Alignment).x, (g.begin as Alignment).y],
        'end': [(g.end as Alignment).x, (g.end as Alignment).y],
        'colors': [for (final col in g.colors) _hex(col)],
      };

  static LinearGradient _gradientFromJson(Map<String, dynamic> j) {
    final begin = (j['begin'] as List?)?.cast<num>();
    final end = (j['end'] as List?)?.cast<num>();
    return LinearGradient(
      begin: begin != null
          ? Alignment(begin[0].toDouble(), begin[1].toDouble())
          : Alignment.topLeft,
      end: end != null
          ? Alignment(end[0].toDouble(), end[1].toDouble())
          : Alignment.bottomRight,
      colors: [
        for (final c in (j['colors'] as List? ?? const []))
          _parseHex(c as String),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ThemeExtension API
  // ---------------------------------------------------------------------------

  @override
  BankThemeData copyWith({
    Color? primary,
    Color? primaryVariant,
    Color? onPrimary,
    Color? surface,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? background,
    Color? onBackground,
    Color? outline,
    Color? positiveBalance,
    Color? negativeBalance,
    Color? pending,
    Color? frozen,
    Gradient? accentGradient,
    BorderRadius? cardRadius,
    BorderRadius? buttonRadius,
    BorderRadius? sheetRadius,
    BorderRadius? chipRadius,
    double? elevationLow,
    double? elevationMedium,
    double? elevationHigh,
    TextStyle? numeralHero,
    TextStyle? numeralLarge,
    TextStyle? numeralMedium,
    TextStyle? numeralSmall,
    String? fontFamily,
    bool? useGlow,
    Color? glowColor,
    String? displayFontFamily,
    Gradient? cardSurfaceGradient,
    BankCardPattern? cardPattern,
    Color? cardPatternColor,
    double? stateLayerHoverOpacity,
    double? stateLayerPressedOpacity,
    double? stateLayerFocusOpacity,
    double? disabledOpacity,
    double? pressScale,
  }) {
    return BankThemeData(
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      onPrimary: onPrimary ?? this.onPrimary,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      outline: outline ?? this.outline,
      positiveBalance: positiveBalance ?? this.positiveBalance,
      negativeBalance: negativeBalance ?? this.negativeBalance,
      pending: pending ?? this.pending,
      frozen: frozen ?? this.frozen,
      accentGradient: accentGradient ?? this.accentGradient,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      elevationLow: elevationLow ?? this.elevationLow,
      elevationMedium: elevationMedium ?? this.elevationMedium,
      elevationHigh: elevationHigh ?? this.elevationHigh,
      numeralHero: numeralHero ?? this.numeralHero,
      numeralLarge: numeralLarge ?? this.numeralLarge,
      numeralMedium: numeralMedium ?? this.numeralMedium,
      numeralSmall: numeralSmall ?? this.numeralSmall,
      fontFamily: fontFamily ?? this.fontFamily,
      useGlow: useGlow ?? this.useGlow,
      glowColor: glowColor ?? this.glowColor,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      cardSurfaceGradient: cardSurfaceGradient ?? this.cardSurfaceGradient,
      cardPattern: cardPattern ?? this.cardPattern,
      cardPatternColor: cardPatternColor ?? this.cardPatternColor,
      stateLayerHoverOpacity:
          stateLayerHoverOpacity ?? this.stateLayerHoverOpacity,
      stateLayerPressedOpacity:
          stateLayerPressedOpacity ?? this.stateLayerPressedOpacity,
      stateLayerFocusOpacity:
          stateLayerFocusOpacity ?? this.stateLayerFocusOpacity,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      pressScale: pressScale ?? this.pressScale,
    );
  }

  @override
  BankThemeData lerp(BankThemeData? other, double t) {
    if (other == null) return this;
    return BankThemeData(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      positiveBalance: Color.lerp(positiveBalance, other.positiveBalance, t)!,
      negativeBalance: Color.lerp(negativeBalance, other.negativeBalance, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      frozen: Color.lerp(frozen, other.frozen, t)!,
      // Gradients do not have a built-in lerp; snap at the midpoint.
      accentGradient: t < 0.5 ? accentGradient : other.accentGradient,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      buttonRadius: BorderRadius.lerp(buttonRadius, other.buttonRadius, t)!,
      sheetRadius: BorderRadius.lerp(sheetRadius, other.sheetRadius, t)!,
      chipRadius: BorderRadius.lerp(chipRadius, other.chipRadius, t)!,
      elevationLow: lerpDouble(elevationLow, other.elevationLow, t)!,
      elevationMedium: lerpDouble(elevationMedium, other.elevationMedium, t)!,
      elevationHigh: lerpDouble(elevationHigh, other.elevationHigh, t)!,
      numeralHero: TextStyle.lerp(numeralHero, other.numeralHero, t)!,
      numeralLarge: TextStyle.lerp(numeralLarge, other.numeralLarge, t)!,
      numeralMedium: TextStyle.lerp(numeralMedium, other.numeralMedium, t)!,
      numeralSmall: TextStyle.lerp(numeralSmall, other.numeralSmall, t)!,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      useGlow: t < 0.5 ? useGlow : other.useGlow,
      glowColor: Color.lerp(glowColor, other.glowColor, t),
      displayFontFamily: t < 0.5 ? displayFontFamily : other.displayFontFamily,
      cardSurfaceGradient:
          t < 0.5 ? cardSurfaceGradient : other.cardSurfaceGradient,
      cardPattern: t < 0.5 ? cardPattern : other.cardPattern,
      cardPatternColor: Color.lerp(cardPatternColor, other.cardPatternColor, t),
      stateLayerHoverOpacity: lerpDouble(
        stateLayerHoverOpacity,
        other.stateLayerHoverOpacity,
        t,
      )!,
      stateLayerPressedOpacity: lerpDouble(
        stateLayerPressedOpacity,
        other.stateLayerPressedOpacity,
        t,
      )!,
      stateLayerFocusOpacity: lerpDouble(
        stateLayerFocusOpacity,
        other.stateLayerFocusOpacity,
        t,
      )!,
      disabledOpacity: lerpDouble(disabledOpacity, other.disabledOpacity, t)!,
      pressScale: lerpDouble(pressScale, other.pressScale, t)!,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & debug
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankThemeData &&
        other.primary == primary &&
        other.primaryVariant == primaryVariant &&
        other.onPrimary == onPrimary &&
        other.surface == surface &&
        other.surfaceVariant == surfaceVariant &&
        other.onSurface == onSurface &&
        other.onSurfaceVariant == onSurfaceVariant &&
        other.background == background &&
        other.onBackground == onBackground &&
        other.outline == outline &&
        other.positiveBalance == positiveBalance &&
        other.negativeBalance == negativeBalance &&
        other.pending == pending &&
        other.frozen == frozen &&
        other.accentGradient == accentGradient &&
        other.cardRadius == cardRadius &&
        other.buttonRadius == buttonRadius &&
        other.sheetRadius == sheetRadius &&
        other.chipRadius == chipRadius &&
        other.elevationLow == elevationLow &&
        other.elevationMedium == elevationMedium &&
        other.elevationHigh == elevationHigh &&
        other.numeralHero == numeralHero &&
        other.numeralLarge == numeralLarge &&
        other.numeralMedium == numeralMedium &&
        other.numeralSmall == numeralSmall &&
        other.fontFamily == fontFamily &&
        other.useGlow == useGlow &&
        other.glowColor == glowColor &&
        other.displayFontFamily == displayFontFamily &&
        other.cardSurfaceGradient == cardSurfaceGradient &&
        other.cardPattern == cardPattern &&
        other.cardPatternColor == cardPatternColor &&
        other.stateLayerHoverOpacity == stateLayerHoverOpacity &&
        other.stateLayerPressedOpacity == stateLayerPressedOpacity &&
        other.stateLayerFocusOpacity == stateLayerFocusOpacity &&
        other.disabledOpacity == disabledOpacity &&
        other.pressScale == pressScale;
  }

  @override
  int get hashCode => Object.hashAll([
        primary,
        primaryVariant,
        onPrimary,
        surface,
        surfaceVariant,
        onSurface,
        onSurfaceVariant,
        background,
        onBackground,
        outline,
        positiveBalance,
        negativeBalance,
        pending,
        frozen,
        accentGradient,
        cardRadius,
        buttonRadius,
        sheetRadius,
        chipRadius,
        elevationLow,
        elevationMedium,
        elevationHigh,
        numeralHero,
        numeralLarge,
        numeralMedium,
        numeralSmall,
        fontFamily,
        useGlow,
        glowColor,
        displayFontFamily,
        cardSurfaceGradient,
        cardPattern,
        cardPatternColor,
        stateLayerHoverOpacity,
        stateLayerPressedOpacity,
        stateLayerFocusOpacity,
        disabledOpacity,
        pressScale,
      ]);

  @override
  String toString() => 'BankThemeData('
      'primary: $primary, '
      'useGlow: $useGlow, '
      'fontFamily: $fontFamily'
      ')';
}
