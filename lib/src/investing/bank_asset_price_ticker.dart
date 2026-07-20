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

  static bool _isDarkSurface(BankThemeData theme) =>
      ThemeData.estimateBrightnessForColor(theme.surface) == Brightness.dark;

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
                    _AnimatedPrice(
                      text: formattedPrice,
                      value: quote.price.amount.toDouble(),
                      style: bankTheme.numeralSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(amountStyle),
                      gainColor: gainColor ??
                          (_isDarkSurface(bankTheme)
                              ? BankTokens.investmentGainDark
                              : BankTokens.investmentGain),
                      lossColor: lossColor ??
                          (_isDarkSurface(bankTheme)
                              ? BankTokens.investmentLossDark
                              : BankTokens.investmentLoss),
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
