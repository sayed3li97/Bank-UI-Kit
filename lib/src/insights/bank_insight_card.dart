import 'package:flutter/material.dart';

import '../../src/common/bank_pressable.dart';
import '../../src/common/bank_surface_depth.dart';
import '../../src/models/bank_insight.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A swipeable AI-generated insight card with confidence indicator.
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

  /// Overrides the confidence-driven tint (icon, dots, badge circle).
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
        InsightConfidence.medium => Colors.amber,
        InsightConfidence.low => theme.onSurfaceVariant,
      };

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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      icon ?? _iconFor(insight.confidence),
                      size: 20,
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
                      borderRadius: BorderRadius.circular(20),
                      semanticLabel: dismissLabel,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          dismissIcon ?? Icons.close,
                          size: 16,
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              if (onAction != null) ...[
                const SizedBox(height: BankTokens.space3),
                Row(
                  children: [
                    _ConfidenceDots(
                      confidence: insight.confidence,
                      color: color,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space3,
                        ),
                        foregroundColor: theme.primary,
                      ),
                      child: Text(actionLabel ?? 'View details'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: BankTokens.space2),
                _ConfidenceDots(
                  confidence: insight.confidence,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceDots extends StatelessWidget {
  final InsightConfidence confidence;
  final Color color;

  const _ConfidenceDots({required this.confidence, required this.color});

  int get _filledCount => switch (confidence) {
        InsightConfidence.high => 3,
        InsightConfidence.medium => 2,
        InsightConfidence.low => 1,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < _filledCount;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : color.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
