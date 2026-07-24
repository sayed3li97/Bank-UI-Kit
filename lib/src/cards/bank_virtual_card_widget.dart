import 'dart:math' show min, pi;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../src/cards/bank_card_network_badge.dart';
import '../../src/cards/bank_flip_card.dart';
import '../../src/models/bank_account.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/card_pattern.dart';
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
///   - [BankFlipTrigger.builtInButton]: overlaid icon button in the card's
///     top-end corner; provide [flipButtonBuilder] to customise it. The
///     front face automatically keeps that corner clear (see
///     [BankFlipCard.builtInButtonClearance]).
///   - [BankFlipTrigger.external]: host app drives the flip entirely.
///
/// Card corner radius defaults to [BankThemeData.cardRadius]; override with
/// [radius].
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
  /// pubspec.yaml. Takes precedence over [network] and [networkLabel].
  final String? networkLogoAsset;

  /// The payment network whose vector mark is rendered top-end via
  /// [BankNetworkBadge]. [BankCardNetwork.generic] renders no mark. When
  /// null, the legacy [networkLabel] string is parsed instead.
  final BankCardNetwork? network;

  /// Passed through to [BankNetworkBadge.markBuilder] so integrators can
  /// inject licensed brand artwork.
  final Widget Function(
    BuildContext context,
    BankCardNetwork network,
    double height,
  )? markBuilder;

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

  /// Fixed card width. When null (the default) the card fills the available
  /// width up to [maxWidth] (340 when [maxWidth] is also null), so it renders
  /// at 340 in unconstrained contexts, exactly as older versions did.
  final double? width;

  /// Fixed card height. When null (the default) the height is derived from
  /// the resolved width using the ISO 7810 ID-1 card ratio
  /// ([kBankCardAspectRatio], 1.586) so this card matches `BankPaymentCard`
  /// proportions.
  final double? height;

  /// Upper bound on the card width when [width] is null. Defaults to 340,
  /// matching the previous fixed width.
  final double? maxWidth;

  /// Overrides the front-face content padding.
  /// Defaults to `EdgeInsets.all(BankTokens.space5)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius.
  /// Defaults to [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the text and icon colour on both faces.
  /// Defaults to [BankThemeData.onPrimary].
  final Color? foregroundColor;

  /// Overrides the gradient painted for [BankCardSurface.gradient].
  /// Defaults to [BankThemeData.cardSurfaceGradient], then
  /// [BankThemeData.accentGradient], then a primary/secondary blend.
  final Gradient? gradient;

  /// Overrides the hero shadow behind the card — **all** surface modes keep
  /// it, including [BankCardSurface.animatedMesh],
  /// [BankCardSurface.metallicSweep], and image backgrounds. Defaults to
  /// [BankTokens.shadowHeroFor] of the theme background brightness; an empty
  /// list removes it.
  final List<BoxShadow>? shadow;

  /// Merged over the custom (non-network) [networkLabel] text style
  /// (upright, tracked [BankTokens.labelLarge]).
  final TextStyle? networkLabelStyle;

  /// Merged over the card number style
  /// (letter-spaced [BankTokens.numeralMedium]).
  final TextStyle? cardNumberStyle;

  /// Merged over the [cardholderLabel] caption style
  /// (tracked [BankTokens.caption]).
  final TextStyle? cardholderLabelStyle;

  /// Merged over the cardholder name style ([BankTokens.labelLarge]).
  final TextStyle? cardholderNameStyle;

  /// Merged over the [expiryLabel] caption style
  /// (tracked [BankTokens.caption]).
  final TextStyle? expiryLabelStyle;

  /// Merged over the expiry value style ([BankTokens.labelLarge]).
  final TextStyle? expiryDateStyle;

  /// Merged over the signature-strip name style
  /// (italic [BankTokens.bodySmall]).
  final TextStyle? signatureStyle;

  /// Merged over the [cvvPlaceholder] style
  /// (letter-spaced [BankTokens.labelLarge]).
  final TextStyle? cvvStyle;

  /// Merged over the [cvvLabel] caption style ([BankTokens.labelSmall]).
  final TextStyle? cvvLabelStyle;

  /// Merged over the back-face bank name style ([BankTokens.labelMedium]).
  final TextStyle? bankNameStyle;

  /// Overrides the frozen-overlay glyph.
  /// Defaults to [Icons.ac_unit_outlined].
  final IconData? frozenIcon;

  /// Overrides the built-in flip button glyph.
  /// Defaults to [Icons.flip_outlined].
  final IconData? flipIcon;

  /// Escape-hatch label for domestic / unlisted schemes, shown when neither
  /// [networkLogoAsset] nor [network] resolves a mark. The values `'visa'`,
  /// `'mastercard'`, `'amex'` / `'american express'` (case-insensitive) are
  /// upgraded to the matching [BankNetworkBadge]; any other non-empty string
  /// renders as upright tracked text. Defaults to `''` (no network claimed —
  /// unconfigured cards no longer show a counterfeit Visa mark).
  final String networkLabel;

  /// Caption above the cardholder name. Defaults to 'CARD HOLDER'.
  final String cardholderLabel;

  /// Caption above the expiry date. Defaults to 'EXPIRES'.
  final String expiryLabel;

  /// Caption under the CVV box on the back face. Defaults to 'CVV'.
  final String cvvLabel;

  /// Masked text inside the CVV box. Defaults to three bullets.
  final String cvvPlaceholder;

  /// Semantics label for the frozen-overlay icon.
  /// Defaults to 'Card frozen'.
  final String frozenSemanticLabel;

  /// Semantics label for the built-in flip button.
  /// Defaults to 'Show card details'.
  final String flipButtonSemanticLabel;

  /// Overrides the card's semantics label. Defaults to
  /// 'Card ending (masked number), (card state)'.
  final String? semanticLabel;

  /// Overrides the flip animation duration.
  /// Defaults to 500 milliseconds.
  final Duration? animationDuration;

  /// Overrides the flip animation curve. Defaults to [Curves.easeInOut].
  final Curve? animationCurve;

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
    this.network,
    this.markBuilder,
    this.bankLogoAsset,
    this.cardholderName,
    this.expiryDate,
    this.isFlipped = false,
    this.onFlip,
    this.flipTrigger = BankFlipTrigger.tapToFlip,
    this.flipButtonBuilder,
    this.width,
    this.height,
    this.maxWidth,
    this.padding,
    this.radius,
    this.foregroundColor,
    this.gradient,
    this.shadow,
    this.networkLabelStyle,
    this.cardNumberStyle,
    this.cardholderLabelStyle,
    this.cardholderNameStyle,
    this.expiryLabelStyle,
    this.expiryDateStyle,
    this.signatureStyle,
    this.cvvStyle,
    this.cvvLabelStyle,
    this.bankNameStyle,
    this.frozenIcon,
    this.flipIcon,
    this.networkLabel = '',
    this.cardholderLabel = 'CARD HOLDER',
    this.expiryLabel = 'EXPIRES',
    this.cvvLabel = 'CVV',
    this.cvvPlaceholder = '•••',
    this.frozenSemanticLabel = 'Card frozen',
    this.flipButtonSemanticLabel = 'Show card details',
    this.semanticLabel,
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<BankVirtualCardWidget> createState() => _BankVirtualCardWidgetState();
}

