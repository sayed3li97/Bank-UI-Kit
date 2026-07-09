import 'package:decimal/decimal.dart';

import 'bank_currency.dart';

class Money {
  final Decimal amount;
  final String currencyCode; // ISO 4217 e.g. 'USD', 'GBP', 'AED'

  const Money({required this.amount, required this.currencyCode});

  /// Creates money from a [double], rounding to the currency's ISO 4217 minor
  /// units as registered in [BankCurrencies] — 2 for most currencies, 0 for
  /// JPY/KRW/VND/etc., and 3 for KWD/BHD/OMR/etc. This keeps the stored value
  /// consistent with how it is displayed. For exact or high-precision values
  /// (e.g. crypto), use the default constructor with a [Decimal].
  factory Money.fromDouble(double amount, String currencyCode) {
    final digits = BankCurrencies.of(currencyCode).decimalDigits;
    return Money(
      amount: Decimal.parse(amount.toStringAsFixed(digits)),
      currencyCode: currencyCode,
    );
  }

  factory Money.zero(String currencyCode) =>
      Money(amount: Decimal.zero, currencyCode: currencyCode);

  Money operator +(Money other) {
    assert(
      currencyCode == other.currencyCode,
      'Cannot add Money with different currencies: '
      '$currencyCode and ${other.currencyCode}',
    );
    return Money(amount: amount + other.amount, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    assert(
      currencyCode == other.currencyCode,
      'Cannot subtract Money with different currencies: '
      '$currencyCode and ${other.currencyCode}',
    );
    return Money(amount: amount - other.amount, currencyCode: currencyCode);
  }

  bool get isNegative => amount < Decimal.zero;
  bool get isZero => amount == Decimal.zero;

  Money copyWith({Decimal? amount, String? currencyCode}) => Money(
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
      );

  @override
  String toString() => '$currencyCode $amount';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          currencyCode == other.currencyCode;

  @override
  int get hashCode => Object.hash(amount, currencyCode);
}
