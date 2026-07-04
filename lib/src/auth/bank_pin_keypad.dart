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

  /// Outer padding wrapped around the whole keypad. When null, no outer
  /// padding is added (the current behavior).
  final EdgeInsetsGeometry? padding;

  /// Fill color of each round digit key. Defaults to the theme
  /// `surfaceVariant` when null.
  final Color? backgroundColor;

  /// Color of the digit glyphs and the action (delete / biometric) icons.
  /// Defaults to the theme `onSurface` when null.
  final Color? foregroundColor;

  /// Accent color used for the key press splash and highlight. Defaults to
  /// the theme `primary` when null.
  final Color? accentColor;

  /// Text style merged over the computed digit style (headline large in the
  /// resolved foreground color). Null applies no override.
  final TextStyle? digitStyle;

  /// Diameter, in logical pixels, of every key and the empty placeholder.
  /// Defaults to 64 when null.
  final double? keySize;

  /// Glyph for the delete (backspace) key. Defaults to
  /// [Icons.backspace_outlined] when null.
  final IconData? deleteIcon;

  /// Glyph for the biometric key. Defaults to [BankIcons.biometric] when null.
  final IconData? biometricIcon;

  /// Accessibility label for the biometric key. Defaults to
  /// `'Use biometrics'` when null.
  final String? biometricSemanticLabel;

  /// Accessibility label for the delete key. Defaults to `'Delete'` when null.
  final String? deleteSemanticLabel;

  const BankPinKeypad({
    required this.onDigit,
    required this.onDelete,
    super.key,
    this.onBiometric,
    this.enabled = true,
    this.digitBuilder,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.digitStyle,
    this.keySize,
    this.deleteIcon,
    this.biometricIcon,
    this.biometricSemanticLabel,
    this.deleteSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

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

    final resolvedPadding = padding;
    if (resolvedPadding != null) {
      keypad = Padding(padding: resolvedPadding, child: keypad);
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
        final index = entry.key;
        final digit = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : BankTokens.space3),
          child: _DigitKey(
            digit: digit,
            bankTheme: bankTheme,
            onTap: enabled ? () => _handleDigit(digit) : null,
            builder: digitBuilder,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            accentColor: accentColor,
            digitStyle: digitStyle,
            keySize: keySize,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context, BankThemeData bankTheme) {
    final resolvedKeySize = keySize ?? 64;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left: biometric or empty placeholder
        if (onBiometric != null)
          _ActionKey(
            semanticLabel: biometricSemanticLabel ?? 'Use biometrics',
            icon: biometricIcon ?? BankIcons.biometric,
            bankTheme: bankTheme,
            onTap: enabled ? onBiometric : null,
            foregroundColor: foregroundColor,
            accentColor: accentColor,
            keySize: keySize,
          )
        else
          SizedBox(width: resolvedKeySize, height: resolvedKeySize),
        const SizedBox(width: BankTokens.space3),
        // Centre: digit 0
        _DigitKey(
          digit: '0',
          bankTheme: bankTheme,
          onTap: enabled ? () => _handleDigit('0') : null,
          builder: digitBuilder,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          accentColor: accentColor,
          digitStyle: digitStyle,
          keySize: keySize,
        ),
        const SizedBox(width: BankTokens.space3),
        // Right: delete
        _ActionKey(
          semanticLabel: deleteSemanticLabel ?? 'Delete',
          icon: deleteIcon ?? Icons.backspace_outlined,
          bankTheme: bankTheme,
          onTap: enabled ? onDelete : null,
          foregroundColor: foregroundColor,
          accentColor: accentColor,
          keySize: keySize,
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
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
    required this.digitStyle,
    required this.keySize,
  });

  final String digit;
  final BankThemeData bankTheme;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, String digit)? builder;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? accentColor;
  final TextStyle? digitStyle;
  final double? keySize;

  @override
  Widget build(BuildContext context) {
    final resolvedKeySize = keySize ?? 64;
    final resolvedAccent = accentColor ?? bankTheme.primary;
    final label = builder != null
        ? builder!(context, digit)
        : Text(
            digit,
            style: BankTokens.headlineLarge
                .copyWith(color: foregroundColor ?? bankTheme.onSurface)
                .merge(digitStyle),
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
          splashColor: resolvedAccent.withValues(alpha: 0.12),
          highlightColor: resolvedAccent.withValues(alpha: 0.08),
          child: Container(
            width: resolvedKeySize,
            height: resolvedKeySize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? bankTheme.surfaceVariant,
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
    required this.foregroundColor,
    required this.accentColor,
    required this.keySize,
  });

  final String semanticLabel;
  final IconData icon;
  final BankThemeData bankTheme;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final Color? accentColor;
  final double? keySize;

  @override
  Widget build(BuildContext context) {
    final resolvedKeySize = keySize ?? 64;
    final resolvedAccent = accentColor ?? bankTheme.primary;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          splashColor: resolvedAccent.withValues(alpha: 0.12),
          highlightColor: resolvedAccent.withValues(alpha: 0.08),
          child: SizedBox(
            width: resolvedKeySize,
            height: resolvedKeySize,
            child: Icon(
              icon,
              size: 24,
              color: foregroundColor ?? bankTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
