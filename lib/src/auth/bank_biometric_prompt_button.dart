import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankBiometricType
// ---------------------------------------------------------------------------

/// The type of biometric authenticator to present in
/// [BankBiometricPromptButton].
enum BankBiometricType {
  /// Fingerprint sensor (shows a fingerprint icon).
  fingerprint,

  /// Face-recognition (shows a face-scan icon).
  face,
}

// ---------------------------------------------------------------------------
// _ButtonState
// ---------------------------------------------------------------------------

enum _ButtonState { idle, loading, success, error }

// ---------------------------------------------------------------------------
// BankBiometricPromptButton
// ---------------------------------------------------------------------------

/// A tappable button that triggers an injected biometric authentication
/// callback and reflects its outcome visually.
///
/// This widget never calls any platform API directly. The host app provides
/// [onAuthenticate], which wraps the platform-specific authentication logic
/// (e.g. `local_auth`). A return value of `true` signals success; `false`
/// signals a user-facing failure.
///
/// State machine:
/// - **idle**: shows [type]-appropriate icon above [label].
/// - **loading**: replaces icon with a [CircularProgressIndicator].
/// - **success**: briefly shows a green checkmark (750 ms) then calls
///   [onSuccess] and returns to idle.
/// - **error**: calls [onError] with `'Authentication failed'` and returns
///   to idle after 500 ms.
///
/// ```dart
/// BankBiometricPromptButton(
///   onAuthenticate: () => LocalAuth.instance.authenticate(
///     localizedReason: 'Confirm your identity',
///   ),
///   onSuccess: () => Navigator.of(context).pushReplacement(dashboardRoute),
///   label: 'Log in with Face ID',
///   type: BankBiometricType.face,
/// )
/// ```
class BankBiometricPromptButton extends StatefulWidget {
  /// Called when the button is tapped. Must return `true` on success and
  /// `false` (or throw) on failure. Throwing is treated identically to
  /// returning `false`.
  final Future<bool> Function() onAuthenticate;

  /// Called after a successful authentication and a brief checkmark display.
  final VoidCallback? onSuccess;

  /// Called with an error message when [onAuthenticate] returns `false`.
  final ValueChanged<String>? onError;

  /// Button label displayed below the icon. Defaults to `'Use Biometrics'`.
  final String label;

  /// Determines the icon displayed. Defaults to
  /// [BankBiometricType.fingerprint].
  final BankBiometricType type;

  const BankBiometricPromptButton({
    required this.onAuthenticate,
    super.key,
    this.onSuccess,
    this.onError,
    this.label = 'Use Biometrics',
    this.type = BankBiometricType.fingerprint,
  });

  @override
  State<BankBiometricPromptButton> createState() =>
      _BankBiometricPromptButtonState();
}

class _BankBiometricPromptButtonState extends State<BankBiometricPromptButton>
    with SingleTickerProviderStateMixin {
  _ButtonState _state = _ButtonState.idle;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: BankTokens.durationFast,
      value: 1,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: BankTokens.curveStandard,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_state != _ButtonState.idle) return;

    // Press-down haptic via scale animation
    await _scaleController.forward();
    await _scaleController.reverse();

    if (!mounted) return;
    setState(() => _state = _ButtonState.loading);

    var success = false;
    try {
      success = await widget.onAuthenticate();
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      setState(() => _state = _ButtonState.success);
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() => _state = _ButtonState.idle);
      widget.onSuccess?.call();
    } else {
      setState(() => _state = _ButtonState.error);
      widget.onError?.call('Authentication failed');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _state = _ButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return Semantics(
      button: true,
      label: widget.label,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _state == _ButtonState.idle ? _handleTap : null,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: BankTokens.minTapTarget,
              minHeight: BankTokens.minTapTarget,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconArea(bankTheme),
                const SizedBox(height: BankTokens.space3),
                _buildLabel(bankTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconArea(BankThemeData bankTheme) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedSwitcher(
        duration: BankTokens.durationFast,
        switchInCurve: BankTokens.curveStandard,
        switchOutCurve: BankTokens.curveStandard,
        child: switch (_state) {
          _ButtonState.loading => CircularProgressIndicator(
              key: const ValueKey<String>('loading'),
              color: bankTheme.primary,
              strokeWidth: 2.5,
            ),
          _ButtonState.success => Icon(
              BankIcons.success,
              key: const ValueKey<String>('success'),
              size: 48,
              color: bankTheme.positiveBalance,
            ),
          _ButtonState.error => Icon(
              BankIcons.error,
              key: const ValueKey<String>('error'),
              size: 48,
              color: bankTheme.negativeBalance,
            ),
          _ButtonState.idle => Icon(
              _iconForType,
              key: const ValueKey<String>('idle'),
              size: 48,
              color: bankTheme.primary,
            ),
        },
      ),
    );
  }

  Widget _buildLabel(BankThemeData bankTheme) {
    return Text(
      widget.label,
      style: BankTokens.labelLarge.copyWith(
        color: bankTheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  IconData get _iconForType => switch (widget.type) {
        BankBiometricType.fingerprint => BankIcons.biometric,
        BankBiometricType.face => BankIcons.faceId,
      };
}
