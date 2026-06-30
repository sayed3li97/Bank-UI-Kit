import 'money.dart';

enum TransactionStatus { cleared, pending, declined, refunded, scheduled }

enum TransactionCategory {
  groceries,
  dining,
  transport,
  entertainment,
  utilities,
  health,
  shopping,
  travel,
  education,
  subscription,
  transfer,
  income,
  investment,
  creditPayment,
  other,
}

class Transaction {
  final String id;
  final Money amount; // negative = debit, positive = credit
  final DateTime settledAt;
  final TransactionStatus status;
  final String merchantName;
  final String? merchantLogoUrl;
  final TransactionCategory category;
  final String? reference;
  final String? accountId;
  final String? note;
  final String? spenderId; // for joint account tagging
  final String? spenderName;
  final String? spenderAvatarUrl;
  final bool isFlexEligible; // BNPL-splittable
  final List<TransactionSplit>? categorySplits;

  const Transaction({
    required this.id,
    required this.amount,
    required this.settledAt,
    required this.status,
    required this.merchantName,
    this.merchantLogoUrl,
    required this.category,
    this.reference,
    this.accountId,
    this.note,
    this.spenderId,
    this.spenderName,
    this.spenderAvatarUrl,
    this.isFlexEligible = false,
    this.categorySplits,
  });

  Transaction copyWith({
    String? id,
    Money? amount,
    DateTime? settledAt,
    TransactionStatus? status,
    String? merchantName,
    String? merchantLogoUrl,
    TransactionCategory? category,
    String? reference,
    String? accountId,
    String? note,
    String? spenderId,
    String? spenderName,
    String? spenderAvatarUrl,
    bool? isFlexEligible,
    List<TransactionSplit>? categorySplits,
  }) =>
      Transaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        settledAt: settledAt ?? this.settledAt,
        status: status ?? this.status,
        merchantName: merchantName ?? this.merchantName,
        merchantLogoUrl: merchantLogoUrl ?? this.merchantLogoUrl,
        category: category ?? this.category,
        reference: reference ?? this.reference,
        accountId: accountId ?? this.accountId,
        note: note ?? this.note,
        spenderId: spenderId ?? this.spenderId,
        spenderName: spenderName ?? this.spenderName,
        spenderAvatarUrl: spenderAvatarUrl ?? this.spenderAvatarUrl,
        isFlexEligible: isFlexEligible ?? this.isFlexEligible,
        categorySplits: categorySplits ?? this.categorySplits,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          settledAt == other.settledAt &&
          status == other.status &&
          merchantName == other.merchantName &&
          merchantLogoUrl == other.merchantLogoUrl &&
          category == other.category &&
          reference == other.reference &&
          accountId == other.accountId &&
          note == other.note &&
          spenderId == other.spenderId &&
          spenderName == other.spenderName &&
          spenderAvatarUrl == other.spenderAvatarUrl &&
          isFlexEligible == other.isFlexEligible &&
          _splitsEqual(categorySplits, other.categorySplits);

  @override
  int get hashCode => Object.hash(
        id,
        amount,
        settledAt,
        status,
        merchantName,
        merchantLogoUrl,
        category,
        reference,
        accountId,
        note,
        spenderId,
        spenderName,
        spenderAvatarUrl,
        isFlexEligible,
        Object.hashAll(categorySplits ?? const []),
      );

  static bool _splitsEqual(
    List<TransactionSplit>? a,
    List<TransactionSplit>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class TransactionSplit {
  final TransactionCategory category;
  final Money amount;

  const TransactionSplit({required this.category, required this.amount});

  TransactionSplit copyWith({
    TransactionCategory? category,
    Money? amount,
  }) =>
      TransactionSplit(
        category: category ?? this.category,
        amount: amount ?? this.amount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionSplit &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(category, amount);
}
