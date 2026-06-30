import 'package:flutter/material.dart';

import '../../common/money_formatter.dart';
import '../../models/transaction.dart';
import '../../scope/bank_ui_scope.dart';
import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

/// A transaction tile that shows which joint account owner initiated it.
class BankJointTransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final String? initiatorName;
  final String? initiatorAvatarUrl;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, Transaction)? itemBuilder;

  const BankJointTransactionListTile({
    super.key,
    required this.transaction,
    this.initiatorName,
    this.initiatorAvatarUrl,
    this.onTap,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) return itemBuilder!(context, transaction);

    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final isDebit = transaction.amount.isNegative;
    final amountColor =
        isDebit ? BankTokens.investmentLoss : BankTokens.investmentGain;

    final amountStr = BankMoneyFormatter.formatSign(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Semantics(
      label:
          '${transaction.merchantName}, $amountStr${initiatorName != null ? ', by $initiatorName' : ''}',
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.surfaceVariant,
                      backgroundImage: transaction.merchantLogoUrl != null
                          ? NetworkImage(transaction.merchantLogoUrl!)
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
                            backgroundColor: theme.primary.withOpacity(0.2),
                            backgroundImage: initiatorAvatarUrl != null
                                ? NetworkImage(initiatorAvatarUrl!)
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
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (initiatorName != null)
                        Text(
                          'by $initiatorName',
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  amountStr,
                  style: BankTokens.numeralSmall.copyWith(color: amountColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
