import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

// ---------------------------------------------------------------------------
// State enum
// ---------------------------------------------------------------------------

/// Describes the current liveness-detection state.
enum BankLivenessState {
  idle,
  detecting,
  success,
  retry,
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Face-guide overlay for liveness detection.
///
/// Stacks a dark overlay with an oval cutout over [cameraChild], then draws:
/// - An oval face guide (the user's face should fill the oval).
/// - A progress ring around the oval animated to [detectionProgress].
/// - An instruction label below the oval.
/// - A retry button when [state] is [BankLivenessState.retry] and [onRetry]
///   is provided.
class BankLivenessCheckOverlay extends StatefulWidget {
  /// The detected liveness state — drives ring colour and feedback icons.
  final BankLivenessState state;

  /// The host app's camera widget. It sits behind the overlay in a [Stack].
  final Widget cameraChild;

  /// Current user instruction, e.g. `'Smile'`. Auto-generated when `null`.
  final String? instruction;

  /// Completion progress of the liveness check. Range: `0.0` – `1.0`.
  final double detectionProgress;

  /// Called when the user taps the retry button while
  /// [state] == [BankLivenessState.retry].
  final VoidCallback? onRetry;

  const BankLivenessCheckOverlay({
    super.key,
    required this.state,
    required this.cameraChild,
    this.instruction,
    this.detectionProgress = 0,
    this.onRetry,
  });

  @override
  State<BankLivenessCheckOverlay> createState() =>
      _BankLivenessCheckOverlayState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _BankLivenessCheckOverlayState extends State<BankLivenessCheckOverlay>
    with TickerProviderStateMixin {
  // Animates the progress arc value.
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Animates success checkmark opacity.
  late final AnimationController _successController;
  late final Animation<double> _successOpacity;

  // Loops for the detecting ring pulse effect.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: BankTokens.durationSlow,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.detectionProgress.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: BankTokens.curveEmphasized,
      ),
    );
    _progressController.forward();

    _successController = AnimationController(
      vsync: this,
      duration: BankTokens.durationBase,
    );
    _successOpacity = CurvedAnimation(
      parent: _successController,
      curve: BankTokens.curveStandard,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: BankTokens.curveStandard),
    );

    if (widget.state == BankLivenessState.success) {
      _successController.forward();
    }
  }

  @override
  void didUpdateWidget(BankLivenessCheckOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate progress arc changes.
    if (oldWidget.detectionProgress != widget.detectionProgress) {
      final prev = _progressAnimation.value;
      final next = widget.detectionProgress.clamp(0.0, 1.0);
      _progressAnimation = Tween<double>(begin: prev, end: next).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: BankTokens.curveEmphasized,
        ),
      );
      _progressController.forward(from: 0);
    }

    // Trigger success opacity.
    if (widget.state == BankLivenessState.success &&
        oldWidget.state != BankLivenessState.success) {
      _successController.forward();
    } else if (widget.state != BankLivenessState.success) {
      _successController.reverse();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Default instruction text
  // ---------------------------------------------------------------------------

  String get _effectiveInstruction {
    if (widget.instruction != null) return widget.instruction!;
    return switch (widget.state) {
      BankLivenessState.idle => 'Position your face in the oval',
      BankLivenessState.detecting => 'Look straight at the camera',
      BankLivenessState.success => 'Liveness verified',
      BankLivenessState.retry => 'Could not verify — please try again',
    };
  }

  // ---------------------------------------------------------------------------
  // Ring colour per state
  // ---------------------------------------------------------------------------

  Color _ringColor(BankThemeData bankTheme) => switch (widget.state) {
        BankLivenessState.idle => bankTheme.outline,
        BankLivenessState.detecting => bankTheme.primary,
        BankLivenessState.success => BankTokens.success,
        BankLivenessState.retry => BankTokens.danger,
      };

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final ringColor = _ringColor(bankTheme);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed.
        widget.cameraChild,

        // Oval overlay + ring.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _progressController,
              _successController,
              _pulseController,
            ]),
            builder: (context, _) {
              return CustomPaint(
                painter: _LivenessOverlayPainter(
                  progress: _progressAnimation.value,
                  ringColor: ringColor,
                  isDetecting: widget.state == BankLivenessState.detecting,
                  pulseOpacity: _pulseOpacity.value,
                  showFullRing: widget.state == BankLivenessState.success ||
                      widget.state == BankLivenessState.retry,
                ),
              );
            },
          ),
        ),

        // Success checkmark overlay.
        AnimatedBuilder(
          animation: _successOpacity,
          builder: (context, _) {
            return Opacity(
              opacity: _successOpacity.value,
              child: Center(
                child: widget.state == BankLivenessState.success
                    ? const Icon(
                        Icons.check_circle_outline,
                        color: BankTokens.success,
                        size: 64,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),

        // Instruction text + retry button at the bottom.
        Positioned(
          left: 0,
          right: 0,
          bottom: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space8,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _effectiveInstruction,
                    style: BankTokens.bodyMedium.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (widget.state == BankLivenessState.retry &&
                  widget.onRetry != null) ...[
                const SizedBox(height: BankTokens.space5),
                FilledButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      BankTokens.minTapTarget * 2,
                      BankTokens.minTapTarget,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _LivenessOverlayPainter extends CustomPainter {
  const _LivenessOverlayPainter({
    required this.progress,
    required this.ringColor,
    required this.isDetecting,
    required this.pulseOpacity,
    required this.showFullRing,
  });

  final double progress;
  final Color ringColor;
  final bool isDetecting;
  final double pulseOpacity;
  final bool showFullRing;

  static const double _overlayOpacity = 0.55;
  static const double _ringStroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Oval proportions: 65% wide, 75% tall, centred, offset slightly upward.
    final ovalW = size.width * 0.65;
    final ovalH = size.height * 0.75;
    final ovalLeft = (size.width - ovalW) / 2;
    final ovalTop = (size.height - ovalH) / 2 - size.height * 0.04;
    final ovalRect = Rect.fromLTWH(ovalLeft, ovalTop, ovalW, ovalH);

    // ── Dark overlay with oval cutout ──
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(_overlayOpacity);

    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(ovalRect);

    final combined = Path.combine(
      PathOperation.difference,
      bgPath,
      ovalPath,
    );
    canvas.drawPath(combined, overlayPaint);

    // ── Progress ring around the oval ──
    final ringPaint = Paint()
      ..color = isDetecting
          ? ringColor.withOpacity(pulseOpacity)
          : ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round;

    // Background track.
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke;

    // Inflate the oval rect slightly so the ring sits outside the face guide.
    final ringRect = ovalRect.inflate(_ringStroke + 2);

    canvas.drawOval(ringRect, trackPaint);

    final sweepAngle = showFullRing
        ? 2 * math.pi
        : 2 * math.pi * progress.clamp(0.0, 1.0);

    if (sweepAngle > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2, // start at top
        sweepAngle,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LivenessOverlayPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.isDetecting != isDetecting ||
      old.pulseOpacity != pulseOpacity ||
      old.showFullRing != showFullRing;
}
