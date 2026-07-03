import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Sample data — SAR-denominated accounts
// ---------------------------------------------------------------------------

abstract final class _HeritageSampleData {
  static final BankAccount current = BankAccount(
    id: 'h_current',
    name: 'Current Account',
    maskedNumber: '•••• 8812',
    balance: Money.fromDouble(58420.75, 'SAR'),
    status: BankAccountStatus.active,
    type: BankAccountType.current,
    currencyCode: 'SAR',
    ibanOrAccountNumber: 'SA44 2000 0001 2345 6789 1234',
    sortCodeOrBic: 'RJHISARI',
  );

  static final BankAccount savings = BankAccount(
    id: 'h_savings',
    name: 'Savings Account',
    maskedNumber: '•••• 3305',
    balance: Money.fromDouble(125000.00, 'SAR'),
    status: BankAccountStatus.active,
    type: BankAccountType.savings,
    currencyCode: 'SAR',
  );

  static final BankAccount investment = BankAccount(
    id: 'h_invest',
    name: 'Investment Account',
    maskedNumber: '•••• 6614',
    balance: Money.fromDouble(45320.00, 'SAR'),
    status: BankAccountStatus.active,
    type: BankAccountType.savings,
    currencyCode: 'SAR',
  );

  static final SavingsPot hajjPot = SavingsPot(
    id: 'pot_hajj',
    name: 'Hajj Fund',
    target: Money.fromDouble(20000, 'SAR'),
    current: Money.fromDouble(14500, 'SAR'),
    interestRate: 3.8,
    hasOwnAccountNumber: true,
    memberIds: const ['user_me'],
    targetDate: DateTime(2027, 4, 1),
    isRoundUpDestination: false,
  );

  static final SavingsPot educationPot = SavingsPot(
    id: 'pot_education',
    name: 'Education Fund',
    target: Money.fromDouble(50000, 'SAR'),
    current: Money.fromDouble(28200, 'SAR'),
    interestRate: 4.2,
    hasOwnAccountNumber: false,
    memberIds: const ['user_me', 'user_spouse'],
    isRoundUpDestination: false,
  );

  static final List<Transaction> transactions = [
    Transaction(
      id: 'h_txn_1',
      amount: Money.fromDouble(-850.00, 'SAR'),
      settledAt: DateTime(2026, 7, 1, 9, 15),
      status: TransactionStatus.cleared,
      merchantName: 'Carrefour',
      category: TransactionCategory.groceries,
      reference: 'Weekly groceries',
    ),
    Transaction(
      id: 'h_txn_2',
      amount: Money.fromDouble(-320.50, 'SAR'),
      settledAt: DateTime(2026, 6, 30, 13, 40),
      status: TransactionStatus.cleared,
      merchantName: 'Jarir Bookstore',
      category: TransactionCategory.shopping,
      reference: 'Books & stationery',
    ),
    Transaction(
      id: 'h_txn_3',
      amount: Money.fromDouble(18500.00, 'SAR'),
      settledAt: DateTime(2026, 6, 28, 9, 0),
      status: TransactionStatus.cleared,
      merchantName: 'Employer',
      category: TransactionCategory.income,
      reference: 'Salary — June 2026',
    ),
    Transaction(
      id: 'h_txn_4',
      amount: Money.fromDouble(-175.00, 'SAR'),
      settledAt: DateTime(2026, 6, 27, 19, 20),
      status: TransactionStatus.cleared,
      merchantName: 'Matam Al Arabiya',
      category: TransactionCategory.dining,
      reference: 'Family dinner',
    ),
    Transaction(
      id: 'h_txn_5',
      amount: Money.fromDouble(-60.00, 'SAR'),
      settledAt: DateTime(2026, 6, 27, 8, 5),
      status: TransactionStatus.pending,
      merchantName: 'SAPTCO',
      category: TransactionCategory.transport,
      reference: 'Bus pass',
    ),
  ];

