import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

/// Formats [Money]-like amount + currency for display, respecting
/// [NumeralStyle].
abstract final class BankMoneyFormatter {
  static String format({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    bool showSign = false,
    bool compact = false,
    bool hideFraction = false,
  }) {
    final fmt = compact
        ? NumberFormat.compactCurrency(
            name: currencyCode,
            symbol: _symbolFor(currencyCode),
            decimalDigits: hideFraction ? 0 : 2,
          )
        : NumberFormat.currency(
            name: currencyCode,
            symbol: _symbolFor(currencyCode),
            decimalDigits: hideFraction ? 0 : 2,
          );

    var result = fmt.format(amount.toDouble());

    if (showSign && amount > Decimal.zero) {
      result = '+$result';
    }

    return numeralStyle.convert(result);
  }

  static String formatSign({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
  }) =>
      format(
        amount: amount,
        currencyCode: currencyCode,
        numeralStyle: numeralStyle,
        showSign: true,
      );

  static String _symbolFor(String code) => switch (code) {
        'USD' => r'$',
        'GBP' => '£',
        'EUR' => '€',
        'JPY' => '¥',
        'AED' => 'AED ',
        'SAR' => 'SAR ',
        'KWD' => 'KWD ',
        'BHD' => 'BHD ',
        'QAR' => 'QAR ',
        'CAD' => r'CA$',
        'AUD' => r'A$',
        'CHF' => 'CHF ',
        'CNY' => '¥',
        'INR' => '₹',
        'BTC' => '₿',
        'ETH' => 'Ξ',
        _ => '$code ',
      };
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
