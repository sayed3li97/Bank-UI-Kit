import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/installment_plan.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Lets the user choose an installment plan from a list.
class BankInstallmentPlanSelector extends StatelessWidget {
  final List<InstallmentPlan> plans;
  final InstallmentPlan? selectedPlan;
  final ValueChanged<InstallmentPlan>? onPlanSelected;
  final bool islamicFinanceMode;

  const BankInstallmentPlanSelector({
    required this.plans,
    super.key,
    this.selectedPlan,
    this.onPlanSelected,
    this.islamicFinanceMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final isIslamic = islamicFinanceMode || scope.islamicFinanceMode;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: BankTokens.space2),
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isSelected = plan == selectedPlan;

        final monthlyStr = BankMoneyFormatter.format(
          amount: plan.monthlyAmount.amount,
          currencyCode: plan.monthlyAmount.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        final totalStr = BankMoneyFormatter.format(
          amount: plan.totalAmount.amount,
          currencyCode: plan.totalAmount.currencyCode,
          numeralStyle: scope.numeralStyle,
        );

        final rateStr = plan.annualRate?.toStringAsFixed(2) ?? '0.00';

        return Semantics(
          selected: isSelected,
          button: true,
          label: '${plan.termMonths} months, $monthlyStr per month',
          child: InkWell(
            onTap: () => onPlanSelected?.call(plan),
            borderRadius: theme.cardRadius,
            child: AnimatedContainer(
              duration: BankTokens.durationBase,
              curve: BankTokens.curveStandard,
              decoration: BoxDecoration(
                borderRadius: theme.cardRadius,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.outline,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? theme.primary.withValues(alpha: 0.06)
                    : theme.surface,
              ),
              padding: const EdgeInsets.all(BankTokens.space3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.termMonths} months',
                          style: BankTokens.labelLarge.copyWith(
                            color: theme.onSurface,
                          ),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          plan.isInterestFree
                              ? 'Interest free'
                              : isIslamic
                                  ? 'Profit rate $rateStr%'
                                  : 'APR $rateStr%',
                          style: BankTokens.bodySmall.copyWith(
                            color: plan.isInterestFree
                                ? BankTokens.investmentGain
                                : theme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$monthlyStr/mo',
                        style: BankTokens.numeralSmall.copyWith(
                          color: isSelected ? theme.primary : theme.onSurface,
                        ),
                      ),
                      Text(
                        'Total $totalStr',
                        style: BankTokens.bodySmall.copyWith(
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: BankTokens.space2),
                  AnimatedContainer(
                    duration: BankTokens.durationFast,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.primary : theme.outline,
                        width: 2,
                      ),
                      color: isSelected ? theme.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
