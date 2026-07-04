import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:flutter/material.dart';

import 'sample_data.dart';

/// A polished neo-bank home dashboard composed entirely from
/// Bank UI Kit widgets. Used as the demo "full app" hero and as a
/// screenshot target across all three presets.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final total = SampleData.current.balance +
        SampleData.savings.balance +
        SampleData.joint.balance;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space12,
          ),
          children: [
            _Header(theme: theme),
            const SizedBox(height: BankTokens.space6),
            _TotalBalance(theme: theme, total: total),
            const SizedBox(height: BankTokens.space6),
            const _QuickActions(),
            const SizedBox(height: BankTokens.space6),
            Center(
              child: BankVirtualCardWidget(
                account: SampleData.current,
                cardholderName: 'ALEX MORGAN',
                expiryDate: '08/28',
              ),
            ),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'Accounts'),
            const SizedBox(height: BankTokens.space3),
            BankAccountCard(account: SampleData.savings, onTap: () {}),
            const SizedBox(height: BankTokens.space3),
            BankAccountCard(account: SampleData.joint, onTap: () {}),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'Goals'),
            const SizedBox(height: BankTokens.space3),
            BankSavingsPotCard(
              pot: SampleData.holidayPot,
              onTap: () {},
              onAddMoney: () {},
            ),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(theme: theme, title: 'This month'),
            const SizedBox(height: BankTokens.space3),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: theme.cardRadius,
                border: Border.all(color: theme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BankTokens.space4),
                child: BankSpendingBreakdownChart(
                  categories: SampleData.spendingByCategory(theme),
                  centerLabel: 'Spent',
                ),
              ),
            ),
            const SizedBox(height: BankTokens.space4),
            BankInsightCard(
              insight: SampleData.insight,
              onAction: () {},
              actionLabel: 'Set budget',
              onDismiss: () {},
            ),
            const SizedBox(height: BankTokens.space6),
            _SectionHeader(
              theme: theme,
              title: 'Recent activity',
              action: 'See all',
            ),
            const SizedBox(height: BankTokens.space2),
            BankTransactionGroupHeader(date: DateTime(2026, 6, 30)),
            ...SampleData.transactions.take(5).map(
                (t) => BankTransactionListTile(transaction: t, onTap: () {})),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: theme.accentGradient,
            color: theme.accentGradient == null ? theme.primary : null,
          ),
          child: Text(
            'AM',
            style: BankTokens.labelLarge.copyWith(
              color: theme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: BankTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
              Text(
                'Alex Morgan',
                style: BankTokens.bodyLarge.copyWith(
                  color: theme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const BankPrivacyToggle(),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_none_rounded, color: theme.onSurface),
        ),
      ],
    );
  }
}

class _TotalBalance extends StatelessWidget {
  const _TotalBalance({required this.theme, required this.total});

  final BankThemeData theme;
  final Money total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total balance',
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        const SizedBox(height: BankTokens.space1),
        BankBalanceText(money: total, size: BankBalanceSize.hero),
        const SizedBox(height: BankTokens.space2),
        Row(
          children: [
            Icon(Icons.trending_up_rounded,
                size: 16, color: theme.positiveBalance),
            const SizedBox(width: BankTokens.space1),
            Text(
              '+£412.18 this week',
              style:
                  BankTokens.labelMedium.copyWith(color: theme.positiveBalance),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = <({IconData icon, String label})>[
      (icon: Icons.add_rounded, label: 'Add'),
      (icon: Icons.swap_horiz_rounded, label: 'Transfer'),
      (icon: Icons.qr_code_rounded, label: 'Pay'),
      (icon: Icons.more_horiz_rounded, label: 'More'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final a in actions) _QuickAction(icon: a.icon, label: a.label),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: theme.buttonRadius,
          ),
          child: Icon(icon, color: theme.primary),
        ),
        const SizedBox(height: BankTokens.space2),
        Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
        ),
      ],
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
