import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Lightweight success micro-animation.
///
/// Plays a three-phase sequence:
///   1. A circle arc draws itself from 0 → 360° (progress 0 → 0.4).
///   2. A checkmark path draws itself inside the circle (progress 0.4 → 0.8).
///   3. A subtle scale-bounce finishes the animation (progress 0.8 → 1.0).
///
/// When [showConfetti] is `true`, twelve small coloured particles animate
/// outward from the centre after [onComplete] fires. No third-party confetti
/// package is used.
///
/// When [MediaQuery.disableAnimationsOf] is `true`, the widget skips directly
/// to the final static state and fires [onComplete] in the first frame.
///
/// ```dart
/// BankSuccessAnimation(
///   size: 96,
///   showConfetti: true,
///   onComplete: () => Navigator.pop(context),
///   label: Text('Payment sent!'),
/// )
/// ```
class BankSuccessAnimation extends StatefulWidget {
  /// Diameter of the circle and checkmark in logical pixels.
  final double size;

  /// Stroke colour. Defaults to [BankTokens.success].
  final Color? color;

  /// When `true`, twelve confetti particles burst outward after the main
  /// animation completes.
  final bool showConfetti;

  /// Called once the main animation (and confetti, if enabled) finishes.
  final VoidCallback? onComplete;

  /// Optional label widget placed below the animation.
  final Widget? label;

  const BankSuccessAnimation({
    super.key,
    this.size = 80,
    this.color,
    this.showConfetti = false,
    this.onComplete,
    this.label,
  }) : assert(size > 0, 'size must be positive');

  @override
  State<BankSuccessAnimation> createState() => _BankSuccessAnimationState();
}

class _BankSuccessAnimationState extends State<BankSuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _confettiController;

  // Main three-phase animation
  late final Animation<double> _circleProgress;
  late final Animation<double> _checkProgress;
  late final Animation<double> _bouncedScaleAnim;

  // Confetti state
  bool _showConfetti = false;
  static const int _confettiCount = 12;

  // Stable confetti colours and angles; computed once in initState.
  late final List<Color> _confettiColors;
  late final List<double> _confettiAngles;

  static const List<Color> _palette = [
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFFFF9500),
    Color(0xFFFF3B30),
    Color(0xFFAF52DE),
    Color(0xFF5AC8FA),
  ];

  @override
  void initState() {
    super.initState();

    _confettiColors = List.generate(
      _confettiCount,
      (i) => _palette[i % _palette.length],
    );
    _confettiAngles = List.generate(
      _confettiCount,
      (i) => (2 * math.pi / _confettiCount) * i,
    );

    _mainController = AnimationController(
      vsync: this,
      duration: BankTokens.durationXSlow,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: BankTokens.durationSlow,
    );

    // Phase 1: circle draws from 0 → 0.4 of total
    _circleProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: BankTokens.curveEmphasized),
      ),
    );

    // Phase 2: check draws from 0.4 → 0.8 of total
    _checkProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: BankTokens.curveStandard),
      ),
    );

    // Phase 3: scale bounce — 1.0 → 1.15 → 1.0 during progress 0.8 → 1.0.
    _bouncedScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0),
      ),
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (widget.showConfetti && mounted) {
          setState(() => _showConfetti = true);
          _confettiController.forward();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStartAnimation();
  }

  void _maybeStartAnimation() {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      // Jump to completed state immediately.
      _mainController.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete?.call();
      });
    } else {
      if (!_mainController.isAnimating && _mainController.value == 0) {
        _mainController.forward();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final Color strokeColor = widget.color ?? BankTokens.success;

    return Semantics(
      label: 'Success',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _confettiController]),
              builder: (context, _) {
                return SizedBox(
                  width: widget.size + 60,
                  height: widget.size + 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Confetti particles
                      if (_showConfetti)
                        ..._buildConfettiParticles(widget.size),
                      // Main animation
                      Transform.scale(
                        scale: _bouncedScaleAnim.value,
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _SuccessPainter(
                            circleProgress: _circleProgress.value,
                            checkProgress: _checkProgress.value,
                            color: strokeColor,
                            fillColor: strokeColor.withOpacity(0.12),
                            strokeWidth: math.max(2.0, widget.size * 0.04),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: BankTokens.space3),
            DefaultTextStyle(
              style: BankTokens.bodyMedium.copyWith(
                color: theme.onSurface,
              ),
              child: widget.label!,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildConfettiParticles(double size) {
    final double radius = (size / 2) + (30 * _confettiController.value);
    final double opacity =
        _confettiController.value < 0.7 ? 1.0 : (1.0 - _confettiController.value) / 0.3;

    return List.generate(_confettiCount, (i) {
      final double angle = _confettiAngles[i];
      final double dx = math.cos(angle) * radius;
      final double dy = math.sin(angle) * radius;

      return Positioned(
        left: (size + 60) / 2 + dx - 4,
        top: (size + 60) / 2 + dy - 4,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _confettiColors[i],
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

/// Draws the circle arc and checkmark path for [BankSuccessAnimation].
class _SuccessPainter extends CustomPainter {
  const _SuccessPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
  });

  final double circleProgress;
  final double checkProgress;
  final Color color;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset center = Offset(r, r);
    final Rect circleRect = Rect.fromCircle(center: center, radius: r - strokeWidth / 2);

    // Background fill when circle is complete enough.
    if (circleProgress >= 1.0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r - strokeWidth / 2, fillPaint);
    }

    // Circle arc
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * circleProgress;
    // Start at top (−π/2) and sweep clockwise.
    canvas.drawArc(
      circleRect,
      -math.pi / 2,
      sweepAngle,
      false,
      circlePaint,
    );

    // Checkmark path — only draw once circle is complete.
    if (checkProgress <= 0 || circleProgress < 0.95) return;

    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Checkmark anchor points (relative to centre).
    final double scale = r * 0.55;
    final Offset p1 = center + Offset(-scale * 0.55, 0);
    final Offset p2 = center + Offset(-scale * 0.1, scale * 0.45);
    final Offset p3 = center + Offset(scale * 0.6, -scale * 0.45);

    // Total path length split: 40 % for first stroke, 60 % for second.
    const double split = 0.4;

    final Path checkPath = Path();

    if (checkProgress <= split) {
      final double t = checkProgress / split;
      final Offset mid = Offset.lerp(p1, p2, t)!;
      checkPath.moveTo(p1.dx, p1.dy);
      checkPath.lineTo(mid.dx, mid.dy);
    } else {
      final double t = (checkProgress - split) / (1 - split);
      final Offset mid = Offset.lerp(p2, p3, t)!;
      checkPath.moveTo(p1.dx, p1.dy);
      checkPath.lineTo(p2.dx, p2.dy);
      checkPath.lineTo(mid.dx, mid.dy);
    }

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.circleProgress != circleProgress ||
      old.checkProgress != checkProgress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
