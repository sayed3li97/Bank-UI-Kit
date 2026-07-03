import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../common/bank_summary_stack.dart';
import '../common/money_formatter.dart';
import '../models/bank_currency.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// Interactive savings projection calculator: pick a deposit amount and
/// a duration, see what you earn.
///
/// Two sliders drive a live results panel (a [BankSummaryStack] block):
/// the deposit, the projected earnings, and the total at maturity.
/// Earnings use a simple annual rate pro-rated monthly,
/// `amount * rate / 100 * months / 12`, rounded to the currency's minor
/// units as registered in [BankCurrencies]. All money strings render via
/// [BankMoneyFormatter] and honour the ambient numeral style.
///
/// Privacy mode intentionally does NOT mask any figure on this card:
/// every amount is a user-entered hypothetical, not account data, so the
/// results rows render as plain text rather than privacy-aware balance
/// text.
///
/// When `islamicFinanceMode` is enabled on the ambient [BankUiScope],
/// the rate row swaps [rateLabel] for [profitRateLabel] and the earnings
/// row swaps [earningsLabel] for [profitEarningsLabel].
///
/// Provide [onApply] to render a full-width call-to-action button that
/// reports the selected deposit (as a [Money]) and duration in months.
///
/// ```dart
/// BankSavingsProjectionCard(
///   currencyCode: 'BHD',
///   annualRate: 3.5,
///   initialAmount: 1000,
///   initialMonths: 12,
///   onApply: (deposit, months) => openSavingsAccount(deposit, months),
/// )
/// ```
class BankSavingsProjectionCard extends StatefulWidget {
  /// Creates a savings projection calculator card.
  const BankSavingsProjectionCard({
    required this.currencyCode,
    required this.annualRate,
    super.key,
    this.initialAmount = 1000,
    this.minAmount = 100,
    this.maxAmount = 50000,
    this.amountStep = 100,
    this.minMonths = 1,
    this.maxMonths = 36,
    this.initialMonths = 12,
    this.onApply,
    this.title = 'Savings projection',
    this.amountLabel = 'Deposit amount',
    this.monthsTemplate = '{n} months',
    this.depositLabel = 'Deposit',
    this.rateLabel = 'Interest rate (AER)',
    this.profitRateLabel = 'Expected profit rate',
    this.earningsLabel = 'Interest earned',
    this.profitEarningsLabel = 'Expected profit',
    this.totalLabel = 'Total at maturity',
    this.applyLabel = 'Start saving',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.shadow,
    this.titleStyle,
    this.amountStyle,
  })  : assert(annualRate >= 0, 'annualRate must not be negative.'),
        assert(minAmount > 0, 'minAmount must be positive.'),
        assert(minAmount < maxAmount, 'minAmount must be below maxAmount.'),
        assert(amountStep > 0, 'amountStep must be positive.'),
        assert(minMonths >= 1, 'minMonths must be at least 1.'),
        assert(
          minMonths <= maxMonths,
          'minMonths must not exceed maxMonths.',
        );

  /// ISO 4217 currency code used for formatting and for [onApply].
  final String currencyCode;

  /// Simple annual rate in percent, e.g. `3.5` for 3.5 %.
  final double annualRate;

  /// Starting deposit selection, clamped into [minAmount]..[maxAmount].
  final double initialAmount;

  /// Lower bound of the deposit slider.
  final double minAmount;

  /// Upper bound of the deposit slider.
  final double maxAmount;

  /// Increment the deposit slider snaps to (drives its divisions).
  final double amountStep;

  /// Lower bound of the duration slider, in months.
  final int minMonths;

  /// Upper bound of the duration slider, in months.
  final int maxMonths;

  /// Starting duration selection, clamped into [minMonths]..[maxMonths].
  final int initialMonths;

  /// Renders a call-to-action button when non-null; called with the
  /// selected deposit and duration in months.
  final void Function(Money deposit, int months)? onApply;

  /// Heading shown at the top of the card.
  final String title;

  /// Label above the deposit slider, also used in its semantics.
  final String amountLabel;

  /// Duration display template; `{n}` is substituted with the months.
  final String monthsTemplate;

  /// Results row label for the deposit.
  final String depositLabel;

  /// Results row label for the rate in conventional mode.
  final String rateLabel;

  /// Replaces [rateLabel] when Islamic finance mode is active.
  final String profitRateLabel;

  /// Results row label for the earnings in conventional mode.
  final String earningsLabel;

  /// Replaces [earningsLabel] when Islamic finance mode is active.
  final String profitEarningsLabel;

  /// Results row label for the total at maturity.
  final String totalLabel;

  /// Caption of the [onApply] button.
  final String applyLabel;

  /// Overrides the card's content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card's corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card's fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the slider and button accent. Defaults to the theme
  /// primary colour.
  final Color? accentColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Merged over the computed [title] style, so partial overrides work.
  final TextStyle? titleStyle;

  /// Merged over the computed deposit-readout numeral style.
  final TextStyle? amountStyle;

  @override
  State<BankSavingsProjectionCard> createState() =>
      _BankSavingsProjectionCardState();
}

