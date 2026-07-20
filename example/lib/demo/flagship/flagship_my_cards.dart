import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'card_artwork.dart';

/// The Meridian "My Cards" screen: a swipeable card carousel whose balance
/// tiles and transactions re-bind to the centred card. Built entirely from
/// Bank UI Kit card widgets (BankCardCarousel + BankPaymentCard +
/// BankBalanceTileRow + BankTransactionListTile).
///
/// It relies on the ambient BankUiScope / BankThemeData / Directionality from
/// the showcase harness — it creates none of its own.
class FlagshipMyCards extends StatefulWidget {
  const FlagshipMyCards({super.key});

  @override
  State<FlagshipMyCards> createState() => _FlagshipMyCardsState();
}

class _FlagshipMyCardsState extends State<FlagshipMyCards> {
  int _selected = 0;

  static final List<_CardModel> _cards = [
    _CardModel(
      label: 'Everyday',
      maskedNumber: '•••• 8695',
      holder: 'ALEX MORGAN',
      expiry: '08/28',
      network: BankCardNetwork.visa,
      available: Money.fromDouble(3565.00, 'GBP'),
      savings: Money.fromDouble(650.00, 'GBP'),
      artwork: CardArtworkPalette.sunset,
    ),
    _CardModel(
      label: 'Rewards',
      maskedNumber: '•••• 5567',
      holder: 'ALEX MORGAN',
      expiry: '02/27',
      network: BankCardNetwork.mastercard,
      available: Money.fromDouble(1284.60, 'GBP'),
      savings: Money.fromDouble(0, 'GBP'),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6D3BEA), Color(0xFF3B1E8F)],
      ),
    ),
    _CardModel(
      label: 'Travel',
      maskedNumber: '•••• 2043',
      holder: 'ALEX MORGAN',
      expiry: '11/26',
      network: BankCardNetwork.amex,
      available: Money.fromDouble(2410.00, 'GBP'),
      savings: Money.fromDouble(1500.00, 'GBP'),
      artwork: CardArtworkPalette.ocean,
    ),
  ];

  List<Transaction> get _transactions {
    // A small per-card transaction sample so the list changes with selection.
    final base = <List<Transaction>>[
      [
        _tx('Tesco', -42.10, TransactionCategory.groceries, 1),
        _tx('Netflix', -10.99, TransactionCategory.subscription, 1),
        _tx('Charlie Adam', 650.00, TransactionCategory.transfer, 3,
            credit: true),
      ],
      [
        _tx('Amazon', -64.00, TransactionCategory.shopping, 2),
        _tx('Cashback reward', 12.40, TransactionCategory.transfer, 5,
            credit: true),
      ],
      [
        _tx('Emirates', -820.00, TransactionCategory.travel, 1),
        _tx('Uber', -18.30, TransactionCategory.transport, 1),
        _tx('Currency top-up', 500.00, TransactionCategory.transfer, 3,
            credit: true),
      ],
    ];
    return base[_selected];
  }

  Transaction _tx(
    String name,
    double amount,
    TransactionCategory category,
    int daysAgo, {
    bool credit = false,
  }) {
    return Transaction(
      id: '$name-$daysAgo',
      amount: Money.fromDouble(amount, 'GBP'),
      settledAt: DateTime(2026, 7, 9).subtract(Duration(days: daysAgo)),
      status: TransactionStatus.cleared,
      merchantName: name,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final card = _cards[_selected];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'My cards',
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: theme.onSurface),
            tooltip: 'Add card',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BankTokens.space10),
        children: [
          const SizedBox(height: BankTokens.space5),
          BankCardCarousel(
            itemCount: _cards.length,
            onCardChanged: (i) => setState(() => _selected = i),
            itemBuilder: (context, i) {
              final c = _cards[i];
              return BankPaymentCard(
                label: c.label,
                maskedNumber: c.maskedNumber,
                holderName: c.holder,
                expiry: c.expiry,
                network: c.network,
                gradient: c.gradient,
                artwork: c.artwork == null
                    ? null
                    : MeridianCardArtwork(palette: c.artwork!),
              );
            },
          ),
          const SizedBox(height: BankTokens.space6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
            child: BankBalanceTileRow(
              tiles: [
                BankBalanceTile(
                  label: 'Available Balance',
                  amount: card.available,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                BankBalanceTile(
                  label: 'Savings',
                  amount: card.savings,
                  icon: Icons.savings_outlined,
                  trend: '+2.4%',
                ),
              ],
            ),
          ),
          const SizedBox(height: BankTokens.space6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
            child: Row(
              children: [
                Text(
                  'Transactions',
                  style: BankTokens.headlineSmall.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  card.label,
                  style: BankTokens.labelMedium
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: BankTokens.space2),
          ..._groupedTransactionRows(),
        ],
      ),
    );
  }

  /// The selected card's transactions with a date header before each day,
  /// so the list reads like a real statement rather than an undated sample.
  List<Widget> _groupedTransactionRows() {
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final t in _transactions) {
      final day =
          DateTime(t.settledAt.year, t.settledAt.month, t.settledAt.day);
      if (day != currentDay) {
        currentDay = day;
        rows.add(BankTransactionGroupHeader(date: day));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: 2,
          ),
          child: BankTransactionListTile(transaction: t),
        ),
      );
    }
    return rows;
  }
}

class _CardModel {
  _CardModel({
    required this.label,
    required this.maskedNumber,
    required this.holder,
    required this.expiry,
    required this.network,
    required this.available,
    required this.savings,
    this.artwork,
    this.gradient,
  });

  final String label;
  final String maskedNumber;
  final String holder;
  final String expiry;
  final BankCardNetwork network;
  final Money available;
  final Money savings;
  final CardArtworkPalette? artwork;
  final Gradient? gradient;
}
