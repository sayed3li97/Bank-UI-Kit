import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Payment networks a card can carry.
enum BankCardNetwork {
  /// Visa.
  visa,

  /// Mastercard.
  mastercard,

  /// American Express.
  amex,

  /// A generic / unbranded mark (no logo shown).
  generic,
}

/// Renders a payment-network mark (Visa, Mastercard, Amex) for a card face.
///
/// The marks are drawn **procedurally as vectors** — the kit bundles no image
/// assets, so this works offline. The Mastercard interlocking circles and the
/// Amex tile use the networks' brand colours by default (overridable via
/// [color] / [secondaryColor]); the Visa wordmark is monochrome and tints to
/// the ambient [BankThemeData.onPrimary] unless [color] is provided.
///
/// Integrators with licensed brand artwork (e.g. official SVGs via
/// `flutter_svg`) can inject it with [markBuilder] instead of the procedural
/// stand-ins.
///
/// ```dart
/// const BankNetworkBadge(network: BankCardNetwork.visa, height: 26)
/// ```
class BankNetworkBadge extends StatelessWidget {
  const BankNetworkBadge({
    required this.network,
    super.key,
    this.height = 26,
    this.color,
    this.secondaryColor,
    this.markBuilder,
    @Deprecated(
      'Marks are vector-drawn; use markBuilder for custom artwork.',
    )
    this.wordmarkStyle,
    this.semanticLabel,
  });

  /// The network to render.
  final BankCardNetwork network;

  /// Mark height in logical pixels. Marks scale their geometry from this.
  final double height;

  /// Ink for the Visa wordmark; defaults to the ambient
  /// [BankThemeData.onPrimary]. For Mastercard it also sets the left circle,
  /// so pass `null` there to keep the brand red (see `BankPaymentCard`, which
  /// does this automatically). Ignored for the Amex tile, whose knockout stays
  /// white on the brand blue.
  final Color? color;

  /// The Mastercard right (amber) circle, or the Amex tile fill. Defaults to
  /// the network brand colours ([BankTokens.networkMastercardAmber] /
  /// [BankTokens.networkAmexBlue]).
  final Color? secondaryColor;

  /// Escape hatch for licensed brand artwork: when non-null this builder
  /// replaces the procedural mark entirely. Receives the [BuildContext], the
  /// [network], and the resolved [height].
  final Widget Function(
    BuildContext context,
    BankCardNetwork network,
    double height,
  )? markBuilder;

  /// No longer used — marks are vector-drawn. Kept for compile compatibility.
  @Deprecated('Marks are vector-drawn; use markBuilder for custom artwork.')
  final TextStyle? wordmarkStyle;

