import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool privacy = false}) => BankUiScope(
      initialData: BankUiScopeData(privacyEnabled: privacy),
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('BankPaymentCard renders label, number, network', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 360,
          child: BankPaymentCard(
            label: 'Everyday',
            maskedNumber: '•••• 8695',
            holderName: 'ALEX MORGAN',
            expiry: '08/28',
            network: BankCardNetwork.visa,
          ),
        ),
      ),
    );
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('•••• 8695'), findsOneWidget);
    expect(find.text('ALEX MORGAN'), findsOneWidget);
    expect(find.text('VISA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankPaymentCard shows balance and masks under privacy',
      (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: BankPaymentCard(
            label: 'Everyday',
            balance: Money.fromDouble(3565, 'GBP'),
          ),
        ),
        privacy: true,
      ),
    );
    expect(tester.takeException(), isNull);
    // The formatted amount must not leak while privacy is on.
    expect(find.textContaining('3,565'), findsNothing);
  });

  testWidgets('BankNetworkBadge renders each network', (tester) async {
    for (final n in BankCardNetwork.values) {
      await tester.pumpWidget(_host(BankNetworkBadge(network: n)));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('BankCardCarousel builds items and reports selection',
      (tester) async {
    var changed = -1;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 380,
          height: 320,
          child: BankCardCarousel(
            itemCount: 3,
            onCardChanged: (i) => changed = i,
            itemBuilder: (context, i) => BankPaymentCard(label: 'Card $i'),
          ),
        ),
      ),
    );
    expect(find.text('Card 0'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(changed, greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankBalanceTileRow lays out tiles', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 380,
          child: BankBalanceTileRow(
            tiles: [
              BankBalanceTile(
                label: 'Available Balance',
                amount: Money.fromDouble(3565, 'GBP'),
                icon: Icons.account_balance_wallet_outlined,
              ),
              BankBalanceTile(
                label: 'Savings',
                amount: Money.fromDouble(650, 'GBP'),
                trend: '+2.4%',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
    expect(find.text('SAVINGS'), findsOneWidget);
    expect(find.text('+2.4%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
