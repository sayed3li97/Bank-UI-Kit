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

  /// Overrides the idle glyph. When null, [BankBiometricType.fingerprint]
  /// uses [BankIcons.biometric] and [BankBiometricType.face] draws a
  /// built-in Face-ID-style glyph (corner brackets, eyes, and nose)
  /// stroked in the accent colour.
  final IconData? icon;

  /// Overrides the success glyph. Defaults to [BankIcons.success].
  final IconData? successIcon;

  /// Overrides the error glyph. Defaults to [BankIcons.error].
  final IconData? errorIcon;

  /// Overrides the glyph size. Defaults to `48`.
  final double? iconSize;

  /// Overrides the idle icon and spinner colour. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the success icon colour. Defaults to
  /// [BankThemeData.positiveBalance].
  final Color? successColor;

  /// Overrides the error icon colour. Defaults to
  /// [BankThemeData.negativeBalance].
  final Color? errorColor;

  /// Merged over the computed label style ([BankTokens.labelLarge] in
  /// [BankThemeData.onSurface]).
  final TextStyle? labelStyle;

  /// Overrides the semantics label. Defaults to [label].
  final String? semanticLabel;

  /// Message passed to [onError] on failure. Defaults to
  /// `'Authentication failed'`.
  final String errorMessage;

  /// Overrides the press-scale and icon-switch duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the press-scale and icon-switch curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  const BankBiometricPromptButton({
    required this.onAuthenticate,
    super.key,
    this.onSuccess,
    this.onError,
    this.label = 'Use Biometrics',
    this.type = BankBiometricType.fingerprint,
    this.icon,
    this.successIcon,
    this.errorIcon,
    this.iconSize,
    this.accentColor,
    this.successColor,
    this.errorColor,
    this.labelStyle,
    this.semanticLabel,
    this.errorMessage = 'Authentication failed',
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<BankBiometricPromptButton> createState() =>
      _BankBiometricPromptButtonState();
}

class _BankBiometricPromptButtonState extends State<BankBiometricPromptButton>
    with SingleTickerProviderStateMixin {
  _ButtonState _state = _ButtonState.idle;

  late final AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  Duration get _resolvedDuration =>
      widget.animationDuration ?? BankTokens.durationFast;

  Curve get _resolvedCurve => widget.animationCurve ?? BankTokens.curveStandard;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: _resolvedDuration,
      value: 1,
    );
    _scaleAnimation = _buildScaleAnimation();
  }

  Animation<double> _buildScaleAnimation() {
    return Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: _resolvedCurve,
      ),
    );
  }

  @override
  void didUpdateWidget(BankBiometricPromptButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _scaleController.duration = _resolvedDuration;
    }
    if (widget.animationCurve != oldWidget.animationCurve) {
      _scaleAnimation = _buildScaleAnimation();
    }
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
      widget.onError?.call(widget.errorMessage);
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
      label: widget.semanticLabel ?? widget.label,
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
    final resolvedAccent = widget.accentColor ?? bankTheme.primary;
    final resolvedIconSize = widget.iconSize ?? 48;

    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedSwitcher(
        duration: _resolvedDuration,
        switchInCurve: _resolvedCurve,
        switchOutCurve: _resolvedCurve,
        child: switch (_state) {
          _ButtonState.loading => CircularProgressIndicator(
              key: const ValueKey<String>('loading'),
              color: resolvedAccent,
              strokeWidth: 2.5,
            ),
          _ButtonState.success => Icon(
              widget.successIcon ?? BankIcons.success,
              key: const ValueKey<String>('success'),
              size: resolvedIconSize,
              color: widget.successColor ?? bankTheme.positiveBalance,
            ),
          _ButtonState.error => Icon(
              widget.errorIcon ?? BankIcons.error,
              key: const ValueKey<String>('error'),
              size: resolvedIconSize,
              color: widget.errorColor ?? bankTheme.negativeBalance,
            ),
          _ButtonState.idle => _buildIdleGlyph(
              resolvedAccent,
              resolvedIconSize,
            ),
        },
      ),
    );
  }

  /// Idle glyph: the caller's [BankBiometricPromptButton.icon] override, the
  /// fingerprint icon, or (for [BankBiometricType.face]) a vector Face-ID
  /// glyph drawn in the accent colour so it matches the platform styling
  /// without shipping raster art.
  Widget _buildIdleGlyph(Color accent, double size) {
    if (widget.icon == null && widget.type == BankBiometricType.face) {
      return ExcludeSemantics(
        key: const ValueKey<String>('idle'),
        child: CustomPaint(
          size: Size.square(size),
          painter: _FaceIdGlyphPainter(color: accent),
        ),
      );
    }
    return Icon(
      widget.icon ?? _iconForType,
      key: const ValueKey<String>('idle'),
      size: size,
      color: accent,
    );
  }

  Widget _buildLabel(BankThemeData bankTheme) {
    return Text(
      widget.label,
      style: BankTokens.labelLarge
          .copyWith(color: bankTheme.onSurface)
          .merge(widget.labelStyle),
      textAlign: TextAlign.center,
    );
  }

  IconData get _iconForType => switch (widget.type) {
        BankBiometricType.fingerprint => BankIcons.biometric,
        BankBiometricType.face => BankIcons.faceId,
      };
}

