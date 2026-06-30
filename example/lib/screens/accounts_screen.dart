import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _accounts = [
  BankAccount(
    id: '1',
    name: 'Current Account',
    maskedNumber: '•••• 4321',
    currencyCode: 'GBP',
    type: BankAccountType.current,
    status: BankAccountStatus.active,
    balance: Money(amount: Decimal.parse('4250.00'), currencyCode: 'GBP'),
    sortCodeOrBic: '12-34-56',
    ibanOrAccountNumber: '12345678',
  ),
  BankAccount(
    id: '2',
    name: 'Savings ISA',
    maskedNumber: '•••• 8765',
    currencyCode: 'GBP',
    type: BankAccountType.isa,
    status: BankAccountStatus.active,
    balance: Money(amount: Decimal.parse('12800.50'), currencyCode: 'GBP'),
  ),
  BankAccount(
    id: '3',
    name: 'Frozen Account',
    maskedNumber: '•••• 1111',
    currencyCode: 'GBP',
    type: BankAccountType.savings,
    status: BankAccountStatus.frozen,
    balance: Money(amount: Decimal.parse('500.00'), currencyCode: 'GBP'),
  ),
];

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Balance Text',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankBalanceText(
            money: Money(amount: Decimal.parse('4250.00'), currencyCode: 'GBP'),
            size: BankBalanceSize.hero,
          ),
          const SizedBox(height: BankTokens.space2),
          BankBalanceText(
            money: Money(amount: Decimal.parse('4250.00'), currencyCode: 'GBP'),
            size: BankBalanceSize.large,
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Account Cards',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ..._accounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space3),
              child: BankAccountCard(account: a),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Account Switcher',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          FilledButton(
            onPressed: () async {
              final selected = await BankAccountSwitcher.show(
                context,
                accounts: _accounts,
                selectedAccountId: _accounts[_activeIndex].id,
              );
              if (selected != null) {
                setState(
                  () => _activeIndex =
                      _accounts.indexWhere((x) => x.id == selected.id),
                );
              }
            },
            child: Text('Switch account (${_accounts[_activeIndex].name})'),
          ),
        ],
      ),
    );
  }
}
