import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/installment_plan.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Vertical list of monthly repayment rows generated from an [InstallmentPlan].
class BankRepaymentScheduleView extends StatelessWidget {
  final InstallmentPlan plan;
  final int? highlightMonthIndex;
  final bool islamicFinanceMode;

  /// Column header over the month numbers. Defaults to `'Month'`.
  final String monthHeaderLabel;

  /// Interest column header in conventional mode. Defaults to
  /// `'Interest'`.
  final String interestHeaderLabel;

  /// Interest column header in Islamic mode. Defaults to `'Profit'`.
  final String profitHeaderLabel;

  /// Payment column header. Defaults to `'Payment'`.
  final String paymentHeaderLabel;

  /// Row label template; `{n}` is the month number. Defaults to
  /// `'Month {n}'`.
  final String monthTemplate;

  /// Caption of the closing total row. Defaults to `'Total repayable'`.
  final String totalLabel;

  /// Accent for the highlighted row tint and text. Defaults to the
  /// theme primary.
  final Color? accentColor;

  /// Overrides the divider color. Defaults to the theme outline.
  final Color? dividerColor;

  /// Overrides the header row padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: space4, vertical: space2)`.
  final EdgeInsetsGeometry? headerPadding;

  /// Overrides the data and total row padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: space4, vertical: space3)`.
  final EdgeInsetsGeometry? rowPadding;

  /// Merged over the column header style (labelSmall, variant color).
  final TextStyle? headerStyle;

  /// Merged over the month cell style (bodyMedium).
  final TextStyle? monthStyle;

  /// Merged over the interest cell style (bodySmall, variant color).
  final TextStyle? interestStyle;

  /// Merged over the payment cell style (numeralSmall).
  final TextStyle? amountStyle;

  /// Merged over the total row styles ([totalLabel] and total amount).
  final TextStyle? totalStyle;

  const BankRepaymentScheduleView({
    required this.plan,
    super.key,
    this.highlightMonthIndex,
    this.islamicFinanceMode = false,
    this.monthHeaderLabel = 'Month',
    this.interestHeaderLabel = 'Interest',
    this.profitHeaderLabel = 'Profit',
    this.paymentHeaderLabel = 'Payment',
    this.monthTemplate = 'Month {n}',
    this.totalLabel = 'Total repayable',
    this.accentColor,
    this.dividerColor,
    this.headerPadding,
    this.rowPadding,
    this.headerStyle,
    this.monthStyle,
    this.interestStyle,
    this.amountStyle,
    this.totalStyle,
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

    final accent = accentColor ?? theme.primary;
    final resolvedDivider = dividerColor ?? theme.outline;
    final resolvedHeaderStyle = BankTokens.labelSmall
        .copyWith(color: theme.onSurfaceVariant)
        .merge(headerStyle);
    final resolvedRowPadding = rowPadding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: headerPadding ??
              const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  monthHeaderLabel,
                  style: resolvedHeaderStyle,
                ),
              ),
              Text(
                isIslamic ? profitHeaderLabel : interestHeaderLabel,
                style: resolvedHeaderStyle,
              ),
              const SizedBox(width: BankTokens.space4),
              Text(
                paymentHeaderLabel,
                style: resolvedHeaderStyle,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: resolvedDivider),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.termMonths,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: resolvedDivider.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final monthNumber = index + 1;
            final monthText = monthTemplate.replaceAll('{n}', '$monthNumber');
            final isHighlighted = highlightMonthIndex == index;

            final interestAmount = plan.monthlyAmount.amount * monthlyRate;
            final interestStr = BankMoneyFormatter.format(
              amount: interestAmount,
              currencyCode: plan.monthlyAmount.currencyCode,
              numeralStyle: scope.numeralStyle,
            );

            return Semantics(
              label: '$monthText: $monthlyStr',
              child: Container(
                color: isHighlighted
                    ? accent.withValues(alpha: 0.06)
                    : Colors.transparent,
                padding: resolvedRowPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        monthText,
                        style: BankTokens.bodyMedium
                            .copyWith(
                              color: isHighlighted ? accent : theme.onSurface,
                              fontWeight: isHighlighted
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )
                            .merge(monthStyle),
                      ),
                    ),
                    Text(
                      interestStr,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(interestStyle),
                    ),
                    const SizedBox(width: BankTokens.space4),
                    Text(
                      monthlyStr,
                      style: BankTokens.numeralSmall
                          .copyWith(
                            color: isHighlighted ? accent : theme.onSurface,
                          )
                          .merge(amountStyle),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Divider(height: 1, color: resolvedDivider),
        Padding(
          padding: resolvedRowPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  totalLabel,
                  style: BankTokens.labelMedium
                      .copyWith(color: theme.onSurface)
                      .merge(totalStyle),
                ),
              ),
              Text(
                BankMoneyFormatter.format(
                  amount: plan.totalAmount.amount,
                  currencyCode: plan.totalAmount.currencyCode,
                  numeralStyle: scope.numeralStyle,
                ),
                style: BankTokens.numeralSmall
                    .copyWith(color: theme.onSurface)
                    .merge(totalStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
