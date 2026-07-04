import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/transaction.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A transaction tile that shows which joint account owner initiated it.
class BankJointTransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final String? initiatorName;
  final String? initiatorAvatarUrl;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, Transaction)? itemBuilder;

  /// Initiator line template; `{name}` is substituted. Defaults to
  /// 'by {name}'.
  final String byTemplate;

  /// Overrides the tile content padding. Defaults to space4 by space3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the tile minimum height. Defaults to 72.
  final double? height;

  /// Overrides the debit amount colour. Defaults to
  /// [BankTokens.investmentLoss].
  final Color? debitColor;

  /// Overrides the credit amount colour. Defaults to
  /// [BankTokens.investmentGain].
  final Color? creditColor;

  /// Merged over the computed merchant-name style
  /// ([BankTokens.labelMedium] in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed initiator-line style
  /// ([BankTokens.bodySmall] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the computed amount style ([BankTokens.numeralSmall]).
  final TextStyle? amountStyle;

  /// Overrides the tile semantics. Defaults to a label built from the
  /// merchant, amount, and initiator.
  final String? semanticLabel;

  const BankJointTransactionListTile({
    required this.transaction,
    super.key,
    this.initiatorName,
    this.initiatorAvatarUrl,
    this.onTap,
    this.itemBuilder,
    this.byTemplate = 'by {name}',
    this.padding,
    this.height,
    this.debitColor,
    this.creditColor,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) return itemBuilder!(context, transaction);

    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final isDebit = transaction.amount.isNegative;
    final amountColor = isDebit
        ? (debitColor ?? BankTokens.investmentLoss)
        : (creditColor ?? BankTokens.investmentGain);

    final amountStr = BankMoneyFormatter.formatSign(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final byLine = initiatorName != null
        ? byTemplate.replaceAll('{name}', initiatorName!)
        : null;
    final initiatorSuffix = byLine != null ? ', $byLine' : '';

    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );

    return Semantics(
      label: semanticLabel ??
          '${transaction.merchantName}, $amountStr$initiatorSuffix',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height ?? 72),
          child: Padding(
            padding: resolvedPadding,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.surfaceVariant,
                      backgroundImage: transaction.merchantLogoUrl != null
                          ? BankUiScope.imageProviderFor(
                              context,
                              transaction.merchantLogoUrl!,
                            )
                          : null,
                      child: transaction.merchantLogoUrl == null
                          ? Text(
                              transaction.merchantName.isNotEmpty
                                  ? transaction.merchantName[0].toUpperCase()
                                  : '?',
                              style: BankTokens.labelMedium
                                  .copyWith(color: theme.primary),
                            )
                          : null,
                    ),
                    if (initiatorName != null || initiatorAvatarUrl != null)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: theme.surface,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor:
                                theme.primary.withValues(alpha: 0.2),
                            backgroundImage: initiatorAvatarUrl != null
                                ? BankUiScope.imageProviderFor(
                                    context,
                                    initiatorAvatarUrl!,
                                  )
                                : null,
                            child: initiatorAvatarUrl == null
                                ? Text(
                                    initiatorName?.isNotEmpty == true
                                        ? initiatorName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 9),
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: BankTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        transaction.merchantName,
                        style: BankTokens.labelMedium
                            .copyWith(color: theme.onSurface)
                            .merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (byLine != null)
                        Text(
                          byLine,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(subtitleStyle),
                        ),
                    ],
                  ),
                ),
                Text(
                  amountStr,
                  style: BankTokens.numeralSmall
                      .copyWith(color: amountColor)
                      .merge(amountStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
