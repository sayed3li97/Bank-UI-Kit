import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// Tone of a [BankRatioBand], mapped to a semantic colour by the gauge.
enum BankRatioTone {
  /// A healthy / comfortable zone (theme positive balance colour).
  positive,

  /// A cautionary zone (amber warning colour).
  warning,

  /// A risky / over-limit zone (theme negative balance colour).
  danger,
}

/// A single coloured zone of a [BankRatioGauge].
///
/// Bands partition the 0..1 track (as a fraction of the gauge's `max`).
/// Each band covers everything from the previous band's [upTo] up to its
/// own [upTo], so a set of bands should be given in ascending [upTo] order
/// with the final band ending at `1.0`.
///
/// ```dart
/// const bands = <BankRatioBand>[
///   BankRatioBand(upTo: 0.7, tone: BankRatioTone.positive, label: 'Healthy'),
///   BankRatioBand(upTo: 0.85, tone: BankRatioTone.warning, label: 'Elevated'),
///   BankRatioBand(upTo: 1.0, tone: BankRatioTone.danger, label: 'High'),
/// ];
/// ```
@immutable
class BankRatioBand {
  /// The upper bound of this band, as a fraction (0..1) of the gauge `max`.
  final double upTo;

  /// The semantic tone that colours this band's fill and zone tint.
  final BankRatioTone tone;

  /// Optional human label shown in the gauge legend (e.g. 'Healthy').
  final String? label;

