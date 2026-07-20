import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/bank_pressable.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/numeral_style.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';

/// A single transaction row, designed for use inside [ListView.builder].
///
/// The amount carries the row's optical weight (tabular numerals at 600
/// weight); the merchant name sits beside it in [BankTokens.labelLarge];
/// a secondary line shows `category · time` in the muted
/// `onSurfaceVariant`, with any non-cleared status appended in its
/// semantic colour.
///
/// **Money semantics:** credits render in the theme's `positiveBalance`
/// family with an explicit `+` sign; debits stay neutral `onSurface` —
/// spending is normal, not an error, so red is reserved for genuinely
/// negative states (declines). Tappable rows get the kit-wide
/// [BankPressable] hover / press / focus treatment.
class BankTransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  /// Full override: when provided, replaces the default tile layout entirely.
  final Widget Function(BuildContext, Transaction)? itemBuilder;

  /// Overrides the row content padding. Defaults to horizontal
  /// [BankTokens.space4] and vertical [BankTokens.space2].
  final EdgeInsetsGeometry? padding;

  /// Overrides the ink splash radius. Defaults to the theme card radius.
  final BorderRadius? radius;

  /// Overrides the minimum row height. Defaults to 72.
  final double? height;

  /// Replaces the leading category avatar when provided.
  final Widget? leading;

  /// Replaces the trailing amount text when provided.
  final Widget? trailing;

  /// Overrides the avatar background. Defaults to the theme surfaceVariant.
  final Color? avatarBackgroundColor;

  /// Overrides the category icon color. Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the merchant name style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the secondary-line style ([BankTokens.bodySmall] in
  /// `onSurfaceVariant`; a non-cleared status keeps its semantic colour).
  final TextStyle? subtitleStyle;

  /// Localised display name for the transaction's category, shown on the
  /// secondary line. Defaults to an English name derived from
  /// [Transaction.category] (e.g. `'Credit payment'`); supply for
  /// non-English locales.
  final String? categoryLabel;

  /// Whether the secondary line shows `category · time`. Defaults to
  /// `true`; set `false` to restore the status-only secondary line.
  final bool showCategoryAndTime;

  /// Merged over the computed amount style.
  final TextStyle? amountStyle;

  /// Overrides the tile semantics label. Defaults to merchant name,
  /// amount, and status.
  final String? semanticLabel;

  const BankTransactionListTile({
    required this.transaction,
    super.key,
    this.onTap,
    this.itemBuilder,
    this.padding,
    this.radius,
    this.height,
    this.leading,
    this.trailing,
    this.avatarBackgroundColor,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.categoryLabel,
    this.showCategoryAndTime = true,
    this.amountStyle,
    this.semanticLabel,
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
        TransactionStatus.refunded => bankTheme.positiveBalance,
        TransactionStatus.scheduled => BankTokens.frozen,
        TransactionStatus.cleared => bankTheme.onSurfaceVariant,
      };

  /// English fallback for the category name: `creditPayment` reads as
  /// `'Credit payment'`. Override per-locale via [categoryLabel].
  static String _defaultCategoryLabel(TransactionCategory category) {
    final spaced = category.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

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
      locale: context.bankLocale,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    // Privacy mode replaces the amount with the scope's masked label in both
    // the visible row and the semantics announcement.
    final displayAmount =
        scope.privacyEnabled ? scope.strings.balanceHidden : formattedAmount;

    // Debits stay neutral onSurface — spending is normal, not an error —
    // while credits take the positive-balance family with their explicit
    // '+' sign, and declines mute to onSurfaceVariant with a strikethrough.
    final amountColor = isDeclined
        ? bankTheme.onSurfaceVariant
        : isCredit
            ? bankTheme.positiveBalance
            : bankTheme.onSurface;

    // The amount carries the row's optical weight: tabular numerals at
    // 600, at least as heavy as the labelLarge merchant name.
    final computedAmountStyle = bankTheme.numeralSmall
        .copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
          decoration:
              isDeclined ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: bankTheme.onSurfaceVariant,
        )
        .merge(amountStyle);

    // Secondary line: 'category · time' in the muted onSurfaceVariant,
    // with any non-cleared status appended in its semantic colour.
    final String? metaText;
    if (showCategoryAndTime) {
      final resolvedCategory =
          categoryLabel ?? _defaultCategoryLabel(transaction.category);
      final time = scope.numeralStyle
          .convert(BankDateFormatter.formatTime(transaction.settledAt));
      metaText = '$resolvedCategory · $time';
    } else {
      metaText = null;
    }
    final subtitleBaseStyle = BankTokens.bodySmall
        .copyWith(color: bankTheme.onSurfaceVariant)
        .merge(subtitleStyle);

    final resolvedSemanticLabel = semanticLabel ??
        [
          transaction.merchantName,
          displayAmount,
          if (metaText != null) metaText,
          transaction.status.name,
        ].join(', ');

    return BankPressable(
      onTap: onTap,
      borderRadius: radius ?? bankTheme.cardRadius,
      semanticLabel: resolvedSemanticLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height ?? 72),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
          child: Row(
            children: [
              leading ??
                  _LeadingAvatar(
                    transaction: transaction,
                    bankTheme: bankTheme,
                    backgroundColor: avatarBackgroundColor,
                    iconColor: accentColor,
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
                      style: BankTokens.labelLarge
                          .copyWith(color: bankTheme.onSurface)
                          .merge(titleStyle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metaText != null || statusLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (metaText != null) TextSpan(text: metaText),
                            if (metaText != null && statusLabel.isNotEmpty)
                              const TextSpan(text: ' · '),
                            if (statusLabel.isNotEmpty)
                              TextSpan(
                                text: statusLabel,
                                style: TextStyle(
                                  color: _statusColor(
                                    transaction.status,
                                    bankTheme,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        style: subtitleBaseStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: BankTokens.space2),
              trailing ??
                  Text(
                    displayAmount,
                    style: computedAmountStyle,
                    textAlign: TextAlign.end,
                  ),
            ],
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
  final Color? backgroundColor;
  final Color? iconColor;

  const _LeadingAvatar({
    required this.transaction,
    required this.bankTheme,
    this.backgroundColor,
    this.iconColor,
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
    final resolvedBackground =
        widget.backgroundColor ?? bankTheme.surfaceVariant;

    if (logoUrl != null && !_logoFailed) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: resolvedBackground,
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
      backgroundColor: resolvedBackground,
      child: Icon(
        BankIcons.forCategoryName(widget.transaction.category.name),
        size: 20,
        color: widget.iconColor ?? bankTheme.primary,
      ),
    );
  }
}
