import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../tokens.dart';

/// The **Studio** preset: a restrained, editorial banking aesthetic.
///
/// Characteristics:
/// - Warm off-white / off-black neutrals
/// - Petrol green primary (#4A7C80 light / #7BB8BC dark)
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
  //
  // The primary/onPrimary pair is deliberately brighter than the dark card
  // gradient above. A filled CTA is a small patch of colour asked to carry the
  // screen's one action; at the card face's luminance it reads as a disabled
  // slab, because a washed mid-tone plus near-black ink is exactly how
  // Material renders a *disabled* filled button. The fill therefore steps up
  // to the palette's brightest petrol tint (#7BB8BC — 6.3:1 against the card
  // surface, so the button separates from what it sits on) and the ink steps
  // down to a deep petrol black (#0E2426) rather than the neutral #1C1C1E,
  // which was literally the page background colour and made the label read as
  // a hole punched in the fill instead of ink laid on it. The pair clears
  // 7.2:1 — AAA, not the 5.6:1 it used to scrape.
  // ---------------------------------------------------------------------------

  static BankThemeData dark() => const BankThemeData(
        primary: Color(0xFF7BB8BC),
        primaryVariant: Color(0xFF93C5C8),
        onPrimary: Color(0xFF0E2426),
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
      // Material paints its elevation shadows from ColorScheme.shadow; a
      // brand that tints its depth ink must reach Material too, or the two
      // depth systems cast different-coloured light. Null keeps M3's black.
      shadow: bank.shadowTint,
    );

    final themed = base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bank.background,
      cardColor: bank.surface,
      // Pre-M3 widgets read ThemeData.shadowColor instead; keep both in step.
      shadowColor: bank.shadowTint,
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