  const BankRatioBand({
    required this.upTo,
    required this.tone,
    this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankRatioBand &&
          other.upTo == upTo &&
          other.tone == tone &&
          other.label == label;

  @override
  int get hashCode => Object.hash(upTo, tone, label);
}

/// A horizontal ratio gauge for figures such as LTV, CLTV, DTI or credit
/// utilisation.
///
/// The gauge maps [value] against [max] to a 0..1 fraction, paints a
/// rounded track split into coloured [bands], overlays a solid fill up to
/// the current fraction (tinted by the band the value lands in), and shows
/// a big percentage readout. An optional [threshold] tick with a
/// [thresholdLabel] marks a limit such as 'Max 85%'.
///
/// The readout respects the ambient [NumeralStyle] from [BankUiScope], and
/// the fill animation is skipped when the platform requests reduced motion
/// via [MediaQuery.disableAnimationsOf].
///
/// ```dart
/// BankRatioGauge(
///   value: 0.82,
///   title: 'Loan to value',
///   thresholdLabel: 'Max 85%',
///   threshold: 0.85,
///   caption: 'Based on the latest valuation',
///   bands: const [
///     BankRatioBand(upTo: 0.7, tone: BankRatioTone.positive),
///     BankRatioBand(upTo: 0.85, tone: BankRatioTone.warning),
///     BankRatioBand(upTo: 1.0, tone: BankRatioTone.danger),
///   ],
/// )
/// ```
class BankRatioGauge extends StatelessWidget {
  /// The measured value. Interpreted against [max]; commonly 0..1.
  final double value;

  /// The full-scale value that maps to the end of the track. Defaults to
  /// `1.0`, so [value] is treated directly as a fraction.
  final double max;

  /// The coloured zones of the track, in ascending [BankRatioBand.upTo]
  /// order. When empty the fill uses [accentColor] or the theme primary.
  final List<BankRatioBand> bands;

  /// Optional heading shown above the track (e.g. 'Loan to value').
  final String? title;

  /// Optional caption for a limit tick (e.g. 'Max 85%'). Shown only when
  /// non-null; pair with [threshold] to draw the matching tick.
  final String? thresholdLabel;

  /// Optional limit marker position, as a fraction (0..1) of [max]. When
  /// non-null a vertical tick is drawn on the track at this position.
  final double? threshold;

  /// Optional quiet caption shown under the track (e.g. 'as of 4 Jul 2026').
  final String? caption;

  /// Suffix appended to the percentage readout. Defaults to `'%'`.
  final String percentSuffix;

  /// Number of decimal places in the percentage readout. Defaults to `0`.
  final int percentDecimals;

  /// Whether to show a legend of the labelled [bands]. Defaults to `true`;
  /// the legend still hides when no band carries a label.
  final bool showBandLegend;

  /// Overrides the content padding. Defaults to none (the gauge is meant to
  /// sit inside an already-padded surface).
  final EdgeInsetsGeometry? padding;

  /// Overrides the rounded-track corner radius. Defaults to a pill
  /// (half the resolved track height).
  final BorderRadius? radius;

  /// Overrides the solid fill colour. Defaults to the tone colour of the
  /// band the value lands in (or the theme primary when [bands] is empty).
  final Color? accentColor;

  /// Overrides the base track colour. Defaults to the theme outline at
  /// 20% opacity.
  final Color? trackColor;

  /// Overrides the threshold tick colour. Defaults to the theme onSurface
  /// at 55% opacity.
  final Color? thresholdColor;

  /// Merged over the [title] style (labelMedium, onSurfaceVariant).
  final TextStyle? titleStyle;

  /// Merged over the big percentage readout style (numeralLarge, tinted by
  /// the active band).
  final TextStyle? readoutStyle;

  /// Merged over the [thresholdLabel] style (labelSmall, onSurfaceVariant).
  final TextStyle? thresholdStyle;

  /// Merged over the [caption] style (bodySmall, onSurfaceVariant).
  final TextStyle? captionStyle;

  /// Merged over each band legend label style (bodySmall, onSurfaceVariant).
  final TextStyle? legendStyle;

  /// Overrides the track thickness. Defaults to 10.
  final double? trackHeight;

  /// Overrides the fill animation duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the fill animation curve. Defaults to
  /// [BankTokens.curveEmphasized].
  final Curve? animationCurve;

  /// Optional replacement for the default title/readout header row.
  final Widget? header;

  /// Optional trailing slot rendered below the caption and legend.
  final Widget? footer;

  /// Overrides the computed semantics label. Defaults to a summary of the
  /// title, percentage, and threshold.
  final String? semanticLabel;

  const BankRatioGauge({
    required this.value,
    super.key,
    this.max = 1.0,
    this.bands = const <BankRatioBand>[],
    this.title,
    this.thresholdLabel,
    this.threshold,
    this.caption,
    this.percentSuffix = '%',
    this.percentDecimals = 0,
    this.showBandLegend = true,
    this.padding,
    this.radius,
    this.accentColor,
    this.trackColor,
    this.thresholdColor,
    this.titleStyle,
    this.readoutStyle,
    this.thresholdStyle,
    this.captionStyle,
    this.legendStyle,
    this.trackHeight,
    this.animationDuration,
    this.animationCurve,
    this.header,
    this.footer,
    this.semanticLabel,
  });

  double get _fraction {
    if (max <= 0) return 0;
    return (value / max).clamp(0.0, 1.0);
  }

  Color _toneColor(BankRatioTone tone, BankThemeData theme) {
    switch (tone) {
      case BankRatioTone.positive:
        return theme.positiveBalance;
      case BankRatioTone.warning:
        return BankTokens.warning;
      case BankRatioTone.danger:
        return theme.negativeBalance;
    }
  }

  BankRatioBand? _activeBand() {
    if (bands.isEmpty) return null;
    final fraction = _fraction;
    for (final band in bands) {
      if (fraction <= band.upTo) return band;
    }
    return bands.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final fraction = _fraction;
    final height = trackHeight ?? 10;
    final resolvedRadius = radius ?? BorderRadius.circular(height / 2);
    final resolvedTrack = trackColor ?? theme.outline.withValues(alpha: 0.2);

    final activeBand = _activeBand();
    final fillColor = accentColor ??
        (activeBand != null
            ? _toneColor(activeBand.tone, theme)
            : theme.primary);

    final zones = <_RatioZone>[];
    var start = 0.0;
    for (final band in bands) {
      final end = band.upTo.clamp(0.0, 1.0);
      if (end > start) {
        zones.add(
          _RatioZone(
            start: start,
            end: end,
            color: _toneColor(band.tone, theme).withValues(alpha: 0.16),
          ),
        );
        start = end;
      }
    }

    final percentValue = max <= 0 ? 0.0 : (value / max) * 100;
    final readout = scope.numeralStyle.convert(
      '${percentValue.clamp(0.0, double.infinity).toStringAsFixed(
            percentDecimals,
          )}$percentSuffix',
    );

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final resolvedThresholdColor =
        thresholdColor ?? theme.onSurface.withValues(alpha: 0.55);

    final track = SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: fraction),
        duration: disableAnimations
            ? Duration.zero
            : (animationDuration ?? BankTokens.durationBase),
        curve: animationCurve ?? BankTokens.curveEmphasized,
        builder: (_, animated, __) => CustomPaint(
          painter: _RatioTrackPainter(
            fraction: animated,
            zones: zones,
            fillColor: fillColor,
            trackColor: resolvedTrack,
            radius: resolvedRadius,
            threshold: threshold?.clamp(0.0, 1.0),
            thresholdColor: resolvedThresholdColor,
          ),
        ),
      ),
    );

    final legendBands =
        bands.where((b) => b.label != null && b.label!.isNotEmpty).toList();

    final resolvedSemantics = semanticLabel ??
        [
          if (title != null) title,
          readout,
          if (thresholdLabel != null) thresholdLabel,
        ].whereType<String>().join(', ');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        header ??
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(titleStyle),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  readout,
                  style: BankTokens.numeralLarge
                      .copyWith(color: fillColor)
                      .merge(readoutStyle),
                ),
              ],
            ),
        const SizedBox(height: BankTokens.space2),
        track,
        if (thresholdLabel != null || caption != null) ...[
          const SizedBox(height: BankTokens.space2),
          Row(
            children: [
              if (thresholdLabel != null)
                Expanded(
                  child: Text(
                    thresholdLabel!,
                    style: BankTokens.labelSmall
                        .copyWith(color: theme.onSurfaceVariant)
                        .merge(thresholdStyle),
                  ),
                )
              else
                const Spacer(),
              if (caption != null)
                Flexible(
                  child: Text(
                    caption!,
                    textAlign: TextAlign.end,
                    style: BankTokens.bodySmall
                        .copyWith(color: theme.onSurfaceVariant)
                        .merge(captionStyle),
                  ),
                ),
            ],
          ),
        ],
        if (showBandLegend && legendBands.isNotEmpty) ...[
          const SizedBox(height: BankTokens.space3),
          Wrap(
            spacing: BankTokens.space4,
            runSpacing: BankTokens.space2,
            children: [
              for (final band in legendBands)
                _LegendChip(
                  color: _toneColor(band.tone, theme),
                  label: band.label!,
                  labelStyle: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(legendStyle),
                ),
            ],
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: BankTokens.space3),
          footer!,
        ],
      ],
    );

    return Semantics(
      label: resolvedSemantics,
      container: true,
      child: padding != null
          ? Padding(padding: padding!, child: content)
          : content,
    );
  }
}

