import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit_example/demo/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeDashboard renders under the Studio preset', (tester) async {
    await tester.pumpWidget(
      BankUiScope(
        initialData: const BankUiScopeData(),
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: const HomeDashboard(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
  });
}