  static List<BankSpendingCategory> spendingByCategory(
    BankThemeData theme,
  ) =>
      [
        BankSpendingCategory(
          category: TransactionCategory.groceries,
          amount: Money.fromDouble(4820.00, 'SAR'),
          color: theme.primary,
        ),
        BankSpendingCategory(
          category: TransactionCategory.dining,
          amount: Money.fromDouble(1940.00, 'SAR'),
          color: const Color(0xFFFF9F0A),
        ),
        BankSpendingCategory(
          category: TransactionCategory.shopping,
          amount: Money.fromDouble(3210.00, 'SAR'),
          color: BankHeritageTheme.gold,
        ),
        BankSpendingCategory(
          category: TransactionCategory.transport,
          amount: Money.fromDouble(860.00, 'SAR'),
          color: const Color(0xFF30D158),
        ),
        BankSpendingCategory(
          category: TransactionCategory.utilities,
          amount: Money.fromDouble(720.00, 'SAR'),
          color: const Color(0xFF5E5CE6),
        ),
      ];

  static final BankInsight insight = BankInsight(
    id: 'h_insight_1',
    title: 'You saved 12% more this month',
    body: 'Your savings rate reached 31% of income — '
        'well above the recommended 20%. Keep it up.',
    confidence: InsightConfidence.high,
    generatedAt: DateTime(2026, 7, 1),
    isDismissed: false,
    relatedCategory: TransactionCategory.income,
  );

  static final BankBudget diningBudget = BankBudget(
    id: 'b_dining',
    name: 'Dining',
    category: TransactionCategory.dining,
    limit: Money.fromDouble(2000, 'SAR'),
    spent: Money.fromDouble(1940, 'SAR'),
    periodStart: DateTime(2026, 7, 1),
    periodEnd: DateTime(2026, 7, 31),
  );
}

// ---------------------------------------------------------------------------
// Heritage Dashboard
// ---------------------------------------------------------------------------

/// Full-featured home dashboard demonstrating the Heritage preset.
///
/// Showcases the institutional green-and-gold design language together with the
/// new [BankAppBar], [BankBottomNavBar], [BankTextField], and
/// [BankShariahBadge] widgets.
class HeritageDashboard extends StatefulWidget {
  const HeritageDashboard({super.key});

  @override
  State<HeritageDashboard> createState() => _HeritageDashboardState();
}

class _HeritageDashboardState extends State<HeritageDashboard> {
  int _tab = 0;

