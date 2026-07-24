import 'package:flutter/material.dart';

import '../../src/common/bank_surface_depth.dart';
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

  /// Legacy depth opt-out. The card renders the kit shadow language
  /// ([BankTokens.shadowCardFor] of the theme background brightness) instead
  /// of Material elevation; pass `0` — or use a theme whose `elevationLow`
  /// is `0`, such as Voltage — to flatten the card to hairline-only depth.
  final double? elevation;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

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
    this.shadow,
    this.border,
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

    // One depth language for every card: token shadows resolved against the
    // theme background brightness, with the dark-surface hairline. Themes
    // that declare flat depth (elevationLow == 0, e.g. Voltage) — or an
    // explicit `elevation: 0` — keep hairline-only separation. The margin
    // preserves the footprint of the Material [Card] this replaces.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
      tier: (elevation ?? theme.elevationLow) <= 0
          ? BankSurfaceDepthTier.flat
          : BankSurfaceDepthTier.card,
    );

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        color: backgroundColor ?? theme.surface,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: Material(
          type: MaterialType.transparency,
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
                            ? BankUiScope.imageProviderFor(
                                context,
                                quote.logoUrl!,
                              )
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
                        style:
                            BankTokens.bodySmall.copyWith(color: changeColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Semantics(
                    button: true,
                    label: isWatched
                        ? removeFromWatchlistLabel
                        : addToWatchlistLabel,
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
        ),
      ),
    );
  }
}
