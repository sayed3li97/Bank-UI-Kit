import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/money_formatter.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A labeled band on a [BankCreditScoreGauge] arc.
class BankScoreBand {
  const BankScoreBand({
    required this.label,
    required this.upTo,
    required this.color,
  });

  final String label;

  /// Inclusive upper score bound of this band.
  final int upTo;

  final Color color;
}

/// Credit-score arc gauge with band segmentation, an animated needle
/// sweep, a delta chip against the previous score, and a provider
/// attribution line.
///
/// Score digits respect the ambient `NumeralStyle`. The sweep animation
/// jumps straight to the final position under
/// `MediaQuery.disableAnimations`.
///
/// ```dart
/// BankCreditScoreGauge(
///   score: 715,
///   previousScore: 703,
///   updatedAt: DateTime(2026, 5, 3),
///   providerLabel: 'SIMAH',
/// )
/// ```
class BankCreditScoreGauge extends StatefulWidget {
  const BankCreditScoreGauge({
    required this.score,
    super.key,
    this.minScore = 300,
    this.maxScore = 850,
    this.bands,
    this.previousScore,
    this.updatedAt,
    this.providerLabel,
    this.onTap,
    this.size = 180,
    this.updatedPrefix = 'Updated',
    this.strokeWidth,
    this.dotColor,
    this.scoreStyle,
    this.bandLabelStyle,
    this.deltaStyle,
    this.updatedStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  final int score;
  final int minScore;
  final int maxScore;

  /// Score bands rendered as arc segments. Defaults to a five-band
  /// poor → excellent scale across [minScore]..[maxScore].
  final List<BankScoreBand>? bands;

  /// Enables the delta chip and animates the sweep from this value.
  final int? previousScore;

  final DateTime? updatedAt;

  /// Bureau attribution, e.g. `'TransUnion'`.
  final String? providerLabel;

  final VoidCallback? onTap;

  /// Diameter of the gauge.
  final double size;

  final String updatedPrefix;

  /// Stroke thickness of the arc segments. Defaults to 10.
  final double? strokeWidth;

  /// Fill of the indicator dot. Defaults to the theme surface.
  final Color? dotColor;

  /// Merged over the score numeral style (numeralHero, onSurface).
  final TextStyle? scoreStyle;

  /// Merged over the band label style (labelMedium in the band color).
  final TextStyle? bandLabelStyle;

  /// Merged over the delta chip text style (labelSmall, gain or loss
  /// color).
  final TextStyle? deltaStyle;

  /// Merged over the updated/provider line style (bodySmall, variant
  /// color).
  final TextStyle? updatedStyle;

  /// Duration of the needle sweep. Defaults to
  /// [BankTokens.durationXSlow].
  final Duration? animationDuration;

  /// Curve of the needle sweep. Defaults to `Curves.easeOutCubic`.
  final Curve? animationCurve;

  /// Overrides the whole computed semantics label.
  final String? semanticLabel;

  List<BankScoreBand> _defaultBands() {
    final range = maxScore - minScore;
    return [
      BankScoreBand(
        label: 'Poor',
        upTo: minScore + (range * 0.25).round(),
        color: BankTokens.danger,
      ),
      BankScoreBand(
        label: 'Fair',
        upTo: minScore + (range * 0.45).round(),
        color: BankTokens.warning,
      ),
      BankScoreBand(
        label: 'Good',
        upTo: minScore + (range * 0.65).round(),
        color: const Color(0xFFB8C34A),
      ),
      BankScoreBand(
        label: 'Very good',
        upTo: minScore + (range * 0.82).round(),
        color: const Color(0xFF6FBF73),
      ),
      BankScoreBand(
        label: 'Excellent',
        upTo: maxScore,
        color: const Color(0xFF2E9E5B),
      ),
    ];
  }

  @override
  State<BankCreditScoreGauge> createState() => _BankCreditScoreGaugeState();
}

class _BankCreditScoreGaugeState extends State<BankCreditScoreGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? BankTokens.durationXSlow,
    );
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve ?? Curves.easeOutCubic,
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

