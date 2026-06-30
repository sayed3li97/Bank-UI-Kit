import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _quotes = [
  AssetQuote(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    price: Money(amount: Decimal.parse('189.50'), currencyCode: 'USD'),
    changePercent: 1.24,
  ),
  AssetQuote(
    symbol: 'TSLA',
    name: 'Tesla, Inc.',
    price: Money(amount: Decimal.parse('245.80'), currencyCode: 'USD'),
    changePercent: -2.15,
  ),
  AssetQuote(
    symbol: 'BTC',
    name: 'Bitcoin',
    price: Money(amount: Decimal.parse('67420.00'), currencyCode: 'USD'),
    changePercent: 3.82,
  ),
];

final _holdings = [
  Holding(
    assetId: 'aapl',
    symbol: 'AAPL',
    name: 'Apple Inc.',
    quantity: Decimal.parse('10'),
    assetClass: AssetClass.equity,
    currentValue: Money(amount: Decimal.parse('1895.00'), currencyCode: 'USD'),
    gainLoss: Money(amount: Decimal.parse('245.00'), currencyCode: 'USD'),
    gainLossPercent: 14.85,
  ),
  Holding(
    assetId: 'btc',
    symbol: 'BTC',
    name: 'Bitcoin',
    quantity: Decimal.parse('0.5'),
    assetClass: AssetClass.crypto,
    currentValue: Money(amount: Decimal.parse('33710.00'), currencyCode: 'USD'),
    gainLoss: Money(amount: Decimal.parse('5710.00'), currencyCode: 'USD'),
    gainLossPercent: 20.39,
  ),
];

final _chartData = List.generate(
  30,
  (i) => BankChartDataPoint(
    timestamp: DateTime.now().subtract(Duration(days: 30 - i)),
    value: 10000 + 500 * (i % 5) - 200 * (i % 3) + i * 80.0,
  ),
);

class InvestingScreen extends StatefulWidget {
  const InvestingScreen({super.key});

  @override
  State<InvestingScreen> createState() => _InvestingScreenState();
}

class _InvestingScreenState extends State<InvestingScreen> {
  final Set<String> _watched = {'AAPL', 'BTC'};
  BankChartTimeRange _range = BankChartTimeRange.oneMonth;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Investing'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Portfolio Chart', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPortfolioPerformanceChart(
            dataPoints: _chartData,
            selectedRange: _range,
            onRangeChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Holdings', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ..._holdings.map(
            (h) => BankHoldingsListTile(holding: h),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Watchlist', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ..._quotes.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space2),
              child: BankWatchlistCard(
                quote: q,
                isWatched: _watched.contains(q.symbol),
                onToggleWatch: () => setState(() {
                  if (_watched.contains(q.symbol)) {
                    _watched.remove(q.symbol);
                  } else {
                    _watched.add(q.symbol);
                  }
                }),
                onTap: () => BankBuySellSheet.show(
                  context,
                  quote: q,
                  onSubmit: (side, type, amount, limit) async {},
                ),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Price Ticker', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankAssetPriceTicker(quotes: _quotes),
          const SizedBox(height: BankTokens.space4),
          Text('Currency Converter', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankLiveExchangeConverter(
            fromCurrency: 'GBP',
            toCurrency: 'USD',
            rate: ExchangeRate(
              fromCurrency: 'GBP',
              toCurrency: 'USD',
              rate: Decimal.parse('1.27'),
              updatedAt: DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }
}
