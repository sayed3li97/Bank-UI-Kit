enum BeneficiaryType { internal, bankTransfer, international }

class BankBeneficiary {
  final String id;
  final String name;
  final String maskedAccount; // e.g. '•••• 1234'
  final BeneficiaryType type;
  final String? avatarUrl;
  final String? bankName;
  final String? currencyCode;
  final bool isVerified;

  const BankBeneficiary({
    required this.id,
    required this.name,
    required this.maskedAccount,
    required this.type,
    this.avatarUrl,
    this.bankName,
    this.currencyCode,
    required this.isVerified,
  });

  BankBeneficiary copyWith({
    String? id,
    String? name,
    String? maskedAccount,
    BeneficiaryType? type,
    String? avatarUrl,
    String? bankName,
    String? currencyCode,
    bool? isVerified,
  }) =>
      BankBeneficiary(
        id: id ?? this.id,
        name: name ?? this.name,
        maskedAccount: maskedAccount ?? this.maskedAccount,
        type: type ?? this.type,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bankName: bankName ?? this.bankName,
        currencyCode: currencyCode ?? this.currencyCode,
        isVerified: isVerified ?? this.isVerified,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankBeneficiary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          maskedAccount == other.maskedAccount &&
          type == other.type &&
          avatarUrl == other.avatarUrl &&
          bankName == other.bankName &&
          currencyCode == other.currencyCode &&
          isVerified == other.isVerified;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        maskedAccount,
        type,
        avatarUrl,
        bankName,
        currencyCode,
        isVerified,
      );
}
