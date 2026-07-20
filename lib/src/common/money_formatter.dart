import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

// BankHijriDate is hidden from the barrel imports so the sibling file
// is bound directly via its relative path.
import '../../bank_ui_kit.dart' hide BankHijriDate;
import '../../core.dart' hide BankHijriDate;
import 'bank_hijri_date.dart';

/// Formats [Money]-like amount + currency for display, respecting
/// [NumeralStyle] and each currency's own presentation guidelines
/// (official symbol, ISO 4217 minor units, symbol placement) as
/// registered in [BankCurrencies].
///
/// ## Presentation contract
///
/// - **Known currencies** render with their official symbol and that
///   currency's own placement/spacing convention (`£2,480.55`,
///   `1 234,56 kr`).
/// - **Unknown codes** degrade *deliberately*: the upper-cased ISO code is
///   used as the symbol and is always separated from the grouped amount by
///   a no-break space — `ZZZ 2,480.55` — never an unspaced `ZZZ2480.55`
///   and never an ungrouped raw number. Widgets should therefore always go
///   through this formatter rather than concatenating `'$code $amount'`
///   by hand.
/// - **Whole amounts** can drop their zero minor units at display sites
///   (hero figures, promotional offers, axis labels) via [format]'s
///   `trimZeroCents`; transactional records should keep the default and
///   render full minor units.
/// - Widgets that want to de-emphasise minor units (smaller pence, like
///   the major banking apps) should compose from [splitMajorMinor] instead
///   of restyling a substring of [format]'s output.
abstract final class BankMoneyFormatter {
  /// Formats [amount] for [currencyCode].
  ///
  /// [locale] controls digit grouping and the decimal separator (e.g. German
  /// `1.234.567,89`, French `1 234 567,89`, Indian `12,34,567.89`). Pass the
  /// app's locale — `Localizations.localeOf(context).toString()` — so money
  /// reads correctly per market; when null the ambient `Intl` locale is used.
  /// [numeralStyle] independently controls the numeral *script* (Western vs
  /// Arabic-Indic vs Persian vs Devanagari) applied after grouping.
  ///
  /// When [trimZeroCents] is `true`, an amount that is whole at the
  /// currency's minor-unit scale renders without its fraction —
  /// `£25,000` instead of `£25,000.00` — while non-whole amounts keep
  /// full minor units (`£25,000.50`). Use it for hero/promotional
  /// figures and axis labels; keep it off for transactional records.
  static String format({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    String? locale,
    bool showSign = false,
    bool compact = false,
    bool hideFraction = false,
    bool trimZeroCents = false,
  }) {
    final currency = BankCurrencies.of(currencyCode);
    final digits = _digitsFor(
      currency,
      amount,
      hideFraction: hideFraction,
      trimZeroCents: trimZeroCents,
    );

    final String number;
    if (compact) {
      number = NumberFormat.compact(locale: locale).format(amount.toDouble());
    } else {
      final fmt = NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: digits,
      );
      number = fmt.format(amount.toDouble());
    }

    var result = _compose(currency, number);

    if (showSign && amount > Decimal.zero) {
      result = '+$result';
    }

