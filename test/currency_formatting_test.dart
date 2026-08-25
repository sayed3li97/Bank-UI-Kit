import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// LEFT-TO-RIGHT ISOLATE — opens a `bidiIsolate: true` money atom.
const String lri = '\u2066';

/// FIRST STRONG ISOLATE — opens an RTL-script currency marker.
const String fsi = '\u2068';

/// POP DIRECTIONAL ISOLATE — closes [lri] and [fsi].
const String pdi = '\u2069';

/// NO-BREAK SPACE — the gap between a currency marker and its digits.
const String nbsp = '\u00A0';

/// The Gulf currencies whose marker is written in Arabic script, with the
/// minor-unit count each one renders at.
const Map<String, int> rtlMarkerCurrencies = {
  'BHD': 3,
  'KWD': 3,
  'OMR': 3,
  'SAR': 2,
  'AED': 2,
};

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
      expect(RegExp('[0-9]').hasMatch(s), isFalse);
    });
  });

  group('trimZeroCents drops zero minor units only', () {
    test('whole amount renders without the fraction', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('25000'),
          currencyCode: 'GBP',
          trimZeroCents: true,
        ),
        '£25,000',
      );
    });

    test('non-whole amount keeps full minor units', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('2480.55'),
          currencyCode: 'GBP',
          trimZeroCents: true,
        ),
        '£2,480.55',
      );
    });

    test('wholeness is judged after rounding to the currency scale', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1999.999'),
          currencyCode: 'GBP',
          trimZeroCents: true,
        ),
        '£2,000',
      );
    });

    test('default (off) keeps the zero fraction', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('25000'),
          currencyCode: 'GBP',
        ),
        '£25,000.00',
      );
    });

    test('zero-decimal currency is unaffected', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1000'),
          currencyCode: 'JPY',
          trimZeroCents: true,
        ),
        '¥1,000',
      );
    });
  });

  group('splitMajorMinor decomposes exactly like format', () {
    test('prefix-symbol currency puts symbol in major', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('2480.55'),
        currencyCode: 'GBP',
      );
      expect(parts.major, '£2,480');
      expect(parts.minor, '.55');
      expect(parts.suffix, '');
    });

    test('suffix-symbol currency puts symbol in suffix', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('1234.5'),
        currencyCode: 'SEK',
      );
      expect(parts.major, '1,234');
      expect(parts.minor, '.50');
      expect(parts.suffix, '\u00A0kr');
    });

    test('concatenation is identical to format for signed amounts', () {
      for (final raw in ['2480.55', '-2480.55', '25000', '0.05']) {
        for (final code in ['GBP', 'SEK', 'JPY', 'KWD', 'ZZZ']) {
          final amount = Decimal.parse(raw);
          final parts = BankMoneyFormatter.splitMajorMinor(
            amount: amount,
            currencyCode: code,
            showSign: true,
          );
          expect(
            parts.major + parts.minor + parts.suffix,
            BankMoneyFormatter.format(
              amount: amount,
              currencyCode: code,
              showSign: true,
            ),
            reason: '$raw $code must reassemble exactly',
          );
        }
      }
    });

    test('negative amount keeps the sign ahead of a leading symbol', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('-2480.55'),
        currencyCode: 'GBP',
      );
      expect(parts.major, '-£2,480');
      expect(parts.minor, '.55');
    });

    test('trimZeroCents empties minor for whole amounts', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('25000'),
        currencyCode: 'GBP',
        trimZeroCents: true,
      );
      expect(parts.major, '£25,000');
      expect(parts.minor, '');
    });

    test('zero-decimal currency has an empty minor', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('1000'),
        currencyCode: 'JPY',
      );
      expect(parts.major, '¥1,000');
      expect(parts.minor, '');
    });
  });

  group('unknown currency codes degrade deliberately', () {
    test('code + no-break space + grouped amount', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('2480.55'),
          currencyCode: 'ZZZ',
        ),
        'ZZZ\u00A02,480.55',
      );
    });

    test('lower-case unknown codes are upper-cased', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('10'),
          currencyCode: 'zzq',
        ),
        'ZZQ\u00A010.00',
      );
    });
  });

  // ---------------------------------------------------------------------
  // The gap belongs on the amount's side of the marker and OUTSIDE the
  // marker's own isolate. U+00A0 is bidi class CS: enclosed with an Arabic
  // marker it resolves right-to-left along with the letters and reorders to
  // the marker's far side, which paints a leading space and glues the marker
  // to the first digit.
  // ---------------------------------------------------------------------
  group('the currency gap sits outside the marker isolate', () {
    test('a Bahraini dinar renders marker, no-break space, digits', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1234.567'),
          currencyCode: 'BHD',
          locale: 'en',
        ),
        '$fsiد.ب$pdi${nbsp}1,234.567',
      );
    });

    test('every RTL-script marker composes the same way', () {
      for (final entry in rtlMarkerCurrencies.entries) {
        final code = entry.key;
        final symbol = BankCurrencies.of(code).symbol;
        final fraction = '5'.padRight(entry.value, '0');
        expect(
          BankMoneyFormatter.format(
            amount: Decimal.parse('1234.5'),
            currencyCode: code,
            locale: 'en',
          ),
          '$fsi$symbol$pdi${nbsp}1,234.$fraction',
          reason: '$code put its gap on the wrong side of the marker',
        );
      }
    });

    test('the no-break space never sits inside the isolate', () {
      for (final code in rtlMarkerCurrencies.keys) {
        final s = BankMoneyFormatter.format(
          amount: Decimal.parse('1234.5'),
          currencyCode: code,
          locale: 'en',
        );
        expect(
          s.contains('$pdi$nbsp'),
          isTrue,
          reason: '$code lost the gap on the amount side of its marker',
        );
        expect(
          s.contains('$nbsp$pdi'),
          isFalse,
          reason: '$code packed the gap inside its isolate',
        );
      }
    });

    test('a negative Gulf amount orders sign, marker, gap, digits', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-1234.567'),
          currencyCode: 'BHD',
          locale: 'en',
        ),
        '-$fsiد.ب$pdi${nbsp}1,234.567',
      );
    });

    test('bidiIsolate wraps the whole atom without moving the gap', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-1234.567'),
          currencyCode: 'BHD',
          locale: 'en',
          bidiIsolate: true,
        ),
        '$lri-$fsiد.ب$pdi${nbsp}1,234.567$pdi',
      );
    });

    test('splitMajorMinor carries marker and gap on the major span', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('1234.567'),
        currencyCode: 'BHD',
        locale: 'en',
      );
      expect(parts.major, '$fsiد.ب$pdi${nbsp}1,234');
      expect(parts.minor, '.567');
      expect(parts.suffix, '');
    });

    test('a Gulf amount ends in a digit, never in a format character', () {
      for (final code in rtlMarkerCurrencies.keys) {
        for (final raw in ['1234.5', '-1234.5', '0']) {
          expect(
            BankMoneyFormatter.format(
              amount: Decimal.parse(raw),
              currencyCode: code,
              locale: 'en',
            ).endsWith(pdi),
            isFalse,
            reason: '$code $raw ends in a directional-format character',
          );
        }
      }
    });

    test('useIsoCode presents a Latin code with no isolate at all', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1234.567'),
        currencyCode: 'BHD',
        locale: 'en',
        useIsoCode: true,
      );
      expect(s, 'BHD${nbsp}1,234.567');
      expect(s.contains(fsi), isFalse);
    });
  });

  group('Latin-marker currencies compose exactly', () {
    test('zero-decimal currencies render whole units, unspaced', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1000'),
          currencyCode: 'JPY',
          locale: 'en',
        ),
        '¥1,000',
      );
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1234567'),
          currencyCode: 'KRW',
          locale: 'en',
        ),
        '₩1,234,567',
      );
    });

    test('a trailing-symbol currency keeps the gap ahead of the symbol', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1234.5'),
          currencyCode: 'SEK',
          locale: 'en',
        ),
        '1,234.50${nbsp}kr',
      );
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1000'),
          currencyCode: 'VND',
          locale: 'en',
        ),
        '1,000$nbsp₫',
      );
    });

    test('a negative amount keeps its sign ahead of the whole atom', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-2480.55'),
          currencyCode: 'GBP',
          locale: 'en',
        ),
        '-£2,480.55',
      );
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-1234.5'),
          currencyCode: 'SEK',
          locale: 'en',
        ),
        '-1,234.50${nbsp}kr',
      );
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
