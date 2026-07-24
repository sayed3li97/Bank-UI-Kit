import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_pressable.dart';
import '../models/models.dart';
import '../theme/bank_theme_data.dart';
import '../theme/card_pattern.dart';
import '../theme/tokens.dart';
import 'bank_card_network_badge.dart';

/// A modern, layered payment-card face with a full-bleed **artwork slot**.
///
/// This is the flexible card surface behind neobank "My Cards" screens: a base
/// gradient (or flat colour), an optional full-bleed [artwork] Widget beneath
/// the UI (character art, a pattern, a photo — the kit bundles no assets, you
/// supply the widget), a legibility [scrim], then the card anatomy composited
/// on top: an EMV chip, a contactless mark, a [network] badge, a [label]
/// pill, the masked [maskedNumber], and the [holderName] / [expiry] row. An
/// optional [balance] renders on the face for account-style cards and honours
/// privacy mode.
///
/// Cards default to the ISO 7810 ID-1 aspect ratio (1.586) so they read as
/// real bank cards, and pair with `BankCardCarousel` for a swipeable wallet.
/// Every visual decision is an optional parameter defaulting to the theme.
///
/// ```dart
/// BankPaymentCard(
///   label: 'Everyday',
///   maskedNumber: '•••• 8695',
///   holderName: 'ALEX MORGAN',
///   expiry: '08/28',
///   network: BankCardNetwork.visa,
///   artwork: const MyCardArtwork(),
///   balance: Money.fromDouble(3565.00, 'GBP'),
/// )
/// ```
class BankPaymentCard extends StatelessWidget {
  const BankPaymentCard({
    super.key,
    this.label,
    this.maskedNumber,
    this.holderName,
    this.expiry,
    this.network = BankCardNetwork.generic,
    this.balance,
    this.balanceLabel = 'Balance',
    this.artwork,
    this.overlay,
    this.surfaceBuilder,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.showChip = true,
    this.chipColor,
    this.showContactless = true,
    this.contactlessIcon,
    this.numberless = false,
    this.scrim,
    this.radius,
    this.padding,
    this.shadow,
    this.aspectRatio = kBankCardAspectRatio,
    this.width,
    this.height,
    this.maxWidth,
    this.onTap,
    this.labelStyle,
    this.numberStyle,
    this.holderNameStyle,
    this.expiryStyle,
    this.captionStyle,
    this.balanceStyle,
    this.holderLabel = 'CARD HOLDER',
    this.expiryLabel = 'VALID THRU',
    this.semanticLabel,
  });

  /// Short human-readable card name / nickname (e.g. `'Everyday'`), shown as a
  /// pill top-left. Hidden when null.
  final String? label;

  /// Masked card number, e.g. `'•••• 8695'`. Hidden when null or [numberless].
  final String? maskedNumber;

  /// Cardholder name, bottom-left. Hidden when null.
  final String? holderName;

  /// Expiry `MM/YY`, bottom-right. Hidden when null.
  final String? expiry;

  /// The payment network mark shown top-right. [BankCardNetwork.generic] hides
  /// it.
  final BankCardNetwork network;

  /// Optional balance rendered on the card face. Masks under privacy mode.
  final Money? balance;

  /// Caption above [balance].
  final String balanceLabel;

  /// Full-bleed artwork widget painted beneath the card UI (illustration,
  /// pattern, photo). The kit ships no assets — supply your own widget.
  final Widget? artwork;

  /// Optional widget layered above the artwork but below the card UI (e.g. a
  /// brand emblem or foil overlay).
  final Widget? overlay;

  /// Escape hatch to wrap the base surface with a custom painted layer without
  /// touching the card UI. Receives the base surface as its child.
  final Widget Function(BuildContext context, Widget child)? surfaceBuilder;

  /// Base gradient. Defaults to [BankThemeData.cardSurfaceGradient], then
  /// [BankThemeData.accentGradient] (or a primary gradient) when both this
  /// and [backgroundColor] are null.
  final Gradient? gradient;

  /// Flat base colour, used when [gradient] is null.
  final Color? backgroundColor;

