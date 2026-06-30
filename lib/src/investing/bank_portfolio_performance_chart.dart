import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

enum BankChartTimeRange { oneDay, oneWeek, oneMonth, threeMonths, oneYear, allTime }

/// A data point for the portfolio performance chart.
class BankChartDataPoint {
  final DateTime timestamp;
  final double value;

  const BankChartDataPoint({required this.timestamp, required this.value});
}

/// Time-series chart wrapper sitting on top of fl_chart.
/// Does not implement its own charting — wraps fl_chart's [LineChart].
class BankPortfolioPerformanceChart extends StatelessWidget {
  final List<BankChartDataPoint> dataPoints;
  final bool showGrid;
  final Color? lineColor;
  final BankChartTimeRange selectedRange;
  final ValueChanged<BankChartTimeRange>? onRangeChanged;

  const BankPortfolioPerformanceChart({
    super.key,
    required this.dataPoints,
    this.showGrid = true,
    this.lineColor,
    this.selectedRange = BankChartTimeRange.oneMonth,
    this.onRangeChanged,
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
          'No data available',
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
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

    return RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: 200,
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
                                .copyWith(color: Colors.white),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.outline,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.24),
                          color.withOpacity(0),
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
                return Padding(
                  padding: const EdgeInsets.only(right: BankTokens.space2),
                  child: TextButton(
                    onPressed: () => onRangeChanged?.call(range),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected
                          ? theme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      foregroundColor:
                          isSelected ? theme.primary : theme.onSurfaceVariant,
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space3,
                      ),
                    ),
                    child: Text(_rangeLabels[range]!),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
