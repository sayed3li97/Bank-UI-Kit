import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a themed [BankUiScope] so widgets that read
/// [BankThemeData.of] / [BankUiScope.of] can be pumped in isolation.
Widget _host(Widget child, BankPreset preset) {
  return BankUiScope(
    initialData: BankUiScopeData(preset: preset),
    child: MaterialApp(
      theme: preset.apply(ThemeData.light(useMaterial3: true)),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

final _account = BankAccount(
  id: 'a1',
  name: 'Everyday',
  maskedNumber: '•••• 4291',
  balance: Money.fromDouble(1234.56, 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
);

final _txn = Transaction(
  id: 't1',
  amount: Money.fromDouble(-4.85, 'GBP'),
  settledAt: DateTime(2026, 6, 30),
  status: TransactionStatus.cleared,
  merchantName: 'Pret A Manger',
  category: TransactionCategory.dining,
);

final _pot = SavingsPot(
  id: 'p1',
  name: 'Japan',
  target: Money.fromDouble(5000, 'GBP'),
  current: Money.fromDouble(3120, 'GBP'),
  hasOwnAccountNumber: true,
  memberIds: const [],
  isRoundUpDestination: true,
);

void main() {
  for (final preset in BankPreset.values) {
    group('Smoke (${preset.name})', () {
      testWidgets('BankBalanceText shows the formatted amount', (tester) async {
        await tester.pumpWidget(
          _host(
            BankBalanceText(
              money: Money.fromDouble(1234.56, 'GBP'),
              size: BankBalanceSize.hero,
            ),
            preset,
          ),
        );
        await tester.pump();
        expect(find.byType(BankBalanceText), findsOneWidget);
        expect(find.textContaining('1,234'), findsOneWidget);
      });

      testWidgets('BankAccountCard renders the account name', (tester) async {
        await tester
            .pumpWidget(_host(BankAccountCard(account: _account), preset));
        await tester.pump();
        expect(find.text('Everyday'), findsOneWidget);
      });

      testWidgets('BankTransactionListTile renders the merchant',
          (tester) async {
        await tester.pumpWidget(
          _host(BankTransactionListTile(transaction: _txn), preset),
        );
        await tester.pump();
        expect(find.text('Pret A Manger'), findsOneWidget);
      });

      testWidgets('BankSavingsPotCard renders the pot name', (tester) async {
        await tester.pumpWidget(_host(BankSavingsPotCard(pot: _pot), preset));
        await tester.pump();
        expect(find.text('Japan'), findsOneWidget);
      });

      testWidgets('BankCreditLimitGauge renders', (tester) async {
        await tester.pumpWidget(
          _host(
            BankCreditLimitGauge(
              creditLimit: Money.fromDouble(5000, 'GBP'),
              usedAmount: Money.fromDouble(1500, 'GBP'),
            ),
            preset,
          ),
        );
        await tester.pump();
        expect(find.byType(BankCreditLimitGauge), findsOneWidget);
      });

      testWidgets('BankStepProgressIndicator renders', (tester) async {
        await tester.pumpWidget(
          _host(
            const BankStepProgressIndicator(totalSteps: 4, currentStep: 2),
            preset,
          ),
        );
        await tester.pump();
        expect(find.byType(BankStepProgressIndicator), findsOneWidget);
      });
    });
  }

  testWidgets('Privacy mode masks the balance', (tester) async {
    await tester.pumpWidget(
      BankUiScope(
        initialData: const BankUiScopeData(privacyEnabled: true),
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Scaffold(
            body: BankBalanceText(
              money:
                  Money(amount: Decimal.parse('1234.56'), currencyCode: 'GBP'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('1,234'), findsNothing);
  });
}