  static const _navItems = <BankNavItem>[
    BankNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    BankNavItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
      label: 'Accounts',
    ),
    BankNavItem(icon: Icons.swap_horiz_rounded, label: 'Transfer'),
    BankNavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Insights',
    ),
    BankNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    Widget body;
    switch (_tab) {
      case 1:
        body = _AccountsTab(theme: theme);
      case 2:
        body = _TransferTab(theme: theme);
      case 3:
        body = _InsightsTab(theme: theme);
      case 4:
        body = _ProfileTab(theme: theme);
      default:
        body = _HomeTab(theme: theme);
    }

    return Scaffold(
      backgroundColor: theme.background,
      bottomNavigationBar: BankBottomNavBar(
        items: _navItems,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Home tab
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _HeroHeader(theme: theme),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: BankTokens.space6),
              _QuickActions(theme: theme),
              const SizedBox(height: BankTokens.space6),
              _VirtualCardSection(theme: theme),
              const SizedBox(height: BankTokens.space6),
              _SectionHeader(
                theme: theme,
                title: 'Goals',
                action: 'See all',
              ),
              const SizedBox(height: BankTokens.space3),
              BankSavingsPotCard(
                pot: _HeritageSampleData.hajjPot,
                onTap: () {},
                onAddMoney: () {},
              ),
              const SizedBox(height: BankTokens.space3),
              BankSavingsPotCard(
                pot: _HeritageSampleData.educationPot,
                onTap: () {},
                onAddMoney: () {},
              ),
              const SizedBox(height: BankTokens.space6),
              _SectionHeader(theme: theme, title: 'This month'),
              const SizedBox(height: BankTokens.space3),
              _SpendingCard(theme: theme),
              const SizedBox(height: BankTokens.space4),
              BankInsightCard(
                insight: _HeritageSampleData.insight,
                onAction: () {},
                actionLabel: 'View report',
                onDismiss: () {},
              ),
              const SizedBox(height: BankTokens.space6),
              _SectionHeader(
                theme: theme,
                title: 'Recent activity',
                action: 'See all',
              ),
              const SizedBox(height: BankTokens.space2),
              BankTransactionGroupHeader(date: DateTime(2026, 7, 1)),
              ..._HeritageSampleData.transactions.take(5).map(
                    (t) => BankTransactionListTile(
                      transaction: t,
                      onTap: () {},
                    ),
                  ),
              const SizedBox(height: BankTokens.space12),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    final total = _HeritageSampleData.current.balance +
        _HeritageSampleData.savings.balance +
        _HeritageSampleData.investment.balance;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.accentGradient,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          BankTokens.space5,
          MediaQuery.paddingOf(context).top + BankTokens.space5,
          BankTokens.space5,
          BankTokens.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GoldAvatar(),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning',
                        style: BankTokens.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        'Mohammed Al-Rashid',
                        style: BankTokens.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {},
                ),
                const SizedBox(width: BankTokens.space2),
                const BankPrivacyToggle(),
              ],
            ),
            const SizedBox(height: BankTokens.space6),
            Text(
              'TOTAL BALANCE',
              style: BankTokens.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1.4,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            BankBalanceText(
              money: total,
              size: BankBalanceSize.hero,
              style: BankTokens.numeralHero.copyWith(
                color: const Color(0xFFFDFBF6),
                fontFamily: theme.fontFamily,
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: BankHeritageTheme.gold,
                ),
                const SizedBox(width: BankTokens.space1),
                Text(
                  '+SAR 2,840 this month',
                  style: BankTokens.labelMedium
                      .copyWith(color: BankHeritageTheme.gold),
                ),
                const Spacer(),
                _ShariahPill(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BankHeritageTheme.gold.withValues(alpha: 0.25),
        border: Border.all(
          color: BankHeritageTheme.gold.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'MA',
        style: BankTokens.labelLarge.copyWith(
          color: BankHeritageTheme.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ShariahPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
        border: Border.all(
          color: BankHeritageTheme.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 10,
            color: BankHeritageTheme.gold,
          ),
          const SizedBox(width: 4),
          Text(
            'Shariah Compliant',
            style: BankTokens.labelSmall.copyWith(
              color: BankHeritageTheme.gold,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    const actions = <({IconData icon, String label})>[
      (icon: Icons.add_rounded, label: 'Top Up'),
      (icon: Icons.swap_horiz_rounded, label: 'Transfer'),
      (icon: Icons.qr_code_rounded, label: 'Pay'),
      (icon: Icons.more_horiz_rounded, label: 'More'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final a in actions)
          _QuickAction(icon: a.icon, label: a.label, theme: theme),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BankTokens.shadowCard,
          ),
          child: Icon(icon, color: theme.primary, size: 24),
        ),
        const SizedBox(height: BankTokens.space2 + 2),
        Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Virtual card
// ---------------------------------------------------------------------------

class _VirtualCardSection extends StatelessWidget {
  const _VirtualCardSection({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(theme: theme, title: 'My Card'),
        const SizedBox(height: BankTokens.space3),
        Center(
          child: BankVirtualCardWidget(
            account: _HeritageSampleData.current,
            cardholderName: 'MOHAMMED AL-RASHID',
            expiryDate: '09/29',
            surface: BankCardSurface.gradient,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Spending card
// ---------------------------------------------------------------------------

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: BankSpendingBreakdownChart(
          categories: _HeritageSampleData.spendingByCategory(theme),
          centerLabel: 'Spent',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accounts tab
// ---------------------------------------------------------------------------

class _AccountsTab extends StatelessWidget {
  const _AccountsTab({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'Accounts',
        subtitle: '3 active accounts',
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: theme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          BankAccountCard(
            account: _HeritageSampleData.current,
            onTap: () {},
          ),
          const SizedBox(height: BankTokens.space3),
          _LabelledAccountCard(
            account: _HeritageSampleData.savings,
            badge: const BankShariahBadge(
              size: BankShariahBadgeSize.small,
            ),
            profitRate: '4.2%',
            theme: theme,
          ),
          const SizedBox(height: BankTokens.space3),
          _LabelledAccountCard(
            account: _HeritageSampleData.investment,
            badge: BankShariahBadge(
              size: BankShariahBadgeSize.small,
              accentColor: BankHeritageTheme.gold,
              label: 'Sukuk Portfolio',
            ),
            profitRate: '6.1%',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LabelledAccountCard extends StatelessWidget {
  const _LabelledAccountCard({
    required this.account,
    required this.theme,
    this.badge,
    this.profitRate,
  });

  final BankAccount account;
  final BankThemeData theme;
  final Widget? badge;
  final String? profitRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (badge != null) badge!,
            const Spacer(),
            if (profitRate != null) ...[
              Icon(
                Icons.trending_up_rounded,
                size: 12,
                color: theme.positiveBalance,
              ),
              const SizedBox(width: 2),
              Text(
                '$profitRate profit rate',
                style: BankTokens.labelSmall
                    .copyWith(color: theme.positiveBalance),
              ),
            ],
          ],
        ),
        const SizedBox(height: BankTokens.space1),
        BankAccountCard(account: account, onTap: () {}),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transfer tab — showcases BankTextField
// ---------------------------------------------------------------------------

class _TransferTab extends StatelessWidget {
  const _TransferTab({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(title: 'New Transfer'),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          const SizedBox(height: BankTokens.space2),
          BankTextField(
            label: 'Recipient name',
            hint: 'Enter full name',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: theme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          BankTextField(
            label: 'IBAN',
            hint: 'SA00 0000 0000 0000 0000 0000',
            prefixIcon: Icon(
              Icons.account_balance_outlined,
              color: theme.onSurfaceVariant,
            ),
            helper: '24-character Saudi IBAN',
          ),
          const SizedBox(height: BankTokens.space4),
          BankTextField(
            label: 'Amount (SAR)',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icon(
              Icons.payments_outlined,
              color: theme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          BankTextField(
            label: 'Reference (optional)',
            hint: 'e.g. Rent payment',
            prefixIcon: Icon(
              Icons.notes_rounded,
              color: theme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BankTokens.space6),
          Row(
            children: [
              const BankShariahBadge(),
              const Spacer(),
              Text(
                'No fees apply',
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: BankTokens.space4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: BankTokens.labelLarge.copyWith(
                  color: theme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights tab
// ---------------------------------------------------------------------------

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(title: 'Insights'),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          const SizedBox(height: BankTokens.space2),
          _SpendingCard(theme: theme),
          const SizedBox(height: BankTokens.space4),
          BankInsightCard(
            insight: _HeritageSampleData.insight,
            onAction: () {},
            actionLabel: 'View details',
            onDismiss: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: theme.cardRadius,
              border: Border.all(color: theme.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space4),
              child: BankBudgetGaugeWidget(
                budget: _HeritageSampleData.diningBudget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile tab
// ---------------------------------------------------------------------------

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          const SizedBox(height: BankTokens.space4),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: theme.accentGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'MA',
                    style: BankTokens.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: BankTokens.space3),
                Text(
                  'Mohammed Al-Rashid',
                  style: BankTokens.headlineMedium.copyWith(
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: BankTokens.space2),
                const BankShariahBadge(label: 'Verified Customer'),
              ],
            ),
          ),
          const SizedBox(height: BankTokens.space6),
          _ProfileTile(
            icon: Icons.security_rounded,
            title: 'Security',
            subtitle: 'Biometrics, PIN, trusted devices',
            theme: theme,
          ),
          _ProfileTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English (عربي)',
            theme: theme,
          ),
          _ProfileTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage alerts and preferences',
            theme: theme,
          ),
          _ProfileTile(
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: '24/7 customer care',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BankTokens.space2),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: theme.chipRadius,
          ),
          child: Icon(icon, color: theme.primary, size: 20),
        ),
        title: Text(
          title,
          style: BankTokens.bodyMedium.copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.onSurfaceVariant,
        ),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.theme,
    required this.title,
    this.action,
  });

  final BankThemeData theme;
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: BankTokens.labelLarge.copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: BankTokens.labelMedium.copyWith(color: theme.primary),
          ),
      ],
    );
  }
}
