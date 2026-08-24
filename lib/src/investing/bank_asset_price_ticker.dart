import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/bank_pressable.dart';
import '../common/money_formatter.dart';
import '../models/models.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Compact price + change-percentage row for a stock, ETF, or crypto asset.
///
/// Displays a [BankEmblem] logo circle (network image, symbol monogram
/// otherwise), the asset symbol and name (unless [compact] is `true`), the
/// current price, and a change chip.
///
/// The change chip is a [BankTintChip] — the same height, padding, radius, and
/// ink as every other chip in the kit — tinted from the gain colour when
/// [AssetQuote.isPositive] is `true` and the loss colour otherwise. Both are
/// resolved for the surface brightness, so the pill does not stay light-mode
/// red on a dark watchlist.
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

  /// Overrides the positive tint used by both the price pulse and the change
  /// chip. Defaults to [BankTokens.investmentGain], or
  /// [BankTokens.investmentGainDark] on a dark surface.
  final Color? gainColor;

  /// Overrides the negative tint used by both the price pulse and the change
  /// chip. Defaults to [BankTokens.investmentLoss], or
  /// [BankTokens.investmentLossDark] on a dark surface.
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

  static bool _isDarkSurface(BankThemeData theme) =>
      ThemeData.estimateBrightnessForColor(theme.surface) == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final dark = _isDarkSurface(bankTheme);
    final resolvedGain = gainColor ??
        (dark ? BankTokens.investmentGainDark : BankTokens.investmentGain);
    final resolvedLoss = lossColor ??
        (dark ? BankTokens.investmentLossDark : BankTokens.investmentLoss);

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

    return BankPressable(
      onTap: onTap,
      borderRadius: radius ?? bankTheme.cardRadius,
      semanticLabel: semanticLabel ?? computedSemanticLabel,
      excludeSemantics: true,
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
              // ── Logo / monogram circle ─────────────────────────────────
              leading ??
                  BankEmblem(
                    imageUrl: quote.logoUrl,
                    initialsFrom: quote.symbol,
                    tier: BankEmblemSize.medium,
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
                      const SizedBox(height: BankTokens.hairlineWidth),
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
                  _AnimatedPrice(
                    text: formattedPrice,
                    value: quote.price.amount.toDouble(),
                    style: bankTheme.numeralSmall
                        .copyWith(color: bankTheme.onSurface)
                        .merge(amountStyle),
                    gainColor: resolvedGain,
                    lossColor: resolvedLoss,
                  ),
                  const SizedBox(height: BankTokens.space1),
                  BankTintChip(
                    label: changeStr,
                    color: positive ? resolvedGain : resolvedLoss,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private: animated price text
// ---------------------------------------------------------------------------

/// Renders the price and animates transitions when it changes: the new
/// value slides/fades in over [BankTokens.durationFast] (from below on a
/// rise, from above on a fall) while the numerals pulse briefly in the
/// gain or loss colour before settling back to the base ink.
///
/// Both the transition and the tint pulse collapse to an instant swap
/// under `MediaQuery.disableAnimations`.
class _AnimatedPrice extends StatefulWidget {
  const _AnimatedPrice({
    required this.text,
    required this.value,
    required this.style,
    required this.gainColor,
    required this.lossColor,
  });

  final String text;
  final double value;
  final TextStyle style;
  final Color gainColor;
  final Color lossColor;

  @override
  State<_AnimatedPrice> createState() => _AnimatedPriceState();
}

class _AnimatedPriceState extends State<_AnimatedPrice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// 1 while the last change was a rise, -1 for a fall, 0 before any
  /// change has been observed.
  int _direction = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: BankTokens.durationBase,
    );
  }

  @override
  void didUpdateWidget(_AnimatedPrice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    _direction = widget.value > oldWidget.value ? 1 : -1;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _pulse.value = 1;
    } else {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pulseColor = _direction < 0 ? widget.lossColor : widget.gainColor;
    final beginOffset = Offset(0, _direction < 0 ? -0.35 : 0.35);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = BankTokens.curveEmphasized.transform(_pulse.value);
        final color = _direction == 0
            ? widget.style.color
            : Color.lerp(pulseColor, widget.style.color, t);
        return AnimatedSwitcher(
          duration: disableAnimations ? Duration.zero : BankTokens.durationFast,
          switchInCurve: BankTokens.curveEmphasized,
          switchOutCurve: BankTokens.curveEmphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween<Offset>(begin: beginOffset, end: Offset.zero),
              ),
              child: child,
            ),
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: AlignmentDirectional.centerEnd,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: Text(
            widget.text,
            key: ValueKey<String>(widget.text),
            style: widget.style.copyWith(color: color),
            maxLines: 1,
          ),
        );
      },
    );
  }
}
