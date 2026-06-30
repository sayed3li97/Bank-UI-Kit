import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/holding.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A portfolio position row. Built for [ListView.builder] usage.
class BankHoldingsListTile extends StatelessWidget {
  final Holding holding;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, Holding)? itemBuilder;

  const BankHoldingsListTile({
    super.key,
    required this.holding,
    this.onTap,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) return itemBuilder!(context, holding);
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final valueStr = BankMoneyFormatter.format(
      amount: holding.currentValue.amount,
      currencyCode: holding.currentValue.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final gainLossStr = BankMoneyFormatter.formatSign(
      amount: holding.gainLoss.amount,
      currencyCode: holding.gainLoss.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final pctStr =
        '${holding.gainLossPercent >= 0 ? '+' : ''}${holding.gainLossPercent.toStringAsFixed(2)}%';
    final gainColor =
        holding.isGain ? BankTokens.investmentGain : BankTokens.investmentLoss;

    return Semantics(
      label:
          '${holding.name}, ${holding.quantity} units, value $valueStr, $pctStr',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
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
                  backgroundImage: holding.logoUrl != null
                      ? NetworkImage(holding.logoUrl!)
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
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${holding.quantity.toString()} ${holding.symbol}',
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant),
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
                          .copyWith(color: theme.onSurface),
                    ),
                    Text(
                      '$gainLossStr ($pctStr)',
                      style:
                          BankTokens.bodySmall.copyWith(color: gainColor),
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
