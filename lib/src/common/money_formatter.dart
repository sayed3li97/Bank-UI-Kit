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
///
/// ## Bidirectional composition
///
/// A money atom mixes a currency marker with a run of digits, and the two
/// have *different* Unicode bidi types. An Arabic marker is Arabic-Letter
/// (AL), which retypes every European digit after it as an Arabic number and
/// drags the grouping and decimal separators with it — so the marker travels
/// inside an FSI/PDI isolate, and the digits stay European wherever the
/// amount lands.
///
/// The gap between them stays *outside* that isolate, on the amount's side
/// of the marker. U+00A0 is bidi class CS, which resolves to ON and then —
/// packed inside an isolate whose only strong character is an Arabic letter
/// — to R by rule N1, so it reorders to the far side of the marker and
/// renders as a leading space with the marker glued to the digits. Left
/// where it belongs it is a lone neutral between the isolate and the number:
/// rule N2 gives it the embedding direction and it holds its place. That is
/// what makes `د.ب 1,234.567` read correctly in an English screen and an
/// Arabic one, with the marker on the side the currency's own placement rule
/// asks for.
///
/// What that does *not* pin is the sign: an unisolated `-$1,234.00` puts its
/// minus on the far end of the number in an Arabic paragraph, because a
/// leading `-` is a neutral and resolves with the paragraph rather than with
/// the digits. Pass `bidiIsolate: true` to wrap the whole atom — sign
/// included — in an LRI/PDI isolate. It is opt-in rather than the default
/// for two reasons: LTR hosts do not have the problem, and a string that
/// *ends* in a directional-format character lays out with a spurious
/// overflow flag in an RTL paragraph under negative letter-spacing, which
/// the kit's own hero numerals use.
abstract final class BankMoneyFormatter {
  /// LEFT-TO-RIGHT ISOLATE — opens a money atom whose internal order is the
  /// currency's, not the paragraph's.
  static const String _lri = '\u2066';

  /// FIRST STRONG ISOLATE — opens the currency marker's own isolate, so its
  /// script is resolved from the marker itself and never leaks outwards.
  static const String _fsi = '\u2068';

