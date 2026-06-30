import 'package:flutter/material.dart';

import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

/// Inline chip indicating a transaction is eligible for flexible installments.
class BankFlexEligibleBadge extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;

  const BankFlexEligibleBadge({
    super.key,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final badgeLabel = label ?? 'Flex eligible';

    return Semantics(
      button: onTap != null,
      label: badgeLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space2,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.12),
            borderRadius: theme.chipRadius,
            border: Border.all(
              color: theme.primary.withOpacity(0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: theme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                badgeLabel,
                style: BankTokens.labelSmall.copyWith(color: theme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
