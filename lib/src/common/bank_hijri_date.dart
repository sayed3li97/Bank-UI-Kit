import 'package:flutter/foundation.dart';

import '../theme/numeral_style.dart';

/// A calendar date in the Umm al-Qura Hijri calendar, the civil
/// calendar of Saudi Arabia and the reference calendar for Islamic
/// banking milestones across the GCC (hawl anniversaries, Ramadan
/// campaigns, profit distribution dates).
///
/// Conversions are table driven: the encoded data reproduces the month
/// lengths of the official Umm al-Qura comparison calendar published
/// by KACST (King Abdulaziz City for Science and Technology), covering
/// 1 Muharram 1420 AH (17 April 1999 CE) through 30 Dhu al-Hijjah
/// 1500 AH (16 November 2077 CE). [fromGregorian], [toGregorian], and
/// the constructor throw [ArgumentError] for dates outside that range,
/// so every reachable instance is a valid Umm al-Qura date.
///
/// Only the calendar date components of a [DateTime] are read; the
/// time of day and time zone are ignored.
///
/// ```dart
/// final hijri = BankHijriDate.fromGregorian(DateTime(2026, 6, 29));
/// hijri.format(); // '14 Muharram 1448 AH'
/// hijri.format(numeralStyle: NumeralStyle.easternArabicIndic);
/// // '١٤ Muharram ١٤٤٨ AH'
/// ```
@immutable
class BankHijriDate {
  /// Creates an Umm al-Qura date, validating [year], [month], and
  /// [day] against the encoded tables.
  ///
  /// Throws [ArgumentError] when [year] is outside [minYear] to
  /// [maxYear], [month] is outside 1 to 12, or [day] is outside the
  /// actual length of that Umm al-Qura month.
  BankHijriDate(this.year, this.month, this.day) {
    final length = daysInMonth(year, month);
    if (day < 1 || day > length) {
      throw ArgumentError.value(
        day,
        'day',
        'Month $month of $year AH has $length days in the '
            'Umm al-Qura calendar.',
      );
    }
  }

  /// Hijri year (anno Hegirae), between [minYear] and [maxYear].
  final int year;

  /// Hijri month, 1 (Muharram) through 12 (Dhu al-Hijjah).
  final int month;

  /// Day of the Hijri month, 1 through 29 or 30.
  final int day;

  /// First supported Hijri year: 1420 AH (began 17 April 1999 CE).
  static const int minYear = 1420;

  /// Last supported Hijri year: 1500 AH (ends 16 November 2077 CE).
  static const int maxYear = 1500;

  /// English transliterated month names used by [format] when no
  /// custom names are supplied.
  static const List<String> defaultMonthNames = <String>[
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];

  /// Julian day number of 1 Muharram 1420 AH (17 April 1999 CE), the
  /// first day covered by [_monthLengthBits].
  static const int _epochJdn = 2451286;

  /// Total days covered by the table: 1 Muharram 1420 AH through
  /// 30 Dhu al-Hijjah 1500 AH inclusive.
  static const int _totalDays = 28704;

  /// Packed Umm al-Qura month lengths, one entry per Hijri year from
  /// [minYear] to [maxYear]. Bit `m` (zero based) is set when month
  /// `m + 1` has 30 days and clear when it has 29 days.
  ///
  /// Encoded from the official KACST Umm al-Qura comparison calendar
  /// (the same month starts tabulated by R.H. van Gent and shipped in
  /// the audited `hijridate` dataset) for 1420 to 1500 AH.
  static const List<int> _monthLengthBits = <int>[
    0xbd2,
    0xbc4,
    0xb89,
    0xa95,
    0x52d,
    0x5ad,
    0xb6a,
    0x6d4,
    0xdc9,
    0xd92,
    0xaa6,
    0x956,
    0x2ae,
    0x56d,
    0x36a,
    0xb55,
    0xaaa,
    0x94d,
    0x49d,
    0x95d,
    0x2ba,
    0x5b5,
    0x5aa,
    0xd55,
    0xa9a,
    0x92e,
    0x26e,
    0x55d,
    0xada,
    0x6d4,
    0x6a5,
    0x54b,
    0xa97,
    0x54e,
    0xaae,
    0x5ac,
    0xba9,
    0xd92,
    0xb25,
    0x64b,
    0xcab,
    0x55a,
    0xb55,
    0x6d2,
    0xea5,
    0xe4a,
    0xa95,
    0x52d,
    0xaad,
    0x36c,
    0x759,
    0x6d2,
    0x695,
    0x52d,
    0xa5b,
    0x4ba,
    0x9ba,
    0x3b4,
    0xb69,
    0xb52,
    0xaa6,
    0x4b6,
    0x96d,
    0x2ec,
    0x6d9,
    0xeb2,
    0xd54,
    0xd2a,
    0xa56,
    0x4ae,
    0x96d,
    0xd6a,
    0xb54,
    0xb29,
    0xa93,
    0x52b,
    0xa57,
    0x536,
    0xab5,
    0x6aa,
    0xe93,
  ];

