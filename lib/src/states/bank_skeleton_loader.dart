import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';
import '../../saving.dart';
import '../common/bank_surface_depth.dart';
import '../saving/bank_savings_pot_card.dart';
import '../saving/saving.dart';

// ---------------------------------------------------------------------------
// Anatomy constants
//
// Each figure mirrors the real component the placeholder stands in for, so the
// layout does not reflow the instant data arrives. They are dimensions of
// existing widgets rather than new design decisions: `_transactionRowHeight` is
// BankTransactionListTile's own `minHeight`, `_emblemSize` its leading avatar
// diameter, and so on.
// ---------------------------------------------------------------------------

const double _accountCardHeight = 200;
const double _transactionRowHeight = 72;
const double _listRowHeight = 72;
const double _potCardHeight = 120;
const double _potRingSize = 72;
const double _emblemSize = 40;
const double _genericHeight = 80;
const double _chartPlotHeight = 132;
const double _progressTrackHeight = 6;

/// Placeholder standing in for a body / label line.
const double _lineBody = 14;

/// Placeholder standing in for a caption or metadata line.
const double _lineCaption = 12;

/// Placeholder standing in for a micro-label (axis ticks, status pips).
const double _lineMicro = 10;

/// Placeholder standing in for a hero numeral.
const double _lineHero = 40;

/// Fully-round corners, for avatar and chip placeholders.
const BorderRadius _pill =
    BorderRadius.all(Radius.circular(BankTokens.radiusFull));

/// Describes the shape of the skeleton placeholder to render.
///
/// Every variant mirrors the anatomy — block sizes, gaps, and card chrome — of
/// the component it stands in for. A skeleton that is only *about* the right
/// size causes a visible reflow the moment real data lands, which reads as a
/// second loading event rather than as a resolution.
enum BankSkeletonVariant {
  /// Mimics a [BankAccountCard]: a card surface carrying a balance block and
  /// two meta lines.
  accountCard,

  /// Mimics a [BankTransactionListTile]: a 72 px row with a 40 px emblem
  /// circle, two text lines, and a trailing amount column.
  transactionTile,

  /// Mimics a [BankSavingsPotCard]: a card surface with a progress-ring area,
  /// two lines, and a progress track.
  potCard,

  /// A plain rectangle sized to [BankSkeletonLoader.width] ×
  /// [BankSkeletonLoader.height] (defaults to `∞ × 80`).
  generic,

  /// A generic Bank UI Kit list row: leading emblem, title and subtitle lines,
  /// and a trailing affordance. Use it for any tile-shaped list that is not a
  /// transaction feed.
  listTile,

  /// A generic content card: header glyph and title, two body lines, and a
  /// footer line, on a real card surface.
  card,

  /// A balance / hero block: micro-label, hero numeral, and two chips.
  /// Deliberately shell-less — it stands in for a screen header such as
  /// [BankPeekBalance], not for a card.
  balanceHero,

  /// A chart panel: title line, a bar plot area, a baseline rule, and axis
  /// tick labels, on a real card surface.
  chart,
}

/// Shimmer-effect placeholder that takes the shape of common Bank UI Kit
/// surfaces while data loads.
///
/// The shimmer is a **lighter** band travelling across the placeholder blocks,
/// composited with [BlendMode.srcATop] so it paints only where a placeholder
/// actually is: the highlight travels *through* the shapes and never appears in
/// the gaps between them. Stacked tiles are phase-offset by [phaseOffset], so a
/// list ripples instead of pulsing in unison.
///
/// Under [MediaQuery.disableAnimationsOf] the widget renders static
/// placeholders and no animation controller runs at all — a shimmer is pure
/// decoration, and users who asked for stillness should get nothing moving.
///
/// When [count] > 1 the widget stacks [count] copies vertically with
/// [itemSpacing] gaps between them. Pass [shape] to shimmer a bespoke
/// composition instead of a [variant]; build it out of [BankSkeletonBox] so the
/// fill colour matches the built-in shapes.
///
/// Wrapped in a [Semantics] carrying [semanticLabel], with its children kept
/// out of the accessibility tree via [ExcludeSemantics].
///
/// ```dart
/// BankSkeletonLoader(
///   variant: BankSkeletonVariant.transactionTile,
///   count: 5,
/// )
/// ```
class BankSkeletonLoader extends StatefulWidget {
  /// Which shape to mimic. Ignored when [shape] is non-null.
  final BankSkeletonVariant variant;

  /// How many tiles to show stacked vertically.
  final int count;