  /// Overrides the computed semantics label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? _defaultSemanticLabel;
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: _mark(context)),
    );
  }

  String get _defaultSemanticLabel => switch (network) {
        BankCardNetwork.visa => 'Visa',
        BankCardNetwork.mastercard => 'Mastercard',
        BankCardNetwork.amex => 'American Express',
        BankCardNetwork.generic => 'Payment card',
      };

  // Note: the painted marks are wrapped in plain (non-directional) boxes and
  // CustomPaint is not mirrored by Directionality. That is intentional —
  // trademarks never flip in RTL locales.
  Widget _mark(BuildContext context) {
    final builder = markBuilder;
    if (builder != null) return builder(context, network, height);

    switch (network) {
      case BankCardNetwork.visa:
        return SizedBox(
          height: height,
          width: height * _VisaWordmarkPainter.aspect,
          child: CustomPaint(
            painter: _VisaWordmarkPainter(
              color: color ?? BankThemeData.of(context).onPrimary,
            ),
          ),
        );
      case BankCardNetwork.amex:
        return _AmexTile(
          height: height,
          fill: secondaryColor ?? BankTokens.networkAmexBlue,
        );
      case BankCardNetwork.mastercard:
        final left = color ?? BankTokens.networkMastercardRed;
        final right = secondaryColor ?? BankTokens.networkMastercardAmber;
        return SizedBox(
          height: height,
          width: height * 1.6,
          child: CustomPaint(
            painter: _MastercardPainter(
              left: left,
              right: right,
              // The classic lens colour only applies to the brand pair;
              // custom inks blend between themselves.
              blend: (color == null && secondaryColor == null)
                  ? BankTokens.networkMastercardBlend
                  : Color.lerp(left, right, 0.5)!,
            ),
          ),
        );
      case BankCardNetwork.generic:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Shared EMV chip
// ---------------------------------------------------------------------------

/// The kit-wide EMV chip: a rounded rectangle with a subtle two-stop metallic
/// gradient and four hairline contact lines.
///
/// Shared by `BankPaymentCard` and `BankVirtualCardWidget` so every card face
/// carries the same chip anatomy. [color] tints the metal (defaults to a soft
/// gold).
class BankCardChip extends StatelessWidget {
  const BankCardChip({
    super.key,
    this.width = 40,
    this.height = 30,
    this.color,
  });

  /// Chip width in logical pixels.
  final double width;

  /// Chip height in logical pixels.
  final double height;

  /// Base metal tone. Defaults to a soft gold.
  final Color? color;

  static const Color _defaultGold = Color(0xFFD9BE74);

  @override
  Widget build(BuildContext context) {
    final base = color ?? _defaultGold;
    final light = Color.lerp(base, Colors.white, 0.28)!;
    final dark = Color.lerp(base, Colors.black, 0.22)!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ),
        borderRadius: BorderRadius.circular(height * 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 0.7,
        ),
      ),
      child: CustomPaint(painter: _ChipContactPainter(ink: dark)),
    );
  }
}

/// Four faint contact hairlines that make the chip read as metal, not paint.
class _ChipContactPainter extends CustomPainter {
  const _ChipContactPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;
    canvas
      ..drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint)
      ..drawLine(
        Offset(thirdW * 2, 0),
        Offset(thirdW * 2, size.height),
        paint,
      )
      ..drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint)
      ..drawLine(
        Offset(0, thirdH * 2),
        Offset(size.width, thirdH * 2),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ChipContactPainter oldDelegate) => oldDelegate.ink != ink;
}

// ---------------------------------------------------------------------------
// Amex tile
// ---------------------------------------------------------------------------

/// Rounded-square Amex stand-in: brand-blue tile with a knocked-out 'AMEX'
/// in a registered upright weight (w700) and tracked micro-caps.
///
/// This is explicitly a stand-in — integrators shipping the official
/// American Express artwork should inject it via
/// [BankNetworkBadge.markBuilder].
class _AmexTile extends StatelessWidget {
  const _AmexTile({required this.height, required this.fill});

