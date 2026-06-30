import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import 'bank_plan_comparison_table.dart';

/// Upsell bottom sheet shown when a free-tier user attempts to access a
/// paid-only feature.
///
/// Present with [BankPaywallSheet.show] or push an instance via
/// [showModalBottomSheet] directly.
class BankPaywallSheet extends StatelessWidget {
  final String featureName;
  final String description;
  final List<BankPlanTier> plans;
  final String? currentTierId;
  final ValueChanged<BankPlanTier>? onUpgrade;
  final VoidCallback? onDismiss;

  const BankPaywallSheet({
    super.key,
    required this.featureName,
    required this.description,
    required this.plans,
    this.currentTierId,
    this.onUpgrade,
    this.onDismiss,
  });

  // ---------------------------------------------------------------------------
  // Convenience factory
  // ---------------------------------------------------------------------------

  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String description,
    required List<BankPlanTier> plans,
    String? currentTierId,
    ValueChanged<BankPlanTier>? onUpgrade,
    VoidCallback? onDismiss,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankPaywallSheet(
          featureName: featureName,
          description: description,
          plans: plans,
          currentTierId: currentTierId,
          onUpgrade: onUpgrade,
          onDismiss: onDismiss,
        ),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    return Semantics(
      label: 'Upgrade required to access $featureName',
      child: Container(
        decoration: BoxDecoration(
          color: bankTheme.surface,
          borderRadius: bankTheme.sheetRadius,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space4,
              BankTokens.space6,
              BankTokens.space4,
              BankTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: BankTokens.space6),
                    decoration: BoxDecoration(
                      color: bankTheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                    ),
                  ),
                ),

                // Star icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bankTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 32,
                      color: bankTheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: BankTokens.space4),

                // Headline
                Text(
                  'Upgrade to access $featureName',
                  style: BankTokens.headlineSmall.copyWith(
                    color: bankTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: BankTokens.space2),

                // Description
                Text(
                  description,
                  style: BankTokens.bodyMedium.copyWith(
                    color: bankTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: BankTokens.space6),

                // Plan cards
                if (plans.length == 1)
                  _SinglePlanCard(
                    tier: plans.first,
                    bankTheme: bankTheme,
                    scope: scope,
                    isCurrent: plans.first.id == currentTierId,
                    onUpgrade: onUpgrade,
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: plans.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: BankTokens.space3),
                      itemBuilder: (context, index) => _SinglePlanCard(
                        tier: plans[index],
                        bankTheme: bankTheme,
                        scope: scope,
                        isCurrent: plans[index].id == currentTierId,
                        onUpgrade: onUpgrade,
                      ),
                    ),
                  ),

                const SizedBox(height: BankTokens.space4),

                // "Maybe later" dismiss button
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Dismiss upgrade prompt',
                    child: TextButton(
                      onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        foregroundColor: bankTheme.onSurfaceVariant,
                      ),
                      child: Text(
                        'Maybe later',
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual plan card inside the sheet
// ---------------------------------------------------------------------------

class _SinglePlanCard extends StatelessWidget {
  final BankPlanTier tier;
  final BankThemeData bankTheme;
  final BankUiScopeData scope;
  final bool isCurrent;
  final ValueChanged<BankPlanTier>? onUpgrade;

  const _SinglePlanCard({
    required this.tier,
    required this.bankTheme,
    required this.scope,
    required this.isCurrent,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tier.accentColor ?? bankTheme.primary;
    final String formattedPrice = BankMoneyFormatter.format(
      amount: tier.monthlyPrice.amount,
      currencyCode: tier.monthlyPrice.currencyCode,
      numeralStyle: scope.numeralStyle,
      hideFraction: true,
    );

    return Container(
      width: 180,
      padding: const EdgeInsets.all(BankTokens.space4),
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: bankTheme.cardRadius,
        border: Border.all(
          color: isCurrent
              ? bankTheme.outline.withValues(alpha: 0.5)
              : accent,
          width: isCurrent ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tagline badge
          if (tier.tagline != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(BankTokens.radiusFull),
              ),
              child: Text(
                tier.tagline!,
                style: BankTokens.labelSmall.copyWith(
                  color: bankTheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: BankTokens.space2),
          ],

          // Tier name
          Text(
            tier.name,
            style: BankTokens.labelLarge.copyWith(color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: BankTokens.space1),

          // Price
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: formattedPrice,
                  style: bankTheme.numeralMedium.copyWith(
                    color: bankTheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: '/mo',
                  style: BankTokens.bodySmall.copyWith(
                    color: bankTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BankTokens.space2),

          // Top 3 features
          ...tier.features.take(3).map(
            (f) {
              final bool? supported = f.tierSupport[tier.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      supported == true
                          ? Icons.check
                          : supported == false
                              ? Icons.close
                              : Icons.horizontal_rule,
                      size: 14,
                      color: supported == true
                          ? BankTokens.success
                          : bankTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: BankTokens.space1),
                    Expanded(
                      child: Text(
                        f.label,
                        style: BankTokens.bodySmall.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Spacer(),

          // Upgrade button
          if (!isCurrent && onUpgrade != null)
            Semantics(
              button: true,
              label: 'Upgrade to ${tier.name}',
              child: SizedBox(
                width: double.infinity,
                height: BankTokens.minTapTarget,
                child: FilledButton(
                  onPressed: () => onUpgrade!(tier),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bankTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: bankTheme.buttonRadius,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Upgrade',
                    style: BankTokens.labelLarge.copyWith(
                      color: bankTheme.onPrimary,
                    ),
                  ),
                ),
              ),
            )
          else if (isCurrent)
            Container(
              alignment: Alignment.center,
              height: BankTokens.minTapTarget,
              child: Text(
                'Current plan',
                style: BankTokens.labelMedium.copyWith(
                  color: bankTheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
