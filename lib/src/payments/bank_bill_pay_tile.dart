import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_emblem.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Lifecycle state of a [BankBill].
enum BankBillStatus { upcoming, dueSoon, overdue, scheduled, paid, autopay }

/// A saved biller / upcoming bill.
class BankBill {
  const BankBill({
    required this.id,
    required this.billerName,
    required this.amountDue,
    required this.dueDate,
    required this.status,
    this.billerLogoUrl,
    this.eBill = false,
  });

  final String id;
  final String billerName;
  final Money amountDue;
  final DateTime dueDate;
  final BankBillStatus status;
  final String? billerLogoUrl;

  /// Paperless bill delivered electronically.
  final bool eBill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankBill &&
          other.id == id &&
          other.billerName == billerName &&
          other.amountDue == amountDue &&
          other.dueDate == dueDate &&
          other.status == status &&
          other.billerLogoUrl == billerLogoUrl &&
          other.eBill == eBill;

  @override
  int get hashCode => Object.hash(
        id,
        billerName,
        amountDue,
        dueDate,
        status,
        billerLogoUrl,
        eBill,
      );
}

/// A saved-biller / upcoming-bill row for the bill-pay center.
///
/// Consistent with `BankTransactionListTile`: biller emblem, name and a
/// due line that turns warning-coloured within three days of the due
/// date and danger when overdue, the amount on the trailing edge, a
/// status chip for autopay / scheduled / paid, and an inline tonal Pay
/// button for payable bills.
///
/// ```dart
/// BankBillPayTile(
///   bill: bill,
///   onPay: () => startPayment(bill),
///   onTap: () => openBill(bill),
/// )
/// ```
class BankBillPayTile extends StatelessWidget {
  const BankBillPayTile({
    required this.bill,
    super.key,
    this.onPay,
    this.onTap,
    this.trailing,
    this.duePrefix = 'Due',
    this.payLabel = 'Pay',
    this.autopayLabel = 'Autopay',
    this.scheduledLabel = 'Scheduled',
    this.paidLabel = 'Paid',
    this.overdueLabel = 'Overdue',
    this.padding,
    this.leading,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.eBillIcon,
    this.autopayIcon,
    this.scheduledIcon,
    this.paidIcon,
    this.semanticLabel,
  });

  final BankBill bill;

  /// Renders the inline Pay button on payable bills
  /// (upcoming / dueSoon / overdue).
  final VoidCallback? onPay;

  final VoidCallback? onTap;

  /// Replaces the default trailing cluster entirely when set.
  final Widget? trailing;

  final String duePrefix;
  final String payLabel;
  final String autopayLabel;
  final String scheduledLabel;
  final String paidLabel;
  final String overdueLabel;

  /// Overrides the row content padding. Defaults to horizontal
  /// [BankTokens.space4] and vertical [BankTokens.space2].
  final EdgeInsetsGeometry? padding;

  /// Replaces the leading biller emblem when set.
  final Widget? leading;

  /// Tint of the inline Pay button. Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the computed biller-name style.
  final TextStyle? titleStyle;

  /// Merged over the computed due-line style.
  final TextStyle? subtitleStyle;

  /// Merged over the computed amount style.
  final TextStyle? amountStyle;

  /// Glyph marking paperless bills. Defaults to [Icons.bolt_outlined].
  final IconData? eBillIcon;

  /// Glyph on the autopay chip. Defaults to [BankIcons.repeat].
  final IconData? autopayIcon;

  /// Glyph on the scheduled chip. Defaults to [BankIcons.schedule].
  final IconData? scheduledIcon;

  /// Glyph on the paid chip. Defaults to [Icons.check_rounded].
  final IconData? paidIcon;

  /// Overrides the computed row semantics label.
  final String? semanticLabel;

  bool get _payable =>
      onPay != null &&
      (bill.status == BankBillStatus.upcoming ||
          bill.status == BankBillStatus.dueSoon ||
          bill.status == BankBillStatus.overdue);

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final dueColor = switch (bill.status) {
      BankBillStatus.overdue => BankTokens.danger,
      BankBillStatus.dueSoon => BankTokens.warning,
      _ => theme.onSurfaceVariant,
    };
    final dueText = bill.status == BankBillStatus.overdue
        ? '$overdueLabel · ${BankDateFormatter.formatShort(bill.dueDate)}'
        : '$duePrefix ${BankDateFormatter.formatShort(bill.dueDate)}';