/// A resolved coloured zone spanning [start]..[end] (fractions) of the track.
class _RatioZone {
  final double start;
  final double end;
  final Color color;

  const _RatioZone({
    required this.start,
    required this.end,
    required this.color,
  });
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle labelStyle;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: BankTokens.space2),
        Text(label, style: labelStyle),
      ],
    );
  }
}

class _RatioTrackPainter extends CustomPainter {
  final double fraction;
  final List<_RatioZone> zones;
  final Color fillColor;
  final Color trackColor;
  final BorderRadius radius;
  final double? threshold;
  final Color thresholdColor;

  const _RatioTrackPainter({
    required this.fraction,
    required this.zones,
    required this.fillColor,
    required this.trackColor,
    required this.radius,
    required this.threshold,
    required this.thresholdColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);

    canvas
      ..save()
      ..clipRRect(rrect);

    // Base track.
    canvas.drawRect(rect, Paint()..color = trackColor);

    // Faint band zones.
    for (final zone in zones) {
      final zoneRect = Rect.fromLTRB(
        zone.start * size.width,
        0,
        zone.end * size.width,
        size.height,
      );
      canvas.drawRect(zoneRect, Paint()..color = zone.color);
    }

    // Solid fill up to the current fraction.
    if (fraction > 0) {
      final fillRect = Rect.fromLTRB(
        0,
        0,
        fraction.clamp(0.0, 1.0) * size.width,
        size.height,
      );
      canvas.drawRect(fillRect, Paint()..color = fillColor);
    }

    canvas.restore();

    // Threshold tick, drawn over the (clipped) track.
    final tick = threshold;
    if (tick != null) {
      final x = tick * size.width;
      final tickPaint = Paint()
        ..color = thresholdColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, -size.height * 0.15),
        Offset(x, size.height * 1.15),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RatioTrackPainter old) =>
      old.fraction != fraction ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.radius != radius ||
      old.threshold != threshold ||
      old.thresholdColor != thresholdColor ||
      !identical(old.zones, zones);
}
