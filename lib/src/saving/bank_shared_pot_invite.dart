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

  /// Heading above the member list. Defaults to 'Members'.
  final String title;

  /// Caption of the invite row. Defaults to 'Invite someone'.
  final String inviteLabel;

  /// Tooltip on each member's remove button. Defaults to
  /// 'Remove member'.
  final String removeMemberTooltip;

  /// Member row semantics template; `{name}` is substituted. Defaults
  /// to 'Member: {name}'.
  final String memberSemanticTemplate;

  /// Overrides the heading padding. Defaults to space4 by space3.
  final EdgeInsetsGeometry? padding;

  /// Overrides the invite row and initials accent. Defaults to the
  /// theme primary colour.
  final Color? accentColor;

  /// Merged over the computed heading style ([BankTokens.labelLarge]
  /// in onSurface).
  final TextStyle? titleStyle;

  /// Overrides the invite row glyph. Defaults to
  /// [Icons.person_add_alt_1_outlined].
  final IconData? inviteIcon;

  /// Overrides the remove button glyph. Defaults to [Icons.close].
  final IconData? removeIcon;

  const BankSharedPotInvite({
    required this.pot,
    required this.currentMembers,
    super.key,
    this.onInvite,
    this.onRemoveMember,
    this.title = 'Members',
    this.inviteLabel = 'Invite someone',
    this.removeMemberTooltip = 'Remove member',
    this.memberSemanticTemplate = 'Member: {name}',
    this.padding,
    this.accentColor,
    this.titleStyle,
    this.inviteIcon,
    this.removeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = accentColor ?? theme.primary;
    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: resolvedPadding,
          child: Text(
            title,
            style: BankTokens.labelLarge
                .copyWith(color: theme.onSurface)
                .merge(titleStyle),
          ),
        ),
        ...currentMembers.map(
          (member) => _MemberRow(
            member: member,
            onRemove: onRemoveMember != null
                ? () => onRemoveMember!(member.id)
                : null,
            theme: theme,
            accent: accent,
            removeTooltip: removeMemberTooltip,
            semanticTemplate: memberSemanticTemplate,
            removeIcon: removeIcon,
          ),
        ),
        if (onInvite != null)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Icon(
                inviteIcon ?? Icons.person_add_alt_1_outlined,
                color: accent,
              ),
            ),
            title: Text(
              inviteLabel,
              style: BankTokens.labelLarge.copyWith(color: accent),
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
  final Color accent;
  final String removeTooltip;
  final String semanticTemplate;
  final IconData? removeIcon;

  const _MemberRow({
    required this.member,
    required this.onRemove,
    required this.theme,
    required this.accent,
    required this.removeTooltip,
    required this.semanticTemplate,
    this.removeIcon,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticTemplate.replaceAll('{name}', member.name),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.surfaceVariant,
            backgroundImage: member.avatarUrl != null
                ? BankUiScope.imageProviderFor(context, member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: BankTokens.labelMedium.copyWith(color: accent),
                  )
                : null,
          ),
          title: Text(
            member.name,
            style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
          ),
          trailing: onRemove != null
              ? IconButton(
                  icon: Icon(
                    removeIcon ?? Icons.close,
                    color: theme.onSurfaceVariant,
                  ),
                  onPressed: onRemove,
                  tooltip: removeTooltip,
                )
              : null,
        ),
      );
}
