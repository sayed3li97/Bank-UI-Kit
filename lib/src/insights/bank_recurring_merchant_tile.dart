import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_emblem.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../models/transaction.dart';
import '../payments/bank_standing_order_tile.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A detected recurring payment (subscription) surfaced by PFM analysis.
class BankRecurringMerchant {
  const BankRecurringMerchant({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.cadence,
    required this.nextExpectedDate,
    required this.firstSeen,
    required this.category,
    this.merchantLogoUrl,
    this.previousAmount,
    this.priceIncreased = false,
  });

  final String id;
  final String merchantName;
  final Money amount;
  final BankRecurringPattern cadence;
  final DateTime nextExpectedDate;
  final DateTime firstSeen;
  final TransactionCategory category;
  final String? merchantLogoUrl;

  /// The charge before the latest one, for price-rise comparison.
  final Money? previousAmount;

  /// Latest charge exceeded [previousAmount].
  final bool priceIncreased;
}

/// Detected-recurring-payment row for the PFM subscription manager -
/// distinct from the `subscriptions/` domain, which covers the bank's
/// own premium tiers.
///
/// Shows the merchant emblem, cadence and next-expected-date line, the
/// amount (with the previous amount struck through and a warning chip
/// when the price rose), and an overflow menu offering cancellation
/// help and payment blocking.
///
/// ```dart
/// BankRecurringMerchantTile(
///   merchant: merchant,
///   onCancelHelp: () => openCancelGuide(merchant),
///   onBlock: () => api.blockMerchant(merchant.id),
/// )
/// ```
class BankRecurringMerchantTile extends StatelessWidget {
  const BankRecurringMerchantTile({
    required this.merchant,
    super.key,
    this.onTap,
    this.onCancelHelp,
    this.onBlock,
    this.nextPrefix = 'next',
    this.priceRiseLabel = 'Price rise',
    this.cancelHelpLabel = 'How to cancel',
    this.blockLabel = 'Block future payments',
    this.blockConfirmTitle = 'Block this merchant?',
    this.blockConfirmBody =
        'Future charges from this merchant will be declined.',
    this.cancelLabel = 'Cancel',
    this.padding,
    this.height,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.priceRiseColor,
    this.moreIcon,
    this.cancelHelpIcon,
    this.blockIcon,
    this.semanticLabel,
  });

  final BankRecurringMerchant merchant;

  final VoidCallback? onTap;

  /// Opens cancellation guidance for this merchant.
  final VoidCallback? onCancelHelp;

  /// Blocks future charges; asked for confirmation first.
  final VoidCallback? onBlock;

  final String nextPrefix;
  final String priceRiseLabel;
  final String cancelHelpLabel;
  final String blockLabel;
  final String blockConfirmTitle;
  final String blockConfirmBody;
  final String cancelLabel;

  /// Overrides the row content padding. Defaults to space4 by space2.
  final EdgeInsetsGeometry? padding;

  /// Overrides the row minimum height. Defaults to 72.
  final double? height;

  /// Replaces the merchant emblem. Defaults to a [BankEmblem] built
  /// from the merchant logo or initials.
  final Widget? leading;

  /// Merged over the merchant name style (bodyLarge, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the cadence line style (bodySmall, onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Overrides the price-rise chip tint. Defaults to
  /// [BankTokens.warning].
  final Color? priceRiseColor;

  /// Overrides the overflow menu glyph. Defaults to
  /// [Icons.more_vert_rounded].
  final IconData? moreIcon;

  /// Overrides the cancel-help sheet glyph. Defaults to
  /// [Icons.help_outline_rounded].
  final IconData? cancelHelpIcon;

  /// Overrides the block sheet glyph. Defaults to
  /// [Icons.block_rounded].
  final IconData? blockIcon;

  /// Overrides the tile semantics label. Defaults to the merchant name
  /// and cadence line.
  final String? semanticLabel;

