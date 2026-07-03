import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_amount_input_field.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_summary_stack.dart';
import '../models/bank_currency.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A complete zakat calculation flow for Islamic banking apps.
///
/// The calculator collects the customer's zakatable wealth through
/// [BankAmountInputField] rows, grouped into assets (cash and balances,
/// gold and silver value, investments, business assets, money owed to
/// you) and deductions (debts to deduct). A live computation card built
/// on [BankSummaryStack] shows total zakatable wealth against the nisab
/// threshold and renders the verdict:
///
/// - below nisab: an informational state ([belowNisabMessage]) replaces
///   the pay button, since no zakat is owed;
/// - at or above nisab: the zakat due (wealth multiplied by [zakatRate],
///   rounded to the currency's minor units) is shown as a large
///   privacy-aware [BankBalanceText] with a full-width pay call to
///   action that emits the amount through [onPay].
///
/// The host computes [nisabThreshold] from the live gold or silver
/// price and may prefill the cash row from the customer's aggregated
/// account balances via [prefilledCash]. All amounts respect the
/// ambient numeral style (Eastern Arabic-Indic digits convert
/// automatically) and privacy mode from the surrounding scope.
///
/// Use [footnote] to attach a short fiqh disclaimer, for example a note
/// that the calculation follows a specific madhhab and that customers
/// should consult a scholar for complex estates.
///
/// ```dart
/// BankZakatCalculator(
///   currencyCode: 'SAR',
///   nisabThreshold: Money.fromDouble(21500, 'SAR'),
///   prefilledCash: Money.fromDouble(52300, 'SAR'),
///   onPay: (zakatDue) => startZakatPayment(zakatDue),
///   footnote: const Text(
///     'Calculated at 2.5% per the lunar year. Consult your scholar '
///     'for jewellery in personal use and complex holdings.',
///   ),
/// )
/// ```
class BankZakatCalculator extends StatefulWidget {
  const BankZakatCalculator({
    required this.currencyCode,
    required this.nisabThreshold,
    required this.onPay,
    super.key,
    this.prefilledCash,
    this.zakatRate = 0.025,
    this.payLabel = 'Pay Zakat',
    this.assetsSectionLabel = 'Zakatable assets',
    this.deductionsSectionLabel = 'Deductions',
    this.cashLabel = 'Cash and balances',
    this.goldSilverLabel = 'Gold and silver value',
    this.investmentsLabel = 'Investments',
    this.businessAssetsLabel = 'Business assets',
    this.receivablesLabel = 'Money owed to you',
    this.debtsLabel = 'Debts to deduct',
    this.totalWealthLabel = 'Total zakatable wealth',
    this.nisabLabel = 'Nisab threshold',
    this.zakatDueLabel = 'Zakat due',
    this.belowNisabMessage = 'No zakat due this year',
    this.footnote,
  }) : assert(
          zakatRate > 0 && zakatRate < 1,
          'zakatRate must be a fraction between 0 and 1 (exclusive).',
        );

  /// ISO 4217 currency code every row is denominated in, e.g. `'SAR'`.
  final String currencyCode;

  /// Wealth level at which zakat becomes obligatory. The host computes
  /// this from the live gold (or silver) price. Must be denominated in
  /// [currencyCode].
  final Money nisabThreshold;

  /// Called when the customer taps the pay call to action, with the
  /// zakat due already computed and rounded to the currency's minor
  /// units.
  final void Function(Money zakatDue) onPay;

  /// Optional starting value for the cash row, typically the sum of the
  /// customer's account balances. Must be denominated in
  /// [currencyCode].
  final Money? prefilledCash;

  /// Fraction of zakatable wealth owed. Defaults to 2.5% (0.025), the
  /// standard rate for a full lunar year.
  final double zakatRate;

  /// Label on the pay call to action.
  final String payLabel;

  /// Heading above the asset input rows.
  final String assetsSectionLabel;

  /// Heading above the deduction input rows.
  final String deductionsSectionLabel;

  /// Label for the cash and balances row.
  final String cashLabel;

  /// Label for the gold and silver value row.
  final String goldSilverLabel;

  /// Label for the investments row.
  final String investmentsLabel;

  /// Label for the business assets row.
  final String businessAssetsLabel;

  /// Label for the money owed to you row.
  final String receivablesLabel;

  /// Label for the debts to deduct row.
  final String debtsLabel;

  /// Label of the total zakatable wealth summary row.
  final String totalWealthLabel;

  /// Label of the nisab threshold summary row.
  final String nisabLabel;

  /// Label above the zakat due figure.
  final String zakatDueLabel;

  /// Message shown in place of the pay button when total zakatable
  /// wealth is below [nisabThreshold].
  final String belowNisabMessage;

  /// Optional short fiqh disclaimer rendered below the computation
  /// card, styled [BankTokens.bodySmall] in the variant text colour by
  /// default.
  final Widget? footnote;

  @override
  State<BankZakatCalculator> createState() => _BankZakatCalculatorState();
}

class _BankZakatCalculatorState extends State<BankZakatCalculator> {
  Decimal? _cash;
  Decimal? _goldSilver;
  Decimal? _investments;
  Decimal? _businessAssets;
  Decimal? _receivables;
  Decimal? _debts;

