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

  /// Overrides the outer padding around the converter. Defaults to none.
  final EdgeInsetsGeometry? padding;

  /// Placeholder shown in each empty amount field. Defaults to `'0.00'`.
  final String hintText;

  /// Glyph on the swap button. Defaults to [Icons.swap_vert].
  final IconData swapIcon;

  /// Semantic label for the swap button. Defaults to `'Swap currencies'`.
  final String swapSemanticLabel;

  /// Semantic label for the convert button. Defaults to `'Convert'`.
  final String convertSemanticLabel;

  /// Rate line template. `{from}`, `{rate}`, and `{to}` are substituted.
  /// Defaults to `'1 {from} = {rate} {to}'`.
  final String rateTemplate;

  /// Separator between the rate line and the freshness line. Defaults to
  /// `' • '`.
  final String rateSeparator;

  /// Freshness label used within the last minute. Defaults to
  /// `'updated just now'`.
  final String updatedJustNowLabel;

  /// Freshness template in minutes; `{n}` is substituted. Defaults to
  /// `'updated {n}m ago'`.
  final String updatedMinutesTemplate;

  /// Freshness template in hours; `{n}` is substituted. Defaults to
  /// `'updated {n}h ago'`.
  final String updatedHoursTemplate;

  /// Overrides the amount-field corner radius. Defaults to
  /// `BorderRadius.circular(BankTokens.radiusMedium)`.
  final BorderRadius? fieldRadius;

  /// Overrides the amount-field fill colour. Defaults to the theme
  /// surfaceVariant.
  final Color? fieldFillColor;

  /// Overrides the swap button background. Defaults to the theme
  /// surfaceVariant.
  final Color? swapButtonColor;

  /// Overrides the primary accent (convert button background and the
  /// focused-field border). Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the convert button corner radius. Defaults to the theme
  /// buttonRadius.
  final BorderRadius? buttonRadius;

  /// Merged over the field-label style
  /// (BankTokens.labelMedium in onSurfaceVariant).
  final TextStyle? fieldLabelStyle;

  /// Merged over the amount-input text style (numeralSmall in onSurface).
  final TextStyle? inputStyle;

  /// Merged over the amount-input hint style
  /// (numeralSmall in onSurfaceVariant).
  final TextStyle? hintStyle;

  /// Merged over the rate line style (BankTokens.bodySmall in
  /// onSurfaceVariant).
  final TextStyle? rateLabelStyle;

  /// Merged over the convert button label style
  /// (BankTokens.labelLarge in onPrimary).
  final TextStyle? convertLabelStyle;

  const BankLiveExchangeConverter({
    required this.rate,
    super.key,
    this.onConvert,
    this.onAmountChanged,
    this.padding,
    this.hintText = '0.00',
    this.swapIcon = Icons.swap_vert,
    this.swapSemanticLabel = 'Swap currencies',
    this.convertSemanticLabel = 'Convert',
    this.rateTemplate = '1 {from} = {rate} {to}',
    this.rateSeparator = ' • ',
    this.updatedJustNowLabel = 'updated just now',
    this.updatedMinutesTemplate = 'updated {n}m ago',
    this.updatedHoursTemplate = 'updated {n}h ago',
    this.fieldRadius,
    this.fieldFillColor,
    this.swapButtonColor,
    this.accentColor,
    this.buttonRadius,
    this.fieldLabelStyle,
    this.inputStyle,
    this.hintStyle,
    this.rateLabelStyle,
    this.convertLabelStyle,
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
    return widget.rateTemplate
        .replaceAll('{from}', _fromCurrency)
        .replaceAll('{rate}', formatted)
        .replaceAll('{to}', _toCurrency);
  }

  String _updatedLabel() {
    final diff = DateTime.now().difference(widget.rate.fetchedAt);
    if (diff.inSeconds < 60) return widget.updatedJustNowLabel;
    if (diff.inMinutes < 60) {
      return widget.updatedMinutesTemplate
          .replaceAll('{n}', '${diff.inMinutes}');
    }
    return widget.updatedHoursTemplate.replaceAll('{n}', '${diff.inHours}');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final accent = widget.accentColor ?? bankTheme.primary;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── FROM field ──
        _CurrencyInputField(
          label: _fromCurrency,
          controller: _fromController,
          bankTheme: bankTheme,
          hintText: widget.hintText,
          fieldRadius: widget.fieldRadius,
          fillColor: widget.fieldFillColor,
          focusColor: accent,
          labelStyle: widget.fieldLabelStyle,
          inputStyle: widget.inputStyle,
          hintStyle: widget.hintStyle,
        ),

        // ── Swap button ──
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
            child: Semantics(
              button: true,
              label: widget.swapSemanticLabel,
              child: Material(
                color: widget.swapButtonColor ?? bankTheme.surfaceVariant,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _swapCurrencies,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(BankTokens.space2),
                    child: Icon(widget.swapIcon, size: 22),
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
          hintText: widget.hintText,
          fieldRadius: widget.fieldRadius,
          fillColor: widget.fieldFillColor,
          focusColor: accent,
          labelStyle: widget.fieldLabelStyle,
          inputStyle: widget.inputStyle,
          hintStyle: widget.hintStyle,
        ),

        const SizedBox(height: BankTokens.space3),

        // ── Exchange rate label ──
        Text(
          '${_rateLabel()}${widget.rateSeparator}${_updatedLabel()}',
          style: BankTokens.bodySmall
              .copyWith(color: bankTheme.onSurfaceVariant)
              .merge(widget.rateLabelStyle),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: BankTokens.space5),

        // ── Convert button ──
        Semantics(
          button: true,
          enabled: _canConvert,
          label: widget.convertSemanticLabel,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fromController, _toController]),
            builder: (context, _) {
              return FilledButton(
                onPressed: _canConvert ? widget.onConvert : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: bankTheme.onPrimary,
                  minimumSize:
                      const Size(double.infinity, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: widget.buttonRadius ?? bankTheme.buttonRadius,
                  ),
                ),
                child: Text(
                  scope.strings.confirm,
                  style: BankTokens.labelLarge
                      .copyWith(color: bankTheme.onPrimary)
                      .merge(widget.convertLabelStyle),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.padding == null) return column;
    return Padding(padding: widget.padding!, child: column);
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
    required this.hintText,
    this.fieldRadius,
    this.fillColor,
    this.focusColor,
    this.labelStyle,
    this.inputStyle,
    this.hintStyle,
  });

  final String label;
  final TextEditingController controller;
  final BankThemeData bankTheme;
  final String hintText;
  final BorderRadius? fieldRadius;
  final Color? fillColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final TextStyle? inputStyle;
  final TextStyle? hintStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius =
        fieldRadius ?? BorderRadius.circular(BankTokens.radiusMedium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: BankTokens.labelMedium
              .copyWith(color: bankTheme.onSurfaceVariant)
              .merge(labelStyle),
        ),
        const SizedBox(height: BankTokens.space1),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
          ],
          style: bankTheme.numeralSmall
              .copyWith(color: bankTheme.onSurface)
              .merge(inputStyle),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: bankTheme.numeralSmall
                .copyWith(color: bankTheme.onSurfaceVariant)
                .merge(hintStyle),
            filled: true,
            fillColor: fillColor ?? bankTheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: resolvedRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: resolvedRadius,
              borderSide: BorderSide(
                color: focusColor ?? bankTheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