  /// Foreground colour for all card text/marks. Defaults to
  /// [BankThemeData.onPrimary].
  final Color? foregroundColor;

  /// Whether to draw the EMV chip.
  final bool showChip;

  /// Chip colour. Defaults to a gold tone.
  final Color? chipColor;

  /// Whether to draw the contactless mark.
  final bool showContactless;

  /// Overrides the contactless glyph.
  final IconData? contactlessIcon;

  /// Hide the number and expiry from the face (data revealed in-app).
  final bool numberless;

  /// Draw a bottom legibility scrim. Defaults to true when [artwork] is set.
  final bool? scrim;

  /// Card corner radius. Defaults to [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Inner padding. Defaults to [BankTokens.space5].
  final EdgeInsetsGeometry? padding;

  /// Card shadow. Defaults to [BankTokens.shadowFloatingFor] of the theme
  /// background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Aspect ratio (width / height). Defaults to [kBankCardAspectRatio] (1.586).
  /// Ignored when [height] is provided.
  final double aspectRatio;

  /// Fixed width. When null the card fills its constraints (up to [maxWidth]).
  final double? width;

  /// Fixed height. When set, [aspectRatio] is ignored.
  final double? height;

  /// Maximum width when [width] is null.
  final double? maxWidth;

  /// Tap handler for the whole card.
  final VoidCallback? onTap;

  /// Merged over the computed label-pill style.
  final TextStyle? labelStyle;

  /// Merged over the computed card-number style.
  final TextStyle? numberStyle;

  /// Merged over the computed cardholder-name style.
  final TextStyle? holderNameStyle;

  /// Merged over the computed expiry style.
  final TextStyle? expiryStyle;

  /// Merged over the computed caption style (holder/expiry/balance labels).
  final TextStyle? captionStyle;

  /// Merged over the computed balance style.
  final TextStyle? balanceStyle;

  /// Caption above [holderName].
  final String holderLabel;

  /// Caption above [expiry].
  final String expiryLabel;

  /// Overrides the computed semantics label.
  final String? semanticLabel;

  // Reference design width for the card face; scaled to the real card size.
  static const double _refWidth = 380;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final fg = foregroundColor ?? theme.onPrimary;
    final cardRadius = radius ?? theme.cardRadius;
    final showScrim = scrim ?? (artwork != null);