  /// Explicit width for [BankSkeletonVariant.generic]. Defaults to
  /// [double.infinity].
  final double? width;

  /// Explicit height for [BankSkeletonVariant.generic]. Defaults to `80`.
  final double? height;

  /// Overrides the placeholder fill. Defaults to [BankThemeData.onSurface] at
  /// [BankTokens.alphaSoft] composited over [surfaceColor] — an opaque tone
  /// rather than a translucent wash, so the block does not change value with
  /// whatever it happens to sit on.
  final Color? baseColor;

  /// Overrides the travelling highlight, painted *over* [baseColor].
  ///
  /// Defaults to a translucent [BankTokens.neutral0] in both brightnesses,
  /// because a shimmer reads as a light source sweeping the surface. Only the
  /// alpha differs by brightness: a light surface sits close to white already,
  /// so it needs a strong wash to shift at all, while the same wash on a dark
  /// surface would blow the placeholder out.
  final Color? highlightColor;

  /// The surface the placeholder is painted on, used to resolve [baseColor] and
  /// the highlight strength. Defaults to [BankThemeData.surface]; pass
  /// [BankThemeData.background] when the skeleton sits on the bare canvas.
  final Color? surfaceColor;

  /// Overrides the placeholder corner radius. Defaults to
  /// [BankThemeData.cardRadius] for the card variants and
  /// [BankTokens.radiusMedium] otherwise.
  final BorderRadius? radius;

  /// Vertical gap between stacked copies. Defaults to [BankTokens.space2].
  final double? itemSpacing;

  /// Duration of one shimmer sweep. Defaults to twice
  /// [BankTokens.durationXSlow] — a shimmer is ambient rather than reactive,
  /// so it runs slower than any interaction transition in the kit.
  final Duration? animationDuration;

  /// Fraction of one sweep by which each stacked tile lags the one above it.
  ///
  /// Non-zero by default: tiles sweeping in unison read as a single slab
  /// flashing (a rendering glitch), while a staggered list reads as loading.
  final double phaseOffset;

  /// A bespoke placeholder composition to shimmer instead of [variant].
  ///
  /// Compose it from [BankSkeletonBox] so the blocks pick up the resolved fill
  /// colour automatically.
  final Widget? shape;

  /// Semantics label announced while loading. Defaults to 'Loading…'.
  final String semanticLabel;

  const BankSkeletonLoader({
    super.key,
    this.variant = BankSkeletonVariant.generic,
    this.count = 1,
    this.width,
    this.height,
    this.baseColor,
    this.highlightColor,
    this.surfaceColor,
    this.radius,
    this.itemSpacing,
    this.animationDuration,
    this.phaseOffset = 0.12,
    this.shape,
    this.semanticLabel = 'Loading…',
  })  : assert(count >= 1, 'count must be at least 1'),
        assert(
          phaseOffset >= 0 && phaseOffset < 1,
          'phaseOffset is a fraction of one sweep, in [0, 1)',
        );

  @override
  State<BankSkeletonLoader> createState() => _BankSkeletonLoaderState();
}

