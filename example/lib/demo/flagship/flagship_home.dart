import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'flagship_data.dart';

/// Home dashboard for the flagship "Meridian" product-suite demo.
///
/// Composed entirely from Bank UI Kit widgets: a hero total position, the
/// customer's held accounts, quick actions, a pre-qualified offer, a
/// catalogue teaser, and a deposit-protection trust signal.
class FlagshipHome extends StatelessWidget {
  const FlagshipHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final total =
        Flagship.accounts.map((a) => a.balance).reduce((a, b) => a + b);
    final exploreCategories = Flagship.categories.take(4).toList();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: Flagship.bankName,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_none_rounded,
              color: theme.onSurface,
            ),
          ),
          const _AvatarButton(initials: 'AM'),
          const SizedBox(width: BankTokens.space2),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space5,
            BankTokens.space4,
            BankTokens.space12,
          ),
          children: [
            _Greeting(theme: theme),
            const SizedBox(height: BankTokens.space5),
            _TotalPosition(theme: theme, total: total),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'Accounts'),
            const SizedBox(height: BankTokens.space3),
            BankAccountCard(account: Flagship.current, onTap: () {}),
            const SizedBox(height: BankTokens.space3),
            BankAccountCard(account: Flagship.savings, onTap: () {}),
            const SizedBox(height: BankTokens.space6),
            BankQuickActionsGrid(
              actions: [
                BankQuickAction(
                  id: 'pay',
                  label: 'Pay',
                  icon: Icons.qr_code_rounded,
                  onTap: () {},
                ),
                BankQuickAction(
                  id: 'transfer',
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () {},
                ),
                BankQuickAction(
                  id: 'statements',
                  label: 'Statements',
                  icon: Icons.receipt_long_rounded,
                  onTap: () {},
                ),
                BankQuickAction(
                  id: 'support',
                  label: 'Support',
                  icon: Icons.headset_mic_outlined,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'Recommended for you'),
            const SizedBox(height: BankTokens.space3),
            BankEligibilityResultCard(
              outcome: BankEligibilityOutcome.likely,
              estimatedRate: '5.9% to 8.4%',
              maxAmount: Money.fromDouble(25000, 'GBP'),
              rateCaption: 'Representative, ${Flagship.ratesAsOf}',
              reasons: const [
                'Based on the accounts you already hold with us',
                'A soft check only, so your credit score is unaffected',
              ],
              applyLabel: 'Check your rate',
              onApply: () {},
            ),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(
              theme: theme,
              title: 'Explore products',
              action: 'See all products',
            ),
            const SizedBox(height: BankTokens.space3),
            _CategoryGrid(categories: exploreCategories),
            const SizedBox(height: BankTokens.space6),
            const BankMoneyProtectionBanner(
              schemeName: 'the Financial Services Compensation Scheme',
              detailText: 'Up to 85,000 GBP per person, per institution.',
              style: BankMoneyProtectionStyle.prominent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: theme.accentGradient,
          color: theme.accentGradient == null ? theme.primary : null,
        ),
        child: Text(
          initials,
          style: BankTokens.labelMedium.copyWith(
            color: theme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning',
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          'Alex Morgan',
          style: BankTokens.headlineSmall.copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TotalPosition extends StatelessWidget {
  const _TotalPosition({required this.theme, required this.total});

  final BankThemeData theme;
  final Money total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total position',
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        const SizedBox(height: BankTokens.space1),
        BankBalanceText(money: total, size: BankBalanceSize.hero),
        const SizedBox(height: BankTokens.space2),
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: theme.positiveBalance,
            ),
            const SizedBox(width: BankTokens.space1),
            Text(
              'Across ${Flagship.accounts.length} accounts',
              style: BankTokens.labelMedium.copyWith(
                color: theme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<FlagshipCategory> categories;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < categories.length; i += 2) {
      final left = categories[i];
      final right = i + 1 < categories.length ? categories[i + 1] : null;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: BankTokens.space3));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _CategoryTile(category: left)),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _CategoryTile(category: right),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final FlagshipCategory category;

  @override
  Widget build(BuildContext context) {
    return BankProductCategoryTile(
      icon: category.icon,
      title: category.title,
      subtitle: category.subtitle,
      count: category.count,
      onTap: () {},
    );
  }
}

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
