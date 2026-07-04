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

  /// Term line template; `{n}` is the term in months. Defaults to
  /// `'{n} months'`.
  final String termTemplate;

  /// Rate line for interest-free plans. Defaults to `'Interest free'`.
  final String interestFreeLabel;

  /// Rate line template in Islamic mode; `{rate}` is the rate.
  /// Defaults to `'Profit rate {rate}%'`.
  final String profitRateTemplate;

  /// Conventional rate line template; `{rate}` is the rate. Defaults
  /// to `'APR {rate}%'`.
  final String aprTemplate;

  /// Monthly amount template; `{amount}` is the formatted amount.
  /// Defaults to `'{amount}/mo'`.
  final String monthlyTemplate;

  /// Total line template; `{amount}` is the formatted total. Defaults
  /// to `'Total {amount}'`.
  final String totalTemplate;

  /// Row semantics template; `{n}` is the term, `{amount}` the monthly
  /// amount. Defaults to `'{n} months, {amount} per month'`.
  final String semanticsTemplate;

  /// Accent for the selected border, tint, price, and radio fill.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Fill of unselected rows. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the row corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the row content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space3)`.
  final EdgeInsetsGeometry? itemPadding;

  /// Vertical gap between rows. Defaults to [BankTokens.space2].
  final double? itemSpacing;

  /// Duration of the row selection animation. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Curve of the row selection animation. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Glyph inside the selected radio dot. Defaults to `Icons.check`.
  final IconData? checkIcon;

  /// Color of the selected radio glyph. Defaults to white.
  final Color? checkColor;

  /// Merged over the term line style (labelLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the rate line style (bodySmall, gain or variant
  /// color).
  final TextStyle? subtitleStyle;

  /// Merged over the monthly amount style (numeralSmall).
  final TextStyle? amountStyle;

  /// Merged over the total line style (bodySmall, variant color).
  final TextStyle? totalStyle;

  /// Replaces the entire default row (including tap handling) for each
  /// plan. Defaults to the built-in row.
  final Widget Function(BuildContext context, InstallmentPlan plan)?
      itemBuilder;

  const BankInstallmentPlanSelector({
    required this.plans,
    super.key,
    this.selectedPlan,
    this.onPlanSelected,
    this.islamicFinanceMode = false,
    this.termTemplate = '{n} months',
    this.interestFreeLabel = 'Interest free',
    this.profitRateTemplate = 'Profit rate {rate}%',
    this.aprTemplate = 'APR {rate}%',
    this.monthlyTemplate = '{amount}/mo',
    this.totalTemplate = 'Total {amount}',
    this.semanticsTemplate = '{n} months, {amount} per month',
    this.accentColor,
    this.backgroundColor,
    this.radius,
    this.itemPadding,
    this.itemSpacing,
    this.animationDuration,
    this.animationCurve,
    this.checkIcon,
    this.checkColor,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.totalStyle,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final isIslamic = islamicFinanceMode || scope.islamicFinanceMode;
    final accent = accentColor ?? theme.primary;
    final resolvedRadius = radius ?? theme.cardRadius;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: itemSpacing ?? BankTokens.space2),
      itemBuilder: (context, index) {
        final plan = plans[index];
        if (itemBuilder != null) return itemBuilder!(context, plan);
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
          label: semanticsTemplate
              .replaceAll('{n}', '${plan.termMonths}')
              .replaceAll('{amount}', monthlyStr),
          child: InkWell(
            onTap: () => onPlanSelected?.call(plan),
            borderRadius: resolvedRadius,
            child: AnimatedContainer(
              duration: animationDuration ?? BankTokens.durationBase,
              curve: animationCurve ?? BankTokens.curveStandard,
              decoration: BoxDecoration(
                borderRadius: resolvedRadius,
                border: Border.all(
                  color: isSelected ? accent : theme.outline,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? accent.withValues(alpha: 0.06)
                    : backgroundColor ?? theme.surface,
              ),
              padding: itemPadding ?? const EdgeInsets.all(BankTokens.space3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          termTemplate.replaceAll('{n}', '${plan.termMonths}'),
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onSurface)
                              .merge(titleStyle),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          plan.isInterestFree
                              ? interestFreeLabel
                              : (isIslamic ? profitRateTemplate : aprTemplate)
                                  .replaceAll('{rate}', rateStr),
                          style: BankTokens.bodySmall
                              .copyWith(
                                color: plan.isInterestFree
                                    ? BankTokens.investmentGain
                                    : theme.onSurfaceVariant,
                              )
                              .merge(subtitleStyle),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        monthlyTemplate.replaceAll('{amount}', monthlyStr),
                        style: BankTokens.numeralSmall
                            .copyWith(
                              color: isSelected ? accent : theme.onSurface,
                            )
                            .merge(amountStyle),
                      ),
                      Text(
                        totalTemplate.replaceAll('{amount}', totalStr),
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(totalStyle),
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
                        color: isSelected ? accent : theme.outline,
                        width: 2,
                      ),
                      color: isSelected ? accent : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            checkIcon ?? Icons.check,
                            size: 12,
                            color: checkColor ?? Colors.white,
                          )
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
