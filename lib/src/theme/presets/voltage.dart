import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Voltage** preset — an electric, dark-native fintech aesthetic.
///
/// Characteristics:
/// - Deep space-blue backgrounds (dark-first; the "light" variant is still dark)
/// - Violet + cyan accent gradient (#7C3AED → #06B6D4 at 135°)
/// - Fully-pill buttons and chips (999 px radius)
/// - Glow-based depth — all Material elevations are 0
/// - [useGlow] = `true` with a 20 % violet glow colour
class BankVoltageTheme {
  const BankVoltageTheme._();

  // ---------------------------------------------------------------------------
  // Shared gradient
  // ---------------------------------------------------------------------------

  static const LinearGradient _accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    // 135 ° is approximated by topLeft → bottomRight in Flutter's coordinate
    // system, which maps to the CSS `135deg` direction.
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
  );

  // ---------------------------------------------------------------------------
  // Light (still a dark palette — Voltage is always dark)
  // ---------------------------------------------------------------------------

  static BankThemeData light() => BankThemeData(
        primary: const Color(0xFF7C3AED),
        primaryVariant: const Color(0xFF06B6D4),
        onPrimary: const Color(0xFFFFFFFF),
        surface: const Color(0xFF252540),
        surfaceVariant: const Color(0xFF2E2E50),
        onSurface: const Color(0xFFF0F0FF),
        onSurfaceVariant: const Color(0xFFA0A0C0),
        background: const Color(0xFF1A1A2E),
        onBackground: const Color(0xFFF0F0FF),
        outline: const Color(0xFF3A3A5A),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: _accentGradient,
        cardRadius: const BorderRadius.all(Radius.circular(16)),
        buttonRadius: const BorderRadius.all(Radius.circular(999)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        chipRadius: const BorderRadius.all(Radius.circular(999)),
        elevationLow: 0,
        elevationMedium: 0,
        elevationHigh: 0,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'SpaceGrotesk',
        useGlow: true,
        glowColor: const Color(0x337C3AED),
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => BankThemeData(
        primary: const Color(0xFF7C3AED),
        primaryVariant: const Color(0xFF06B6D4),
        onPrimary: const Color(0xFFFFFFFF),
        surface: const Color(0xFF1A1A30),
        surfaceVariant: const Color(0xFF2E2E50),
        onSurface: const Color(0xFFF0F0FF),
        onSurfaceVariant: const Color(0xFFA0A0C0),
        background: const Color(0xFF0F0F1A),
        onBackground: const Color(0xFFF0F0FF),
        outline: const Color(0xFF3A3A5A),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: _accentGradient,
        cardRadius: const BorderRadius.all(Radius.circular(16)),
        buttonRadius: const BorderRadius.all(Radius.circular(999)),
        sheetRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        chipRadius: const BorderRadius.all(Radius.circular(999)),
        elevationLow: 0,
        elevationMedium: 0,
        elevationHigh: 0,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'SpaceGrotesk',
        useGlow: true,
        glowColor: const Color(0x337C3AED),
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Voltage preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's violet primary colour.
  ///
  /// Voltage is a dark-first theme; [base.brightness] selects between the two
  /// dark-palette variants but both are dark.
  static ThemeData applyTo(ThemeData base) {
    final bool isDark = base.brightness == Brightness.dark;
    final BankThemeData bank = isDark ? dark() : light();

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: bank.primary,
      brightness: Brightness.dark,
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