// ---------------------------------------------------------------------------
// _FaceIdGlyphPainter
// ---------------------------------------------------------------------------

/// Paints a Face-ID-style glyph: four rounded-square corner brackets
/// framing two eye strokes and a nose stroke.
///
/// Purely geometric (no bundled art), stroked in a single [color] so it
/// follows the button's accent, and symmetric enough to read correctly in
/// both text directions.
class _FaceIdGlyphPainter extends CustomPainter {
  /// Stroke colour of every element of the glyph.
  final Color color;

  const _FaceIdGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Centre the square glyph inside whatever rect we were given.
    final origin = Offset(
      (size.width - s) / 2,
      (size.height - s) / 2,
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final inset = s * 0.06; // Keeps round caps inside the canvas.
    final side = s - inset * 2;
    final radius = side * 0.28; // Corner radius of the bracket arcs.
    final arm = side * 0.14; // Straight tail after each arc.

    final left = inset;
    final top = inset;
    final right = inset + side;
    final bottom = inset + side;

    // Four corner brackets: straight arm, 90-degree arc, straight arm.
    final brackets = Path()
      // Top-left.
      ..moveTo(left, top + radius + arm)
      ..lineTo(left, top + radius)
      ..arcToPoint(
        Offset(left + radius, top),
        radius: Radius.circular(radius),
      )
      ..lineTo(left + radius + arm, top)
      // Top-right.
      ..moveTo(right - radius - arm, top)
      ..lineTo(right - radius, top)
      ..arcToPoint(
        Offset(right, top + radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(right, top + radius + arm)
      // Bottom-right.
      ..moveTo(right, bottom - radius - arm)
      ..lineTo(right, bottom - radius)
      ..arcToPoint(
        Offset(right - radius, bottom),
        radius: Radius.circular(radius),
      )
      ..lineTo(right - radius - arm, bottom)
      // Bottom-left.
      ..moveTo(left + radius + arm, bottom)
      ..lineTo(left + radius, bottom)
      ..arcToPoint(
        Offset(left, bottom - radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(left, bottom - radius - arm);
    canvas.drawPath(brackets, paint);

    // Two eye strokes.
    final eyeTop = s * 0.36;
    final eyeBottom = s * 0.46;
    canvas
      ..drawLine(
        Offset(s * 0.34, eyeTop),
        Offset(s * 0.34, eyeBottom),
        paint,
      )
      ..drawLine(
        Offset(s * 0.66, eyeTop),
        Offset(s * 0.66, eyeBottom),
        paint,
      );

    // Nose: a vertical stroke that hooks gently at the base.
    final nose = Path()
      ..moveTo(s * 0.52, s * 0.38)
      ..lineTo(s * 0.52, s * 0.56)
      ..quadraticBezierTo(s * 0.52, s * 0.62, s * 0.45, s * 0.62);
    canvas.drawPath(nose, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FaceIdGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
