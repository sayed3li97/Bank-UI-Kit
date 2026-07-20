import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/bank_summary_stack.dart';
import '../common/bank_surface_depth.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// How the repayment preview is computed.
enum BankFinancingModel {
  /// Conventional declining-balance amortization:
  /// `P * r / (1 - (1+r)^-n)`.
  amortizing,

  /// Murabaha-style cost-plus sale: total profit is fixed up front at
  /// `cost * annualRate * years` and installments are equal shares of
  /// the sale price `(cost + profit) / n`. Profit never compounds and
  /// does not change with early or late payment.
  murabaha,
}

/// Amount / tenor sliders with a live repayment preview: the entry
/// point that front-ends `BankRepaymentScheduleView` and
/// `BankInstallmentPlanSelector`.
///
/// The payment math follows [financingModel]. When it is null the
/// model tracks `islamicFinanceMode`: conventional amortization
/// normally, Murabaha cost-plus (flat profit fixed at contract time)
/// when Islamic mode is on, so the label and the arithmetic always
/// agree. The rate line honours `islamicFinanceMode` (profit rate
/// instead of APR) unless [rateLabel] overrides it. Totals render via
/// `BankSummaryStack`.
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
    this.financingModel,
    this.profitAmountLabel = 'Total profit',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.shadow,
    this.accentColor,
    this.labelStyle,
    this.amountStyle,
    this.monthlyStyle,
    this.animationDuration,
    this.animationCurve,
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

  /// Payment arithmetic. Null tracks `islamicFinanceMode`: amortizing
  /// conventionally, [BankFinancingModel.murabaha] in Islamic mode.
  final BankFinancingModel? financingModel;

  /// Replaces [costOfCreditLabel] under [BankFinancingModel.murabaha].
  final String profitAmountLabel;

  /// Overrides the card content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card border color. By default the raised card carries
  /// **no visible border on light surfaces** (depth comes from the shadow);
  /// dark surfaces get a [BankTokens.hairlineWidth] hairline in
  /// [BankTokens.hairlineColor].
  final Color? borderColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Accent for the sliders, the monthly figure, and the continue
  /// button. Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the small caption styles ([amountLabel], tenor line,
  /// and [monthlyLabel]).
  final TextStyle? labelStyle;

  /// Merged over the selected-amount numeral style (numeralLarge).
  final TextStyle? amountStyle;

  /// Merged over the monthly payment hero style (numeralHero, accent).
  final TextStyle? monthlyStyle;

  /// Duration of the monthly figure cross-fade. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Curve of the monthly figure cross-fade. Defaults to linear.
  final Curve? animationCurve;

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

  /// Amortizing: P * r / (1 - (1+r)^-n), degrading to P/n at a zero
  /// rate. Murabaha: (P + P * annualRate * years) / n, flat.
  double _monthlyPayment(BankFinancingModel model) {
    if (model == BankFinancingModel.murabaha) {
      final profit = _amount * widget.annualRate * (_months / 12);
      return (_amount + profit) / _months;
    }
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

    final model = widget.financingModel ??
        (scope.islamicFinanceMode
            ? BankFinancingModel.murabaha
            : BankFinancingModel.amortizing);
    final monthly = _monthlyPayment(model);
    final totalRepayable = monthly * _months;
    final costOfCredit = totalRepayable - _amount;
    final costName = model == BankFinancingModel.murabaha
        ? widget.profitAmountLabel
        : widget.costOfCreditLabel;

    final rateName = widget.rateLabel ??
        (scope.islamicFinanceMode ? widget.profitRateLabel : widget.aprLabel);
    final ratePercent = scope.numeralStyle
        .convert('${(widget.annualRate * 100).toStringAsFixed(2)}%');

    final formattedMonthly = BankMoneyFormatter.format(
      amount: _money(monthly).amount,
      currencyCode: _currency,
      numeralStyle: scope.numeralStyle,
    );

    final accent = widget.accentColor ?? theme.primary;

    // Raised card: shadow-only depth — no doubled outline+shadow. The
    // resolver adds the dark-surface hairline (invisible on light) unless
    // the caller supplies an explicit borderColor.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: widget.backgroundColor,
      shadow: widget.shadow,
      border: widget.borderColor == null
          ? null
          : Border.all(color: widget.borderColor!),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.surface,
        borderRadius: widget.radius ?? theme.cardRadius,
        border: depth.border,
        boxShadow: depth.shadow,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.amountLabel,
              style: BankTokens.labelMedium
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(widget.labelStyle),
            ),
            Text(
              BankMoneyFormatter.format(
                amount: _money(_amount).amount,
                currencyCode: _currency,
                numeralStyle: scope.numeralStyle,
              ),
              style: BankTokens.numeralLarge
                  .copyWith(
                    color: theme.onSurface,
                    fontFamily: theme.fontFamily,
                  )
                  .merge(widget.amountStyle),
            ),
            Semantics(
              slider: true,
              label: widget.amountLabel,
              excludeSemantics: true,
              child: Slider(
                value: _amount,
                min: _min,
                max: _max,
                activeColor: accent,
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
              style: BankTokens.labelMedium
                  .copyWith(color: theme.onSurface)
                  .merge(widget.labelStyle),
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
                activeColor: accent,
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
                        .copyWith(color: theme.onSurfaceVariant)
                        .merge(widget.labelStyle),
                  ),
                  AnimatedSwitcher(
                    duration:
                        widget.animationDuration ?? BankTokens.durationFast,
                    switchInCurve: widget.animationCurve ?? Curves.linear,
                    switchOutCurve: widget.animationCurve ?? Curves.linear,
                    child: Text(
                      formattedMonthly,
                      key: ValueKey<String>(formattedMonthly),
                      style: BankTokens.numeralHero
                          .copyWith(
                            color: accent,
                            fontFamily: theme.fontFamily,
                          )
                          .merge(widget.monthlyStyle),
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
                  label: costName,
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
                    backgroundColor: accent,
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
