import 'package:flutter/material.dart';

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

  const BankInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  static IconData _iconFor(InsightConfidence confidence) => switch (confidence) {
        InsightConfidence.high => Icons.insights_rounded,
        InsightConfidence.medium => Icons.lightbulb_outline_rounded,
        InsightConfidence.low => Icons.help_outline_rounded,
      };

  static Color _confidenceColor(InsightConfidence confidence, BankThemeData theme) =>
      switch (confidence) {
        InsightConfidence.high => theme.primary,
        InsightConfidence.medium => Colors.amber,
        InsightConfidence.low => theme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final color = _confidenceColor(insight.confidence, theme);

    return Semantics(
      label: '${insight.title}. ${insight.body}',
      button: onTap != null,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
        color: theme.surface,
        elevation: theme.elevationLow,
        child: InkWell(
          onTap: onTap,
          borderRadius: theme.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
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
                        color: color.withOpacity(0.12),
                      ),
                      child: Icon(
                        _iconFor(insight.confidence),
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
                                .copyWith(color: theme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight.body,
                            style: BankTokens.bodySmall
                                .copyWith(color: theme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (onDismiss != null)
                      Semantics(
                        button: true,
                        label: 'Dismiss insight',
                        child: InkWell(
                          onTap: onDismiss,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
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
            color: filled ? color : color.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}
