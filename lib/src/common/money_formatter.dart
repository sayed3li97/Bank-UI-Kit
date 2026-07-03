import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

/// Formats [Money]-like amount + currency for display, respecting
/// [NumeralStyle] and each currency's own presentation guidelines
/// (official symbol, ISO 4217 minor units, symbol placement) as
/// registered in [BankCurrencies].
abstract final class BankMoneyFormatter {
  static String format({
    required Decimal amount,
    required String currencyCode,
    NumeralStyle numeralStyle = NumeralStyle.western,
    bool showSign = false,
    bool compact = false,
    bool hideFraction = false,
  }) {
    final currency = BankCurrencies.of(currencyCode);
    final digits = hideFraction ? 0 : currency.decimalDigits;

    final String number;
    if (compact) {
      number = NumberFormat.compact().format(amount.toDouble());
    } else {
      final fmt = NumberFormat.decimalPatternDigits(decimalDigits: digits);
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
  }) =>
      format(
        amount: amount,
        currencyCode: currencyCode,
        numeralStyle: numeralStyle,
        showSign: true,
      );

  /// The bare display symbol for [currencyCode], suitable for input
  /// prefixes and axis labels.
  static String symbolFor(String currencyCode) =>
      BankCurrencies.of(currencyCode).embeddableSymbol.trim();

  static String _compose(BankCurrency currency, String number) {
    // A negative amount keeps its sign ahead of a leading symbol.
    final negative = number.startsWith('-');
    final unsigned = negative ? number.substring(1) : number;
    final symbol = currency.embeddableSymbol.trim();
    final gap = currency.spaceBetweenSymbolAndAmount ? '\u00A0' : '';

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
