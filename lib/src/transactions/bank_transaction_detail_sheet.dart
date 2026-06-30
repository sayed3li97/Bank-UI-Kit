import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Full-detail bottom sheet for a single transaction.
class BankTransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  /// Optional map widget supplied by the host app (e.g. a Google Maps snippet).
  final Widget? mapPreview;
  final VoidCallback? onDispute;
  final VoidCallback? onShare;

  const BankTransactionDetailSheet({
    super.key,
    required this.transaction,
    this.mapPreview,
    this.onDispute,
    this.onShare,
  });

  /// Convenience helper to push the sheet.
  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    Widget? mapPreview,
    VoidCallback? onDispute,
    VoidCallback? onShare,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankTransactionDetailSheet(
          transaction: transaction,
          mapPreview: mapPreview,
          onDispute: onDispute,
          onShare: onShare,
        ),
      );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _categoryLabel(TransactionCategory cat) => switch (cat) {
        TransactionCategory.groceries => 'Groceries',
        TransactionCategory.dining => 'Dining',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.health => 'Health',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.travel => 'Travel',
        TransactionCategory.education => 'Education',
        TransactionCategory.subscription => 'Subscription',
        TransactionCategory.transfer => 'Transfer',
        TransactionCategory.income => 'Income',
        TransactionCategory.investment => 'Investment',
        TransactionCategory.creditPayment => 'Credit Payment',
        TransactionCategory.other => 'Other',
      };

  String _statusLabel(TransactionStatus status, BankUiScopeData scope) =>
      switch (status) {
        TransactionStatus.pending => scope.strings.pending,
        TransactionStatus.cleared => scope.strings.cleared,
        TransactionStatus.declined => scope.strings.declined,
        TransactionStatus.refunded => scope.strings.refunded,
        TransactionStatus.scheduled => scope.strings.scheduled,
      };

  Color _statusColor(TransactionStatus status, BankThemeData bankTheme) =>
      switch (status) {
        TransactionStatus.pending => BankTokens.pending,
        TransactionStatus.declined => bankTheme.negativeBalance,
        TransactionStatus.refunded => BankTokens.positiveBalance,
        TransactionStatus.scheduled => BankTokens.frozen,
        TransactionStatus.cleared => bankTheme.onSurface,
      };

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = BankThemeData.of(context);
    final BankUiScopeData scope = BankUiScope.of(context);
    final s = scope.strings;

    final bool isCredit = !transaction.amount.isNegative;
    final bool isDeclined =
        transaction.status == TransactionStatus.declined;

    final String formattedAmount = BankMoneyFormatter.format(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    final Color amountColor = isDeclined
        ? bankTheme.onSurfaceVariant
        : isCredit
            ? bankTheme.positiveBalance
            : bankTheme.onSurface;

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double maxHeight =
        MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: bankTheme.sheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: BankTokens.space2),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: bankTheme.outline,
                  borderRadius:
                      BorderRadius.circular(BankTokens.radiusFull),
                ),
              ),
            ),
          ),
          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space4,
                BankTokens.space4,
                bottomPadding + BankTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: avatar + name + amount ---
                  Center(
                    child: Column(
                      children: [
                        _MerchantAvatar(
                          transaction: transaction,
                          bankTheme: bankTheme,
                        ),
                        const SizedBox(height: BankTokens.space2),
                        Text(
                          transaction.merchantName,
                          style: BankTokens.headlineSmall.copyWith(
                            color: bankTheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          formattedAmount,
                          style: bankTheme.numeralHero.copyWith(
                            color: amountColor,
                            decoration: isDeclined
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: bankTheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BankTokens.space6),
                  const Divider(height: 1),
                  const SizedBox(height: BankTokens.space4),

                  // --- Detail rows ---
                  _DetailRow(
                    label: 'Date',
                    value: BankDateFormatter.formatLong(transaction.settledAt),
                    bankTheme: bankTheme,
                  ),
                  _DetailRow(
                    label: 'Category',
                    value: _categoryLabel(transaction.category),
                    bankTheme: bankTheme,
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: _statusLabel(transaction.status, scope),
                    valueColor:
                        _statusColor(transaction.status, bankTheme),
                    bankTheme: bankTheme,
                  ),
                  if (transaction.reference != null)
                    _DetailRow(
                      label: 'Reference',
                      value: transaction.reference!,
                      bankTheme: bankTheme,
                      canCopy: true,
                    ),
                  if (transaction.note != null)
                    _DetailRow(
                      label: 'Note',
                      value: transaction.note!,
                      bankTheme: bankTheme,
                    ),
                  if (transaction.spenderName != null)
                    _DetailRow(
                      label: 'Paid by',
                      value: transaction.spenderName!,
                      bankTheme: bankTheme,
                    ),

                  // --- Map preview ---
                  if (mapPreview != null) ...[
                    const SizedBox(height: BankTokens.space4),
                    ClipRRect(
                      borderRadius: bankTheme.cardRadius,
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: mapPreview!,
                      ),
                    ),
                  ],

                  // --- Category splits ---
                  if (transaction.categorySplits != null &&
                      transaction.categorySplits!.isNotEmpty) ...[
                    const SizedBox(height: BankTokens.space4),
                    const Divider(height: 1),
                    const SizedBox(height: BankTokens.space3),
                    Text(
                      'Category Breakdown',
                      style: BankTokens.labelLarge.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    ...transaction.categorySplits!.map(
                      (split) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: BankTokens.space2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              BankIcons.forCategoryName(
                                split.category.name,
                              ),
                              size: 16,
                              color: bankTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: BankTokens.space2),
                            Expanded(
                              child: Text(
                                _categoryLabel(split.category),
                                style: BankTokens.bodyMedium.copyWith(
                                  color: bankTheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              BankMoneyFormatter.format(
                                amount: split.amount.amount,
                                currencyCode: split.amount.currencyCode,
                                numeralStyle: scope.numeralStyle,
                              ),
                              style: bankTheme.numeralSmall.copyWith(
                                color: bankTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // --- Action row ---
                  if (onDispute != null || onShare != null) ...[
                    const SizedBox(height: BankTokens.space4),
                    const Divider(height: 1),
                    const SizedBox(height: BankTokens.space2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (onDispute != null)
                          Semantics(
                            button: true,
                            label: s.dispute,
                            child: TextButton.icon(
                              onPressed: onDispute,
                              icon: Icon(
                                BankIcons.dispute,
                                color: bankTheme.negativeBalance,
                                size: 18,
                              ),
                              label: Text(
                                s.dispute,
                                style: BankTokens.labelMedium.copyWith(
                                  color: bankTheme.negativeBalance,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  BankTokens.minTapTarget,
                                  BankTokens.minTapTarget,
                                ),
                              ),
                            ),
                          ),
                        if (onShare != null)
                          Semantics(
                            button: true,
                            label: s.share,
                            child: TextButton.icon(
                              onPressed: onShare,
                              icon: Icon(
                                BankIcons.share,
                                color: bankTheme.primary,
                                size: 18,
                              ),
                              label: Text(
                                s.share,
                                style: BankTokens.labelMedium.copyWith(
                                  color: bankTheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  BankTokens.minTapTarget,
                                  BankTokens.minTapTarget,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopy;
  final BankThemeData bankTheme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.bankTheme,
    this.valueColor,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BankTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: BankTokens.bodySmall.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: BankTokens.bodyMedium.copyWith(
                      color: valueColor ?? bankTheme.onSurface,
                    ),
                  ),
                ),
                if (canCopy)
                  GestureDetector(
                    onTap: () {
                      // Copy to clipboard
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: BankTokens.space1,
                      ),
                      child: Icon(
                        BankIcons.copy,
                        size: 16,
                        color: bankTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantAvatar extends StatefulWidget {
  final Transaction transaction;
  final BankThemeData bankTheme;

  const _MerchantAvatar({
    required this.transaction,
    required this.bankTheme,
  });

  @override
  State<_MerchantAvatar> createState() => _MerchantAvatarState();
}

class _MerchantAvatarState extends State<_MerchantAvatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = widget.bankTheme;
    final String? logoUrl = widget.transaction.merchantLogoUrl;

    if (logoUrl != null && !_failed) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: bankTheme.surfaceVariant,
        backgroundImage: NetworkImage(logoUrl),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _failed = true);
        },
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: bankTheme.surfaceVariant,
      child: Icon(
        BankIcons.forCategoryName(widget.transaction.category.name),
        size: 28,
        color: bankTheme.primary,
      ),
    );
  }
}
