import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Step enum
// ---------------------------------------------------------------------------

/// The ordered steps in the KYC (Know Your Customer) onboarding flow.
enum BankKycStep {
  welcome,
  documentType,
  documentCapture,
  selfie,
  liveness,
  review,
  complete,
}

// ---------------------------------------------------------------------------
// Status sealed hierarchy
// ---------------------------------------------------------------------------

/// Base class for all KYC flow status values emitted by
/// [BankKycFlowController].
sealed class BankKycStatus {
  const BankKycStatus();
}

/// Initial state — no action has been taken yet.
class BankKycIdle extends BankKycStatus {
  const BankKycIdle();
}

/// The flow moved to a new [step].
class BankKycStepChanged extends BankKycStatus {
  final BankKycStep step;
  const BankKycStepChanged(this.step);
}

/// All steps have been completed and the application was submitted.
class BankKycSubmitted extends BankKycStatus {
  const BankKycSubmitted();
}

/// The submitted application is awaiting manual or automated review.
class BankKycUnderReview extends BankKycStatus {
  const BankKycUnderReview();
}

/// The KYC application was approved.
class BankKycApproved extends BankKycStatus {
  const BankKycApproved();
}

/// The KYC application was rejected with a human-readable [reason].
class BankKycRejected extends BankKycStatus {
  final String reason;
  const BankKycRejected(this.reason);
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Headless controller that drives a multi-step KYC onboarding flow.
///
/// UI layers listen to this [ChangeNotifier] and rebuild when [currentStep]
/// or [status] changes. The controller never performs network calls; the host
/// app is responsible for wiring [markApproved] / [markRejected] to the
/// result of its own API call.
class BankKycFlowController extends ChangeNotifier {
  BankKycStep _currentStep = BankKycStep.welcome;
  BankKycStatus _status = const BankKycIdle();

  /// The step currently displayed to the user.
  BankKycStep get currentStep => _currentStep;

  /// The latest status emitted by the flow.
  BankKycStatus get status => _status;

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Advances the flow to the next [BankKycStep].
  ///
  /// Has no effect when the flow is already on [BankKycStep.complete].
  void advance() {
    final next = switch (_currentStep) {
      BankKycStep.welcome => BankKycStep.documentType,
      BankKycStep.documentType => BankKycStep.documentCapture,
      BankKycStep.documentCapture => BankKycStep.selfie,
      BankKycStep.selfie => BankKycStep.liveness,
      BankKycStep.liveness => BankKycStep.review,
      BankKycStep.review => BankKycStep.complete,
      BankKycStep.complete => BankKycStep.complete,
    };

    if (next == _currentStep) return;

    _currentStep = next;
    _status = BankKycStepChanged(next);
    notifyListeners();
  }

  /// Navigates back to the previous [BankKycStep].
  ///
  /// Has no effect when the flow is on [BankKycStep.welcome].
  void goBack() {
    final previous = switch (_currentStep) {
      BankKycStep.welcome => BankKycStep.welcome,
      BankKycStep.documentType => BankKycStep.welcome,
      BankKycStep.documentCapture => BankKycStep.documentType,
      BankKycStep.selfie => BankKycStep.documentCapture,
      BankKycStep.liveness => BankKycStep.selfie,
      BankKycStep.review => BankKycStep.liveness,
      BankKycStep.complete => BankKycStep.review,
    };

    if (previous == _currentStep) return;

    _currentStep = previous;
    _status = BankKycStepChanged(previous);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Submits the completed KYC application.
  ///
  /// Emits [BankKycSubmitted] immediately, then [BankKycUnderReview] to signal
  /// that the application is pending a decision. The two notifications are
  /// delivered in separate microtask frames so UI layers can react to each.
  void submit() {
    _status = const BankKycSubmitted();
    notifyListeners();

    Future.microtask(() {
      _status = const BankKycUnderReview();
      notifyListeners();
    });
  }

  /// Marks the KYC application as approved.
  void markApproved() {
    _status = const BankKycApproved();
    notifyListeners();
  }

  /// Marks the KYC application as rejected with a human-readable [reason].
  void markRejected(String reason) {
    _status = BankKycRejected(reason);
    notifyListeners();
  }

  /// Resets the controller back to its initial state so the flow can be
  /// restarted from the beginning.
  void reset() {
    _currentStep = BankKycStep.welcome;
    _status = const BankKycIdle();
    notifyListeners();
  }
}