class _BankSkeletonLoaderState extends State<BankSkeletonLoader>
    with SingleTickerProviderStateMixin {
  static final Duration _defaultSweep = BankTokens.durationXSlow * 2;

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? _defaultSweep,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(BankSkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _controller
        ..stop()
        ..duration = widget.animationDuration ?? _defaultSweep;
      _syncTicker();
    }
  }

  /// Keeps the ticker in step with the reduced-motion setting.
  ///
  /// Under reduced motion the controller is *stopped*, not merely ignored: a
  /// repeating ticker would keep the subtree rebuilding every frame for a
  /// decoration nobody is going to see.
  void _syncTicker() {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final surface = widget.surfaceColor ?? theme.surface;
    final base = widget.baseColor ?? _defaultBase(theme, surface);
    final highlight = widget.highlightColor ?? _defaultHighlight(surface);
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final spacing = widget.itemSpacing ?? BankTokens.space2;

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: _BankSkeletonScope(
            base: base,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < widget.count; index++)
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : spacing),
                    child: _tile(
                      index: index,
                      theme: theme,
                      highlight: highlight,
                      direction: direction,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _defaultBase(BankThemeData theme, Color surface) =>
      Color.alphaBlend(
        theme.onSurface.withValues(alpha: BankTokens.alphaSoft),
        surface,
      );

  static Color _defaultHighlight(Color surface) {
    final isDark =
        ThemeData.estimateBrightnessForColor(surface) == Brightness.dark;
    return BankTokens.neutral0.withValues(
      alpha: isDark ? BankTokens.alphaMuted : BankTokens.alphaScrim,
    );
  }

  /// One stacked copy: placeholder content, the shimmer over it, and — for the
  /// card variants — the real card chrome around the outside.
  Widget _tile({
    required int index,
    required BankThemeData theme,
    required Color highlight,
    required TextDirection direction,
  }) {
    final content = widget.shape ?? _content(index);

    final shimmered = _reduceMotion
        ? content
        : AnimatedBuilder(
            animation: _controller,
            // Each tile lags the one above it, so a stack ripples rather than
            // flashing as one slab.
            builder: (context, child) => _ShimmerMask(
              phase: (_controller.value + index * widget.phaseOffset) % 1.0,
              highlight: highlight,
              textDirection: direction,
              child: child!,
            ),
            child: content,
          );

    // A host-supplied shape is placed exactly as given: the kit has no idea
    // what chrome it belongs in.
    if (widget.shape != null) return shimmered;
    return _shell(theme, shimmered);
  }

  /// The placeholder blocks for [BankSkeletonLoader.variant] — everything the
  /// shimmer travels through.
  Widget _content(int index) {
    switch (widget.variant) {
      case BankSkeletonVariant.accountCard:
        return const _AccountCardContent();
      case BankSkeletonVariant.transactionTile:
        return _TransactionRowContent(index: index);
      case BankSkeletonVariant.potCard:
        return const _PotCardContent();
      case BankSkeletonVariant.listTile:
        return _ListRowContent(index: index);
      case BankSkeletonVariant.card:
        return const _CardContent();
      case BankSkeletonVariant.balanceHero:
        return const _BalanceHeroContent();
      case BankSkeletonVariant.chart:
        return const _ChartContent();
      case BankSkeletonVariant.generic:
        return BankSkeletonBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? _genericHeight,
          borderRadius:
              widget.radius ?? BorderRadius.circular(BankTokens.radiusMedium),
        );
    }
  }

  /// Fixed height of the variant's card shell, or `null` when it has none (the
  /// row and hero variants sit directly on the host's surface) or when it sizes
  /// itself to its content.
  double? get _shellHeight => switch (widget.variant) {
        BankSkeletonVariant.accountCard => _accountCardHeight,
        BankSkeletonVariant.potCard => _potCardHeight,
        _ => null,
      };

  bool get _hasShell => switch (widget.variant) {
        BankSkeletonVariant.accountCard ||
        BankSkeletonVariant.potCard ||
        BankSkeletonVariant.card ||
        BankSkeletonVariant.chart =>
          true,
        _ => false,
      };

  /// The real card chrome — surface colour, theme radius, and the kit's
  /// resolved depth — drawn *outside* the shimmer mask.
  ///
  /// The chrome is not a placeholder: it is already exactly what the loaded
  /// card will look like, so lighting it up with the sweep would misreport
  /// settled pixels as pending ones.
  Widget _shell(BankThemeData theme, Widget child) {
    if (!_hasShell) return child;
    final depth = BankSurfaceDepth.resolve(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: widget.radius ?? theme.cardRadius,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: SizedBox(
        width: double.infinity,
        height: _shellHeight,
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer mask
// ---------------------------------------------------------------------------

/// Composites a soft highlight band over [child] with [BlendMode.srcATop].
///
/// `srcATop` is the whole trick: the band paints only where the child is
/// already opaque, so it travels through the placeholder blocks and leaves the
/// gaps between them untouched. A band painted across the *whole* tile instead
/// reads as a rectangle flashing on top of the content rather than as light
/// moving across it.
class _ShimmerMask extends StatelessWidget {
  const _ShimmerMask({
    required this.phase,
    required this.highlight,
    required this.textDirection,
    required this.child,
  });

  /// How far through one sweep, in `[0, 1)`.
  final double phase;
  final Color highlight;
  final TextDirection textDirection;
  final Widget child;

  /// How far past each edge the band travels, as a multiple of the placeholder
  /// width. Above 1 the band spends a beat fully off-canvas between sweeps, so
  /// the loop reads as a repeated pass rather than as a strobe.
  static const double _overshoot = 1.25;

  /// Colour stops of the band: transparent shoulders, one soft peak.
  static const List<double> _stops = [0, 0.35, 0.5, 0.65, 1];

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        // The band is symmetric, so only its travel direction has to mirror:
        // under RTL the sweep runs end-to-start like everything else.
        final sign = textDirection == TextDirection.rtl ? -1.0 : 1.0;
        final dx = bounds.width * _overshoot * (2 * phase - 1) * sign;
        final transparent = highlight.withValues(alpha: 0);
        return LinearGradient(
          colors: [
            transparent,
            transparent,
            highlight,
            transparent,
            transparent,
          ],
          stops: _stops,
          transform: _BandTransform(dx),
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// Slides the highlight band along the x axis.
class _BandTransform extends GradientTransform {
  const _BandTransform(this.dx);

  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

// ---------------------------------------------------------------------------
// Fill scope
// ---------------------------------------------------------------------------

/// Carries the resolved placeholder fill down to every [BankSkeletonBox] in a
/// loader's subtree, so a host-composed [BankSkeletonLoader.shape] matches the
/// built-in variants without a colour being threaded through by hand.
class _BankSkeletonScope extends InheritedWidget {
  const _BankSkeletonScope({required this.base, required super.child});

  final Color base;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BankSkeletonScope>()?.base;

  @override
  bool updateShouldNotify(_BankSkeletonScope oldWidget) =>
      oldWidget.base != base;
}

// ---------------------------------------------------------------------------
// Public building block
// ---------------------------------------------------------------------------

/// A single solid placeholder block: the atom every [BankSkeletonVariant] is
/// built from.
///
/// Exposed so a host can compose an anatomy the kit does not ship. Pass the
/// result to [BankSkeletonLoader.shape] and it inherits that loader's fill
/// colour and shimmer; used outside a loader it falls back to the same
/// theme-derived fill, so a one-off placeholder still matches the system.
///
/// ```dart
/// BankSkeletonLoader(
///   shape: const Row(
///     children: [
///       BankSkeletonBox(width: 40, height: 40),
///       SizedBox(width: BankTokens.space3),
///       Expanded(child: BankSkeletonBox(height: 14)),
///     ],
///   ),
/// )
/// ```
class BankSkeletonBox extends StatelessWidget {
  /// Width of the block. `null` (the default) fills the available width, so the
  /// parent must impose a bounded width.
  final double? width;

  /// Height of the block. `null` fills the available height.
  final double? height;

  /// Corner radius. Defaults to [BankTokens.radiusSmall]; pass
  /// [BankTokens.radiusFull] for avatar and chip placeholders.
  final BorderRadius? borderRadius;

  /// Overrides the fill. Defaults to the enclosing [BankSkeletonLoader]'s
  /// resolved base colour, or a theme-derived equivalent outside one.
  final Color? color;

  const BankSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fill =
        color ?? _BankSkeletonScope.maybeOf(context) ?? _themeFill(context);
    // `BoxConstraints.expand` leaves an unspecified axis infinite, and
    // ConstrainedBox then clamps it to whatever the parent allows — which is
    // how a null dimension becomes "fill".
    return ConstrainedBox(
      constraints: BoxConstraints.expand(
        width: width == double.infinity ? null : width,
        height: height,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius:
              borderRadius ?? BorderRadius.circular(BankTokens.radiusSmall),
        ),
      ),
    );
  }

  static Color _themeFill(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Color.alphaBlend(
      theme.onSurface.withValues(alpha: BankTokens.alphaSoft),
      theme.surface,
    );
  }
}

// ---------------------------------------------------------------------------
// Shape helpers
// ---------------------------------------------------------------------------

/// A text-line placeholder occupying [widthFactor] of the available width.
///
/// Fractional rather than fixed so a line never overflows a narrow tile and
/// keeps its proportions when the host scales the layout.
Widget _line(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: BankSkeletonBox(height: height),
    );

/// Deterministic per-row variation in line length.
///
/// Identical line widths down a list read as a table of empty cells; a little
/// variation reads as text that has not arrived yet.
double _jitter(int index, List<double> steps) => steps[index % steps.length];

const List<double> _titleSteps = [0.62, 0.48, 0.55, 0.42];
const List<double> _subtitleSteps = [0.34, 0.42, 0.28, 0.38];

// ---------------------------------------------------------------------------
// Account card content
// ---------------------------------------------------------------------------

class _AccountCardContent extends StatelessWidget {
  const _AccountCardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Account name, and the status chip pushed opposite it.
            Expanded(child: _line(0.34, _lineCaption)),
            const BankSkeletonBox(
              width: BankTokens.space8,
              height: BankTokens.space5,
              borderRadius: _pill,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance figure.
            _line(0.56, BankTokens.space8),
            const SizedBox(height: BankTokens.space3),
            _line(0.4, _lineBody),
            const SizedBox(height: BankTokens.space2),
            _line(0.28, _lineCaption),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction row content
// ---------------------------------------------------------------------------

class _TransactionRowContent extends StatelessWidget {
  const _TransactionRowContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _transactionRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        ),
        child: Row(
          children: [
            const BankSkeletonBox(
              width: _emblemSize,
              height: _emblemSize,
              borderRadius: _pill,
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(_jitter(index, _titleSteps), _lineBody),
                  const SizedBox(height: BankTokens.space2),
                  _line(_jitter(index, _subtitleSteps), _lineCaption),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            // Trailing amount column: the kit aligns amount over status.
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BankSkeletonBox(width: BankTokens.space16, height: _lineBody),
                SizedBox(height: BankTokens.space1),
                BankSkeletonBox(width: BankTokens.space10, height: _lineMicro),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic list row content
// ---------------------------------------------------------------------------

class _ListRowContent extends StatelessWidget {
  const _ListRowContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _listRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        ),
        child: Row(
          children: [
            const BankSkeletonBox(
              width: _emblemSize,
              height: _emblemSize,
              borderRadius: _pill,
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(_jitter(index, _titleSteps), _lineBody),
                  const SizedBox(height: BankTokens.space2),
                  _line(_jitter(index, _subtitleSteps), _lineCaption),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            // Trailing affordance: chevron, toggle, or value glyph.
            const BankSkeletonBox(
              width: BankTokens.iconMedium,
              height: BankTokens.iconMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pot card content
// ---------------------------------------------------------------------------

class _PotCardContent extends StatelessWidget {
  const _PotCardContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BankSkeletonBox(
          width: _potRingSize,
          height: _potRingSize,
          borderRadius: _pill,
        ),
        const SizedBox(width: BankTokens.space4),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(0.66, BankTokens.space4),
              const SizedBox(height: BankTokens.space2),
              _line(0.42, _lineCaption),
              const SizedBox(height: BankTokens.space3),
              const BankSkeletonBox(
                height: _progressTrackHeight,
                borderRadius: _pill,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Generic content-card content
// ---------------------------------------------------------------------------

class _CardContent extends StatelessWidget {
  const _CardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BankSkeletonBox(
              width: BankTokens.iconXLarge,
              height: BankTokens.iconXLarge,
              borderRadius: _pill,
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(child: _line(0.5, _lineBody)),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        const BankSkeletonBox(height: _lineCaption),
        const SizedBox(height: BankTokens.space2),
        _line(0.82, _lineCaption),
        const SizedBox(height: BankTokens.space4),
        _line(0.32, _lineBody),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Balance / hero content
// ---------------------------------------------------------------------------

class _BalanceHeroContent extends StatelessWidget {
  const _BalanceHeroContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Micro-label above the figure.
        _line(0.3, BankTokens.space3),
        const SizedBox(height: BankTokens.space3),
        _line(0.68, _lineHero),
        const SizedBox(height: BankTokens.space3),
        const Row(
          children: [
            BankSkeletonBox(
              width: BankTokens.space16 + BankTokens.space6,
              height: BankTokens.space6,
              borderRadius: _pill,
            ),
            SizedBox(width: BankTokens.space2),
            BankSkeletonBox(
              width: BankTokens.space16,
              height: BankTokens.space6,
              borderRadius: _pill,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart content
// ---------------------------------------------------------------------------

/// Relative bar heights. Uneven on purpose: a row of equal bars reads as a
/// loaded chart of identical values rather than as a pending one.
const List<double> _barSteps = [0.45, 0.72, 0.38, 0.9, 0.6, 0.52, 0.8];

class _ChartContent extends StatelessWidget {
  const _ChartContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(0.38, _lineBody),
        const SizedBox(height: BankTokens.space5),
        SizedBox(
          height: _chartPlotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _barSteps.length; i++) ...[
                if (i > 0) const SizedBox(width: BankTokens.space2),
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: _barSteps[i],
                    alignment: Alignment.bottomCenter,
                    child: const BankSkeletonBox(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(BankTokens.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: BankTokens.space3),
        // Axis baseline.
        const BankSkeletonBox(height: BankTokens.hairlineWidth),
        const SizedBox(height: BankTokens.space2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BankSkeletonBox(width: BankTokens.space6, height: _lineMicro),
            BankSkeletonBox(width: BankTokens.space6, height: _lineMicro),
            BankSkeletonBox(width: BankTokens.space6, height: _lineMicro),
            BankSkeletonBox(width: BankTokens.space6, height: _lineMicro),
          ],
        ),
      ],
    );
  }
}