  Future<void> _showActions(BuildContext context) async {
    final theme = BankThemeData.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onCancelHelp != null)
              ListTile(
                leading: Icon(
                  cancelHelpIcon ?? Icons.help_outline_rounded,
                  color: theme.onSurface,
                ),
                title: Text(
                  cancelHelpLabel,
                  style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onCancelHelp!();
                },
              ),
            if (onBlock != null)
              ListTile(
                leading: Icon(
                  blockIcon ?? Icons.block_rounded,
                  color: BankTokens.danger,
                ),
                title: Text(
                  blockLabel,
                  style:
                      BankTokens.bodyLarge.copyWith(color: BankTokens.danger),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: theme.surface,
                      title: Text(
                        blockConfirmTitle,
                        style: BankTokens.headlineSmall
                            .copyWith(color: theme.onSurface),
                      ),
                      content: Text(
                        blockConfirmBody,
                        style: BankTokens.bodyMedium
                            .copyWith(color: theme.onSurfaceVariant),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(cancelLabel),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(
                            blockLabel,
                            style: const TextStyle(color: BankTokens.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) onBlock!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final cadenceLine = '${merchant.cadence.label} · $nextPrefix '
        '${BankDateFormatter.formatShort(merchant.nextExpectedDate)}';
    final hasActions = onCancelHelp != null || onBlock != null;

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? '${merchant.merchantName}, $cadenceLine',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height ?? 72),
          child: Padding(
            padding: padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space2,
                ),
            child: Row(
              children: [
                leading ??
                    BankEmblem(
                      imageUrl: merchant.merchantLogoUrl,
                      initialsFrom: merchant.merchantName,
                    ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              merchant.merchantName,
                              style: BankTokens.bodyLarge
                                  .copyWith(color: theme.onSurface)
                                  .merge(titleStyle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (merchant.priceIncreased) ...[
                            const SizedBox(width: BankTokens.space2),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: (priceRiseColor ?? BankTokens.warning)
                                    .withValues(alpha: 0.12),
                                borderRadius: theme.chipRadius,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BankTokens.space2,
                                  vertical: 2,
                                ),
                                child: Text(
                                  priceRiseLabel,
                                  style: BankTokens.labelSmall.copyWith(
                                    color: priceRiseColor ?? BankTokens.warning,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cadenceLine,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(subtitleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BankBalanceText(
                      money: merchant.amount,
                      size: BankBalanceSize.small,
                    ),
                    if (merchant.priceIncreased &&
                        merchant.previousAmount != null)
                      Text(
                        BankMoneyFormatter.format(
                          amount: merchant.previousAmount!.amount,
                          currencyCode: merchant.previousAmount!.currencyCode,
                          numeralStyle: scope.numeralStyle,
                        ),
                        style: BankTokens.labelSmall.copyWith(
                          color: theme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                if (hasActions)
                  IconButton(
                    onPressed: () => _showActions(context),
                    icon: Icon(
                      moreIcon ?? Icons.more_vert_rounded,
                      size: 20,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary bar for the subscription manager: total recurring spend per
/// month (or year) across the detected merchants.
class BankRecurringTotalHeader extends StatefulWidget {
  const BankRecurringTotalHeader({
    required this.merchants,
    super.key,
    this.monthlyTemplate = 'You spend {amount}/month on {count} subscriptions',
    this.yearlyTemplate = 'About {amount}/year',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.headlineStyle,
    this.sublineStyle,
  });

  final List<BankRecurringMerchant> merchants;

  /// `{amount}` and `{count}` placeholders are substituted.
  final String monthlyTemplate;

  /// Shown under the headline; `{amount}` is substituted.
  final String yearlyTemplate;

  /// Overrides the bar content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the bar corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the bar fill. Defaults to the theme primary at 8%
  /// opacity.
  final Color? backgroundColor;

  /// Merged over the headline style (bodyLarge w600, onSurface).
  final TextStyle? headlineStyle;

  /// Merged over the subline style (bodySmall, onSurfaceVariant).
  final TextStyle? sublineStyle;

  @override
  State<BankRecurringTotalHeader> createState() =>
      _BankRecurringTotalHeaderState();
}

class _BankRecurringTotalHeaderState extends State<BankRecurringTotalHeader> {
  double _monthlyTotal() {
    var total = 0.0;
    for (final merchant in widget.merchants) {
      final amount = merchant.amount.amount.toDouble();
      total += switch (merchant.cadence) {
        BankRecurringPattern.daily => amount * 30,
        BankRecurringPattern.weekly => amount * 4.33,
        BankRecurringPattern.biweekly => amount * 2.17,
        BankRecurringPattern.monthly => amount,
      };
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    if (widget.merchants.isEmpty) return const SizedBox.shrink();

    final currency = widget.merchants.first.amount.currencyCode;
    final monthly = _monthlyTotal();

    String format(double value) => BankMoneyFormatter.format(
          amount: Money.fromDouble(value, currency).amount,
          currencyCode: currency,
          numeralStyle: scope.numeralStyle,
        );

    final headline = widget.monthlyTemplate
        .replaceAll('{amount}', format(monthly))
        .replaceAll('{count}', '${widget.merchants.length}');
    final subline =
        widget.yearlyTemplate.replaceAll('{amount}', format(monthly * 12));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.primary.withValues(alpha: 0.08),
        borderRadius: widget.radius ?? theme.cardRadius,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: BankTokens.bodyLarge
                  .copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w600,
                  )
                  .merge(widget.headlineStyle),
            ),
            const SizedBox(height: 2),
            Text(
              subline,
              style: BankTokens.bodySmall
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(widget.sublineStyle),
            ),
          ],
        ),
      ),
    );
  }
}
