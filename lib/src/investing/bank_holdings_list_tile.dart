import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/holding.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';

/// A portfolio position row. Built for [ListView.builder] usage.
class BankHoldingsListTile extends StatelessWidget {
  final Holding holding;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, Holding)? itemBuilder;

  /// Overrides the row content padding. Defaults to space4 by space3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the row minimum height. Defaults to 72.
  final double? height;

  /// Replaces the logo/initials avatar at the start of the row.
  final Widget? leading;

  /// Merged over the holding name style (labelLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the quantity line style (bodySmall, onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the current value style (numeralSmall, onSurface).
  final TextStyle? amountStyle;

  /// Overrides the positive gain tint. Defaults to
  /// [BankTokens.investmentGain].
  final Color? gainColor;

  /// Overrides the loss tint. Defaults to [BankTokens.investmentLoss].
  final Color? lossColor;

  /// Overrides the computed row semantics label.
  final String? semanticLabel;

  const BankHoldingsListTile({
    required this.holding,
    super.key,
    this.onTap,
    this.itemBuilder,
    this.padding,
    this.height,
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
    if (itemBuilder != null) return itemBuilder!(context, holding);
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final valueStr = BankMoneyFormatter.format(
      amount: holding.currentValue.amount,
      currencyCode: holding.currentValue.currencyCode,
      locale: context.bankLocale,
      numeralStyle: scope.numeralStyle,
    );
    final gainLossStr = BankMoneyFormatter.formatSign(
      amount: holding.gainLoss.amount,
      currencyCode: holding.gainLoss.currencyCode,
      locale: context.bankLocale,
      numeralStyle: scope.numeralStyle,
    );
    final pctStr = '${holding.gainLossPercent >= 0 ? '+' : ''}'
        '${holding.gainLossPercent.toStringAsFixed(2)}%';
    final changeColor = holding.isGain
        ? gainColor ?? BankTokens.investmentGain
        : lossColor ?? BankTokens.investmentLoss;

    return Semantics(
      label: semanticLabel ??
          '${holding.name}, ${holding.quantity} units, '
              'value $valueStr, $pctStr',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height ?? 72),
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
                      backgroundImage: holding.logoUrl != null
                          ? BankUiScope.imageProviderFor(
                              context,
                              holding.logoUrl!,
                            )
                          : null,
                      child: holding.logoUrl == null
                          ? Text(
                              holding.symbol.isNotEmpty
                                  ? holding.symbol[0]
                                  : '?',
                              style: BankTokens.labelMedium
                                  .copyWith(color: theme.primary),
                            )
                          : null,
                    ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        holding.name,
                        style: BankTokens.labelLarge
                            .copyWith(color: theme.onSurface)
                            .merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${holding.quantity} ${holding.symbol}',
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(subtitleStyle),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      valueStr,
                      style: BankTokens.numeralSmall
                          .copyWith(color: theme.onSurface)
                          .merge(amountStyle),
                    ),
                    Text(
                      '$gainLossStr ($pctStr)',
                      style: BankTokens.bodySmall.copyWith(color: changeColor),
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
