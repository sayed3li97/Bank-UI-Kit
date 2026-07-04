import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import 'flagship_data.dart';

/// Servicing overview for the Meridian flagship demo: the products the
/// customer already holds, the status of their in-flight auto-finance
/// application, and a single relationship total.
///
/// Composed entirely from Bank UI Kit widgets so it inherits privacy,
/// RTL, and numeral-style handling for free. Relies on the ambient
/// [BankUiScope] and [BankThemeData] provided by the host app / harness,
/// matching the composition of the other polished demo screens.
class FlagshipMyProducts extends StatelessWidget {
  const FlagshipMyProducts({super.key});

  /// The credit card the customer holds, expressed as a [BankAccount] so it
  /// can render through [BankProductItemTile] with the credit-utilisation
  /// bar. Its figures mirror the matching entry in [Flagship.holdings].
  static final BankAccount _rewardsCard = BankAccount(
    id: 'm_card',
    name: 'Platinum Rewards Card',
    maskedNumber: '•••• 5567',
    balance: Money.fromDouble(-1284.60, 'GBP'),
    status: BankAccountStatus.active,
    type: BankAccountType.current,
    currencyCode: 'GBP',
  );

  static final Money _cardLimit = Money.fromDouble(6000, 'GBP');
  static final Money _cardOutstanding = Money.fromDouble(1284.60, 'GBP');

  /// Sum of the positive holdings: the customer's deposits with Meridian.
  Money get _totalRelationship {
    var total = Money.zero('GBP');
    for (final holding in Flagship.holdings) {
      if (holding.valueGbp > 0) {
        total += Money.fromDouble(holding.valueGbp, 'GBP');
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: BankAppBar(
        title: 'My products',
        subtitle: Flagship.bankName,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space4,
            BankTokens.space12,
          ),
          children: [
            _SectionHeader(theme: theme, title: 'Your products'),
            const SizedBox(height: BankTokens.space3),
            BankProductItemTile(
              account: Flagship.current,
              onTap: () {},
            ),
            const SizedBox(height: BankTokens.space2),
            BankProductItemTile(
              account: Flagship.savings,
              rateLabel: '4.60%',
              onTap: () {},
            ),
            const SizedBox(height: BankTokens.space2),
            BankProductItemTile(
              account: _rewardsCard,
              variantOverride: BankProductItemVariant.credit,
              creditLimit: _cardLimit,
              outstanding: _cardOutstanding,
              onTap: () {},
            ),
            const SizedBox(height: BankTokens.space8),
            _SectionHeader(theme: theme, title: 'Applications'),
            const SizedBox(height: BankTokens.space3),
            _ApplicationCard(theme: theme),
            const SizedBox(height: BankTokens.space8),
            _SectionHeader(theme: theme, title: 'Relationship summary'),
            const SizedBox(height: BankTokens.space3),
            _RelationshipCard(theme: theme, total: _totalRelationship),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Applications: in-flight auto-finance status
// ---------------------------------------------------------------------------

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingBadge(
                theme: theme,
                icon: Icons.directions_car_outlined,
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Flagship.autoFinance.name,
                      style: BankTokens.labelLarge.copyWith(
                        color: theme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref AF-7Q2K-4413 · 25,000 GBP',
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _StatusPill(theme: theme, label: 'Approved'),
            ],
          ),
          const SizedBox(height: BankTokens.space5),
          BankStatusTracker(
            currentIndex: 2,
            stages: [
              BankTrackerStage(
                title: 'Submitted',
                subtitle: 'Application received',
                timestamp: DateTime(2026, 7, 2, 9, 14),
              ),
              BankTrackerStage(
                title: 'Reviewing',
                subtitle: 'Affordability and identity checks',
                timestamp: DateTime(2026, 7, 2, 11, 30),
              ),
              BankTrackerStage(
                title: 'Approved',
                subtitle: 'Offer confirmed at 6.4% APR',
                timestamp: DateTime(2026, 7, 3, 16, 5),
              ),
              const BankTrackerStage(
                title: 'Funded',
                subtitle: 'Funds released to your dealer within '
                    '1 working day',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Relationship summary
// ---------------------------------------------------------------------------

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({required this.theme, required this.total});
  final BankThemeData theme;
  final Money total;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      theme: theme,
      child: BankSummaryStack(
        items: [
          BankSummaryItem(
            label: 'Everyday',
            money: Money.fromDouble(8214.52, 'GBP'),
          ),
          BankSummaryItem(
            label: 'Reserve Savings',
            money: Money.fromDouble(15750.00, 'GBP'),
          ),
          BankSummaryItem(
            label: 'Total relationship',
            money: total,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// A soft, bordered surface card matching the demo screens' card language.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.theme, required this.child});
  final BankThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: child,
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({required this.theme, required this.icon});
  final BankThemeData theme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: theme.chipRadius,
      ),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(icon, color: theme.primary, size: BankTokens.space5),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.theme, required this.label});
  final BankThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.positiveBalance.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 12, color: theme.positiveBalance),
          const SizedBox(width: 4),
          Text(
            label,
            style: BankTokens.labelSmall.copyWith(
              color: theme.positiveBalance,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.theme, required this.title});
  final BankThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: BankTokens.labelLarge.copyWith(
        color: theme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
