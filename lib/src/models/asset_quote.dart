import 'money.dart';

class AssetQuote {
  final String symbol;
  final String name;
  final Money price;
  final double changePercent; // e.g. 2.34 or -1.12
  final Money? change24h;
  final String? logoUrl;

  const AssetQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    this.change24h,
    this.logoUrl,
  });

  AssetQuote copyWith({
    String? symbol,
    String? name,
    Money? price,
    double? changePercent,
    Money? change24h,
    String? logoUrl,
  }) =>
      AssetQuote(
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        price: price ?? this.price,
        changePercent: changePercent ?? this.changePercent,
        change24h: change24h ?? this.change24h,
        logoUrl: logoUrl ?? this.logoUrl,
      );

  bool get isPositive => changePercent >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetQuote &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          name == other.name &&
          price == other.price &&
          changePercent == other.changePercent &&
          change24h == other.change24h &&
          logoUrl == other.logoUrl;

  @override
  int get hashCode => Object.hash(
        symbol,
        name,
        price,
        changePercent,
        change24h,
        logoUrl,
      );
}
