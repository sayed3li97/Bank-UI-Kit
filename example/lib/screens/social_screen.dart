import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/social.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final transaction = Transaction(
      id: 't_joint',
      merchantName: 'Waitrose',
      amount: Money(amount: Decimal.parse('-85.40'), currencyCode: 'GBP'),
      category: TransactionCategory.groceries,
      status: TransactionStatus.cleared,
      settledAt: DateTime.now().subtract(const Duration(hours: 4)),
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Social & Joint'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Joint Transaction Tile',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankJointTransactionListTile(
            transaction: transaction,
            initiatorName: 'Sarah',
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Ownership Badges',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Wrap(
            spacing: BankTokens.space2,
            children: BankOwnershipRole.values
                .map((r) => BankAccountOwnershipBadge(role: r))
                .toList(),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Shared Goal Progress',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankSharedGoalProgressCard(
            goalName: 'Family Holiday',
            targetAmount:
                Money(amount: Decimal.parse('5000.00'), currencyCode: 'GBP'),
            savedAmount:
                Money(amount: Decimal.parse('2350.00'), currencyCode: 'GBP'),
            contributors: [
              BankGoalContributor(name: 'Alice'),
              BankGoalContributor(name: 'Bob'),
              BankGoalContributor(name: 'Charlie'),
            ],
            onContribute: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Contact Payment',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          FilledButton(
            onPressed: () => BankContactPaymentSheet.show(
              context,
              contactName: 'Alice Johnson',
              onSubmit: (amount, note) async {},
            ),
            child: const Text('Pay Contact'),
          ),
        ],
      ),
    );
  }
}
