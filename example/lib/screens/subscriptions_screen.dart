import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final features = [
      const BankPlanFeature(
        label: 'Basic account',
        tierSupport: {'free': true, 'plus': true, 'premium': true},
      ),
      const BankPlanFeature(
        label: 'No FX fees',
        tierSupport: {'free': false, 'plus': true, 'premium': true},
      ),
      const BankPlanFeature(
        label: 'Priority support',
        tierSupport: {'free': false, 'plus': true, 'premium': true},
      ),
      const BankPlanFeature(
        label: 'Metal card',
        tierSupport: {'free': false, 'plus': false, 'premium': true},
      ),
    ];

    final tiers = [
      BankPlanTier(
        id: 'free',
        name: 'Free',
        monthlyPrice: Money(amount: Decimal.zero, currencyCode: 'GBP'),
        features: features,
      ),
      BankPlanTier(
        id: 'plus',
        name: 'Plus',
        monthlyPrice: Money(amount: Decimal.parse('5.00'), currencyCode: 'GBP'),
        tagline: 'Most popular',
        features: features,
      ),
      BankPlanTier(
        id: 'premium',
        name: 'Premium',
        monthlyPrice:
            Money(amount: Decimal.parse('15.00'), currencyCode: 'GBP'),
        features: features,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('Plan Comparison',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPlanComparisonTable(
            tiers: tiers,
            highlightedTierId: 'plus',
            onSelectTier: (_) {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Perks Marketplace',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPerksMarketplaceCard(
            perk: const BankPerk(
              id: 'p1',
              partnerName: 'LoungeKey',
              title: 'Airport Lounges',
              description:
                  'Access 1,300+ lounges worldwide with your Premium card.',
            ),
            onActivate: () {},
          ),
          const SizedBox(height: BankTokens.space3),
          BankPerksMarketplaceCard(
            perk: const BankPerk(
              id: 'p2',
              partnerName: 'Visa Offers',
              title: '5% cashback on groceries',
              description:
                  'Earn cashback every time you shop at participating supermarkets.',
              discountLabel: '5% back',
              isActivated: true,
            ),
            onActivate: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Referral Card',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankReferralInviteCard(
            referralCode: 'ALEX2024',
            rewardDescription: 'Get £10 for every friend who joins',
            referralCount: 3,
            onShare: () {},
            onCopyCode: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => BankPaywallSheet.show(
              context,
              featureName: 'International transfers',
              description:
                  'Send money abroad instantly with no fees on Premium.',
              plans: tiers,
              currentTierId: 'free',
              onUpgrade: (_) {},
            ),
            child: const Text('Show Paywall'),
          ),
        ],
      ),
    );
  }
}
