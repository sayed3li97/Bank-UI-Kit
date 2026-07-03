import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A single contributor to a [BankFinancialHealthScore].
///
/// Each factor represents one dimension of financial wellness (spending
/// discipline, savings rate, debt load, and so on) with a normalised
/// [score] between `0.0` (critical) and `1.0` (excellent).
@immutable
class BankHealthFactor {
  const BankHealthFactor({
    required this.id,
    required this.label,
    required this.score,
    required this.icon,
    this.tip,
  });

  /// Stable identifier, useful when handling factor taps.
  final String id;

  /// Human-readable factor name, e.g. `'Savings rate'`.
  final String label;

  /// Normalised factor score from `0.0` (critical) to `1.0` (excellent).
  final double score;

  /// Leading icon for the factor row.
  final IconData icon;

  /// Optional coaching tip rendered under the factor progress bar.
  final String? tip;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankHealthFactor &&
        other.id == id &&
        other.label == label &&
        other.score == score &&
        other.icon == icon &&
        other.tip == tip;
  }

  @override
  int get hashCode => Object.hash(id, label, score, icon, tip);
}

/// Composite financial wellness score card: one glanceable number
/// with tappable factor drill-downs.
///
/// Renders a 270 degree segmented arc gauge (red, amber, green bands)
/// with the overall [score] centered in hero numerals and the [title]
/// beneath it. When [previousScore] is provided the sweep animates from
/// the old position and a delta chip appears under the gauge. Below the
/// gauge, each [BankHealthFactor] renders as a row with its icon, label,
/// a thin progress bar tinted by its score (danger below 0.4, warning
/// below 0.7, positive otherwise), an optional tip line, and a chevron
/// when [onFactorTap] is set.
///
/// Score digits respect the ambient [NumeralStyle]. The sweep animation
/// jumps straight to the final position under
/// `MediaQuery.disableAnimations`. The gauge semantics summarise the
/// score and the weakest factor.
///
/// ```dart
/// BankFinancialHealthScore(
///   score: 72,
///   previousScore: 65,
///   factors: const [
///     BankHealthFactor(
///       id: 'savings',
///       label: 'Savings rate',
///       score: 0.35,
///       icon: Icons.savings_outlined,
///       tip: 'Try saving 10% of every paycheck.',
///     ),
///     BankHealthFactor(
///       id: 'spending',
///       label: 'Spending discipline',
///       score: 0.8,
///       icon: Icons.speed_outlined,
///     ),
///   ],
///   onFactorTap: (factor) => openFactorDetail(factor.id),
/// )
/// ```
class BankFinancialHealthScore extends StatefulWidget {
  const BankFinancialHealthScore({
    required this.score,
    required this.factors,
    super.key,
    this.previousScore,
    this.onFactorTap,
    this.title = 'Financial health',
    this.gaugeSize = 150,
  });

  /// Overall wellness score from 0 to 100.
  final int score;

  /// Individual wellness dimensions rendered as rows under the gauge.
  final List<BankHealthFactor> factors;

  /// Enables the delta chip and animates the sweep from this value.
  final int? previousScore;

  /// Called with the tapped factor; enables the row chevrons.
  final void Function(BankHealthFactor factor)? onFactorTap;

  /// Heading shown under the score inside the gauge.
  final String title;

  /// Diameter of the arc gauge.
  final double gaugeSize;

  @override
  State<BankFinancialHealthScore> createState() =>
      _BankFinancialHealthScoreState();
}

