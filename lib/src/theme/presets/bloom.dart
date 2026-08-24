import 'package:flutter/material.dart';

import '../bank_theme_data.dart';
import '../card_pattern.dart';
import '../tokens.dart';

/// The **Bloom** preset: a warm, consumer-friendly banking aesthetic.
///
/// Characteristics:
/// - Coral primary (#FF6B6B light / #FF8585 dark) with navy accent
/// - Warm cream / deep teal neutrals
/// - Fully-pill buttons and chips for a friendly, approachable feel
/// - Generous 20 px card radius and 28 px sheet radius
/// - No accent gradient, no glow: warmth is conveyed through colour alone
/// - Light mode casts a **warm-tinted shadow** ([BankThemeData.shadowTint]),
///   which is the preset's differentiator — see [_warmShadowInk]
class BankBloomTheme {
  const BankBloomTheme._();

  /// The ink Bloom's light-mode depth shadows are cast in: a deep plum-brown
  /// drawn from the dark end of the card gradient.
  ///
  /// The kit default is a blue-grey (`0x101828`), which under a cream-and-coral
  /// palette reads as a cold grey smudge rather than as shade. Bloom keeps the
  /// kit's shadow *geometry* — the same blur and offset every other preset
  /// uses — and changes only the hue, so cards sit at the same height but the
  /// light warms as it falls.
  ///
  /// Dark mode deliberately does **not** tint: on a near-black canvas depth
  /// reads as blocked light, and any hue in the occlusion just muddies it —
  /// which is why [BankTokens.shadowCardDark] and friends are pure black.
  static const Color _warmShadowInk = Color(0xFF4A2B33);

  // ---------------------------------------------------------------------------
  // Card-face gradients
  //
  // A naive coral → navy blend desaturates to grey at the RGB midpoint
  // (audit #44). These gradients instead walk through neighbouring warm
  // hues — coral → warm rose → deep plum — so every intermediate colour
  // stays saturated and the face reads like a sunset, never like sludge.
  // ---------------------------------------------------------------------------

  static const LinearGradient _lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B5E), Color(0xFFE4574F), Color(0xFF7A3B5E)],
  );

  static const LinearGradient _darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8585), Color(0xFFD95B58), Color(0xFF6E3556)],
  );

  /// Concentric corner arcs in the dark navy ink at 8 % alpha: the "bloom"
  /// motif, echoing petals opening from the card corner.
  static const Color _arcInk = Color(0x141A2030);

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
        // Was 0.02 — a sentinel meaning "warm-tinted shadow" that no consumer
        // could act on and that Card.elevation rounds away to nothing. The
        // warmth now lives in shadowTint, so this can be a real elevation.
        elevationLow: 1,
        elevationMedium: 4,
        elevationHigh: 8,
        numeralHero: BankTokens.numeralHero,
        numeralLarge: BankTokens.numeralLarge,
        numeralMedium: BankTokens.numeralMedium,
        numeralSmall: BankTokens.numeralSmall,
        fontFamily: 'packages/bank_ui_kit/Nunito',
        useGlow: false,
        displayFontFamily: 'packages/bank_ui_kit/Fredoka',
        cardSurfaceGradient: _lightCardGradient,
        cardPattern: BankCardPattern.arcs,
        cardPatternColor: _arcInk,
        shadowTint: _warmShadowInk,
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
        displayFontFamily: 'packages/bank_ui_kit/Fredoka',
        cardSurfaceGradient: _darkCardGradient,
        cardPattern: BankCardPattern.arcs,
        cardPatternColor: _arcInk,
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
      // Material paints Card / Material / AppBar elevation shadows from
      // ColorScheme.shadow, so wiring the warm ink here is what turns Bloom's
      // elevation contract into pixels. Null leaves M3's default black.
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
    // The Fredoka display face is layered on afterwards so headlines carry
    // Bloom's rounded, friendly voice while Nunito does the body work.
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
