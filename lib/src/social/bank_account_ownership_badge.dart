import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

enum BankOwnershipRole { primary, joint, beneficiary }

/// Small inline badge indicating account ownership role.
class BankAccountOwnershipBadge extends StatelessWidget {
  final BankOwnershipRole role;
  final String? customLabel;

  /// Overrides the role glyph. Defaults to a per-role built-in icon.
  final IconData? customIcon;

  /// Overrides the badge tint. Defaults to a per-role theme colour.
  final Color? backgroundColor;

  /// Overrides the icon and label colour. Defaults per role.
  final Color? foregroundColor;

  /// Overrides the inner padding. Defaults to space2 by 3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the badge corner radius. Defaults to the theme chipRadius.
  final BorderRadius? radius;

  /// Merged over the computed label style ([BankTokens.labelSmall]).
  final TextStyle? labelStyle;

  /// Overrides the badge semantics. Defaults to 'Account role: {label}'.
  final String? semanticLabel;

  const BankAccountOwnershipBadge({
    required this.role,
    super.key,
    this.customLabel,
    this.customIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.radius,
    this.labelStyle,
    this.semanticLabel,
  });

  static String _defaultLabel(BankOwnershipRole role) => switch (role) {
        BankOwnershipRole.primary => 'Primary',
        BankOwnershipRole.joint => 'Joint',
        BankOwnershipRole.beneficiary => 'Beneficiary',
      };

  static IconData _icon(BankOwnershipRole role) => switch (role) {
        BankOwnershipRole.primary => Icons.star_rounded,
        BankOwnershipRole.joint => Icons.people_rounded,
        BankOwnershipRole.beneficiary => Icons.person_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final label = customLabel ?? _defaultLabel(role);

    final (defaultBg, defaultFg) = switch (role) {
      BankOwnershipRole.primary => (
          theme.primary.withValues(alpha: 0.12),
          theme.primary
        ),
      BankOwnershipRole.joint => (
          Colors.purple.withValues(alpha: 0.12),
          Colors.purple
        ),
      BankOwnershipRole.beneficiary => (
          theme.outline.withValues(alpha: 0.12),
          theme.onSurfaceVariant
        ),
    };

    final bgColor = backgroundColor ?? defaultBg;
    final fgColor = foregroundColor ?? defaultFg;
    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 3,
        );
    final resolvedRadius = radius ?? theme.chipRadius;

    return Semantics(
      label: semanticLabel ?? 'Account role: $label',
      child: Container(
        padding: resolvedPadding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: resolvedRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(customIcon ?? _icon(role), size: 12, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: BankTokens.labelSmall
                  .copyWith(color: fgColor)
                  .merge(labelStyle),
            ),
          ],
        ),
      ),
    );
  }
}
