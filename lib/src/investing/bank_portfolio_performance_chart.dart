import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

enum BankChartTimeRange {
  oneDay,
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  allTime
}

/// A data point for the portfolio performance chart.
class BankChartDataPoint {
  final DateTime timestamp;
  final double value;

  const BankChartDataPoint({required this.timestamp, required this.value});
}

/// Time-series chart wrapper sitting on top of fl_chart.
/// Does not implement its own charting: wraps fl_chart's [LineChart].
class BankPortfolioPerformanceChart extends StatelessWidget {
  final List<BankChartDataPoint> dataPoints;
  final bool showGrid;
  final Color? lineColor;
  final BankChartTimeRange selectedRange;
  final ValueChanged<BankChartTimeRange>? onRangeChanged;

  /// Overrides the chart height. Defaults to 200.
  final double? height;

  /// Overrides the line thickness. Defaults to 2.
  final double? lineWidth;

  /// Overrides the below-line fill. Defaults to a vertical fade of the
  /// line colour from 24% opacity to transparent.
  final Gradient? gradient;

  /// Overrides the horizontal grid line colour. Defaults to the theme
  /// outline.
  final Color? gridColor;

  /// Merged over the touch tooltip text style (labelMedium, onSurface).
  final TextStyle? tooltipStyle;

  /// Overrides the touch tooltip fill. Defaults to the theme
  /// surfaceVariant.
  final Color? tooltipBackgroundColor;

  /// Currency used to format tooltip, header, and axis values through
  /// [BankMoneyFormatter]. When null, plain numbers are shown.
  final String? currencyCode;

  /// Overrides the built-in value formatting (tooltip, header, and
  /// value-axis labels).
  final String Function(double value)? valueFormatter;

  /// Overrides the built-in short date formatting on the time axis.
  final String Function(DateTime date)? dateFormatter;

  /// Toggles the min/max value labels and first/last date labels.
  /// Defaults to true.
  final bool showAxisLabels;

  /// Toggles the latest-value / period-change header. Defaults to true.
  final bool showChangeHeader;

  /// Overrides the period-gain tint (header chip, default line colour).
  /// Defaults to [BankTokens.investmentGain] /
  /// [BankTokens.investmentGainDark] by surface brightness.
  final Color? gainColor;

  /// Overrides the period-loss tint (header chip, default line colour).
  /// Defaults to [BankTokens.investmentLoss] /
  /// [BankTokens.investmentLossDark] by surface brightness.
  final Color? lossColor;

  /// Overrides the selected range pill tint. Defaults to the theme
  /// primary.
  final Color? accentColor;

  /// Overrides the built-in range captions ('1D', '1W', ...); missing
  /// entries fall back to the defaults.
  final Map<BankChartTimeRange, String>? rangeLabels;

  /// Empty-state text. Defaults to 'No data available'.
  final String emptyLabel;

  /// Merged over the empty-state style (bodyMedium, onSurfaceVariant).
  final TextStyle? emptyLabelStyle;

  /// Wraps the chart in a [Semantics] node when provided; no semantics
  /// node is added by default.
  final String? semanticLabel;

  const BankPortfolioPerformanceChart({
    required this.dataPoints,
    super.key,
    this.showGrid = true,
    this.lineColor,
    this.selectedRange = BankChartTimeRange.oneMonth,
    this.onRangeChanged,
    this.height,
    this.lineWidth,
    this.gradient,
    this.gridColor,
    this.tooltipStyle,
    this.tooltipBackgroundColor,
    this.currencyCode,
    this.valueFormatter,
    this.dateFormatter,
    this.showAxisLabels = true,
    this.showChangeHeader = true,
    this.gainColor,
    this.lossColor,
    this.accentColor,
    this.rangeLabels,
    this.emptyLabel = 'No data available',
    this.emptyLabelStyle,
    this.semanticLabel,
  });

