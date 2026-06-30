import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A [ThemeExtension] that carries every Bank UI Kit design decision:
/// brand colours, semantic colours, shape radii, elevation levels,
/// numeral typography, and optional glow / gradient decorations.
///
/// Retrieve from the nearest [BuildContext] with [BankThemeData.of].
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
    this.accentGradient,
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
    this.fontFamily,
    required this.useGlow,
    this.glowColor,
  });

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
      positiveBalance:
          Color.lerp(positiveBalance, other.positiveBalance, t)!,
      negativeBalance:
          Color.lerp(negativeBalance, other.negativeBalance, t)!,
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
        other.glowColor == glowColor;
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
      ]);

  @override
  String toString() => 'BankThemeData('
      'primary: $primary, '
      'useGlow: $useGlow, '
      'fontFamily: $fontFamily'
      ')';
}
