import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _pots = [
  SavingsPot(
    id: 'p1',
    name: 'Holiday Fund',
    current: Money(amount: Decimal.parse('1250.00'), currencyCode: 'GBP'),
    target: Money(amount: Decimal.parse('3000.00'), currencyCode: 'GBP'),
    interestRate: 4.5,
    hasOwnAccountNumber: false,
    memberIds: const [],
    isRoundUpDestination: false,
  ),
  SavingsPot(
    id: 'p2',
    name: 'Emergency Fund',
    current: Money(amount: Decimal.parse('5000.00'), currencyCode: 'GBP'),
    target: Money(amount: Decimal.parse('6000.00'), currencyCode: 'GBP'),
    interestRate: 3.2,
    hasOwnAccountNumber: true,
    memberIds: const ['m1', 'm2'],
    isRoundUpDestination: false,
  ),
  SavingsPot(
    id: 'p3',
    name: 'New Laptop',
    current: Money(amount: Decimal.parse('200.00'), currencyCode: 'GBP'),
    target: Money(amount: Decimal.parse('1500.00'), currencyCode: 'GBP'),
    hasOwnAccountNumber: false,
    memberIds: const [],
    isRoundUpDestination: true,
  ),
];

class SavingScreen extends StatelessWidget {
  const SavingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Saving'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Savings Pots',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ..._pots.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space3),
              child: BankSavingsPotCard(
                pot: p,
                onTap: () => BankPotContributionSheet.show(
                  context,
                  pot: p,
                  onConfirm: (_) async {},
                ),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Round-Up Settings',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          FilledButton(
            onPressed: () => BankRoundUpSettingsSheet.show(
              context,
              isEnabled: false,
              multiplier: 1,
              availablePots: _pots,
              onEnabledChanged: (_) {},
              onMultiplierChanged: (_) {},
              onPotSelected: (_) {},
            ),
            child: const Text('Configure Round-Up'),
          ),
          const SizedBox(height: BankTokens.space3),
          Text('Shared Pot Members',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankSharedPotInvite(
            pot: _pots[1],
            currentMembers: const [
              BankPotMember(id: 'm1', name: 'Alice Johnson'),
              BankPotMember(id: 'm2', name: 'Bob Smith'),
            ],
            onInvite: () {},
            onRemoveMember: (id) async {},
          ),
        ],
      ),
    );
  }
}
