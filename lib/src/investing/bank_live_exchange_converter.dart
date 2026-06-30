import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Two-sided live currency converter.
///
/// Editing the FROM field recomputes the TO field automatically, and vice
/// versa. A swap button flips the direction. The "Convert" button is enabled
/// only when the entered amount is positive and calls [onConvert].
///
/// The host app is responsible for supplying a fresh [ExchangeRate] whenever
/// the rate changes; the widget is stateless with respect to rate data.
class BankLiveExchangeConverter extends StatefulWidget {
  /// The current exchange rate used for conversion.
  final ExchangeRate rate;

  /// Called when the user taps the "Convert" button.
  final VoidCallback? onConvert;

  /// Called whenever the FROM amount changes, with the computed [Money] value.
  final ValueChanged<Money>? onAmountChanged;

  const BankLiveExchangeConverter({
    required this.rate,
    super.key,
    this.onConvert,
    this.onAmountChanged,
  });

  @override
  State<BankLiveExchangeConverter> createState() =>
      _BankLiveExchangeConverterState();
}

class _BankLiveExchangeConverterState extends State<BankLiveExchangeConverter> {
  // Which currency is on the FROM side (top/left).
  late String _fromCurrency;
  late String _toCurrency;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Prevents re-entrant updates when programmatically setting field text.
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.rate.fromCurrency;
    _toCurrency = widget.rate.toCurrency;

    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
  }

  @override
  void didUpdateWidget(BankLiveExchangeConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rate != widget.rate) {
      // Recalculate TO when rate changes.
      _recomputeTo();
    }
  }

  @override
  void dispose() {
    _fromController
      ..removeListener(_onFromChanged)
      ..dispose();
    _toController
      ..removeListener(_onToChanged)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Decimal get _effectiveRate {
    // If user swapped, we need the inverse rate.
    if (_fromCurrency == widget.rate.fromCurrency) {
      return widget.rate.rate;
    }
    // Swapped: from == rate.toCurrency, to == rate.fromCurrency
    if (widget.rate.rate == Decimal.zero) return Decimal.zero;
    return (Decimal.one / widget.rate.rate).toDecimal(
      scaleOnInfinitePrecision: 10,
    );
  }

  double _parseInput(String text) =>
      double.tryParse(text.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;

  void _onFromChanged() {
    if (_updating) return;
    _updating = true;
    try {
      final fromVal = _parseInput(_fromController.text);
      final rate = _effectiveRate.toDouble();
      final toVal = fromVal * rate;

      _toController.text = fromVal == 0 ? '' : toVal.toStringAsFixed(2);

      if (widget.onAmountChanged != null) {
        final fromDecimal = Decimal.parse(fromVal.toStringAsFixed(2));
        widget.onAmountChanged!(
          Money(amount: fromDecimal, currencyCode: _fromCurrency),
        );
      }
    } finally {
      _updating = false;
    }
  }

  void _onToChanged() {
    if (_updating) return;
    _updating = true;
    try {
      final toVal = _parseInput(_toController.text);
      final rate = _effectiveRate.toDouble();
      final fromVal = rate == 0 ? 0.0 : toVal / rate;

      _fromController.text = toVal == 0 ? '' : fromVal.toStringAsFixed(2);

      if (widget.onAmountChanged != null) {
        final fromDecimal = Decimal.parse(fromVal.toStringAsFixed(2));
        widget.onAmountChanged!(
          Money(amount: fromDecimal, currencyCode: _fromCurrency),
        );
      }
    } finally {
      _updating = false;
    }
  }

  void _recomputeTo() {
    if (_fromController.text.isEmpty) return;
    _updating = true;
    try {
      final fromVal = _parseInput(_fromController.text);
      final rate = _effectiveRate.toDouble();
      _toController.text =
          fromVal == 0 ? '' : (fromVal * rate).toStringAsFixed(2);
    } finally {
      _updating = false;
    }
  }

  void _swapCurrencies() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;

      // Swap field texts as well.
      final tmpText = _fromController.text;
      _updating = true;
      _fromController.text = _toController.text;
      _toController.text = tmpText;
      _updating = false;
    });
  }

  bool get _canConvert {
    final val = _parseInput(_fromController.text);
    return val > 0;
  }

  String _rateLabel() {
    final rateDouble = _effectiveRate.toDouble();
    final formatted = rateDouble.toStringAsFixed(4);
    return '1 $_fromCurrency = $formatted $_toCurrency';
  }

  String _updatedLabel() {
    final diff = DateTime.now().difference(widget.rate.fetchedAt);
    if (diff.inSeconds < 60) return 'updated just now';
    if (diff.inMinutes < 60) return 'updated ${diff.inMinutes}m ago';
    return 'updated ${diff.inHours}h ago';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── FROM field ──
        _CurrencyInputField(
          label: _fromCurrency,
          controller: _fromController,
          bankTheme: bankTheme,
        ),

        // ── Swap button ──
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
            child: Semantics(
              button: true,
              label: 'Swap currencies',
              child: Material(
                color: bankTheme.surfaceVariant,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _swapCurrencies,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(BankTokens.space2),
                    child: Icon(Icons.swap_vert, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── TO field ──
        _CurrencyInputField(
          label: _toCurrency,
          controller: _toController,
          bankTheme: bankTheme,
        ),

        const SizedBox(height: BankTokens.space3),

        // ── Exchange rate label ──
        Text(
          '${_rateLabel()} • ${_updatedLabel()}',
          style: BankTokens.bodySmall.copyWith(
            color: bankTheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: BankTokens.space5),

        // ── Convert button ──
        Semantics(
          button: true,
          enabled: _canConvert,
          label: 'Convert',
          child: AnimatedBuilder(
            animation: Listenable.merge([_fromController, _toController]),
            builder: (context, _) {
              return FilledButton(
                onPressed: _canConvert ? widget.onConvert : null,
                style: FilledButton.styleFrom(
                  backgroundColor: bankTheme.primary,
                  foregroundColor: bankTheme.onPrimary,
                  minimumSize:
                      const Size(double.infinity, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: bankTheme.buttonRadius,
                  ),
                ),
                child: Text(
                  scope.strings.confirm,
                  style: BankTokens.labelLarge.copyWith(
                    color: bankTheme.onPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private: currency input field
// ---------------------------------------------------------------------------

class _CurrencyInputField extends StatelessWidget {
  const _CurrencyInputField({
    required this.label,
    required this.controller,
    required this.bankTheme,
  });

  final String label;
  final TextEditingController controller;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: BankTokens.labelMedium.copyWith(
            color: bankTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BankTokens.space1),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
          ],
          style: bankTheme.numeralSmall.copyWith(color: bankTheme.onSurface),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: bankTheme.numeralSmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: bankTheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
              borderSide: BorderSide(color: bankTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
