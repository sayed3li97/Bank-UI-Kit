import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../src/cards/bank_flip_card.dart';
import '../../src/models/bank_account.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum BankCardSurface {
  flatColor,
  gradient,
  animatedMesh,
  metallicSweep,
}

enum BankCardState { normal, frozen }

// ---------------------------------------------------------------------------
// BankVirtualCardWidget
// ---------------------------------------------------------------------------

/// Realistic virtual card with front/back flip animation.
///
/// Supports multiple surface treatments ([BankCardSurface]) and a
/// frozen-state frost overlay. The flip is controlled externally via
/// [isFlipped] + [onFlip]; the internal [AnimationController] responds to
/// changes in [isFlipped] and plays the animation accordingly.
///
/// ## New in this version
///
/// - **[backgroundImage]**: supply any [ImageProvider] (asset, network,
///   memory) to use as the card background instead of the [surface] colour.
///   A dark overlay is applied automatically for readability; override it
///   with [backgroundImageOverlay].
///
/// - **[flipTrigger]**: choose how the flip is triggered:
///   - [BankFlipTrigger.tapToFlip] (default): tap anywhere on the card.
///   - [BankFlipTrigger.builtInButton]: overlaid icon button in the card
///     corner; provide [flipButtonBuilder] to customise it.
///   - [BankFlipTrigger.external]: host app drives the flip entirely.
///
/// Card corner radius is fixed at 16 px per the card-material specification.
class BankVirtualCardWidget extends StatefulWidget {
  final BankAccount account;
  final BankCardSurface surface;
  final BankCardState cardState;

  /// Solid colour used for [BankCardSurface.flatColor] and as the base for
  /// [BankCardSurface.gradient]. Falls back to [BankThemeData.primary].
  final Color? primaryColor;

  /// Second gradient stop for [BankCardSurface.gradient].
  /// Falls back to [BankThemeData.primaryVariant].
  final Color? secondaryColor;

  /// When set, the card's [surface] decoration is replaced by this image.
  /// Accepts any [ImageProvider]: [AssetImage], [NetworkImage], [MemoryImage].
  final ImageProvider? backgroundImage;

  /// How the [backgroundImage] is fitted within the card.
  final BoxFit backgroundImageFit;

  /// Colour blended over [backgroundImage] to keep text legible.
  /// Defaults to a 30 % black darken filter.
  final Color? backgroundImageOverlay;

  /// Asset path for the card-network logo (e.g. `'assets/visa.png'`).
  /// Rendered as an [Image.asset]: must be registered in the host-app
  /// pubspec.yaml.
  final String? networkLogoAsset;

  /// Asset path for the bank logo on the back face.
  final String? bankLogoAsset;

  final String? cardholderName;

  /// Expiry date string in `'MM/YY'` format.
  final String? expiryDate;

  /// Whether the card is currently showing its back face.
  final bool isFlipped;

  /// Invoked when the flip trigger fires. For [BankFlipTrigger.tapToFlip]
  /// and [BankFlipTrigger.builtInButton] the host should toggle [isFlipped]
  /// here.
  final VoidCallback? onFlip;

  /// How the flip is triggered. Defaults to [BankFlipTrigger.tapToFlip]
  /// (tap anywhere on the card).
  final BankFlipTrigger flipTrigger;

  /// Replaces the default icon-button when `flipTrigger` is `builtInButton`.
  /// The builder receives the [BuildContext] and a `flip` callback to invoke
  /// on interaction.
  final Widget Function(BuildContext context, VoidCallback flip)?
      flipButtonBuilder;

  final double width;
  final double height;

  const BankVirtualCardWidget({
    required this.account,
    super.key,
    this.surface = BankCardSurface.gradient,
    this.cardState = BankCardState.normal,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundImage,
    this.backgroundImageFit = BoxFit.cover,
    this.backgroundImageOverlay,
    this.networkLogoAsset,
    this.bankLogoAsset,
    this.cardholderName,
    this.expiryDate,
    this.isFlipped = false,
    this.onFlip,
    this.flipTrigger = BankFlipTrigger.tapToFlip,
    this.flipButtonBuilder,
    this.width = 340,
    this.height = 200,
  });

  @override
  State<BankVirtualCardWidget> createState() => _BankVirtualCardWidgetState();
}

