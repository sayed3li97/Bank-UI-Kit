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

  /// Overrides the card content padding. Defaults to space4 by space3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card elevation. Defaults to the theme elevationLow.
  final double? elevation;

  /// Replaces the logo/initials avatar at the start of the card.
  final Widget? leading;

  /// Merged over the symbol style (labelLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the asset name style (bodySmall, onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the price style (numeralSmall, onSurface).
  final TextStyle? amountStyle;

  /// Overrides the positive change tint. Defaults to
  /// [BankTokens.investmentGain].
  final Color? gainColor;

  /// Overrides the negative change tint. Defaults to
  /// [BankTokens.investmentLoss].
  final Color? lossColor;

  /// Overrides the watched star glyph. Defaults to [Icons.star].
  final IconData? watchedIcon;

  /// Overrides the unwatched star glyph. Defaults to
  /// [Icons.star_outline].
  final IconData? unwatchedIcon;

  /// Overrides the watched star tint. Defaults to amber.
  final Color? watchedColor;

  /// Semantics label for the watch toggle when watched. Defaults to
  /// 'Remove from watchlist'.
  final String removeFromWatchlistLabel;

  /// Semantics label for the watch toggle when not watched. Defaults
  /// to 'Add to watchlist'.
  final String addToWatchlistLabel;

  const BankWatchlistCard({
    required this.quote,
    super.key,
    this.isWatched = true,
    this.onToggleWatch,
    this.onTap,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.elevation,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.gainColor,
    this.lossColor,
    this.watchedIcon,
    this.unwatchedIcon,
    this.watchedColor,
    this.removeFromWatchlistLabel = 'Remove from watchlist',
    this.addToWatchlistLabel = 'Add to watchlist',
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
        ? gainColor ?? BankTokens.investmentGain
        : lossColor ?? BankTokens.investmentLoss;
    final resolvedRadius = radius ?? theme.cardRadius;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
      color: backgroundColor ?? theme.surface,
      elevation: elevation ?? theme.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: resolvedRadius,
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
          child: Row(
            children: [
              leading ??
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
                          .copyWith(color: theme.onSurface)
                          .merge(titleStyle),
                    ),
                    Text(
                      quote.name,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(subtitleStyle),
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
                        .copyWith(color: theme.onSurface)
                        .merge(amountStyle),
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
                label:
                    isWatched ? removeFromWatchlistLabel : addToWatchlistLabel,
                child: IconButton(
                  icon: Icon(
                    isWatched
                        ? watchedIcon ?? Icons.star
                        : unwatchedIcon ?? Icons.star_outline,
                    color: isWatched
                        ? watchedColor ?? Colors.amber
                        : theme.onSurfaceVariant,
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
