import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

/// Data for the flagship product-suite demo: a fictional retail bank
/// ("Meridian") showing a full product catalogue and apply journeys.
///
/// Everything here is plain Dart, the shape a host app maps its backend
/// into before handing it to Bank UI Kit widgets. Rates are illustrative
/// and dated for realism.
abstract final class Flagship {
  static const String bankName = 'Meridian';
  static const String tagline = 'Banking that moves with you.';
  static const String ratesAsOf = 'as of 4 Jul 2026';

  // ---------------------------------------------------------------------------
  // Accounts the customer already holds (for Home + My products).
  // ---------------------------------------------------------------------------

  static final BankAccount current = BankAccount(
    id: 'm_current',
    name: 'Everyday',
    maskedNumber: '•••• 4291',
    balance: Money.fromDouble(8214.52, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.current,
    currencyCode: 'GBP',
    ibanOrAccountNumber: 'GB29 MERD 6016 1331 9268 19',
    sortCodeOrBic: '04-00-04',
  );

  static final BankAccount savings = BankAccount(
    id: 'm_savings',
    name: 'Reserve Savings',
    maskedNumber: '•••• 7732',
    balance: Money.fromDouble(15750.00, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.savings,
    currencyCode: 'GBP',
  );

  static List<BankAccount> get accounts => [current, savings];

  // ---------------------------------------------------------------------------
  // Product catalogue.
  // ---------------------------------------------------------------------------

  static const List<FlagshipCategory> categories = [
    FlagshipCategory(
      id: 'accounts',
      title: 'Accounts',
      subtitle: 'Everyday, savings, and more',
      icon: Icons.account_balance_wallet_outlined,
      count: 4,
    ),
    FlagshipCategory(
      id: 'cards',
      title: 'Cards',
      subtitle: 'Credit, debit, and secured',
      icon: Icons.credit_card_outlined,
      count: 5,
    ),
    FlagshipCategory(
      id: 'loans',
      title: 'Loans',
      subtitle: 'Auto, personal, and home equity',
      icon: Icons.directions_car_outlined,
      count: 4,
    ),
    FlagshipCategory(
      id: 'mortgages',
      title: 'Mortgages',
      subtitle: 'Buy, remortgage, or release equity',
      icon: Icons.home_outlined,
      count: 3,
    ),
    FlagshipCategory(
      id: 'invest',
      title: 'Invest',
      subtitle: 'Portfolios, funds, and pensions',
      icon: Icons.trending_up_outlined,
      count: 4,
    ),
    FlagshipCategory(
      id: 'insurance',
      title: 'Protect',
      subtitle: 'Life, home, travel, and auto',
      icon: Icons.shield_outlined,
      count: 4,
    ),
  ];

  /// The featured product on the catalogue root and the subject of the
  /// end-to-end apply journey.
  static const FlagshipProduct autoFinance = FlagshipProduct(
    id: 'auto_finance',
    category: 'loans',
    name: 'Auto Finance',
    tagline: 'Drive away sooner, from 5.9% APR.',
    rate: BankProductRate(
        value: '5.9%', label: 'from APR', caption: 'Representative'),
    features: [
      'Borrow 3,000 to 60,000 GBP over 1 to 7 years',
      'No fee for settling early',
      'Personalised rate with no impact to your credit score',
      'Decision in minutes',
    ],
    badges: [
      FlagshipBadge('Featured', BankProductBadgeTone.promo),
      FlagshipBadge('No early-settlement fee', BankProductBadgeTone.positive),
    ],
    monthlyExampleGbp: 432.10,
    representativeExample:
        'Representative example: borrowing 25,000 GBP over 60 months at '
        '6.4% APR (fixed), you would pay 60 monthly payments of 432.10 GBP. '
        'Total amount repayable 25,926 GBP. Total charge for credit 926 GBP.',
  );

  static const FlagshipProduct murabahaAuto = FlagshipProduct(
    id: 'murabaha_auto',
    category: 'loans',
    name: 'Auto Finance (Murabaha)',
    tagline: 'Shariah-compliant vehicle finance at a fixed profit rate.',
    rate: BankProductRate(
      value: '5.9%',
      label: 'Profit rate',
      caption: 'Fixed, Shariah-compliant',
    ),
    features: [
      'The bank buys the vehicle and sells it to you at cost plus a '
          'disclosed, fixed profit',
      'No interest (riba), fully Shariah-board approved',
      'Fixed monthly payments for the whole term',
      'Early settlement rebate (ibra) available',
    ],
    badges: [
      FlagshipBadge('Shariah', BankProductBadgeTone.shariah),
      FlagshipBadge('Fixed profit', BankProductBadgeTone.positive),
    ],
    monthlyExampleGbp: 441.20,
    representativeExample:
        'Cost-plus example: vehicle cost 25,000 GBP plus a fixed profit of '
        '1,472 GBP gives a total sale price of 26,472 GBP, paid over 60 '
        'fixed monthly payments of 441.20 GBP. No interest is charged.',
  );

  static const List<FlagshipProduct> loans = [
    autoFinance,
    FlagshipProduct(
      id: 'personal_loan',
      category: 'loans',
      name: 'Personal Loan',
      tagline: 'One fixed rate for anything from 1,000 to 35,000 GBP.',
      rate: BankProductRate(
          value: '6.2%', label: 'from APR', caption: 'Representative'),
      features: [
        'Fixed monthly payments',
        'Funds as soon as the same day',
        'No early-repayment charge',
      ],
      badges: [FlagshipBadge('Popular', BankProductBadgeTone.neutral)],
      monthlyExampleGbp: 149.20,
      representativeExample:
          'Representative 6.2% APR (fixed). Borrowing 10,000 GBP over 60 '
          'months at 5.9% p.a. (fixed), 60 payments of 192.90 GBP.',
    ),
    FlagshipProduct(
      id: 'heloc',
      category: 'loans',
      name: 'Home Equity Line',
      tagline: 'Draw on your home equity when you need it.',
      rate: BankProductRate(
          value: '7.4%', label: 'variable APR', caption: 'as of 4 Jul 2026'),
      features: [
        'Borrow up to 85% of your home value less your mortgage',
        'Interest only on what you draw',
        'Fixed-rate lock available on balances',
      ],
      badges: [FlagshipBadge('Secured', BankProductBadgeTone.neutral)],
      monthlyExampleGbp: 0,
      representativeExample:
          'Variable rate tracks Bank Rate plus a margin. Your home may be '
          'repossessed if you do not keep up repayments.',
    ),
  ];

  static const List<FlagshipProduct> deposits = [
    FlagshipProduct(
      id: 'reserve_saver',
      category: 'accounts',
      name: 'Reserve Saver',
      tagline: 'A variable rate that rewards your balance.',
      rate: BankProductRate(
          value: '4.60%', label: 'AER variable', caption: 'as of 4 Jul 2026'),
      features: [
        'No minimum balance, no monthly fee',
        'Instant access to your money',
        'Interest paid monthly',
      ],
      badges: [FlagshipBadge('No fee', BankProductBadgeTone.positive)],
      monthlyExampleGbp: 0,
      representativeExample: '',
    ),
    FlagshipProduct(
      id: 'fixed_saver',
      category: 'accounts',
      name: '12-Month Fixed Saver',
      tagline: 'Lock in a fixed rate for a set term.',
      rate: BankProductRate(
          value: '4.85%', label: 'AER fixed', caption: '12-month term'),
      features: [
        'Fixed rate guaranteed for 12 months',
        'From 1,000 GBP',
        'Choose what happens at maturity',
      ],
      badges: [FlagshipBadge('Fixed', BankProductBadgeTone.neutral)],
      monthlyExampleGbp: 0,
      representativeExample:
          'Deposit 20,000 GBP at 4.85% AER fixed for 12 months returns '
          '970 GBP interest at maturity. Early access is not permitted.',
    ),
  ];

  /// Products the customer already holds, for the My products screen.
  static const List<FlagshipHolding> holdings = [
    FlagshipHolding(
      name: 'Everyday',
      subtitle: 'Current account',
      valueGbp: 8214.52,
      icon: Icons.account_balance_wallet_outlined,
    ),
    FlagshipHolding(
      name: 'Reserve Savings',
      subtitle: '4.60% AER variable',
      valueGbp: 15750.00,
      icon: Icons.savings_outlined,
    ),
    FlagshipHolding(
      name: 'Platinum Rewards Card',
      subtitle: 'Balance 1,284.60 GBP of 6,000 GBP limit',
      valueGbp: -1284.60,
      icon: Icons.credit_card_outlined,
    ),
  ];
}

/// A catalogue category tile's data.
class FlagshipCategory {
  const FlagshipCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
}

/// A catalogue product's data, mapped onto [BankProductCard].
class FlagshipProduct {
  const FlagshipProduct({
    required this.id,
    required this.category,
    required this.name,
    required this.tagline,
    required this.rate,
    required this.features,
    required this.badges,
    required this.representativeExample,
    this.monthlyExampleGbp = 0,
  });

  final String id;
  final String category;
  final String name;
  final String tagline;
  final BankProductRate rate;
  final List<String> features;
  final List<FlagshipBadge> badges;
  final String representativeExample;
  final double monthlyExampleGbp;

  List<BankProductBadge> get productBadges => badges
      .map((b) => BankProductBadge(label: b.label, tone: b.tone))
      .toList();
}

/// A lightweight badge tuple (const-friendly).
class FlagshipBadge {
  const FlagshipBadge(this.label, this.tone);
  final String label;
  final BankProductBadgeTone tone;
}

/// A product the customer holds, for My products.
class FlagshipHolding {
  const FlagshipHolding({
    required this.name,
    required this.subtitle,
    required this.valueGbp,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final double valueGbp;
  final IconData icon;
}
