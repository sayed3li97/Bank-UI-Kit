import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankPinKeypad
// ---------------------------------------------------------------------------

/// Numeric keypad for PIN entry.
///
/// Exposes [onDigit] and [onDelete] callbacks so the host app fully owns the
/// PIN string state. The layout mirrors a standard telephone keypad:
///
/// ```
///  1  2  3
///  4  5  6
///  7  8  9
/// [B] 0 [⌫]
/// ```
///
/// Where `[B]` is either a biometric trigger button (when [onBiometric] is
/// non-null) or an invisible placeholder.
///
/// Provide [digitBuilder] to replace the default digit cell rendering while
/// keeping the standard delete and biometric cells.
///
/// ```dart
/// BankPinKeypad(
///   onDigit: (d) => setState(() => _pin += d),
///   onDelete: () => setState(() {
///     if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
///   }),
///   onBiometric: _handleBiometric,
/// )
/// ```
class BankPinKeypad extends StatelessWidget {
  /// Called when the user taps a digit key. Receives the digit as a string
  /// (`'0'`–`'9'`).
  final ValueChanged<String> onDigit;

  /// Called when the user taps the delete (backspace) key.
  final VoidCallback onDelete;

  /// When non-null, a fingerprint icon button is shown in the bottom-left
  /// position and this callback is invoked on tap.
  final VoidCallback? onBiometric;

  /// When `false`, all keys are rendered at 40 % opacity and do not respond
  /// to gestures.
  final bool enabled;

  /// Optional builder for digit cells. When provided, it replaces the default
  /// [Text]-based rendering for digits `'1'`–`'9'` and `'0'`. The delete and
  /// biometric cells are not affected.
  final Widget Function(BuildContext context, String digit)? digitBuilder;

  static const List<String> _digits = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
  ];

  const BankPinKeypad({
    super.key,
    this.onBiometric,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
    this.digitBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = BankThemeData.of(context);

    Widget keypad = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rows 1–3: digits 1–9
        _buildDigitRow(context, bankTheme, ['1', '2', '3']),
        const SizedBox(height: BankTokens.space2),
        _buildDigitRow(context, bankTheme, ['4', '5', '6']),
        const SizedBox(height: BankTokens.space2),
        _buildDigitRow(context, bankTheme, ['7', '8', '9']),
        const SizedBox(height: BankTokens.space2),
        // Bottom row: biometric / empty, 0, delete
        _buildBottomRow(context, bankTheme),
      ],
    );

    if (!enabled) {
      keypad = Opacity(opacity: 0.4, child: keypad);
    }

    return keypad;
  }

  Widget _buildDigitRow(
    BuildContext context,
    BankThemeData bankTheme,
    List<String> digits,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.asMap().entries.map((entry) {
        final int index = entry.key;
        final String digit = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : BankTokens.space3),
          child: _DigitKey(
            digit: digit,
            bankTheme: bankTheme,
            onTap: enabled ? () => _handleDigit(digit) : null,
            builder: digitBuilder,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context, BankThemeData bankTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left: biometric or empty placeholder
        onBiometric != null
            ? _ActionKey(
                semanticLabel: 'Use biometrics',
                icon: BankIcons.biometric,
                bankTheme: bankTheme,
                onTap: enabled ? onBiometric : null,
              )
            : const SizedBox(width: 64, height: 64),
        const SizedBox(width: BankTokens.space3),
        // Centre: digit 0
        _DigitKey(
          digit: '0',
          bankTheme: bankTheme,
          onTap: enabled ? () => _handleDigit('0') : null,
          builder: digitBuilder,
        ),
        const SizedBox(width: BankTokens.space3),
        // Right: delete
        _ActionKey(
          semanticLabel: 'Delete',
          icon: Icons.backspace_outlined,
          bankTheme: bankTheme,
          onTap: enabled ? onDelete : null,
        ),
      ],
    );
  }

  void _handleDigit(String digit) {
    HapticFeedback.selectionClick();
    onDigit(digit);
  }
}

// ---------------------------------------------------------------------------
// _DigitKey
// ---------------------------------------------------------------------------

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.bankTheme,
    required this.onTap,
    required this.builder,
  });

  final String digit;
  final BankThemeData bankTheme;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, String digit)? builder;

  @override
  Widget build(BuildContext context) {
    final Widget label = builder != null
        ? builder!(context, digit)
        : Text(
            digit,
            style: BankTokens.headlineLarge.copyWith(
              color: bankTheme.onSurface,
            ),
          );

    return Semantics(
      button: true,
      label: digit,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          splashColor: bankTheme.primary.withOpacity(0.12),
          highlightColor: bankTheme.primary.withOpacity(0.08),
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bankTheme.surfaceVariant,
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionKey (delete / biometric)
// ---------------------------------------------------------------------------

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.semanticLabel,
    required this.icon,
    required this.bankTheme,
    required this.onTap,
  });

  final String semanticLabel;
  final IconData icon;
  final BankThemeData bankTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          splashColor: bankTheme.primary.withOpacity(0.12),
          highlightColor: bankTheme.primary.withOpacity(0.08),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(
              icon,
              size: 24,
              color: bankTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
