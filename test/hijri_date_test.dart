import 'package:bank_ui_kit/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reference pairs computed from the official Umm al-Qura comparison
/// calendar (KACST), spread across the supported 1420 to 1500 AH range.
/// Cross-checked against published anchors: Ramadan 1440 began on
/// 2019-05-06, 1 Muharram 1421 fell on 2000-04-06, and 1 Muharram 1448
/// falls on 2026-06-16.
const List<(int, int, int, int, int, int)> _references = [
  // (hijri year, month, day, gregorian year, month, day)
  (1420, 1, 1, 1999, 4, 17),
  (1420, 9, 1, 1999, 12, 9),
  (1421, 1, 1, 2000, 4, 6),
  (1426, 10, 27, 2005, 11, 29),
  (1431, 12, 9, 2010, 11, 15),
  (1440, 9, 1, 2019, 5, 6),
  (1445, 6, 15, 2023, 12, 28),
  (1448, 1, 1, 2026, 6, 16),
  (1452, 3, 30, 2030, 7, 31),
  (1460, 7, 1, 2038, 8, 2),
  (1475, 2, 21, 2052, 10, 14),
  (1489, 11, 30, 2067, 2, 14),
  (1500, 12, 30, 2077, 11, 16),
];

void main() {
  group('BankHijriDate reference dates', () {
    for (final (hy, hm, hd, gy, gm, gd) in _references) {
      test('fromGregorian: $gy-$gm-$gd is $hy-$hm-$hd AH', () {
        expect(
          BankHijriDate.fromGregorian(DateTime(gy, gm, gd)),
          BankHijriDate(hy, hm, hd),
        );
      });

      test('toGregorian: $hy-$hm-$hd AH is $gy-$gm-$gd', () {
        expect(
          BankHijriDate(hy, hm, hd).toGregorian(),
          DateTime(gy, gm, gd),
        );
      });
    }
  });

  group('BankHijriDate conversion invariants', () {
    test('every supported day round-trips and stays well formed', () {
      var date = DateTime(1999, 4, 17);
      final last = DateTime(2077, 11, 16);
      var previous = BankHijriDate.fromGregorian(date);
      var count = 1;

      expect(previous, BankHijriDate(1420, 1, 1));
      expect(previous.toGregorian(), date);

      while (date.isBefore(last)) {
        date = DateTime(date.year, date.month, date.day + 1);
        final hijri = BankHijriDate.fromGregorian(date);
        count++;

        // Round trip.
        expect(hijri.toGregorian(), date);

        // Consecutive Gregorian days advance the Hijri date by one.
        if (hijri.day != 1) {
          expect(hijri.year, previous.year);
          expect(hijri.month, previous.month);
          expect(hijri.day, previous.day + 1);
        } else if (hijri.month != 1) {
          expect(hijri.year, previous.year);
          expect(hijri.month, previous.month + 1);
        } else {
          expect(hijri.year, previous.year + 1);
          expect(previous.month, 12);
        }

        // A month ends only after 29 or 30 days.
        if (hijri.day == 1) {
          expect(previous.day, inInclusiveRange(29, 30));
          expect(
            previous.day,
            BankHijriDate.daysInMonth(previous.year, previous.month),
          );
        }

        previous = hijri;
      }

      expect(previous, BankHijriDate(1500, 12, 30));
      expect(count, 28704);
    });

    test('time of day is ignored', () {
      expect(
        BankHijriDate.fromGregorian(DateTime(2026, 6, 16, 23, 59, 59)),
        BankHijriDate(1448, 1, 1),
      );
    });

    test('daysInMonth matches the Umm al-Qura tables', () {
      expect(BankHijriDate.daysInMonth(1420, 1), 29);
      expect(BankHijriDate.daysInMonth(1448, 1), 29);
      expect(BankHijriDate.daysInMonth(1500, 12), 30);
    });
  });

  group('BankHijriDate range validation', () {
    test('gregorian dates outside the tables throw', () {
      expect(
        () => BankHijriDate.fromGregorian(DateTime(1999, 4, 16)),
        throwsArgumentError,
      );
      expect(
        () => BankHijriDate.fromGregorian(DateTime(2077, 11, 17)),
        throwsArgumentError,
      );
      expect(BankHijriDate.supportsGregorian(DateTime(1999, 4, 16)), isFalse);
      expect(BankHijriDate.supportsGregorian(DateTime(1999, 4, 17)), isTrue);
      expect(BankHijriDate.supportsGregorian(DateTime(2077, 11, 16)), isTrue);
      expect(BankHijriDate.supportsGregorian(DateTime(2077, 11, 17)), isFalse);
    });

    test('hijri components outside the tables throw', () {
      expect(() => BankHijriDate(1419, 12, 29), throwsArgumentError);
      expect(() => BankHijriDate(1501, 1, 1), throwsArgumentError);
      expect(() => BankHijriDate(1448, 0, 1), throwsArgumentError);
      expect(() => BankHijriDate(1448, 13, 1), throwsArgumentError);
      expect(() => BankHijriDate(1448, 1, 0), throwsArgumentError);
      // Muharram 1448 has only 29 days.
      expect(() => BankHijriDate(1448, 1, 30), throwsArgumentError);
    });
  });

  group('BankHijriDate.format', () {
    test('defaults to transliterated names and AH suffix', () {
      expect(
        BankHijriDate.fromGregorian(DateTime(2026, 6, 29)).format(),
        '14 Muharram 1448 AH',
      );
      expect(BankHijriDate(1440, 9, 1).format(), '1 Ramadan 1440 AH');
      expect(
        BankHijriDate(1445, 6, 15).format(),
        '15 Jumada al-Akhirah 1445 AH',
      );
    });

    test('renders eastern Arabic-Indic numerals on request', () {
      expect(
        BankHijriDate(1448, 1, 14).format(
          numeralStyle: NumeralStyle.easternArabicIndic,
        ),
        '١٤ Muharram ١٤٤٨ AH',
      );
    });

    test('honours custom month names and era suffix', () {
      final names = List<String>.generate(12, (i) => 'M${i + 1}');
      expect(
        BankHijriDate(1448, 3, 2).format(monthNames: names, eraSuffix: 'H'),
        '2 M3 1448 H',
      );
      expect(
        BankHijriDate(1448, 3, 2).format(monthNames: names, eraSuffix: ''),
        '2 M3 1448',
      );
    });

    test('rejects month name lists that are not exactly 12 long', () {
      expect(
        () => BankHijriDate(1448, 1, 1).format(monthNames: ['Muharram']),
        throwsArgumentError,
      );
    });
  });

  group('BankHijriDate equality', () {
    test('== and hashCode use year, month, and day', () {
      expect(BankHijriDate(1448, 1, 14), BankHijriDate(1448, 1, 14));
      expect(
        BankHijriDate(1448, 1, 14).hashCode,
        BankHijriDate(1448, 1, 14).hashCode,
      );
      expect(BankHijriDate(1448, 1, 14), isNot(BankHijriDate(1448, 1, 15)));
      expect(BankHijriDate(1448, 1, 14), isNot(BankHijriDate(1448, 2, 14)));
      expect(BankHijriDate(1448, 1, 14), isNot(BankHijriDate(1449, 1, 14)));
    });
  });

  group('BankDateFormatter.formatDual', () {
    test('composes gregorian short date with parenthesized hijri', () {
      expect(
        BankDateFormatter.formatDual(DateTime(2026, 6, 16)),
        '16 Jun 2026 (1 Muharram 1448 AH)',
      );
    });

    test('converts all digits through the numeral style', () {
      expect(
        BankDateFormatter.formatDual(
          DateTime(2026, 6, 16),
          numeralStyle: NumeralStyle.easternArabicIndic,
        ),
        '١٦ Jun ٢٠٢٦ (١ Muharram ١٤٤٨ AH)',
      );
    });

    test('supports custom hijri month names', () {
      expect(
        BankDateFormatter.formatDual(
          DateTime(2019, 5, 6),
          hijriMonthNames: const [
            'Muharram',
            'Safar',
            'Rabi I',
            'Rabi II',
            'Jumada I',
            'Jumada II',
            'Rajab',
            'Shaban',
            'Ramadan',
            'Shawwal',
            'Dhu al-Qadah',
            'Dhu al-Hijjah',
          ],
        ),
        '6 May 2019 (1 Ramadan 1440 AH)',
      );
    });

    test('throws outside the supported Umm al-Qura range', () {
      expect(
        () => BankDateFormatter.formatDual(DateTime(1998, 1, 15)),
        throwsArgumentError,
      );
    });
  });
}
