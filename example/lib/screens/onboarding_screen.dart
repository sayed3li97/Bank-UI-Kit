import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  static const _steps = ['Identity', 'Documents', 'Selfie', 'Review'];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Onboarding / KYC'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Step Progress',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankStepProgressIndicator(
            totalSteps: _steps.length,
            currentStep: _step,
            labels: _steps,
            showLabels: true,
          ),
          const SizedBox(height: BankTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _step > 0 ? () => setState(() => _step--) : null,
                child: const Text('Back'),
              ),
              const SizedBox(width: BankTokens.space3),
              FilledButton(
                onPressed: _step < _steps.length - 1
                    ? () => setState(() => _step++)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Async Verification',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          const BankAsyncVerificationState(
            title: 'Verification Under Review',
            message:
                'We\'re reviewing your documents. This usually takes 1–2 business days.',
            estimatedTime: '1–2 business days',
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Consent Modal',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          FilledButton(
            onPressed: () => BankConsentModal.show(
              context,
              title: 'Terms & Conditions',
              termsContent:
                  'By using this service, you agree to our Terms of Service and Privacy Policy. '
                  'We collect your data to provide banking services. '
                  'Your data is protected by industry-standard encryption. '
                  'You may withdraw consent at any time by contacting support. '
                  '\n\nScroll to bottom to accept.',
              onAccept: () {},
              onDecline: () {},
            ),
            child: const Text('Show Consent Modal'),
          ),
        ],
      ),
    );
  }
}
