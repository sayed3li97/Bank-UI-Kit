import 'package:flutter/material.dart';

import '../../src/common/bank_surface_depth.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A card showing a shared savings goal with contributor avatars and progress.
class BankSharedGoalProgressCard extends StatelessWidget {
  final String goalName;
  final Money targetAmount;
  final Money savedAmount;
  final List<BankGoalContributor> contributors;
  final Widget? illustration;
  final VoidCallback? onTap;
  final VoidCallback? onContribute;

  /// Caption of the contribute action. Defaults to 'Contribute'.
  final String contributeLabel;

  /// Progress line template; `{saved}` and `{target}` are substituted.
  /// Defaults to '{saved} of {target}'.
  final String progressTemplate;

  /// Contributor-count noun when there is exactly one contributor.
  /// Defaults to 'contributor'.
  final String contributorSingularLabel;

  /// Contributor-count noun otherwise. Defaults to 'contributors'.
  final String contributorPluralLabel;

  /// Overrides the card content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the percent text, progress bar, and avatar accent.
  /// Defaults to the theme primary colour.
  final Color? accentColor;

  /// Legacy depth opt-out. The card renders the kit shadow language
  /// ([BankTokens.shadowCardFor] of the theme background brightness) instead
  /// of Material elevation; pass `0` — or use a theme whose `elevationLow`
  /// is `0`, such as Voltage — to flatten the card to hairline-only depth.
  final double? elevation;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Merged over the computed goal-name style ([BankTokens.labelLarge]
  /// in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed progress-line style
  /// ([BankTokens.bodySmall] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the computed percent style ([BankTokens.numeralSmall]).
  final TextStyle? amountStyle;

  /// When non-null, wraps the card in a [Semantics] node with this
  /// label. Defaults to no extra semantics node.
  final String? semanticLabel;

  const BankSharedGoalProgressCard({
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    super.key,
    this.contributors = const [],
    this.illustration,
    this.onTap,
    this.onContribute,
    this.contributeLabel = 'Contribute',
    this.progressTemplate = '{saved} of {target}',
    this.contributorSingularLabel = 'contributor',
    this.contributorPluralLabel = 'contributors',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.elevation,
    this.shadow,
    this.border,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.semanticLabel,
  });

  double get _fraction {
    final target = targetAmount.amount.toDouble();
    if (target <= 0) return 0;
    return (savedAmount.amount.toDouble() / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final savedStr = BankMoneyFormatter.format(
      amount: savedAmount.amount,
      currencyCode: savedAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final targetStr = BankMoneyFormatter.format(
      amount: targetAmount.amount,
      currencyCode: targetAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final fraction = _fraction;
    final percentStr = '${(fraction * 100).toStringAsFixed(0)}%';

    final contributorNoun = contributors.length == 1
        ? contributorSingularLabel
        : contributorPluralLabel;
    final contributorLabel = '${contributors.length} $contributorNoun';

    final progressLine = progressTemplate
        .replaceAll('{saved}', savedStr)
        .replaceAll('{target}', targetStr);

    final resolvedRadius = radius ?? theme.cardRadius;
    final resolvedAccent = accentColor ?? theme.primary;
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);

    // One depth language for every card: token shadows resolved against the
    // theme background brightness, with the dark-surface hairline. Themes
    // that declare flat depth (elevationLow == 0, e.g. Voltage) — or an
    // explicit `elevation: 0` — keep hairline-only separation. The margin
    // preserves the footprint of the Material [Card] this replaces.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
      tier: (elevation ?? theme.elevationLow) <= 0
          ? BankSurfaceDepthTier.flat
          : BankSurfaceDepthTier.card,
    );

    final Widget card = Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        color: backgroundColor ?? theme.surface,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: resolvedRadius,
            child: Padding(
              padding: resolvedPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (illustration != null) ...[
                        SizedBox(width: 40, height: 40, child: illustration),
                        const SizedBox(width: BankTokens.space3),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalName,
                              style: BankTokens.labelLarge
                                  .copyWith(color: theme.onSurface)
                                  .merge(titleStyle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              progressLine,
                              style: BankTokens.bodySmall
                                  .copyWith(color: theme.onSurfaceVariant)
                                  .merge(subtitleStyle),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        percentStr,
                        style: BankTokens.numeralSmall
                            .copyWith(color: resolvedAccent)
                            .merge(amountStyle),
                      ),
                    ],
                  ),
                  const SizedBox(height: BankTokens.space3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: theme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(resolvedAccent),
                    ),
                  ),
                  if (contributors.isNotEmpty) ...[
                    const SizedBox(height: BankTokens.space3),
                    Row(
                      children: [
                        _ContributorStack(
                          contributors: contributors,
                          theme: theme,
                          accent: resolvedAccent,
                        ),
                        const SizedBox(width: BankTokens.space2),
                        Text(
                          contributorLabel,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (onContribute != null)
                          TextButton(
                            onPressed: onContribute,
                            child: Text(contributeLabel),
                          ),
                      ],
                    ),
                  ] else if (onContribute != null) ...[
                    const SizedBox(height: BankTokens.space3),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: onContribute,
                        child: Text(contributeLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, child: card);
  }
}

class BankGoalContributor {
  final String name;
  final String? avatarUrl;
  final Money? contributed;

  const BankGoalContributor({
    required this.name,
    this.avatarUrl,
    this.contributed,
  });
}

class _ContributorStack extends StatelessWidget {
  final List<BankGoalContributor> contributors;
  final BankThemeData theme;
  final Color accent;

  const _ContributorStack({
    required this.contributors,
    required this.theme,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const avatarRadius = 14.0;
    const overlap = 8.0;
    final count = contributors.length.clamp(0, 4);
    final width = avatarRadius * 2 + (count - 1) * (avatarRadius * 2 - overlap);

    return SizedBox(
      width: width,
      height: avatarRadius * 2,
      child: Stack(
        children: List.generate(count, (i) {
          final c = contributors[i];
          return Positioned(
            left: i * (avatarRadius * 2 - overlap),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: theme.surface,
              child: CircleAvatar(
                radius: avatarRadius - 1.5,
                backgroundColor: accent.withValues(alpha: 0.2),
                backgroundImage: c.avatarUrl != null
                    ? BankUiScope.imageProviderFor(context, c.avatarUrl!)
                    : null,
                child: c.avatarUrl == null
                    ? Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: BankTokens.labelSmall
                            .copyWith(color: accent, fontSize: 10),
                      )
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