  @override
  void initState() {
    super.initState();
    assert(
      widget.nisabThreshold.currencyCode == widget.currencyCode,
      'nisabThreshold must be denominated in currencyCode '
      '(${widget.currencyCode}).',
    );
    assert(
      widget.prefilledCash == null ||
          widget.prefilledCash!.currencyCode == widget.currencyCode,
      'prefilledCash must be denominated in currencyCode '
      '(${widget.currencyCode}).',
    );
    _cash = widget.prefilledCash?.amount;
  }

  Decimal get _totalAssets {
    var sum = Decimal.zero;
    for (final part in [
      _cash,
      _goldSilver,
      _investments,
      _businessAssets,
      _receivables,
    ]) {
      sum += part ?? Decimal.zero;
    }
    return sum;
  }

  /// Assets minus debts, floored at zero: over-indebted estates owe
  /// nothing rather than a negative amount.
  Decimal get _zakatableWealth {
    final net = _totalAssets - (_debts ?? Decimal.zero);
    return net < Decimal.zero ? Decimal.zero : net;
  }

  Money get _zakatDue {
    final rate = Decimal.parse(widget.zakatRate.toString());
    final digits = BankCurrencies.of(widget.currencyCode).decimalDigits;
    return Money(
      amount: (_zakatableWealth * rate).round(scale: digits),
      currencyCode: widget.currencyCode,
    );
  }

  Widget _sectionHeader(String label, BankThemeData theme) => Semantics(
        header: true,
        child: Text(
          label,
          style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
        ),
      );

  Widget _amountField({
    required String label,
    required ValueChanged<Decimal?> onChanged,
    Decimal? initialAmount,
  }) =>
      BankAmountInputField(
        currencyCode: widget.currencyCode,
        onChanged: onChanged,
        initialAmount: initialAmount,
        label: label,
        displaySize: BankBalanceSize.medium,
      );

  Widget _belowNisabState(BankThemeData theme) => MergeSemantics(
        key: const ValueKey<bool>(true),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.08),
            borderRadius: theme.buttonRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
            child: Row(
              children: [
                Icon(BankIcons.info, size: 24, color: theme.primary),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Text(
                    widget.belowNisabMessage,
                    style: BankTokens.bodyMedium.copyWith(
                      color: theme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _zakatDueBlock(BankThemeData theme, Money zakatDue) => Column(
        key: const ValueKey<bool>(false),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.zakatDueLabel,
            style: BankTokens.labelMedium.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BankTokens.space1),
          BankBalanceText(money: zakatDue),
          const SizedBox(height: BankTokens.space4),
          Semantics(
            button: true,
            label: widget.payLabel,
            child: FilledButton(
              onPressed: () => widget.onPay(zakatDue),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                minimumSize: const Size(
                  double.infinity,
                  BankTokens.minTapTarget,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
                textStyle: BankTokens.labelLarge,
              ),
              child: Text(widget.payLabel),
            ),
          ),
        ],
      );

  Widget _computationCard(BuildContext context, BankThemeData theme) {
    final wealth = Money(
      amount: _zakatableWealth,
      currencyCode: widget.currencyCode,
    );
    final belowNisab = _zakatableWealth < widget.nisabThreshold.amount;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      color: theme.surface,
      elevation: theme.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BankSummaryStack(
              items: [
                BankSummaryItem(
                  label: widget.totalWealthLabel,
                  money: wealth,
                  emphasized: true,
                ),
                BankSummaryItem(
                  label: widget.nisabLabel,
                  money: widget.nisabThreshold,
                ),
              ],
            ),
            const SizedBox(height: BankTokens.space4),
            AnimatedSize(
              duration:
                  disableAnimations ? Duration.zero : BankTokens.durationBase,
              curve: BankTokens.curveStandard,
              alignment: AlignmentDirectional.topStart,
              child: AnimatedSwitcher(
                duration:
                    disableAnimations ? Duration.zero : BankTokens.durationBase,
                switchInCurve: BankTokens.curveStandard,
                switchOutCurve: BankTokens.curveStandard,
                child: belowNisab
                    ? _belowNisabState(theme)
                    : _zakatDueBlock(theme, _zakatDue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionHeader(widget.assetsSectionLabel, theme),
        const SizedBox(height: BankTokens.space3),
        _amountField(
          label: widget.cashLabel,
          onChanged: (v) => setState(() => _cash = v),
          initialAmount: widget.prefilledCash?.amount,
        ),
        const SizedBox(height: BankTokens.space4),
        _amountField(
          label: widget.goldSilverLabel,
          onChanged: (v) => setState(() => _goldSilver = v),
        ),
        const SizedBox(height: BankTokens.space4),
        _amountField(
          label: widget.investmentsLabel,
          onChanged: (v) => setState(() => _investments = v),
        ),
        const SizedBox(height: BankTokens.space4),
        _amountField(
          label: widget.businessAssetsLabel,
          onChanged: (v) => setState(() => _businessAssets = v),
        ),
        const SizedBox(height: BankTokens.space4),
        _amountField(
          label: widget.receivablesLabel,
          onChanged: (v) => setState(() => _receivables = v),
        ),
        const SizedBox(height: BankTokens.space6),
        _sectionHeader(widget.deductionsSectionLabel, theme),
        const SizedBox(height: BankTokens.space3),
        _amountField(
          label: widget.debtsLabel,
          onChanged: (v) => setState(() => _debts = v),
        ),
        const SizedBox(height: BankTokens.space6),
        _computationCard(context, theme),
        if (widget.footnote != null) ...[
          const SizedBox(height: BankTokens.space4),
          DefaultTextStyle.merge(
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
            child: widget.footnote!,
          ),
        ],
      ],
    );
  }
}
