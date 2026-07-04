import 'dart:async';

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
/// On step 2 completion the widget calls [onSubmit] with
/// `(currentPin, newPin)`.
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

  /// Overrides the outer padding around the flow. Defaults to none.
  final EdgeInsetsGeometry? padding;

  /// Overrides the submit spinner colour. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the step title and back icon colour. Defaults to
  /// [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Overrides the success badge and icon colour. Defaults to
  /// [BankTokens.success].
  final Color? successColor;

  /// Merged over the computed title style ([BankTokens.headlineMedium]).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodyMedium]).
  final TextStyle? subtitleStyle;

  /// Merged over the computed error style ([BankTokens.bodySmall] in
  /// [BankTokens.danger]).
  final TextStyle? errorTextStyle;

  /// Merged over the step indicator style ([BankTokens.labelMedium]).
  final TextStyle? stepLabelStyle;

  /// Icon of the back button. Defaults to [Icons.arrow_back].
  final IconData backIcon;

  /// Icon shown in the success badge. Defaults to
  /// [Icons.check_circle_outline].
  final IconData successIcon;

  /// Duration of the error message switcher. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Curve of the error message switcher. Defaults to [Curves.linear].
  final Curve? animationCurve;

  /// Title of the current PIN step. Defaults to `'Enter current PIN'`.
  final String currentPinTitle;

  /// Title of the new PIN step. Defaults to `'Enter new PIN'`.
  final String newPinTitle;

  /// Title of the confirm step. Defaults to `'Confirm new PIN'`.
  final String confirmPinTitle;

  /// Subtitle of the current PIN step. Defaults to
  /// `'Enter the PIN for your card'`.
  final String currentPinSubtitle;

  /// Subtitle of the new PIN step. Defaults to
  /// `'Choose a new <pinLength>-digit PIN'`.
  final String? newPinSubtitle;

  /// Subtitle of the confirm step. Defaults to
  /// `'Re-enter your new PIN to confirm'`.
  final String confirmPinSubtitle;

  /// Error shown when the two new PINs differ. Defaults to
  /// `"PINs don't match. Please try again."`.
  final String mismatchErrorText;

  /// Error shown when the current PIN is rejected. Defaults to
  /// `'Incorrect current PIN. Please try again.'`.
  final String incorrectPinErrorText;

  /// Error shown when [onSubmit] throws. Defaults to
  /// `'Something went wrong. Please try again.'`.
  final String genericErrorText;

  /// Step indicator on the current PIN step. Defaults to `'Step 1 of 3'`.
  final String currentPinStepLabel;

  /// Step indicator on the new PIN step. Defaults to `'Step 2 of 3'`.
  final String newPinStepLabel;

  /// Step indicator on the confirm step. Defaults to `'Step 3 of 3'`.
  final String confirmPinStepLabel;

  /// Semantics label of the back button. Defaults to `'Go back'`.
  final String backSemanticLabel;

  /// Heading of the success view. Defaults to `'PIN Changed'`.
  final String successTitle;

  /// Body text of the success view. Defaults to
  /// `'Your card PIN has been updated successfully.'`.
  final String successMessage;

  /// Semantics label of the success view. Defaults to
  /// `'PIN changed successfully'`.
  final String successSemanticLabel;

  /// Overrides the root semantics label. Defaults to the current step title.
  final String? semanticLabel;

  const BankCardPinManager({
    required this.onSubmit,
    super.key,
    this.pinLength = 4,
    this.onCancel,
    this.onSuccess,
    this.padding,
    this.accentColor,
    this.foregroundColor,
    this.successColor,
    this.titleStyle,
    this.subtitleStyle,
    this.errorTextStyle,
    this.stepLabelStyle,
    this.backIcon = Icons.arrow_back,
    this.successIcon = Icons.check_circle_outline,
    this.animationDuration,
    this.animationCurve,
    this.currentPinTitle = 'Enter current PIN',
    this.newPinTitle = 'Enter new PIN',
    this.confirmPinTitle = 'Confirm new PIN',
    this.currentPinSubtitle = 'Enter the PIN for your card',
    this.newPinSubtitle,
    this.confirmPinSubtitle = 'Re-enter your new PIN to confirm',
    this.mismatchErrorText = "PINs don't match. Please try again.",
    this.incorrectPinErrorText = 'Incorrect current PIN. Please try again.',
    this.genericErrorText = 'Something went wrong. Please try again.',
    this.currentPinStepLabel = 'Step 1 of 3',
    this.newPinStepLabel = 'Step 2 of 3',
    this.confirmPinStepLabel = 'Step 3 of 3',
    this.backSemanticLabel = 'Go back',
    this.successTitle = 'PIN Changed',
    this.successMessage = 'Your card PIN has been updated successfully.',
    this.successSemanticLabel = 'PIN changed successfully',
    this.semanticLabel,
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
        _PinStep.current => widget.currentPinTitle,
        _PinStep.newPin => widget.newPinTitle,
        _PinStep.confirm => widget.confirmPinTitle,
      };

  String get _stepSubtitle => switch (_step) {
        _PinStep.current => widget.currentPinSubtitle,
        _PinStep.newPin =>
          widget.newPinSubtitle ?? 'Choose a new ${widget.pinLength}-digit PIN',
        _PinStep.confirm => widget.confirmPinSubtitle,
      };

  String get _stepIndicatorLabel => switch (_step) {
        _PinStep.current => widget.currentPinStepLabel,
        _PinStep.newPin => widget.newPinStepLabel,
        _PinStep.confirm => widget.confirmPinStepLabel,
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
        _errorMessage = widget.mismatchErrorText;
        _confirmPin = '';
      });
      unawaited(HapticFeedback.heavyImpact());
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
        // Incorrect current PIN: return to step 0.
        setState(() {
          _isSubmitting = false;
          _step = _PinStep.current;
          _currentPin = '';
          _newPin = '';
          _confirmPin = '';
          _showError = true;
          _errorMessage = widget.incorrectPinErrorText;
        });
        unawaited(HapticFeedback.heavyImpact());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showError = true;
        _errorMessage = widget.genericErrorText;
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
    final resolvedForeground = widget.foregroundColor ?? bankTheme.onSurface;
    final resolvedAccent = widget.accentColor ?? bankTheme.primary;
    final resolvedDuration =
        widget.animationDuration ?? BankTokens.durationBase;
    final resolvedCurve = widget.animationCurve ?? Curves.linear;

    final Widget body;
    if (_success) {
      body = _SuccessView(
        bankTheme: bankTheme,
        icon: widget.successIcon,
        color: widget.successColor ?? BankTokens.success,
        foregroundColor: resolvedForeground,
        title: widget.successTitle,
        message: widget.successMessage,
        semanticLabel: widget.successSemanticLabel,
        titleStyle: widget.titleStyle,
        messageStyle: widget.subtitleStyle,
      );
    } else {
      body = Semantics(
        label: widget.semanticLabel ?? _stepTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Navigation bar ───────────────────────────────────────────────
            _PinStepNavBar(
              onBack: _goBack,
              bankTheme: bankTheme,
              backIcon: widget.backIcon,
              backSemanticLabel: widget.backSemanticLabel,
              iconColor: resolvedForeground,
              stepLabel: _stepIndicatorLabel,
              stepLabelStyle: widget.stepLabelStyle,
            ),

            const SizedBox(height: BankTokens.space8),

            // ── Title & subtitle ─────────────────────────────────────────────
            Text(
              _stepTitle,
              style: BankTokens.headlineMedium
                  .copyWith(color: resolvedForeground)
                  .merge(widget.titleStyle),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BankTokens.space1),

            Text(
              _stepSubtitle,
              style: BankTokens.bodyMedium
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(widget.subtitleStyle),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BankTokens.space8),

            // ── PIN dots ─────────────────────────────────────────────────────
            BankPinDots(
              length: widget.pinLength,
              filled: _activePin.length,
              error: _showError,
            ),

            // ── Error message ────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: resolvedDuration,
              switchInCurve: resolvedCurve,
              switchOutCurve: resolvedCurve,
              child: _showError && _errorMessage.isNotEmpty
                  ? Padding(
                      key: ValueKey(_errorMessage),
                      padding: const EdgeInsets.only(top: BankTokens.space3),
                      child: Text(
                        _errorMessage,
                        style: BankTokens.bodySmall
                            .copyWith(color: BankTokens.danger)
                            .merge(widget.errorTextStyle),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('no-error'),
                      height: BankTokens.space6,
                    ),
            ),

            const SizedBox(height: BankTokens.space6),

            // ── Keypad ───────────────────────────────────────────────────────
            BankPinKeypad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              enabled: !_isSubmitting,
            ),

            // ── Loading indicator ────────────────────────────────────────────
            if (_isSubmitting) ...[
              const SizedBox(height: BankTokens.space4),
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: resolvedAccent,
                ),
              ),
            ],

            const SizedBox(height: BankTokens.space6),
          ],
        ),
      );
    }

    if (widget.padding == null) return body;
    return Padding(padding: widget.padding!, child: body);
  }
}

