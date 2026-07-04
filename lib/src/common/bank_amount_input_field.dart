import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accounts/bank_balance_text.dart';
import '../models/bank_currency.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';
import 'money_formatter.dart';

/// A format-as-you-type monetary text field: the form-embedded counterpart
/// to `BankAmountKeypad`.
///
/// The field renders the currency symbol (resolved through
/// [BankMoneyFormatter]'s symbol table) as a fixed prefix, groups thousands
/// live while the user types, restricts fraction digits to the currency's
/// precision (0 for JPY, 3 for KWD/BHD, 2 by default), and converts digits
/// per [NumeralStyle]: falling back to the ambient [BankUiScope] style when
/// [numeralStyle] is `null`.
///
/// The parsed value is emitted as a [Decimal] via [onChanged] so hosts can
/// construct `Money(amount, currencyCode)` directly. Empty input reports
/// `null`. When the entered amount exceeds [maxAmount] (or falls below
/// [minAmount]), the entry text and helper line turn [BankTokens.danger] and
/// `null` is reported.
///
/// A non-null [errorText] replaces the helper line and turns the border
/// [BankTokens.danger], matching `BankTextField`.
///
/// ```dart
/// BankAmountInputField(
///   currencyCode: 'USD',
///   onChanged: (amount) => setState(() => _amount = amount),
///   label: 'Amount',
///   helperText: 'Available: \$5,000.00',
///   maxAmount: Decimal.parse('5000'),
/// )
/// ```
class BankAmountInputField extends StatefulWidget {
  const BankAmountInputField({
    required this.currencyCode,
    required this.onChanged,
    super.key,
    this.initialAmount,
    this.maxAmount,
    this.minAmount,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.displaySize = BankBalanceSize.large,
    this.numeralStyle,
    this.contentPadding,
    this.radius,
    this.backgroundColor,
    this.amountStyle,
    this.labelStyle,
    this.helperStyle,
    this.errorStyle,
    this.semanticLabel,
  });

  /// ISO 4217 currency code, e.g. `'USD'`, `'JPY'`. Determines the prefix
  /// symbol and the number of fraction digits accepted.
  final String currencyCode;

  /// Called on every edit with the parsed amount, or `null` when the field
  /// is empty or the amount is outside [minAmount]..[maxAmount].
  final ValueChanged<Decimal?> onChanged;

  /// Pre-filled amount shown when the field first builds.
  final Decimal? initialAmount;

  /// Upper bound; amounts above it render in [BankTokens.danger] and report
  /// `null` to [onChanged].
  final Decimal? maxAmount;

  /// Lower bound; amounts below it render in [BankTokens.danger] and report
  /// `null` to [onChanged].
  final Decimal? minAmount;

  /// Label rendered above the field. Coloured [BankTokens.danger] on error.
  final String? label;

  /// Helper text rendered below the field. Replaced by [errorText] when set
  /// and tinted [BankTokens.danger] while the amount is out of range.
  final String? helperText;

  /// Error message. When non-null the border turns [BankTokens.danger] and
  /// the label is tinted accordingly.
  final String? errorText;

  /// When `false` the field is greyed out and does not accept input.
  final bool enabled;

  /// Whether the field requests focus when first built.
  final bool autofocus;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Numeral typography tier (from [BankThemeData]) used for the entry text.
  final BankBalanceSize displaySize;

  /// Numeral script for the entered digits. Falls back to
  /// [BankUiScopeData.numeralStyle] when `null`.
  final NumeralStyle? numeralStyle;

  /// Overrides the field's inner content padding (default:
  /// [BankTokens.space4] horizontal by [BankTokens.space3] vertical).
  final EdgeInsetsGeometry? contentPadding;

  /// Overrides [BankThemeData.buttonRadius] as the field border radius.
  final BorderRadius? radius;

  /// Overrides [BankThemeData.surface] as the fill while enabled
  /// (the disabled fill stays [BankThemeData.surfaceVariant]).
  final Color? backgroundColor;

  /// Merged over the computed entry style (the [displaySize] numeral
  /// tier coloured per the in-range state).
  final TextStyle? amountStyle;

  /// Merged over the computed [label] style (default:
  /// [BankTokens.labelMedium] coloured per the error state).
  final TextStyle? labelStyle;

  /// Merged over the computed [helperText] style (default:
  /// [BankTokens.bodySmall] coloured per the in-range state).
  final TextStyle? helperStyle;

