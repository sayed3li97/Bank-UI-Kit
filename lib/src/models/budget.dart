import 'package:decimal/decimal.dart';

import 'money.dart';
import 'transaction.dart';

class BankBudget {
  final String id;
  final String name;
  final TransactionCategory? category; // null = overall budget
  final Money limit;
  final Money spent;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BankBudget({
    required this.id,
    required this.name,
    required this.limit,
    required this.spent,
    required this.periodStart,
    required this.periodEnd,
    this.category,
  });

  BankBudget copyWith({
    String? id,
    String? name,
    TransactionCategory? category,
    Money? limit,
    Money? spent,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) =>
      BankBudget(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        limit: limit ?? this.limit,
        spent: spent ?? this.spent,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
      );

  double get spentFraction => limit.amount == Decimal.zero
      ? 0
      : (spent.amount / limit.amount).toDouble().clamp(0.0, double.infinity);

  bool get isOverBudget => spent.amount > limit.amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankBudget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          limit == other.limit &&
          spent == other.spent &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        limit,
        spent,
        periodStart,
        periodEnd,
      );
}
