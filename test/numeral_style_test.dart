import 'package:bank_ui_kit/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumeralStyleX.convert', () {
    test('western passes through unchanged', () {
      expect(NumeralStyle.western.convert('1,234.56'), '1,234.56');
    });

    test('easternArabicIndic converts digits but keeps separators', () {
      expect(
        NumeralStyle.easternArabicIndic.convert('1,234.56'),
        '١,٢٣٤.٥٦',
      );
    });

    test('persian uses Extended Arabic-Indic digits', () {
      expect(NumeralStyle.persian.convert('1,234.56'), '۱,۲۳۴.۵۶');
    });

    test('persian differs from easternArabicIndic on 4/5/6', () {
      // The two blocks share glyphs for most digits but diverge here; guard
      // against accidentally reusing the Arabic-Indic table for Persian.
      expect(NumeralStyle.persian.convert('456'), '۴۵۶');
      expect(NumeralStyle.easternArabicIndic.convert('456'), '٤٥٦');
      expect(
        NumeralStyle.persian.convert('456'),
        isNot(NumeralStyle.easternArabicIndic.convert('456')),
      );
    });

    test('devanagari uses Devanagari digits', () {
      expect(NumeralStyle.devanagari.convert('1,234.56'), '१,२३४.५६');
    });

    test('non-digit characters are preserved', () {
      expect(
        NumeralStyle.easternArabicIndic.convert(r'£9 + $0'),
        r'£٩ + $٠',
      );
      expect(NumeralStyle.devanagari.convert(r'£9 + $0'), r'£९ + $०');
    });

    test('every style maps all ten digits one-to-one', () {
      for (final style in NumeralStyle.values) {
        final converted = style.convert('0123456789');
        // Ten output characters (all BMP digits are single code units here).
        expect(converted.length, 10, reason: '$style');
        // Round-trips are unique per style (no collisions/gaps in the table).
        expect(converted.split('').toSet().length, 10, reason: '$style');
      }
    });
  });
}
