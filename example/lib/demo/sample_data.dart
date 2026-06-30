import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Realistic, illustration-free sample data used by the demo "full app"
/// dashboard and the screenshot harness.
///
/// Everything here is plain Dart data — the same shape a host app would map
/// its backend responses into before handing them to Bank UI Kit widgets.
abstract final class SampleData {
  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  static final BankAccount current = BankAccount(
    id: 'acc_current',
    name: 'Everyday',
    maskedNumber: '•••• 4291',
    balance: Money.fromDouble(8214.52, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.current,
    currencyCode: 'GBP',
    ibanOrAccountNumber: 'GB29 NWBK 6016 1331 9268 19',
    sortCodeOrBic: '04-00-04',
  );

  static final BankAccount savings = BankAccount(
    id: 'acc_savings',
    name: 'Savings',
    maskedNumber: '•••• 7732',
    balance: Money.fromDouble(15750.00, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.savings,
    currencyCode: 'GBP',
  );

  static final BankAccount joint = BankAccount(
    id: 'acc_joint',
    name: 'Joint Account',
    maskedNumber: '•••• 1180',
    balance: Money.fromDouble(2340.18, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.joint,
    currencyCode: 'GBP',
    ownerIds: const ['user_me', 'user_sam'],
  );

  static final List<BankAccount> accounts = [current, savings, joint];

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  static final List<Transaction> transactions = [
    Transaction(
      id: 'txn_1',
      amount: Money.fromDouble(-4.85, 'GBP'),
      settledAt: DateTime(2026, 6, 30, 8, 12),
      status: TransactionStatus.cleared,
      merchantName: 'Pret A Manger',
      category: TransactionCategory.dining,
      reference: 'Flat white & croissant',
    ),
    Transaction(
      id: 'txn_2',
      amount: Money.fromDouble(-62.40, 'GBP'),
      settledAt: DateTime(2026, 6, 29, 18, 47),
      status: TransactionStatus.cleared,
      merchantName: 'Tesco',
      category: TransactionCategory.groceries,
      reference: 'Weekly shop',
    ),
    Transaction(
      id: 'txn_3',
      amount: Money.fromDouble(-11.99, 'GBP'),
      settledAt: DateTime(2026, 6, 29, 6, 0),
      status: TransactionStatus.cleared,
      merchantName: 'Spotify',
      category: TransactionCategory.subscription,
      reference: 'Premium',
    ),
    Transaction(
      id: 'txn_4',
      amount: Money.fromDouble(2750.00, 'GBP'),
      settledAt: DateTime(2026, 6, 28, 9, 0),
      status: TransactionStatus.cleared,
      merchantName: 'Acme Corp',
      category: TransactionCategory.income,
      reference: 'Salary — June',
    ),
    Transaction(
      id: 'txn_5',
      amount: Money.fromDouble(-2.80, 'GBP'),
      settledAt: DateTime(2026, 6, 28, 8, 35),
      status: TransactionStatus.pending,
      merchantName: 'Transport for London',
      category: TransactionCategory.transport,
      reference: 'Contactless — Zone 1',
    ),
    Transaction(
      id: 'txn_6',
      amount: Money.fromDouble(-39.00, 'GBP'),
      settledAt: DateTime(2026, 6, 27, 20, 15),
      status: TransactionStatus.cleared,
      merchantName: 'Uniqlo',
      category: TransactionCategory.shopping,
      reference: 'T-shirts',
      isFlexEligible: true,
    ),
    Transaction(
      id: 'txn_7',
      amount: Money.fromDouble(-18.50, 'GBP'),
      settledAt: DateTime(2026, 6, 27, 13, 5),
      status: TransactionStatus.cleared,
      merchantName: 'Dishoom',
      category: TransactionCategory.dining,
      reference: 'Lunch',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Savings pots
  // ---------------------------------------------------------------------------

  static final SavingsPot holidayPot = SavingsPot(
    id: 'pot_holiday',
    name: 'Japan 2026',
    target: Money.fromDouble(5000, 'GBP'),
    current: Money.fromDouble(3120, 'GBP'),
    interestRate: 4.1,
    hasOwnAccountNumber: true,
    memberIds: const ['user_me'],
    targetDate: DateTime(2026, 11, 1),
    isRoundUpDestination: true,
  );

  static final SavingsPot emergencyPot = SavingsPot(
    id: 'pot_emergency',
    name: 'Rainy Day',
    target: Money.fromDouble(10000, 'GBP'),
    current: Money.fromDouble(6500, 'GBP'),
    interestRate: 4.1,
    hasOwnAccountNumber: false,
    memberIds: const ['user_me'],
    isRoundUpDestination: false,
  );

  // ---------------------------------------------------------------------------
  // Spending breakdown
  // ---------------------------------------------------------------------------

  static List<BankSpendingCategory> spendingByCategory(BankThemeData theme) => [
        BankSpendingCategory(
          category: TransactionCategory.groceries,
          amount: Money.fromDouble(312.40, 'GBP'),
          color: theme.primary,
        ),
        BankSpendingCategory(
          category: TransactionCategory.dining,
          amount: Money.fromDouble(198.75, 'GBP'),
          color: const Color(0xFFFF9F0A),
        ),
        BankSpendingCategory(
          category: TransactionCategory.transport,
          amount: Money.fromDouble(96.20, 'GBP'),
          color: const Color(0xFF30D158),
        ),
        BankSpendingCategory(
          category: TransactionCategory.shopping,
          amount: Money.fromDouble(154.00, 'GBP'),
          color: const Color(0xFF5E5CE6),
        ),
        BankSpendingCategory(
          category: TransactionCategory.subscription,
          amount: Money.fromDouble(41.97, 'GBP'),
          color: const Color(0xFFFF375F),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Insight
  // ---------------------------------------------------------------------------

  static final BankInsight insight = BankInsight(
    id: 'insight_1',
    title: 'Dining is up 24% this month',
    body: 'You\'ve spent £199 on eating out — £38 more than your '
        '3-month average. Want to set a dining budget?',
    confidence: InsightConfidence.high,
    generatedAt: DateTime(2026, 6, 30),
    isDismissed: false,
    relatedCategory: TransactionCategory.dining,
  );

  // ---------------------------------------------------------------------------
  // Holdings (investing)
  // ---------------------------------------------------------------------------

  static final List<Holding> holdings = [
    Holding(
      assetId: 'aapl',
      symbol: 'AAPL',
      name: 'Apple Inc.',
      assetClass: AssetClass.equity,
      quantity: Decimal.parse('12'),
      currentValue: Money.fromDouble(2640.00, 'GBP'),
      gainLoss: Money.fromDouble(312.40, 'GBP'),
      gainLossPercent: 13.4,
    ),
    Holding(
      assetId: 'btc',
      symbol: 'BTC',
      name: 'Bitcoin',
      assetClass: AssetClass.crypto,
      quantity: Decimal.parse('0.15'),
      currentValue: Money.fromDouble(8900.00, 'GBP'),
      gainLoss: Money.fromDouble(-420.00, 'GBP'),
      gainLossPercent: -4.5,
    ),
  ];

  static final InstallmentPlan installmentPlan = InstallmentPlan(
    termMonths: 6,
    monthlyAmount: Money.fromDouble(42.50, 'GBP'),
    totalAmount: Money.fromDouble(255.00, 'GBP'),
    isInterestFree: true,
  );
}
