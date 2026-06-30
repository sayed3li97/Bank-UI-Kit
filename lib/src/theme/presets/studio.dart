import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Studio** preset — a restrained, editorial banking aesthetic.
///
/// Characteristics:
/// - Warm off-white / off-black neutrals
/// - Petrol green primary (#4A7C80 light / #5E9EA3 dark)
/// - Rectangular cards with rounded corners (12 px)
/// - No gradient, no glow
/// - Standard Material elevations
class BankStudioTheme {
  const BankStudioTheme._();

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => BankThemeData(
        primary: const Color(0xFF4A7C80),
        primaryVariant: const Color(0xFF326669),
        onPrimary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFF4F4F2),
        onSurface: const Color(0xFF1C1C1E),
        onSurfaceVariant: const Color(0xFF636366),
        background: const Color(0xFFFAFAF8),
        onBackground: const Color(0xFF1C1C1E),
        outline: const Color(0xFFE8E8E6),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: null,
        cardRadius: const BorderRadius.all(Radius.circular(12)),
        buttonRadius: const BorderRadius.all(Radius.circular(12)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        chipRadius: const BorderRadius.all(Radius.circular(8)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'SpaceGrotesk',
        useGlow: false,
        glowColor: null,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => BankThemeData(
        primary: const Color(0xFF5E9EA3),
        primaryVariant: const Color(0xFF7BB8BC),
        onPrimary: const Color(0xFF1C1C1E),
        surface: const Color(0xFF2C2C2A),
        surfaceVariant: const Color(0xFF3A3A38),
        onSurface: const Color(0xFFF5F5F3),
        onSurfaceVariant: const Color(0xFFAEAEB2),
        background: const Color(0xFF1E1E1C),
        onBackground: const Color(0xFFF5F5F3),
        outline: const Color(0xFF3A3A38),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: null,
        cardRadius: const BorderRadius.all(Radius.circular(12)),
        buttonRadius: const BorderRadius.all(Radius.circular(12)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        chipRadius: const BorderRadius.all(Radius.circular(8)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'SpaceGrotesk',
        useGlow: false,
        glowColor: null,
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Studio preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's palette.
  static ThemeData applyTo(ThemeData base) {
    final bool isDark = base.brightness == Brightness.dark;
    final BankThemeData bank = isDark ? dark() : light();

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: bank.primary,
      brightness: base.brightness,
      primary: bank.primary,
      onPrimary: bank.onPrimary,
      surface: bank.surface,
      onSurface: bank.onSurface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bank.background,
      cardColor: bank.surface,
      extensions: <ThemeExtension<dynamic>>[bank],
    );
  }
}
