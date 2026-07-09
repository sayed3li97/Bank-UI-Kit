import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A palette for [MeridianCardArtwork].
class CardArtworkPalette {
  const CardArtworkPalette({
    required this.sky,
    required this.sun,
    required this.hillNear,
    required this.hillFar,
  });

  final List<Color> sky;
  final Color sun;
  final Color hillNear;
  final Color hillFar;

  static const sunset = CardArtworkPalette(
    sky: [Color(0xFFFF8A3D), Color(0xFFFF5E7E)],
    sun: Color(0xFFFFD37A),
    hillNear: Color(0xFF3D1D53),
    hillFar: Color(0xFF7A2E6A),
  );

  static const ocean = CardArtworkPalette(
    sky: [Color(0xFF2AA9E0), Color(0xFF1D6FD6)],
    sun: Color(0xFFBFF3FF),
    hillNear: Color(0xFF083B66),
    hillFar: Color(0xFF115E97),
  );

  static const forest = CardArtworkPalette(
    sky: [Color(0xFF23C48E), Color(0xFF0E8F72)],
    sun: Color(0xFFE9FFD8),
    hillNear: Color(0xFF0B3B2E),
    hillFar: Color(0xFF12664A),
  );
}

/// A self-contained, asset-free editorial "landscape" illustration used to
/// demonstrate [BankPaymentCard.artwork]. Painted with a [CustomPainter] so the
/// example bundles no images and the card art re-scales crisply.
class MeridianCardArtwork extends StatelessWidget {
  const MeridianCardArtwork({required this.palette, super.key});

  final CardArtworkPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.sky,
        ),
      ),
      child: CustomPaint(
          painter: _ArtworkPainter(palette), child: const SizedBox.expand()),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  _ArtworkPainter(this.palette);

  final CardArtworkPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sun / moon disc, upper area.
    final sunCenter = Offset(w * 0.72, h * 0.36);
    final sunR = h * 0.26;
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()..color = palette.sun.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      sunCenter,
      sunR * 1.5,
      Paint()..color = palette.sun.withValues(alpha: 0.18),
    );

    // Far rolling hill.
    final far = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(w * 0.25, h * 0.55, w * 0.55, h * 0.82, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        far, Paint()..color = palette.hillFar.withValues(alpha: 0.9));

    // Near rolling hill.
    final near = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.3, h * 0.72, w * 0.62, h * 0.98, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = palette.hillNear);

    // A few stars / dots in the sky.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final rnd = math.Random(7);
    for (var i = 0; i < 8; i++) {
      final dx = rnd.nextDouble() * w * 0.6;
      final dy = rnd.nextDouble() * h * 0.5;
      canvas.drawCircle(Offset(dx, dy), rnd.nextDouble() * 1.6 + 0.6, dot);
    }
  }

  @override
  bool shouldRepaint(_ArtworkPainter old) => old.palette != palette;
}
