import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Bloom** preset: a warm, consumer-friendly banking aesthetic.
///
/// Characteristics:
/// - Coral primary (#FF6B6B light / #FF8585 dark) with navy accent
/// - Warm cream / deep teal neutrals
/// - Fully-pill buttons and chips for a friendly, approachable feel
/// - Generous 20 px card radius and 28 px sheet radius
/// - No accent gradient, no glow: warmth is conveyed through colour alone
/// - `elevationLow` carries a subtle warm-tinted shadow (modelled as a very
///   low opacity value; the host app applies it via [BoxShadow.blurRadius])
class BankBloomTheme {
  const BankBloomTheme._();

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => const BankThemeData(
        primary: Color(0xFFFF6B6B),
        primaryVariant: Color(0xFF1A3557),
        onPrimary: Color(0xFF1A2030),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFFFF3EE),
        onSurface: Color(0xFF1A2030),
        onSurfaceVariant: Color(0xFF6B7280),
        background: Color(0xFFFFF9F5),
        onBackground: Color(0xFF1A2030),
        outline: Color(0xFFF6EFEA),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        cardRadius: BorderRadius.all(Radius.circular(20)),
        buttonRadius: BorderRadius.all(Radius.circular(999)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(28)),
        chipRadius: BorderRadius.all(Radius.circular(999)),
        // 0.02 signals a warm-tinted shadow at very low opacity.
        // Consumers map this to a BoxShadow with a warm colour.
        elevationLow: 0.02,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/Nunito',
        useGlow: false,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => const BankThemeData(
        primary: Color(0xFFFF8585),
        primaryVariant: Color(0xFF4A7FBF),
        onPrimary: Color(0xFF1A2030),
        surface: Color(0xFF243344),
        surfaceVariant: Color(0xFF2C3E50),
        onSurface: Color(0xFFF5F0EC),
        onSurfaceVariant: Color(0xFFB0B8C4),
        background: Color(0xFF1C2A3A),
        onBackground: Color(0xFFF5F0EC),
        outline: Color(0xFF283646),
        positiveBalance: BankTokens.positiveBalanceDark,
        negativeBalance: BankTokens.negativeBalanceDark,
        pending: BankTokens.pendingDark,
        frozen: BankTokens.frozen,
        cardRadius: BorderRadius.all(Radius.circular(20)),
        buttonRadius: BorderRadius.all(Radius.circular(999)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(28)),
        chipRadius: BorderRadius.all(Radius.circular(999)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/Nunito',
        useGlow: false,
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Bloom preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's coral primary colour.
  static ThemeData applyTo(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final bank = isDark ? dark() : light();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: bank.primary,
      brightness: base.brightness,
      primary: bank.primary,
      onPrimary: bank.onPrimary,
      surface: bank.surface,
      onSurface: bank.onSurface,
    );

    final themed = base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bank.background,
      cardColor: bank.surface,
      extensions: <ThemeExtension<dynamic>>[bank],
    );

    // Wire the preset's brand font into the Material text themes so every
    // descendant Text inherits it (the kit's own styles intentionally omit
    // a family and inherit this default).
    return bank.fontFamily == null
        ? themed
        : themed.copyWith(
            textTheme: themed.textTheme.apply(fontFamily: bank.fontFamily),
            primaryTextTheme:
                themed.primaryTextTheme.apply(fontFamily: bank.fontFamily),
          );
  }
}
