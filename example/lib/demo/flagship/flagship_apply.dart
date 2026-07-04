import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:flutter/material.dart';

import 'flagship_data.dart';

/// The showpiece of the Meridian flagship demo: the end-to-end apply
/// journey for [Flagship.autoFinance].
///
/// A [BankApplicationController] drives seven steps (eligibility, customize,
/// offer, documents, disclosures, sign, decision). A
/// [BankStepProgressIndicator] tracks progress under the app bar, and each
/// step renders a real kit widget for its task.
///
/// The screenshot harness can jump straight to a rich mid-flow step via
/// [initialStep] (for example the offer step), so the flow reads well as a
/// single still frame.
class FlagshipApplyFlow extends StatefulWidget {
  const FlagshipApplyFlow({super.key, this.initialStep = 0});

  /// The step the flow opens on. Earlier steps are pre-marked complete so
  /// the progress indicator and back navigation stay coherent.
  final int initialStep;

  @override
  State<FlagshipApplyFlow> createState() => _FlagshipApplyFlowState();
}

class _FlagshipApplyFlowState extends State<FlagshipApplyFlow> {
  static const List<BankApplicationStep> _steps = [
    BankApplicationStep(id: 'eligibility', title: 'Eligibility'),
    BankApplicationStep(id: 'customize', title: 'Customize'),
    BankApplicationStep(id: 'offer', title: 'Your offer'),
    BankApplicationStep(id: 'documents', title: 'Documents'),
    BankApplicationStep(id: 'disclosures', title: 'Disclosures'),
    BankApplicationStep(id: 'sign', title: 'Sign'),
    BankApplicationStep(id: 'decision', title: 'Decision'),
  ];

  static const String _currency = 'GBP';
  static const String _reference = 'AF-7Q2K-4413';

  late final BankApplicationController _controller;

  // Local UI state carried across steps.
  bool _idCaptured = false;
  bool _incomeCaptured = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initialStep.clamp(0, _steps.length - 1);
    _controller = BankApplicationController(
      steps: _steps,
      initialIndex: start,
    )..addListener(_onControllerChanged);