// ---------------------------------------------------------------------------
// _PinStepNavBar
// ---------------------------------------------------------------------------

/// Step navigation bar with a back arrow and a step indicator.
class _PinStepNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final BankThemeData bankTheme;
  final IconData backIcon;
  final String backSemanticLabel;
  final Color iconColor;
  final String stepLabel;
  final TextStyle? stepLabelStyle;

  const _PinStepNavBar({
    required this.onBack,
    required this.bankTheme,
    required this.backIcon,
    required this.backSemanticLabel,
    required this.iconColor,
    required this.stepLabel,
    this.stepLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button: min 44×44
        Semantics(
          button: true,
          label: backSemanticLabel,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            child: SizedBox(
              width: BankTokens.minTapTarget,
              height: BankTokens.minTapTarget,
              child: Center(
                child: Icon(
                  backIcon,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          stepLabel,
          style: BankTokens.labelMedium
              .copyWith(color: bankTheme.onSurfaceVariant)
              .merge(stepLabelStyle),
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
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final String title;
  final String message;
  final String semanticLabel;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  const _SuccessView({
    required this.bankTheme,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.title,
    required this.message,
    required this.semanticLabel,
    this.titleStyle,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BankTokens.space12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space5),
          Text(
            title,
            style: BankTokens.headlineMedium
                .copyWith(color: foregroundColor)
                .merge(titleStyle),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            message,
            style: BankTokens.bodyMedium
                .copyWith(color: bankTheme.onSurfaceVariant)
                .merge(messageStyle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BankTokens.space12),
        ],
      ),
    );
  }
}
