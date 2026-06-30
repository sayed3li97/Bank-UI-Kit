import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/auth/bank_pin_dots.dart';
import '../../src/auth/bank_pin_keypad.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankCardPinManager
// ---------------------------------------------------------------------------

/// Three-step Change-PIN flow: verify current PIN → enter new PIN → confirm.
///
/// Step 0: User enters their **current** PIN.
/// Step 1: User enters the **new** PIN.
/// Step 2: User **confirms** the new PIN.
///
/// On step 2 completion the widget calls [onSubmit] with `(currentPin, newPin)`.
/// If the two new PINs do not match, a shake animation is played and an error
/// message is shown without advancing. On a successful [onSubmit] result
/// ([Future<bool>] returning `true`) [onSuccess] is invoked.
///
/// Integrates [BankPinDots] for visual feedback and [BankPinKeypad] for input.
class BankCardPinManager extends StatefulWidget {
  /// Number of digits in the PIN (typically 4 or 6).
  final int pinLength;

  /// Async submit handler. Receives the current PIN and the new PIN.
  /// Return `true` on success, `false` on failure (e.g. incorrect current PIN).
  final Future<bool> Function(String currentPin, String newPin) onSubmit;

  /// Called when the user dismisses the flow without completing it.
  final VoidCallback? onCancel;

  /// Called after a successful [onSubmit] response.
  final VoidCallback? onSuccess;

  const BankCardPinManager({
    super.key,
    this.pinLength = 4,
    required this.onSubmit,
    this.onCancel,
    this.onSuccess,
  });

  @override
  State<BankCardPinManager> createState() => _BankCardPinManagerState();
}

// ---------------------------------------------------------------------------
// Step enum
// ---------------------------------------------------------------------------

enum _PinStep { current, newPin, confirm }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _BankCardPinManagerState extends State<BankCardPinManager> {
  _PinStep _step = _PinStep.current;

  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';

  bool _showError = false;
  String _errorMessage = '';

  bool _isSubmitting = false;
  bool _success = false;

  // ---------------------------------------------------------------------------
  // Active buffer getter
  // ---------------------------------------------------------------------------

  String get _activePin => switch (_step) {
        _PinStep.current => _currentPin,
        _PinStep.newPin => _newPin,
        _PinStep.confirm => _confirmPin,
      };

  // ---------------------------------------------------------------------------
  // Step metadata
  // ---------------------------------------------------------------------------

  String get _stepTitle => switch (_step) {
        _PinStep.current => 'Enter current PIN',
        _PinStep.newPin => 'Enter new PIN',
        _PinStep.confirm => 'Confirm new PIN',
      };

  String get _stepSubtitle => switch (_step) {
        _PinStep.current => 'Enter the PIN for your card',
        _PinStep.newPin => 'Choose a new ${widget.pinLength}-digit PIN',
        _PinStep.confirm => 'Re-enter your new PIN to confirm',
      };

  // ---------------------------------------------------------------------------
  // Digit handlers
  // ---------------------------------------------------------------------------

  void _onDigit(String digit) {
    if (_isSubmitting || _success) return;

    final current = _activePin;
    if (current.length >= widget.pinLength) return;

    setState(() {
      _showError = false;
      _errorMessage = '';
      _setActive(current + digit);
    });

    // Auto-advance when the buffer is full.
    final updated = _activePin;
    if (updated.length == widget.pinLength) {
      _onPinComplete();
    }
  }

  void _onDelete() {
    if (_isSubmitting || _success) return;
    final current = _activePin;
    if (current.isEmpty) return;
    setState(() {
      _showError = false;
      _setActive(current.substring(0, current.length - 1));
    });
  }

  void _setActive(String value) {
    switch (_step) {
      case _PinStep.current:
        _currentPin = value;
      case _PinStep.newPin:
        _newPin = value;
      case _PinStep.confirm:
        _confirmPin = value;
    }
  }

  // ---------------------------------------------------------------------------
  // Step completion logic
  // ---------------------------------------------------------------------------

  void _onPinComplete() {
    switch (_step) {
      case _PinStep.current:
        _advanceTo(_PinStep.newPin);
      case _PinStep.newPin:
        _advanceTo(_PinStep.confirm);
      case _PinStep.confirm:
        _handleConfirm();
    }
  }

  void _advanceTo(_PinStep next) {
    setState(() {
      _step = next;
      _showError = false;
      _errorMessage = '';
    });
  }

