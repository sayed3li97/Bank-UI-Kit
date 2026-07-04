import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///     if (_amount.isNotEmpty) {
///       _amount = _amount.substring(0, _amount.length - 1);
///     }
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
  /// remains responsible for enforcing the limit: this is a visual cue only.
  final double? maxAmount;

  /// When `false`, the entire keypad is rendered at 40 % opacity and does not
  /// respond to gestures.
  final bool enabled;

  /// Overrides the corner radius of each key. Defaults to the theme
  /// buttonRadius.
  final BorderRadius? keyRadius;

  /// Overrides the background color of each key. Defaults to the theme
  /// surfaceVariant.
  final Color? keyColor;

  /// Overrides the digit, decimal, and delete glyph color on each key.
  /// Defaults to the theme onSurface.
  final Color? keyForegroundColor;

  /// Merged over the amount display style (theme numeralHero in onSurface).
  final TextStyle? amountStyle;

  /// Merged over the currency code style
  /// (BankTokens.headlineMedium in onSurfaceVariant).
  final TextStyle? currencyStyle;

  /// Merged over each key label style
  /// (BankTokens.headlineMedium in onSurface).
  final TextStyle? keyTextStyle;

  /// Overrides the delete key glyph. Defaults to
  /// [Icons.backspace_outlined].
  final IconData? deleteIcon;

  /// Overrides the width of each key. Defaults to `88`.
  final double? keyWidth;

  /// Overrides the height of each key. Defaults to `56`.
  final double? keyHeight;

  /// Semantics label of the delete key. Defaults to `'Delete'`.
  final String deleteSemanticLabel;

  /// Semantics label of the decimal-point key. Defaults to
  /// `'Decimal point'`.
  final String decimalSemanticLabel;

  /// Overrides the semantics label of the amount display. Defaults to
  /// `'<currencyCode> <amount>'`.
  final String? semanticLabel;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  const BankAmountKeypad({
    required this.amountText,
    required this.currencyCode,
    required this.onDigit,
    required this.onDelete,
    super.key,
    this.onDecimalPoint,
    this.numeralStyle = NumeralStyle.western,
    this.maxAmount,
    this.enabled = true,
    this.keyRadius,
    this.keyColor,
    this.keyForegroundColor,
    this.amountStyle,
    this.currencyStyle,
    this.keyTextStyle,
    this.deleteIcon,
    this.keyWidth,
    this.keyHeight,
    this.deleteSemanticLabel = 'Delete',
    this.decimalSemanticLabel = 'Decimal point',
    this.semanticLabel,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses [amountText] to a double for the max-amount comparison.
  double get _parsedAmount {
    final cleaned = amountText.replaceAll(RegExp('[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  bool get _atMax => maxAmount != null && _parsedAmount >= maxAmount!;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final resolvedKeyRadius = keyRadius ?? bankTheme.buttonRadius;
    final resolvedKeyColor = keyColor ?? bankTheme.surfaceVariant;
    final resolvedKeyForeground = keyForegroundColor ?? bankTheme.onSurface;
    final resolvedKeyStyle = BankTokens.headlineMedium
        .copyWith(color: resolvedKeyForeground)
        .merge(keyTextStyle);
    final resolvedKeyWidth = keyWidth ?? 88.0;
    final resolvedKeyHeight = keyHeight ?? 56.0;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AmountDisplay(
          amountText: amountText,
          currencyCode: currencyCode,
          numeralStyle: scope.numeralStyle,
          bankTheme: bankTheme,
          amountStyle: amountStyle,
          currencyStyle: currencyStyle,
          semanticLabel: semanticLabel,
        ),
        const SizedBox(height: BankTokens.space6),
        // Digit rows 1–9
        for (final row in _rows) ...[
          _KeyRow(
            keys: row
                .map(
                  (d) => _DigitKey(
                    digit: d,
                    bankTheme: bankTheme,
                    dimmed: _atMax,
                    enabled: enabled,
                    onTap: enabled && !_atMax ? () => _handleDigit(d) : null,
                    radius: resolvedKeyRadius,
                    color: resolvedKeyColor,
                    textStyle: resolvedKeyStyle,
                    width: resolvedKeyWidth,
                    height: resolvedKeyHeight,
                  ),
                )
                .toList(),
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
              radius: resolvedKeyRadius,
              color: resolvedKeyColor,
              textStyle: resolvedKeyStyle,
              width: resolvedKeyWidth,
              height: resolvedKeyHeight,
              semanticLabel: decimalSemanticLabel,
            ),
            _DigitKey(
              digit: '0',
              bankTheme: bankTheme,
              dimmed: _atMax,
              enabled: enabled,
              onTap: enabled && !_atMax ? () => _handleDigit('0') : null,
              radius: resolvedKeyRadius,
              color: resolvedKeyColor,
              textStyle: resolvedKeyStyle,
              width: resolvedKeyWidth,
              height: resolvedKeyHeight,
            ),
            _DeleteKey(
              bankTheme: bankTheme,
              enabled: enabled,
              onTap: enabled ? onDelete : null,
              radius: resolvedKeyRadius,
              color: resolvedKeyColor,
              icon: deleteIcon ?? Icons.backspace_outlined,
              iconColor: resolvedKeyForeground,
              width: resolvedKeyWidth,
              height: resolvedKeyHeight,
              semanticLabel: deleteSemanticLabel,
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
    required this.amountStyle,
    required this.currencyStyle,
    required this.semanticLabel,
  });

  final String amountText;
  final String currencyCode;
  final NumeralStyle numeralStyle;
  final BankThemeData bankTheme;
  final TextStyle? amountStyle;
  final TextStyle? currencyStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final displayText = amountText.isEmpty ? '0' : amountText;
    final converted = numeralStyle.convert(displayText);

    return Semantics(
      label: semanticLabel ?? '$currencyCode $displayText',
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
              style: BankTokens.headlineMedium
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(currencyStyle),
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                converted,
                style: bankTheme.numeralHero
                    .copyWith(color: bankTheme.onSurface)
                    .merge(amountStyle),
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
    required this.radius,
    required this.color,
    required this.textStyle,
    required this.width,
    required this.height,
  });

  final String digit;
  final BankThemeData bankTheme;
  final bool dimmed;
  final bool enabled;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color color;
  final TextStyle textStyle;
  final double width;
  final double height;

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
            borderRadius: radius,
            splashColor: bankTheme.primary.withValues(alpha: 0.12),
            highlightColor: bankTheme.primary.withValues(alpha: 0.08),
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: color,
              ),
              child: Text(digit, style: textStyle),
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
    required this.radius,
    required this.color,
    required this.textStyle,
    required this.width,
    required this.height,
    required this.semanticLabel,
  });

  final BankThemeData bankTheme;
  final bool enabled;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color color;
  final TextStyle textStyle;
  final double width;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return SizedBox(width: width, height: height);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          borderRadius: radius,
          splashColor: bankTheme.primary.withValues(alpha: 0.12),
          highlightColor: bankTheme.primary.withValues(alpha: 0.08),
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: color,
            ),
            child: Text('.', style: textStyle),
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
    required this.radius,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.width,
    required this.height,
    required this.semanticLabel,
  });

  final BankThemeData bankTheme;
  final bool enabled;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final double width;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
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
          borderRadius: radius,
          splashColor: bankTheme.primary.withValues(alpha: 0.12),
          highlightColor: bankTheme.primary.withValues(alpha: 0.08),
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: color,
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
