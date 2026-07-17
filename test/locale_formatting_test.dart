import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final amount = Decimal.parse('1234567.89');

  group('BankMoneyFormatter is locale-aware', () {
    test('US English uses comma grouping + dot decimal', () {
      final s = BankMoneyFormatter.format(
        amount: amount,
        currencyCode: 'USD',
        locale: 'en',
      );
      expect(s, contains('1,234,567.89'));
    });

    test('German uses dot grouping + comma decimal', () {
      final s = BankMoneyFormatter.format(
        amount: amount,
        currencyCode: 'EUR',
        locale: 'de',
      );
      expect(s, contains('1.234.567,89'));
    });

    test('French uses space grouping + comma decimal', () {
      final s = BankMoneyFormatter.format(
        amount: amount,
        currencyCode: 'EUR',
        locale: 'fr',
      );
      // intl uses a non-breaking / narrow space; assert the comma decimal and
      // that no ASCII comma grouping leaked in.
      expect(s, contains(',89'));
      expect(s.contains('1,234,567'), isFalse);
    });

    test('Indian English uses lakh/crore grouping', () {
      final s = BankMoneyFormatter.format(
        amount: amount,
        currencyCode: 'INR',
        locale: 'en_IN',
      );
      expect(s, contains('12,34,567.89'));
    });

    test('null locale falls back without throwing', () {
      final s = BankMoneyFormatter.format(
        amount: amount,
        currencyCode: 'USD',
      );
      expect(s, isNotEmpty);
    });
  });

  testWidgets('BankBalanceText follows the ambient Localizations locale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: BankUiScope(
          child: Scaffold(
            body: Builder(
              // Override just the locale, reusing the app's delegates, so the
              // widget sees `de` without needing a de MaterialLocalizations.
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('de'),
                child: Center(
                  child: BankBalanceText(
                    money: Money.fromDouble(1234567.89, 'EUR'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // German grouping should appear because the widget resolved the locale.
    expect(find.textContaining('1.234.567,89'), findsOneWidget);
  });
}
