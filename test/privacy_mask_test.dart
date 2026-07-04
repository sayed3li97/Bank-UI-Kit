import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compliance suite: privacy mode must mask money everywhere.
///
/// Every amount-bearing widget below is pumped inside a [BankUiScope] with
/// `privacyEnabled: true`. The raw formatted amount (e.g. `2,480.50`) must
/// appear nowhere in the rendered text or the semantics tree, while the
/// scope's mask glyph ([BankUiStrings.balanceHidden]) must be visible.

/// The glyph the kit substitutes for hidden amounts.
final String _mask = BankUiStrings.defaults.balanceHidden;

/// Raw amount fragments that must never surface while privacy is on.
///
/// The comma-grouped forms are what [BankMoneyFormatter] renders for the
/// sample amounts (2480.50, 5000.75, their 7481.25 sum, and the 4.25 fee);
/// `12,450` is the points balance; the bare decimal forms guard semantics
/// labels built from `Money.amount` directly.
const List<String> _forbidden = <String>[
  '2,480.50',
  '5,000.75',
  '7,481.25',
  '12,450',
  '2480.5',
  '5000.75',
  '7481.25',
  '4.25',
];

// ---------------------------------------------------------------------------
// Sample data (masked strings deliberately avoid the mask glyph so the
// mask-presence assertion can only be satisfied by a masked amount).
// ---------------------------------------------------------------------------

final _primary = Money.fromDouble(2480.50, 'GBP');
final _secondary = Money.fromDouble(5000.75, 'GBP');
final _fee = Money.fromDouble(4.25, 'GBP');

final _account = BankAccount(
  id: 'a1',
  name: 'Everyday',
  maskedNumber: '**** 4291',
  balance: _primary,
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
);

final _transaction = Transaction(
  id: 't1',
  amount: Money.fromDouble(-2480.50, 'GBP'),
  settledAt: DateTime(2026, 7, 2, 14, 30),
  status: TransactionStatus.cleared,
  merchantName: 'Waterstones',
  category: TransactionCategory.shopping,
);

final _pot = SavingsPot(
  id: 'p1',
  name: 'Holiday fund',
  target: _secondary,
  current: _primary,
  hasOwnAccountNumber: false,
  memberIds: const ['m1'],
  isRoundUpDestination: false,
);

const _beneficiary = BankBeneficiary(
  id: 'ben1',
  name: 'Omar Farouk',
  maskedAccount: '**** 8842',
  type: BeneficiaryType.bankTransfer,
  isVerified: true,
);

final _familyMember = BankFamilyMemberCard(
  id: 'fam1',
  memberName: 'Maya',
  cardLast4: '4291',
  spendLimit: _secondary,
  spentThisPeriod: _primary,
);

final _forecastNow = DateTime(2026, 7, 3);

