import 'money.dart';

class InstallmentPlan {
  final int termMonths;
  final Money monthlyAmount;
  final Money totalAmount;
  final bool isInterestFree;
  final double? annualRate; // null when isInterestFree
  final DateTime? startDate;

  const InstallmentPlan({
    required this.termMonths,
    required this.monthlyAmount,
    required this.totalAmount,
    required this.isInterestFree,
    this.annualRate,
    this.startDate,
  });

  InstallmentPlan copyWith({
    int? termMonths,
    Money? monthlyAmount,
    Money? totalAmount,
    bool? isInterestFree,
    double? annualRate,
    DateTime? startDate,
  }) =>
      InstallmentPlan(
        termMonths: termMonths ?? this.termMonths,
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        totalAmount: totalAmount ?? this.totalAmount,
        isInterestFree: isInterestFree ?? this.isInterestFree,
        annualRate: annualRate ?? this.annualRate,
        startDate: startDate ?? this.startDate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallmentPlan &&
          runtimeType == other.runtimeType &&
          termMonths == other.termMonths &&
          monthlyAmount == other.monthlyAmount &&
          totalAmount == other.totalAmount &&
          isInterestFree == other.isInterestFree &&
          annualRate == other.annualRate &&
          startDate == other.startDate;

  @override
  int get hashCode => Object.hash(
        termMonths,
        monthlyAmount,
        totalAmount,
        isInterestFree,
        annualRate,
        startDate,
      );
}
