import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A single transaction row, designed for use inside [ListView.builder].
/// Shows category icon (with optional merchant logo), signed amount, and
/// status.
class BankTransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  /// Full override: when provided, replaces the default tile layout entirely.
  final Widget Function(BuildContext, Transaction)? itemBuilder;

  const BankTransactionListTile({
    required this.transaction,
    super.key,
    this.onTap,
    this.itemBuilder,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _statusLabel(TransactionStatus status, BankUiScopeData scope) =>
      switch (status) {
        TransactionStatus.pending => scope.strings.pending,
        TransactionStatus.declined => scope.strings.declined,
        TransactionStatus.refunded => scope.strings.refunded,
        TransactionStatus.scheduled => scope.strings.scheduled,
        TransactionStatus.cleared => '',
      };

  Color _statusColor(TransactionStatus status, BankThemeData bankTheme) =>
      switch (status) {
        TransactionStatus.pending => BankTokens.pending,
        TransactionStatus.declined => bankTheme.negativeBalance,
        TransactionStatus.refunded => BankTokens.positiveBalance,
        TransactionStatus.scheduled => BankTokens.frozen,
        TransactionStatus.cleared => bankTheme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return itemBuilder!(context, transaction);
    }

    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final isDeclined = transaction.status == TransactionStatus.declined;
    final isCredit = !transaction.amount.isNegative;
    final statusLabel = _statusLabel(transaction.status, scope);

    final formattedAmount = BankMoneyFormatter.format(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    // Privacy mode replaces the amount with the scope's masked label in both
    // the visible row and the semantics announcement.
    final displayAmount =
        scope.privacyEnabled ? scope.strings.balanceHidden : formattedAmount;

    final amountColor = isDeclined
        ? bankTheme.onSurfaceVariant
        : isCredit
            ? bankTheme.positiveBalance
            : bankTheme.onSurface;

    final amountStyle = bankTheme.numeralSmall.copyWith(
      color: amountColor,
      decoration: isDeclined ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: bankTheme.onSurfaceVariant,
    );

    final semanticLabel = '${transaction.merchantName}, $displayAmount, '
        '${transaction.status.name}';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: bankTheme.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                _LeadingAvatar(
                  transaction: transaction,
                  bankTheme: bankTheme,
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.merchantName,
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (statusLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: BankTokens.bodySmall.copyWith(
                            color: _statusColor(transaction.status, bankTheme),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                Text(
                  displayAmount,
                  style: amountStyle,
                  textAlign: TextAlign.end,
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
// Private helpers
// ---------------------------------------------------------------------------

class _LeadingAvatar extends StatefulWidget {
  final Transaction transaction;
  final BankThemeData bankTheme;

  const _LeadingAvatar({
    required this.transaction,
    required this.bankTheme,
  });

  @override
  State<_LeadingAvatar> createState() => _LeadingAvatarState();
}

class _LeadingAvatarState extends State<_LeadingAvatar> {
  bool _logoFailed = false;

  @override
  void didUpdateWidget(_LeadingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaction.merchantLogoUrl !=
        widget.transaction.merchantLogoUrl) {
      _logoFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = widget.bankTheme;
    final logoUrl = widget.transaction.merchantLogoUrl;

    if (logoUrl != null && !_logoFailed) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: bankTheme.surfaceVariant,
        backgroundImage: BankUiScope.imageProviderFor(context, logoUrl),
        onBackgroundImageError: (_, __) {
          if (mounted) {
            setState(() => _logoFailed = true);
          }
        },
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: bankTheme.surfaceVariant,
      child: Icon(
        BankIcons.forCategoryName(widget.transaction.category.name),
        size: 20,
        color: bankTheme.primary,
      ),
    );
  }
}
