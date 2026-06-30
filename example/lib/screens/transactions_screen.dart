import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _now = DateTime.now();

final _transactions = [
  Transaction(
    id: 't1',
    merchantName: 'Sainsbury\'s',
    amount: Money(amount: Decimal.parse('-42.50'), currencyCode: 'GBP'),
    category: TransactionCategory.groceries,
    status: TransactionStatus.cleared,
    settledAt: _now.subtract(const Duration(hours: 2)),
  ),
  Transaction(
    id: 't2',
    merchantName: 'Employer Ltd',
    amount: Money(amount: Decimal.parse('3200.00'), currencyCode: 'GBP'),
    category: TransactionCategory.income,
    status: TransactionStatus.cleared,
    settledAt: _now.subtract(const Duration(days: 1)),
  ),
  Transaction(
    id: 't3',
    merchantName: 'Netflix',
    amount: Money(amount: Decimal.parse('-15.99'), currencyCode: 'GBP'),
    category: TransactionCategory.subscription,
    status: TransactionStatus.pending,
    settledAt: _now.subtract(const Duration(days: 2)),
  ),
  Transaction(
    id: 't4',
    merchantName: 'Costa Coffee',
    amount: Money(amount: Decimal.parse('-4.20'), currencyCode: 'GBP'),
    category: TransactionCategory.dining,
    status: TransactionStatus.cleared,
    settledAt: _now.subtract(const Duration(days: 3)),
  ),
];

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => BankTransactionFilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          BankTransactionGroupHeader(label: 'Today'),
          ..._transactions.take(1).map(
                (t) => BankTransactionListTile(
                  transaction: t,
                  onTap: () =>
                      BankTransactionDetailSheet.show(context, transaction: t),
                ),
              ),
          BankTransactionGroupHeader(label: 'Yesterday'),
          ..._transactions.skip(1).take(1).map(
                (t) => BankTransactionListTile(
                  transaction: t,
                  onTap: () =>
                      BankTransactionDetailSheet.show(context, transaction: t),
                ),
              ),
          BankTransactionGroupHeader(label: 'Earlier'),
          ..._transactions.skip(2).map(
                (t) => BankTransactionListTile(
                  transaction: t,
                  onTap: () =>
                      BankTransactionDetailSheet.show(context, transaction: t),
                ),
              ),
        ],
      ),
    );
  }
}