  Future<void> _handleConfirm() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _showError = true;
        _errorMessage = "PINs don't match. Please try again.";
        _confirmPin = '';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ok = await widget.onSubmit(_currentPin, _newPin);
      if (!mounted) return;

      if (ok) {
        setState(() {
          _success = true;
          _isSubmitting = false;
        });
        widget.onSuccess?.call();
      } else {
        // Incorrect current PIN — return to step 0.
        setState(() {
          _isSubmitting = false;
          _step = _PinStep.current;
          _currentPin = '';
          _newPin = '';
          _confirmPin = '';
          _showError = true;
          _errorMessage = 'Incorrect current PIN. Please try again.';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showError = true;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Back / cancel
  // ---------------------------------------------------------------------------

  void _goBack() {
    switch (_step) {
      case _PinStep.current:
        widget.onCancel?.call();
      case _PinStep.newPin:
        setState(() {
          _step = _PinStep.current;
          _currentPin = '';
          _showError = false;
          _errorMessage = '';
        });
      case _PinStep.confirm:
        setState(() {
          _step = _PinStep.newPin;
          _newPin = '';
          _showError = false;
          _errorMessage = '';
        });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    if (_success) {
      return _SuccessView(bankTheme: bankTheme);
    }

    return Semantics(
      label: _stepTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Navigation bar ─────────────────────────────────────────────────
          _PinStepNavBar(
            step: _step,
            onBack: _goBack,
            bankTheme: bankTheme,
          ),

          const SizedBox(height: BankTokens.space8),

          // ── Title & subtitle ───────────────────────────────────────────────
          Text(
            _stepTitle,
            style: BankTokens.headlineMedium.copyWith(
              color: bankTheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: BankTokens.space1),

          Text(
            _stepSubtitle,
            style: BankTokens.bodyMedium.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: BankTokens.space8),

          // ── PIN dots ───────────────────────────────────────────────────────
          BankPinDots(
            length: widget.pinLength,
            filled: _activePin.length,
            error: _showError,
          ),

          // ── Error message ──────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: BankTokens.durationBase,
            child: _showError && _errorMessage.isNotEmpty
                ? Padding(
                    key: ValueKey(_errorMessage),
                    padding: const EdgeInsets.only(top: BankTokens.space3),
                    child: Text(
                      _errorMessage,
                      style: BankTokens.bodySmall.copyWith(
                        color: BankTokens.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('no-error'),
                    height: BankTokens.space6,
                  ),
          ),

          const SizedBox(height: BankTokens.space6),

          // ── Keypad ────────────────────────────────────────────────────────
          BankPinKeypad(
            onDigit: _onDigit,
            onDelete: _onDelete,
            enabled: !_isSubmitting,
          ),

          // ── Loading indicator ─────────────────────────────────────────────
          if (_isSubmitting) ...[
            const SizedBox(height: BankTokens.space4),
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: bankTheme.primary,
              ),
            ),
          ],

          const SizedBox(height: BankTokens.space6),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PinStepNavBar
// ---------------------------------------------------------------------------

/// Step navigation bar with a back arrow and a step indicator.
class _PinStepNavBar extends StatelessWidget {
  final _PinStep step;
  final VoidCallback onBack;
  final BankThemeData bankTheme;

  const _PinStepNavBar({
    required this.step,
    required this.onBack,
    required this.bankTheme,
  });

  String get _stepLabel => switch (step) {
        _PinStep.current => 'Step 1 of 3',
        _PinStep.newPin => 'Step 2 of 3',
        _PinStep.confirm => 'Step 3 of 3',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button — min 44×44
        Semantics(
          button: true,
          label: 'Go back',
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            child: SizedBox(
              width: BankTokens.minTapTarget,
              height: BankTokens.minTapTarget,
              child: Center(
                child: Icon(
                  Icons.arrow_back,
                  color: bankTheme.onSurface,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          _stepLabel,
          style: BankTokens.labelMedium.copyWith(
            color: bankTheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // Placeholder to keep the step label centred.
        const SizedBox(width: BankTokens.minTapTarget),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _SuccessView
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final BankThemeData bankTheme;

  const _SuccessView({required this.bankTheme});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PIN changed successfully',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BankTokens.space12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: BankTokens.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: BankTokens.success,
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space5),
          Text(
            'PIN Changed',
            style: BankTokens.headlineMedium.copyWith(
              color: bankTheme.onSurface,
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            'Your card PIN has been updated successfully.',
            style: BankTokens.bodyMedium.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BankTokens.space12),
        ],
      ),
    );
  }
}
