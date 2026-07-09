import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A swipeable "My Cards" carousel: a snapping [PageView] whose active card is
/// centred while its neighbours peek in from both edges and de-emphasise
/// (scale + fade) continuously as you swipe. A page-dot indicator sits below.
///
/// It is deliberately generic — you supply [itemCount] and an [itemBuilder]
/// (typically returning a `BankPaymentCard`) — and it reports the centred card
/// through [onCardChanged], so a balance-tile row or transaction list below can
/// re-bind to the selected card. Add a trailing "Add card" tile simply by
/// including it as your last item.
///
/// ```dart
/// BankCardCarousel(
///   itemCount: cards.length,
///   onCardChanged: (i) => setState(() => selected = i),
///   itemBuilder: (context, i) => BankPaymentCard(/* cards[i] */),
/// )
/// ```
class BankCardCarousel extends StatefulWidget {
  const BankCardCarousel({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.onCardChanged,
    this.initialIndex = 0,
    this.viewportFraction = 0.86,
    this.aspectRatio = kBankCardAspectRatio,
    this.minScale = 0.9,
    this.minOpacity = 0.55,
    this.itemGap = BankTokens.space3,
    this.showIndicator = true,
    this.indicatorSpacing = BankTokens.space4,
    this.activeDotColor,
    this.inactiveDotColor,
    this.maxCardWidth = 460,
  });

  /// Number of cards.
  final int itemCount;

  /// Builds the card at `index`.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Called with the newly centred card index when the page settles.
  final ValueChanged<int>? onCardChanged;

  /// The initially centred card.
  final int initialIndex;

  /// Fraction of the viewport each page occupies (controls neighbour peek).
  final double viewportFraction;

  /// Card aspect ratio (width / height). Defaults to [kBankCardAspectRatio].
  final double aspectRatio;

  /// Scale of the fully off-centre neighbours (1.0 = no shrink).
  final double minScale;

  /// Opacity of the fully off-centre neighbours (1.0 = no fade).
  final double minOpacity;

  /// Horizontal gap between adjacent cards.
  final double itemGap;

  /// Whether to show the page-dot indicator.
  final bool showIndicator;

  /// Gap between the cards and the indicator.
  final double indicatorSpacing;

  /// Active dot colour. Defaults to [BankThemeData.primary].
  final Color? activeDotColor;

  /// Inactive dot colour. Defaults to the outline colour.
  final Color? inactiveDotColor;

  /// Upper bound on a single card's width (keeps cards sane on wide screens).
  final double maxCardWidth;

  @override
  State<BankCardCarousel> createState() => _BankCardCarouselState();
}

class _BankCardCarouselState extends State<BankCardCarousel> {
  late final PageController _controller;
  late double _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = widget.initialIndex.toDouble();
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: widget.initialIndex,
    )..addListener(_onScroll);
  }

  void _onScroll() {
    final p = _controller.page;
    if (p != null && p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        var available = constraints.maxWidth;
        if (!available.isFinite) available = 360;
        final cardWidth = (available * widget.viewportFraction)
            .clamp(0.0, widget.maxCardWidth);
        final cardHeight = cardWidth / widget.aspectRatio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.itemCount,
                onPageChanged: (i) {
                  setState(() => _current = i);
                  widget.onCardChanged?.call(i);
                },
                itemBuilder: (context, index) {
                  final child = Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: widget.itemGap / 2),
                    child: Center(
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: widget.itemBuilder(context, index),
                      ),
                    ),
                  );
                  if (reduceMotion) return child;
                  final delta = (_page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (1 - widget.minScale) * delta;
                  final opacity = 1 - (1 - widget.minOpacity) * delta;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
              ),
            ),
            if (widget.showIndicator && widget.itemCount > 1) ...[
              SizedBox(height: widget.indicatorSpacing),
              _Indicator(
                count: widget.itemCount,
                current: _current,
                active: widget.activeDotColor ?? theme.primary,
                inactive: widget.inactiveDotColor ??
                    theme.outline.withValues(alpha: 0.9),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.count,
    required this.current,
    required this.active,
    required this.inactive,
  });

  final int count;
  final int current;
  final Color active;
  final Color inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: BankTokens.durationBase,
            curve: BankTokens.curveStandard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current ? active : inactive,
              borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            ),
          ),
      ],
    );
  }
}