  double _fraction(int score) {
    final clamped = score.clamp(widget.minScore, widget.maxScore);
    return (clamped - widget.minScore) / (widget.maxScore - widget.minScore);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final numeralStyle = BankUiScope.of(context).numeralStyle;
    final bands = widget.bands ?? widget._defaultBands();

    final band = bands.firstWhere(
      (b) => widget.score <= b.upTo,
      orElse: () => bands.last,
    );

    final delta =
        widget.previousScore == null ? 0 : widget.score - widget.previousScore!;
    final startFraction =
        widget.previousScore == null ? 0.0 : _fraction(widget.previousScore!);
    final endFraction = _fraction(widget.score);

    final updatedText = widget.updatedAt == null
        ? null
        : '${widget.updatedPrefix} '
            '${BankDateFormatter.formatShort(widget.updatedAt!)}';
    final updatedLine = [
      if (updatedText != null) updatedText,
      if (widget.providerLabel != null) widget.providerLabel!,
    ].join(' · ');

    return Semantics(
      label: widget.semanticLabel ??
          'Credit score ${widget.score} of ${widget.maxScore}, '
              '${band.label}'
              '${delta == 0 ? '' : delta > 0 ? ', up $delta points' : ''}'
              '${delta < 0 ? ', down ${delta.abs()} points' : ''}',
      button: widget.onTap != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) {
                  final fraction = startFraction +
                      (endFraction - startFraction) * _sweep.value;
                  return CustomPaint(
                    painter: _GaugePainter(
                      bands: bands,
                      minScore: widget.minScore,
                      maxScore: widget.maxScore,
                      fraction: fraction,
                      trackColor: theme.surfaceVariant,
                      dotColor: widget.dotColor ?? theme.surface,
                      strokeWidth: widget.strokeWidth ?? 10,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            numeralStyle.convert('${widget.score}'),
                            style: BankTokens.numeralHero
                                .copyWith(
                                  color: theme.onSurface,
                                  fontFamily: theme.fontFamily,
                                )
                                .merge(widget.scoreStyle),
                          ),
                          Text(
                            band.label,
                            style: BankTokens.labelMedium
                                .copyWith(color: band.color)
                                .merge(widget.bandLabelStyle),
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
                  color: (delta > 0 ? theme.positiveBalance : BankTokens.danger)
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
                      delta > 0 ? '+$delta' : '−${delta.abs()}',
                    ),
                    style: BankTokens.labelSmall
                        .copyWith(
                          color: delta > 0
                              ? theme.positiveBalance
                              : BankTokens.danger,
                        )
                        .merge(widget.deltaStyle),
                  ),
                ),
              ),
            ],
            if (updatedLine.isNotEmpty) ...[
              const SizedBox(height: BankTokens.space2),
              Text(
                updatedLine,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(widget.updatedStyle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.bands,
    required this.minScore,
    required this.maxScore,
    required this.fraction,
    required this.trackColor,
    required this.dotColor,
    required this.strokeWidth,
  });

  final List<BankScoreBand> bands;
  final int minScore;
  final int maxScore;

  /// 0..1 position of the indicator dot along the arc.
  final double fraction;

  final Color trackColor;
  final Color dotColor;
  final double strokeWidth;

  static const _sweepAngle = math.pi * 1.5; // 270°
  static const _startAngle = math.pi * 0.75; // pointing down-left
  static const _gap = 0.035; // radians between band segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var bandStart = _startAngle;
    var previousBound = minScore;
    for (final band in bands) {
      final bandFraction = (band.upTo - previousBound) / (maxScore - minScore);
      final bandSweep = _sweepAngle * bandFraction;
      stroke.color = band.color.withValues(alpha: 0.35);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        bandStart + _gap / 2,
        math.max(bandSweep - _gap, 0.01),
        false,
        stroke,
      );
      bandStart += bandSweep;
      previousBound = band.upTo;
    }

    // Filled progress overlay up to the indicator.
    var fillStart = _startAngle;
    var remaining = _sweepAngle * fraction;
    previousBound = minScore;
    for (final band in bands) {
      if (remaining <= 0) break;
      final bandFraction = (band.upTo - previousBound) / (maxScore - minScore);
      final bandSweep = _sweepAngle * bandFraction;
      final drawSweep = math.min(bandSweep, remaining);
      stroke.color = band.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        fillStart + _gap / 2,
        math.max(drawSweep - _gap, 0.01),
        false,
        stroke,
      );
      fillStart += bandSweep;
      remaining -= bandSweep;
      previousBound = band.upTo;
    }

    // Indicator dot.
    final angle = _startAngle + _sweepAngle * fraction;
    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas
      ..drawCircle(dotCenter, 8, Paint()..color = dotColor)
      ..drawCircle(
        dotCenter,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _colorAt(fraction),
      );
  }

  Color _colorAt(double f) {
    final score = minScore + ((maxScore - minScore) * f).round();
    for (final band in bands) {
      if (score <= band.upTo) return band.color;
    }
    return bands.last.color;
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.bands != bands ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.dotColor != dotColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
