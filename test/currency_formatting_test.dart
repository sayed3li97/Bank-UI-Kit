import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.fromDouble honours ISO 4217 minor units', () {
    test('3-decimal currency keeps three places', () {
      expect(
        Money.fromDouble(1234.567, 'KWD').amount,
        Decimal.parse('1234.567'),
      );
    });

    test('2-decimal currency keeps two places', () {
      expect(
        Money.fromDouble(1234.567, 'USD').amount,
        Decimal.parse('1234.57'),
      );
    });

    test('0-decimal currency keeps whole units', () {
      expect(Money.fromDouble(1000.4, 'JPY').amount, Decimal.parse('1000'));
    });
  });

  group('BankMoneyFormatter renders each currency correctly', () {
    final amount = Decimal.parse('1234567.891');

    test('2-decimal, prefix symbol (USD)', () {
      final s = BankMoneyFormatter.format(amount: amount, currencyCode: 'USD');
      expect(s, contains(r'$'));
      expect(s, contains('1,234,567.89'));
    });

    test('0-decimal (JPY) drops the fraction', () {
      final s = BankMoneyFormatter.format(amount: amount, currencyCode: 'JPY');
      expect(s, contains('1,234,568'));
      expect(s.contains('.'), isFalse);
    });

    test('3-decimal (KWD) keeps three places', () {
      final s = BankMoneyFormatter.format(amount: amount, currencyCode: 'KWD');
      expect(s, contains('1,234,567.891'));
    });

    test('suffix symbol currency (SEK) places the symbol after', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1234.5'),
        currencyCode: 'SEK',
      );
      expect(s.trim().endsWith('kr'), isTrue);
    });

    test('Arabic-Indic numeral style converts the digits', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1234.5'),
        currencyCode: 'AED',
        numeralStyle: NumeralStyle.easternArabicIndic,
      );
      // No Western digits should remain in the numeric portion.
      expect(RegExp(r'[0-9]').hasMatch(s), isFalse);
    });
  });

  group('BankCurrencies registry', () {
    test('knows minor units for special currencies', () {
      expect(BankCurrencies.of('KWD').decimalDigits, 3);
      expect(BankCurrencies.of('JPY').decimalDigits, 0);
      expect(BankCurrencies.of('USD').decimalDigits, 2);
    });

    test('enumerates and reports known codes', () {
      expect(BankCurrencies.isKnown('KWD'), isTrue);
      expect(BankCurrencies.isKnown('ZZZ'), isFalse);
      expect(BankCurrencies.all, isNotEmpty);
      expect(BankCurrencies.codes, contains('USD'));
    });

    test('register adds a custom currency (e.g. crypto)', () {
      BankCurrencies.register(
        const BankCurrency(
          code: 'BTC',
          symbol: '₿',
          name: 'Bitcoin',
          decimalDigits: 8,
        ),
      );
      expect(BankCurrencies.isKnown('BTC'), isTrue);
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('0.12345678'),
        currencyCode: 'BTC',
      );
      expect(s, contains('0.12345678'));
      expect(s, contains('₿'));
    });
  });
}
