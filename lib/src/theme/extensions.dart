import 'package:flutter/material.dart';

import 'bank_theme_data.dart';
import 'presets/bloom.dart';
import 'presets/heritage.dart';
import 'presets/studio.dart';
import 'presets/voltage.dart';
import 'tokens.dart';

/// The three first-party design presets shipped with Bank UI Kit.
///
/// Pass a value to [BankPresetApply.apply] to merge the preset into an
/// existing [ThemeData]:
///
/// ```dart
/// MaterialApp(
///   theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
/// );
/// ```
///
/// To build a fully custom theme instead of using a preset, see
/// [BankThemeData.custom] and [BankThemeDataApply.withBankTheme].
enum BankPreset {
  /// Electric dark-native preset with violet/cyan gradient and glow effects.
  voltage,

  /// Restrained editorial preset with petrol-green primary and rectangular UI.
  studio,

  /// Warm consumer-friendly preset with coral primary and pill-shaped UI.
  bloom,

  /// Institutional Islamic banking preset: deep forest-green + muted gold.
  heritage,
}

/// Convenience extension that applies a [BankPreset] to a [ThemeData].
extension BankPresetApply on BankPreset {
  /// Merges this preset's [BankThemeData] extension and [ColorScheme] into
  /// [base], returning the resulting [ThemeData].
  ThemeData apply(ThemeData base) => switch (this) {
        BankPreset.voltage => BankVoltageTheme.applyTo(base),
        BankPreset.studio => BankStudioTheme.applyTo(base),
        BankPreset.bloom => BankBloomTheme.applyTo(base),
        BankPreset.heritage => BankHeritageTheme.applyTo(base),
      };
}

/// Extension on [ThemeData] for wiring a [BankThemeData] without a preset.
///
/// Use this together with [BankThemeData.custom] when you want full control
/// over every token without starting from a built-in preset:
///
/// ```dart
/// final myBankTheme = BankThemeData.custom(
///   primary: const Color(0xFF0052CC),
///   brightness: Brightness.light,
///   cardRadius: const BorderRadius.all(Radius.circular(20)),
/// );
///
/// MaterialApp(
///   theme: ThemeData.light(useMaterial3: true).withBankTheme(myBankTheme),
///   darkTheme: ThemeData.dark(useMaterial3: true).withBankTheme(
///     BankThemeData.custom(
///       primary: const Color(0xFF4D9DFF),
///       brightness: Brightness.dark,
///     ),
///   ),
/// );
/// ```
///
/// `withBankTheme` registers `bankTheme` as a [ThemeExtension] **and**
/// synchronises the Material [ColorScheme] to the bank theme's palette, so
/// Material widgets and Bank UI Kit widgets stay visually consistent.
extension BankThemeDataApply on ThemeData {
  /// Returns a copy of this [ThemeData] with [bankTheme] registered as a
  /// [ThemeExtension] and the [ColorScheme] aligned to the bank theme's
  /// primary, surface and on-surface colours.
  ThemeData withBankTheme(BankThemeData bankTheme) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: bankTheme.primary,
      brightness: brightness,
      primary: bankTheme.primary,
      onPrimary: bankTheme.onPrimary,
      surface: bankTheme.surface,
      onSurface: bankTheme.onSurface,
    );
    final themed = copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bankTheme.background,
      cardColor: bankTheme.surface,
      extensions: <ThemeExtension<dynamic>>[bankTheme],
    );
    // Always attach the glyph-coverage fallback fonts so currency symbols,
    // Arabic script, and non-Latin numerals render; wire the brand font too
    // when set (apply() ignores a null family).
    return themed.copyWith(
      textTheme: themed.textTheme.apply(
        fontFamily: bankTheme.fontFamily,
        fontFamilyFallback: kBankFontFallback,
      ),
      primaryTextTheme: themed.primaryTextTheme.apply(
        fontFamily: bankTheme.fontFamily,
        fontFamilyFallback: kBankFontFallback,
      ),
    );
  }
}
