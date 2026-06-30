import 'package:flutter/material.dart';

import '../../models/bank_notification.dart';
import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

/// A scrollable notification feed with read/unread states and swipe-to-dismiss.
class BankInAppNotificationCenter extends StatelessWidget {
  final List<BankNotification> notifications;
  final void Function(BankNotification)? onNotificationTap;
  final void Function(BankNotification)? onDismiss;
  final VoidCallback? onMarkAllRead;
  final Widget? emptyState;

  const BankInAppNotificationCenter({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onDismiss,
    this.onMarkAllRead,
    this.emptyState,
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
                Icon(Icons.notifications_none_rounded,
                    size: 48, color: theme.onSurfaceVariant),
                const SizedBox(height: BankTokens.space3),
                Text(
                  'No notifications',
                  style:
                      BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
                ),
              ],
            ),
          );
    }

    return Column(
      children: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                Text(
                  '$unreadCount unread',
                  style: BankTokens.labelSmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
                const Spacer(),
                if (onMarkAllRead != null)
                  TextButton(
                    onPressed: onMarkAllRead,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space3,
                      ),
                    ),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.outline.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                theme: theme,
                onTap: () => onNotificationTap?.call(notification),
                onDismiss: onDismiss != null
                    ? () => onDismiss!(notification)
                    : null,
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
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.theme,
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

  static Color _colorFor(BankNotificationType type, BankThemeData theme) =>
      switch (type) {
        BankNotificationType.security || BankNotificationType.fraud =>
          BankTokens.investmentLoss,
        BankNotificationType.payment || BankNotificationType.transfer =>
          BankTokens.investmentGain,
        _ => theme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final Widget tile = Semantics(
      label:
          '${notification.isRead ? '' : 'Unread: '}${notification.title}. ${notification.body}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : theme.primary.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colorFor(notification.type, theme).withOpacity(0.12),
                ),
                child: Icon(
                  _iconFor(notification.type),
                  size: 20,
                  color: _colorFor(notification.type, theme),
                ),
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
                            style: BankTokens.labelMedium.copyWith(
                              color: theme.onSurface,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.receivedAt),
                      style: BankTokens.labelSmall.copyWith(
                        color: theme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDismiss == null) return tile;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: BankTokens.investmentLoss.withOpacity(0.12),
        padding: const EdgeInsets.only(right: BankTokens.space4),
        child: const Icon(Icons.delete_outline_rounded,
            color: BankTokens.investmentLoss),
      ),
      onDismissed: (_) => onDismiss!(),
      child: tile,
    );
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
