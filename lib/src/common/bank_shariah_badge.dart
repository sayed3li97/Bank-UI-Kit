import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Visual size tier for [BankShariahBadge].
enum BankShariahBadgeSize {
  /// 10 px icon, `labelSmall` text — suitable for list tiles and card corners.
  small,

  /// 12 px icon, `labelMedium` text — suitable for section headers and modals.
  medium,
}

/// A compact badge marking a financial product as Shariah compliant.
///
/// Renders a verified-check icon alongside a configurable [label], using the
/// theme's primary colour (or a custom [accentColor]) tinted at 8 % opacity
/// as the background.
///
/// ```dart
/// // Standard usage on an account card:
/// BankShariahBadge()
///
/// // Small variant with custom colour on a product tile:
/// BankShariahBadge(
///   size: BankShariahBadgeSize.small,
///   accentColor: BankHeritageTheme.gold,
/// )
/// ```
class BankShariahBadge extends StatelessWidget {
  const BankShariahBadge({
    super.key,
    this.label = 'Shariah Compliant',
    this.size = BankShariahBadgeSize.medium,
    this.accentColor,
  });

  /// Badge text. Defaults to `'Shariah Compliant'`.
  final String label;

  final BankShariahBadgeSize size;

  /// Overrides [BankThemeData.primary] as the icon and text colour.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final color = accentColor ?? theme.primary;
    final isSmall = size == BankShariahBadgeSize.small;

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? BankTokens.space2 : BankTokens.space3,
          vertical: isSmall ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: theme.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: isSmall ? 10 : 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: (isSmall ? BankTokens.labelSmall : BankTokens.labelMedium)
                  .copyWith(color: color, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
