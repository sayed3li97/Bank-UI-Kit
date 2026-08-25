import 'package:flutter/material.dart';

import '../../src/common/bank_pressable.dart';
import '../../src/common/bank_surface_depth.dart';
import '../../src/models/bank_insight.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/button_text_style.dart';
import '../../src/theme/tokens.dart';

/// A swipeable AI-generated insight card with a labelled confidence meter.
///
/// The meter is bars plus wording rather than the three dots it used to be:
/// dots at the foot of a card read as carousel pagination, and they left the
/// model's confidence encoded in nothing but position and hue.
class BankInsightCard extends StatelessWidget {
  final BankInsight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  /// Overrides the card content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Legacy depth opt-out. The card renders the kit shadow language
  /// ([BankTokens.shadowCardFor] of the theme background brightness) instead
  /// of Material elevation; pass `0` — or use a theme whose `elevationLow`
  /// is `0`, such as Voltage — to flatten the card to hairline-only depth.
  final double? elevation;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Overrides the confidence-driven tint (leading glyph, badge circle, and
  /// the confidence meter bars).
  final Color? accentColor;

  /// Overrides the confidence-driven leading glyph.
  final IconData? icon;

  /// Merged over the insight title style (labelLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the insight body style (bodySmall, onSurfaceVariant).
  final TextStyle? bodyStyle;

  /// Overrides the dismiss glyph. Defaults to [Icons.close].
  final IconData? dismissIcon;

  /// Semantics label for the dismiss button. Defaults to
  /// 'Dismiss insight'.
  final String dismissLabel;

  /// Whether to render the confidence meter. Defaults to `true`.
  ///
  /// Turn it off for hosts that surface model confidence elsewhere; the
  /// meter is never hidden from assistive technology while it is visible.
  final bool showConfidence;

  /// Supplies the confidence wording, shown *and* announced. Defaults to
  /// 'High confidence' / 'Medium confidence' / 'Low confidence'.
  ///
  /// The text is not decoration: three marks alone were indistinguishable
  /// from carousel pagination, and colour alone cannot carry the level, so
  /// the label is the state's primary encoding and the bars only reinforce
  /// it (WCAG 1.4.1).
  final String Function(InsightConfidence confidence)? confidenceLabelBuilder;

  /// Accessible name of the confidence meter, announced ahead of the level
  /// from [confidenceLabelBuilder]. Defaults to 'Insight confidence'.
  final String confidenceSemanticLabel;

  /// Merged over the confidence label style ([BankTokens.caption] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? confidenceLabelStyle;

  /// Overrides the card semantics label. Defaults to title and body.
  final String? semanticLabel;

  const BankInsightCard({
    required this.insight,
    super.key,
    this.onTap,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.elevation,
    this.shadow,
    this.border,
    this.accentColor,
    this.icon,
    this.titleStyle,
    this.bodyStyle,
    this.dismissIcon,
    this.dismissLabel = 'Dismiss insight',
    this.showConfidence = true,
    this.confidenceLabelBuilder,
    this.confidenceSemanticLabel = 'Insight confidence',
    this.confidenceLabelStyle,
    this.semanticLabel,
  });

  static IconData _iconFor(InsightConfidence confidence) =>
      switch (confidence) {
        InsightConfidence.high => Icons.insights_rounded,
        InsightConfidence.medium => Icons.lightbulb_outline_rounded,
        InsightConfidence.low => Icons.help_outline_rounded,
      };

  static Color _confidenceColor(
    InsightConfidence confidence,
    BankThemeData theme,
  ) =>
      switch (confidence) {
        InsightConfidence.high => theme.primary,
        // The theme's brightness-aware pending amber, not a raw swatch:
        // Colors.amber is illegible on light surfaces and unbranded on dark.
        InsightConfidence.medium => theme.pending,
        InsightConfidence.low => theme.onSurfaceVariant,
      };

  static String _defaultConfidenceLabel(InsightConfidence confidence) =>
      switch (confidence) {
        InsightConfidence.high => 'High confidence',
        InsightConfidence.medium => 'Medium confidence',
        InsightConfidence.low => 'Low confidence',
      };

  Widget _confidenceMeter(Color color) => _ConfidenceMeter(
        confidence: insight.confidence,
        color: color,
        label: (confidenceLabelBuilder ?? _defaultConfidenceLabel)(
          insight.confidence,
        ),
        semanticLabel: confidenceSemanticLabel,
        labelStyle: confidenceLabelStyle,
      );

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final color = accentColor ?? _confidenceColor(insight.confidence, theme);
    final resolvedRadius = radius ?? theme.cardRadius;
    // One depth language for every card: token shadows resolved against the
    // theme background brightness, with the dark-surface hairline. Themes
    // that declare flat depth (elevationLow == 0, e.g. Voltage) — or an
    // explicit `elevation: 0` — keep hairline-only separation.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
      tier: (elevation ?? theme.elevationLow) <= 0
          ? BankSurfaceDepthTier.flat
          : BankSurfaceDepthTier.card,
    );

