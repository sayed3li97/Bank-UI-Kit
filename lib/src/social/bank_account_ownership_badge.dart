import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../l10n/bank_strings.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The account-holder's relationship to an account.
enum BankOwnershipRole {
  /// Sole owner of the account.
  primary,

  /// Co-owner with equal rights.
  joint,

  /// Named beneficiary: no operating rights, so it reads as neutral rather
  /// than branded.
  beneficiary,
}

/// Small inline badge indicating account ownership role.
///
/// Built on [BankTintChip], so its height, padding, radius, glyph size, and
/// ink are the kit's one chip anatomy rather than a private set — a role badge
/// beside a price-change chip now lines up instead of nearly lining up.
class BankAccountOwnershipBadge extends StatelessWidget {
  /// The role this badge announces.
  final BankOwnershipRole role;

  /// Overrides the role's built-in label.
  final String? customLabel;

  /// Overrides the role glyph. Defaults to a per-role built-in icon.
  final IconData? customIcon;

  /// Overrides the badge tint. Defaults to a per-role theme colour washed at
  /// [BankTokens.alphaSoft].
  final Color? backgroundColor;

  /// Overrides the icon and label colour. Defaults per role, contrast-
  /// corrected against the badge fill.
  final Color? foregroundColor;

  /// Overrides the inner padding. Defaults to the
  /// [BankTintChip.horizontalPadding] contract.
  final EdgeInsetsGeometry? padding;

  /// Overrides the badge corner radius. Defaults to the theme chipRadius.
  final BorderRadius? radius;

  /// Merged over the computed label style ([BankTokens.caption]).
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

  static IconData _icon(BankOwnershipRole role) => switch (role) {
        BankOwnershipRole.primary => Icons.star_rounded,
        BankOwnershipRole.joint => Icons.people_rounded,
        BankOwnershipRole.beneficiary => Icons.person_outline_rounded,
      };

  /// The hue each role is tinted from.
  ///
  /// [BankOwnershipRole.joint] takes a hue from the identity palette seeded on
  /// the role name — a stable step off the brand hue — instead of the raw
  /// Material purple it used to hard-code, which belonged to no brand and
  /// dropped below AA on dark surfaces.
  static Color _tintFor(BankOwnershipRole role, BankThemeData theme) =>
      switch (role) {
        BankOwnershipRole.primary => theme.primary,
        BankOwnershipRole.joint => BankEmblem.tintFor(theme, 'joint'),
        BankOwnershipRole.beneficiary => theme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final strings = BankStrings.of(context);
    final label = customLabel ??
        switch (role) {
          BankOwnershipRole.primary => strings.ownershipPrimary,
          BankOwnershipRole.joint => strings.ownershipJoint,
          BankOwnershipRole.beneficiary => strings.ownershipBeneficiary,
        };

    return BankTintChip(
      label: label,
      color: _tintFor(role, theme),
      icon: customIcon ?? _icon(role),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      radius: radius,
      labelStyle: labelStyle,
      semanticLabel: semanticLabel ?? 'Account role: $label',
    );
  }
}
