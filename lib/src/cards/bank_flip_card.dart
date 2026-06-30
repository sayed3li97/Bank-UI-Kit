import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// How the flip animation is triggered on a [BankFlipCard].
enum BankFlipTrigger {
  /// Tapping anywhere on the card toggles the flip.
  tapToFlip,

  /// A small icon button is rendered in the card corner. The rest of the card
  /// is not tappable. Supply [BankFlipCard.flipButtonBuilder] to replace the
  /// default button with a custom widget.
  builtInButton,

  /// No built-in trigger. The host app drives the flip entirely via
  /// [BankFlipCard.isFlipped] and [BankFlipCard.onFlip].
  external,
}

/// Which physical axis the card rotates around.
enum BankFlipAxis {
  /// Card flips left-to-right (rotates around the Y axis). Default.
  horizontal,

  /// Card flips top-to-bottom (rotates around the X axis).
  vertical,
}

// ---------------------------------------------------------------------------
// BankFlipCard
// ---------------------------------------------------------------------------

/// A generic 3-D flip-card container.
///
/// Wraps any [frontBuilder] / [backBuilder] pair in a smooth perspective-flip
/// animation. Suitable for credit cards, account cards, info tiles — any
/// two-sided widget.
///
/// ## Trigger modes
///
/// | [trigger]                          | Behaviour |
/// |------------------------------------|-----------|
/// | `tapToFlip`     | Tap anywhere on the card to flip (default). |
/// | `builtInButton` | Small icon button in the card corner. |
/// | `external`      | No built-in trigger — host drives the flip. |
///
/// ## External control
///
/// Provide both [isFlipped] and [onFlip] to make the card *controlled*:
///
/// ```dart
/// BankFlipCard(
///   isFlipped: _flipped,
///   onFlip: () => setState(() => _flipped = !_flipped),
///   frontBuilder: (ctx, _) => MyFront(),
///   backBuilder:  (ctx, _) => MyBack(),
/// )
/// ```
///
/// Omit both for a self-managed (uncontrolled) card.
///
/// ## Custom flip button
///
/// ```dart
/// BankFlipCard(
///   trigger: BankFlipTrigger.builtInButton,
///   flipButtonBuilder: (ctx, flip) => IconButton(
///     icon: const Icon(Icons.info_outline),
///     onPressed: flip,
///   ),
///   frontBuilder: ...,
///   backBuilder:  ...,
/// )
/// ```
class BankFlipCard extends StatefulWidget {
  /// Builds the front face. Receives the [BuildContext] and whether the card
  /// is currently showing the back ([isFlipped] = true during animation).
  final Widget Function(BuildContext context, bool isFlipped) frontBuilder;

  /// Builds the back face. Receives the [BuildContext] and whether the card
  /// is currently showing the back.
  final Widget Function(BuildContext context, bool isFlipped) backBuilder;

  // ── External control ──────────────────────────────────────────────────────

  /// When non-null, the card is *controlled* by the host. Pair with [onFlip].
  final bool? isFlipped;

  /// Called when the card's flip trigger fires. When [isFlipped] is null the
  /// card manages its own state and [onFlip] is optional (used as a side-effect
  /// callback). When [isFlipped] is provided the host must toggle it in
  /// [onFlip].
  final VoidCallback? onFlip;

  // ── Trigger ───────────────────────────────────────────────────────────────

  /// What causes the flip. Defaults to [BankFlipTrigger.tapToFlip].
  final BankFlipTrigger trigger;

  /// Replaces the default icon-button when [trigger] is `builtInButton`.
  /// The builder receives a `flip` callback that the custom widget should
  /// invoke on interaction.
  final Widget Function(BuildContext context, VoidCallback flip)?
      flipButtonBuilder;

  // ── Animation ─────────────────────────────────────────────────────────────

  /// Duration of the flip animation. Defaults to 500 ms.
  final Duration flipDuration;

  /// Curve applied to the flip animation. Defaults to [Curves.easeInOutCubic].
  final Curve flipCurve;

  /// The rotation axis. Defaults to [BankFlipAxis.horizontal].
  final BankFlipAxis flipAxis;

  // ── Layout ────────────────────────────────────────────────────────────────

  /// Card width. Defaults to 340.
  final double width;

