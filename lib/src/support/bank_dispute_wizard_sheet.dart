import 'package:flutter/material.dart';

import '../common/bank_status_tracker.dart';
import '../common/bank_summary_stack.dart';
import '../common/bank_text_field.dart';
import '../models/transaction.dart';
import '../onboarding/bank_step_progress_indicator.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import '../transactions/bank_transaction_list_tile.dart';

/// Steps of the dispute filing flow.
enum BankDisputeStep { reason, details, evidence, review, submitted }

/// A selectable dispute reason.
class BankDisputeReason {
  const BankDisputeReason({required this.code, required this.label});

  final String code;
  final String label;

  /// Common card-network dispute reasons.
  static const List<BankDisputeReason> defaults = [
    BankDisputeReason(code: 'unauthorized', label: 'I did not authorize this'),
    BankDisputeReason(code: 'duplicate', label: 'I was charged twice'),
    BankDisputeReason(code: 'wrong_amount', label: 'The amount is wrong'),
    BankDisputeReason(
      code: 'not_received',
      label: 'Goods or services not received',
    ),
    BankDisputeReason(
      code: 'cancelled_subscription',
      label: 'I cancelled this subscription',
    ),
    BankDisputeReason(code: 'other', label: 'Something else'),
  ];
}

/// A named evidence attachment descriptor (the host owns file pickers
/// and uploads: the controller stores names only).
class BankDisputeEvidence {
  const BankDisputeEvidence({required this.id, required this.name});

  final String id;
  final String name;
}

/// Headless dispute-flow state, following the kit's controller
/// conventions: pure state machine, never touches the network. The
/// host listens, renders [BankDisputeWizardSheet], and performs the
/// actual submission when [submit] fires [onSubmitRequested].
class BankDisputeFlowController extends ChangeNotifier {
  BankDisputeFlowController({this.onSubmitRequested});

  /// Fired by [submit]; the host performs the network call and then
  /// calls [markSubmitted].
  final VoidCallback? onSubmitRequested;

  BankDisputeStep _step = BankDisputeStep.reason;
  BankDisputeReason? _reason;
  String _description = '';
  final List<BankDisputeEvidence> _evidence = [];

  BankDisputeStep get step => _step;
  BankDisputeReason? get reason => _reason;
  String get description => _description;
  List<BankDisputeEvidence> get evidence => List.unmodifiable(_evidence);

  void selectReason(BankDisputeReason reason) {
    _reason = reason;
    _step = BankDisputeStep.details;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void goToEvidence() {
    if (_description.trim().length < 10) return;
    _step = BankDisputeStep.evidence;
    notifyListeners();
  }

  void addEvidence(BankDisputeEvidence item) {
    _evidence.add(item);
    notifyListeners();
  }

  void removeEvidence(String id) {
    _evidence.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void goToReview() {
    _step = BankDisputeStep.review;
    notifyListeners();
  }

  void submit() => onSubmitRequested?.call();

  /// Host calls this after its network submission succeeds.
  void markSubmitted() {
    _step = BankDisputeStep.submitted;
    notifyListeners();
  }

  /// Back-safe navigation; returns false at the first step.
  bool goBack() {
    switch (_step) {
      case BankDisputeStep.reason:
      case BankDisputeStep.submitted:
        return false;
      case BankDisputeStep.details:
        _step = BankDisputeStep.reason;
      case BankDisputeStep.evidence:
        _step = BankDisputeStep.details;
      case BankDisputeStep.review:
        _step = BankDisputeStep.evidence;
    }
    notifyListeners();
    return true;
  }
}

/// Transaction-anchored dispute filing wizard, launched from the
/// transaction detail sheet's dispute hook. Steps: reason radio list →
/// description → optional evidence slots → review (summary + the
/// disputed transaction) → submitted (status tracker with the expected
/// timeline).
///
/// ```dart
/// BankDisputeWizardSheet.show(
///   context,
///   transaction: transaction,
///   controller: _controller,
/// );
/// ```
class BankDisputeWizardSheet extends StatefulWidget {
  const BankDisputeWizardSheet({
    required this.transaction,
    required this.controller,
    super.key,
    this.reasons = BankDisputeReason.defaults,
    this.onAddEvidence,
    this.title = 'Dispute transaction',
    this.reasonTitle = 'What went wrong?',
    this.detailsTitle = 'Tell us more',
    this.detailsHint = 'Describe what happened (at least 10 characters)',
    this.evidenceTitle = 'Add evidence (optional)',
    this.addEvidenceLabel = 'Add a document',
    this.reviewTitle = 'Review your dispute',
    this.continueLabel = 'Continue',
    this.submitLabel = 'Submit dispute',
    this.reasonLabel = 'Reason',
    this.descriptionLabel = 'Description',
    this.submittedStages = const [
      BankTrackerStage(title: 'Submitted'),
      BankTrackerStage(title: 'Under review'),
      BankTrackerStage(title: 'Resolved'),
    ],
    this.submittedNote = 'Most disputes are resolved within 10 business days.',
  });

  final Transaction transaction;
  final BankDisputeFlowController controller;
  final List<BankDisputeReason> reasons;

  /// Opens the host's file picker; add results via
  /// [BankDisputeFlowController.addEvidence].
  final VoidCallback? onAddEvidence;

  final String title;
  final String reasonTitle;
  final String detailsTitle;
  final String detailsHint;
  final String evidenceTitle;
  final String addEvidenceLabel;
  final String reviewTitle;
  final String continueLabel;
  final String submitLabel;
  final String reasonLabel;
  final String descriptionLabel;
  final List<BankTrackerStage> submittedStages;
  final String submittedNote;

  /// Presents the wizard as a 92%-height modal sheet.
  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    required BankDisputeFlowController controller,
    List<BankDisputeReason> reasons = BankDisputeReason.defaults,
    VoidCallback? onAddEvidence,
  }) {
    final theme = BankThemeData.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: BankDisputeWizardSheet(
          transaction: transaction,
          controller: controller,
          reasons: reasons,
          onAddEvidence: onAddEvidence,
        ),
      ),
    );
  }

  @override
  State<BankDisputeWizardSheet> createState() => _BankDisputeWizardSheetState();
}

