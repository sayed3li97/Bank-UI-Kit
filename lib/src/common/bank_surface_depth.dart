import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The depth tier of a card-like surface.
enum BankSurfaceDepthTier {
  /// No shadow — flat / inset surfaces separated by the hairline alone.
  flat,

  /// Resting card surface ([BankTokens.shadowCardFor]).
  card,

  /// Floating element — sheets, pickers, overlays
  /// ([BankTokens.shadowFloatingFor]).
  floating,

  /// Hero surface ([BankTokens.shadowHeroFor]).
  hero,
}

/// Internal (non-exported) resolver that maps the kit's depth language to
/// concrete pixels, so every card, tile, and sheet renders the same lighting
/// model.
///
/// The rules mirror the reference implementations in `BankAccountCard` and
/// `BankPaymentCard`:
///
/// - the shadow variant follows the brightness of the **theme background**
///   (light-ink shadows disappear on near-black backgrounds, so dark
///   backgrounds get the pure-black occlusion variants), and is re-inked with
///   [BankThemeData.shadowTint] when the brand defines one, so a preset's
///   shadow colour reaches the kit's own surfaces and not just Material
///   elevations;
/// - the hairline follows the brightness of the **painted surface** — dark
///   surfaces get a [BankTokens.hairlineWidth] hairline in
///   [BankTokens.hairlineColor], light surfaces keep an invisible border of
///   the same width so geometry is identical across brightness;
/// - caller overrides always win: pass `shadow: const []` to flatten, or
///   `border: const Border()` to remove the hairline.
class BankSurfaceDepth {
  const BankSurfaceDepth({required this.shadow, required this.border});

  /// The resolved box shadow. Empty for [BankSurfaceDepthTier.flat] (unless
  /// overridden).
  final List<BoxShadow> shadow;

  /// The resolved hairline border — visible on dark surfaces, an invisible
  /// same-width border on light ones.
  final BoxBorder border;

  /// Resolves the depth treatment for a surface painted [surfaceColor]
  /// (defaults to [BankThemeData.surface]) on the ambient [theme] background.
  static BankSurfaceDepth resolve(
    BankThemeData theme, {
    Color? surfaceColor,
    List<BoxShadow>? shadow,
    BoxBorder? border,
    BankSurfaceDepthTier tier = BankSurfaceDepthTier.card,
  }) {
    final resolvedSurface = surfaceColor ?? theme.surface;
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(resolvedSurface);
    final backgroundBrightness =
        ThemeData.estimateBrightnessForColor(theme.background);

    // Route through the theme rather than the tokens directly: shadowFor
    // applies the brand's shadowTint, which is what makes a preset's
    // documented shadow colour real on kit surfaces.
    final resolvedShadow = shadow ??
        theme.shadowFor(
          switch (tier) {
            BankSurfaceDepthTier.flat => BankElevationTier.flat,
            BankSurfaceDepthTier.card => BankElevationTier.card,
            BankSurfaceDepthTier.floating => BankElevationTier.floating,
            BankSurfaceDepthTier.hero => BankElevationTier.hero,
          },
          brightness: backgroundBrightness,
        );

    final resolvedBorder = border ??
        Border.all(
          color: surfaceBrightness == Brightness.dark
              ? BankTokens.hairlineColor(theme.onSurface, surfaceBrightness)
              : theme.onSurface.withValues(alpha: 0),
          // Matches Border.all's default today; keep the token as the source
          // of truth for hairline geometry.
          // ignore: avoid_redundant_argument_values
          width: BankTokens.hairlineWidth,
        );

    return BankSurfaceDepth(shadow: resolvedShadow, border: resolvedBorder);
  }
}
