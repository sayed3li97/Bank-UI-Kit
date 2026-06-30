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

  const BankSpendingBreakdownChart({
    required this.categories,
    super.key,
    this.centerLabel,
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
          'No spending data',
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
      );
    }

    final total = widget.categories.fold<double>(
      0,
      (sum, c) => sum + c.amount.amount.toDouble().abs(),
    );

    return RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: 220,
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
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                sections: widget.categories.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final isTouched = i == _touchedIndex;
                  final color =
                      cat.color ?? _defaultColors[i % _defaultColors.length];
                  final value = cat.amount.amount.toDouble().abs();
                  final pct = total > 0 ? (value / total * 100) : 0.0;

                  return PieChartSectionData(
                    value: value,
                    color: color,
                    radius: isTouched ? 60 : 50,
                    showTitle: isTouched,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle:
                        BankTokens.labelSmall.copyWith(color: Colors.white),
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
              final color =
                  cat.color ?? _defaultColors[i % _defaultColors.length];
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
                          _categoryName(cat.category),
                          style: BankTokens.labelSmall
                              .copyWith(color: theme.onSurface),
                        ),
                        Text(
                          amountStr,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant),
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