  final double height;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * 1.7,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height * 0.18),
      ),
      child: Text(
        'AMEX',
        style: BankTokens.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: height * 0.34,
          letterSpacing: height * 0.07,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visa wordmark painter
// ---------------------------------------------------------------------------

/// Hand-encoded vector 'VISA' wordmark: four slanted geometric letterforms
/// traced in a normalized 1080 x 324 design box and scaled from the badge
/// height. Single-ink monochrome so it tints to any card foreground.
///
/// This is a procedural stand-in with the wordmark's characteristic oblique;
/// integrators shipping the official Visa artwork should inject it via
/// [BankNetworkBadge.markBuilder].
class _VisaWordmarkPainter extends CustomPainter {
  const _VisaWordmarkPainter({required this.color});

  final Color color;

  static const double _designW = 1080;
  static const double _designH = 324;

  /// Width-to-height ratio of the drawn wordmark.
  static const double aspect = _designW / _designH;

  /// Oblique shear applied to the upright letterforms (top leans end-ward).
  static const double _slant = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56;

    canvas.save();
    canvas.scale(size.width / _designW, size.height / _designH);
    // Shear the upright letterforms into the wordmark's oblique, then shift
    // so the sheared box stays inside the design box.
    canvas.translate(85, 0);
    canvas.skew(-_slant, 0);

    // V — letter box 0..320.
    final v = Path()
      ..moveTo(0, 0)
      ..lineTo(62, 0)
      ..lineTo(160, 203)
      ..lineTo(258, 0)
      ..lineTo(320, 0)
      ..lineTo(186, 324)
      ..lineTo(134, 324)
      ..close();
    canvas.drawPath(v, fill);

    // I — letter box 354..416.
    canvas.drawRect(const Rect.fromLTRB(354, 0, 416, 324), fill);

    // S — two tangent arcs stroked as one spine, letter box 450..640.
    const sTop = Offset(545, 95);
    const sBottom = Offset(545, 229);
    final s = Path()
      ..addArc(
        Rect.fromCircle(center: sTop, radius: 67),
        -pi / 4,
        -1.25 * pi,
      )
      ..arcTo(
        Rect.fromCircle(center: sBottom, radius: 67),
        -pi / 2,
        1.25 * pi,
        false,
      );
    canvas.drawPath(s, stroke);

    // A — letter box 670..990, counter closed by the crossbar.
    final a = Path()
      ..moveTo(810, 0)
      ..lineTo(850, 0)
      ..lineTo(990, 324)
      ..lineTo(928, 324)
      ..lineTo(830, 121)
      ..lineTo(732, 324)
      ..lineTo(670, 324)
      ..close();
    canvas.drawPath(a, fill);
    canvas.drawRect(const Rect.fromLTRB(760, 200, 900, 262), fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VisaWordmarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// Mastercard painter
// ---------------------------------------------------------------------------

class _MastercardPainter extends CustomPainter {
  _MastercardPainter({
    required this.left,
    required this.right,
    required this.blend,
  });

  final Color left;
  final Color right;
  final Color blend;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final cy = size.height / 2;
    // Circles overlap in the middle third.
    final leftCenter = Offset(size.width * 0.36, cy);
    final rightCenter = Offset(size.width * 0.64, cy);

    final leftPaint = Paint()..color = left;
    final rightPaint = Paint()..color = right;
    canvas.drawCircle(leftCenter, r, leftPaint);
    canvas.drawCircle(rightCenter, r, rightPaint);

    // Paint the intersection lens in the blend colour using a clip to the
    // left circle over the right circle region.
    canvas.save();
    final overlap = Path()
      ..addOval(Rect.fromCircle(center: leftCenter, radius: r));
    canvas.clipPath(overlap);
    canvas.drawCircle(rightCenter, r, Paint()..color = blend);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MastercardPainter old) =>
      old.left != left || old.right != right || old.blend != blend;
}

/// Splits a masked PAN into digit and bullet runs so mask bullets can be
/// rendered slightly larger — the '•' glyph in most faces covers only about
/// half the digit x-height, which reads as two colliding fonts next to
/// tabular numerals.
///
/// Returns a span whose bullet runs are scaled to [bulletScale] of the base
/// font size. Kept in this file so all card faces share one PAN treatment.
TextSpan bankMaskedPanSpan(
  String pan,
  TextStyle style, {
  double bulletScale = 1.3,
}) {
  final bulletStyle = style.copyWith(
    fontSize:
        (style.fontSize ?? BankTokens.numeralMedium.fontSize!) * bulletScale,
    height: 1,
  );
  final spans = <TextSpan>[];
  for (final match in RegExp('[•*]+|[^•*]+').allMatches(pan)) {
    final run = match.group(0)!;
    final isMask = run.startsWith('•') || run.startsWith('*');
    spans.add(TextSpan(text: run, style: isMask ? bulletStyle : null));
  }
  return TextSpan(style: style, children: spans);
}
