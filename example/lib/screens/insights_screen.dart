import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final now = DateTime.now();

    final categories = [
      BankSpendingCategory(
        category: TransactionCategory.groceries,
        amount: Money(amount: Decimal.parse('420.00'), currencyCode: 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.transport,
        amount: Money(amount: Decimal.parse('185.00'), currencyCode: 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.shopping,
        amount: Money(amount: Decimal.parse('310.00'), currencyCode: 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.entertainment,
        amount: Money(amount: Decimal.parse('95.00'), currencyCode: 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.utilities,
        amount: Money(amount: Decimal.parse('140.00'), currencyCode: 'GBP'),
      ),
    ];

    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

    final budgets = [
      BankBudget(
        id: 'b1',
        name: 'Food & Drink',
        category: TransactionCategory.groceries,
        limit: Money(amount: Decimal.parse('400.00'), currencyCode: 'GBP'),
        spent: Money(amount: Decimal.parse('420.00'), currencyCode: 'GBP'),
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
      BankBudget(
        id: 'b2',
        name: 'Shopping',
        category: TransactionCategory.shopping,
        limit: Money(amount: Decimal.parse('500.00'), currencyCode: 'GBP'),
        spent: Money(amount: Decimal.parse('310.00'), currencyCode: 'GBP'),
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
      BankBudget(
        id: 'b3',
        name: 'Transport',
        category: TransactionCategory.transport,
        limit: Money(amount: Decimal.parse('200.00'), currencyCode: 'GBP'),
        spent: Money(amount: Decimal.parse('185.00'), currencyCode: 'GBP'),
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    ];

    final insights = [
      BankInsight(
        id: 'i1',
        title: 'Spending up 12% this month',
        body: 'You\'ve spent more than usual on food & drink this month.',
        confidence: InsightConfidence.high,
        generatedAt: now.subtract(const Duration(hours: 2)),
        isDismissed: false,
        relatedCategory: TransactionCategory.food,
      ),
      BankInsight(
        id: 'i2',
        title: 'Subscription review recommended',
        body: 'You have 8 active subscriptions totalling £67.93/month.',
        confidence: InsightConfidence.medium,
        generatedAt: now.subtract(const Duration(days: 1)),
        isDismissed: false,
        relatedCategory: TransactionCategory.subscription,
      ),
      BankInsight(
        id: 'i3',
        title: 'Possible saving opportunity',
        body: 'Switching your energy provider could save you £15/month.',
        confidence: InsightConfidence.low,
        generatedAt: now.subtract(const Duration(days: 2)),
        isDismissed: false,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Spending Breakdown', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankSpendingBreakdownChart(categories: categories),
          const SizedBox(height: BankTokens.space4),
          Text('Budget Gauges', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Card(
            shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
            color: theme.surface,
            elevation: theme.elevationLow,
            child: Column(
              children: budgets
                  .map((b) => BankBudgetGaugeWidget(budget: b))
                  .toList(),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('AI Insights', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space3),
              child: BankInsightCard(
                insight: insight,
                onAction: () {},
                actionLabel: 'See details',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