  static const _rangeLabels = <BankChartTimeRange, String>{
    BankChartTimeRange.oneDay: '1D',
    BankChartTimeRange.oneWeek: '1W',
    BankChartTimeRange.oneMonth: '1M',
    BankChartTimeRange.threeMonths: '3M',
    BankChartTimeRange.oneYear: '1Y',
    BankChartTimeRange.allTime: 'All',
  };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final isDark =
        ThemeData.estimateBrightnessForColor(theme.surface) == Brightness.dark;
    final resolvedGain = gainColor ??
        (isDark ? BankTokens.investmentGainDark : BankTokens.investmentGain);
    final resolvedLoss = lossColor ??
        (isDark ? BankTokens.investmentLossDark : BankTokens.investmentLoss);

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: BankTokens.bodyMedium
              .copyWith(color: theme.onSurfaceVariant)
              .merge(emptyLabelStyle),
        ),
      );
    }

    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final minY = dataPoints.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final maxY = dataPoints.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;
    final ySpan = chartMaxY - chartMinY;

    // Period direction drives the default line colour and the header
    // change chip: gains read green, losses red, on every preset.
    final first = dataPoints.first.value;
    final last = dataPoints.last.value;
    final isGain = last >= first;
    final color = lineColor ?? (isGain ? resolvedGain : resolvedLoss);
    final changePct = first == 0 ? 0.0 : (last - first) / first.abs() * 100;
    final changeStr =
        '${isGain ? '+' : '-'}${changePct.abs().toStringAsFixed(2)}%';

    String formatValue(double v, {bool compact = false}) {
      if (valueFormatter != null) return valueFormatter!(v);
      final code = currencyCode;
      if (code == null) return v.toStringAsFixed(2);
      return BankMoneyFormatter.format(
        amount: Money.fromDouble(v, code).amount,
        currencyCode: code,
        numeralStyle: scope.numeralStyle,
        compact: compact,
      );
    }

    String formatDate(DateTime d) =>
        dateFormatter?.call(d) ?? BankDateFormatter.formatShort(d);

    final axisStyle =
        BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant);

    final chart = RepaintBoundary(
      child: Column(
        children: [
          if (showChangeHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatValue(last),
                    style: BankTokens.numeralMedium
                        .copyWith(color: theme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: (isGain ? resolvedGain : resolvedLoss)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BankTokens.space2,
                      vertical: 2,
                    ),
                    child: Text(
                      changeStr,
                      style: BankTokens.labelSmall.copyWith(
                        color: isGain ? resolvedGain : resolvedLoss,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BankTokens.space3),
          ],
          SizedBox(
            height: height ?? 200,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        tooltipBackgroundColor ?? theme.surfaceVariant,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            formatValue(s.y),
                            BankTokens.labelMedium
                                .copyWith(color: theme.onSurface)
                                .merge(tooltipStyle),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridColor ?? theme.onSurface.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  // Value scale: min/max labels on the trailing edge.
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showAxisLabels,
                      reservedSize: 56,
                      interval: ySpan > 0 ? ySpan : 1,
                      getTitlesWidget: (value, meta) {
                        final tolerance = (ySpan > 0 ? ySpan : 1) * 0.001;
                        final isMinEdge = (value - meta.min).abs() < tolerance;
                        final isMaxEdge = (value - meta.max).abs() < tolerance;
                        if (!isMinEdge && !isMaxEdge) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Text(
                            formatValue(isMinEdge ? minY : maxY, compact: true),
                            style: axisStyle,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  // Time scale: first/last date labels.
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showAxisLabels,
                      reservedSize: 24,
                      interval:
                          spots.length > 1 ? (spots.length - 1).toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index != 0 && index != dataPoints.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            formatDate(dataPoints[index].timestamp),
                            style: axisStyle,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: lineWidth ?? 2.0,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: gradient ??
                          LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.24),
                              color.withValues(alpha: 0),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BankChartTimeRange.values.map((range) {
                final isSelected = range == selectedRange;
                final rangeAccent = accentColor ?? theme.primary;
                return Padding(
                  padding: const EdgeInsets.only(right: BankTokens.space2),
                  child: TextButton(
                    onPressed: () => onRangeChanged?.call(range),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected
                          ? rangeAccent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      foregroundColor:
                          isSelected ? rangeAccent : theme.onSurfaceVariant,
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space3,
                      ),
                    ),
                    child: Text(
                      rangeLabels?[range] ?? _rangeLabels[range]!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) return chart;
    return Semantics(label: semanticLabel, child: chart);
  }
}
