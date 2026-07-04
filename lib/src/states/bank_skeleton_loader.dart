import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';
import '../../saving.dart';
import '../saving/bank_savings_pot_card.dart';
import '../saving/saving.dart';

/// Describes the shape of the skeleton placeholder to render.
///
/// - [accountCard]: mimics a [BankAccountCard]: 200 px tall card with a
///   balance line and two text lines.
/// - [transactionTile]: mimics a [BankTransactionListTile]: 72 px tall row
///   with a 40 px avatar circle and two lines.
/// - [potCard]: mimics a [BankSavingsPotCard]: 120 px card with a circular
///   progress ring area.
/// - [generic]: a plain rectangle sized to [BankSkeletonLoader.width] ×
///   [BankSkeletonLoader.height] (defaults to `∞ × 80`).
enum BankSkeletonVariant { accountCard, transactionTile, potCard, generic }

/// Shimmer-effect placeholder that takes the shape of common Bank UI Kit
/// cards while data loads.
///
/// Implements a self-contained looping shimmer using an [AnimationController]
/// and a sweeping [LinearGradient]; no third-party shimmer package is required.
///
/// When [count] > 1, the widget stacks [count] copies vertically with
/// [BankTokens.space2] gaps between them.
///
/// Wrap inside a [Semantics] with `label: 'Loading…'` and excludes its
/// children from the accessibility tree via [ExcludeSemantics].
///
/// ```dart
/// BankSkeletonLoader(
///   variant: BankSkeletonVariant.transactionTile,
///   count: 5,
/// )
/// ```
class BankSkeletonLoader extends StatefulWidget {
  /// Which card shape to mimic.
  final BankSkeletonVariant variant;

  /// How many tiles to show stacked vertically.
  final int count;

  /// Explicit width for [BankSkeletonVariant.generic]. Defaults to
  /// [double.infinity].
  final double? width;

  /// Explicit height for [BankSkeletonVariant.generic]. Defaults to `80`.
  final double? height;

  /// Overrides the shimmer base colour. Defaults to
  /// [BankThemeData.onSurface] at 6% alpha.
  final Color? baseColor;

  /// Overrides the shimmer highlight colour. Defaults to
  /// [BankThemeData.onSurface] at 14% alpha.
  final Color? highlightColor;

  /// Overrides the placeholder corner radius. Defaults to
  /// [BankThemeData.cardRadius] for the card variants and
  /// [BankTokens.radiusMedium] otherwise.
  final BorderRadius? radius;

  /// Vertical gap between stacked copies. Defaults to
  /// [BankTokens.space2].
  final double? itemSpacing;

  /// Duration of one shimmer sweep. Defaults to 1400 milliseconds.
  final Duration? animationDuration;

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
    this.radius,
    this.itemSpacing,
    this.animationDuration,
    this.semanticLabel = 'Loading…',
  }) : assert(count >= 1, 'count must be at least 1');

  @override
  State<BankSkeletonLoader> createState() => _BankSkeletonLoaderState();
}

