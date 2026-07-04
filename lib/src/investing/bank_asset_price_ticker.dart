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

  /// Overrides the row content padding. Defaults to space4 by space2.
  final EdgeInsetsGeometry? padding;

  /// Overrides the tap ripple corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Replaces the logo/initials circle at the start of the row.
  final Widget? leading;

  /// Merged over the symbol style (labelLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the asset name style (bodySmall, onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the price style (numeralSmall, onSurface).
  final TextStyle? amountStyle;

  /// Overrides the positive badge tint. Defaults to
  /// [BankTokens.investmentGain].
  final Color? gainColor;

  /// Overrides the negative badge tint. Defaults to
  /// [BankTokens.investmentLoss].
  final Color? lossColor;

  /// Overrides the computed row semantics label.
  final String? semanticLabel;

  const BankAssetPriceTicker({
    required this.quote,
    super.key,
    this.onTap,
    this.compact = false,
    this.padding,
    this.radius,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.gainColor,
    this.lossColor,
    this.semanticLabel,
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
    final computedSemanticLabel = '${quote.symbol}: $formattedPrice, '
        '$changeSign$changePercentStr% today';

    return Semantics(
      label: semanticLabel ?? computedSemanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius ?? bankTheme.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space2,
                ),
            child: Row(
              children: [
                // ── Logo / initials circle ─────────────────────────────────
                leading ??
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
                        style: BankTokens.labelLarge
                            .copyWith(color: bankTheme.onSurface)
                            .merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 1),
                        Text(
                          quote.name,
                          style: BankTokens.bodySmall
                              .copyWith(color: bankTheme.onSurfaceVariant)
                              .merge(subtitleStyle),
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
                      style: bankTheme.numeralSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(amountStyle),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    _ChangeBadge(
                      label: changeStr,
                      positive: positive,
                      gainColor: gainColor,
                      lossColor: lossColor,
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
    this.gainColor,
    this.lossColor,
  });

  final String label;
  final bool positive;
  final Color? gainColor;
  final Color? lossColor;

  @override
  Widget build(BuildContext context) {
    final fg = positive
        ? gainColor ?? BankTokens.investmentGain
        : lossColor ?? BankTokens.investmentLoss;
    final bg = fg.withValues(alpha: 0.15);

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
