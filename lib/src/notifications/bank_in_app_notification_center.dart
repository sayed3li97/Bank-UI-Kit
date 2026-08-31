import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/bank_pressable.dart';
import '../models/bank_notification.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A scrollable notification feed with read/unread states and swipe-to-dismiss.
///
/// Unread is encoded by **one** device, not three: a marker dot in the row's
/// semantic accent, backed by a heavier title. Rows deliberately do not take a
/// full-bleed colour wash — a per-row wash turns a feed into a striped block,
/// fights every accent inside the row, and duplicates what the dot already
/// says. Pass [unreadTintColor] to opt back into a wash.
class BankInAppNotificationCenter extends StatelessWidget {
  final List<BankNotification> notifications;
  final void Function(BankNotification)? onNotificationTap;
  final void Function(BankNotification)? onDismiss;
  final VoidCallback? onMarkAllRead;
  final Widget? emptyState;

  /// Optional slot rendered above the feed. Defaults to nothing.
  final Widget? header;

  /// Empty-state message. Defaults to 'No notifications'.
  final String emptyLabel;

  /// Mark-all-read button label. Defaults to 'Mark all read'.
  final String markAllReadLabel;

  /// Word after the unread count. Defaults to 'unread'.
  final String unreadSuffix;

  /// Semantics prefix for unread tiles. Defaults to 'Unread: '.
  final String unreadSemanticPrefix;

  /// Relative timestamp under a minute. Defaults to 'Just now'.
  final String justNowLabel;

  /// Suffix after the minute count. Defaults to 'm ago'.
  final String minutesAgoSuffix;

  /// Suffix after the hour count. Defaults to 'h ago'.
  final String hoursAgoSuffix;

  /// Suffix after the day count. Defaults to 'd ago'.
  final String daysAgoSuffix;

  /// Empty-state glyph. Defaults to [Icons.notifications_none_rounded].
  final IconData? emptyIcon;

  /// Swipe-to-dismiss background glyph. Defaults to
  /// [Icons.delete_outline_rounded].
  final IconData? dismissIcon;

  /// Per-type glyph overrides, merged over the built-in mapping.
  final Map<BankNotificationType, IconData> typeIcons;

  /// Per-type accent overrides, merged over the built-in mapping.
  final Map<BankNotificationType, Color> typeColors;

  /// Fill behind unread tiles.
  ///
  /// Defaults to no fill: unread is carried by the marker dot and the heavier
  /// title, and a per-row wash on top of those is the third encoding of one
  /// bit. Set it to restore a wash — [BankEmblem.fillFor] gives one at the
  /// kit's standard strength.
  final Color? unreadTintColor;

  /// Accent of the swipe-to-dismiss affordance. Defaults to
  /// [BankThemeData.negativeBalance], so it tracks brightness.
  final Color? dismissColor;

  /// Divider color between tiles. Defaults to the theme hairline.
  final Color? dividerColor;

  /// Merged over the computed tile title style (labelMedium).
  final TextStyle? titleStyle;

  /// Merged over the computed tile body style (bodySmall).
  final TextStyle? bodyStyle;

  /// Merged over the computed timestamp style ([BankTokens.caption]).
  final TextStyle? timeStyle;

  /// Overrides each tile's padding. Defaults to [BankTokens.space4]
  /// horizontal and [BankTokens.space3] vertical.
  final EdgeInsetsGeometry? itemPadding;