class _BankSavingsProjectionCardState extends State<BankSavingsProjectionCard> {
  late double _amount;
  late int _months;

  @override
  void initState() {
    super.initState();
    _amount =
        _snap(widget.initialAmount.clamp(widget.minAmount, widget.maxAmount));
    _months = widget.initialMonths.clamp(widget.minMonths, widget.maxMonths);
  }

  /// Quantizes [raw] to the nearest [BankSavingsProjectionCard.amountStep]
  /// above the range minimum, staying inside the slider bounds.
  double _snap(double raw) {
    final steps = ((raw - widget.minAmount) / widget.amountStep).round();
    return (widget.minAmount + steps * widget.amountStep)
        .clamp(widget.minAmount, widget.maxAmount);
  }

  int get _amountDivisions => math.max(
        ((widget.maxAmount - widget.minAmount) / widget.amountStep).round(),
        1,
      );

  /// Rounds [value] to the currency's ISO 4217 minor units.
  Decimal _round(double value) {
    final digits = BankCurrencies.of(widget.currencyCode).decimalDigits;
    return Decimal.parse(value.toStringAsFixed(digits));
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final accent = widget.accentColor ?? theme.primary;
    final resolvedPadding =
        widget.padding ?? const EdgeInsets.all(BankTokens.space4);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedBackground = widget.backgroundColor ?? theme.surface;
    final resolvedShadow = widget.shadow ?? BankTokens.shadowCard;

    final deposit = _round(_amount);
    final earnings = _round(_amount * widget.annualRate / 100 * _months / 12);
    final total = deposit + earnings;

    String formatMoney(Decimal amount) => BankMoneyFormatter.format(
          amount: amount,
          currencyCode: widget.currencyCode,
          numeralStyle: scope.numeralStyle,
        );

    final formattedDeposit = formatMoney(deposit);
    final formattedEarnings = formatMoney(earnings);
    final formattedTotal = formatMoney(total);

    final rateName =
        scope.islamicFinanceMode ? widget.profitRateLabel : widget.rateLabel;
    final earningsName = scope.islamicFinanceMode
        ? widget.profitEarningsLabel
        : widget.earningsLabel;
    final ratePercent =
        scope.numeralStyle.convert('${widget.annualRate.toStringAsFixed(2)}%');

    final monthsText = widget.monthsTemplate
        .replaceAll('{n}', scope.numeralStyle.convert('$_months'));

    final resolvedTitleStyle = BankTokens.headlineSmall
        .copyWith(color: theme.onSurface, fontFamily: theme.fontFamily)
        .merge(widget.titleStyle);
    final resolvedAmountStyle = BankTokens.numeralLarge
        .copyWith(color: theme.onSurface, fontFamily: theme.fontFamily)
        .merge(widget.amountStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: resolvedRadius,
        border: Border.all(color: theme.outline),
        boxShadow: resolvedShadow,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: resolvedTitleStyle),
            const SizedBox(height: BankTokens.space3),
            Text(
              widget.amountLabel,
              style: BankTokens.labelMedium
                  .copyWith(color: theme.onSurfaceVariant),
            ),
            Text(formattedDeposit, style: resolvedAmountStyle),
            Semantics(
              slider: true,
              label: '${widget.amountLabel}: $formattedDeposit',
              excludeSemantics: true,
              child: Slider(
                value: _amount,
                min: widget.minAmount,
                max: widget.maxAmount,
                divisions: _amountDivisions,
                activeColor: accent,
                inactiveColor: theme.surfaceVariant,
                onChanged: (raw) => setState(() => _amount = _snap(raw)),
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            Text(
              monthsText,
              style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
            ),
            Semantics(
              slider: true,
              label: widget.monthsTemplate.replaceAll('{n}', '$_months'),
              excludeSemantics: true,
              child: Slider(
                value: _months.toDouble(),
                min: widget.minMonths.toDouble(),
                max: widget.maxMonths.toDouble(),
                divisions: math.max(widget.maxMonths - widget.minMonths, 1),
                activeColor: accent,
                inactiveColor: theme.surfaceVariant,
                onChanged: (raw) => setState(() => _months = raw.round()),
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            // Hypothetical figures: plain-text rows on purpose, so the
            // privacy scope never masks them.
            MergeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: resolvedRadius,
                ),
                child: BankSummaryStack(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: BankTokens.space4,
                    vertical: BankTokens.space2,
                  ),
                  items: [
                    BankSummaryItem(
                      label: widget.depositLabel,
                      value: formattedDeposit,
                    ),
                    BankSummaryItem(label: rateName, value: ratePercent),
                    BankSummaryItem(
                      label: earningsName,
                      value: formattedEarnings,
                    ),
                    BankSummaryItem(
                      label: widget.totalLabel,
                      value: formattedTotal,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onApply != null) ...[
              const SizedBox(height: BankTokens.space4),
              SizedBox(
                width: double.infinity,
                height: BankTokens.space12,
                child: FilledButton(
                  onPressed: () => widget.onApply!(
                    Money(
                      amount: deposit,
                      currencyCode: widget.currencyCode,
                    ),
                    _months,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: theme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    widget.applyLabel,
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
