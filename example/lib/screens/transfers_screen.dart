import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _beneficiaries = [
  BankBeneficiary(
    id: 'b1',
    name: 'Alice Johnson',
    maskedAccount: '•••• 5678',
    type: BeneficiaryType.bankTransfer,
    isVerified: true,
  ),
  BankBeneficiary(
    id: 'b2',
    name: 'Bob Smith',
    maskedAccount: '•••• 4321',
    type: BeneficiaryType.bankTransfer,
    isVerified: true,
  ),
];

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Transfers'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Amount Keypad',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankAmountKeypad(
            currencyCode: 'GBP',
            onAmountChanged: (_) {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Beneficiary Picker',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankBeneficiaryPicker(
            beneficiaries: _beneficiaries,
            onBeneficiarySelected: (_) {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Transfer Review',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankTransferReviewCard(
            amount: Money(amount: Decimal.parse('250.00'), currencyCode: 'GBP'),
            recipient: _beneficiaries.first,
            reference: 'Rent payment',
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Scheduled Transfer',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankScheduledTransferToggle(
            onScheduleChanged: (_) {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Payment Request',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPaymentRequestCard(
            requesterName: 'Alice Johnson',
            amount: Money(amount: Decimal.parse('35.00'), currencyCode: 'GBP'),
            note: 'Dinner last Tuesday',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            onAccept: () {},
            onDecline: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => BankTransactionPinSheet.show(
              context,
              onPinEntered: (_) async {},
            ),
            child: const Text('Enter PIN (sheet)'),
          ),
        ],
      ),
    );
  }
}
