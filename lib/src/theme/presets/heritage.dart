import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Heritage** preset — an institutional Islamic banking aesthetic.
///
/// Characteristics:
/// - Deep forest-green primary (#006341 light / #4DA67A dark)
/// - Muted gold accent (#C8A96E) available via [BankHeritageTheme.gold]
/// - Crisp-white surfaces on a soft sage-tinted background
/// - 16 px card corners — professional but approachable
/// - Subtle emerald gradient for card and hero surfaces
/// - No glow, no neon — calm authority and institutional trust
class BankHeritageTheme {
  const BankHeritageTheme._();

  /// Muted gold used for premium highlights and decorative accents.
  static const Color gold = Color(0xFFC8A96E);

  static const LinearGradient _lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006341), Color(0xFF004A2F)],
  );

  static const LinearGradient _darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D7A55), Color(0xFF1A4D35)],
  );

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => const BankThemeData(
        primary: Color(0xFF006341),
        primaryVariant: Color(0xFF004A2F),
        onPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFEFF3F0),
        onSurface: Color(0xFF1A2419),
        onSurfaceVariant: Color(0xFF4D5E4D),
        background: Color(0xFFF5F7F5),
        onBackground: Color(0xFF1A2419),
        outline: Color(0xFFD0DDD0),
        positiveBalance: Color(0xFF00875A),
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: _lightGradient,
        cardRadius: BorderRadius.all(Radius.circular(16)),
        buttonRadius: BorderRadius.all(Radius.circular(12)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(24)),
        chipRadius: BorderRadius.all(Radius.circular(8)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/SpaceGrotesk',
        useGlow: false,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => const BankThemeData(
        primary: Color(0xFF4DA67A),
        primaryVariant: Color(0xFF6DBF94),
        onPrimary: Color(0xFF003822),
        surface: Color(0xFF1A2419),
        surfaceVariant: Color(0xFF243024),
        onSurface: Color(0xFFE8F0E8),
        onSurfaceVariant: Color(0xFF9AB59A),
        background: Color(0xFF111A14),
        onBackground: Color(0xFFE8F0E8),
        outline: Color(0xFF2E3D2E),
        positiveBalance: Color(0xFF4DA67A),
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: _darkGradient,
        cardRadius: BorderRadius.all(Radius.circular(16)),
        buttonRadius: BorderRadius.all(Radius.circular(12)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(24)),
        chipRadius: BorderRadius.all(Radius.circular(8)),
        elevationLow: 0,
        elevationMedium: 2,
        elevationHigh: 4,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/SpaceGrotesk',
        useGlow: false,
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Heritage preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's deep-green primary colour.
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

    return bank.fontFamily == null
        ? themed
        : themed.copyWith(
            textTheme: themed.textTheme.apply(fontFamily: bank.fontFamily),
            primaryTextTheme:
                themed.primaryTextTheme.apply(fontFamily: bank.fontFamily),
          );
  }
}
