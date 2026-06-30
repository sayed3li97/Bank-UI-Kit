import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../common/money_formatter.dart';
import '../../models/installment_plan.dart';
import '../../scope/bank_ui_scope.dart';
import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

/// Vertical list of monthly repayment rows generated from an [InstallmentPlan].
class BankRepaymentScheduleView extends StatelessWidget {
  final InstallmentPlan plan;
  final int? highlightMonthIndex;
  final bool islamicFinanceMode;

  const BankRepaymentScheduleView({
    super.key,
    required this.plan,
    this.highlightMonthIndex,
    this.islamicFinanceMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final isIslamic = islamicFinanceMode || scope.islamicFinanceMode;

    final monthlyStr = BankMoneyFormatter.format(
      amount: plan.monthlyAmount.amount,
      currencyCode: plan.monthlyAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final monthlyRate = plan.isInterestFree || plan.annualRate == null
        ? Decimal.zero
        : Decimal.parse((plan.annualRate! / 100 / 12).toStringAsFixed(10));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Month',
                  style: BankTokens.labelSmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ),
              Text(
                isIslamic ? 'Profit' : 'Interest',
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
              const SizedBox(width: BankTokens.space4),
              Text(
                'Payment',
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.outline),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.termMonths,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: theme.outline.withOpacity(0.5)),
          itemBuilder: (context, index) {
            final monthNumber = index + 1;
            final isHighlighted = highlightMonthIndex == index;

            final interestAmount =
                plan.monthlyAmount.amount * monthlyRate;
            final interestStr = BankMoneyFormatter.format(
              amount: interestAmount,
              currencyCode: plan.monthlyAmount.currencyCode,
              numeralStyle: scope.numeralStyle,
            );

            return Semantics(
              label: 'Month $monthNumber: $monthlyStr',
              child: Container(
                color: isHighlighted
                    ? theme.primary.withOpacity(0.06)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Month $monthNumber',
                        style: BankTokens.bodyMedium.copyWith(
                          color: isHighlighted ? theme.primary : theme.onSurface,
                          fontWeight: isHighlighted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      interestStr,
                      style: BankTokens.bodySmall.copyWith(
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: BankTokens.space4),
                    Text(
                      monthlyStr,
                      style: BankTokens.numeralSmall.copyWith(
                        color: isHighlighted ? theme.primary : theme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Divider(height: 1, color: theme.outline),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total repayable',
                  style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
                ),
              ),
              Text(
                BankMoneyFormatter.format(
                  amount: plan.totalAmount.amount,
                  currencyCode: plan.totalAmount.currencyCode,
                  numeralStyle: scope.numeralStyle,
                ),
                style: BankTokens.numeralSmall.copyWith(color: theme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
