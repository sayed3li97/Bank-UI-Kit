import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';

/// Full-detail bottom sheet for a single transaction.
class BankTransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  /// Optional map widget supplied by the host app (e.g. a Google Maps snippet).
  final Widget? mapPreview;
  final VoidCallback? onDispute;
  final VoidCallback? onShare;

  /// Replaces the avatar, merchant name, and amount header when provided.
  final Widget? header;

  /// Overrides the scrollable content padding. Defaults to
  /// [BankTokens.space4] plus the bottom safe area inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the sheet corner radius. Defaults to the theme sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet background. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the drag handle color. Defaults to the theme outline.
  final Color? handleColor;

  /// Overrides the avatar background. Defaults to the theme surfaceVariant.
  final Color? avatarBackgroundColor;

  /// Overrides the primary accents (avatar icon, share action).
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the merchant name style ([BankTokens.headlineSmall]).
  final TextStyle? titleStyle;

  /// Merged over the computed hero amount style.
  final TextStyle? amountStyle;

  /// Overrides the max sheet height as a screen fraction. Defaults to
  /// 0.92.
  final double? maxHeightFraction;

  /// Overrides the date row label. Defaults to 'Date'.
  final String dateLabel;

  /// Overrides the category row label. Defaults to 'Category'.
  final String categoryLabel;

  /// Overrides the status row label. Defaults to 'Status'.
  final String statusRowLabel;

  /// Overrides the reference row label. Defaults to 'Reference'.
  final String referenceLabel;

  /// Overrides the note row label. Defaults to 'Note'.
  final String noteLabel;

  /// Overrides the spender row label. Defaults to 'Paid by'.
  final String paidByLabel;

  /// Overrides the splits section heading. Defaults to
  /// 'Category Breakdown'.
  final String categoryBreakdownLabel;

  /// Overrides the category display name. Defaults to built-in
  /// English labels.
  final String Function(TransactionCategory)? categoryLabelBuilder;

  /// Overrides the dispute action glyph. Defaults to [BankIcons.dispute].
  final IconData? disputeIcon;

  /// Overrides the share action glyph. Defaults to [BankIcons.share].
  final IconData? shareIcon;

  /// Overrides the copy glyph on copyable rows. Defaults to
  /// [BankIcons.copy].
  final IconData? copyIcon;

  const BankTransactionDetailSheet({
    required this.transaction,
    super.key,
    this.mapPreview,
    this.onDispute,
    this.onShare,
    this.header,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.handleColor,
    this.avatarBackgroundColor,
    this.accentColor,
    this.titleStyle,
    this.amountStyle,
    this.maxHeightFraction,
    this.dateLabel = 'Date',
    this.categoryLabel = 'Category',
    this.statusRowLabel = 'Status',
    this.referenceLabel = 'Reference',
    this.noteLabel = 'Note',
    this.paidByLabel = 'Paid by',
    this.categoryBreakdownLabel = 'Category Breakdown',
    this.categoryLabelBuilder,
    this.disputeIcon,
    this.shareIcon,
    this.copyIcon,
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
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final s = scope.strings;

    final isCredit = !transaction.amount.isNegative;
    final isDeclined = transaction.status == TransactionStatus.declined;

    final formattedAmount = BankMoneyFormatter.format(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      locale: context.bankLocale,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    final amountColor = isDeclined
        ? bankTheme.onSurfaceVariant
        : isCredit
            ? bankTheme.positiveBalance
            : bankTheme.onSurface;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxHeight =
        MediaQuery.of(context).size.height * (maxHeightFraction ?? 0.92);
    final resolvedCategoryLabel = categoryLabelBuilder ?? _categoryLabel;
    final accent = accentColor ?? bankTheme.primary;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: backgroundColor ?? bankTheme.surface,
        borderRadius: radius ?? bankTheme.sheetRadius,
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
                  color: handleColor ?? bankTheme.outline,
                  borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                ),
              ),
            ),
          ),
          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    BankTokens.space4,
                    BankTokens.space4,
                    BankTokens.space4,
                    bottomPadding + BankTokens.space4,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: avatar + name + amount ---
                  header ??
                      Center(
                        child: Column(
                          children: [
                            _MerchantAvatar(
                              transaction: transaction,
                              bankTheme: bankTheme,
                              backgroundColor: avatarBackgroundColor,
                              iconColor: accentColor,
                            ),
                            const SizedBox(height: BankTokens.space2),
                            Text(
                              transaction.merchantName,
                              style: BankTokens.headlineSmall
                                  .copyWith(color: bankTheme.onSurface)
                                  .merge(titleStyle),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: BankTokens.space1),
                            Text(
                              formattedAmount,
                              style: bankTheme.numeralHero
                                  .copyWith(
                                    color: amountColor,
                                    decoration: isDeclined
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: bankTheme.onSurfaceVariant,
                                  )
                                  .merge(amountStyle),
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
                    label: dateLabel,
                    value: BankDateFormatter.formatLong(transaction.settledAt),
                    bankTheme: bankTheme,
                  ),
                  _DetailRow(
                    label: categoryLabel,
                    value: resolvedCategoryLabel(transaction.category),
                    bankTheme: bankTheme,
                  ),
                  _DetailRow(
                    label: statusRowLabel,
                    value: _statusLabel(transaction.status, scope),
                    valueColor: _statusColor(transaction.status, bankTheme),
                    bankTheme: bankTheme,
                  ),
                  if (transaction.reference != null)
                    _DetailRow(
                      label: referenceLabel,
                      value: transaction.reference!,
                      bankTheme: bankTheme,
                      canCopy: true,
                      copyIcon: copyIcon,
                    ),
                  if (transaction.note != null)
                    _DetailRow(
                      label: noteLabel,
                      value: transaction.note!,
                      bankTheme: bankTheme,
                    ),
                  if (transaction.spenderName != null)
                    _DetailRow(
                      label: paidByLabel,
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
                        child: mapPreview,
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
                      categoryBreakdownLabel,
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
                                resolvedCategoryLabel(split.category),
                                style: BankTokens.bodyMedium.copyWith(
                                  color: bankTheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              BankMoneyFormatter.format(
                                amount: split.amount.amount,
                                currencyCode: split.amount.currencyCode,
                                locale: context.bankLocale,
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
                                disputeIcon ?? BankIcons.dispute,
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
                                shareIcon ?? BankIcons.share,
                                color: accent,
                                size: 18,
                              ),
                              label: Text(
                                s.share,
                                style: BankTokens.labelMedium.copyWith(
                                  color: accent,
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
  final IconData? copyIcon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.bankTheme,
    this.valueColor,
    this.canCopy = false,
    this.copyIcon,
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
                        copyIcon ?? BankIcons.copy,
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
  final Color? backgroundColor;
  final Color? iconColor;

  const _MerchantAvatar({
    required this.transaction,
    required this.bankTheme,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<_MerchantAvatar> createState() => _MerchantAvatarState();
}

class _MerchantAvatarState extends State<_MerchantAvatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final bankTheme = widget.bankTheme;
    final logoUrl = widget.transaction.merchantLogoUrl;
    final resolvedBackground =
        widget.backgroundColor ?? bankTheme.surfaceVariant;

    if (logoUrl != null && !_failed) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: resolvedBackground,
        backgroundImage: BankUiScope.imageProviderFor(context, logoUrl),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _failed = true);
        },
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: resolvedBackground,
      child: Icon(
        BankIcons.forCategoryName(widget.transaction.category.name),
        size: 28,
        color: widget.iconColor ?? bankTheme.primary,
      ),
    );
  }
}
