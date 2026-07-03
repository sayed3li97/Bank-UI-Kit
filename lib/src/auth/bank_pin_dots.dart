import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

// ---------------------------------------------------------------------------
// Shake animation helper
// ---------------------------------------------------------------------------

/// Internal widget that shakes its [child] horizontally when [shake] is true.
///
/// Uses a [SingleTickerProviderStateMixin]-based [AnimationController] that
/// plays a ±4 px horizontal oscillation over 300 ms (3 cycles). The animation
/// re-triggers on every transition from `shake == false` to `shake == true`.
class _ShakeWidget extends StatefulWidget {
  const _ShakeWidget({
    required this.shake,
    required this.child,
  });

  final bool shake;
  final Widget child;

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Oscillates ±4 logical pixels along the x-axis.
    // SlideTransition expects a fraction of the child's size, so we use a
    // FractionalTranslation override via TweenSequence on a raw offset tween.
    _offsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.04, 0),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: const Offset(-0.04, 0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.04, 0),
          end: const Offset(0.04, 0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// BankPinDots
// ---------------------------------------------------------------------------

/// Displays filled/empty dot indicators for a PIN entry sequence.
///
/// Works alongside [BankPinKeypad] or any other PIN input mechanism. The
/// [filled] count drives the visual state; the host app is responsible for
/// tracking the actual PIN digits.
///
/// When [error] flips from `false` to `true`, the dot row plays a short
/// horizontal shake animation to signal an incorrect PIN.
///
/// ```dart
/// BankPinDots(
///   length: 6,
///   filled: _pin.length,
///   error: _showError,
/// )
/// ```
class BankPinDots extends StatelessWidget {
  /// Total expected PIN length (e.g. 6).
  final int length;

  /// Number of digits entered so far. Clamped internally to [0, length].
  final int filled;

  /// When `true`, dots are drawn as solid circles; when `false`, this field
  /// is reserved for future use: in practice dots are always shown obscured.
  final bool obscure;

  /// When flipped to `true`, the dot row plays a horizontal shake animation
  /// to indicate an incorrect PIN entry.
  final bool error;

  /// Override colour for filled dots. Defaults to [BankThemeData.primary].
  final Color? filledColor;

  /// Override colour for empty dots. Defaults to [BankThemeData.outline].
  final Color? emptyColor;

  /// Diameter of each dot in logical pixels. Defaults to `12`.
  final double dotSize;

  const BankPinDots({
    required this.filled,
    super.key,
    this.length = 6,
    this.obscure = true,
    this.error = false,
    this.filledColor,
    this.emptyColor,
    this.dotSize = 12,
  }) : assert(length > 0, 'length must be greater than 0');

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final clampedFilled = filled.clamp(0, length);

    final resolvedFilled = filledColor ?? bankTheme.primary;
    final resolvedEmpty = emptyColor ?? bankTheme.outline;

    final Widget dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (index) {
        final isFilled = index < clampedFilled;
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 0 : BankTokens.space2,
          ),
          child: _PinDot(
            filled: isFilled,
            size: dotSize,
            filledColor: resolvedFilled,
            emptyColor: resolvedEmpty,
          ),
        );
      }),
    );

    return Semantics(
      label: '$clampedFilled of $length digits entered',
      excludeSemantics: true,
      child: _ShakeWidget(
        shake: error,
        child: dots,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual dot
// ---------------------------------------------------------------------------

class _PinDot extends StatelessWidget {
  const _PinDot({
    required this.filled,
    required this.size,
    required this.filledColor,
    required this.emptyColor,
  });

  final bool filled;
  final double size;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BankTokens.durationFast,
      curve: BankTokens.curveStandard,
      width: size,
      height: size,
      decoration: filled
          ? BoxDecoration(
              color: filledColor,
              shape: BoxShape.circle,
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: emptyColor,
                width: 1.5,
              ),
            ),
    );
  }
}
