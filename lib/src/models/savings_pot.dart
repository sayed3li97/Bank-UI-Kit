import 'package:decimal/decimal.dart';

import 'money.dart';

class SavingsPot {
  final String id;
  final String name;
  final Money target;
  final Money current;
  final double? interestRate; // annual percentage, e.g. 3.5
  final bool hasOwnAccountNumber;
  final String? imageUrl;
  final List<String> memberIds; // empty for personal, multiple for shared
  final DateTime? targetDate;
  final bool isRoundUpDestination;

  const SavingsPot({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.hasOwnAccountNumber,
    required this.memberIds,
    required this.isRoundUpDestination,
    this.interestRate,
    this.imageUrl,
    this.targetDate,
  });

  SavingsPot copyWith({
    String? id,
    String? name,
    Money? target,
    Money? current,
    double? interestRate,
    bool? hasOwnAccountNumber,
    String? imageUrl,
    List<String>? memberIds,
    DateTime? targetDate,
    bool? isRoundUpDestination,
  }) =>
      SavingsPot(
        id: id ?? this.id,
        name: name ?? this.name,
        target: target ?? this.target,
        current: current ?? this.current,
        interestRate: interestRate ?? this.interestRate,
        hasOwnAccountNumber: hasOwnAccountNumber ?? this.hasOwnAccountNumber,
        imageUrl: imageUrl ?? this.imageUrl,
        memberIds: memberIds ?? this.memberIds,
        targetDate: targetDate ?? this.targetDate,
        isRoundUpDestination: isRoundUpDestination ?? this.isRoundUpDestination,
      );

  double get progressFraction => target.amount == Decimal.zero
      ? 0
      : (current.amount / target.amount).toDouble().clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsPot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          target == other.target &&
          current == other.current &&
          interestRate == other.interestRate &&
          hasOwnAccountNumber == other.hasOwnAccountNumber &&
          imageUrl == other.imageUrl &&
          _listEquals(memberIds, other.memberIds) &&
          targetDate == other.targetDate &&
          isRoundUpDestination == other.isRoundUpDestination;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        target,
        current,
        interestRate,
        hasOwnAccountNumber,
        imageUrl,
        Object.hashAll(memberIds),
        targetDate,
        isRoundUpDestination,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