  /// Merged over the computed [errorText] style (default:
  /// [BankTokens.bodySmall] in [BankTokens.danger]).
  final TextStyle? errorStyle;

  /// Overrides [label] as the field's semantics label.
  final String? semanticLabel;

  @override
  State<BankAmountInputField> createState() => _BankAmountInputFieldState();
}

class _BankAmountInputFieldState extends State<BankAmountInputField> {
  final TextEditingController _controller = TextEditingController();

  Decimal? _amount;
  bool _outOfRange = false;
  bool _initialised = false;
  NumeralStyle _appliedStyle = NumeralStyle.western;

  int get _precision => _precisionFor(widget.currencyCode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final style = widget.numeralStyle ?? BankUiScope.of(context).numeralStyle;
    if (!_initialised) {
      _initialised = true;
      _appliedStyle = style;
      final initial = widget.initialAmount;
      if (initial != null) {
        final raw = initial.toStringAsFixed(_precision);
        _setControllerText(_displayFromRaw(raw, style));
        _amount = initial;
        _outOfRange = _isOutOfRange(initial);
      }
    } else if (style != _appliedStyle) {
      _appliedStyle = style;
      final raw = _rawFromDisplay(_controller.text, _precision);
      _setControllerText(_displayFromRaw(raw, style));
    }
  }

  @override
  void didUpdateWidget(BankAmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currencyCode != oldWidget.currencyCode ||
        widget.maxAmount != oldWidget.maxAmount ||
        widget.minAmount != oldWidget.minAmount) {
      final raw = _rawFromDisplay(_controller.text, _precision);
      if (widget.currencyCode != oldWidget.currencyCode) {
        _setControllerText(_displayFromRaw(raw, _appliedStyle));
      }
      _amount = _parseRaw(raw);
      _outOfRange = _amount != null && _isOutOfRange(_amount!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setControllerText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  bool _isOutOfRange(Decimal amount) {
    final max = widget.maxAmount;
    final min = widget.minAmount;
    return (max != null && amount > max) || (min != null && amount < min);
  }

  void _handleTextChanged(String text) {
    final raw = _rawFromDisplay(text, _precision);
    final amount = _parseRaw(raw);
    final outOfRange = amount != null && _isOutOfRange(amount);
    setState(() {
      _amount = amount;
      _outOfRange = outOfRange;
    });
    widget.onChanged(outOfRange ? null : amount);
  }

  TextStyle _entryStyle(BankThemeData theme) => switch (widget.displaySize) {
        BankBalanceSize.hero => theme.numeralHero,
        BankBalanceSize.large => theme.numeralLarge,
        BankBalanceSize.medium => theme.numeralMedium,
        BankBalanceSize.small => theme.numeralSmall,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final hasError = widget.errorText != null;

    final entryColor = _outOfRange ? BankTokens.danger : theme.onSurface;
    final entryStyle = _entryStyle(theme)
        .copyWith(color: entryColor)
        .merge(widget.amountStyle);
    final symbol = _currencySymbolFor(widget.currencyCode);
    final zeroHint = _appliedStyle.convert(
      _precision == 0 ? '0' : '0.${'0' * _precision}',
    );

    final borderColor = hasError ? BankTokens.danger : theme.outline;
    final focusedColor = hasError ? BankTokens.danger : theme.primary;
    final borderRadius = widget.radius ?? theme.buttonRadius;

    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: focusedColor, width: 2),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: theme.outline.withValues(alpha: 0.4)),
    );

