import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One balance observation (or projection) on a [BankCashflowChart].
class BankBalancePoint {
  const BankBalancePoint({required this.date, required this.balance});

  final DateTime date;
  final Money balance;
}

/// Account-level balance-trend chart with a committed-payments forecast
/// overlay: the sibling of `BankPortfolioPerformanceChart`, wrapping
/// fl_chart's `LineChart`.
///
/// History renders as a solid primary line with a soft gradient fill;
/// [forecast] continues from today as a dashed line in the pending
/// color. An optional [safeToSpend] horizontal reference line and a
/// touch tooltip (privacy-aware: masked mode shows bullets) complete
/// the chart.
///
/// ```dart
/// BankCashflowChart(
///   history: last30Days,
///   forecast: next14Days,
///   currencyCode: 'SAR',
///   safeToSpend: Money.fromDouble(2350, 'SAR'),
/// )
/// ```
class BankCashflowChart extends StatelessWidget {
  const BankCashflowChart({
    required this.history,
    required this.currencyCode,
    super.key,
    this.forecast,
    this.safeToSpend,
    this.onPointFocus,
    this.height = 220,
    this.safeToSpendLabel = 'Safe to spend',
    this.emptyLabel = 'No balance data',
  });

  /// Observed balances, oldest first.
  final List<BankBalancePoint> history;

  final String currencyCode;

  /// Projected balances continuing after the last history point.
  final List<BankBalancePoint>? forecast;

  /// Renders a labeled horizontal reference line.
  final Money? safeToSpend;

  /// Fired as the user drags across the chart; null on release.
  final void Function(BankBalancePoint?)? onPointFocus;

  final double height;
  final String safeToSpendLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    if (history.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyLabel,
            style:
                BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
          ),
        ),
      );
    }

    final all = [...history, ...?forecast];
    final values =
        all.map((p) => p.balance.amount.toDouble()).toList(growable: false);
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (safeToSpend != null) {
      final line = safeToSpend!.amount.toDouble();
      minY = math.min(minY, line);
      maxY = math.max(maxY, line);
    }
    final pad = math.max((maxY - minY) * 0.12, 1);
    minY -= pad;
    maxY += pad;

    final historySpots = [
      for (var i = 0; i < history.length; i++)
        FlSpot(i.toDouble(), history[i].balance.amount.toDouble()),
    ];
    final forecastSpots = [
      if (forecast != null && forecast!.isNotEmpty) ...[
        historySpots.last,
        for (var i = 0; i < forecast!.length; i++)
          FlSpot(
            (history.length + i).toDouble(),
            forecast![i].balance.amount.toDouble(),
          ),
      ],
    ];

    String formatCompact(double value) => BankMoneyFormatter.format(
          amount: Money.fromDouble(value, currencyCode).amount,
          currencyCode: currencyCode,
          numeralStyle: scope.numeralStyle,
          compact: true,
        );

    BankBalancePoint pointAt(int index) => index < history.length
        ? history[index]
        : forecast![index - history.length];

    final semanticSummary = 'Balance ranged from '
        '${formatCompact(values.reduce(math.min))} to '
        '${formatCompact(values.reduce(math.max))}'
        '${forecastSpots.isEmpty ? '' : ', projected'}'
        '${forecastSpots.isEmpty ? '' : ' '}'
        '${forecastSpots.isEmpty ? '' : formatCompact(forecastSpots.last.y)}';

    return Semantics(
      label: semanticSummary,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.outline.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        formatCompact(value),
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: math.max((all.length / 4).floorToDouble(), 1),
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= all.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          BankDateFormatter.formatShort(all[index].date),
                          style: BankTokens.labelSmall
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (forecastSpots.isNotEmpty)
                    VerticalLine(
                      x: (history.length - 1).toDouble(),
                      color: theme.outline,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                ],
                horizontalLines: [
                  if (safeToSpend != null)
                    HorizontalLine(
                      y: safeToSpend!.amount.toDouble(),
                      color: theme.positiveBalance,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.positiveBalance),
                        labelResolver: (_) => safeToSpendLabel,
                      ),
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                touchCallback: onPointFocus == null
                    ? null
                    : (event, response) {
                        final spot = response?.lineBarSpots?.firstOrNull;
                        if (spot == null || event is FlTapUpEvent) {
                          onPointFocus!(null);
                          return;
                        }
                        onPointFocus!(pointAt(spot.x.round()));
                      },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.surfaceVariant,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        scope.privacyEnabled
                            ? '••••'
                            : '${BankDateFormatter.formatShort(
                                pointAt(spot.x.round()).date,
                              )}\n${formatCompact(spot.y)}',
                        BankTokens.labelMedium.copyWith(color: theme.onSurface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: historySpots,
                  isCurved: true,
                  barWidth: 2.5,
                  color: theme.primary,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primary.withValues(alpha: 0.12),
                        theme.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                if (forecastSpots.isNotEmpty)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: theme.pending,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
