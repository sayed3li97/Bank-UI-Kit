import 'transaction.dart';

enum InsightConfidence { low, medium, high }

class BankInsight {
  final String id;
  final String title;
  final String body;
  final InsightConfidence confidence;
  final DateTime generatedAt;
  final bool isDismissed;
  final TransactionCategory? relatedCategory;

  const BankInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.confidence,
    required this.generatedAt,
    required this.isDismissed,
    this.relatedCategory,
  });

  BankInsight copyWith({
    String? id,
    String? title,
    String? body,
    InsightConfidence? confidence,
    DateTime? generatedAt,
    bool? isDismissed,
    TransactionCategory? relatedCategory,
  }) =>
      BankInsight(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        confidence: confidence ?? this.confidence,
        generatedAt: generatedAt ?? this.generatedAt,
        isDismissed: isDismissed ?? this.isDismissed,
        relatedCategory: relatedCategory ?? this.relatedCategory,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankInsight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          confidence == other.confidence &&
          generatedAt == other.generatedAt &&
          isDismissed == other.isDismissed &&
          relatedCategory == other.relatedCategory;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        body,
        confidence,
        generatedAt,
        isDismissed,
        relatedCategory,
      );
}