class _BankVirtualCardWidgetState extends State<BankVirtualCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  static const double _cardRadius = 16;
  static const Duration _flipDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: _flipDuration,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    if (widget.isFlipped) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(BankVirtualCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Surface decoration
  // ---------------------------------------------------------------------------

  BoxDecoration _buildFlatColorDecoration(BankThemeData bankTheme) =>
      BoxDecoration(
        color: widget.primaryColor ?? bankTheme.primary,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: BankTokens.shadowHero,
      );

  BoxDecoration _buildGradientDecoration(BankThemeData bankTheme) =>
      BoxDecoration(
        gradient: bankTheme.accentGradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor ?? bankTheme.primary,
                widget.secondaryColor ?? bankTheme.primaryVariant,
              ],
            ),
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: BankTokens.shadowHero,
      );

  // ---------------------------------------------------------------------------
  // Surface wrapper
  // ---------------------------------------------------------------------------

  BoxDecoration _buildImageDecoration(BankThemeData bankTheme) => BoxDecoration(
        color: widget.primaryColor ?? bankTheme.primary,
        borderRadius: BorderRadius.circular(_cardRadius),
        image: DecorationImage(
          image: widget.backgroundImage!,
          fit: widget.backgroundImageFit,
          colorFilter: widget.backgroundImageOverlay != null
              ? ColorFilter.mode(
                  widget.backgroundImageOverlay!,
                  BlendMode.srcATop,
                )
              : const ColorFilter.mode(
                  Color(0x4D000000), // 30 % black darken
                  BlendMode.darken,
                ),
        ),
      );

  Widget _wrapSurface({
    required Widget child,
    required BankThemeData bankTheme,
  }) {
    final borderRadius = BorderRadius.circular(_cardRadius);

    // Image background overrides the surface enum.
    if (widget.backgroundImage != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: _buildImageDecoration(bankTheme),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }

    switch (widget.surface) {
      case BankCardSurface.flatColor:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: _buildFlatColorDecoration(bankTheme),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

      case BankCardSurface.gradient:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: _buildGradientDecoration(bankTheme),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

      case BankCardSurface.animatedMesh:
        return RepaintBoundary(
          child: _AnimatedMeshCard(
            width: widget.width,
            height: widget.height,
            primaryColor: widget.primaryColor ?? bankTheme.primary,
            secondaryColor: widget.secondaryColor ?? bankTheme.primaryVariant,
            borderRadius: borderRadius,
            child: child,
          ),
        );

      case BankCardSurface.metallicSweep:
        return RepaintBoundary(
          child: _MetallicSweepCard(
            width: widget.width,
            height: widget.height,
            primaryColor: widget.primaryColor ?? bankTheme.primary,
            secondaryColor: widget.secondaryColor ?? bankTheme.primaryVariant,
            borderRadius: borderRadius,
            child: child,
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Frozen overlay
  // ---------------------------------------------------------------------------

  Widget _buildFrozenOverlay() => Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: ColoredBox(
              color: Colors.blueGrey.withValues(alpha: 0.35),
              child: const Center(
                child: Icon(
                  Icons.ac_unit_outlined,
                  color: Colors.white,
                  size: 48,
                  semanticLabel: 'Card frozen',
                ),
              ),
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Front face
  // ---------------------------------------------------------------------------

  Widget _buildFrontFace(BankThemeData bankTheme) {
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.75);

    return _wrapSurface(
      bankTheme: bankTheme,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: chip icon + network logo ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // EMV chip placeholder
                Container(
                  width: 38,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE8CE8C),
                        Color(0xFFC9A85C),
                        Color(0xFFB08F45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 0.8,
                    ),
                  ),
                  child: CustomPaint(painter: _ChipContactPainter()),
                ),
                if (widget.networkLogoAsset != null)
                  Image.asset(
                    widget.networkLogoAsset!,
                    height: 28,
                    fit: BoxFit.contain,
                  )
                else
                  Text(
                    'VISA',
                    style: BankTokens.labelLarge.copyWith(
                      color: textPrimary,
                      fontStyle: FontStyle.italic,
                      fontSize: 18,
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // ── Card number (masked) ───────────────────────────────────────
            Text(
              _formatMaskedNumber(widget.account.maskedNumber),
              style: BankTokens.numeralMedium.copyWith(
                color: textPrimary,
                letterSpacing: 3,
                fontSize: 18,
              ),
              textDirection: TextDirection.ltr,
            ),

            const SizedBox(height: BankTokens.space4),

            // ── Bottom row: cardholder + expiry ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: BankTokens.labelSmall.copyWith(
                          color: textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.cardholderName ?? widget.account.name,
                        style: BankTokens.labelLarge.copyWith(
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (widget.expiryDate != null) ...[
                  const SizedBox(width: BankTokens.space3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EXPIRES',
                        style: BankTokens.labelSmall.copyWith(
                          color: textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.expiryDate!,
                        style: BankTokens.labelLarge.copyWith(
                          color: textPrimary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Back face
  // ---------------------------------------------------------------------------

  Widget _buildBackFace(BankThemeData bankTheme) {
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.75);

    return _wrapSurface(
      bankTheme: bankTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Magnetic stripe ────────────────────────────────────────────────
          Container(
            height: 50,
            color: const Color(0xFF1A1A1A),
          ),

          const SizedBox(height: BankTokens.space5),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Signature strip + CVV ────────────────────────────────────
                Row(
                  children: [
                    // Signature strip
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space2,
                          vertical: BankTokens.space1,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            widget.cardholderName ?? widget.account.name,
                            style: BankTokens.bodySmall.copyWith(
                              color: const Color(0xFF333333),
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BankTokens.space2),
                    // CVV box
                    Container(
                      width: 56,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '•••',
                        style: BankTokens.labelLarge.copyWith(
                          color: const Color(0xFF333333),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: BankTokens.space1),

                Text(
                  'CVV',
                  style: BankTokens.labelSmall.copyWith(color: textSecondary),
                  textAlign: TextAlign.end,
                ),

                const Spacer(),
              ],
            ),
          ),

          const Spacer(),

          // ── Bottom: bank logo ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              left: BankTokens.space5,
              right: BankTokens.space5,
              bottom: BankTokens.space4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.bankLogoAsset != null)
                  Image.asset(
                    widget.bankLogoAsset!,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                else
                  Text(
                    widget.account.name,
                    style: BankTokens.labelMedium.copyWith(color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: card number formatting
  // ---------------------------------------------------------------------------

  /// Renders the masked card number as four groups for legibility.
  /// Input can be `'•••• 4242'` or `'4242'`: we normalise to
  /// `'•••• •••• •••• 4242'`.
  String _formatMaskedNumber(String masked) {
    final clean = masked.replaceAll(RegExp(r'[\s•]+'), '');
    if (clean.isEmpty) return '•••• •••• •••• ••••';
    final last = clean.length > 4 ? clean.substring(clean.length - 4) : clean;
    return '•••• •••• •••• $last';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final isFrozen = widget.cardState == BankCardState.frozen;

    final Widget animated = AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, _) {
        final angle = _flipAnimation.value;
        final showBack = angle > pi / 2;

        // Front: 0 → π. Back: counter-rotate so at π it appears upright;
        // scaleX(-1) prevents mirroring.
        Widget face;
        if (!showBack) {
          face = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: _buildFaceStack(
              context: context,
              bankTheme: bankTheme,
              isFront: true,
              isFrozen: isFrozen,
            ),
          );
        } else {
          face = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle - pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1, 1),
              child: _buildFaceStack(
                context: context,
                bankTheme: bankTheme,
                isFront: false,
                isFrozen: isFrozen,
              ),
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

    // ── Wrap with flip trigger ────────────────────────────────────────
    Widget card;
    switch (widget.flipTrigger) {
      case BankFlipTrigger.tapToFlip:
        card = GestureDetector(
          onTap: widget.onFlip,
          behavior: HitTestBehavior.opaque,
          child: animated,
        );
      case BankFlipTrigger.builtInButton:
        card = Stack(
          clipBehavior: Clip.none,
          children: [
            animated,
            Positioned(
              top: BankTokens.space2,
              right: BankTokens.space2,
              child: widget.flipButtonBuilder != null
                  ? widget.flipButtonBuilder!(context, widget.onFlip ?? () {})
                  : _VirtualCardFlipButton(
                      onFlip: widget.onFlip ?? () {},
                    ),
            ),
          ],
        );
      case BankFlipTrigger.external:
        card = animated;
    }

    return Semantics(
      label: 'Card ending ${widget.account.maskedNumber}, '
          '${widget.cardState.name}',
      button: widget.flipTrigger != BankFlipTrigger.external,
      child: card,
    );
  }

  Widget _buildFaceStack({
    required BuildContext context,
    required BankThemeData bankTheme,
    required bool isFront,
    required bool isFrozen,
  }) {
    final face =
        isFront ? _buildFrontFace(bankTheme) : _buildBackFace(bankTheme);

    if (isFrozen) {
      return Stack(
        children: [
          face,
          _buildFrozenOverlay(),
        ],
      );
    }

    return face;
  }
}

// ---------------------------------------------------------------------------
// Built-in flip button for BankVirtualCardWidget
// ---------------------------------------------------------------------------

class _VirtualCardFlipButton extends StatelessWidget {
  const _VirtualCardFlipButton({required this.onFlip});

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
          child: const Padding(
            padding: EdgeInsets.all(BankTokens.space2),
            child: Icon(
              Icons.flip_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Mesh Surface
// ---------------------------------------------------------------------------

/// Animated gradient-mesh card surface.
///
/// Renders two soft, blurred colour blobs that drift in opposite directions
/// over the card surface to create a living mesh-gradient effect. Wrapped in
/// [RepaintBoundary] by the caller.
class _AnimatedMeshCard extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final BorderRadius borderRadius;
  final Widget child;

  const _AnimatedMeshCard({
    required this.width,
    required this.height,
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_AnimatedMeshCard> createState() => _AnimatedMeshCardState();
}

class _AnimatedMeshCardState extends State<_AnimatedMeshCard>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;
  late final Animation<Alignment> _anim1;
  late final Animation<Alignment> _anim2;

  @override
  void initState() {
    super.initState();

    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _anim1 = AlignmentTween(
      begin: Alignment.topLeft,
      end: const Alignment(0.6, 0.8),
    ).animate(CurvedAnimation(parent: _ctrl1, curve: Curves.easeInOut));

    _anim2 = AlignmentTween(
      begin: Alignment.bottomRight,
      end: const Alignment(-0.6, -0.8),
    ).animate(CurvedAnimation(parent: _ctrl2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl1, _ctrl2]),
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.85),
            borderRadius: widget.borderRadius,
          ),
          child: Stack(
            children: [
              // ── Blob 1 ────────────────────────────────────────────────────
              Positioned(
                left: (_anim1.value.x + 1) / 2 * widget.width - 100,
                top: (_anim1.value.y + 1) / 2 * widget.height - 100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.secondaryColor.withValues(alpha: 0.7),
                        widget.secondaryColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Blob 2 ────────────────────────────────────────────────────
              Positioned(
                left: (_anim2.value.x + 1) / 2 * widget.width - 80,
                top: (_anim2.value.y + 1) / 2 * widget.height - 80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Metallic Sweep Surface
// ---------------------------------------------------------------------------

/// Metallic sweep card surface.
///
/// Applies a looping specular-highlight sweep using [ShaderMask] over a
/// solid base colour, giving a premium metal-card impression. Wrapped in
/// [RepaintBoundary] by the caller.
class _MetallicSweepCard extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final BorderRadius borderRadius;
  final Widget child;

  const _MetallicSweepCard({
    required this.width,
    required this.height,
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_MetallicSweepCard> createState() => _MetallicSweepCardState();
}

class _MetallicSweepCardState extends State<_MetallicSweepCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _sweep = Tween<double>(begin: -1.4, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) {
        // Sweep moves a narrow white highlight band from left to right.
        final dx = _sweep.value;
        final shader = LinearGradient(
          begin: Alignment(dx - 0.25, -0.5),
          end: Alignment(dx + 0.25, 0.5),
          colors: const [
            Colors.transparent,
            Color(0x66FFFFFF), // ~40% white
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.secondaryColor,
              ],
            ),
            borderRadius: widget.borderRadius,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: shader.createShader,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Faint EMV contact lines that make the chip read as metal, not paint.
class _ChipContactPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x2E6B5320)
      ..strokeWidth = 0.9;
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
  bool shouldRepaint(_ChipContactPainter oldDelegate) => false;
}
