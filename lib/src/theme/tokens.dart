import 'package:flutter/widgets.dart';

/// Design tokens for the Bank UI Kit design system.
///
/// All values are `static const` and organised into semantic groups:
/// colour roles, spacing, border-radius, motion, typography, and tap targets.
class BankTokens {
  const BankTokens._();

  // ---------------------------------------------------------------------------
  // Colour roles
  // ---------------------------------------------------------------------------

  /// Green used for positive account balances.
  static const Color positiveBalance = Color(0xFF00C48C);

  /// Red used for negative account balances or overdue amounts.
  static const Color negativeBalance = Color(0xFFFF4D4D);

  /// Amber used for pending transactions or awaiting-confirmation states.
  static const Color pending = Color(0xFFF5A623);

  /// Grey used for frozen / suspended accounts or cards.
  static const Color frozen = Color(0xFF8E8E93);

  /// System-level success feedback colour.
  static const Color success = Color(0xFF34C759);

  /// System-level warning feedback colour.
  static const Color warning = Color(0xFFFF9500);

  /// System-level danger / destructive-action colour.
  static const Color danger = Color(0xFFFF3B30);

  /// Green used to represent an investment gain.
  static const Color investmentGain = Color(0xFF30D158);

  /// Red used to represent an investment loss.
  static const Color investmentLoss = Color(0xFFFF453A);

  /// Green used to show available credit headroom.
  static const Color creditAvailable = Color(0xFF30D158);

  /// Amber used to show the portion of credit already utilised.
  static const Color creditUsed = Color(0xFFFF9F0A);

  // ---------------------------------------------------------------------------
  // Spacing — 4 pt grid
  // ---------------------------------------------------------------------------

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ---------------------------------------------------------------------------
  // Border-radius tiers
  // ---------------------------------------------------------------------------

  static const double radiusSmall = 4;
  static const double radiusMedium = 12;
  static const double radiusLarge = 20;
  static const double radiusXLarge = 28;

  /// Use for fully-pill / circular shapes (e.g. chips, FABs).
  static const double radiusFull = 999;

  // ---------------------------------------------------------------------------
  // Motion — duration
  // ---------------------------------------------------------------------------

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationBase = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationXSlow = Duration(milliseconds: 600);

  // ---------------------------------------------------------------------------
  // Motion — easing curves
  // ---------------------------------------------------------------------------

  /// General-purpose easing for UI transitions.
  static const Curve curveStandard = Curves.easeInOut;

  /// High-energy easing for primary actions and hero elements.
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Easing for elements entering the screen from off-canvas.
  static const Curve curveDecelerate = Curves.decelerate;

  // ---------------------------------------------------------------------------
  // Typography scale — system fonts
  //
  // Font files are registered in pubspec.yaml but may be stubs in CI.
  // All styles intentionally omit `fontFamily` so the system font is used,
  // making every constant truly `const` and safe to reference from tests.
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  /// Hero monetary numeral — large balance displays.
  static const TextStyle numeralHero = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: 1.1,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Large monetary numeral — card balances and summary rows.
  static const TextStyle numeralLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Medium monetary numeral — list items and sub-totals.
  static const TextStyle numeralMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  /// Small monetary numeral — dense tables and secondary figures.
  static const TextStyle numeralSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  // ---------------------------------------------------------------------------
  // Elevation shadows
  //
  // Premium surfaces take depth from soft, layered, low-alpha shadows —
  // never from visible hairline borders. All shadows are tinted with a
  // blue-grey ink (0x101828) so they read as ambient light, not dirt.
  // ---------------------------------------------------------------------------

  /// Resting card shadow: barely-there ambient + soft key light.
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Hovering / floating elements: sheets, pickers, popovers.
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Hero surfaces (virtual cards, feature banners).
  static const List<BoxShadow> shadowHero = [
    BoxShadow(
      color: Color(0x29101828),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Accessibility
  // ---------------------------------------------------------------------------

  /// Minimum touch/tap target size in logical pixels (WCAG 2.5.5).
  static const double minTapTarget = 44;
}