class _BankDisputeWizardSheetState extends State<BankDisputeWizardSheet> {
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.controller.description);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _description.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  int _stepIndex(BankDisputeStep step) => switch (step) {
        BankDisputeStep.reason => 1,
        BankDisputeStep.details => 2,
        BankDisputeStep.evidence => 3,
        BankDisputeStep.review => 4,
        BankDisputeStep.submitted => 4,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final controller = widget.controller;
    final step = controller.step;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (step != BankDisputeStep.reason &&
                    step != BankDisputeStep.submitted)
                  IconButton(
                    onPressed: controller.goBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.onSurface,
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: BankTokens.headlineSmall
                        .copyWith(color: theme.onSurface),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (step != BankDisputeStep.submitted) ...[
              const SizedBox(height: BankTokens.space2),
              BankStepProgressIndicator(
                totalSteps: 4,
                currentStep: _stepIndex(step),
              ),
            ],
            const SizedBox(height: BankTokens.space4),
            Expanded(
              child: SingleChildScrollView(
                child: switch (step) {
                  BankDisputeStep.reason => _ReasonStep(
                      title: widget.reasonTitle,
                      reasons: widget.reasons,
                      selected: controller.reason,
                      theme: theme,
                      onSelected: controller.selectReason,
                    ),
                  BankDisputeStep.details => _DetailsStep(
                      title: widget.detailsTitle,
                      hint: widget.detailsHint,
                      controller: _description,
                      theme: theme,
                      onChanged: controller.setDescription,
                    ),
                  BankDisputeStep.evidence => _EvidenceStep(
                      title: widget.evidenceTitle,
                      addLabel: widget.addEvidenceLabel,
                      evidence: controller.evidence,
                      theme: theme,
                      onAdd: widget.onAddEvidence,
                      onRemove: controller.removeEvidence,
                    ),
                  BankDisputeStep.review => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reviewTitle,
                          style: BankTokens.headlineSmall
                              .copyWith(color: theme.onSurface),
                        ),
                        const SizedBox(height: BankTokens.space3),
                        BankTransactionListTile(
                          transaction: widget.transaction,
                        ),
                        const SizedBox(height: BankTokens.space3),
                        BankSummaryStack(
                          items: [
                            BankSummaryItem(
                              label: widget.reasonLabel,
                              value: controller.reason?.label ?? '',
                            ),
                            BankSummaryItem(
                              label: widget.descriptionLabel,
                              value: controller.description,
                            ),
                          ],
                        ),
                      ],
                    ),
                  BankDisputeStep.submitted => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BankStatusTracker(
                          stages: widget.submittedStages,
                        ),
                        const SizedBox(height: BankTokens.space3),
                        Text(
                          widget.submittedNote,
                          style: BankTokens.bodyMedium
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      ],
                    ),
                },
              ),
            ),
            if (step == BankDisputeStep.details ||
                step == BankDisputeStep.evidence ||
                step == BankDisputeStep.review)
              SizedBox(
                height: BankTokens.space12,
                child: FilledButton(
                  onPressed: switch (step) {
                    BankDisputeStep.details =>
                      controller.description.trim().length >= 10
                          ? controller.goToEvidence
                          : null,
                    BankDisputeStep.evidence => controller.goToReview,
                    _ => controller.submit,
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    disabledBackgroundColor: theme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    step == BankDisputeStep.review
                        ? widget.submitLabel
                        : widget.continueLabel,
                    style: BankTokens.labelLarge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReasonStep extends StatelessWidget {
  const _ReasonStep({
    required this.title,
    required this.reasons,
    required this.selected,
    required this.theme,
    required this.onSelected,
  });

  final String title;
  final List<BankDisputeReason> reasons;
  final BankDisputeReason? selected;
  final BankThemeData theme;
  final ValueChanged<BankDisputeReason> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space3),
        for (final reason in reasons)
          Semantics(
            button: true,
            selected: reason.code == selected?.code,
            label: reason.label,
            child: InkWell(
              onTap: () => onSelected(reason),
              borderRadius: theme.buttonRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: BankTokens.space2,
                ),
                child: Row(
                  children: [
                    Icon(
                      reason.code == selected?.code
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: reason.code == selected?.code
                          ? theme.primary
                          : theme.onSurfaceVariant,
                    ),
                    const SizedBox(width: BankTokens.space3),
                    Expanded(
                      child: Text(
                        reason.label,
                        style: BankTokens.bodyLarge
                            .copyWith(color: theme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.title,
    required this.hint,
    required this.controller,
    required this.theme,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final BankThemeData theme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space3),
        BankTextField(
          controller: controller,
          hint: hint,
          maxLines: 4,
          autofocus: true,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({
    required this.title,
    required this.addLabel,
    required this.evidence,
    required this.theme,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String addLabel;
  final List<BankDisputeEvidence> evidence;
  final BankThemeData theme;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space3),
        for (final item in evidence)
          Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: theme.chipRadius,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: BankTokens.space3,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: theme.primary,
                    ),
                    const SizedBox(width: BankTokens.space2),
                    Expanded(
                      child: Text(
                        item.name,
                        style: BankTokens.bodyMedium
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(item.id),
                      iconSize: 16,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (onAdd != null)
          OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: theme.buttonRadius,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(addLabel, style: BankTokens.labelLarge),
          ),
      ],
    );
  }
}
