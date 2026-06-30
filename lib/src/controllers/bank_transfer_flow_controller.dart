import 'package:flutter/foundation.dart';

import '../models/models.dart';

// ---------------------------------------------------------------------------
// Step enum
// ---------------------------------------------------------------------------

/// The ordered steps in the money-transfer flow.
enum BankTransferStep {
  amount,
  beneficiary,
  review,
  pin,
  result,
}

// ---------------------------------------------------------------------------
// Status sealed hierarchy
// ---------------------------------------------------------------------------

/// Base class for all transfer flow status values emitted by
/// [BankTransferFlowController].
sealed class BankTransferStatus {
  const BankTransferStatus();
}

/// Initial state — the flow has not started yet.
class BankTransferIdle extends BankTransferStatus {
  const BankTransferIdle();
}

/// The flow advanced or went back to a new [step].
class BankTransferStepChanged extends BankTransferStatus {
  final BankTransferStep step;
  const BankTransferStepChanged(this.step);
}

/// The PIN was accepted and the transfer is being processed.
class BankTransferProcessing extends BankTransferStatus {
  const BankTransferProcessing();
}

/// The transfer completed successfully with the given [referenceNumber].
class BankTransferSuccess extends BankTransferStatus {
  final String referenceNumber;
  const BankTransferSuccess(this.referenceNumber);
}

/// The transfer failed with a human-readable [reason].
class BankTransferFailure extends BankTransferStatus {
  final String reason;
  const BankTransferFailure(this.reason);
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Headless controller that drives a multi-step money-transfer flow.
///
/// UI layers observe this [ChangeNotifier] and render each [step] as it
/// changes. The controller stores the user's inputs ([amount], [beneficiary],
/// [isScheduled], [scheduledDate]) so they can be read back at any point,
/// e.g. to display a review summary.
///
/// Network calls are the host app's responsibility. Use [markSuccess] and
/// [markFailure] to propagate API results back into the controller.
class BankTransferFlowController extends ChangeNotifier {
  BankTransferStep _step = BankTransferStep.amount;
  BankTransferStatus _status = const BankTransferIdle();
  Money? _amount;
  BankBeneficiary? _beneficiary;
  bool _isScheduled = false;
  DateTime? _scheduledDate;

  /// The step currently displayed to the user.
  BankTransferStep get step => _step;

  /// The latest status emitted by the flow.
  BankTransferStatus get status => _status;

  /// The amount the user entered, or `null` if not yet set.
  Money? get amount => _amount;

  /// The beneficiary selected by the user, or `null` if not yet set.
  BankBeneficiary? get beneficiary => _beneficiary;

  /// Whether the transfer is scheduled for a future date.
  bool get isScheduled => _isScheduled;

  /// The scheduled date, or `null` when [isScheduled] is `false`.
  DateTime? get scheduledDate => _scheduledDate;

  // ---------------------------------------------------------------------------
  // Input setters
  // ---------------------------------------------------------------------------

  /// Records the [amount] the user wants to send and notifies listeners.
  void setAmount(Money amount) {
    _amount = amount;
    notifyListeners();
  }

  /// Records the selected [beneficiary] and notifies listeners.
  void setBeneficiary(BankBeneficiary beneficiary) {
    _beneficiary = beneficiary;
    notifyListeners();
  }

  /// Toggles scheduled transfer mode.
  ///
  /// When [isScheduled] is `true`, [date] becomes the scheduled date.
  /// When `false`, any previously stored [scheduledDate] is cleared.
  void setScheduled(bool isScheduled, {DateTime? date}) {
    _isScheduled = isScheduled;
    _scheduledDate = isScheduled ? date : null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Advances the flow to the next [BankTransferStep].
  ///
  /// Has no effect when the flow is already on [BankTransferStep.result].
  void advance() {
    final next = switch (_step) {
      BankTransferStep.amount => BankTransferStep.beneficiary,
      BankTransferStep.beneficiary => BankTransferStep.review,
      BankTransferStep.review => BankTransferStep.pin,
      BankTransferStep.pin => BankTransferStep.result,
      BankTransferStep.result => BankTransferStep.result,
    };

    if (next == _step) return;

    _step = next;
    _status = BankTransferStepChanged(next);
    notifyListeners();
  }

  /// Navigates back to the previous [BankTransferStep].
  ///
  /// Has no effect when the flow is on [BankTransferStep.amount].
  void goBack() {
    final previous = switch (_step) {
      BankTransferStep.amount => BankTransferStep.amount,
      BankTransferStep.beneficiary => BankTransferStep.amount,
      BankTransferStep.review => BankTransferStep.beneficiary,
      BankTransferStep.pin => BankTransferStep.review,
      BankTransferStep.result => BankTransferStep.pin,
    };

    if (previous == _step) return;

    _step = previous;
    _status = BankTransferStepChanged(previous);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Called when the user confirms their PIN.
  ///
  /// Emits [BankTransferProcessing] immediately. The host app is responsible
  /// for validating [pin] against its backend and calling [markSuccess] or
  /// [markFailure] with the result.
  ///
  /// The [pin] parameter is intentionally unused by the controller itself —
  /// PIN validation must never happen on the client.
  void submitPin(String pin) {
    _status = const BankTransferProcessing();
    notifyListeners();
  }

  /// Marks the transfer as successful and advances the flow to the result
  /// step with a [referenceNumber] that the UI can display.
  void markSuccess(String referenceNumber) {
    _step = BankTransferStep.result;
    _status = BankTransferSuccess(referenceNumber);
    notifyListeners();
  }

  /// Marks the transfer as failed and advances the flow to the result step
  /// with a human-readable [reason].
  void markFailure(String reason) {
    _step = BankTransferStep.result;
    _status = BankTransferFailure(reason);
    notifyListeners();
  }

  /// Resets the controller to its initial state so a new transfer can begin.
  void reset() {
    _step = BankTransferStep.amount;
    _status = const BankTransferIdle();
    _amount = null;
    _beneficiary = null;
    _isScheduled = false;
    _scheduledDate = null;
    notifyListeners();
  }
}