    return numeralStyle.convert(result);
  }

  static String formatSign({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    String? locale,
  }) =>
      format(
        amount: amount,
        currencyCode: currencyCode,
        numeralStyle: numeralStyle,
        locale: locale,
        showSign: true,
      );

  /// The bare display symbol for [currencyCode], suitable for input
  /// prefixes and axis labels.
  static String symbolFor(String currencyCode) =>
      BankCurrencies.of(currencyCode).embeddableSymbol.trim();

  /// Formats [amount] like [format], but split into typographic parts so
  /// widgets can de-emphasise the minor units (render the pence smaller
  /// and lighter than the pounds, the way premium banking apps do).
  ///
  /// Returns a record whose concatenation `major + minor + suffix` is
  /// character-for-character identical to [format] called with the same
  /// arguments:
  ///
  /// - `major` — sign, any leading symbol, and the grouped integer part
  ///   (`'\u00A32,480'`, `'-1 234'`);
  /// - `minor` — the locale decimal separator plus fraction digits
  ///   (`'.55'`), or `''` when the currency has no minor units, or when
  ///   [trimZeroCents] drops a zero fraction;
  /// - `suffix` — a trailing symbol with its gap for symbol-after
  ///   currencies (a no-break space plus `'kr'`), otherwise `''`.
  ///   Keep it at full size: only `minor` is meant to shrink.
  ///
  /// ```dart
  /// final parts = BankMoneyFormatter.splitMajorMinor(
  ///   amount: Decimal.parse('2480.55'),
  ///   currencyCode: 'GBP',
  /// );
  /// Text.rich(TextSpan(children: [
  ///   TextSpan(text: parts.major),
  ///   TextSpan(text: parts.minor, style: minorUnitStyle),
  ///   TextSpan(text: parts.suffix),
  /// ]));
  /// ```
  static ({String major, String minor, String suffix}) splitMajorMinor({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    String? locale,
    bool showSign = false,
    bool hideFraction = false,
    bool trimZeroCents = false,
  }) {
    final currency = BankCurrencies.of(currencyCode);
    final digits = _digitsFor(
      currency,
      amount,
      hideFraction: hideFraction,
      trimZeroCents: trimZeroCents,
    );

    final fmt = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: digits,
    );
    final number = fmt.format(amount.toDouble());

    final negative = number.startsWith('-');
    final unsigned = negative ? number.substring(1) : number;

    final decimalSep = fmt.symbols.DECIMAL_SEP;
    final sepIndex = unsigned.lastIndexOf(decimalSep);
    final intPart = sepIndex < 0 ? unsigned : unsigned.substring(0, sepIndex);
    final minor = sepIndex < 0 ? '' : unsigned.substring(sepIndex);

    final sign = negative
        ? '-'
        : (showSign && amount > Decimal.zero)
            ? '+'
            : '';
    final symbol = currency.embeddableSymbol.trim();
    final gap = _gapFor(currency);

    final String major;
    final String suffix;
    if (currency.symbolBeforeAmount) {
      major = '$sign$symbol$gap$intPart';
      suffix = '';
    } else {
      major = '$sign$intPart';
      suffix = '$gap$symbol';
    }

    return (
      major: numeralStyle.convert(major),
      minor: numeralStyle.convert(minor),
      suffix: numeralStyle.convert(suffix),
    );
  }

  /// The minor-unit digit count to render: the currency's ISO 4217 scale,
  /// zeroed when the caller hides the fraction or when [trimZeroCents]
  /// applies to a whole amount (evaluated *after* rounding to the
  /// currency's scale, so `1999.999` still renders `2,000.00`\u2026 \u2192 `2,000`).
  static int _digitsFor(
    BankCurrency currency,
    Decimal amount, {
    required bool hideFraction,
    required bool trimZeroCents,
  }) {
    if (hideFraction) return 0;
    final digits = currency.decimalDigits;
    if (trimZeroCents && digits > 0) {
      final rounded = amount.round(scale: digits);
      if (rounded.isInteger) return 0;
    }
    return digits;
  }

  /// The gap between symbol and amount. Currencies that specify a gap get
  /// a no-break space; unknown codes (whose "symbol" is the ISO code
  /// itself) always get one, so a degraded rendering is deliberately
  /// `ZZZ 2,480.55` — code, no-break space, grouped amount — and never an
  /// unspaced `ZZZ2480.55`.
  static String _gapFor(BankCurrency currency) =>
      (currency.spaceBetweenSymbolAndAmount ||
              !BankCurrencies.isKnown(currency.code))
          ? '\u00A0'
          : '';

  static String _compose(BankCurrency currency, String number) {
    // A negative amount keeps its sign ahead of a leading symbol.
    final negative = number.startsWith('-');
    final unsigned = negative ? number.substring(1) : number;
    final symbol = currency.embeddableSymbol.trim();
    final gap = _gapFor(currency);

    final composed = currency.symbolBeforeAmount
        ? '$symbol$gap$unsigned'
        : '$unsigned$gap$symbol';
    return negative ? '-$composed' : composed;
  }
}

/// Formats a [DateTime] relative to today using [BankUiStrings]-compatible
/// labels.
abstract final class BankDateFormatter {
  static String formatGroupHeader({
    required DateTime date,
    required String todayLabel,
    required String yesterdayLabel,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return todayLabel;
    if (diff == 1) return yesterdayLabel;
    return DateFormat('d MMMM y').format(date);
  }

  static String formatShort(DateTime date) => DateFormat('d MMM').format(date);

  static String formatLong(DateTime date) =>
      DateFormat('d MMMM y, HH:mm').format(date);

  static String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  static String formatFull(DateTime date) =>
      DateFormat('EEE d MMM y').format(date);

  /// Dual-calendar date for GCC audiences: the Gregorian short date
  /// followed by the parenthesized Umm al-Qura equivalent, e.g.
  /// `'16 Jun 2026 (1 Muharram 1448 AH)'`.
  ///
  /// The Hijri part is produced by [BankHijriDate.format] with
  /// [hijriMonthNames] (defaults to the English transliterations) and
  /// all digits are rendered through [numeralStyle]. Throws
  /// [ArgumentError] when [date] is outside the supported Umm al-Qura
  /// range; probe with [BankHijriDate.supportsGregorian] first when
  /// the input is not under your control.
  static String formatDual(
    DateTime date, {
    NumeralStyle numeralStyle = NumeralStyle.western,
    List<String>? hijriMonthNames,
  }) {
    final gregorian = DateFormat('d MMM y').format(date);
    final hijri = BankHijriDate.fromGregorian(date).format(
      monthNames: hijriMonthNames,
    );
    return numeralStyle.convert('$gregorian ($hijri)');
  }

  /// Compact relative time for activity feeds: `just now`, `5m ago`,
  /// `2h ago`, `3d ago`, then [formatShort] beyond a week.
  static String formatRelative(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShort(date);
  }
}