    // Seed the state of every step the harness is skipping past so the flow
    // stays internally consistent when it opens mid-journey.
    for (var i = 0; i < start; i++) {
      final step = _steps[i];
      _controller
        ..setStepValid(step.id, true)
        ..markComplete(step.id);
    }
    if (start > 3) {
      _idCaptured = true;
      _incomeCaptured = true;
    }
    if (start == _steps.length - 1) {
      _controller.setStatus(BankApplicationStatus.approved);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _advance() {
    final id = _controller.currentStep.id;
    _controller
      ..setStepValid(id, true)
      ..markComplete(id);
    if (_controller.currentStep.id == 'sign') {
      _controller.setStatus(BankApplicationStatus.approved);
    }
    _controller.next();
  }

  void _onBack() {
    if (_controller.isFirstStep) {
      Navigator.of(context).maybePop();
    } else {
      _controller.back();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final isDecision = _controller.currentStep.id == 'decision';

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'Apply: Auto Finance',
        subtitle: 'Step ${_controller.currentIndex + 1} of ${_steps.length}'
            ' · ${_controller.currentStep.title}',
        leading: isDecision
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _onBack,
                tooltip: 'Back',
              ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space4,
                BankTokens.space4,
                BankTokens.space2,
              ),
              child: BankStepProgressIndicator(
                totalSteps: _steps.length,
                currentStep: _controller.currentIndex + 1,
              ),
            ),
            Expanded(child: _buildStepBody(theme)),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(BankThemeData theme) {
    switch (_controller.currentStep.id) {
      case 'eligibility':
        return _scroll(child: _buildEligibility());
      case 'customize':
        return _scroll(child: _buildCustomize(theme));
      case 'offer':
        return _scroll(child: _buildOffer());
      case 'documents':
        return _scroll(child: _buildDocuments(theme));
      case 'disclosures':
        return _buildDisclosures();
      case 'sign':
        return _scroll(child: _buildSign(theme));
      case 'decision':
        return _buildDecision(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _scroll({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BankTokens.space4,
        BankTokens.space2,
        BankTokens.space4,
        BankTokens.space6,
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Step bodies
  // ---------------------------------------------------------------------------

  Widget _buildEligibility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIntro(
          title: 'You are pre-qualified',
          body: 'Based on a soft check, here is what you could borrow. '
              'Checking will not affect your credit score.',
        ),
        const SizedBox(height: BankTokens.space4),
        BankEligibilityResultCard(
          outcome: BankEligibilityOutcome.likely,
          estimatedRate: '5.9% to 8.4%',
          maxAmount: Money.fromDouble(25000, _currency),
          rateCaption: 'Representative, subject to full application',
          reasons: const [
            'Add your annual income to refine your rate',
            'A longer term could lower your monthly payments',
          ],
          applyLabel: 'Continue to apply',
          onApply: _advance,
        ),
      ],
    );
  }

  Widget _buildCustomize(BankThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIntro(
          title: 'Tailor your finance',
          body: 'Move the sliders to see how your amount and term change your '
              'monthly payment.',
        ),
        const SizedBox(height: BankTokens.space4),
        BankLoanCalculatorCard(
          minAmount: Money.fromDouble(3000, _currency),
          maxAmount: Money.fromDouble(60000, _currency),
          minMonths: 12,
          maxMonths: 84,
          annualRate: 0.064,
          initialAmount: Money.fromDouble(25000, _currency),
          initialMonths: 60,
          onChanged: (amount, months) {
            _controller
              ..setField('amount', amount)
              ..setField('months', months);
          },
          onContinue: _advance,
          disclosureSlot: Text(
            Flagship.autoFinance.representativeExample,
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIntro(
          title: 'Your personalised offer',
          body: 'This is a firm offer. The figures below will not change when '
              'you accept.',
        ),
        const SizedBox(height: BankTokens.space4),
        BankOfferSummaryCard(
          payment: Money.fromDouble(432.10, _currency),
          amount: Money.fromDouble(25000, _currency),
          rate: '6.4%',
          term: '60 months',
          totalRepayable: Money.fromDouble(25926, _currency),
          totalInterest: Money.fromDouble(926, _currency),
          firmness: BankOfferFirmness.firm,
          fees: const [
            BankSummaryItem(label: 'Arrangement fee', value: 'None'),
            BankSummaryItem(label: 'Early settlement', value: 'No fee'),
          ],
          representativeExample: Flagship.autoFinance.representativeExample,
          onAccept: _advance,
          onAdjust: _controller.back,
        ),
      ],
    );
  }

  Widget _buildDocuments(BankThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIntro(
          title: 'Verify your identity',
          body: 'We need two documents to confirm who you are and check '
              'affordability.',
        ),
        const SizedBox(height: BankTokens.space4),
        _DocumentRow(
          theme: theme,
          icon: Icons.badge_outlined,
          title: 'Photo ID',
          subtitle: 'Passport or driving licence',
          actionLabel: 'Photograph ID',
          done: _idCaptured,
          onAction: () => setState(() => _idCaptured = true),
        ),
        const SizedBox(height: BankTokens.space3),
        _DocumentRow(
          theme: theme,
          icon: Icons.receipt_long_outlined,
          title: 'Proof of income',
          subtitle: 'Latest payslip or bank statement',
          actionLabel: 'Upload',
          done: _incomeCaptured,
          onAction: () => setState(() => _incomeCaptured = true),
        ),
        const SizedBox(height: BankTokens.space4),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 16, color: theme.onSurfaceVariant),
            const SizedBox(width: BankTokens.space2),
            Expanded(
              child: Text(
                'Your documents are encrypted and used only to assess this '
                'application.',
                style: BankTokens.bodySmall.copyWith(
                  color: theme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisclosures() {
    return BankDisclosureConsentSheet(
      showHandle: false,
      title: 'Review and agree',
      subtitle: 'Please read these before you sign.',
      continueLabel: 'Agree and continue',
      disclosures: [
        BankDisclosure(
          title: 'Representative example',
          body: Flagship.autoFinance.representativeExample,
          required: true,
        ),
        const BankDisclosure(
          title: 'Your right to cancel',
          body: 'You have 14 days from the day after the agreement is signed '
              'to withdraw. If you withdraw, you repay the amount borrowed '
              'plus any interest accrued, with no penalty.',
          required: true,
        ),
      ],
      consents: const [
        BankConsentItem(
          id: 'agreement',
          label: 'I agree to the credit agreement and its terms',
          required: true,
        ),
        BankConsentItem(
          id: 'marketing',
          label: 'Send me Meridian product news and offers',
        ),
      ],
      onChanged: (_) {},
      onAgree: _advance,
      footerText: 'Meridian Bank plc is authorised and regulated. Borrowing '
          'is subject to status and affordability.',
    );
  }

  Widget _buildSign(BankThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIntro(
          title: 'Sign your agreement',
          body: 'Draw your signature or type your full name to complete your '
              'application.',
        ),
        const SizedBox(height: BankTokens.space4),
        BankESignaturePad(
          title: 'Your signature',
          now: () => DateTime(2026, 7, 4, 10),
          onSigned: (_) => _advance(),
          footer: Text(
            'By signing you confirm the details are correct and you agree to '
            'the credit agreement.',
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecision(BankThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BankTokens.space6,
        BankTokens.space6,
        BankTokens.space6,
        BankTokens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BankSuccessAnimation(
              size: 96,
              color: theme.positiveBalance,
            ),
          ),
          const SizedBox(height: BankTokens.space6),
          Text(
            'Approved',
            textAlign: TextAlign.center,
            style: BankTokens.headlineLarge.copyWith(color: theme.onSurface),
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            'Your Auto Finance is ready. Congratulations, Alex.',
            textAlign: TextAlign.center,
            style: BankTokens.bodyLarge.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BankTokens.space6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: theme.cardRadius,
              boxShadow: BankTokens.shadowCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space4),
              child: BankSummaryStack(
                items: [
                  BankSummaryItem(
                    label: 'Amount',
                    money: Money.fromDouble(25000, _currency),
                  ),
                  const BankSummaryItem(
                    label: 'Monthly payment',
                    value: 'GBP 432.10',
                  ),
                  const BankSummaryItem(label: 'Term', value: '60 months'),
                  const BankSummaryItem(
                    label: 'Reference',
                    value: _reference,
                    copyable: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          _TimelineCard(theme: theme),
          const SizedBox(height: BankTokens.space6),
          SizedBox(
            height: BankTokens.space12,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
              ),
              child: Text('Done', style: BankTokens.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(BankThemeData theme) {
    // Only the documents step needs an explicit Back / Continue bar; every
    // other step carries its own primary call to action.
    if (_controller.currentStep.id != 'documents') {
      return const SizedBox.shrink();
    }
    final canContinue = _idCaptured && _incomeCaptured;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BankTokens.space4,
          BankTokens.space3,
          BankTokens.space4,
          BankTokens.space4,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _controller.back,
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(0, BankTokens.minTapTarget),
                  side: BorderSide(color: theme.outline),
                  foregroundColor: theme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
                child: Text('Back', style: BankTokens.labelLarge),
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: canContinue ? _advance : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  minimumSize: const Size(0, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
                child: Text('Continue', style: BankTokens.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _stepIntro({required String title, required String body}) {
    final theme = BankThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space2),
        Text(
          body,
          style: BankTokens.bodyMedium.copyWith(
            color: theme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Document checklist row
// ---------------------------------------------------------------------------

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.done,
    required this.onAction,
  });

  final BankThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool done;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: theme.chipRadius,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: theme.primary, size: 22),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BankTokens.bodyLarge.copyWith(
                      color: theme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: BankTokens.bodySmall.copyWith(
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            if (done)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.positiveBalance,
                    size: 20,
                  ),
                  const SizedBox(width: BankTokens.space1),
                  Text(
                    'Added',
                    style: BankTokens.labelMedium.copyWith(
                      color: theme.positiveBalance,
                    ),
                  ),
                ],
              )
            else
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: theme.primary),
                child: Text(actionLabel, style: BankTokens.labelLarge),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Funds timeline card (decision step)
// ---------------------------------------------------------------------------

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    const steps = <({String title, String detail, bool done})>[
      (title: 'Agreement signed', detail: 'Today, 10:00', done: true),
      (title: 'Funds released', detail: 'Today', done: true),
      (
        title: 'Money in your Everyday account',
        detail: 'By the next working day',
        done: false,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What happens next',
              style: BankTokens.labelLarge.copyWith(
                color: theme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      i == steps.length - 1 ? 0 : BankTokens.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      steps[i].done
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 20,
                      color: steps[i].done
                          ? theme.positiveBalance
                          : theme.onSurfaceVariant,
                    ),
                    const SizedBox(width: BankTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: BankTokens.bodyMedium.copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            steps[i].detail,
                            style: BankTokens.bodySmall.copyWith(
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