    final accent = accentColor ?? theme.primary;
    final resolvedAmountStyle = amountStyle == null
        ? null
        : theme.numeralSmall
            .copyWith(color: theme.onSurface)
            .merge(amountStyle);

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? '${bill.billerName}, $dueText',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
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
                      imageUrl: bill.billerLogoUrl,
                      initialsFrom: bill.billerName,
                    ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billerName,
                        style: BankTokens.bodyLarge
                            .copyWith(color: theme.onSurface)
                            .merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              dueText,
                              style: BankTokens.bodySmall
                                  .copyWith(color: dueColor)
                                  .merge(subtitleStyle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bill.eBill) ...[
                            const SizedBox(width: BankTokens.space1),
                            Icon(
                              eBillIcon ?? Icons.bolt_outlined,
                              size: 12,
                              color: theme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                if (trailing != null)
                  trailing!
                else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BankBalanceText(
                        money: bill.amountDue,
                        size: BankBalanceSize.small,
                        style: resolvedAmountStyle,
                      ),
                      const SizedBox(height: 2),
                      _StatusChip(
                        status: bill.status,
                        autopayLabel: autopayLabel,
                        scheduledLabel: scheduledLabel,
                        paidLabel: paidLabel,
                        autopayIcon: autopayIcon,
                        scheduledIcon: scheduledIcon,
                        paidIcon: paidIcon,
                        theme: theme,
                      ),
                    ],
                  ),
                  if (_payable) ...[
                    const SizedBox(width: BankTokens.space3),
                    FilledButton.tonal(
                      onPressed: onPay,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.12),
                        foregroundColor: accent,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: theme.buttonRadius,
                        ),
                      ),
                      child: Text(payLabel, style: BankTokens.labelLarge),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.autopayLabel,
    required this.scheduledLabel,
    required this.paidLabel,
    required this.theme,
    this.autopayIcon,
    this.scheduledIcon,
    this.paidIcon,
  });

  final BankBillStatus status;
  final String autopayLabel;
  final String scheduledLabel;
  final String paidLabel;
  final BankThemeData theme;
  final IconData? autopayIcon;
  final IconData? scheduledIcon;
  final IconData? paidIcon;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      BankBillStatus.autopay => (
          autopayLabel,
          theme.primary,
          autopayIcon ?? BankIcons.repeat,
        ),
      BankBillStatus.scheduled => (
          scheduledLabel,
          theme.pending,
          scheduledIcon ?? BankIcons.schedule,
        ),
      BankBillStatus.paid => (
          paidLabel,
          theme.positiveBalance,
          paidIcon ?? Icons.check_rounded,
        ),
      _ => (null, null, null),
    };
    if (label == null || color == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: BankTokens.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal 14-day strip showing which upcoming days carry bill due
/// dates, for the cashflow-aware bill view. Days with dues render a dot
/// and the summed amount under the day number.
class BankBillCalendarStrip extends StatelessWidget {
  const BankBillCalendarStrip({
    required this.bills,
    super.key,
    this.days = 14,
    this.startDate,
    this.onDayTap,
    this.padding,
    this.height,
    this.radius,
    this.accentColor,
    this.dayStyle,
    this.billsDueLabel = 'bills due',
  });

  final List<BankBill> bills;

  /// How many days to render, starting from [startDate].
  final int days;

  /// Defaults to today.
  final DateTime? startDate;

  final void Function(DateTime day, List<BankBill> due)? onDayTap;

  /// Overrides the strip's scroll padding. Defaults to horizontal
  /// [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Overrides the strip height. Defaults to 76.
  final double? height;

  /// Overrides the day-cell corner radius. Defaults to the theme
  /// chip radius.
  final BorderRadius? radius;

  /// Tint of due-day cells and dots. Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the computed day-number style.
  final TextStyle? dayStyle;

  /// Semantics suffix announced after the due count, e.g. '2 bills due'.
  final String billsDueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final start = startDate ?? DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final accent = accentColor ?? theme.primary;
    final cellRadius = radius ?? theme.chipRadius;

    return SizedBox(
      height: height ?? 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        itemCount: days,
        separatorBuilder: (_, __) => const SizedBox(width: BankTokens.space2),
        itemBuilder: (context, index) {
          final day = startDay.add(Duration(days: index));
          final due = bills
              .where(
                (bill) =>
                    bill.dueDate.year == day.year &&
                    bill.dueDate.month == day.month &&
                    bill.dueDate.day == day.day,
              )
              .toList(growable: false);
          final hasDue = due.isNotEmpty;

          return Semantics(
            button: onDayTap != null,
            label: '${BankDateFormatter.formatShort(day)}'
                '${hasDue ? ', ${due.length} $billsDueLabel' : ''}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onDayTap == null ? null : () => onDayTap!(day, due),
              borderRadius: cellRadius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hasDue
                      ? accent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: cellRadius,
                ),
                child: SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        BankDateFormatter.formatShort(day).split(' ').first,
                        style: BankTokens.labelMedium
                            .copyWith(
                              color: hasDue ? accent : theme.onSurface,
                            )
                            .merge(dayStyle),
                      ),
                      const SizedBox(height: 4),
                      if (hasDue)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(width: 5, height: 5),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