  /// Card height. Defaults to 200.
  final double height;

  const BankFlipCard({
    required this.frontBuilder,
    required this.backBuilder,
    super.key,
    this.isFlipped,
    this.onFlip,
    this.trigger = BankFlipTrigger.tapToFlip,
    this.flipButtonBuilder,
    this.flipDuration = const Duration(milliseconds: 500),
    this.flipCurve = Curves.easeInOutCubic,
    this.flipAxis = BankFlipAxis.horizontal,
    this.width = 340,
    this.height = 200,
  });

  @override
  State<BankFlipCard> createState() => _BankFlipCardState();
}

class _BankFlipCardState extends State<BankFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  bool _internalFlipped = false;

  bool get _isFlipped => widget.isFlipped ?? _internalFlipped;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.flipDuration);
    _anim = CurvedAnimation(parent: _ctrl, curve: widget.flipCurve);
    if (_isFlipped) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(BankFlipCard old) {
    super.didUpdateWidget(old);
    _ctrl.duration = widget.flipDuration;

    if (widget.isFlipped != null && widget.isFlipped != old.isFlipped) {
      widget.isFlipped! ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleFlip() {
    widget.onFlip?.call();
    // Internal state path (uncontrolled).
    if (widget.isFlipped == null) {
      final next = !_internalFlipped;
      setState(() => _internalFlipped = next);
      next ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final angle = _anim.value * pi;
        final showBack = angle > pi / 2;
        final isH = widget.flipAxis == BankFlipAxis.horizontal;

        Widget face;
        if (!showBack) {
          // Front rotates from 0 → π.
          face = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective depth
              .._rotateAxis(isH, angle),
            child: widget.frontBuilder(context, false),
          );
        } else {
          // Back starts at π (mirrored) and rotates back to 0 relative to
          // itself, so at animation-end (angle == π) it appears upright.
          // We also scale the mirrored axis by -1 so text isn't reversed.
          face = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              .._rotateAxis(isH, angle - pi),
            child: Transform(
              alignment: Alignment.center,
              transform: isH
                  ? (Matrix4.identity()..scale(-1, 1, 1))
                  : (Matrix4.identity()..scale(1, -1, 1)),
              child: widget.backBuilder(context, true),
            ),
          );
        }

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: face,
        );
      },
    );

    // ── Wrap with trigger ─────────────────────────────────────────────────
    switch (widget.trigger) {
      case BankFlipTrigger.tapToFlip:
        card = GestureDetector(
          onTap: _handleFlip,
          behavior: HitTestBehavior.opaque,
          child: card,
        );

      case BankFlipTrigger.builtInButton:
        card = Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            Positioned(
              top: BankTokens.space2,
              right: BankTokens.space2,
              child: widget.flipButtonBuilder != null
                  ? widget.flipButtonBuilder!(context, _handleFlip)
                  : _DefaultFlipButton(onFlip: _handleFlip),
            ),
          ],
        );

      case BankFlipTrigger.external:
        // No built-in trigger; host drives via isFlipped / onFlip.
        break;
    }

    return Semantics(
      label: _isFlipped ? 'Card back' : 'Card front',
      button: widget.trigger != BankFlipTrigger.external,
      child: card,
    );
  }
}

// ---------------------------------------------------------------------------
// Matrix4 extension helper (private)
// ---------------------------------------------------------------------------

extension on Matrix4 {
  void _rotateAxis(bool horizontal, double angle) {
    if (horizontal) {
      rotateY(angle);
    } else {
      rotateX(angle);
    }
  }
}

// ---------------------------------------------------------------------------
// Default flip button
// ---------------------------------------------------------------------------

/// Small semi-transparent icon button rendered in the card corner when
/// `BankFlipTrigger.builtInButton` is active and no `flipButtonBuilder` is
/// provided.
class _DefaultFlipButton extends StatelessWidget {
  const _DefaultFlipButton({required this.onFlip});

  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show card details',
      child: Material(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        child: InkWell(
          onTap: onFlip,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: const Padding(
            padding: EdgeInsets.all(BankTokens.space2),
            child: Icon(
              Icons.flip_outlined,
              size: 18,
              color: Colors.white,
              semanticLabel: 'Flip card',
            ),
          ),
        ),
      ),
    );
  }
}
