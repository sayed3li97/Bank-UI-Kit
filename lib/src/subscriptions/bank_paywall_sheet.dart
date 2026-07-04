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

  /// Overrides the sheet content padding. Defaults to space4 sides and
  /// bottom with a space6 top.
  final EdgeInsetsGeometry? padding;

  /// Overrides the sheet corner radius. Defaults to the theme sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet background color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the header icon tint and the fallback plan accent.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the plan-card shadow. Defaults to a soft black drop
  /// shadow; pass `const []` to flatten.
  final List<BoxShadow>? cardShadow;

  /// Glyph inside the circular header badge. Defaults to
  /// [Icons.star_rounded].
  final IconData? headerIcon;

  /// Merged over the headline style (BankTokens.headlineSmall in
  /// onSurface).
  final TextStyle? titleStyle;

  /// Merged over the description style (BankTokens.bodyMedium in
  /// onSurfaceVariant).
  final TextStyle? descriptionStyle;

  /// Headline text; every `{feature}` occurrence is replaced with
  /// [featureName]. Defaults to `'Upgrade to access {feature}'`.
  final String headlineTemplate;

  /// Label of the dismiss button. Defaults to `'Maybe later'`.
  final String dismissLabel;

  /// Label of the per-plan upgrade button. Defaults to `'Upgrade'`.
  final String upgradeLabel;

  /// Text shown instead of the button on the current plan. Defaults to
  /// `'Current plan'`.
  final String currentPlanLabel;

  /// Suffix rendered after each monthly price. Defaults to `'/mo'`.
  final String perMonthLabel;

  /// Slot rendered above the header icon. Hidden when null.
  final Widget? header;

  /// Slot rendered below the dismiss button. Hidden when null.
  final Widget? footer;

  /// Overrides the sheet semantics label. Defaults to
  /// `'Upgrade required to access <featureName>'`.
  final String? semanticLabel;

  const BankPaywallSheet({
    required this.featureName,
    required this.description,
    required this.plans,
    super.key,
    this.currentTierId,
    this.onUpgrade,
    this.onDismiss,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.cardShadow,
    this.headerIcon,
    this.titleStyle,
    this.descriptionStyle,
    this.headlineTemplate = 'Upgrade to access {feature}',
    this.dismissLabel = 'Maybe later',
    this.upgradeLabel = 'Upgrade',
    this.currentPlanLabel = 'Current plan',
    this.perMonthLabel = '/mo',
    this.header,
    this.footer,
    this.semanticLabel,
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
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    Color? backgroundColor,
    Color? accentColor,
    List<BoxShadow>? cardShadow,
    IconData? headerIcon,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    String headlineTemplate = 'Upgrade to access {feature}',
    String dismissLabel = 'Maybe later',
    String upgradeLabel = 'Upgrade',
    String currentPlanLabel = 'Current plan',
    String perMonthLabel = '/mo',
    Widget? header,
    Widget? footer,
    String? semanticLabel,
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
          padding: padding,
          radius: radius,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          cardShadow: cardShadow,
          headerIcon: headerIcon,
          titleStyle: titleStyle,
          descriptionStyle: descriptionStyle,
          headlineTemplate: headlineTemplate,
          dismissLabel: dismissLabel,
          upgradeLabel: upgradeLabel,
          currentPlanLabel: currentPlanLabel,
          perMonthLabel: perMonthLabel,
          header: header,
          footer: footer,
          semanticLabel: semanticLabel,
        ),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final accent = accentColor ?? bankTheme.primary;
    final resolvedPadding = padding ??
        const EdgeInsets.fromLTRB(
          BankTokens.space4,
          BankTokens.space6,
          BankTokens.space4,
          BankTokens.space4,
        );
    final headline = headlineTemplate.replaceAll('{feature}', featureName);

    return Semantics(
      label: semanticLabel ?? 'Upgrade required to access $featureName',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? bankTheme.surface,
          borderRadius: radius ?? bankTheme.sheetRadius,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: resolvedPadding,
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
                      borderRadius:
                          BorderRadius.circular(BankTokens.radiusFull),
                    ),
                  ),
                ),

                if (header != null) ...[
                  header!,
                  const SizedBox(height: BankTokens.space4),
                ],

                // Star icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      headerIcon ?? Icons.star_rounded,
                      size: 32,
                      color: accent,
                    ),
                  ),
                ),

                const SizedBox(height: BankTokens.space4),

                // Headline
                Text(
                  headline,
                  style: BankTokens.headlineSmall
                      .copyWith(color: bankTheme.onSurface)
                      .merge(titleStyle),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: BankTokens.space2),

                // Description
                Text(
                  description,
                  style: BankTokens.bodyMedium
                      .copyWith(color: bankTheme.onSurfaceVariant)
                      .merge(descriptionStyle),
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
                    fallbackAccent: accent,
                    shadow: cardShadow,
                    upgradeLabel: upgradeLabel,
                    currentPlanLabel: currentPlanLabel,
                    perMonthLabel: perMonthLabel,
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
                        fallbackAccent: accent,
                        shadow: cardShadow,
                        upgradeLabel: upgradeLabel,
                        currentPlanLabel: currentPlanLabel,
                        perMonthLabel: perMonthLabel,
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
                        dismissLabel,
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                if (footer != null) ...[
                  const SizedBox(height: BankTokens.space4),
                  footer!,
                ],
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
  final Color fallbackAccent;
  final List<BoxShadow>? shadow;
  final String upgradeLabel;
  final String currentPlanLabel;
  final String perMonthLabel;

  const _SinglePlanCard({
    required this.tier,
    required this.bankTheme,
    required this.scope,
    required this.isCurrent,
    required this.onUpgrade,
    required this.fallbackAccent,
    required this.shadow,
    required this.upgradeLabel,
    required this.currentPlanLabel,
    required this.perMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tier.accentColor ?? fallbackAccent;
    final formattedPrice = BankMoneyFormatter.format(
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
          color: isCurrent ? bankTheme.outline.withValues(alpha: 0.5) : accent,
          width: isCurrent ? 1 : 2,
        ),
        boxShadow: shadow ??
            [
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
                  text: perMonthLabel,
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
              final supported = f.tierSupport[tier.id];
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
                    upgradeLabel,
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
                currentPlanLabel,
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
