import 'package:decimal/decimal.dart';

import 'money.dart';

enum AssetClass { equity, etf, crypto, bond, commodity }

class Holding {
  final String assetId;
  final String symbol;
  final String name;
  final AssetClass assetClass;
  final Decimal quantity;
  final Money currentValue;
  final Money gainLoss; // positive = gain, negative = loss
  final double gainLossPercent;
  final String? logoUrl;

  const Holding({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.quantity,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
    this.logoUrl,
  });

  Holding copyWith({
    String? assetId,
    String? symbol,
    String? name,
    AssetClass? assetClass,
    Decimal? quantity,
    Money? currentValue,
    Money? gainLoss,
    double? gainLossPercent,
    String? logoUrl,
  }) =>
      Holding(
        assetId: assetId ?? this.assetId,
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        assetClass: assetClass ?? this.assetClass,
        quantity: quantity ?? this.quantity,
        currentValue: currentValue ?? this.currentValue,
        gainLoss: gainLoss ?? this.gainLoss,
        gainLossPercent: gainLossPercent ?? this.gainLossPercent,
        logoUrl: logoUrl ?? this.logoUrl,
      );

  bool get isGain => gainLoss.amount >= Decimal.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holding &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          symbol == other.symbol &&
          name == other.name &&
          assetClass == other.assetClass &&
          quantity == other.quantity &&
          currentValue == other.currentValue &&
          gainLoss == other.gainLoss &&
          gainLossPercent == other.gainLossPercent &&
          logoUrl == other.logoUrl;

  @override
  int get hashCode => Object.hash(
        assetId,
        symbol,
        name,
        assetClass,
        quantity,
        currentValue,
        gainLoss,
        gainLossPercent,
        logoUrl,
      );
}
