import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  bool _showSuccess = false;

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
          Text('Skeleton Loaders', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          const BankSkeletonLoader(variant: BankSkeletonVariant.listTile),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(variant: BankSkeletonVariant.card),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(variant: BankSkeletonVariant.chart),
          const SizedBox(height: BankTokens.space2),
          const BankSkeletonLoader(variant: BankSkeletonVariant.text),
          const SizedBox(height: BankTokens.space4),
          Text('Empty State', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankEmptyStateView(
            title: 'No transactions yet',
            subtitle: 'Your transactions will appear here once you start spending.',
            actionLabel: 'Add money',
            onAction: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Error State', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankErrorStateView(
            title: 'Something went wrong',
            message: 'We could not load your data. Please try again.',
            onRetry: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Fraud Alert Banner', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankFraudAlertBanner(
            title: 'Suspicious activity detected',
            message: 'An unusual transaction was attempted on your account.',
            onDismiss: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Success Animation', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
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
                label: 'Payment complete',
                showConfetti: true,
              ),
            ),
          ],
          const SizedBox(height: BankTokens.space4),
          Text('Toast Banners', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          ...BankToastVariant.values.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: BankTokens.space2),
              child: BankToastBanner(
                message: '${v.name.replaceFirst(v.name[0], v.name[0].toUpperCase())} toast message',
                variant: v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
