import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Step model
// ---------------------------------------------------------------------------

/// A single step in a multi-step product application flow.
///
/// A step is identified by a stable [id] (used for validity, completion and
/// navigation), carries a human-readable [title] for the UI, and may be
/// marked [optional] so the flow can advance past it even when the host has
/// not reported it as valid.
@immutable
class BankApplicationStep {
  /// Creates an immutable application step description.
  const BankApplicationStep({
    required this.id,
    required this.title,
    this.optional = false,
  });

  /// Stable identifier for this step, unique within a flow.
  final String id;

  /// Human-readable title shown to the user (e.g. 'Your details').
  final String title;

  /// Whether the step can be skipped / advanced past without being valid.
  final bool optional;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankApplicationStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          optional == other.optional;

  @override
  int get hashCode => Object.hash(id, title, optional);

  @override
  String toString() =>
      'BankApplicationStep(id: $id, title: $title, optional: $optional)';
}

// ---------------------------------------------------------------------------
// Status enum
// ---------------------------------------------------------------------------

/// The lifecycle status of a product application, from data entry through to
/// the lender's decision.
enum BankApplicationStatus {
  /// The user is still working through the steps.
  inProgress,

  /// The application has been sent and is awaiting acknowledgement.
  submitting,

  /// The application was successfully submitted for a decision.
  submitted,

  /// The application was approved.
  approved,

  /// The application was referred for manual review.
  referred,

  /// The application was declined.
  declined,
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Headless state machine that drives a multi-step product application (apply)
/// flow, such as applying for a loan, card, mortgage or deposit account.
///
/// This is a plain [ChangeNotifier] with no Flutter widget dependencies, so it
/// can be constructed, unit-tested and driven independently of any UI. A UI
/// layer listens to the controller and rebuilds when [currentIndex],
/// completion, validity or [status] change.
///
/// The controller owns:
/// * the ordered list of [steps];
/// * a free-form [data] bag written via [setField] and read via [getField];
/// * per-step completion, set via [markComplete] and read via [isComplete];
/// * per-step validity, set by the host via [setStepValid], which gates
///   [canAdvance] and therefore [next].
///
/// It performs no network calls. The host app submits the application itself
/// and reports the outcome back through [setStatus].
///
/// ```dart
/// final controller = BankApplicationController(
///   steps: const [
///     BankApplicationStep(id: 'amount', title: 'How much?'),
///     BankApplicationStep(id: 'details', title: 'Your details'),
///     BankApplicationStep(id: 'promo', title: 'Promo code', optional: true),
///     BankApplicationStep(id: 'review', title: 'Review'),
///   ],
/// );
///
/// controller.setField('amount', 10000);
/// controller.setStepValid('amount', true);
/// controller.markComplete('amount');
/// controller.next(); // advances to 'details'
///
/// // When the user taps submit:
/// controller.setStatus(BankApplicationStatus.submitting);
/// final ok = await api.submit(controller.data);
/// controller.setStatus(
///   ok ? BankApplicationStatus.submitted : BankApplicationStatus.declined,
/// );
/// ```
class BankApplicationController extends ChangeNotifier {
  /// Creates a controller for the given ordered [steps].
  ///
  /// [steps] must not be empty. An optional [initialIndex] selects the first
  /// visible step (defaults to the first step).
  BankApplicationController({
    required List<BankApplicationStep> steps,
    int initialIndex = 0,
  })  : assert(steps.isNotEmpty, 'steps must not be empty'),
        assert(
          initialIndex >= 0 && initialIndex < steps.length,
          'initialIndex is out of range',
        ),
        _steps = List<BankApplicationStep>.unmodifiable(steps),
        _initialIndex = initialIndex,
        _currentIndex = initialIndex;

  final List<BankApplicationStep> _steps;
  final int _initialIndex;
  final Map<String, Object?> _data = <String, Object?>{};
  final Set<String> _completed = <String>{};
  final Map<String, bool> _valid = <String, bool>{};

  int _currentIndex;
  BankApplicationStatus _status = BankApplicationStatus.inProgress;

  // -------------------------------------------------------------------------
  // Read-only state
  // -------------------------------------------------------------------------

  /// The ordered, unmodifiable list of steps in this flow.
  List<BankApplicationStep> get steps => _steps;

  /// The zero-based index of the step currently shown to the user.
  int get currentIndex => _currentIndex;

