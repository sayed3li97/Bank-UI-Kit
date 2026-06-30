import 'package:flutter/material.dart';

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

  const BankSharedGoalProgressCard({
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    super.key,
    this.contributors = const [],
    this.illustration,
    this.onTap,
    this.onContribute,
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

    final contributorSuffix = contributors.length == 1 ? '' : 's';
    final contributorLabel =
        '${contributors.length} contributor$contributorSuffix';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      color: theme.surface,
      elevation: theme.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
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
                              .copyWith(color: theme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$savedStr of $targetStr',
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    percentStr,
                    style:
                        BankTokens.numeralSmall.copyWith(color: theme.primary),
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
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
              if (contributors.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space3),
                Row(
                  children: [
                    _ContributorStack(
                      contributors: contributors,
                      theme: theme,
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
                        child: const Text('Contribute'),
                      ),
                  ],
                ),
              ] else if (onContribute != null) ...[
                const SizedBox(height: BankTokens.space3),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onContribute,
                    child: const Text('Contribute'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  const _ContributorStack({
    required this.contributors,
    required this.theme,
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
                backgroundColor: theme.primary.withValues(alpha: 0.2),
                backgroundImage:
                    c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                child: c.avatarUrl == null
                    ? Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.primary, fontSize: 10),
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
