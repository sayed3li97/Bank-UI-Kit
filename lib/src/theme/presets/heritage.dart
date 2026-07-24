import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../card_pattern.dart';
import '../tokens.dart';

/// The **Heritage** preset: an institutional Islamic banking aesthetic.
///
/// Characteristics:
/// - Deep forest-green primary (#006341 light / #4DA67A dark)
/// - Muted gold accent (#C8A96E) available via [BankHeritageTheme.gold]
/// - Crisp-white surfaces on a soft sage-tinted background
/// - 16 px card corners: professional but approachable
/// - Subtle emerald gradient for card and hero surfaces
/// - No glow, no neon: calm authority and institutional trust
class BankHeritageTheme {
  const BankHeritageTheme._();

  /// Muted gold used for premium highlights and decorative accents.
  static const Color gold = Color(0xFFC8A96E);

  static const LinearGradient _lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6B47), Color(0xFF03402A)],
  );

  static const LinearGradient _darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F8259), Color(0xFF123A28)],
  );

  // ---------------------------------------------------------------------------
  // Card-face gradients
  //
  // Institutional card faces: deep green sliding to a darker green within a
  // deliberately small hue range — authority, not fireworks. Overlaid with
  // an eight-point-star lattice in onPrimary at 7 % alpha.
  // ---------------------------------------------------------------------------

  static const LinearGradient _lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6B47), Color(0xFF064F34), Color(0xFF03402A)],
  );

  static const LinearGradient _darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F8259), Color(0xFF1D5A3D), Color(0xFF123A28)],
  );

  /// Lattice ink: onPrimary (white) at 7 % alpha.
  static const Color _lightLatticeInk = Color(0x12FFFFFF);

  /// Lattice ink for the dark variant: its onPrimary at 7 % alpha.
  static const Color _darkLatticeInk = Color(0x1200291A);

  // ---------------------------------------------------------------------------
  // Light
  // ---------------------------------------------------------------------------

  static BankThemeData light() => const BankThemeData(
        primary: Color(0xFF006341),
        primaryVariant: Color(0xFF004A2F),
        onPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFF1EFE8),
        onSurface: Color(0xFF171E19),
        onSurfaceVariant: Color(0xFF6B7268),
        background: Color(0xFFF8F7F3),
        onBackground: Color(0xFF171E19),
        outline: Color(0xFFECEAE2),
        positiveBalance: BankTokens.positiveBalance,
        negativeBalance: BankTokens.negativeBalance,
        pending: BankTokens.pending,
        frozen: BankTokens.frozen,
        accentGradient: _lightGradient,
        cardRadius: BorderRadius.all(Radius.circular(20)),
        buttonRadius: BorderRadius.all(Radius.circular(14)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        displayFontFamily: 'packages/bank_ui_kit/NotoSerifDisplay',
        cardSurfaceGradient: _lightCardGradient,
        cardPattern: BankCardPattern.lattice,
        cardPatternColor: _lightLatticeInk,
      );

  // ---------------------------------------------------------------------------
  // Dark
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => const BankThemeData(
        primary: Color(0xFF4DA67A),
        primaryVariant: Color(0xFF6DBF94),
        onPrimary: Color(0xFF00291A),
        surface: Color(0xFF17211C),
        surfaceVariant: Color(0xFF202C25),
        onSurface: Color(0xFFE8F0E8),
        onSurfaceVariant: Color(0xFF9AB59A),
        background: Color(0xFF0E1613),
        onBackground: Color(0xFFE8F0E8),
        outline: Color(0xFF24302A),
        positiveBalance: Color(0xFF4DA67A),
        negativeBalance: BankTokens.negativeBalanceDark,
        pending: BankTokens.pendingDark,
        frozen: BankTokens.frozen,
        accentGradient: _darkGradient,
        cardRadius: BorderRadius.all(Radius.circular(20)),
        buttonRadius: BorderRadius.all(Radius.circular(14)),
        sheetRadius: BorderRadius.vertical(top: Radius.circular(28)),
        chipRadius: BorderRadius.all(Radius.circular(10)),
        elevationLow: 0,
        elevationMedium: 2,
        elevationHigh: 4,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/SpaceGrotesk',
        useGlow: false,
        displayFontFamily: 'packages/bank_ui_kit/NotoSerifDisplay',
        cardSurfaceGradient: _darkCardGradient,
        cardPattern: BankCardPattern.lattice,
        cardPatternColor: _darkLatticeInk,
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

    // Always attach the glyph-coverage fallback fonts; also wire the brand
    // font family when the preset defines one (apply() ignores a null family).
    // The NotoSerifDisplay display face is layered on afterwards: serif
    // headlines over Space Grotesk body — the institutional voice.
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