class _BankVirtualCardWidgetState extends State<BankVirtualCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  static const Duration _flipDuration = Duration(milliseconds: 500);

  /// Default card width, used as the upper bound when neither `width` nor
  /// `maxWidth` is provided.
  static const double _defaultWidth = 340;

  @override
  void initState() {
    super.initState();
    final resolvedDuration = widget.animationDuration ?? _flipDuration;
    final resolvedCurve = widget.animationCurve ?? Curves.easeInOut;
    _flipController = AnimationController(
      vsync: this,
      duration: resolvedDuration,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: resolvedCurve),
    );

    if (widget.isFlipped) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(BankVirtualCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _flipController.duration = widget.animationDuration ?? _flipDuration;
    }
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

  /// Card corner radius, honouring the `radius` override; the default comes
  /// from the theme so the whole card family shares one shape.
  BorderRadius _resolvedRadius(BankThemeData bankTheme) =>
      widget.radius ?? bankTheme.cardRadius;

  /// The hero shadow, honouring the `shadow` override and the theme
  /// background brightness. Applied uniformly to **every** surface mode so
  /// mesh / metallic / image cards never float as flat cutouts.
  List<BoxShadow> _resolvedShadow(BankThemeData bankTheme) =>
      widget.shadow ??
      BankTokens.shadowHeroFor(
        ThemeData.estimateBrightnessForColor(bankTheme.background),
      );

  BoxDecoration _buildFlatColorDecoration(BankThemeData bankTheme) =>
      BoxDecoration(
        color: widget.primaryColor ?? bankTheme.primary,
        borderRadius: _resolvedRadius(bankTheme),
      );

  BoxDecoration _buildGradientDecoration(BankThemeData bankTheme) {
    final resolvedGradient = widget.gradient ??
        bankTheme.cardSurfaceGradient ??
        bankTheme.accentGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor ?? bankTheme.primary,
            widget.secondaryColor ?? bankTheme.primaryVariant,
          ],
        );
    return BoxDecoration(
      gradient: resolvedGradient,
      borderRadius: _resolvedRadius(bankTheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Surface wrapper
  // ---------------------------------------------------------------------------

  BoxDecoration _buildImageDecoration(BankThemeData bankTheme) => BoxDecoration(
        color: widget.primaryColor ?? bankTheme.primary,
        borderRadius: _resolvedRadius(bankTheme),
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

  /// Layers the theme's generative card pattern beneath [child] so every
  /// preset stamps its own texture on the face. Skipped for image
  /// backgrounds, which carry their own artwork.
  Widget _withPattern(Widget child, BankThemeData bankTheme) {
    final pattern = bankTheme.cardPattern;
    if (pattern == BankCardPattern.none || widget.backgroundImage != null) {
      return child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: BankCardPatternPainter(
              pattern: pattern,
              color: bankTheme.cardPatternColor ??
                  bankTheme.onPrimary.withValues(alpha: 0.08),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _wrapSurface({
    required Widget child,
    required BankThemeData bankTheme,
    required double cardWidth,
    required double cardHeight,
  }) {
    final borderRadius = _resolvedRadius(bankTheme);
    final content = _withPattern(child, bankTheme);

    Widget surface;
    if (widget.backgroundImage != null) {
      // Image background overrides the surface enum.
      surface = Container(
        width: cardWidth,
        height: cardHeight,
        decoration: _buildImageDecoration(bankTheme),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    } else {
      switch (widget.surface) {
        case BankCardSurface.flatColor:
          surface = Container(
            width: cardWidth,
            height: cardHeight,
            decoration: _buildFlatColorDecoration(bankTheme),
            clipBehavior: Clip.antiAlias,
            child: content,
          );

        case BankCardSurface.gradient:
          surface = Container(
            width: cardWidth,
            height: cardHeight,
            decoration: _buildGradientDecoration(bankTheme),
            clipBehavior: Clip.antiAlias,
            child: content,
          );

        case BankCardSurface.animatedMesh:
          surface = RepaintBoundary(
            child: _AnimatedMeshCard(
              width: cardWidth,
              height: cardHeight,
              primaryColor: widget.primaryColor ?? bankTheme.primary,
              secondaryColor: widget.secondaryColor ?? bankTheme.primaryVariant,
              borderRadius: borderRadius,
              child: content,
            ),
          );

        case BankCardSurface.metallicSweep:
          surface = RepaintBoundary(
            child: _MetallicSweepCard(
              width: cardWidth,
              height: cardHeight,
              primaryColor: widget.primaryColor ?? bankTheme.primary,
              secondaryColor: widget.secondaryColor ?? bankTheme.primaryVariant,
              borderRadius: borderRadius,
              child: content,
            ),
          );
      }
    }

    // The hero shadow is hoisted out of the per-surface decorations so every
    // mode — including mesh, metallic, and image — keeps its depth grounding.
    final shadow = _resolvedShadow(bankTheme);
    if (shadow.isEmpty) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow,
      ),
      child: surface,
    );
  }

  // ---------------------------------------------------------------------------
  // Frozen overlay
  // ---------------------------------------------------------------------------

  Widget _buildFrozenOverlay(BankThemeData bankTheme) {
    final resolvedFrozenIcon = widget.frozenIcon ?? Icons.ac_unit_outlined;
    final resolvedForeground = widget.foregroundColor ?? bankTheme.onPrimary;
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: _resolvedRadius(bankTheme),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: ColoredBox(
            color: Colors.blueGrey.withValues(alpha: 0.35),
            child: Center(
              child: Icon(
                resolvedFrozenIcon,
                color: resolvedForeground,
                size: 48,
                semanticLabel: widget.frozenSemanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Front face
  // ---------------------------------------------------------------------------

  /// Resolves the network mark for the front face:
  /// asset > [BankVirtualCardWidget.network] > parsed legacy label > custom
  /// label text > nothing.
  Widget? _networkMark(Color textPrimary) {
    if (widget.networkLogoAsset != null) {
      return Image.asset(
        widget.networkLogoAsset!,
        height: 28,
        fit: BoxFit.contain,
      );
    }
    final network = widget.network ?? _parseNetworkLabel(widget.networkLabel);
    if (network != null) {
      if (network == BankCardNetwork.generic) return null;
      return BankNetworkBadge(
        network: network,
        // Tint only the monochrome Visa wordmark; Mastercard and Amex keep
        // their brand colours.
        color: network == BankCardNetwork.visa ? textPrimary : null,
        markBuilder: widget.markBuilder,
      );
    }
    if (widget.networkLabel.isEmpty) return null;
    // Documented escape hatch for domestic schemes: upright, tracked — never
    // synthetic italic.
    return Text(
      widget.networkLabel,
      style: BankTokens.labelLarge
          .copyWith(color: textPrimary, letterSpacing: 1)
          .merge(widget.networkLabelStyle),
    );
  }

  static BankCardNetwork? _parseNetworkLabel(String label) =>
      switch (label.trim().toLowerCase()) {
        'visa' => BankCardNetwork.visa,
        'mastercard' => BankCardNetwork.mastercard,
        'amex' || 'american express' => BankCardNetwork.amex,
        _ => null,
      };

  /// Horizontal space the front face reserves at the top-end corner so face
  /// content never collides with the built-in flip button overlay.
  double _cornerClearance(EdgeInsetsGeometry resolvedPadding) {
    if (widget.flipTrigger != BankFlipTrigger.builtInButton) return 0;
    final dir = Directionality.of(context);
    final pad = resolvedPadding.resolve(dir);
    final endPad = dir == TextDirection.rtl ? pad.left : pad.right;
    final clearance = BankFlipCard.builtInButtonClearance - endPad;
    return clearance > 0 ? clearance : 0;
  }

  Widget _buildFrontFace(
    BankThemeData bankTheme,
    double cardWidth,
    double cardHeight,
  ) {
    final textPrimary = widget.foregroundColor ?? bankTheme.onPrimary;
    final labelInk = textPrimary.withValues(alpha: 0.70);
    final resolvedPadding =
        widget.padding ?? const EdgeInsets.all(BankTokens.space5);
    final cornerClearance = _cornerClearance(resolvedPadding);
    final mark = _networkMark(textPrimary);

    final captionStyle = BankTokens.caption.copyWith(
      color: labelInk,
      letterSpacing: 1.2,
    );

    return _wrapSurface(
      bankTheme: bankTheme,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: chip + network mark ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BankCardChip(width: 38, height: 28),
                if (mark != null)
                  Padding(
                    // Reflow start-ward when the built-in flip button
                    // occupies the top-end corner.
                    padding: EdgeInsetsDirectional.only(end: cornerClearance),
                    child: mark,
                  ),
              ],
            ),

            const Spacer(),

            // ── Card number (masked), at the optical centre ───────────────
            Text.rich(
              bankMaskedPanSpan(
                _formatMaskedNumber(widget.account.maskedNumber),
                BankTokens.numeralMedium
                    .copyWith(
                      color: textPrimary,
                      letterSpacing: 2.4,
                      height: 1,
                    )
                    .merge(widget.cardNumberStyle),
              ),
              textDirection: TextDirection.ltr,
            ),

            const Spacer(),

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
                        widget.cardholderLabel,
                        style: captionStyle.merge(widget.cardholderLabelStyle),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.cardholderName ?? widget.account.name,
                        style: BankTokens.labelLarge
                            .copyWith(color: textPrimary)
                            .merge(widget.cardholderNameStyle),
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
                        widget.expiryLabel,
                        style: captionStyle.merge(widget.expiryLabelStyle),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.expiryDate!,
                        style: BankTokens.labelLarge.copyWith(
                          color: textPrimary,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ).merge(widget.expiryDateStyle),
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

  Widget _buildBackFace(
    BankThemeData bankTheme,
    double cardWidth,
    double cardHeight,
  ) {
    final textPrimary = widget.foregroundColor ?? bankTheme.onPrimary;
    final textSecondary = textPrimary.withValues(alpha: 0.75);

    return _wrapSurface(
      bankTheme: bankTheme,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
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
                            style: BankTokens.bodySmall
                                .copyWith(
                                  color: const Color(0xFF333333),
                                  fontStyle: FontStyle.italic,
                                )
                                .merge(widget.signatureStyle),
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
                        widget.cvvPlaceholder,
                        style: BankTokens.labelLarge
                            .copyWith(
                              color: const Color(0xFF333333),
                              letterSpacing: 4,
                            )
                            .merge(widget.cvvStyle),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: BankTokens.space1),

                Text(
                  widget.cvvLabel,
                  style: BankTokens.labelSmall
                      .copyWith(color: textSecondary)
                      .merge(widget.cvvLabelStyle),
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
                    style: BankTokens.labelMedium
                        .copyWith(color: textPrimary)
                        .merge(widget.bankNameStyle),
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
  // Sizing
  // ---------------------------------------------------------------------------

  /// Resolves the rendered width: an explicit `width` wins; otherwise the
  /// card fills the available width up to `maxWidth` (340 by default).
  double _resolveWidth(BoxConstraints constraints) {
    final fixedWidth = widget.width;
    if (fixedWidth != null) return fixedWidth;
    final maxWidth = widget.maxWidth ?? _defaultWidth;
    return constraints.hasBoundedWidth
        ? min(constraints.maxWidth, maxWidth)
        : maxWidth;
  }

  /// Resolves the rendered height: an explicit `height` wins; otherwise the
  /// height preserves the ISO 7810 ID-1 card ratio ([kBankCardAspectRatio])
  /// so this card matches `BankPaymentCard` proportions.
  double _resolveHeight(double cardWidth) =>
      widget.height ?? cardWidth / kBankCardAspectRatio;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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

  Widget _buildCard(
    BuildContext context,
    double cardWidth,
    double cardHeight,
  ) {
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
              cardWidth: cardWidth,
              cardHeight: cardHeight,
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
              transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1),
              child: _buildFaceStack(
                context: context,
                bankTheme: bankTheme,
                isFront: false,
                isFrozen: isFrozen,
                cardWidth: cardWidth,
                cardHeight: cardHeight,
              ),
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
            // Directional so the button tracks the top-END corner in RTL;
            // the front face reserves this corner via [_cornerClearance].
            PositionedDirectional(
              top: BankFlipCard.builtInButtonInset,
              end: BankFlipCard.builtInButtonInset,
              child: widget.flipButtonBuilder != null
                  ? widget.flipButtonBuilder!(context, widget.onFlip ?? () {})
                  : _VirtualCardFlipButton(
                      onFlip: widget.onFlip ?? () {},
                      icon: widget.flipIcon ?? Icons.flip_outlined,
                      semanticLabel: widget.flipButtonSemanticLabel,
                    ),
            ),
          ],
        );
      case BankFlipTrigger.external:
        card = animated;
    }

    return Semantics(
      label: widget.semanticLabel ??
          'Card ending ${widget.account.maskedNumber}, '
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
    required double cardWidth,
    required double cardHeight,
  }) {
    final face = isFront
        ? _buildFrontFace(bankTheme, cardWidth, cardHeight)
        : _buildBackFace(bankTheme, cardWidth, cardHeight);

    if (isFrozen) {
      return Stack(
        children: [
          face,
          _buildFrozenOverlay(bankTheme),
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
  const _VirtualCardFlipButton({
    required this.onFlip,
    required this.icon,
    required this.semanticLabel,
  });

  final VoidCallback onFlip;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        child: InkWell(
          onTap: onFlip,
          borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space2),
            child: Icon(
              icon,
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
