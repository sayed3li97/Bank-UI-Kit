import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Studio** preset: a restrained, editorial banking aesthetic.
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
  // Card-face gradients
  //
  // A refinement of the primary -> primaryVariant pair the cards previously
  // fell back to: same petrol hues, three stops on a subtle diagonal so the
  // face reads as brushed material rather than a flat fill. Studio keeps
  // its editorial restraint: no pattern, no display face.
  // ---------------------------------------------------------------------------

  static const LinearGradient _lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A7C80), Color(0xFF3E7074), Color(0xFF326669)],
  );

  static const LinearGradient _darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E9EA3), Color(0xFF528D92), Color(0xFF457D82)],
  );

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => const BankThemeData(
        primary: Color(0xFF4A7C80),
        primaryVariant: Color(0xFF326669),
        onPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFF4F4F2),
        onSurface: Color(0xFF1C1C1E),
        onSurfaceVariant: Color(0xFF636366),
        background: Color(0xFFFAFAF8),
        onBackground: Color(0xFF1C1C1E),
        outline: Color(0xFFEFEFEB),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        cardRadius: BorderRadius.all(Radius.circular(16)),
        buttonRadius: BorderRadius.all(Radius.circular(12)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(24)),
        chipRadius: BorderRadius.all(Radius.circular(10)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/SpaceGrotesk',
        useGlow: false,
        cardSurfaceGradient: _lightCardGradient,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => const BankThemeData(
        primary: Color(0xFF5E9EA3),
        primaryVariant: Color(0xFF7BB8BC),
        onPrimary: Color(0xFF1C1C1E),
        surface: Color(0xFF2C2C2A),
        surfaceVariant: Color(0xFF3A3A38),
        onSurface: Color(0xFFF5F5F3),
        onSurfaceVariant: Color(0xFFAEAEB2),
        background: Color(0xFF1E1E1C),
        onBackground: Color(0xFFF5F5F3),
        outline: Color(0xFF333331),
        positiveBalance: BankTokens.positiveBalanceDark,
        negativeBalance: BankTokens.negativeBalanceDark,
        pending: BankTokens.pendingDark,
        frozen: BankTokens.frozen,
        cardRadius: BorderRadius.all(Radius.circular(16)),
        buttonRadius: BorderRadius.all(Radius.circular(12)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(24)),
        chipRadius: BorderRadius.all(Radius.circular(10)),
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/SpaceGrotesk',
        useGlow: false,
        cardSurfaceGradient: _darkCardGradient,
      );

  // ---------------------------------------------------------------------------
  // applyTo
  // ---------------------------------------------------------------------------

  /// Returns a new [ThemeData] derived from [base] with the Studio preset
  /// applied as a [ThemeExtension] and the Material 3 [ColorScheme] wired to
  /// the preset's palette.
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
    // Always attach the glyph-coverage fallback fonts; also wire the brand
    // font family when the preset defines one (apply() ignores a null family).
    // The optional display face is layered on afterwards so headlines can
    // carry a distinct brand voice (no-op when displayFontFamily is null).
    return themed.copyWith(
      textTheme: bank.applyDisplayFontTo(
        themed.textTheme.apply(
          fontFamily: bank.fontFamily,
          fontFamilyFallback: kBankFontFallback,
        ),
      ),
      primaryTextTheme: bank.applyDisplayFontTo(
        themed.primaryTextTheme.apply(
          fontFamily: bank.fontFamily,
          fontFamilyFallback: kBankFontFallback,
        ),
      ),
    );
  }
}
