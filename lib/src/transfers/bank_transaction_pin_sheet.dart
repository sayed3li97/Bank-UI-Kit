import 'package:flutter/material.dart';

import '../../src/auth/bank_pin_dots.dart';
import '../../src/auth/bank_pin_keypad.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankTransactionPinSheet
// ---------------------------------------------------------------------------

/// Transfer-specific authorisation PIN bottom sheet.
///
/// Distinct from the login PIN: uses a different semantic label, title, and
/// subtitle to make the authorisation context clear. The host app supplies an
/// [onSubmit] callback that performs the authorisation; the result determines
/// whether the sheet closes with `true` or shows an error shake.
///
/// Use [BankTransactionPinSheet.show] to present it as a modal bottom sheet:
///
/// ```dart
/// final confirmed = await BankTransactionPinSheet.show(
///   context,
///   onSubmit: (pin) async {
///     return await api.authoriseTransfer(pin);
///   },
/// );
/// if (confirmed == true) { /* proceed */ }
/// ```
class BankTransactionPinSheet extends StatefulWidget {
  /// Number of PIN digits expected. Defaults to `6`.
  final int pinLength;

  /// Called with the entered PIN when [pinLength] digits have been entered.
  /// Return `true` to close the sheet with a success result, or `false` to
  /// show a shake error and allow retry.
  final Future<bool> Function(String pin) onSubmit;

  /// Called when the user taps the cancel button. If `null`, a default
  /// `Navigator.pop` is used.
  final VoidCallback? onCancel;

  /// Sheet title. Defaults to `'Enter PIN'`.
  final String title;

  /// Subtitle shown below the title. Defaults to
  /// `'Enter your PIN to confirm this transfer'`.
  final String subtitle;

  const BankTransactionPinSheet({
    required this.onSubmit,
    super.key,
    this.pinLength = 6,
    this.onCancel,
    this.title = 'Enter PIN',
    this.subtitle = 'Enter your PIN to confirm this transfer',
  });

  // ---------------------------------------------------------------------------
  // Static show helper
  // ---------------------------------------------------------------------------

  /// Presents the sheet as a modal bottom sheet and returns `true` on
  /// successful authorisation, `false` on cancellation, or `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function(String) onSubmit,
    int pinLength = 6,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => BankTransactionPinSheet(
          onSubmit: onSubmit,
          pinLength: pinLength,
        ),
      );

  @override
  State<BankTransactionPinSheet> createState() =>
      _BankTransactionPinSheetState();
}

class _BankTransactionPinSheetState extends State<BankTransactionPinSheet> {
  String _pin = '';
  bool _loading = false;
  bool _error = false;

  // ---------------------------------------------------------------------------
  // PIN management
  // ---------------------------------------------------------------------------

  void _appendDigit(String digit) {
    if (_loading || _pin.length >= widget.pinLength) return;
    setState(() {
      _pin += digit;
      _error = false;
    });

    if (_pin.length == widget.pinLength) {
      _submit();
    }
  }

  void _deleteDigit() {
    if (_loading || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  Future<void> _submit() async {
    final pinSnapshot = _pin;
    setState(() => _loading = true);

    bool success;
    try {
      success = await widget.onSubmit(pinSnapshot);
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    // Wrong PIN: shake dots, clear after a short delay.
    setState(() {
      _loading = false;
      _error = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _pin = '';
      _error = false;
    });
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Semantics(
      label: 'Transaction PIN sheet',
      child: Container(
        decoration: BoxDecoration(
          color: bankTheme.surface,
          borderRadius: bankTheme.sheetRadius,
        ),
        padding: EdgeInsets.only(
          left: BankTokens.space6,
          right: BankTokens.space6,
          top: BankTokens.space4,
          bottom: BankTokens.space6 + mediaQuery.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: bankTheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(BankTokens.radiusFull),
              ),
            ),
            const SizedBox(height: BankTokens.space6),
            // Title
            Semantics(
              header: true,
              child: Text(
                widget.title,
                style: BankTokens.headlineMedium.copyWith(
                  color: bankTheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            // Subtitle
            Text(
              widget.subtitle,
              style: BankTokens.bodyMedium.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BankTokens.space6),
            // PIN dots
            BankPinDots(
              length: widget.pinLength,
              filled: _pin.length,
              error: _error,
            ),
            const SizedBox(height: BankTokens.space6),
            // Loading indicator overlays the keypad area when submitting.
            if (_loading)
              SizedBox(
                height: _keypadApproxHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    color: bankTheme.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              BankPinKeypad(
                onDigit: _appendDigit,
                onDelete: _deleteDigit,
                enabled: !_loading,
              ),
            const SizedBox(height: BankTokens.space4),
            // Cancel button
            SizedBox(
              height: BankTokens.minTapTarget,
              child: TextButton(
                onPressed: _loading ? null : _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: bankTheme.onSurfaceVariant,
                  minimumSize: const Size(
                    BankTokens.minTapTarget,
                    BankTokens.minTapTarget,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Approximate height of the BankPinKeypad so the loading indicator doesn't
  /// cause a layout shift.
  static const double _keypadApproxHeight = 296;
}