  /// POP DIRECTIONAL ISOLATE — closes [_fsi] and [_lri].
  static const String _pdi = '\u2069';

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
  ///
  /// [useIsoCode] swaps the official symbol for the upper-cased ISO 4217
  /// code (`USD 500,000.00`, `BHD 1,000.000`). Reach for it wherever one
  /// list carries more than one currency: symbols are ambiguous by design
  /// (`$` is claimed by a dozen markets) and a mixed list read at a glance
  /// is exactly where that ambiguity turns into a misread figure.
  ///
  /// [bidiIsolate] wraps the whole atom — sign, marker, gap and digits — in
  /// an LRI/PDI isolate, so its internal order is fixed by the currency
  /// rather than by the surrounding paragraph. Turn it on for a host that
  /// renders money inside RTL copy; see the class docs for why it is not the
  /// default.
  static String format({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    String? locale,
    bool showSign = false,
    bool compact = false,
    bool hideFraction = false,
    bool trimZeroCents = false,
    bool useIsoCode = false,
    bool bidiIsolate = false,
  }) {
    final currency = _presentationFor(currencyCode, useIsoCode: useIsoCode);
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

    // The sign has to be composed with the atom rather than prepended to
    // it: prepended, it would sit outside the directional isolate and
    // detach from the number the moment the paragraph runs right-to-left.
    final negative = number.startsWith('-');
    final unsigned = negative ? number.substring(1) : number;
    final sign = _signFor(
      amount,
      negative: negative,
      showSign: showSign,
    );

    return numeralStyle.convert(
      _compose(currency, sign, unsigned, isolate: bidiIsolate),
    );
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
  /// When the atom is bidi-isolated (see the class docs), the opening
  /// isolate leads `major` and the closing one trails whichever part ends
  /// the atom, so the three spans still reassemble byte-for-byte into
  /// [format]'s output — and so a widget cannot render a `major` span that
  /// opens an isolate nothing closes.
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
    bool useIsoCode = false,
    bool bidiIsolate = false,
  }) {
    final currency = _presentationFor(currencyCode, useIsoCode: useIsoCode);
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

    final sign = _signFor(amount, negative: negative, showSign: showSign);
    final marker = _markerFor(currency);

    var major =
        currency.symbolBeforeAmount ? '$sign$marker$intPart' : '$sign$intPart';
    var minorPart = minor;
    var suffix = currency.symbolBeforeAmount ? '' : marker;

    if (bidiIsolate) {
      major = '$_lri$major';
      // The isolate has to close on the *last* span that carries text,
      // otherwise a widget that renders the parts as separate spans emits
      // an unterminated isolate and every glyph after the amount inherits
      // its direction.
      if (suffix.isNotEmpty) {
        suffix = '$suffix$_pdi';
      } else if (minorPart.isNotEmpty) {
        minorPart = '$minorPart$_pdi';
      } else {
        major = '$major$_pdi';
      }
    }

    return (
      major: numeralStyle.convert(major),
      minor: numeralStyle.convert(minorPart),
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
  /// The space is *no-break* on purpose: a marker and its digits are one
  /// reading unit, and a line break between them turns one amount into two
  /// unrelated fragments.
  static String _gapFor(BankCurrency currency) =>
      (currency.spaceBetweenSymbolAndAmount ||
              !BankCurrencies.isKnown(currency.code))
          ? '\u00A0'
          : '';

  /// The presentation metadata to compose with: the registered currency,
  /// or - when [useIsoCode] - a view of it that presents the ISO 4217 code
  /// in the symbol's place.
  ///
  /// The view keeps the currency's minor units (a BHD prize still renders
  /// three decimals) and takes the same spaced, code-leading shape the
  /// unknown-code fallback uses, so a disambiguated list and a degraded one
  /// read as one convention rather than two. It is also, deliberately, not
  /// RTL-script: an ISO code is Latin whichever market it names.
  static BankCurrency _presentationFor(
    String currencyCode, {
    required bool useIsoCode,
  }) {
    final currency = BankCurrencies.of(currencyCode);
    if (!useIsoCode) return currency;
    return BankCurrency(
      code: currency.code,
      symbol: currency.code,
      name: currency.name,
      decimalDigits: currency.decimalDigits,
      spaceBetweenSymbolAndAmount: true,
    );
  }

  /// The sign composed ahead of the amount: `'-'` for negatives, `'+'` for
  /// positives only when the caller asked for it, `''` otherwise.
  static String _signFor(
    Decimal amount, {
    required bool negative,
    required bool showSign,
  }) {
    if (negative) return '-';
    if (showSign && amount > Decimal.zero) return '+';
    return '';
  }

  /// Assembles sign, symbol, gap and [unsigned] digits into one money atom,
  /// wrapped in an LRI/PDI isolate when [isolate] is set.
  ///
  /// The gap travels with the marker (see [_markerFor]) and sits on the
  /// digits' side of it, outside the marker's own FSI/PDI isolate.
  static String _compose(
    BankCurrency currency,
    String sign,
    String unsigned, {
    required bool isolate,
  }) {
    final marker = _markerFor(currency);
    final atom = currency.symbolBeforeAmount
        ? '$sign$marker$unsigned'
        : '$sign$unsigned$marker';
    return isolate ? '$_lri$atom$_pdi' : atom;
  }

  /// The currency marker as one embeddable unit: the symbol — wrapped in an
  /// FSI/PDI isolate when it is written in an RTL script — followed (or
  /// preceded, for a symbol-after currency) by the gap that separates it
  /// from the digits.
  ///
  /// The isolate holds the *letters and nothing else*. That is what stops
  /// Arabic-Letter marker glyphs retyping the European digits beside them,
  /// and it is deliberately all it does: a no-break space packed in with the
  /// marker is a CS neutral surrounded by R, resolves to R, and reorders to
  /// the far side of the marker — which paints a stray space in front of the
  /// marker and glues the marker itself to the first digit, the exact
  /// fallback-font seam the gap exists to prevent. Outside the isolate the
  /// gap is a neutral between an isolate (opaque to the algorithm) and a
  /// number, so it takes the embedding direction and stays put in an LTR and
  /// an RTL paragraph alike.
  static String _markerFor(BankCurrency currency) {
    final symbol = currency.symbol.trim();
    final mark = currency.symbolIsRtlScript ? '$_fsi$symbol$_pdi' : symbol;
    final gap = _gapFor(currency);
    return currency.symbolBeforeAmount ? '$mark$gap' : '$gap$mark';
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
    return formatDateOnly(date);
  }

  static String formatShort(DateTime date) => DateFormat('d MMM').format(date);

  /// The long date with no time component: `'30 June 2026'`.
  static String formatDateOnly(DateTime date) =>
      DateFormat('d MMMM y').format(date);

  static String formatLong(DateTime date) =>
      DateFormat('d MMMM y, HH:mm').format(date);

  /// [formatLong] for values that actually carry a time, [formatDateOnly]
  /// for values that do not.
  ///
  /// Dates that arrive as `DateTime(2026, 6, 30)` — statement periods,
  /// document issue dates, anything parsed from a date-only field — sit at
  /// exactly midnight, and rendering their time prints a `00:00` the
  /// backend never meant. Worse, it is not inert: a customer reading
  /// "30 June 2026, 00:00" has been told a precise instant that is simply
  /// untrue. Use this wherever the timestamp's precision is the source's
  /// choice rather than yours.
  static String formatLongOrDate(DateTime date) =>
      carriesTimeOfDay(date) ? formatLong(date) : formatDateOnly(date);

  /// Whether [date] carries a time of day, i.e. is anything but exact
  /// local midnight.
  ///
  /// Sub-second components count: a value at `00:00:00.001` was produced
  /// by a clock, not by a date-only field.
  static bool carriesTimeOfDay(DateTime date) =>
      date.hour != 0 ||
      date.minute != 0 ||
      date.second != 0 ||
      date.millisecond != 0 ||
      date.microsecond != 0;

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