  /// The step currently shown to the user.
  BankApplicationStep get currentStep => _steps[_currentIndex];

  /// The current lifecycle status of the application.
  BankApplicationStatus get status => _status;

  /// An unmodifiable view of the free-form data collected so far.
  Map<String, Object?> get data => Map<String, Object?>.unmodifiable(_data);

  /// Whether the current step is the first step in the flow.
  bool get isFirstStep => _currentIndex == 0;

  /// Whether the current step is the last step in the flow.
  bool get isLastStep => _currentIndex == _steps.length - 1;

  /// Completion progress as a fraction in the range 0.0 to 1.0, computed as
  /// the number of completed steps divided by the total number of steps.
  double get progress => _completed.length / _steps.length;

  /// Whether [next] is currently permitted.
  ///
  /// The flow may advance when the current step has been reported valid via
  /// [setStepValid], or when the current step is [BankApplicationStep.optional]
  /// and no explicit validity has been set for it.
  bool get canAdvance {
    final step = currentStep;
    return _valid[step.id] ?? step.optional;
  }

  // -------------------------------------------------------------------------
  // Data bag
  // -------------------------------------------------------------------------

  /// Stores [value] under [key] in the application [data] bag and notifies
  /// listeners.
  void setField(String key, Object? value) {
    _data[key] = value;
    notifyListeners();
  }

  /// Reads the value stored under [key], cast to [T], or `null` if absent or
  /// of a different type.
  T? getField<T>(String key) {
    final value = _data[key];
    return value is T ? value : null;
  }

  // -------------------------------------------------------------------------
  // Completion
  // -------------------------------------------------------------------------

  /// Marks the step with the given [id] as complete and notifies listeners.
  void markComplete(String id) {
    if (_completed.add(id)) {
      notifyListeners();
    }
  }

  /// Clears the completion flag for the step with the given [id].
  void markIncomplete(String id) {
    if (_completed.remove(id)) {
      notifyListeners();
    }
  }

  /// Whether the step with the given [id] has been marked complete.
  bool isComplete(String id) => _completed.contains(id);

  // -------------------------------------------------------------------------
  // Validity
  // -------------------------------------------------------------------------

  /// Records whether the step with the given [id] currently holds valid input.
  ///
  /// The host calls this as the user edits a step so that [canAdvance] (and
  /// therefore [next]) reflects the latest validity.
  void setStepValid(String id, bool isValid) {
    if (_valid[id] == isValid) return;
    _valid[id] = isValid;
    notifyListeners();
  }

  /// Whether the step with the given [id] is currently valid.
  ///
  /// Falls back to the step's [BankApplicationStep.optional] flag when no
  /// explicit validity has been recorded, or `false` for an unknown [id].
  bool isStepValid(String id) {
    final explicit = _valid[id];
    if (explicit != null) return explicit;
    for (final step in _steps) {
      if (step.id == id) return step.optional;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  /// Advances to the next step when [canAdvance] is `true`.
  ///
  /// Has no effect on the last step or when the current step is not yet valid.
  void next() {
    if (isLastStep || !canAdvance) return;
    _currentIndex++;
    notifyListeners();
  }

  /// Navigates back to the previous step.
  ///
  /// Has no effect when already on the first step.
  void back() {
    if (isFirstStep) return;
    _currentIndex--;
    notifyListeners();
  }

  /// Jumps to the step at [index].
  ///
  /// Out-of-range indices are ignored.
  void goTo(int index) {
    if (index < 0 || index >= _steps.length || index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  /// Jumps to the step whose [BankApplicationStep.id] equals [id].
  ///
  /// Unknown ids are ignored.
  void goToId(String id) {
    final index = _steps.indexWhere((step) => step.id == id);
    if (index == -1) return;
    goTo(index);
  }

  // -------------------------------------------------------------------------
  // Status
  // -------------------------------------------------------------------------

  /// Updates the application lifecycle [status] and notifies listeners.
  void setStatus(BankApplicationStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /// Resets the controller to its initial state so the flow can restart.
  ///
  /// Clears collected data, completion and validity, returns to the initial
  /// step and sets [status] back to [BankApplicationStatus.inProgress].
  void reset() {
    _currentIndex = _initialIndex;
    _status = BankApplicationStatus.inProgress;
    _data.clear();
    _completed.clear();
    _valid.clear();
    notifyListeners();
  }
}
