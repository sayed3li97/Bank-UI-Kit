import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Bloom** preset — a warm, consumer-friendly banking aesthetic.
///
/// Characteristics:
/// - Coral primary (#FF6B6B light / #FF8585 dark) with navy accent
/// - Warm cream / deep teal neutrals
/// - Fully-pill buttons and chips for a friendly, approachable feel
/// - Generous 20 px card radius and 28 px sheet radius
/// - No accent gradient, no glow — warmth is conveyed through colour alone
/// - `elevationLow` carries a subtle warm-tinted shadow (modelled as a very
///   low opacity value; the host app applies it via [BoxShadow.blurRadius])
class BankBloomTheme {
  const BankBloomTheme._();

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => BankThemeData(
        primary: const Color(0xFFFF6B6B),
        primaryVariant: const Color(0xFF1A3557),
        onPrimary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFFFF3EE),
        onSurface: const Color(0xFF1A2030),
        onSurfaceVariant: const Color(0xFF6B7280),
        background: const Color(0xFFFFF9F5),
        onBackground: const Color(0xFF1A2030),
        outline: const Color(0xFFF0E8E4),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: null,
        cardRadius: const BorderRadius.all(Radius.circular(20)),
        buttonRadius: const BorderRadius.all(Radius.circular(999)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        chipRadius: const BorderRadius.all(Radius.circular(999)),
        // 0.02 signals a warm-tinted shadow at very low opacity.
        // Consumers map this to a BoxShadow with a warm colour.
        elevationLow: 0.02,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'Nunito',
        useGlow: false,
        glowColor: null,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => BankThemeData(
        primary: const Color(0xFFFF8585),
        primaryVariant: const Color(0xFF4A7FBF),
        onPrimary: const Color(0xFF1A2030),
        surface: const Color(0xFF243344),
        surfaceVariant: const Color(0xFF2C3E50),
        onSurface: const Color(0xFFF5F0EC),
        onSurfaceVariant: const Color(0xFFB0B8C4),
        background: const Color(0xFF1C2A3A),
        onBackground: const Color(0xFFF5F0EC),
        outline: const Color(0xFF2C3A4A),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: null,
        cardRadius: const BorderRadius.all(Radius.circular(20)),
        buttonRadius: const BorderRadius.all(Radius.circular(999)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        chipRadius: const BorderRadius.all(Radius.circular(999)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'Nunito',
        useGlow: false,
        glowColor: null,
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Bloom preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's coral primary colour.
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
