import 'package:flutter/material.dart';

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
/// The marks are drawn **procedurally** — the kit bundles no image assets, so
/// this works offline and tints to the card's foreground where the mark is
/// typographic. The Mastercard interlocking circles use the network's brand
/// colours by default (overridable via [color]/[secondaryColor]).
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
    this.wordmarkStyle,
    this.semanticLabel,
  });

  /// The network to render.
  final BankCardNetwork network;

  /// Mark height in logical pixels. Wordmarks scale their font from this.
  final double height;

  /// Ink for the typographic marks (Visa / Amex); defaults to white. For
  /// Mastercard it also sets the left circle, so pass `null` there to keep
  /// the brand red (see `BankPaymentCard`, which does this automatically).
  final Color? color;

  /// The Mastercard right (amber) circle. Defaults to the brand amber.
  final Color? secondaryColor;

  /// Merged over the computed wordmark style.
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

  Widget _mark(BuildContext context) {
    switch (network) {
      case BankCardNetwork.visa:
        return _wordmark('VISA', italic: true, letterSpacing: height * 0.06);
      case BankCardNetwork.amex:
        return _wordmark('AMEX', italic: false, letterSpacing: height * 0.08);
      case BankCardNetwork.mastercard:
        return SizedBox(
          height: height,
          width: height * 1.6,
          child: CustomPaint(
            painter: _MastercardPainter(
              left: color ?? const Color(0xFFEB001B),
              right: secondaryColor ?? const Color(0xFFF79E1B),
            ),
          ),
        );
      case BankCardNetwork.generic:
        return const SizedBox.shrink();
    }
  }

  Widget _wordmark(
    String text, {
    required bool italic,
    required double letterSpacing,
  }) {
    final base = BankTokens.headlineSmall.copyWith(
      color: color ?? Colors.white,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w800,
      fontSize: height * 0.82,
      letterSpacing: letterSpacing,
      height: 1,
    );
    return Text(text, style: base.merge(wordmarkStyle));
  }
}

class _MastercardPainter extends CustomPainter {
  _MastercardPainter({required this.left, required this.right});

  final Color left;
  final Color right;

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

    // Blended overlap: paint the intersection in the classic orange using a
    // clip to the left circle over the right circle region.
    canvas.save();
    final overlap = Path()
      ..addOval(Rect.fromCircle(center: leftCenter, radius: r));
    canvas.clipPath(overlap);
    canvas.drawCircle(
      rightCenter,
      r,
      Paint()..color = const Color(0xFFFF5F00),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MastercardPainter old) =>
      old.left != left || old.right != right;
}