    Widget field = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: _precision > 0,
      ),
      inputFormatters: [
        _BankAmountTextInputFormatter(
          precision: _precision,
          numeralStyle: _appliedStyle,
        ),
      ],
      onChanged: _handleTextChanged,
      style: entryStyle,
      decoration: InputDecoration(
        hintText: zeroHint,
        hintStyle: _entryStyle(theme).copyWith(
          color: theme.onSurfaceVariant,
        ),
        prefix: Padding(
          padding: const EdgeInsetsDirectional.only(end: BankTokens.space1),
          child: Text(
            symbol,
            style: _entryStyle(theme).copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ),
        filled: true,
        fillColor: widget.enabled
            ? (widget.backgroundColor ?? theme.surface)
            : theme.surfaceVariant,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: BankTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: BankTokens.danger, width: 2),
        ),
        disabledBorder: disabledBorder,
      ),
    );

    final semanticsLabel = widget.semanticLabel ?? widget.label;
    if (semanticsLabel != null) {
      field = Semantics(
        label: semanticsLabel,
        child: field,
      );
    }

    final helperColor =
        _outOfRange ? BankTokens.danger : theme.onSurfaceVariant;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space2),
              child: Text(
                widget.label!,
                style: BankTokens.labelMedium
                    .copyWith(
                      color: hasError ? BankTokens.danger : theme.onSurface,
                    )
                    .merge(widget.labelStyle),
              ),
            ),
          field,
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: BankTokens.space1,
                start: BankTokens.space1,
              ),
              child: Text(
                widget.errorText!,
                style: BankTokens.bodySmall
                    .copyWith(color: BankTokens.danger)
                    .merge(widget.errorStyle),
              ),
            )
          else if (widget.helperText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: BankTokens.space1,
                start: BankTokens.space1,
              ),
              child: Text(
                widget.helperText!,
                style: BankTokens.bodySmall
                    .copyWith(color: helperColor)
                    .merge(widget.helperStyle),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input formatter
// ---------------------------------------------------------------------------

/// Normalises raw keystrokes to a canonical amount string, then re-renders
/// it with live thousands grouping and [NumeralStyle] digit conversion.
///
/// The caret is kept at the end of the field: the natural position for
/// calculator-style amount entry.
class _BankAmountTextInputFormatter extends TextInputFormatter {
  _BankAmountTextInputFormatter({
    required this.precision,
    required this.numeralStyle,
  });

  final int precision;
  final NumeralStyle numeralStyle;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = _rawFromDisplay(newValue.text, precision);
    final display = _displayFromRaw(raw, numeralStyle);
    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency metadata comes from the shared BankCurrencies registry, so
// precision and symbols stay consistent with every other money surface.
// ---------------------------------------------------------------------------

int _precisionFor(String currencyCode) =>
    BankCurrencies.of(currencyCode).decimalDigits;

/// Extracts the display symbol for [currencyCode] by formatting zero through
/// [BankMoneyFormatter] and stripping the digits: reusing the kit's symbol
/// table instead of duplicating it.
String _currencySymbolFor(String currencyCode) =>
    BankMoneyFormatter.symbolFor(currencyCode);

// ---------------------------------------------------------------------------
// Amount string pipeline
// ---------------------------------------------------------------------------

/// Lookup table from Eastern Arabic-Indic digit to ASCII equivalent.
const Map<String, String> _westernFromEasternDigits = {
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
};

String _toWesternDigits(String input) => input.replaceAllMapped(
      RegExp('[٠-٩]'),
      (Match m) => _westernFromEasternDigits[m[0]]!,
    );

/// Reduces arbitrary display text to a canonical amount string: ASCII
/// digits, at most one `.`, at most [precision] fraction digits, and no
/// redundant leading zeros. Returns `''` for effectively empty input.
String _rawFromDisplay(String display, int precision) {
  final ascii = _toWesternDigits(display).replaceAll(RegExp('[^0-9.]'), '');
  if (ascii.isEmpty) return '';

  final dot = ascii.indexOf('.');
  var intPart = dot < 0 ? ascii : ascii.substring(0, dot);
  var fracPart = dot < 0 ? '' : ascii.substring(dot + 1).replaceAll('.', '');

  // Strip redundant leading zeros, keeping a single zero before the dot.
  intPart = intPart.replaceFirst(RegExp('^0+(?=[0-9])'), '');
  if (fracPart.length > precision) {
    fracPart = fracPart.substring(0, precision);
  }

  if (dot < 0 || precision == 0) return intPart;
  if (intPart.isEmpty) intPart = '0';
  return '$intPart.$fracPart';
}

/// Renders a canonical amount string with thousands grouping and numeral
/// conversion for display inside the text field.
String _displayFromRaw(String raw, NumeralStyle numeralStyle) {
  if (raw.isEmpty) return '';
  final dot = raw.indexOf('.');
  final intPart = dot < 0 ? raw : raw.substring(0, dot);
  final grouped = _groupThousands(intPart);
  final out = dot < 0 ? grouped : '$grouped.${raw.substring(dot + 1)}';
  return numeralStyle.convert(out);
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Parses a canonical amount string to a [Decimal], tolerating a trailing
/// decimal point mid-entry. Returns `null` for empty input.
Decimal? _parseRaw(String raw) {
  var cleaned = raw;
  if (cleaned.endsWith('.')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  if (cleaned.isEmpty) return null;
  return Decimal.tryParse(cleaned);
}
