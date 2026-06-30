import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

final _plans = [
  InstallmentPlan(
    termMonths: 3,
    monthlyAmount: Money(amount: Decimal.parse('166.67'), currencyCode: 'GBP'),
    totalAmount: Money(amount: Decimal.parse('500.00'), currencyCode: 'GBP'),
    isInterestFree: true,
  ),
  InstallmentPlan(
    termMonths: 6,
    monthlyAmount: Money(amount: Decimal.parse('87.50'), currencyCode: 'GBP'),
    totalAmount: Money(amount: Decimal.parse('525.00'), currencyCode: 'GBP'),
    isInterestFree: false,
    annualRate: 9.9,
  ),
  InstallmentPlan(
    termMonths: 12,
    monthlyAmount: Money(amount: Decimal.parse('46.50'), currencyCode: 'GBP'),
    totalAmount: Money(amount: Decimal.parse('558.00'), currencyCode: 'GBP'),
    isInterestFree: false,
    annualRate: 14.9,
  ),
];

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  InstallmentPlan? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Credit & BNPL'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Credit Limit Gauge',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankCreditLimitGauge(
              creditLimit: Money(
                  amount: Decimal.parse('5000.00'), currencyCode: 'GBP'),
              usedAmount: Money(
                  amount: Decimal.parse('3200.00'), currencyCode: 'GBP'),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Row(
            children: [
              Text('Flex Eligible Badge',
                  style:
                      BankTokens.labelLarge.copyWith(color: theme.onSurface)),
              const SizedBox(width: BankTokens.space3),
              const BankFlexEligibleBadge(),
            ],
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Installment Plan Selector',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankInstallmentPlanSelector(
            plans: _plans,
            selectedPlan: _selected,
            onPlanSelected: (p) => setState(() => _selected = p),
          ),
          if (_selected != null) ...[
            const SizedBox(height: BankTokens.space4),
            Text('Repayment Schedule',
                style:
                    BankTokens.labelLarge.copyWith(color: theme.onSurface)),
            const SizedBox(height: BankTokens.space3),
            BankRepaymentScheduleView(
              plan: _selected!,
              highlightMonthIndex: 0,
            ),
          ],
        ],
      ),
    );
  }
}
