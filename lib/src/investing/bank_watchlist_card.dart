import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/asset_quote.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A saved/watched asset card with quick-glance price and watchlist toggle.
class BankWatchlistCard extends StatelessWidget {
  final AssetQuote quote;
  final bool isWatched;
  final VoidCallback? onToggleWatch;
  final VoidCallback? onTap;

  const BankWatchlistCard({
    required this.quote,
    super.key,
    this.isWatched = true,
    this.onToggleWatch,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final priceStr = BankMoneyFormatter.format(
      amount: quote.price.amount,
      currencyCode: quote.price.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final changeSign = quote.changePercent >= 0 ? '+' : '';
    final changeStr = '$changeSign${quote.changePercent.toStringAsFixed(2)}%';
    final changeColor = quote.isPositive
        ? BankTokens.investmentGain
        : BankTokens.investmentLoss;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      color: theme.surface,
      elevation: theme.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.surfaceVariant,
                backgroundImage: quote.logoUrl != null
                    ? BankUiScope.imageProviderFor(context, quote.logoUrl!)
                    : null,
                child: quote.logoUrl == null
                    ? Text(
                        quote.symbol.isNotEmpty ? quote.symbol[0] : '?',
                        style: BankTokens.labelMedium
                            .copyWith(color: theme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.symbol,
                      style: BankTokens.labelLarge
                          .copyWith(color: theme.onSurface),
                    ),
                    Text(
                      quote.name,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceStr,
                    style: BankTokens.numeralSmall
                        .copyWith(color: theme.onSurface),
                  ),
                  Text(
                    changeStr,
                    style: BankTokens.bodySmall.copyWith(color: changeColor),
                  ),
                ],
              ),
              const SizedBox(width: BankTokens.space2),
              Semantics(
                button: true,
                label: isWatched ? 'Remove from watchlist' : 'Add to watchlist',
                child: IconButton(
                  icon: Icon(
                    isWatched ? Icons.star : Icons.star_outline,
                    color: isWatched ? Colors.amber : theme.onSurfaceVariant,
                  ),
                  onPressed: onToggleWatch,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
