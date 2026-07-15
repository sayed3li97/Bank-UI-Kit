/// Controls which numeral script is used when rendering monetary values.
///
/// The [NumeralStyleX] extension on this enum provides a [convert] method
/// that translates an already-formatted string (e.g. produced by `intl`) into
/// the target numeral system.
enum NumeralStyle {
  /// Standard 0-9 digits as used in most Latin-script locales.
  western,

  /// Eastern Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) as used in Arabic-script
  /// locales such as Arabic (ar).
  easternArabicIndic,

  /// Extended (Perso-)Arabic-Indic digits (۰۱۲۳۴۵۶۷۸۹) as used in Persian
  /// (fa), Dari, Pashto, and Urdu. These share a block with
  /// [easternArabicIndic] but four glyphs differ (notably 4, 5, 6), so the
  /// two are not interchangeable.
  persian,

  /// Devanagari digits (०१२३४५६७८९) as used across North-Indian scripts —
  /// Hindi, Marathi, Nepali, and others.
  devanagari,
}

/// Provides numeral-conversion utilities on [NumeralStyle].
extension NumeralStyleX on NumeralStyle {
  /// Converts the ASCII digits in [input] to the target numeral script.
  ///
  /// Non-digit characters (decimal separators, currency symbols, signs, etc.)
  /// are passed through unchanged, preserving the structure produced by `intl`.
  ///
  /// Example:
  /// ```dart
  /// NumeralStyle.easternArabicIndic.convert('1,234.56')
  /// // → '١,٢٣٤.٥٦'
  /// NumeralStyle.persian.convert('1,234.56')
  /// // → '۱,۲۳۴.۵۶'
  /// NumeralStyle.devanagari.convert('1,234.56')
  /// // → '१,२३४.५६'
  /// ```
  String convert(String input) {
    // Western needs no work; every other style maps ASCII 0-9 to the digit at
    // the same index in its ten-glyph table.
    final digits = _digitsFor(this);
    if (digits == null) return input;
    return input.replaceAllMapped(
      RegExp('[0-9]'),
      (Match m) => digits[int.parse(m[0]!)],
    );
  }
}

/// The ordered 0-9 glyph table for [style], or `null` for
/// [NumeralStyle.western] (which is the identity conversion).
List<String>? _digitsFor(NumeralStyle style) {
  switch (style) {
    case NumeralStyle.western:
      return null;
    case NumeralStyle.easternArabicIndic:
      return _easternArabicIndicDigits;
    case NumeralStyle.persian:
      return _persianDigits;
    case NumeralStyle.devanagari:
      return _devanagariDigits;
  }
}

/// Eastern Arabic-Indic digits, indexed 0-9 (U+0660–U+0669).
const List<String> _easternArabicIndicDigits = [
  '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
];

/// Extended (Perso-)Arabic-Indic digits, indexed 0-9 (U+06F0–U+06F9).
const List<String> _persianDigits = [
  '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', //
];

/// Devanagari digits, indexed 0-9 (U+0966–U+096F).
const List<String> _devanagariDigits = [
  '०', '१', '२', '३', '४', '५', '६', '७', '८', '९', //
];
