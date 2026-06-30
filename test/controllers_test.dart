import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankIncomeSorterController', () {
    SavingsPot pot(String id) => SavingsPot(
          id: id,
          name: id,
          target: Money.fromDouble(1000, 'GBP'),
          current: Money.zero('GBP'),
          hasOwnAccountNumber: false,
          memberIds: const [],
          isRoundUpDestination: false,
        );

    IncomeSorterEntry entry(String id, double value, {bool pct = true}) =>
        IncomeSorterEntry(
          potId: id,
          potName: id,
          fractionOrFixed: value,
          isPercentage: pct,
        );

    test('percentage entries allocate proportionally', () {
      final c = BankIncomeSorterController(
        incomingAmount: Money.fromDouble(1000, 'GBP'),
        availablePots: [pot('a'), pot('b')],
      )
        ..addEntry(entry('a', 30))
        ..addEntry(entry('b', 20));

      expect(c.totalAllocated, Money.fromDouble(500, 'GBP'));
      expect(c.remaining, Money.fromDouble(500, 'GBP'));
      expect(c.isValid, isTrue);
    });

    test('over-allocation is invalid', () {
      final c = BankIncomeSorterController(
        incomingAmount: Money.fromDouble(100, 'GBP'),
        availablePots: [pot('a')],
      )..addEntry(entry('a', 150));

      expect(c.isValid, isFalse);
      expect(c.remaining.isNegative, isTrue);
    });

    test('fixed entries subtract absolute amounts', () {
      final c = BankIncomeSorterController(
        incomingAmount: Money.fromDouble(1000, 'GBP'),
        availablePots: [pot('a')],
      )..addEntry(entry('a', 250, pct: false));

      expect(c.totalAllocated, Money.fromDouble(250, 'GBP'));
    });

    test('removeEntry updates the allocation', () {
      final c = BankIncomeSorterController(
        incomingAmount: Money.fromDouble(1000, 'GBP'),
        availablePots: [pot('a')],
      )..addEntry(entry('a', 50));
      expect(c.totalAllocated, Money.fromDouble(500, 'GBP'));
      c.removeEntry(0);
      expect(c.totalAllocated, Money.zero('GBP'));
    });
  });
}
