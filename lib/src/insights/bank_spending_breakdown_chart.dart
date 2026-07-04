import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/models/transaction.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A category name + money pair for the spending breakdown.
class BankSpendingCategory {
  final TransactionCategory category;
  final Money amount;
  final Color? color;

  const BankSpendingCategory({
    required this.category,
    required this.amount,
    this.color,
  });
}

/// Donut chart showing spending split by category.
class BankSpendingBreakdownChart extends StatefulWidget {
  final List<BankSpendingCategory> categories;
  final String? centerLabel;

  /// Overrides the fallback section palette used when a category has
  /// no explicit colour. Cycled when shorter than the category list.
  final List<Color>? colors;

  /// Overrides the donut height. Defaults to 220.
  final double? chartHeight;

  /// Overrides the donut hole radius. Defaults to 60.
  final double? centerSpaceRadius;

  /// Empty-state text. Defaults to 'No spending data'.
  final String emptyLabel;

  /// Merged over the empty-state style (bodyMedium, onSurfaceVariant).
  final TextStyle? emptyLabelStyle;

  /// Merged over the touched-section percent style (labelSmall, white).
  final TextStyle? sectionTitleStyle;

  /// Merged over the legend category name style (labelSmall,
  /// onSurface).
  final TextStyle? legendLabelStyle;

  /// Merged over the legend amount style (bodySmall, onSurfaceVariant).
  final TextStyle? legendAmountStyle;

  /// Overrides the built-in English category names in the legend.
  final String Function(TransactionCategory category)? categoryNameBuilder;

  /// Wraps the chart in a [Semantics] node when provided; no semantics
  /// node is added by default.
  final String? semanticLabel;

  const BankSpendingBreakdownChart({
    required this.categories,
    super.key,
    this.centerLabel,
    this.colors,
    this.chartHeight,
    this.centerSpaceRadius,
    this.emptyLabel = 'No spending data',
    this.emptyLabelStyle,
    this.sectionTitleStyle,
    this.legendLabelStyle,
    this.legendAmountStyle,
    this.categoryNameBuilder,
    this.semanticLabel,
  });

  @override
  State<BankSpendingBreakdownChart> createState() =>
      _BankSpendingBreakdownChartState();
}

class _BankSpendingBreakdownChartState
    extends State<BankSpendingBreakdownChart> {
  int _touchedIndex = -1;

  static const List<Color> _defaultColors = [
    Color(0xFF4A7C80),
    Color(0xFFFF6B6B),
    Color(0xFF7C3AED),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(
          widget.emptyLabel,
          style: BankTokens.bodyMedium
              .copyWith(color: theme.onSurfaceVariant)
              .merge(widget.emptyLabelStyle),
        ),
      );
    }

    final total = widget.categories.fold<double>(
      0,
      (sum, c) => sum + c.amount.amount.toDouble().abs(),
    );

    final palette = (widget.colors == null || widget.colors!.isEmpty)
        ? _defaultColors
        : widget.colors!;

    final chart = RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: widget.chartHeight ?? 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      setState(() => _touchedIndex = -1);
                      return;
                    }
                    setState(
                      () => _touchedIndex =
                          response.touchedSection!.touchedSectionIndex,
                    );
                  },
                ),
                centerSpaceRadius: widget.centerSpaceRadius ?? 60,
                sectionsSpace: 2,
                sections: widget.categories.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final isTouched = i == _touchedIndex;
                  final color = cat.color ?? palette[i % palette.length];
                  final value = cat.amount.amount.toDouble().abs();
                  final pct = total > 0 ? (value / total * 100) : 0.0;

                  return PieChartSectionData(
                    value: value,
                    color: color,
                    radius: isTouched ? 60 : 50,
                    showTitle: isTouched,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: BankTokens.labelSmall
                        .copyWith(color: Colors.white)
                        .merge(widget.sectionTitleStyle),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          Wrap(
            spacing: BankTokens.space3,
            runSpacing: BankTokens.space2,
            children: widget.categories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final color = cat.color ?? palette[i % palette.length];
              final amountStr = BankMoneyFormatter.format(
                amount: cat.amount.amount,
                currencyCode: cat.amount.currencyCode,
                numeralStyle: scope.numeralStyle,
              );

              return GestureDetector(
                onTap: () => setState(
                  () => _touchedIndex = _touchedIndex == i ? -1 : i,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryNameBuilder?.call(cat.category) ??
                              _categoryName(cat.category),
                          style: BankTokens.labelSmall
                              .copyWith(color: theme.onSurface)
                              .merge(widget.legendLabelStyle),
                        ),
                        Text(
                          amountStr,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(widget.legendAmountStyle),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (widget.semanticLabel == null) return chart;
    return Semantics(label: widget.semanticLabel, child: chart);
  }

  String _categoryName(TransactionCategory cat) => switch (cat) {
        TransactionCategory.groceries => 'Groceries',
        TransactionCategory.dining => 'Dining',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.health => 'Health',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.travel => 'Travel',
        TransactionCategory.education => 'Education',
        TransactionCategory.subscription => 'Subscription',
        TransactionCategory.transfer => 'Transfer',
        TransactionCategory.income => 'Income',
        TransactionCategory.investment => 'Investment',
        TransactionCategory.creditPayment => 'Credit',
        TransactionCategory.other => 'Other',
      };
}
