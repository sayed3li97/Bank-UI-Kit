import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../models/models.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A compact metric tile pairing a caption with a formatted [Money] value —
/// the "Available Balance" / "Savings" tiles that sit under a card carousel.
///
/// The amount is rendered with [BankBalanceText], so it formats currency,
/// respects the numeral style, and masks under privacy mode automatically.
/// Optionally shows a leading [icon] disc and a [trend] chip (e.g. `'+2.4%'`).
/// Pair several in a [BankBalanceTileRow].
///
/// ```dart
/// BankBalanceTile(
///   label: 'Available Balance',
///   amount: Money.fromDouble(3565.00, 'GBP'),
///   icon: Icons.account_balance_wallet_outlined,
/// )
/// ```
class BankBalanceTile extends StatelessWidget {
  const BankBalanceTile({
    required this.label,
    required this.amount,
    super.key,
    this.icon,
    this.trend,
    this.trendPositive = true,
    this.onTap,
    this.backgroundColor,
    this.accentColor,
    this.borderColor,
    this.radius,
    this.padding,
    this.labelStyle,
    this.amountStyle,
    this.width,
    this.semanticLabel,
  });

  /// Caption above the amount.
  final String label;

  /// The value shown as the hero.
  final Money amount;

  /// Optional leading icon shown in a tinted disc.
  final IconData? icon;

  /// Optional trend chip text (e.g. `'+2.4%'`). Hidden when null.
  final String? trend;

  /// Colours the [trend] chip positive (accent) or negative.
  final bool trendPositive;

  /// Tap handler (e.g. route to account detail).
  final VoidCallback? onTap;

  /// Tile fill. Defaults to [BankThemeData.surface].
  final Color? backgroundColor;

  /// Icon/trend accent. Defaults to [BankThemeData.primary].
  final Color? accentColor;

  /// Border colour. Defaults to a faint outline.
  final Color? borderColor;

  /// Corner radius. Defaults to [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Inner padding. Defaults to [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Merged over the computed caption style.
  final TextStyle? labelStyle;

  /// Merged over the computed amount style.
  final TextStyle? amountStyle;

  /// Fixed width (used by a scrollable [BankBalanceTileRow]).
  final double? width;

  /// The tile's semantics label. Defaults to [label] (the caption) so a
  /// tappable tile has an accessible name.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = accentColor ?? theme.primary;

    final content = Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(BankTokens.space4),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: radius ?? theme.cardRadius,
        border: Border.all(
          color: borderColor ?? theme.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                const SizedBox(width: BankTokens.space2),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BankTokens.labelSmall
                      .copyWith(
                        color: theme.onSurfaceVariant,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      )
                      .merge(labelStyle),
                ),
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: BankBalanceText(
                  money: amount,
                  size: BankBalanceSize.small,
                  style: BankTokens.headlineSmall
                      .copyWith(
                        color: theme.onSurface,
                        fontWeight: FontWeight.w800,
                      )
                      .merge(amountStyle),
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: BankTokens.space2),
                _TrendChip(
                  label: trend!,
                  color: trendPositive
                      ? theme.positiveBalance
                      : theme.negativeBalance,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final tile = Semantics(
      // Default to the caption so a tappable tile always has an accessible
      // name; the amount is announced by the BankBalanceText child (which
      // masks under privacy mode).
      label: semanticLabel ?? label,
      button: onTap != null,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: radius ?? theme.cardRadius,
              child: InkWell(
                borderRadius: radius ?? theme.cardRadius,
                onTap: onTap,
                child: content,
              ),
            ),
    );
    return tile;
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      ),
      child: Text(
        label,
        style: BankTokens.labelSmall
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Lays out several [BankBalanceTile]s: two-up (each [Expanded]) by default, or
/// a horizontally scrollable rail when [scrollable] is true (for 3+ metrics).
class BankBalanceTileRow extends StatelessWidget {
  const BankBalanceTileRow({
    required this.tiles,
    super.key,
    this.scrollable = false,
    this.gap = BankTokens.space3,
    this.scrollableTileWidth = 180,
    this.padding,
  });

  /// The tiles to lay out.
  final List<BankBalanceTile> tiles;

  /// When true, tiles scroll horizontally at [scrollableTileWidth]; otherwise
  /// they share the width evenly.
  final bool scrollable;

  /// Gap between tiles.
  final double gap;

  /// Fixed tile width in scrollable mode.
  final double scrollableTileWidth;

  /// Outer padding (useful in scrollable mode for edge insets).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: scrollableTileWidth, child: tiles[i]),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      // IntrinsicHeight bounds the row so CrossAxisAlignment.stretch (which
      // equalises tile heights) does not receive an unbounded height when the
      // row sits directly inside a scroll view.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }
}
