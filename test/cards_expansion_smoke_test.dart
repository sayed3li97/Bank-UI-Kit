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
    final semantics = tester.ensureSemantics();
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
    // The Visa mark is vector-drawn — no counterfeit text wordmark — but it
    // still announces the network to assistive technologies.
    expect(find.text('VISA'), findsNothing);
    expect(find.byType(BankNetworkBadge), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(BankNetworkBadge)).label,
      contains('Visa'),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
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

  testWidgets('BankNetworkBadge markBuilder overrides the procedural mark',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankNetworkBadge(
          network: BankCardNetwork.visa,
          markBuilder: (context, network, height) =>
              SizedBox(key: const Key('custom-mark'), height: height),
        ),
      ),
    );
    expect(find.byKey(const Key('custom-mark')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'virtual card built-in flip button clears the network mark (LTR + RTL)',
      (tester) async {
    final account = BankAccount(
      id: 'a1',
      name: 'Everyday',
      maskedNumber: '•••• 4291',
      balance: Money.fromDouble(1200, 'GBP'),
      status: BankAccountStatus.active,
      type: BankAccountType.current,
      currencyCode: 'GBP',
    );

    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      await tester.pumpWidget(
        _host(
          Directionality(
            textDirection: direction,
            child: BankVirtualCardWidget(
              account: account,
              network: BankCardNetwork.visa,
              flipTrigger: BankFlipTrigger.builtInButton,
              width: 340,
            ),
          ),
        ),
      );
      final markRect = tester.getRect(find.byType(BankNetworkBadge));
      final buttonRect = tester.getRect(find.byIcon(Icons.flip_outlined));
      expect(
        markRect.overlaps(buttonRect),
        isFalse,
        reason: 'network mark must not collide with the flip button '
            '($direction)',
      );
      final cardRect = tester.getRect(find.byType(BankVirtualCardWidget));
      if (direction == TextDirection.rtl) {
        // The button tracks the top-end corner: physical LEFT half in RTL.
        expect(buttonRect.center.dx, lessThan(cardRect.center.dx));
      } else {
        expect(buttonRect.center.dx, greaterThan(cardRect.center.dx));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'horizontal card built-in flip button clears the badge (LTR + RTL)',
      (tester) async {
    final account = BankAccount(
      id: 'a2',
      name: 'Everyday',
      maskedNumber: '•••• 4291',
      balance: Money.fromDouble(1200, 'GBP'),
      status: BankAccountStatus.active,
      type: BankAccountType.current,
      currencyCode: 'GBP',
    );

    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      await tester.pumpWidget(
        _host(
          Directionality(
            textDirection: direction,
            child: BankHorizontalAccountCard(
              account: account,
              trigger: BankFlipTrigger.builtInButton,
              width: 340,
            ),
          ),
        ),
      );
      final badgeRect = tester.getRect(find.text('CURRENT'));
      final buttonRect = tester.getRect(find.byIcon(Icons.flip_outlined));
      expect(
        badgeRect.overlaps(buttonRect),
        isFalse,
        reason: 'account-type badge must not collide with the flip button '
            '($direction)',
      );
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
    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('+2.4%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
