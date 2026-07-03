import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/bank_summary_stack.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// Amount / tenor sliders with a live repayment preview — the entry
/// point that front-ends `BankRepaymentScheduleView` and
/// `BankInstallmentPlanSelector`.
///
/// The monthly payment is computed internally with the standard
/// amortization formula and re-renders through a 150 ms switcher on
/// every change. The rate line honours `islamicFinanceMode` (profit
/// rate instead of APR) unless [rateLabel] overrides it. Totals render
/// via `BankSummaryStack`.
///
/// ```dart
/// BankLoanCalculatorCard(
///   minAmount: Money.fromDouble(5000, 'SAR'),
///   maxAmount: Money.fromDouble(250000, 'SAR'),
///   minMonths: 6,
///   maxMonths: 60,
///   annualRate: 0.049,
///   onChanged: (amount, months) => quote(amount, months),
///   onContinue: _startApplication,
/// )
/// ```
class BankLoanCalculatorCard extends StatefulWidget {
  const BankLoanCalculatorCard({
    required this.minAmount,
    required this.maxAmount,
    required this.minMonths,
    required this.maxMonths,
    required this.annualRate,
    required this.onChanged,
    super.key,
    this.initialAmount,
    this.initialMonths,
    this.rateLabel,
    this.disclosureSlot,
    this.onContinue,
    this.continueLabel = 'Continue',
    this.amountLabel = 'Loan amount',
    this.tenorTemplate = '{n} months',
    this.monthlyLabel = 'Monthly payment',
    this.totalRepayableLabel = 'Total repayable',
    this.costOfCreditLabel = 'Cost of credit',
    this.aprLabel = 'APR',
    this.profitRateLabel = 'Profit rate',
  });

  final Money minAmount;
  final Money maxAmount;
  final int minMonths;
  final int maxMonths;

  /// Nominal annual rate as a fraction, e.g. `0.049` for 4.9 %.
  final double annualRate;

  /// Fired on every slider commit with the selected amount and tenor.
  final void Function(Money amount, int months) onChanged;

  final Money? initialAmount;
  final int? initialMonths;

  /// Overrides the APR / profit-rate label entirely.
  final String? rateLabel;

  /// Slot for regulatory representative-example text.
  final Widget? disclosureSlot;

  /// Renders a full-width continue button when set.
  final VoidCallback? onContinue;

  final String continueLabel;
  final String amountLabel;

  /// `{n}` is substituted with the tenor.
  final String tenorTemplate;

  final String monthlyLabel;
  final String totalRepayableLabel;
  final String costOfCreditLabel;
  final String aprLabel;
  final String profitRateLabel;

  @override
  State<BankLoanCalculatorCard> createState() => _BankLoanCalculatorCardState();
}

class _BankLoanCalculatorCardState extends State<BankLoanCalculatorCard> {
  late double _amount;
  late int _months;

  double get _min => widget.minAmount.amount.toDouble();
  double get _max => widget.maxAmount.amount.toDouble();

  String get _currency => widget.minAmount.currencyCode;

  @override
  void initState() {
    super.initState();
    _amount = (widget.initialAmount?.amount.toDouble() ?? (_min + _max) / 2)
        .clamp(_min, _max);
    _amount = _snap(_amount);
    final midMonths = (widget.minMonths + widget.maxMonths) ~/ 2;
    _months = (widget.initialMonths ?? midMonths)
        .clamp(widget.minMonths, widget.maxMonths);
  }

  double _snap(double raw) {
    final magnitude = math
        .pow(10, math.max(_max.round().toString().length - 3, 1))
        .toDouble();
    return (raw / magnitude).round() * magnitude;
  }

  /// Standard amortization: P * r / (1 - (1+r)^-n), degrading to P/n at
  /// a zero rate.
  double get _monthlyPayment {
    final r = widget.annualRate / 12;
    if (r <= 0) return _amount / _months;
    return _amount * r / (1 - math.pow(1 + r, -_months));
  }

  Money _money(double value) => Money.fromDouble(value, _currency);

  void _emit() => widget.onChanged(_money(_amount), _months);

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final monthly = _monthlyPayment;
    final totalRepayable = monthly * _months;
    final costOfCredit = totalRepayable - _amount;

    final rateName = widget.rateLabel ??
        (scope.islamicFinanceMode ? widget.profitRateLabel : widget.aprLabel);
    final ratePercent = scope.numeralStyle
        .convert('${(widget.annualRate * 100).toStringAsFixed(2)}%');

    final formattedMonthly = BankMoneyFormatter.format(
      amount: _money(monthly).amount,
      currencyCode: _currency,
      numeralStyle: scope.numeralStyle,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.amountLabel,
              style: BankTokens.labelMedium
                  .copyWith(color: theme.onSurfaceVariant),
            ),
            Text(
              BankMoneyFormatter.format(
                amount: _money(_amount).amount,
                currencyCode: _currency,
                numeralStyle: scope.numeralStyle,
              ),
              style: BankTokens.numeralLarge.copyWith(
                color: theme.onSurface,
                fontFamily: theme.fontFamily,
              ),
            ),
            Semantics(
              slider: true,
              label: widget.amountLabel,
              excludeSemantics: true,
              child: Slider(
                value: _amount,
                min: _min,
                max: _max,
                activeColor: theme.primary,
                inactiveColor: theme.surfaceVariant,
                onChanged: (raw) =>
                    setState(() => _amount = _snap(raw).clamp(_min, _max)),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            Text(
              widget.tenorTemplate.replaceAll(
                '{n}',
                scope.numeralStyle.convert('$_months'),
              ),
              style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
            ),
            Semantics(
              slider: true,
              label: widget.tenorTemplate.replaceAll('{n}', '$_months'),
              excludeSemantics: true,
              child: Slider(
                value: _months.toDouble(),
                min: widget.minMonths.toDouble(),
                max: widget.maxMonths.toDouble(),
                divisions: math.max(widget.maxMonths - widget.minMonths, 1),
                activeColor: theme.primary,
                inactiveColor: theme.surfaceVariant,
                onChanged: (raw) => setState(() => _months = raw.round()),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            Center(
              child: Column(
                children: [
                  Text(
                    widget.monthlyLabel,
                    style: BankTokens.labelMedium
                        .copyWith(color: theme.onSurfaceVariant),
                  ),
                  AnimatedSwitcher(
                    duration: BankTokens.durationFast,
                    child: Text(
                      formattedMonthly,
                      key: ValueKey<String>(formattedMonthly),
                      style: BankTokens.numeralHero.copyWith(
                        color: theme.primary,
                        fontFamily: theme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            BankSummaryStack(
              items: [
                BankSummaryItem(
                  label: widget.totalRepayableLabel,
                  money: _money(totalRepayable),
                ),
                BankSummaryItem(
                  label: widget.costOfCreditLabel,
                  money: _money(costOfCredit),
                ),
                BankSummaryItem(label: rateName, value: ratePercent),
              ],
            ),
            if (widget.disclosureSlot != null) ...[
              const SizedBox(height: BankTokens.space3),
              widget.disclosureSlot!,
            ],
            if (widget.onContinue != null) ...[
              const SizedBox(height: BankTokens.space4),
              SizedBox(
                width: double.infinity,
                height: BankTokens.space12,
                child: FilledButton(
                  onPressed: widget.onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    widget.continueLabel,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onPrimary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
