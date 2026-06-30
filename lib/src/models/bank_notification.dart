enum BankNotificationType {
  payment,
  transfer,
  security,
  fraud,
  marketing,
  system,
  savingsGoal,
  cardActivity,
  kycUpdate,
  priceAlert,
}

class BankNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final BankNotificationType type;
  final String? deepLinkPath; // host app handles routing
  final String? imageUrl;

  const BankNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isRead,
    required this.type,
    this.deepLinkPath,
    this.imageUrl,
  });

  BankNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    BankNotificationType? type,
    String? deepLinkPath,
    String? imageUrl,
  }) =>
      BankNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        receivedAt: receivedAt ?? this.receivedAt,
        isRead: isRead ?? this.isRead,
        type: type ?? this.type,
        deepLinkPath: deepLinkPath ?? this.deepLinkPath,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          receivedAt == other.receivedAt &&
          isRead == other.isRead &&
          type == other.type &&
          deepLinkPath == other.deepLinkPath &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        body,
        receivedAt,
        isRead,
        type,
        deepLinkPath,
        imageUrl,
      );
}