  /// Converts the calendar date of [date] to its Umm al-Qura
  /// equivalent.
  ///
  /// Throws [ArgumentError] when [date] falls before 17 April 1999 or
  /// after 16 November 2077, the bounds of the encoded tables. Use
  /// [supportsGregorian] to probe first when the input is not under
  /// your control.
  static BankHijriDate fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    var remaining = jdn - _epochJdn;
    if (remaining < 0 || remaining >= _totalDays) {
      throw ArgumentError.value(
        date,
        'date',
        'Outside the supported Umm al-Qura range '
            '(1999-04-17 to 2077-11-16 CE, $minYear to $maxYear AH).',
      );
    }

    var year = minYear;
    var yearLength = _yearLength(year);
    while (remaining >= yearLength) {
      remaining -= yearLength;
      year += 1;
      yearLength = _yearLength(year);
    }

    var month = 1;
    var monthLength = daysInMonth(year, month);
    while (remaining >= monthLength) {
      remaining -= monthLength;
      month += 1;
      monthLength = daysInMonth(year, month);
    }

    return BankHijriDate(year, month, remaining + 1);
  }

  /// Whether [date] falls inside the supported conversion range, so
  /// [fromGregorian] would succeed.
  static bool supportsGregorian(DateTime date) {
    final offset = _gregorianToJdn(date.year, date.month, date.day) - _epochJdn;
    return offset >= 0 && offset < _totalDays;
  }

  /// Length in days (29 or 30) of [month] in Hijri [year] according to
  /// the Umm al-Qura tables.
  ///
  /// Throws [ArgumentError] when [year] is outside [minYear] to
  /// [maxYear] or [month] is outside 1 to 12.
  static int daysInMonth(int year, int month) {
    if (year < minYear || year > maxYear) {
      throw ArgumentError.value(
        year,
        'year',
        'Umm al-Qura data covers $minYear to $maxYear AH.',
      );
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12.');
    }
    final thirtyDays = (_monthLengthBits[year - minYear] >> (month - 1)) & 1;
    return thirtyDays == 1 ? 30 : 29;
  }

  /// Converts this date back to the Gregorian calendar as a [DateTime]
  /// at local midnight.
  DateTime toGregorian() {
    var offset = 0;
    for (var y = minYear; y < year; y++) {
      offset += _yearLength(y);
    }
    for (var m = 1; m < month; m++) {
      offset += daysInMonth(year, m);
    }
    offset += day - 1;
    return _jdnToGregorian(_epochJdn + offset);
  }

  /// Formats this date as `'day month year suffix'`, for example
  /// `'14 Muharram 1448 AH'`.
  ///
  /// [monthNames] must contain exactly 12 entries (Muharram first) and
  /// defaults to [defaultMonthNames]. [eraSuffix] defaults to `'AH'`;
  /// pass an empty string to omit it. Digits are rendered through
  /// [numeralStyle].
  String format({
    NumeralStyle numeralStyle = NumeralStyle.western,
    List<String>? monthNames,
    String? eraSuffix,
  }) {
    final names = monthNames ?? defaultMonthNames;
    if (names.length != 12) {
      throw ArgumentError.value(
        monthNames,
        'monthNames',
        'Must contain exactly 12 month names.',
      );
    }
    final suffix = eraSuffix ?? 'AH';
    final text = suffix.isEmpty
        ? '$day ${names[month - 1]} $year'
        : '$day ${names[month - 1]} $year $suffix';
    return numeralStyle.convert(text);
  }

  /// Total length in days of Hijri [year], derived from the packed
  /// month lengths.
  static int _yearLength(int year) {
    var days = 0;
    for (var m = 1; m <= 12; m++) {
      days += daysInMonth(year, m);
    }
    return days;
  }

  /// Julian day number of the Gregorian calendar date [year], [month],
  /// [day] (Fliegel and Van Flandern algorithm).
  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Gregorian calendar date for Julian day number [jdn], returned as
  /// a [DateTime] at local midnight.
  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankHijriDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'BankHijriDate($year, $month, $day)';
}
