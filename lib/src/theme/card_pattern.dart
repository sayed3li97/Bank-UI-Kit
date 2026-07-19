import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import 'bank_theme_data.dart';

/// Generative background patterns for card faces.
///
/// Each preset can stamp a distinct, brand-owned texture onto payment-card
/// surfaces via [BankThemeData.cardPattern] instead of every brand shipping
/// the same flat gradient. Patterns are painted by [BankCardPatternPainter]
/// at very low alpha so they read as texture, never as content.
enum BankCardPattern {
  /// No pattern: the card face is the plain surface / gradient.
  none,

  /// Two overlapping families of soft sine-wave lines (Voltage).
  mesh,

  /// Islamic-style eight-point star lattice (Heritage).
  lattice,

  /// Three large concentric arcs anchored at a corner (Bloom).
  arcs,

  /// A fine dot grid.
  grid,
}

/// Paints a [BankCardPattern] across the full card face.
///
/// The geometry is deterministic (no randomness), scales with the painted
/// [Size], and is cheap enough to run on every frame of a card carousel.
/// The [color] is used exactly as passed — callers supply a low-alpha ink
/// (typically `onPrimary` at 6–10 % opacity) so the pattern stays subordinate
/// to the card content:
///
/// ```dart
/// CustomPaint(
///   painter: BankCardPatternPainter(
///     pattern: theme.cardPattern,
///     color: theme.cardPatternColor ?? theme.onPrimary.withValues(alpha: .08),
///   ),
/// )
/// ```
class BankCardPatternPainter extends CustomPainter {
  const BankCardPatternPainter({
    required this.pattern,
    required this.color,
  });

  /// Which generative pattern to draw. [BankCardPattern.none] paints nothing.
  final BankCardPattern pattern;

  /// The stroke / dot colour, used as passed (callers pre-apply alpha).
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == BankCardPattern.none || size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (pattern) {
      case BankCardPattern.none:
        break;
      case BankCardPattern.mesh:
        _paintMesh(canvas, size);
      case BankCardPattern.lattice:
        _paintLattice(canvas, size);
      case BankCardPattern.arcs:
        _paintArcs(canvas, size);
      case BankCardPattern.grid:
        _paintGrid(canvas, size);
    }
    canvas.restore();
  }

  /// Thin stroke paint whose width scales gently with the card size.
  Paint _stroke(Size size) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, size.shortestSide / 220);

  /// Two overlapping families of soft sine waves, phase-shifted per line.
  void _paintMesh(Canvas canvas, Size size) {
    final paint = _stroke(size);
    const steps = 48;

    void waveFamily({
      required int lines,
      required double frequency,
      required double amplitude,
      required double phaseStep,
    }) {
      for (var i = 0; i < lines; i++) {
        final baseY = size.height * (i + 0.5) / lines;
        final phase = i * phaseStep;
        final path = Path();
        for (var s = 0; s <= steps; s++) {
          final x = size.width * s / steps;
          final y = baseY +
              amplitude * math.sin(frequency * 2 * math.pi * s / steps + phase);
          if (s == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, paint);
      }
    }

    waveFamily(
      lines: 6,
      frequency: 1.6,
      amplitude: size.height * 0.10,
      phaseStep: 0.9,
    );
    waveFamily(
      lines: 5,
      frequency: 2.4,
      amplitude: size.height * 0.06,
      phaseStep: -1.3,
    );
  }

  /// Eight-point star lattice: each tile overlays an axis-aligned square and
  /// the same square rotated 45°, the classic Islamic khatam construction.
  void _paintLattice(Canvas canvas, Size size) {
    final paint = _stroke(size);
    final cell = size.shortestSide / 3.2;
    final half = cell / 2;
    // Overshoot one cell on every edge so the lattice fills the corners.
    for (var cy = -half; cy <= size.height + cell; cy += cell) {
      for (var cx = -half; cx <= size.width + cell; cx += cell) {
        final center = Offset(cx + half, cy + half);
        // Axis-aligned square.
        canvas.drawRect(
          Rect.fromCenter(center: center, width: cell, height: cell),
          paint,
        );
        // The same square rotated 45° (drawn as a diamond path).
        final r = half * math.sqrt2;
        final diamond = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
  }

  /// Three large concentric circles anchored at the bottom-right corner;
  /// the clip crops them into corner arcs.
  void _paintArcs(Canvas canvas, Size size) {
    final paint = _stroke(size)
      ..strokeWidth = math.max(1, size.shortestSide / 160);
    final anchor = Offset(size.width, size.height);
    final base = size.longestSide;
    for (final factor in const [0.42, 0.66, 0.90]) {
      canvas.drawCircle(anchor, base * factor, paint);
    }
  }

  /// A fine dot grid on a square cadence.
  void _paintGrid(Canvas canvas, Size size) {
    final spacing = size.shortestSide / 12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.5, size.shortestSide / 110)
      ..strokeCap = StrokeCap.round;
    final points = <Offset>[
      for (var y = spacing / 2; y < size.height; y += spacing)
        for (var x = spacing / 2; x < size.width; x += spacing) Offset(x, y),
    ];
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(BankCardPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}
