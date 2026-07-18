import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Automated WCAG structural gates using Flutter's built-in accessibility
/// guidelines: every interactive kit widget must have a large-enough tap
/// target (the kit's 44px standard, WCAG 2.5.5 / iOS HIG) and an accessible
/// label. These complement the deterministic colour-contrast gate in
/// accessibility_contrast_test.dart.
void main() {
  testWidgets('interactive widgets meet tap-target + label guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: BankUiScope(
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BankBalanceTile(
                  label: 'Available Balance',
                  amount: Money.fromDouble(3565, 'GBP'),
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                BankQuickActionsGrid(
                  actions: [
                    BankQuickAction(
                      id: 'send',
                      icon: Icons.send_rounded,
                      label: 'Send',
                      onTap: () {},
                    ),
                    BankQuickAction(
                      id: 'scan',
                      icon: Icons.qr_code_rounded,
                      label: 'Scan',
                      onTap: () {},
                    ),
                    BankQuickAction(
                      id: 'topup',
                      icon: Icons.add_rounded,
                      label: 'Top up',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