class _BankSkeletonLoaderState extends State<BankSkeletonLoader>
    with SingleTickerProviderStateMixin {
  static const Duration _defaultShimmerDuration = Duration(milliseconds: 1400);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? _defaultShimmerDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(BankSkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _controller
        ..stop()
        ..duration = widget.animationDuration ?? _defaultShimmerDuration
        ..repeat();
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

    final base = widget.baseColor ?? theme.onSurface.withValues(alpha: 0.06);
    final highlight =
        widget.highlightColor ?? theme.onSurface.withValues(alpha: 0.14);

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.count, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0
                          ? 0.0
                          : widget.itemSpacing ?? BankTokens.space2,
                    ),
                    child: _buildVariantShell(
                      context,
                      base: base,
                      highlight: highlight,
                      theme: theme,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVariantShell(
    BuildContext context, {
    required Color base,
    required Color highlight,
    required BankThemeData theme,
  }) {
    switch (widget.variant) {
      case BankSkeletonVariant.accountCard:
        return _AccountCardSkeleton(
          progress: _controller.value,
          base: base,
          highlight: highlight,
          cardRadius: widget.radius ?? theme.cardRadius,
        );
      case BankSkeletonVariant.transactionTile:
        return _TransactionTileSkeleton(
          progress: _controller.value,
          base: base,
          highlight: highlight,
          borderRadius:
              widget.radius ?? BorderRadius.circular(BankTokens.radiusMedium),
        );
      case BankSkeletonVariant.potCard:
        return _PotCardSkeleton(
          progress: _controller.value,
          base: base,
          highlight: highlight,
          cardRadius: widget.radius ?? theme.cardRadius,
        );
      case BankSkeletonVariant.generic:
        return _GenericSkeleton(
          progress: _controller.value,
          base: base,
          highlight: highlight,
          width: widget.width ?? double.infinity,
          height: widget.height ?? 80,
          borderRadius:
              widget.radius ?? BorderRadius.circular(BankTokens.radiusMedium),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Shimmer painter
// ---------------------------------------------------------------------------

/// Paints a sweeping shimmer gradient across the entire canvas area.
///
/// [progress] drives the horizontal sweep from -1.0 to +2.0 so the highlight
/// fully enters and exits the visible area in each loop.
class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter({
    required this.progress,
    required this.base,
    required this.highlight,
  });

  final double progress;
  final Color base;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    // Map progress [0, 1] → shimmer sweep from left-of-frame to right-of-frame.
    final sweep = -size.width + (size.width * 3 * progress);

    final gradient = LinearGradient(
      colors: [base, base, highlight, base, base],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      transform: _SweepGradientTransform(sweep),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.progress != progress ||
      old.base != base ||
      old.highlight != highlight;
}

/// Applies a horizontal translation to the gradient shader so the highlight
/// band sweeps across the painted area.
class _SweepGradientTransform implements GradientTransform {
  const _SweepGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

// ---------------------------------------------------------------------------
// Shape helpers
// ---------------------------------------------------------------------------

/// Clips a [CustomPaint] shimmer to a rounded shape and adds grey structural
/// block sub-widgets (circle, lines, etc.) painted on top of the shimmer.
Widget _shimmerClip({
  required BorderRadius borderRadius,
  required double width,
  required double height,
  required double progress,
  required Color base,
  required Color highlight,
  required Widget Function(double width, double height) overlay,
}) {
  return ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ShimmerPainter(
              progress: progress,
              base: base,
              highlight: highlight,
            ),
          ),
          overlay(width, height),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Account card skeleton (200 px tall, 16 px radius, balance + 2 lines)
// ---------------------------------------------------------------------------

class _AccountCardSkeleton extends StatelessWidget {
  const _AccountCardSkeleton({
    required this.progress,
    required this.base,
    required this.highlight,
    required this.cardRadius,
  });

  final double progress;
  final Color base;
  final Color highlight;
  final BorderRadius cardRadius;

  @override
  Widget build(BuildContext context) {
    return _shimmerClip(
      borderRadius: cardRadius,
      width: double.infinity,
      height: 200,
      progress: progress,
      base: base,
      highlight: highlight,
      overlay: (w, h) => Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BankTokens.space8),
            // Balance line
            _SkeletonBlock(
              width: 160,
              height: 28,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            ),
            const SizedBox(height: BankTokens.space3),
            // Label line 1
            _SkeletonBlock(
              width: 100,
              height: 14,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            ),
            const SizedBox(height: BankTokens.space2),
            // Label line 2
            _SkeletonBlock(
              width: 80,
              height: 14,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction tile skeleton (72 px, avatar + 2 lines)
// ---------------------------------------------------------------------------

class _TransactionTileSkeleton extends StatelessWidget {
  const _TransactionTileSkeleton({
    required this.progress,
    required this.base,
    required this.highlight,
    required this.borderRadius,
  });

  final double progress;
  final Color base;
  final Color highlight;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return _shimmerClip(
      borderRadius: borderRadius,
      width: double.infinity,
      height: 72,
      progress: progress,
      base: base,
      highlight: highlight,
      overlay: (w, h) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        ),
        child: Row(
          children: [
            // Avatar circle
            _SkeletonBlock(
              width: 40,
              height: 40,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(
                    width: double.infinity,
                    height: 14,
                    color: base,
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                  const SizedBox(height: BankTokens.space2),
                  _SkeletonBlock(
                    width: 100,
                    height: 12,
                    color: base,
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            _SkeletonBlock(
              width: 60,
              height: 14,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pot card skeleton (120 px, circular ring area)
// ---------------------------------------------------------------------------

class _PotCardSkeleton extends StatelessWidget {
  const _PotCardSkeleton({
    required this.progress,
    required this.base,
    required this.highlight,
    required this.cardRadius,
  });

  final double progress;
  final Color base;
  final Color highlight;
  final BorderRadius cardRadius;

  @override
  Widget build(BuildContext context) {
    return _shimmerClip(
      borderRadius: cardRadius,
      width: double.infinity,
      height: 120,
      progress: progress,
      base: base,
      highlight: highlight,
      overlay: (w, h) => Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Row(
          children: [
            // Circular progress ring placeholder
            _SkeletonBlock(
              width: 72,
              height: 72,
              color: base,
              borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            ),
            const SizedBox(width: BankTokens.space4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(
                    width: 120,
                    height: 16,
                    color: base,
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                  const SizedBox(height: BankTokens.space2),
                  _SkeletonBlock(
                    width: 80,
                    height: 12,
                    color: base,
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                  const SizedBox(height: BankTokens.space3),
                  _SkeletonBlock(
                    width: double.infinity,
                    height: 6,
                    color: base,
                    borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic skeleton
// ---------------------------------------------------------------------------

class _GenericSkeleton extends StatelessWidget {
  const _GenericSkeleton({
    required this.progress,
    required this.base,
    required this.highlight,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double progress;
  final Color base;
  final Color highlight;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return _shimmerClip(
      borderRadius: borderRadius,
      width: width,
      height: height,
      progress: progress,
      base: base,
      highlight: highlight,
      overlay: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Block helper
// ---------------------------------------------------------------------------

/// A solid-coloured rounded rectangle used as a structural element inside
/// skeleton variants. The shimmer gradient from the parent [Stack] bleeds
/// through because this widget is painted on top of the shimmer layer and uses
/// the same `base` colour: the two layers blend to produce the sweep effect.
class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }
}
