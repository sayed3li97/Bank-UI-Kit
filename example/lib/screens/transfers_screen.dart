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

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  String _amountText = '0';
  String? _selectedBeneficiaryId = 'b1';
  BankTransferTiming _timing = BankTransferTiming.instant;

  void _appendDigit(String digit) {
    setState(() {
      if (_amountText == '0') {
        _amountText = digit;
      } else {
        _amountText += digit;
      }
    });
  }

  void _deleteDigit() {
    setState(() {
      if (_amountText.length <= 1) {
        _amountText = '0';
      } else {
        _amountText = _amountText.substring(0, _amountText.length - 1);
      }
    });
  }

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
            amountText: _amountText,
            currencyCode: 'GBP',
            onDigit: _appendDigit,
            onDelete: _deleteDigit,
            onDecimalPoint: () {
              if (!_amountText.contains('.')) {
                setState(() => _amountText += '.');
              }
            },
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Beneficiary Picker',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankBeneficiaryPicker(
            beneficiaries: _beneficiaries,
            selectedId: _selectedBeneficiaryId,
            onSelected: (b) => setState(() => _selectedBeneficiaryId = b.id),
            onAddNew: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Transfer Review',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankTransferReviewCard(
            amount: Money(amount: Decimal.parse('250.00'), currencyCode: 'GBP'),
            beneficiary: _beneficiaries.first,
            fee: Money(amount: Decimal.parse('0.00'), currencyCode: 'GBP'),
            estimatedArrival: 'Instant',
            additionalInfo: const Text('Reference: Rent payment'),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Scheduled Transfer',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankScheduledTransferToggle(
            selected: _timing,
            onChanged: (t) => setState(() => _timing = t),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Payment Request',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPaymentRequestCard(
            requesterId: 'b1',
            requesterName: 'Alice Johnson',
            amount: Money(amount: Decimal.parse('35.00'), currencyCode: 'GBP'),
            note: 'Dinner last Tuesday',
            requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
            onAccept: () {},
            onDecline: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => BankTransactionPinSheet.show(
              context,
              onSubmit: (_) async => true,
            ),
            child: const Text('Enter PIN (sheet)'),
          ),
        ],
      ),
    );
  }
}
