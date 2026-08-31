// Every sheet body that paints its own surface presents itself with
// `showHandle: false`, so `BankSheetSurface` draws no grab handle for it — the
// body owns that affordance. A hand-rolled bar is a painted rectangle and
// contributes nothing to the semantics tree, which leaves a visible drag
// affordance that assistive technology cannot see.
//
// These bodies therefore all route through `BankSheetHandle`, which carries the
// labelled `Semantics` container. This suite pumps each one standalone and
// asserts the handle is present *and* announced, so the regression cannot come
// back one sheet at a time.
import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData get _appTheme =>
    BankPreset.studio.apply(ThemeData.light(useMaterial3: true));

/// Pumps [child] on a viewport tall enough that these full-height sheet bodies
/// lay out without overflowing, which would fail the test for the wrong reason.
Future<void> _pumpSheet(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    BankUiScope(
      child: MaterialApp(
        theme: _appTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Asserts the pumped sheet body draws exactly one grab handle and that
/// assistive technology is given a non-empty label for it.
void _expectAnnouncedHandle(WidgetTester tester) {
  final handle = find.byType(BankSheetHandle);
  expect(handle, findsOneWidget);
  expect(tester.getSemantics(handle).label, isNotEmpty);
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

BankAccount _account(String id, String name) => BankAccount(
      id: id,
      name: name,
      maskedNumber: '•••• 4242',
      balance: Money.fromDouble(2480.50, 'GBP'),
      status: BankAccountStatus.active,
      type: BankAccountType.current,
      currencyCode: 'GBP',
    );

SavingsPot _pot() => SavingsPot(
      id: 'pot-1',
      name: 'Holiday Fund',
      target: Money.fromDouble(3000, 'GBP'),
      current: Money.fromDouble(1860, 'GBP'),
      hasOwnAccountNumber: false,
      memberIds: const [],
      isRoundUpDestination: false,
    );

Transaction _transaction() => Transaction(
      id: 'tx-1',
      amount: Money.fromDouble(-38.50, 'GBP'),
      settledAt: DateTime(2026, 6, 28),
      status: TransactionStatus.cleared,
      merchantName: 'Café Nero',
      category: TransactionCategory.dining,
    );

AssetQuote _quote() => AssetQuote(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      price: Money.fromDouble(189.50, 'USD'),
      changePercent: 1.24,
    );

List<BankPlanTier> _plans() => [
      BankPlanTier(
        id: 'free',
        name: 'Free',
        monthlyPrice: Money.fromDouble(0, 'GBP'),
        features: const [
          BankPlanFeature(
            label: 'Everyday spending',
            tierSupport: {'free': true, 'premium': true},
          ),
        ],
      ),
      BankPlanTier(
        id: 'premium',
        name: 'Premium',
        monthlyPrice: Money.fromDouble(15, 'GBP'),
        features: const [
          BankPlanFeature(
            label: 'Everyday spending',
            tierSupport: {'free': true, 'premium': true},
          ),
        ],
      ),
    ];

void main() {
  late SemanticsHandle semantics;

  setUp(() => semantics = TestWidgetsFlutterBinding.instance.ensureSemantics());
  tearDown(() => semantics.dispose());

  testWidgets('BankPotContributionSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankPotContributionSheet(pot: _pot(), onConfirm: (_) async {}),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankIncomeSorterSheet announces its handle', (tester) async {
    final controller = BankIncomeSorterController(
      incomingAmount: Money.fromDouble(2400, 'GBP'),
      availablePots: [_pot()],
    );
    addTearDown(controller.dispose);

    await _pumpSheet(tester, BankIncomeSorterSheet(controller: controller));
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankRoundUpSettingsSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankRoundUpSettingsSheet(
        isEnabled: true,
        multiplier: 1,
        availablePots: [_pot()],
        onEnabledChanged: (_) {},
        onMultiplierChanged: (_) {},
        onPotSelected: (_) {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankTransactionCostSplitSheet announces its handle',
      (tester) async {
    await _pumpSheet(
      tester,
      BankTransactionCostSplitSheet(
        transaction: _transaction(),
        participants: const [
          BankSplitParticipant(id: 'p1', name: 'Alex Morgan'),
          BankSplitParticipant(id: 'p2', name: 'Sam Reed'),
        ],
        onConfirm: (_) {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankTransactionFilterSheet announces its handle',
      (tester) async {
    await _pumpSheet(tester, BankTransactionFilterSheet(onApply: (_) {}));
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankTransactionCategorySplitSheet announces its handle',
      (tester) async {
    await _pumpSheet(
      tester,
      BankTransactionCategorySplitSheet(
        transaction: _transaction(),
        onConfirm: (_) {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankTransactionDetailSheet announces its handle',
      (tester) async {
    await _pumpSheet(
      tester,
      BankTransactionDetailSheet(transaction: _transaction()),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankBuySellSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankBuySellSheet(
        quote: _quote(),
        onSubmit: (side, type, amount, limit) async {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankDisclosureConsentSheet announces its handle',
      (tester) async {
    await _pumpSheet(
      tester,
      BankDisclosureConsentSheet(
        disclosures: const [
          BankDisclosure(
            title: 'Representative example',
            body: 'Borrowing 25,000 GBP over 60 months at 6.4% APR.',
          ),
        ],
        consents: const [
          BankConsentItem(id: 'agreement', label: 'I agree', required: true),
        ],
        onChanged: (_) {},
        onAgree: () {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankDisclosureConsentSheet still honours showHandle: false',
      (tester) async {
    await _pumpSheet(
      tester,
      BankDisclosureConsentSheet(
        disclosures: const [
          BankDisclosure(title: 'Terms', body: 'The full agreement.'),
        ],
        consents: const [
          BankConsentItem(id: 'agreement', label: 'I agree'),
        ],
        showHandle: false,
        onChanged: (_) {},
        onAgree: () {},
      ),
    );
    expect(find.byType(BankSheetHandle), findsNothing);
  });

  testWidgets('BankAccountSwitcher announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankAccountSwitcher(
        accounts: [_account('a1', 'Main Account'), _account('a2', 'Savings')],
        selectedAccountId: 'a1',
        onSelected: (_) {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankPaywallSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankPaywallSheet(
        featureName: 'International transfers',
        description: 'Send money abroad with no fees on Premium.',
        plans: _plans(),
        currentTierId: 'free',
        onUpgrade: (_) {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankContactPaymentSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankContactPaymentSheet(
        contacts: const [
          BankSplitParticipant(id: 'c1', name: 'Alex Morgan'),
          BankSplitParticipant(id: 'c2', name: 'Sam Reed'),
        ],
        onSend: (id, amount, note) async {},
        onRequest: (id, amount, note) async {},
      ),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankUpdatePromptSheet announces its handle', (tester) async {
    await _pumpSheet(
      tester,
      BankUpdatePromptSheet(onUpdate: () {}, onNotNow: () {}),
    );
    _expectAnnouncedHandle(tester);
  });

  testWidgets('BankCountryPicker announces its sheet handle', (tester) async {
    await tester.pumpWidget(
      BankUiScope(
        child: MaterialApp(
          theme: _appTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => BankCountryPicker.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    _expectAnnouncedHandle(tester);
  });

  testWidgets('a forwarded handle colour still reaches the bar',
      (tester) async {
    const handleInk = Color(0xFF00FF00);

    await _pumpSheet(
      tester,
      BankTransactionDetailSheet(
        transaction: _transaction(),
        handleColor: handleInk,
      ),
    );

    final bar = tester.widget<Container>(
      find.descendant(
        of: find.byType(BankSheetHandle),
        matching: find.byType(Container),
      ),
    );
    expect((bar.decoration! as BoxDecoration).color, handleInk);
    _expectAnnouncedHandle(tester);
  });

  testWidgets('the handle stays centred under RTL', (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      BankUiScope(
        child: MaterialApp(
          theme: _appTheme,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: Scaffold(
            body: BankTransactionDetailSheet(transaction: _transaction()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectAnnouncedHandle(tester);
    final handle = tester.getRect(find.byType(BankSheetHandle));
    final bar = tester.getRect(
      find.descendant(
        of: find.byType(BankSheetHandle),
        matching: find.byType(Container),
      ),
    );
    expect(bar.center.dx, closeTo(handle.center.dx, 0.01));
  });
}
