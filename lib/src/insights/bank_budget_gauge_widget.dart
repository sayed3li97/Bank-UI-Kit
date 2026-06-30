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

  const BankBudgetGaugeWidget({
    required this.budget,
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final fraction = budget.spentFraction.clamp(0.0, 1.0);
    final isOverBudget = budget.isOverBudget;

    final barColor = isOverBudget
        ? BankTokens.investmentLoss
        : fraction > 0.8
            ? Colors.amber
            : BankTokens.investmentGain;

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

    return Semantics(
      label: '${budget.name} budget: $spentStr of $limitStr'
          '${isOverBudget ? ', over budget' : ''}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurface),
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            BankTokens.investmentLoss.withValues(alpha: 0.12),
                        borderRadius: theme.chipRadius,
                      ),
                      child: Text(
                        'Over budget',
                        style: BankTokens.labelSmall
                            .copyWith(color: BankTokens.investmentLoss),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BankTokens.space1),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$spentStr of $limitStr',
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '${(fraction * 100).toStringAsFixed(0)}%',
                    style: BankTokens.labelSmall.copyWith(color: barColor),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: fraction),
                  duration: BankTokens.durationBase,
                  curve: BankTokens.curveEmphasized,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.outline.withValues(alpha: 0.2),
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
