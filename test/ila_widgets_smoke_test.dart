import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:bank_ui_kit/social.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool islamic = false}) => BankUiScope(
      initialData: BankUiScopeData(islamicFinanceMode: islamic),
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('BankMoneyCircleCard renders turn tracker and pot',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankMoneyCircleCard(
          name: 'Family Jamiyah',
          contribution: Money.fromDouble(100, 'BHD'),
          members: const [
            BankCircleMember(
              id: 'm1',
              name: 'Noora',
              turnIndex: 1,
              paidThisCycle: true,
            ),
            BankCircleMember(
              id: 'm2',
              name: 'You',
              turnIndex: 2,
              isMe: true,
            ),
            BankCircleMember(id: 'm3', name: 'Ali', turnIndex: 3),
          ],
          currentCycle: 2,
          totalCycles: 3,
          nextCollectionDate: DateTime(2026, 8, 2),
          isAdminView: true,
          onRemind: () {},
        ),
      ),
    );
    expect(find.text('Family Jamiyah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankPrizeDrawCard shows draws and eligibility', (tester) async {
    await tester.pumpWidget(
      _host(
        BankPrizeDrawCard(
          balance: Money.fromDouble(25, 'BHD'),
          entriesCount: 0,
          draws: [
            BankPrizeDraw(
              id: 'd1',
              prizeLabel: 'USD 500,000',
              drawDate: DateTime(2026, 9, 13),
              lastDepositDate: DateTime(2026, 8, 31),
              isGrand: true,
            ),
          ],
          minDeposit: Money.fromDouble(50, 'BHD'),
          clock: () => DateTime(2026, 7, 4, 9),
          onAddMoney: () {},
        ),
      ),
    );
    expect(find.text('USD 500,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'BankSavingsProjectionCard swaps to profit labels in Islamic mode',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const BankSavingsProjectionCard(
          currencyCode: 'BHD',
          annualRate: 3.5,
        ),
        islamic: true,
      ),
    );
    expect(find.textContaining('profit', findRichText: true), findsWidgets);
    expect(find.textContaining('AER'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankAssistantPanel fires prompt and submit callbacks',
      (tester) async {
    String? tappedPrompt;
    String? submitted;
    await tester.pumpWidget(
      _host(
        BankAssistantPanel(
          assistantName: 'Aya',
          prompts: const [
            BankAssistantPrompt(id: 'p1', label: 'Spending this month'),
          ],
          onPromptTap: (p) => tappedPrompt = p.id,
          onSubmitted: (q) => submitted = q,
        ),
      ),
    );
    await tester.tap(find.text('Spending this month'));
    await tester.enterText(find.byType(TextField), 'freeze card');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(tappedPrompt, 'p1');
    expect(submitted, 'freeze card');
    expect(tester.takeException(), isNull);
  });
}
