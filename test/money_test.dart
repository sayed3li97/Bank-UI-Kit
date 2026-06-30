import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('fromDouble rounds to two decimals', () {
      final m = Money.fromDouble(12.345, 'GBP');
      expect(m.amount, Decimal.parse('12.35'));
      expect(m.currencyCode, 'GBP');
    });

    test('zero is zero', () {
      final z = Money.zero('USD');
      expect(z.isZero, isTrue);
      expect(z.isNegative, isFalse);
    });

    test('addition and subtraction', () {
      final a = Money.fromDouble(10, 'GBP');
      final b = Money.fromDouble(2.50, 'GBP');
      expect((a + b).amount, Decimal.parse('12.50'));
      expect((a - b).amount, Decimal.parse('7.50'));
    });

    test('negative detection', () {
      final m = Money.fromDouble(-5, 'GBP');
      expect(m.isNegative, isTrue);
    });

    test('value equality', () {
      expect(Money.fromDouble(1, 'GBP'), Money.fromDouble(1, 'GBP'));
      expect(
        Money.fromDouble(1, 'GBP'),
        isNot(Money.fromDouble(1, 'USD')),
      );
    });

    test('mixing currencies throws in debug (assertion)', () {
      expect(
        () => Money.fromDouble(1, 'GBP') + Money.fromDouble(1, 'USD'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('BankMoneyFormatter', () {
    test('formats GBP with grouping', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1234.5'),
        currencyCode: 'GBP',
      );
      expect(s.contains('1,234'), isTrue);
    });

    test('showSign prefixes positive amounts', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('10'),
        currencyCode: 'GBP',
        showSign: true,
      );
      expect(s.startsWith('+'), isTrue);
    });

    test('eastern arabic-indic numerals convert digits', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('123'),
        currencyCode: 'AED',
        numeralStyle: NumeralStyle.easternArabicIndic,
      );
      expect(s.contains(RegExp('[0-9]')), isFalse);
      expect(s.contains('١'), isTrue);
    });
  });
}
