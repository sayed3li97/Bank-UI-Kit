import 'dart:math' show min, pi;

import 'package:flutter/material.dart';

import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// How the flip animation is triggered on a [BankFlipCard].
enum BankFlipTrigger {
  /// Tapping anywhere on the card toggles the flip.
  tapToFlip,

  /// A small icon button is rendered in the card's **top-end corner**. The
  /// rest of the card is not tappable. Supply
  /// [BankFlipCard.flipButtonBuilder] to replace the default button with a
  /// custom widget. Faces should keep [BankFlipCard.builtInButtonClearance]
  /// free of content at that corner so the button never occludes them.
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
/// animation. Suitable for credit cards, account cards, info tiles: any
/// two-sided widget.
///
/// ## Trigger modes
///
/// | [trigger]                          | Behaviour |
/// |------------------------------------|-----------|
/// | `tapToFlip`     | Tap anywhere on the card to flip (default). |
/// | `builtInButton` | Small icon button in the card corner. |
/// | `external`      | No built-in trigger: host drives the flip. |
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
  ///
  /// When [trigger] is [BankFlipTrigger.builtInButton] the button overlays
  /// the top-end corner: keep [builtInButtonClearance] logical pixels free of
  /// content from the card's end edge in that corner.
  final Widget Function(BuildContext context, bool isFlipped) frontBuilder;

  /// Builds the back face. Receives the [BuildContext] and whether the card
  /// is currently showing the back.
  ///
  /// The built-in flip button also overlays this face's top-end corner; see
  /// [builtInButtonClearance].
  final Widget Function(BuildContext context, bool isFlipped) backBuilder;

  // ── Built-in button geometry (contract for face builders) ────────────────

  /// Inset of the built-in flip button from the card's top and end edges.
  static const double builtInButtonInset = BankTokens.space2;

  /// Footprint (width and height) of the default built-in flip button:
  /// an 18 px icon plus [BankTokens.space2] padding on each side.
  static const double builtInButtonExtent = 34;

  /// Horizontal extent a face must keep free of content from the card's
  /// **end** edge at the top corner when [trigger] is
  /// [BankFlipTrigger.builtInButton]: button inset + button footprint + a
  /// [BankTokens.space2] gap.
  static const double builtInButtonClearance =
      builtInButtonInset + builtInButtonExtent + BankTokens.space2;

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

  /// Default card width, used as the upper bound when neither [width] nor
  /// [maxWidth] is provided.
  static const double _defaultWidth = 340;

  /// Fixed card width. When null (the default) the card fills the available
  /// width up to [maxWidth] (340 when [maxWidth] is also null), so it renders
  /// at 340 in unconstrained contexts, exactly as older versions did.
  final double? width;

  /// Fixed card height. When null (the default) the height is derived from
  /// the resolved width using the ISO 7810 ID-1 card ratio
  /// ([kBankCardAspectRatio], 1.586) so flip cards match the rest of the
  /// card family.
  final double? height;

  /// Upper bound on the card width when [width] is null. Defaults to 340,
  /// matching the previous fixed width.
  final double? maxWidth;

  // Customization overrides (all optional; null keeps current behaviour).

  /// Glyph of the default flip button. Defaults to [Icons.flip_outlined].
  final IconData? flipIcon;

  /// Background of the default flip button. Defaults to black at 30% alpha.
  final Color? flipButtonBackgroundColor;

  /// Icon and splash colour of the default flip button. Defaults to
  /// [Colors.white].
  final Color? flipButtonForegroundColor;

  /// Semantics label of the default flip button. Defaults to
  /// 'Show card details'.
  final String? flipButtonSemanticLabel;

  /// Semantics label of the default flip button glyph. Defaults to
  /// 'Flip card'.
  final String? flipIconSemanticLabel;

  /// Semantics label announced while the front face shows. Defaults to
  /// 'Card front'.
  final String? frontSemanticLabel;

  /// Semantics label announced while the back face shows. Defaults to
  /// 'Card back'.
  final String? backSemanticLabel;

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
    this.width,
    this.height,
    this.maxWidth,
    this.flipIcon,
    this.flipButtonBackgroundColor,
    this.flipButtonForegroundColor,
    this.flipButtonSemanticLabel,
    this.flipIconSemanticLabel,
    this.frontSemanticLabel,
    this.backSemanticLabel,
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

  // ── Sizing ────────────────────────────────────────────────────────────────

  /// Resolves the rendered width: an explicit [BankFlipCard.width] wins;
  /// otherwise the card fills the available width up to
  /// [BankFlipCard.maxWidth] (340 by default).
  double _resolveWidth(BoxConstraints constraints) {
    final fixedWidth = widget.width;
    if (fixedWidth != null) return fixedWidth;
    final maxWidth = widget.maxWidth ?? BankFlipCard._defaultWidth;
    return constraints.hasBoundedWidth
        ? min(constraints.maxWidth, maxWidth)
        : maxWidth;
  }

  /// Resolves the rendered height: an explicit [BankFlipCard.height] wins;
  /// otherwise the height preserves the ISO 7810 ID-1 card ratio
  /// ([kBankCardAspectRatio]).
  double _resolveHeight(double cardWidth) =>
      widget.height ?? cardWidth / kBankCardAspectRatio;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _resolveWidth(constraints);
        final cardHeight = _resolveHeight(cardWidth);
        return _buildCard(context, cardWidth, cardHeight);
      },
    );
  }

  Widget _buildCard(BuildContext context, double cardWidth, double cardHeight) {
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
                  ? (Matrix4.identity()..scaleByDouble(-1, 1, 1, 1))
                  : (Matrix4.identity()..scaleByDouble(1, -1, 1, 1)),
              child: widget.backBuilder(context, true),
            ),
          );
        }

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
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
            // Directional so the button tracks the top-END corner in RTL.
            PositionedDirectional(
              top: BankFlipCard.builtInButtonInset,
              end: BankFlipCard.builtInButtonInset,
              child: widget.flipButtonBuilder != null
                  ? widget.flipButtonBuilder!(context, _handleFlip)
                  : _DefaultFlipButton(
                      onFlip: _handleFlip,
                      icon: widget.flipIcon,
                      backgroundColor: widget.flipButtonBackgroundColor,
                      foregroundColor: widget.flipButtonForegroundColor,
                      buttonSemanticLabel: widget.flipButtonSemanticLabel,
                      iconSemanticLabel: widget.flipIconSemanticLabel,
                    ),
            ),
          ],
        );

      case BankFlipTrigger.external:
        // No built-in trigger; host drives via isFlipped / onFlip.
        break;
    }

    final resolvedLabel = _isFlipped
        ? (widget.backSemanticLabel ?? 'Card back')
        : (widget.frontSemanticLabel ?? 'Card front');

    return Semantics(
      label: resolvedLabel,
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
  const _DefaultFlipButton({
    required this.onFlip,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.buttonSemanticLabel,
    this.iconSemanticLabel,
  });

  final VoidCallback onFlip;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? buttonSemanticLabel;
  final String? iconSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        backgroundColor ?? Colors.black.withValues(alpha: 0.30);
    final resolvedForeground = foregroundColor ?? Colors.white;

    return Semantics(
      button: true,
      label: buttonSemanticLabel ?? 'Show card details',
      child: Material(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        child: InkWell(
          onTap: onFlip,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          splashColor: resolvedForeground.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space2),
            child: Icon(
              icon ?? Icons.flip_outlined,
              size: 18,
              color: resolvedForeground,
              semanticLabel: iconSemanticLabel ?? 'Flip card',
            ),
          ),
        ),
      ),
    );
  }
}
