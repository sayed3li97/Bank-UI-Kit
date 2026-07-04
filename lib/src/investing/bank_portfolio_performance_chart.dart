import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  /// Merged over the touch tooltip text style (labelSmall, white).
  final TextStyle? tooltipStyle;

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
    final color = lineColor ??
        (theme.accentGradient is LinearGradient
            ? (theme.accentGradient! as LinearGradient).colors.first
            : theme.primary);

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

    final chart = RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: height ?? 200,
            child: LineChart(
              LineChartData(
                minY: minY - padding,
                maxY: maxY + padding,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '\$${s.y.toStringAsFixed(2)}',
                            BankTokens.labelSmall
                                .copyWith(color: Colors.white)
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
                    color: gridColor ?? theme.outline,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  topTitles: AxisTitles(),
                  bottomTitles: AxisTitles(),
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
