import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Framing state enum
// ---------------------------------------------------------------------------

/// Describes the current document-alignment state detected by the host app.
enum BankDocumentFramingState {
  idle, // no document detected
  detecting, // partially in frame
  aligned, // correctly aligned
  tooClose,
  tooFar,
  badLighting,
  blurry,
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Camera frame guide for document capture.
///
/// Camera-plugin agnostic — overlays on top of whatever camera widget the
/// host app provides via [cameraChild]. The overlay draws:
/// - A dark semi-transparent background with a rectangular document cutout.
/// - L-shaped corner guides that animate between idle and aligned colours.
/// - An optional rule-of-thirds grid inside the cutout ([showGrid]).
/// - A status pill at the bottom edge of the cutout.
/// - A capture button when [framingState] is [BankDocumentFramingState.aligned].
class BankDocumentCaptureOverlay extends StatelessWidget {
  /// The detected framing state — drives corner colour, status message, and
  /// whether the capture button is shown.
  final BankDocumentFramingState framingState;

  /// The host app's camera widget. It sits behind the overlay in a [Stack].
  final Widget cameraChild;

  /// Override the auto-generated status message. If `null`, a default string
  /// is derived from [framingState].
  final String? statusMessage;

  /// Callback shown as a capture button when
  /// [framingState] == [BankDocumentFramingState.aligned]. `null` hides the
  /// button even when aligned.
  final VoidCallback? onCapture;

  /// When `true`, a rule-of-thirds grid is drawn inside the cutout using thin
  /// dashed lines.
  final bool showGrid;

  const BankDocumentCaptureOverlay({
    super.key,
    required this.framingState,
    required this.cameraChild,
    this.statusMessage,
    this.onCapture,
    this.showGrid = false,
  });

  // ---------------------------------------------------------------------------
  // Default status messages
  // ---------------------------------------------------------------------------

  static String _defaultMessage(BankDocumentFramingState state) =>
      switch (state) {
        BankDocumentFramingState.idle => 'Position your document in the frame',
        BankDocumentFramingState.detecting => 'Keep the document in frame',
        BankDocumentFramingState.aligned => 'Hold still…',
        BankDocumentFramingState.tooClose => 'Move further away',
        BankDocumentFramingState.tooFar => 'Move closer',
        BankDocumentFramingState.badLighting => 'Improve lighting conditions',
        BankDocumentFramingState.blurry => 'Hold the camera steady',
      };

  // ---------------------------------------------------------------------------
  // Status pill colour + icon
  // ---------------------------------------------------------------------------

  static Color _pillColor(BankDocumentFramingState state) => switch (state) {
        BankDocumentFramingState.aligned => const Color(0xFF34C759),
        BankDocumentFramingState.badLighting => const Color(0xFFFF9500),
        BankDocumentFramingState.blurry => const Color(0xFFFF9500),
        _ => Colors.white,
      };

  static IconData _pillIcon(BankDocumentFramingState state) => switch (state) {
        BankDocumentFramingState.aligned => Icons.check_circle_outline,
        BankDocumentFramingState.badLighting => Icons.wb_sunny_outlined,
        BankDocumentFramingState.blurry => Icons.blur_on_outlined,
        _ => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final message = statusMessage ?? _defaultMessage(framingState);
    final isAligned = framingState == BankDocumentFramingState.aligned;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed sits at the back.
        cameraChild,

        // Overlay with cutout + corner guides.
        RepaintBoundary(
          child: _DocumentOverlayPainterWidget(
            framingState: framingState,
            bankTheme: bankTheme,
            showGrid: showGrid,
          ),
        ),

        // Status pill + capture button anchored near the bottom.
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capture button — only when aligned and callback provided.
              if (isAligned && onCapture != null) ...[
                Semantics(
                  button: true,
                  label: 'Capture document',
                  child: GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: bankTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: bankTheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: BankTokens.space4),
              ],

              // Status pill.
              _StatusPill(
                message: message,
                color: _pillColor(framingState),
                icon: _pillIcon(framingState),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay painter widget
// ---------------------------------------------------------------------------

class _DocumentOverlayPainterWidget extends StatefulWidget {
  const _DocumentOverlayPainterWidget({
    required this.framingState,
    required this.bankTheme,
    required this.showGrid,
  });

  final BankDocumentFramingState framingState;
  final BankThemeData bankTheme;
  final bool showGrid;

  @override
  State<_DocumentOverlayPainterWidget> createState() =>
      _DocumentOverlayPainterWidgetState();
}

class _DocumentOverlayPainterWidgetState
    extends State<_DocumentOverlayPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _cornerColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BankTokens.durationSlow,
    );
    _updateColorTween();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_DocumentOverlayPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.framingState != widget.framingState ||
        oldWidget.bankTheme != widget.bankTheme) {
      _updateColorTween();
      _syncAnimation();
    }
  }

  void _updateColorTween() {
    final targetColor =
        widget.framingState == BankDocumentFramingState.aligned
            ? widget.bankTheme.primary
            : widget.bankTheme.outline;

    _cornerColor = ColorTween(
      begin: _cornerColor.value ?? widget.bankTheme.outline,
      end: targetColor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: BankTokens.curveStandard),
    );
  }

  void _syncAnimation() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _DocumentOverlayPainter(
            cornerColor: _cornerColor.value ?? widget.bankTheme.outline,
            showGrid: widget.showGrid,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _DocumentOverlayPainter extends CustomPainter {
  const _DocumentOverlayPainter({
    required this.cornerColor,
    required this.showGrid,
  });

  final Color cornerColor;
  final bool showGrid;

  static const double _widthFraction = 0.85;
  static const double _heightFraction = 0.55;
  static const double _cornerLength = 24.0;
  static const double _cornerStroke = 4.0;
  static const double _overlayOpacity = 0.6;

  Rect _cutoutRect(Size size) {
    final cutW = size.width * _widthFraction;
    final cutH = size.height * _heightFraction;
    final left = (size.width - cutW) / 2;
    final top = (size.height - cutH) / 2;
    return Rect.fromLTWH(left, top, cutW, cutH);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = _cutoutRect(size);

    // ── Dark overlay with rectangular cutout ──
    final overlayPaint = Paint()..color = Colors.black.withOpacity(_overlayOpacity);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(4)));

    final combined = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );
    canvas.drawPath(combined, overlayPaint);

    // ── Corner guides ──
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, cutout, cornerPaint);

    // ── Optional rule-of-thirds grid ──
    if (showGrid) {
      _drawGrid(canvas, cutout);
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final cl = _cornerLength;

    // Top-left
    canvas.drawLine(Offset(l, t + cl), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + cl, t), paint);

    // Top-right
    canvas.drawLine(Offset(r - cl, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cl), paint);

    // Bottom-left
    canvas.drawLine(Offset(l, b - cl), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + cl, b), paint);

    // Bottom-right
    canvas.drawLine(Offset(r - cl, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cl), paint);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Vertical thirds.
    final thirdW = rect.width / 3;
    for (int i = 1; i <= 2; i++) {
      final x = rect.left + thirdW * i;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }

    // Horizontal thirds.
    final thirdH = rect.height / 3;
    for (int i = 1; i <= 2; i++) {
      final y = rect.top + thirdH * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_DocumentOverlayPainter old) =>
      old.cornerColor != cornerColor || old.showGrid != showGrid;
}

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textColor =
        color == Colors.white ? const Color(0xFF1C1C1E) : Colors.white;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: BankTokens.space6),
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(color == Colors.white ? 0.9 : 1.0),
          borderRadius:
              const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                message,
                style: BankTokens.labelMedium.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
