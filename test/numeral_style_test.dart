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

    test('non-digit characters are preserved', () {
      expect(
        NumeralStyle.easternArabicIndic.convert(r'£9 + $0'),
        r'£٩ + $٠',
      );
    });
  });
}
