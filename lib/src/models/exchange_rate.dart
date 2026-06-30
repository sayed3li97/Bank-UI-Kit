import 'package:decimal/decimal.dart';

import 'money.dart';

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final Decimal rate;
  final DateTime fetchedAt;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.fetchedAt,
  });

  ExchangeRate copyWith({
    String? fromCurrency,
    String? toCurrency,
    Decimal? rate,
    DateTime? fetchedAt,
  }) =>
      ExchangeRate(
        fromCurrency: fromCurrency ?? this.fromCurrency,
        toCurrency: toCurrency ?? this.toCurrency,
        rate: rate ?? this.rate,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );

  Money convert(Money from) {
    assert(
      from.currencyCode == fromCurrency,
      'Cannot convert ${from.currencyCode} using a rate '
      'from $fromCurrency to $toCurrency',
    );
    return Money(amount: from.amount * rate, currencyCode: toCurrency);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRate &&
          runtimeType == other.runtimeType &&
          fromCurrency == other.fromCurrency &&
          toCurrency == other.toCurrency &&
          rate == other.rate &&
          fetchedAt == other.fetchedAt;

  @override
  int get hashCode => Object.hash(fromCurrency, toCurrency, rate, fetchedAt);
}
