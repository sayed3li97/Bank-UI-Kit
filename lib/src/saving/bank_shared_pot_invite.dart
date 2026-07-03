import 'package:flutter/material.dart';

import '../../src/models/savings_pot.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A member of a shared pot.
class BankPotMember {
  final String id;
  final String name;
  final String? avatarUrl;

  const BankPotMember({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

/// Invite another account holder to view or contribute to a pot.
class BankSharedPotInvite extends StatelessWidget {
  final SavingsPot pot;
  final List<BankPotMember> currentMembers;
  final VoidCallback? onInvite;
  final Future<void> Function(String memberId)? onRemoveMember;

  const BankSharedPotInvite({
    required this.pot,
    required this.currentMembers,
    super.key,
    this.onInvite,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Text(
            'Members',
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
          ),
        ),
        ...currentMembers.map(
          (member) => _MemberRow(
            member: member,
            onRemove: onRemoveMember != null
                ? () => onRemoveMember!(member.id)
                : null,
            theme: theme,
          ),
        ),
        if (onInvite != null)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primary.withValues(alpha: 0.12),
              child:
                  Icon(Icons.person_add_alt_1_outlined, color: theme.primary),
            ),
            title: Text(
              'Invite someone',
              style: BankTokens.labelLarge.copyWith(color: theme.primary),
            ),
            onTap: onInvite,
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final BankPotMember member;
  final VoidCallback? onRemove;
  final BankThemeData theme;

  const _MemberRow({
    required this.member,
    required this.onRemove,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Member: ${member.name}',
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.surfaceVariant,
            backgroundImage: member.avatarUrl != null
                ? BankUiScope.imageProviderFor(context, member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style:
                        BankTokens.labelMedium.copyWith(color: theme.primary),
                  )
                : null,
          ),
          title: Text(
            member.name,
            style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
          ),
          trailing: onRemove != null
              ? IconButton(
                  icon: Icon(Icons.close, color: theme.onSurfaceVariant),
                  onPressed: onRemove,
                  tooltip: 'Remove member',
                )
              : null,
        ),
      );
}