  const BankInAppNotificationCenter({
    required this.notifications,
    super.key,
    this.onNotificationTap,
    this.onDismiss,
    this.onMarkAllRead,
    this.emptyState,
    this.header,
    this.emptyLabel = 'No notifications',
    this.markAllReadLabel = 'Mark all read',
    this.unreadSuffix = 'unread',
    this.unreadSemanticPrefix = 'Unread: ',
    this.justNowLabel = 'Just now',
    this.minutesAgoSuffix = 'm ago',
    this.hoursAgoSuffix = 'h ago',
    this.daysAgoSuffix = 'd ago',
    this.emptyIcon,
    this.dismissIcon,
    this.typeIcons = const {},
    this.typeColors = const {},
    this.unreadTintColor,
    this.dismissColor,
    this.dividerColor,
    this.titleStyle,
    this.bodyStyle,
    this.timeStyle,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    if (notifications.isEmpty) {
      return emptyState ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  emptyIcon ?? Icons.notifications_none_rounded,
                  size: BankTokens.iconHero,
                  color: theme.onSurfaceVariant,
                ),
                const SizedBox(height: BankTokens.space3),
                Text(
                  emptyLabel,
                  style: BankTokens.bodyMedium
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ],
            ),
          );
    }

    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(theme.surface);

    return Column(
      children: [
        if (header != null) header!,
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                Text(
                  '$unreadCount $unreadSuffix',
                  style: BankTokens.caption
                      .copyWith(color: theme.onSurfaceVariant),
                ),
                const Spacer(),
                if (onMarkAllRead != null)
                  TextButton(
                    onPressed: onMarkAllRead,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, BankTokens.minTapTarget),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space3,
                      ),
                    ),
                    child: Text(markAllReadLabel),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: BankTokens.hairlineWidth,
              thickness: BankTokens.hairlineWidth,
              color: dividerColor ??
                  BankTokens.hairlineColor(theme.onSurface, surfaceBrightness),
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                theme: theme,
                center: this,
                onTap: onNotificationTap == null
                    ? null
                    : () => onNotificationTap!(notification),
                onDismiss:
                    onDismiss != null ? () => onDismiss!(notification) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final BankNotification notification;
  final BankThemeData theme;
  final BankInAppNotificationCenter center;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.theme,
    required this.center,
    this.onTap,
    this.onDismiss,
  });

  static IconData _iconFor(BankNotificationType type) => switch (type) {
        BankNotificationType.payment => Icons.receipt_rounded,
        BankNotificationType.transfer => Icons.swap_horiz_rounded,
        BankNotificationType.security => Icons.security_rounded,
        BankNotificationType.fraud => Icons.warning_amber_rounded,
        BankNotificationType.marketing => Icons.local_offer_rounded,
        BankNotificationType.system => Icons.info_rounded,
        BankNotificationType.savingsGoal => Icons.savings_rounded,
        BankNotificationType.cardActivity => Icons.credit_card_rounded,
        BankNotificationType.kycUpdate => Icons.verified_rounded,
        BankNotificationType.priceAlert => Icons.show_chart_rounded,
      };

  /// Semantic accent per type, taken from the *theme's* brightness-aware
  /// financial colours rather than the light-surface tokens — the light red
  /// used to stay put on a near-black feed and fall under AA.
  static Color _colorFor(BankNotificationType type, BankThemeData theme) =>
      switch (type) {
        BankNotificationType.security ||
        BankNotificationType.fraud =>
          theme.negativeBalance,
        BankNotificationType.payment ||
        BankNotificationType.transfer =>
          theme.positiveBalance,
        _ => theme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final accent = center.typeColors[notification.type] ??
        _colorFor(notification.type, theme);
    final markerInk = BankEmblem.inkFor(theme, accent);
    final dismissAccent = center.dismissColor ?? theme.negativeBalance;
    final unread = !notification.isRead;

    final Widget row = Container(
      color: unread ? center.unreadTintColor : null,
      padding: center.itemPadding ??
          const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BankEmblem(
            icon: center.typeIcons[notification.type] ??
                _iconFor(notification.type),
            tier: BankEmblemSize.medium,
            tintColor: accent,
          ),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: BankTokens.labelMedium
                            .copyWith(
                              color: theme.onSurface,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.normal,
                            )
                            .merge(center.titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: BankTokens.space2),
                      Container(
                        width: BankTintChip.dotSize,
                        height: BankTintChip.dotSize,
                        decoration: BoxDecoration(
                          color: markerInk,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BankTokens.space1),
                Text(
                  notification.body,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(center.bodyStyle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: BankTokens.space1),
                Text(
                  _timeAgo(notification.receivedAt),
                  style: BankTokens.caption
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(center.timeStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget tile = BankPressable(
      onTap: onTap,
      semanticLabel: '${unread ? center.unreadSemanticPrefix : ''}'
          '${notification.title}. '
          '${notification.body}',
      excludeSemantics: true,
      child: row,
    );

    if (onDismiss == null) return tile;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: BankEmblem.fillFor(theme, dismissAccent),
        padding: const EdgeInsetsDirectional.only(end: BankTokens.space4),
        child: Icon(
          center.dismissIcon ?? Icons.delete_outline_rounded,
          size: BankTokens.iconLarge,
          color: BankEmblem.inkFor(theme, dismissAccent),
        ),
      ),
      onDismissed: (_) => onDismiss!(),
      child: tile,
    );
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return center.justNowLabel;
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${center.minutesAgoSuffix}';
    }
    if (diff.inHours < 24) return '${diff.inHours}${center.hoursAgoSuffix}';
    if (diff.inDays < 7) return '${diff.inDays}${center.daysAgoSuffix}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
