import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Inline chip indicating a transaction is eligible for flexible installments.
class BankFlexEligibleBadge extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;

  /// Overrides the chip content padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: BankTokens.space2, vertical: 3)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the chip corner radius. Defaults to the theme chipRadius.
  final BorderRadius? radius;

  /// Accent driving the icon, text, tint, and border. Defaults to the
  /// theme primary.
  final Color? accentColor;

  /// Overrides the chip fill. Defaults to the accent at 12% opacity.
  final Color? backgroundColor;

  /// Overrides the chip border color. Defaults to the accent at 24%
  /// opacity.
  final Color? borderColor;

  /// Leading glyph. Defaults to `Icons.auto_awesome`.
  final IconData? icon;

  /// Size of the leading glyph. Defaults to 12.
  final double? iconSize;

  /// Merged over the label style (labelSmall in the accent color).
  final TextStyle? labelStyle;

  /// Overrides the semantics label. Defaults to the badge label.
  final String? semanticLabel;

  const BankFlexEligibleBadge({
    super.key,
    this.label,
    this.onTap,
    this.padding,
    this.radius,
    this.accentColor,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.iconSize,
    this.labelStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final badgeLabel = label ?? 'Flex eligible';
    final accent = accentColor ?? theme.primary;

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? badgeLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: BankTokens.space2,
                vertical: 3,
              ),
          decoration: BoxDecoration(
            color: backgroundColor ?? accent.withValues(alpha: 0.12),
            borderRadius: radius ?? theme.chipRadius,
            border: Border.all(
              color: borderColor ?? accent.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.auto_awesome,
                size: iconSize ?? 12,
                color: accent,
              ),
              const SizedBox(width: 4),
              Text(
                badgeLabel,
                style: BankTokens.labelSmall
                    .copyWith(color: accent)
                    .merge(labelStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
