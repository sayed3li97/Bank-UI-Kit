import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/accounts/bank_balance_text.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/numeral_style.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankAmountKeypad
// ---------------------------------------------------------------------------

/// Large numeric keypad tuned for currency input.
///
/// The host app owns the current amount string and passes it in via
/// [amountText]. Digit presses and delete events are surfaced via callbacks;
/// the widget never mutates state itself.
///
/// ```dart
/// BankAmountKeypad(
///   amountText: _amount,
///   currencyCode: 'GBP',
///   onDigit: (d) => setState(() => _amount += d),
///   onDelete: () => setState(() {
///     if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
///   }),
///   onDecimalPoint: () => setState(() {
///     if (!_amount.contains('.')) _amount += '.';
///   }),
/// )
/// ```
class BankAmountKeypad extends StatelessWidget {
  /// Current formatted amount string shown in the display area.
  final String amountText;

  /// ISO 4217 currency code, e.g. `'GBP'`, `'USD'`.
  final String currencyCode;

  /// Called with `'0'`–`'9'` when the user taps a digit key.
  final ValueChanged<String> onDigit;

  /// Called when the user taps the delete/backspace key.
  final VoidCallback onDelete;

  /// When non-null, the decimal-point key is active and this callback is
  /// invoked when the user taps it. When `null`, the cell is rendered as an
  /// empty placeholder.
  final VoidCallback? onDecimalPoint;

  /// Numeral script used when displaying the amount.
  final NumeralStyle numeralStyle;

  /// Optional upper bound; when the current parsed amount meets or exceeds
  /// this value, digit keys are rendered at reduced opacity. The host app
  /// remains responsible for enforcing the limit — this is a visual cue only.
  final double? maxAmount;

  /// When `false`, the entire keypad is rendered at 40 % opacity and does not
  /// respond to gestures.
  final bool enabled;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  const BankAmountKeypad({
    super.key,
    required this.amountText,
    required this.currencyCode,
    required this.onDigit,
    required this.onDelete,
    this.onDecimalPoint,
    this.numeralStyle = NumeralStyle.western,
    this.maxAmount,
    this.enabled = true,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses [amountText] to a double for the max-amount comparison.
  double get _parsedAmount {
    final cleaned = amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  bool get _atMax =>
      maxAmount != null && _parsedAmount >= maxAmount!;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AmountDisplay(
          amountText: amountText,
          currencyCode: currencyCode,
          numeralStyle: scope.numeralStyle,
          bankTheme: bankTheme,
        ),
        const SizedBox(height: BankTokens.space6),
        // Digit rows 1–9
        for (final row in _rows) ...[
          _KeyRow(
            keys: row.map(
              (d) => _DigitKey(
                digit: d,
                bankTheme: bankTheme,
                dimmed: _atMax,
                enabled: enabled,
                onTap: enabled && !_atMax ? () => _handleDigit(d) : null,
              ),
            ).toList(),
          ),
          const SizedBox(height: BankTokens.space2),
        ],
        // Bottom row: decimal | 0 | backspace
        _KeyRow(
          keys: [
            _DecimalKey(
              bankTheme: bankTheme,
              enabled: enabled && onDecimalPoint != null,
              onTap: enabled && onDecimalPoint != null ? onDecimalPoint : null,
            ),
            _DigitKey(
              digit: '0',
              bankTheme: bankTheme,
              dimmed: _atMax,
              enabled: enabled,
              onTap: enabled && !_atMax ? () => _handleDigit('0') : null,
            ),
            _DeleteKey(
              bankTheme: bankTheme,
              enabled: enabled,
              onTap: enabled ? onDelete : null,
            ),
          ],
        ),
      ],
    );

    if (!enabled) {
      content = Opacity(opacity: 0.4, child: content);
    }

    return content;
  }

  void _handleDigit(String digit) {
    HapticFeedback.selectionClick();
    onDigit(digit);
  }
}

// ---------------------------------------------------------------------------
// Amount display
// ---------------------------------------------------------------------------

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.amountText,
    required this.currencyCode,
    required this.numeralStyle,
    required this.bankTheme,
  });

  final String amountText;
  final String currencyCode;
  final NumeralStyle numeralStyle;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final displayText = amountText.isEmpty ? '0' : amountText;
    final converted = numeralStyle.convert(displayText);

    return Semantics(
      label: '$currencyCode $displayText',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currencyCode,
              style: BankTokens.headlineMedium.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                converted,
                style: bankTheme.numeralHero.copyWith(
                  color: bankTheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key row
// ---------------------------------------------------------------------------

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys});

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: BankTokens.space3),
          keys[i],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Digit key
// ---------------------------------------------------------------------------

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.bankTheme,
    required this.dimmed,
    required this.enabled,
    required this.onTap,
  });

  final String digit;
  final BankThemeData bankTheme;
  final bool dimmed;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: digit,
      excludeSemantics: true,
      child: Opacity(
        opacity: dimmed ? 0.35 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: bankTheme.buttonRadius,
            splashColor: bankTheme.primary.withOpacity(0.12),
            highlightColor: bankTheme.primary.withOpacity(0.08),
            child: Container(
              width: 88,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: bankTheme.buttonRadius,
                color: bankTheme.surfaceVariant,
              ),
              child: Text(
                digit,
                style: BankTokens.headlineMedium.copyWith(
                  color: bankTheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decimal key
// ---------------------------------------------------------------------------

class _DecimalKey extends StatelessWidget {
  const _DecimalKey({
    required this.bankTheme,
    required this.enabled,
    required this.onTap,
  });

  final BankThemeData bankTheme;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox(width: 88, height: 56);
    }

    return Semantics(
      button: true,
      label: 'Decimal point',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          borderRadius: bankTheme.buttonRadius,
          splashColor: bankTheme.primary.withOpacity(0.12),
          highlightColor: bankTheme.primary.withOpacity(0.08),
          child: Container(
            width: 88,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: bankTheme.buttonRadius,
              color: bankTheme.surfaceVariant,
            ),
            child: Text(
              '.',
              style: BankTokens.headlineMedium.copyWith(
                color: bankTheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete key
// ---------------------------------------------------------------------------

class _DeleteKey extends StatelessWidget {
  const _DeleteKey({
    required this.bankTheme,
    required this.enabled,
    required this.onTap,
  });

  final BankThemeData bankTheme;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Delete',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              HapticFeedback.selectionClick();
              onTap!();
            }
          },
          borderRadius: bankTheme.buttonRadius,
          splashColor: bankTheme.primary.withOpacity(0.12),
          highlightColor: bankTheme.primary.withOpacity(0.08),
          child: Container(
            width: 88,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: bankTheme.buttonRadius,
              color: bankTheme.surfaceVariant,
            ),
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: bankTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
