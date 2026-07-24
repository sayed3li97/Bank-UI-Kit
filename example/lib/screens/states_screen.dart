import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  bool _showSuccess = false;

  /// Product copy per toast variant, instead of generated
  /// `enumName toast message` strings.
  static String _toastMessage(BankToastVariant variant) => switch (variant) {
        BankToastVariant.success => 'Transfer of £250.00 sent to Alice',
        BankToastVariant.error => 'Payment failed. Check your details.',
        BankToastVariant.info => 'Planned maintenance Sunday 02:00–04:00',
        BankToastVariant.warning => 'Your session expires in 2 minutes',
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('States & Feedback'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Skeleton Loaders',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          const BankSkeletonLoader(variant: BankSkeletonVariant.accountCard),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(
              variant: BankSkeletonVariant.transactionTile),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(variant: BankSkeletonVariant.potCard),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(variant: BankSkeletonVariant.generic),
          const SizedBox(height: BankTokens.space4),
          Text('Empty State',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankEmptyStateView(
            title: 'No transactions yet',
            subtitle:
                'Your transactions will appear here once you start spending.',
            actionLabel: 'Add money',
            onAction: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Error State',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankErrorStateView(
            title: 'Something went wrong',
            message: 'We could not load your data. Please try again.',
            onRetry: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Fraud Alert Banner',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankFraudAlertBanner(
            title: 'Suspicious activity detected',
            body: 'An unusual transaction was attempted on your account.',
            primaryActionLabel: 'Review activity',
            dismissLabel: 'Dismiss',
            onPrimaryAction: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Success Animation',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          FilledButton(
            onPressed: () => setState(() => _showSuccess = !_showSuccess),
            child: Text(_showSuccess ? 'Hide' : 'Show Success Animation'),
          ),
          if (_showSuccess) ...[
            const SizedBox(height: BankTokens.space3),
            const SizedBox(
              height: 120,
              child: BankSuccessAnimation(
                label: Text('Payment complete'),
                showConfetti: true,
              ),
            ),
          ],
          const SizedBox(height: BankTokens.space4),
          Text('Toast Banners',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ...BankToastVariant.values.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space2),
              child: BankToastBanner(
                message: _toastMessage(v),
                variant: v,
                isVisible: true,
                onDismiss: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