final _forecasts = <BankBillForecast>[
  BankBillForecast(
    id: 'f1',
    billerName: 'City Power',
    predictedAmount: _primary,
    expectedDate: DateTime(2026, 7, 4),
    confidence: 0.95,
    confirmed: true,
  ),
  BankBillForecast(
    id: 'f2',
    billerName: 'Metro Water',
    predictedAmount: _secondary,
    expectedDate: DateTime(2026, 7, 10),
    confidence: 0.6,
  ),
];

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Widget _host(Widget child, {bool privacyEnabled = true}) {
  return BankUiScope(
    initialData: BankUiScopeData(privacyEnabled: privacyEnabled),
    child: MaterialApp(
      theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Collects every label/value/hint/tooltip in the semantics tree.
List<String> _semanticsStrings(WidgetTester tester) {
  final strings = <String>[];
  for (final element in tester.allElements) {
    if (element is! RenderObjectElement) {
      continue;
    }
    final node = element.renderObject.debugSemantics;
    if (node == null) {
      continue;
    }
    strings
      ..add(node.label)
      ..add(node.value)
      ..add(node.hint)
      ..add(node.tooltip);
  }
  return strings;
}

/// Asserts no raw amount fragment is rendered (plain or rich text) or
/// exposed through semantics, and that the mask glyph is visible.
void _expectMasked(WidgetTester tester) {
  for (final raw in _forbidden) {
    expect(
      find.textContaining(raw, findRichText: true),
      findsNothing,
      reason: 'Raw amount fragment "$raw" leaked into rendered text.',
    );
  }
  expect(
    find.textContaining(_mask, findRichText: true),
    findsWidgets,
    reason: 'Expected the privacy mask glyph to be rendered.',
  );
  final semantics = _semanticsStrings(tester);
  for (final raw in _forbidden) {
    expect(
      semantics.where((s) => s.contains(raw)),
      isEmpty,
      reason: 'Raw amount fragment "$raw" leaked into the semantics tree.',
    );
  }
}

Future<void> _pumpMaskedCase(WidgetTester tester, Widget child) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(_host(child));
  _expectMasked(tester);
  handle.dispose();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('control: raw amounts render when privacy is off',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            BankBalanceText(money: _primary),
            BankTransactionListTile(transaction: _transaction),
          ],
        ),
        privacyEnabled: false,
      ),
    );
    // Proves the forbidden fragments match the kit's real output format,
    // so the findsNothing assertions below cannot pass vacuously.
    expect(find.text('£2,480.50'), findsOneWidget);
    expect(find.textContaining('2,480.50'), findsNWidgets(2));
  });

  testWidgets('BankBalanceText masks text and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(BankBalanceText(money: _primary)));

    expect(find.text(_mask), findsOneWidget);
    expect(find.textContaining('2,480.50'), findsNothing);

    // BankBalanceText wraps its text in Semantics(label: ...,
    // excludeSemantics: true): hidden state announces 'Balance hidden'
    // and must never announce the 'Balance: <amount>' visible-state label.
    expect(find.bySemanticsLabel('Balance hidden'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Balance: ')), findsNothing);

    _expectMasked(tester);
    handle.dispose();
  });

  testWidgets('BankAccountCard masks the balance', (tester) async {
    await _pumpMaskedCase(tester, BankAccountCard(account: _account));
  });

  testWidgets('BankHorizontalAccountCard masks the balance', (tester) async {
    await _pumpMaskedCase(
      tester,
      BankHorizontalAccountCard(account: _account),
    );
  });

  testWidgets('BankTransactionListTile masks the amount', (tester) async {
    await _pumpMaskedCase(
      tester,
      BankTransactionListTile(transaction: _transaction),
    );
  });

  testWidgets('BankSavingsPotCard masks balance and goal', (tester) async {
    await _pumpMaskedCase(tester, BankSavingsPotCard(pot: _pot));
  });

  testWidgets('BankPaymentRequestCard masks the requested amount',
      (tester) async {
    await _pumpMaskedCase(
      tester,
      BankPaymentRequestCard(
        requesterId: 'u1',
        requesterName: 'Dana',
        amount: _primary,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        onAccept: () {},
        onDecline: () {},
      ),
    );
  });

  testWidgets('BankTransferReviewCard masks amount and fee', (tester) async {
    await _pumpMaskedCase(
      tester,
      BankTransferReviewCard(
        amount: _primary,
        beneficiary: _beneficiary,
        fee: _fee,
        estimatedArrival: 'Within 2 hours',
      ),
    );
  });

  testWidgets('BankSummaryStack masks money items', (tester) async {
    await _pumpMaskedCase(
      tester,
      BankSummaryStack(
        items: [
          const BankSummaryItem(label: 'From', value: 'Everyday'),
          BankSummaryItem(label: 'Total', money: _primary, emphasized: true),
        ],
      ),
    );
  });

  testWidgets('BankPointsHubCard masks points and cash value line',
      (tester) async {
    await _pumpMaskedCase(
      tester,
      const BankPointsHubCard(
        pointsBalance: 12450,
        actions: [],
        cashValueLabel: '= £2,480.50',
      ),
    );
  });

  testWidgets('BankFamilyCardTile masks spent and limit amounts',
      (tester) async {
    await _pumpMaskedCase(
      tester,
      BankFamilyCardTile(
        member: _familyMember,
        onFreezeToggle: (frozen) async => frozen,
      ),
    );
  });

  testWidgets('BankBillForecastList masks total and row amounts',
      (tester) async {
    await _pumpMaskedCase(
      tester,
      BankBillForecastList(
        forecasts: _forecasts,
        currencyCode: 'GBP',
        now: _forecastNow,
      ),
    );
  });
}
