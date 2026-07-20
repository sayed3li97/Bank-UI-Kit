import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/budget.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Shows a budget's progress with an animated bar and over-budget warning.
class BankBudgetGaugeWidget extends StatelessWidget {
  final BankBudget budget;
  final VoidCallback? onTap;

  /// Chip text shown when the budget is exceeded. Defaults to
  /// 'Over budget'.
  final String overBudgetLabel;

  /// Spend line template; `{spent}` and `{limit}` are substituted.
  /// Defaults to '{spent} of {limit}'.
  final String amountTemplate;

  /// Overrides the content padding. Defaults to space4 by space3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the tap ripple corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the computed bar tint. Defaults to a spend-fraction
  /// driven colour: [BankTokens.success] below 80%, [BankTokens.warning]
  /// above 80%, [BankTokens.danger] once over budget (dark variants on
  /// dark surfaces).
  final Color? accentColor;

  /// Overrides the bar track colour. Defaults to the theme outline at
  /// 20% opacity.
  final Color? trackColor;

  /// Merged over the budget name style (labelMedium, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the 'spent of limit' line style (bodySmall,
  /// onSurfaceVariant).
  final TextStyle? amountStyle;

  /// Merged over the percentage label style (labelSmall, bar tint).
  final TextStyle? percentStyle;

  /// Overrides the progress bar thickness. Defaults to 8.
  final double? barHeight;

  /// Overrides the fill animation duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the fill animation curve. Defaults to
  /// [BankTokens.curveEmphasized].
  final Curve? animationCurve;

  /// Overrides the computed semantics label. Defaults to a summary of
  /// name, spend, limit, and over-budget state.
  final String? semanticLabel;

  const BankBudgetGaugeWidget({
    required this.budget,
    super.key,
    this.onTap,
    this.overBudgetLabel = 'Over budget',
    this.amountTemplate = '{spent} of {limit}',
    this.padding,
    this.radius,
    this.accentColor,
    this.trackColor,
    this.titleStyle,
    this.amountStyle,
    this.percentStyle,
    this.barHeight,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    // Only the painted fill is clamped; the printed percentage stays
    // truthful (e.g. '105%' beside the over-budget chip, never a
    // contradictory '100%').
    final trueFraction = budget.spentFraction;
    final fraction = trueFraction.clamp(0.0, 1.0);
    final isOverBudget = budget.isOverBudget;

    final isDark =
        ThemeData.estimateBrightnessForColor(theme.surface) == Brightness.dark;
    final barColor = accentColor ??
        (isOverBudget
            ? (isDark ? BankTokens.dangerDark : BankTokens.danger)
            : fraction > 0.8
                ? (isDark ? BankTokens.warningDark : BankTokens.warning)
                : (isDark ? BankTokens.successDark : BankTokens.success));
    final overBudgetColor = isDark ? BankTokens.dangerDark : BankTokens.danger;

    final spentStr = BankMoneyFormatter.format(
      amount: budget.spent.amount,
      currencyCode: budget.spent.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final limitStr = BankMoneyFormatter.format(
      amount: budget.limit.amount,
      currencyCode: budget.limit.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );

    return Semantics(
      label: semanticLabel ??
          '${budget.name} budget: $spentStr of $limitStr'
              '${isOverBudget ? ', over budget' : ''}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius ?? theme.cardRadius,
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurface)
                          .merge(titleStyle),
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: overBudgetColor.withValues(alpha: 0.12),
                        borderRadius: theme.chipRadius,
                      ),
                      child: Text(
                        overBudgetLabel,
                        style: BankTokens.labelSmall
                            .copyWith(color: overBudgetColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BankTokens.space1),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      amountTemplate
                          .replaceAll('{spent}', spentStr)
                          .replaceAll('{limit}', limitStr),
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(amountStyle),
                    ),
                  ),
                  Text(
                    '${(trueFraction * 100).toStringAsFixed(0)}%',
                    style: BankTokens.labelSmall
                        .copyWith(color: barColor)
                        .merge(percentStyle),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: fraction),
                  duration: animationDuration ?? BankTokens.durationBase,
                  curve: animationCurve ?? BankTokens.curveEmphasized,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: barHeight ?? 8,
                    backgroundColor:
                        trackColor ?? theme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
