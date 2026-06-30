/// Controls which numeral script is used when rendering monetary values.
///
/// The [NumeralStyleX] extension on this enum provides a [convert] method
/// that translates an already-formatted string (e.g. produced by `intl`) into
/// the target numeral system.
enum NumeralStyle {
  /// Standard 0-9 digits as used in most Latin-script locales.
  western,

  /// Eastern Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) as used in Arabic-script
  /// locales such as Arabic (ar), Persian (fa), and Urdu (ur).
  easternArabicIndic,
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
  /// ```
  String convert(String input) {
    switch (this) {
      case NumeralStyle.western:
        // Already in western digits; return the string as-is.
        return input;

      case NumeralStyle.easternArabicIndic:
        return input.replaceAllMapped(
          RegExp('[0-9]'),
          (Match m) => _easternArabicIndicDigits[m[0]]!,
        );
    }
  }
}

/// Lookup table from ASCII digit to Eastern Arabic-Indic equivalent.
const Map<String, String> _easternArabicIndicDigits = {
  '0': '٠', // ٠
  '1': '١', // ١
  '2': '٢', // ٢
  '3': '٣', // ٣
  '4': '٤', // ٤
  '5': '٥', // ٥
  '6': '٦', // ٦
  '7': '٧', // ٧
  '8': '٨', // ٨
  '9': '٩', // ٩
};