    return BankPressable(
      onTap: onTap,
      borderRadius: resolvedRadius,
      semanticLabel: semanticLabel ?? '${insight.title}. ${insight.body}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.surface,
          borderRadius: resolvedRadius,
          boxShadow: depth.shadow,
          border: depth.border,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(BankTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: BankTokens.space10,
                    height: BankTokens.space10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: BankTokens.alphaMuted),
                    ),
                    child: Icon(
                      icon ?? _iconFor(insight.confidence),
                      size: BankTokens.iconMedium,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onSurface)
                              .merge(titleStyle),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insight.body,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(bodyStyle),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    BankPressable(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(
                        BankTokens.minTapTarget / 2,
                      ),
                      semanticLabel: dismissLabel,
                      child: SizedBox(
                        // The glyph keeps its 16 px optical weight; only the
                        // hit area grows to the 44 px minimum (WCAG 2.5.5).
                        width: BankTokens.minTapTarget,
                        height: BankTokens.minTapTarget,
                        child: Center(
                          child: Icon(
                            dismissIcon ?? Icons.close,
                            size: BankTokens.iconSmall,
                            color: theme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (onAction != null) ...[
                const SizedBox(height: BankTokens.space3),
                Row(
                  children: [
                    // One flex child, not two: a `Spacer` beside a `Flexible`
                    // meter splits the slack evenly, so the meter could never
                    // exceed half of it and its wording ellipsized on a 360 pt
                    // phone. `Expanded` hands the meter all the free space —
                    // it lays out at its natural width and the trailing button
                    // still sits flush with the content edge.
                    if (showConfidence)
                      Expanded(child: _confidenceMeter(color))
                    else
                      const Spacer(),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        // Height, not just padding: the semantics rect of a
                        // 32 px button is what fails the tap-target audit.
                        minimumSize: const Size(0, BankTokens.minTapTarget),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space3,
                        ),
                        foregroundColor: theme.primary,
                        textStyle: bankButtonTextStyle(context),
                      ),
                      child: Text(actionLabel ?? 'View details'),
                    ),
                  ],
                ),
              ] else if (showConfidence) ...[
                const SizedBox(height: BankTokens.space2),
                _confidenceMeter(color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The labelled confidence indicator: an ascending three-bar meter plus its
/// wording.
///
/// Bars, not dots, and never on their own — a row of equal dots at the foot
/// of a card is the universal carousel-pagination signature, and it also left
/// the level encoded in position and colour alone. The ascending bars read as
/// signal strength, and the adjacent text is the level's real encoding, so the
/// meter degrades to plain language for screen readers, monochrome displays,
/// and colour-vision deficiencies alike.
class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({
    required this.confidence,
    required this.color,
    required this.label,
    required this.semanticLabel,
    required this.labelStyle,
  });

  final InsightConfidence confidence;
  final Color color;
  final String label;
  final String semanticLabel;
  final TextStyle? labelStyle;

  /// Bar count lit for [confidence]; the ladder is 1-3 of 3.
  int get _filledCount => switch (confidence) {
        InsightConfidence.high => 3,
        InsightConfidence.medium => 2,
        InsightConfidence.low => 1,
      };

  /// Bar heights climb the spacing grid so the meter reads as a level even
  /// with every bar lit the same colour.
  static const List<double> _barHeights = [
    BankTokens.space1,
    BankTokens.space2,
    BankTokens.space3,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Semantics(
      container: true,
      label: semanticLabel,
      value: label,
      // The bars carry no information the value string does not; announcing
      // the visible text again would read the level twice.
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _barHeights.length; i++) ...[
                if (i > 0) const SizedBox(width: BankTokens.space1),
                Container(
                  width: BankTokens.space1,
                  height: _barHeights[i],
                  decoration: BoxDecoration(
                    color: i < _filledCount
                        ? color
                        : color.withValues(alpha: BankTokens.alphaMuted),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BankTokens.radiusSmall),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: BankTokens.space2),
          Flexible(
            child: Text(
              label,
              // Ink stays the muted on-surface role rather than the
              // confidence tint: amber-on-white is the classic AA failure,
              // and the wording already carries the level.
              style: BankTokens.caption
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(labelStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