class _BankFinancialHealthScoreState extends State<BankFinancialHealthScore>
    with SingleTickerProviderStateMixin {
  static const int _maxScore = 100;

  late final AnimationController _controller;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BankTokens.durationXSlow,
    );
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: BankTokens.curveEmphasized,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (animationsDisabled) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _fraction(int score) => score.clamp(0, _maxScore) / _maxScore;

  /// Tint for a normalised 0..1 score: danger below 0.4, warning below
  /// 0.7, positive otherwise.
  Color _tintFor(double score, BankThemeData theme) {
    if (score < 0.4) return BankTokens.danger;
    if (score < 0.7) return BankTokens.warning;
    return theme.positiveBalance;
  }

  BankHealthFactor? get _weakestFactor {
    if (widget.factors.isEmpty) return null;
    return widget.factors.reduce((a, b) => b.score < a.score ? b : a);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final numeralStyle = BankUiScope.of(context).numeralStyle;

    final segments = [
      const _GaugeSegment(upTo: 0.4, color: BankTokens.danger),
      const _GaugeSegment(upTo: 0.7, color: BankTokens.warning),
      _GaugeSegment(upTo: 1, color: theme.positiveBalance),
    ];

    final delta =
        widget.previousScore == null ? 0 : widget.score - widget.previousScore!;
    final startFraction =
        widget.previousScore == null ? 0.0 : _fraction(widget.previousScore!);
    final endFraction = _fraction(widget.score);
    final scoreColor = _tintFor(endFraction, theme);

    final weakest = _weakestFactor;
    final gaugeLabel = '${widget.title}, score ${widget.score} '
        'of $_maxScore'
        '${delta > 0 ? ', up $delta points' : ''}'
        '${delta < 0 ? ', down ${delta.abs()} points' : ''}'
        '${weakest == null ? '' : ', weakest area: ${weakest.label}'}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: gaugeLabel,
              container: true,
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: widget.gaugeSize,
                    height: widget.gaugeSize,
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) {
                        final fraction = startFraction +
                            (endFraction - startFraction) * _sweep.value;
                        return CustomPaint(
                          painter: _HealthGaugePainter(
                            segments: segments,
                            fraction: fraction,
                            trackColor: theme.surfaceVariant,
                            dotColor: theme.surface,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  numeralStyle.convert('${widget.score}'),
                                  style: BankTokens.numeralHero.copyWith(
                                    color: theme.onSurface,
                                    fontFamily: theme.fontFamily,
                                    fontSize: widget.gaugeSize * 0.24,
                                  ),
                                ),
                                Text(
                                  widget.title,
                                  style: BankTokens.labelMedium
                                      .copyWith(color: scoreColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (delta != 0) ...[
                    const SizedBox(height: BankTokens.space2),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: (delta > 0
                                ? theme.positiveBalance
                                : BankTokens.danger)
                            .withValues(alpha: 0.12),
                        borderRadius: theme.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space2,
                          vertical: 2,
                        ),
                        child: Text(
                          numeralStyle.convert(
                            delta > 0 ? '+$delta' : '-${delta.abs()}',
                          ),
                          style: BankTokens.labelSmall.copyWith(
                            color: delta > 0
                                ? theme.positiveBalance
                                : BankTokens.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.factors.isNotEmpty) ...[
              const SizedBox(height: BankTokens.space4),
              for (final factor in widget.factors)
                _FactorRow(
                  factor: factor,
                  tint: _tintFor(factor.score, theme),
                  onTap: widget.onFactorTap == null
                      ? null
                      : () => widget.onFactorTap!(factor),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Factor row
// ---------------------------------------------------------------------------

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.factor,
    required this.tint,
    this.onTap,
  });

  final BankHealthFactor factor;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final percent = (factor.score.clamp(0.0, 1.0) * 100).round();

    return Semantics(
      button: onTap != null,
      label: '${factor.label}, $percent percent'
          '${factor.tip == null ? '' : '. ${factor.tip}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                Icon(
                  factor.icon,
                  size: 20,
                  color: theme.onSurfaceVariant,
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factor.label,
                        style: BankTokens.bodyMedium
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: BankTokens.space1),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(BankTokens.radiusFull),
                        child: SizedBox(
                          height: 4,
                          child: ColoredBox(
                            color: theme.surfaceVariant,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: factor.score.clamp(0.0, 1.0),
                              child: ColoredBox(color: tint),
                            ),
                          ),
                        ),
                      ),
                      if (factor.tip != null) ...[
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          factor.tip!,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: BankTokens.space2),
                  Transform.flip(
                    flipX: isRtl,
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gauge painter
// ---------------------------------------------------------------------------

/// One coloured band of the health gauge arc.
class _GaugeSegment {
  const _GaugeSegment({required this.upTo, required this.color});

  /// Upper bound of the segment as a 0..1 fraction of the arc.
  final double upTo;

  final Color color;
}

/// Paints a 270 degree arc split into coloured segments, a filled
/// progress overlay up to [fraction], and an indicator dot.
class _HealthGaugePainter extends CustomPainter {
  const _HealthGaugePainter({
    required this.segments,
    required this.fraction,
    required this.trackColor,
    required this.dotColor,
  });

  final List<_GaugeSegment> segments;

  /// 0..1 position of the indicator dot along the arc.
  final double fraction;

  final Color trackColor;
  final Color dotColor;

  static const _sweepAngle = math.pi * 1.5; // 270 degrees
  static const _startAngle = math.pi * 0.75; // pointing down-left
  static const _gap = 0.05; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Dim band segments across the full sweep.
    var bandStart = _startAngle;
    var previousBound = 0.0;
    for (final segment in segments) {
      final bandSweep = _sweepAngle * (segment.upTo - previousBound);
      stroke.color = segment.color.withValues(alpha: 0.3);
      canvas.drawArc(
        rect,
        bandStart + _gap / 2,
        math.max(bandSweep - _gap, 0.01),
        false,
        stroke,
      );
      bandStart += bandSweep;
      previousBound = segment.upTo;
    }

    // Filled progress overlay up to the indicator.
    var fillStart = _startAngle;
    var remaining = _sweepAngle * fraction;
    previousBound = 0.0;
    for (final segment in segments) {
      if (remaining <= 0) break;
      final bandSweep = _sweepAngle * (segment.upTo - previousBound);
      final drawSweep = math.min(bandSweep, remaining);
      stroke.color = segment.color;
      canvas.drawArc(
        rect,
        fillStart + _gap / 2,
        math.max(drawSweep - _gap, 0.01),
        false,
        stroke,
      );
      fillStart += bandSweep;
      remaining -= bandSweep;
      previousBound = segment.upTo;
    }

    // Indicator dot.
    final angle = _startAngle + _sweepAngle * fraction;
    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas
      ..drawCircle(dotCenter, 7, Paint()..color = dotColor)
      ..drawCircle(
        dotCenter,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _colorAt(fraction),
      );
  }

  Color _colorAt(double f) {
    for (final segment in segments) {
      if (f <= segment.upTo) return segment.color;
    }
    return segments.last.color;
  }

  @override
  bool shouldRepaint(_HealthGaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.segments != segments ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.dotColor != dotColor;
}
