import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

// ---------------------------------------------------------------------------
// Entry model
// ---------------------------------------------------------------------------

/// Represents a single pot allocation rule within [BankIncomeSorterController].
///
/// When [isPercentage] is `true`, [fractionOrFixed] is treated as a percentage
/// of the incoming income (e.g. `25.0` means 25 %).
/// When `false`, it is treated as an absolute monetary amount in the same
/// currency as [BankIncomeSorterController.incomingAmount].
class IncomeSorterEntry {
  final String potId;
  final String potName;
  double fractionOrFixed;
  final bool isPercentage;

  IncomeSorterEntry({
    required this.potId,
    required this.potName,
    required this.fractionOrFixed,
    this.isPercentage = true,
  });

  IncomeSorterEntry copyWith({
    String? potId,
    String? potName,
    double? fractionOrFixed,
    bool? isPercentage,
  }) =>
      IncomeSorterEntry(
        potId: potId ?? this.potId,
        potName: potName ?? this.potName,
        fractionOrFixed: fractionOrFixed ?? this.fractionOrFixed,
        isPercentage: isPercentage ?? this.isPercentage,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncomeSorterEntry &&
        other.potId == potId &&
        other.potName == potName &&
        other.fractionOrFixed == fractionOrFixed &&
        other.isPercentage == isPercentage;
  }

  @override
  int get hashCode =>
      Object.hash(potId, potName, fractionOrFixed, isPercentage);
}

// ---------------------------------------------------------------------------
// Status sealed hierarchy
// ---------------------------------------------------------------------------

/// Base class for all income-sorter status values emitted by
/// [BankIncomeSorterController].
sealed class BankIncomeSorterStatus {
  const BankIncomeSorterStatus();
}

/// Initial state — the user has not started editing yet.
class BankIncomeSorterIdle extends BankIncomeSorterStatus {
  const BankIncomeSorterIdle();
}

/// The user is actively editing the allocation rules.
class BankIncomeSorterEditing extends BankIncomeSorterStatus {
  const BankIncomeSorterEditing();
}

/// The user confirmed the allocation rules.
///
/// [entries] is an unmodifiable snapshot of the confirmed rules.
/// [saveForNext] reflects whether the user chose to persist the rules for
/// future income events.
class BankIncomeSorterConfirmed extends BankIncomeSorterStatus {
  final List<IncomeSorterEntry> entries;
  final bool saveForNext;

  const BankIncomeSorterConfirmed(
    this.entries, {
    required this.saveForNext,
  });
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Headless controller for the income-sorter feature.
///
/// The income-sorter lets users split an incoming payment across multiple
/// savings pots before it lands in their main account. The controller tracks
/// the allocation rules, validates that they do not exceed the incoming amount,
/// and emits [BankIncomeSorterConfirmed] when the user is satisfied.
class BankIncomeSorterController extends ChangeNotifier {
  /// The gross incoming amount being distributed.
  final Money incomingAmount;

  /// All savings pots the user may allocate income into.
  final List<SavingsPot> availablePots;

  List<IncomeSorterEntry> _entries = [];
  bool _saveForNext = false;
  BankIncomeSorterStatus _status = const BankIncomeSorterIdle();

  BankIncomeSorterController({
    required this.incomingAmount,
    required this.availablePots,
  });

  // ---------------------------------------------------------------------------
  // Read-only accessors
  // ---------------------------------------------------------------------------

  /// An unmodifiable view of the current allocation entries.
  List<IncomeSorterEntry> get entries => List.unmodifiable(_entries);

  /// Whether the user chose to save these rules for the next income event.
  bool get saveForNext => _saveForNext;

  /// The latest status emitted by the controller.
  BankIncomeSorterStatus get status => _status;

  // ---------------------------------------------------------------------------
  // Derived computations
  // ---------------------------------------------------------------------------

  /// The total amount that has been allocated across all entries.
  ///
  /// Each entry is resolved to an absolute [Money] value:
  /// - If [IncomeSorterEntry.isPercentage] is `true`, the value is
  ///   `incomingAmount * (fractionOrFixed / 100)`.
  /// - If `false`, the value is treated as an absolute amount in the same
  ///   currency.
  Money get totalAllocated {
    if (_entries.isEmpty) return Money.zero(incomingAmount.currencyCode);

    var total = Money.zero(incomingAmount.currencyCode);
    for (final entry in _entries) {
      final Money entryAmount;
      if (entry.isPercentage) {
        final factor =
            Decimal.parse((entry.fractionOrFixed / 100).toStringAsFixed(10));
        entryAmount = Money(
          amount: (incomingAmount.amount * factor).round(scale: 2),
          currencyCode: incomingAmount.currencyCode,
        );
      } else {
        entryAmount = Money(
          amount: Decimal.parse(entry.fractionOrFixed.toStringAsFixed(2)),
          currencyCode: incomingAmount.currencyCode,
        );
      }
      total = total + entryAmount;
    }
    return total;
  }

  /// The portion of [incomingAmount] that has not yet been allocated.
  ///
  /// May be negative if the user over-allocates; callers should check
  /// [isValid] before confirming.
  Money get remaining => incomingAmount - totalAllocated;

  /// `true` when the total allocated amount does not exceed [incomingAmount].
  bool get isValid => !remaining.isNegative;

  // ---------------------------------------------------------------------------
  // Mutation
  // ---------------------------------------------------------------------------

  /// Appends a new [entry] to the allocation list.
  void addEntry(IncomeSorterEntry entry) {
    _entries = List.of(_entries)..add(entry);
    _status = const BankIncomeSorterEditing();
    notifyListeners();
  }

  /// Replaces the entry at [index] with [entry].
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  void updateEntry(int index, IncomeSorterEntry entry) {
    final updated = List.of(_entries);
    updated[index] = entry;
    _entries = updated;
    _status = const BankIncomeSorterEditing();
    notifyListeners();
  }

  /// Removes the entry at [index].
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  void removeEntry(int index) {
    final updated = List.of(_entries);
    updated.removeAt(index);
    _entries = updated;
    _status = const BankIncomeSorterEditing();
    notifyListeners();
  }

  /// Sets whether to persist the current rules for the next income event.
  void setSaveForNext(bool value) {
    _saveForNext = value;
    notifyListeners();
  }

  /// Confirms the current allocation rules if [isValid].
  ///
  /// Emits [BankIncomeSorterConfirmed] with an unmodifiable snapshot of the
  /// entries and the current [saveForNext] value. If the allocation is
  /// invalid (total exceeds [incomingAmount]), this method is a no-op.
  void confirm() {
    if (!isValid) return;

    final snapshot = List<IncomeSorterEntry>.unmodifiable(_entries);
    _status = BankIncomeSorterConfirmed(snapshot, saveForNext: _saveForNext);
    notifyListeners();
  }

  /// Resets the controller to its initial state.
  void reset() {
    _entries = [];
    _saveForNext = false;
    _status = const BankIncomeSorterIdle();
    notifyListeners();
  }
}
