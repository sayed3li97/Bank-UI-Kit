import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<BankNotification> _notifications;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _notifications = [
      BankNotification(
        id: 'n1',
        title: 'Payment received',
        body: 'Alice Johnson sent you £35.00',
        type: BankNotificationType.transfer,
        receivedAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      BankNotification(
        id: 'n2',
        title: 'New device login',
        body: 'A new login was detected from iPhone 16 Pro in London.',
        type: BankNotificationType.security,
        receivedAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      BankNotification(
        id: 'n3',
        title: 'Payment due',
        body: 'Your credit card payment of £250.00 is due in 3 days.',
        type: BankNotificationType.payment,
        receivedAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      BankNotification(
        id: 'n4',
        title: 'Exclusive offer',
        body: 'Get 5% cashback on your next grocery shop this weekend.',
        type: BankNotificationType.marketing,
        receivedAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      BankNotification(
        id: 'n5',
        title: 'Card activity',
        body: 'You spent £42.50 at Sainsbury\'s.',
        type: BankNotificationType.cardActivity,
        receivedAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BankInAppNotificationCenter(
        notifications: _notifications,
        onNotificationTap: (n) => setState(() {
          final idx = _notifications.indexWhere((x) => x.id == n.id);
          if (idx != -1) {
            _notifications[idx] = n.copyWith(isRead: true);
          }
        }),
        onDismiss: (n) => setState(
          () => _notifications.removeWhere((x) => x.id == n.id),
        ),
        onMarkAllRead: () => setState(() {
          _notifications =
              _notifications.map((n) => n.copyWith(isRead: true)).toList();
        }),
      ),
    );
  }
}
