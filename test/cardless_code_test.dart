import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return BankUiScope(
    child: MaterialApp(
      theme: BankPreset.studio.apply(ThemeData(useMaterial3: true)),
      home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
    ),
  );
}

void main() {
  testWidgets('countdown ring shows m:ss for a minutes-scale window',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankCardlessCashCode(
          code: '482913',
          expiresAt: DateTime.now().add(const Duration(minutes: 14)),
          amount: Money.fromDouble(150, 'GBP'),
        ),
      ),
    );
    // 13:59 or 14:00 depending on tick timing; both are m:ss.
    expect(
      find.textContaining(RegExp(r'^\d{1,2}:\d{2}$')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pathological far-future expiry renders short day text, no overflow',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankCardlessCashCode(
          code: '482913',
          expiresAt: DateTime.now().add(const Duration(days: 164, hours: 5)),
          amount: Money.fromDouble(150, 'GBP'),
        ),
      ),
    );
    // Days-scale windows collapse to '<n>d' instead of a six-figure
    // minute count that wraps across the ring.
    expect(find.text('164d'), findsOneWidget);
    // The ring text sits inside a FittedBox so no input can overlap the
    // ring stroke.
    expect(
      find.ancestor(
        of: find.text('164d'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hours-scale window renders h:mm', (tester) async {
    await tester.pumpWidget(
      _host(
        BankCardlessCashCode(
          code: '482913',
          expiresAt: DateTime.now().add(const Duration(hours: 23, minutes: 59)),
          amount: Money.fromDouble(150, 'GBP'),
        ),
      ),
    );
    expect(
      find.textContaining(RegExp(r'^23:5[89]$')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
