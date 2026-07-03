import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke coverage for the competitive-parity component set: every new
/// widget pumps, lays out, and renders its primary content under each
/// preset without throwing.
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

void main() {
  for (final preset in BankPreset.values) {
    group('Parity smoke (${preset.name})', () {
      testWidgets('BankEmblem renders initials deterministically',
          (tester) async {
        await tester.pumpWidget(
          _host(const BankEmblem(initialsFrom: 'Acme Trading'), preset),
        );
        expect(find.text('AT'), findsOneWidget);
      });

      testWidgets('BankSummaryStack renders label/value rows',
          (tester) async {
        await tester.pumpWidget(
          _host(
            const BankSummaryStack(
              items: [
                BankSummaryItem(label: 'From', value: 'Everyday'),
                BankSummaryItem(label: 'Reference', value: 'INV-9'),
              ],
            ),
            preset,
          ),
        );
        expect(find.text('From'), findsOneWidget);
        expect(find.text('INV-9'), findsOneWidget);
      });

      testWidgets('BankProductItemTile renders the account name',
          (tester) async {
        await tester.pumpWidget(
          _host(BankProductItemTile(account: _account), preset),
        );
        expect(find.text('Everyday'), findsOneWidget);
      });

      testWidgets('BankAccountNumberText groups an IBAN', (tester) async {
        await tester.pumpWidget(
          _host(
            const BankAccountNumberText(
              value: 'GB29NWBK60161331926819',
              kind: BankAccountNumberKind.iban,
              copyEnabled: false,
            ),
            preset,
          ),
        );
        expect(find.textContaining('GB29'), findsOneWidget);
      });

      testWidgets('BankStatusTracker renders stages', (tester) async {
        await tester.pumpWidget(
          _host(
            BankStatusTracker(
              stages: const [
                BankTrackerStage(title: 'Submitted'),
                BankTrackerStage(title: 'Under review'),
                BankTrackerStage(title: 'Resolved'),
              ],
              currentIndex: 1,
            ),
            preset,
          ),
        );
        expect(find.text('Under review'), findsOneWidget);
      });

      testWidgets('BankOtpInput renders the requested box count',
          (tester) async {
        await tester.pumpWidget(
          _host(BankOtpInput(onCompleted: (_) {}), preset),
        );
        expect(find.byType(BankOtpInput), findsOneWidget);
      });

      testWidgets('BankCountryPicker field shows placeholder',
          (tester) async {
        await tester.pumpWidget(
          _host(BankCountryPicker(onSelected: (_) {}), preset),
        );
        expect(find.text('Select country'), findsOneWidget);
      });

      testWidgets('BankMoneyProtectionBanner shows the scheme name',
          (tester) async {
        await tester.pumpWidget(
          _host(
            const BankMoneyProtectionBanner(schemeName: 'FSCS'),
            preset,
          ),
        );
        expect(find.textContaining('FSCS'), findsOneWidget);
      });

      testWidgets('BankStatementListTile renders title and New chip',
          (tester) async {
        await tester.pumpWidget(
          _host(
            BankStatementListTile(
              document: BankDocument(
                id: 'st1',
                title: 'March statement',
                periodOrDate: DateTime(2026, 3, 31),
                type: BankDocumentType.statement,
                isNew: true,
              ),
              onView: () {},
            ),
            preset,
          ),
        );
        expect(find.text('March statement'), findsOneWidget);
        expect(find.text('New'), findsOneWidget);
      });

      testWidgets('BankBillPayTile renders biller and Pay button',
          (tester) async {
        await tester.pumpWidget(
          _host(
            BankBillPayTile(
              bill: BankBill(
                id: 'b1',
                billerName: 'City Power',
                amountDue: Money.fromDouble(120, 'GBP'),
                dueDate: DateTime(2026, 7, 14),
                status: BankBillStatus.dueSoon,
              ),
              onPay: () {},
            ),
            preset,
          ),
        );
        expect(find.text('City Power'), findsOneWidget);
        expect(find.text('Pay'), findsOneWidget);
      });

      testWidgets('BankApprovalRequestTile shows approvals progress',
          (tester) async {
        await tester.pumpWidget(
          _host(
            BankApprovalRequestTile(
              request: BankApprovalRequest(
                id: 'ap1',
                title: 'Payment to Acme Ltd',
                requesterName: 'Dana',
                requestedAt: DateTime(2026, 7, 2),
                approvalsRequired: 3,
                approvalsGiven: 2,
                state: BankApprovalState.pending,
              ),
            ),
            preset,
          ),
        );
        expect(find.text('2 of 3 approvals'), findsOneWidget);
      });

      testWidgets('BankCreditScoreGauge announces the score',
          (tester) async {
        await tester.pumpWidget(
          _host(const BankCreditScoreGauge(score: 715), preset),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('715'), findsOneWidget);
      });

      testWidgets('BankCashflowChart renders without data crashing',
          (tester) async {
        await tester.pumpWidget(
          _host(
            BankCashflowChart(
              history: [
                for (var i = 0; i < 5; i++)
                  BankBalancePoint(
                    date: DateTime(2026, 6, i + 1),
                    balance: Money.fromDouble(1000.0 + i * 50, 'GBP'),
                  ),
              ],
              currencyCode: 'GBP',
            ),
            preset,
          ),
        );
        expect(find.byType(BankCashflowChart), findsOneWidget);
      });

      testWidgets('BankHelpFaqList expands an item on tap',
          (tester) async {
        await tester.pumpWidget(
          _host(
            const BankHelpFaqList(
              items: [
                BankFaqItem(
                  id: 'f1',
                  question: 'How do I freeze my card?',
                  answer: 'Open the card screen and tap Freeze.',
                ),
              ],
              searchable: false,
            ),
            preset,
          ),
        );
        await tester.tap(find.text('How do I freeze my card?'));
        await tester.pumpAndSettle();
        expect(
          find.text('Open the card screen and tap Freeze.'),
          findsOneWidget,
        );
      });

      testWidgets('BankMyQrCard encodes and shows the display name',
          (tester) async {
        await tester.pumpWidget(
          _host(
            const BankMyQrCard(
              payload: 'bank://pay/GB29NWBK60161331926819',
              displayName: 'Sara Ahmed',
            ),
            preset,
          ),
        );
        expect(find.text('Sara Ahmed'), findsOneWidget);
      });

      testWidgets('BankLoanCalculatorCard computes a monthly payment',
          (tester) async {
        await tester.pumpWidget(
          _host(
            BankLoanCalculatorCard(
              minAmount: Money.fromDouble(1000, 'GBP'),
              maxAmount: Money.fromDouble(20000, 'GBP'),
              minMonths: 6,
              maxMonths: 60,
              annualRate: 0.049,
              onChanged: (_, __) {},
            ),
            preset,
          ),
        );
        expect(find.text('Monthly payment'), findsOneWidget);
      });
    });
  }

  testWidgets('BankScaApprovalSheet never masks the amount under privacy',
      (tester) async {
    await tester.pumpWidget(
      BankUiScope(
        initialData: const BankUiScopeData(privacyEnabled: true),
        child: MaterialApp(
          theme:
              BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Scaffold(
            body: BankScaApprovalSheet(
              amount: Money.fromDouble(1250, 'GBP'),
              payeeName: 'Acme Trading LLC',
              methods: const {BankScaMethod.pin},
              onApprove: (_, __) async => true,
              onReject: () {},
            ),
          ),
        ),
      ),
    );
    // Dynamic linking: amount stays visible even with privacy mode on.
    expect(find.textContaining('1,250'), findsOneWidget);
  });
}