    final baseDecoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? theme.primary) : null,
      gradient: gradient ??
          (backgroundColor == null
              ? (theme.cardSurfaceGradient ??
                  theme.accentGradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primary, theme.primaryVariant],
                  ))
              : null),
    );

    Widget base = DecoratedBox(decoration: baseDecoration);
    if (surfaceBuilder != null) base = surfaceBuilder!(context, base);

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        base,
        // Brand-owned generative texture; artwork replaces it when present.
        if (theme.cardPattern != BankCardPattern.none && artwork == null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BankCardPatternPainter(
                  pattern: theme.cardPattern,
                  color: theme.cardPatternColor ??
                      theme.onPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        if (artwork != null)
          Positioned.fill(child: ExcludeSemantics(child: artwork)),
        if (showScrim)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.30),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        if (overlay != null)
          Positioned.fill(child: ExcludeSemantics(child: overlay)),
        // The face is laid out on a fixed reference canvas (same aspect as the
        // card) and scaled to fit, so a fully-populated card never overflows —
        // including inside a shrunk carousel item.
        Positioned.fill(
          child: FittedBox(
            child: SizedBox(
              width: _refWidth,
              height: _refWidth / aspectRatio,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(BankTokens.space5),
                child: _face(theme, fg),
              ),
            ),
          ),
        ),
      ],
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: shadow ??
            BankTokens.shadowFloatingFor(
              ThemeData.estimateBrightnessForColor(theme.background),
            ),
      ),
      child: ClipRRect(borderRadius: cardRadius, child: stack),
    );

    final sized = _sized(decorated);
    final resolvedSemanticLabel = semanticLabel ?? _semantics();

    if (onTap == null) {
      return Semantics(label: resolvedSemanticLabel, child: sized);
    }
    // Kit-wide pressed-scale / hover / focus treatment for tappable cards.
    return BankPressable(
      onTap: onTap,
      borderRadius: cardRadius,
      overlayColor: fg,
      semanticLabel: resolvedSemanticLabel,
      child: sized,
    );
  }

  String _semantics() {
    final parts = <String>[
      if (label != null) label!,
      'card',
      if (maskedNumber != null && !numberless) 'ending $maskedNumber',
    ];
    return parts.join(' ');
  }

  Widget _sized(Widget child) {
    if (height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    if (width != null) {
      return SizedBox(
        width: width,
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        var w = constraints.maxWidth;
        if (!w.isFinite) w = 340;
        if (maxWidth != null && w > maxWidth!) w = maxWidth!;
        return SizedBox(
          width: w,
          child: AspectRatio(aspectRatio: aspectRatio, child: child),
        );
      },
    );
  }

  Widget _face(BankThemeData theme, Color fg) {
    // Shared card-family micro-label treatment: tracked all-caps caption at
    // ~70% foreground alpha.
    final caption = BankTokens.caption
        .copyWith(
          color: fg.withValues(alpha: 0.70),
          letterSpacing: 1.2,
        )
        .merge(captionStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top block: label / network, then chip + contactless.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) _labelPill(fg),
                const Spacer(),
                if (network != BankCardNetwork.generic)
                  BankNetworkBadge(
                    network: network,
                    // Tint only the monochrome Visa wordmark; Mastercard and
                    // Amex keep their brand colours rather than adopting the
                    // card foreground.
                    color: network == BankCardNetwork.visa ? fg : null,
                  ),
              ],
            ),
            const SizedBox(height: BankTokens.space4),
            Row(
              children: [
                if (showChip) _chip(theme),
                if (showChip && showContactless)
                  const SizedBox(width: BankTokens.space3),
                if (showContactless)
                  Icon(
                    contactlessIcon ?? BankIcons.cardContactless,
                    color: fg.withValues(alpha: 0.9),
                    size: 22,
                  ),
              ],
            ),
          ],
        ),
        // Bottom block: balance, number, holder / expiry.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (balance != null) ...[
              Text(balanceLabel.toUpperCase(), style: caption),
              const SizedBox(height: 2),
              // The numeral base (tier size/weight, tabular figures) comes
              // from the balance-text size ramp; the caller style merges
              // over it.
              BankBalanceText(
                money: balance!,
                // Explicit against future default changes.
                // ignore: avoid_redundant_argument_values
                size: BankBalanceSize.large,
                style: TextStyle(color: fg).merge(balanceStyle),
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            if (!numberless && maskedNumber != null) ...[
              // Shared card-family PAN treatment (see `bankMaskedPanSpan`).
              Text.rich(
                bankMaskedPanSpan(
                  maskedNumber!,
                  BankTokens.numeralMedium
                      .copyWith(
                        color: fg,
                        letterSpacing: 2.4,
                        height: 1,
                      )
                      .merge(numberStyle),
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (holderName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(holderLabel, style: caption),
                        const SizedBox(height: 2),
                        Text(
                          holderName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BankTokens.labelLarge
                              .copyWith(color: fg, fontWeight: FontWeight.w700)
                              .merge(holderNameStyle),
                        ),
                      ],
                    ),
                  ),
                if (expiry != null && !numberless)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(expiryLabel, style: caption),
                      const SizedBox(height: 2),
                      Text(
                        expiry!,
                        textDirection: TextDirection.ltr,
                        style: BankTokens.labelLarge.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          // Tabular so the expiry block's edge is stable
                          // across carousel cards.
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ).merge(expiryStyle),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _labelPill(Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space3,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      ),
      child: Text(
        label!,
        style: BankTokens.labelMedium
            .copyWith(color: fg, fontWeight: FontWeight.w700)
            .merge(labelStyle),
      ),
    );
  }

  Widget _chip(BankThemeData theme) =>
      BankCardChip(width: 44, height: 32, color: chipColor);
}
