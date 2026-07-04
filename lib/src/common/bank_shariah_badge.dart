import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Visual size tier for [BankShariahBadge].
enum BankShariahBadgeSize {
  /// 10 px icon, `labelSmall` text: suitable for list tiles and card corners.
  small,

  /// 12 px icon, `labelMedium` text: suitable for section headers and modals.
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
    this.padding,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.iconSize,
    this.labelStyle,
    this.semanticLabel,
  });

  /// Badge text. Defaults to `'Shariah Compliant'`.
  final String label;

  final BankShariahBadgeSize size;

  /// Overrides [BankThemeData.primary] as the icon and text colour.
  final Color? accentColor;

  /// Overrides the badge's inner padding. Defaults to a [size]-driven
  /// symmetric inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the badge corner radius. Defaults to
  /// [BankThemeData.chipRadius].
  final BorderRadius? radius;

  /// Overrides the badge fill. Defaults to the accent colour at 8 % opacity.
  final Color? backgroundColor;

  /// Overrides the badge outline colour. Defaults to the accent colour at
  /// 35 % opacity.
  final Color? borderColor;

  /// Overrides the leading glyph. Defaults to [Icons.verified_rounded].
  final IconData? icon;

  /// Overrides the icon size. Defaults to 10 (small) or 12 (medium).
  final double? iconSize;

  /// Merged over the computed label style ([BankTokens.labelSmall] or
  /// [BankTokens.labelMedium] in the accent colour).
  final TextStyle? labelStyle;

  /// Overrides the badge's semantics label. Defaults to [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final color = accentColor ?? theme.primary;
    final isSmall = size == BankShariahBadgeSize.small;

    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isSmall ? BankTokens.space2 : BankTokens.space3,
          vertical: isSmall ? 2 : 4,
        );

    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        padding: resolvedPadding,
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withValues(alpha: 0.08),
          border: Border.all(
            color: borderColor ?? color.withValues(alpha: 0.35),
          ),
          borderRadius: radius ?? theme.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.verified_rounded,
              size: iconSize ?? (isSmall ? 10 : 12),
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: (isSmall ? BankTokens.labelSmall : BankTokens.labelMedium)
                  .copyWith(color: color, letterSpacing: 0)
                  .merge(labelStyle),
            ),
          ],
        ),
      ),
    );
  }
}
