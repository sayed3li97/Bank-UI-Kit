import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

enum BankOwnershipRole { primary, joint, beneficiary }

/// Small inline badge indicating account ownership role.
class BankAccountOwnershipBadge extends StatelessWidget {
  final BankOwnershipRole role;
  final String? customLabel;

  const BankAccountOwnershipBadge({
    super.key,
    required this.role,
    this.customLabel,
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

    final (bgColor, fgColor) = switch (role) {
      BankOwnershipRole.primary => (
          theme.primary.withOpacity(0.12),
          theme.primary
        ),
      BankOwnershipRole.joint => (
          Colors.purple.withOpacity(0.12),
          Colors.purple
        ),
      BankOwnershipRole.beneficiary => (
          theme.outline.withOpacity(0.12),
          theme.onSurfaceVariant
        ),
    };

    return Semantics(
      label: 'Account role: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space2, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: theme.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(role), size: 12, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: BankTokens.labelSmall.copyWith(color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}
