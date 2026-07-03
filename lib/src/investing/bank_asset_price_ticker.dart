import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Compact price + change-percentage row for a stock, ETF, or crypto asset.
///
/// Displays a logo circle (network image or initials fallback), the asset
/// symbol and name (unless [compact] is `true`), the current price, and a
/// colour-coded change badge.
///
/// The change badge is a rounded pill:
/// - Green background when [AssetQuote.isPositive] is `true`.
/// - Red background when the change is negative.
///
/// Tapping the row calls [onTap] when provided.
class BankAssetPriceTicker extends StatelessWidget {
  /// The quote data to display.
  final AssetQuote quote;

  /// Called when the row is tapped. If `null`, no tap interaction is wired.
  final VoidCallback? onTap;

  /// When `true`, hides the asset name and shows only symbol + price + badge.
  final bool compact;

  const BankAssetPriceTicker({
    required this.quote,
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final formattedPrice = BankMoneyFormatter.format(
      amount: quote.price.amount,
      currencyCode: quote.price.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final positive = quote.isPositive;
    final absChange = quote.changePercent.abs();
    final changeStr = positive
        ? '+${absChange.toStringAsFixed(2)}%'
        : '-${absChange.toStringAsFixed(2)}%';

    final changeSign = quote.changePercent >= 0 ? '+' : '';
    final changePercentStr = quote.changePercent.toStringAsFixed(2);
    final semanticLabel = '${quote.symbol}: $formattedPrice, '
        '$changeSign$changePercentStr% today';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: bankTheme.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                // ── Logo / initials circle ─────────────────────────────────
                _AssetLogo(
                  logoUrl: quote.logoUrl,
                  symbol: quote.symbol,
                  bankTheme: bankTheme,
                ),

                const SizedBox(width: BankTokens.space3),

                // ── Symbol + optional name ─────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quote.symbol,
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 1),
                        Text(
                          quote.name,
                          style: BankTokens.bodySmall.copyWith(
                            color: bankTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: BankTokens.space3),

                // ── Price + change badge ───────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedPrice,
                      style: bankTheme.numeralSmall.copyWith(
                        color: bankTheme.onSurface,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    _ChangeBadge(
                      label: changeStr,
                      positive: positive,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private: asset logo with network image + fallback
// ---------------------------------------------------------------------------

class _AssetLogo extends StatefulWidget {
  const _AssetLogo({
    required this.logoUrl,
    required this.symbol,
    required this.bankTheme,
  });

  final String? logoUrl;
  final String symbol;
  final BankThemeData bankTheme;

  @override
  State<_AssetLogo> createState() => _AssetLogoState();
}

class _AssetLogoState extends State<_AssetLogo> {
  bool _logoFailed = false;

  @override
  void didUpdateWidget(_AssetLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoUrl != widget.logoUrl) {
      _logoFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.logoUrl;

    if (url != null && !_logoFailed) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: widget.bankTheme.surfaceVariant,
        backgroundImage: BankUiScope.imageProviderFor(context, url),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _logoFailed = true);
        },
      );
    }

    // Fallback: first character of the symbol on a surface-variant circle.
    final initial =
        widget.symbol.isNotEmpty ? widget.symbol[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: widget.bankTheme.surfaceVariant,
      child: Text(
        initial,
        style: BankTokens.labelMedium.copyWith(
          color: widget.bankTheme.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private: change percentage pill badge
// ---------------------------------------------------------------------------

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({
    required this.label,
    required this.positive,
  });

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final bg = positive
        ? BankTokens.investmentGain.withValues(alpha: 0.15)
        : BankTokens.investmentLoss.withValues(alpha: 0.15);
    final fg = positive ? BankTokens.investmentGain : BankTokens.investmentLoss;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      ),
      child: Text(
        label,
        style: BankTokens.labelSmall.copyWith(color: fg),
        maxLines: 1,
      ),
    );
  }
}
