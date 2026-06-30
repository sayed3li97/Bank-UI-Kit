import 'money.dart';

enum BankAccountStatus { active, frozen, restricted, closed, pending }

enum BankAccountType { current, savings, joint, business, isa, crypto }

class BankAccount {
  final String id;
  final String name; // e.g. 'Main Account'
  final String maskedNumber; // e.g. '•••• 4242'
  final Money balance;
  final BankAccountStatus status;
  final BankAccountType type;
  final String currencyCode;
  final String? ibanOrAccountNumber; // full, for display in detail
  final String? sortCodeOrBic;
  final List<String>? ownerIds; // for joint accounts

  const BankAccount({
    required this.id,
    required this.name,
    required this.maskedNumber,
    required this.balance,
    required this.status,
    required this.type,
    required this.currencyCode,
    this.ibanOrAccountNumber,
    this.sortCodeOrBic,
    this.ownerIds,
  });

  BankAccount copyWith({
    String? id,
    String? name,
    String? maskedNumber,
    Money? balance,
    BankAccountStatus? status,
    BankAccountType? type,
    String? currencyCode,
    String? ibanOrAccountNumber,
    String? sortCodeOrBic,
    List<String>? ownerIds,
  }) =>
      BankAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        maskedNumber: maskedNumber ?? this.maskedNumber,
        balance: balance ?? this.balance,
        status: status ?? this.status,
        type: type ?? this.type,
        currencyCode: currencyCode ?? this.currencyCode,
        ibanOrAccountNumber: ibanOrAccountNumber ?? this.ibanOrAccountNumber,
        sortCodeOrBic: sortCodeOrBic ?? this.sortCodeOrBic,
        ownerIds: ownerIds ?? this.ownerIds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          maskedNumber == other.maskedNumber &&
          balance == other.balance &&
          status == other.status &&
          type == other.type &&
          currencyCode == other.currencyCode &&
          ibanOrAccountNumber == other.ibanOrAccountNumber &&
          sortCodeOrBic == other.sortCodeOrBic &&
          _listEquals(ownerIds, other.ownerIds);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        maskedNumber,
        balance,
        status,
        type,
        currencyCode,
        ibanOrAccountNumber,
        sortCodeOrBic,
        Object.hashAll(ownerIds ?? const []),
      );

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
