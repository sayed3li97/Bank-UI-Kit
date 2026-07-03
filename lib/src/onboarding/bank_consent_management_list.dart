import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/money_formatter.dart';
import '../states/bank_empty_state_view.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Lifecycle state of a data-sharing consent.
enum BankConsentState { active, expiringSoon, expired, revoked }

/// A granted open-banking / data-sharing consent.
class BankConsent {
  const BankConsent({
    required this.id,
    required this.granteeName,
    required this.scopes,
    required this.grantedAt,
    required this.state,
    this.granteeLogoUrl,
    this.expiresAt,
  });

  final String id;

  /// The third party holding access, e.g. `'Budgeting App X'`.
  final String granteeName;

  /// Human-readable scope descriptions, e.g. `'Account balances'`.
  final List<String> scopes;

  final DateTime grantedAt;
  final BankConsentState state;
  final String? granteeLogoUrl;
  final DateTime? expiresAt;
}

/// Granted data-sharing consents with revocation — the
/// ongoing-management counterpart to `BankConsentModal`'s one-shot
/// acceptance, covering the PSD2 / open-banking consent dashboard.
///
/// Each consent renders as a card with the grantee emblem, scope chips
/// (three visible, the rest behind an expander), grant/expiry line
/// (warning-tinted when expiring within 14 days), and a danger revoke
/// action behind a confirmation dialog. Revoked consents stay in the
/// list struck-through for audit visibility.
///
/// ```dart
/// BankConsentManagementList(
///   consents: consents,
///   onRevoke: (id) => api.revokeConsent(id),
/// )
/// ```
class BankConsentManagementList extends StatefulWidget {
  const BankConsentManagementList({
    required this.consents,
    required this.onRevoke,
    super.key,
    this.onLearnMore,
    this.emptyState,
    this.revokeLabel = 'Revoke access',
    this.revokeConfirmTitle = 'Revoke access?',
    this.revokeConfirmBody = 'This app immediately loses access to your data.',
    this.cancelLabel = 'Cancel',
    this.grantedPrefix = 'Granted',
    this.expiresPrefix = 'expires',
    this.revokedLabel = 'Revoked',
    this.expiredLabel = 'Expired',
    this.expiringSoonLabel = 'Expiring soon',
    this.activeLabel = 'Active',
    this.moreScopesSuffix = 'more',
    this.emptyTitle = 'No connected apps',
    this.emptySubtitle =
        'Apps you allow to access your account data appear here.',
  });

  final List<BankConsent> consents;

  /// Revokes on the backend; return `true` on success.
  final Future<bool> Function(String consentId) onRevoke;

  final VoidCallback? onLearnMore;

  /// Overrides the default `BankEmptyStateView`.
  final Widget? emptyState;

  final String revokeLabel;
  final String revokeConfirmTitle;
  final String revokeConfirmBody;
  final String cancelLabel;
  final String grantedPrefix;
  final String expiresPrefix;
  final String revokedLabel;
  final String expiredLabel;
  final String expiringSoonLabel;
  final String activeLabel;
  final String moreScopesSuffix;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  State<BankConsentManagementList> createState() =>
      _BankConsentManagementListState();
}

class _BankConsentManagementListState extends State<BankConsentManagementList> {
  final Set<String> _revoking = <String>{};
  final Set<String> _locallyRevoked = <String>{};
  final Set<String> _expandedScopes = <String>{};

  Future<void> _confirmRevoke(BankConsent consent) async {
    final theme = BankThemeData.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          widget.revokeConfirmTitle,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        content: Text(
          widget.revokeConfirmBody,
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(widget.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              widget.revokeLabel,
              style: const TextStyle(color: BankTokens.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revoking.add(consent.id));
    var succeeded = false;
    try {
      succeeded = await widget.onRevoke(consent.id);
    } on Object {
      succeeded = false;
    }
    if (!mounted) return;
    setState(() {
      _revoking.remove(consent.id);
      if (succeeded) _locallyRevoked.add(consent.id);
    });
  }

  BankConsentState _effectiveState(BankConsent consent) =>
      _locallyRevoked.contains(consent.id)
          ? BankConsentState.revoked
          : consent.state;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    if (widget.consents.isEmpty) {
      return widget.emptyState ??
          BankEmptyStateView(
            title: widget.emptyTitle,
            subtitle: widget.emptySubtitle,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final consent in widget.consents)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: _ConsentCard(
              consent: consent,
              state: _effectiveState(consent),
              revoking: _revoking.contains(consent.id),
              scopesExpanded: _expandedScopes.contains(consent.id),
              theme: theme,
              widget: widget,
              onToggleScopes: () => setState(() {
                if (!_expandedScopes.add(consent.id)) {
                  _expandedScopes.remove(consent.id);
                }
              }),
              onRevoke: () => _confirmRevoke(consent),
            ),
          ),
        if (widget.onLearnMore != null)
          TextButton(
            onPressed: widget.onLearnMore,
            child: Text(
              'How data sharing works',
              style: BankTokens.labelLarge.copyWith(color: theme.primary),
            ),
          ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.consent,
    required this.state,
    required this.revoking,
    required this.scopesExpanded,
    required this.theme,
    required this.widget,
    required this.onToggleScopes,
    required this.onRevoke,
  });

  final BankConsent consent;
  final BankConsentState state;
  final bool revoking;
  final bool scopesExpanded;
  final BankThemeData theme;
  final BankConsentManagementList widget;
  final VoidCallback onToggleScopes;
  final VoidCallback onRevoke;

  (String, Color) get _stateChip => switch (state) {
        BankConsentState.active => (widget.activeLabel, theme.positiveBalance),
        BankConsentState.expiringSoon => (
            widget.expiringSoonLabel,
            BankTokens.warning
          ),
        BankConsentState.expired => (
            widget.expiredLabel,
            theme.onSurfaceVariant
          ),
        BankConsentState.revoked => (
            widget.revokedLabel,
            theme.onSurfaceVariant
          ),
      };

  @override
  Widget build(BuildContext context) {
    final inactive =
        state == BankConsentState.revoked || state == BankConsentState.expired;
    final (chipLabel, chipColor) = _stateChip;

    final expiryText = consent.expiresAt == null
        ? null
        : '${widget.expiresPrefix} '
            '${BankDateFormatter.formatShort(consent.expiresAt!)}';
    final grantedText = '${widget.grantedPrefix} '
        '${BankDateFormatter.formatShort(consent.grantedAt)}';
    final grantedLine = [
      grantedText,
      if (expiryText != null) expiryText,
    ].join(' · ');

    final visibleScopes =
        scopesExpanded ? consent.scopes : consent.scopes.take(3).toList();
    final hiddenCount = consent.scopes.length - 3;

    return AnimatedSize(
      duration: BankTokens.durationBase,
      curve: BankTokens.curveStandard,
      alignment: Alignment.topCenter,
      child: Opacity(
        opacity: inactive ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: theme.cardRadius,
            border: Border.all(color: theme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BankEmblem(
                      imageUrl: consent.granteeLogoUrl,
                      initialsFrom: consent.granteeName,
                    ),
                    const SizedBox(width: BankTokens.space3),
                    Expanded(
                      child: Text(
                        consent.granteeName,
                        style: BankTokens.bodyLarge.copyWith(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w600,
                          decoration: state == BankConsentState.revoked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.12),
                        borderRadius: theme.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space2,
                          vertical: 2,
                        ),
                        child: Text(
                          chipLabel,
                          style:
                              BankTokens.labelSmall.copyWith(color: chipColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BankTokens.space3),
                Wrap(
                  spacing: BankTokens.space1,
                  runSpacing: BankTokens.space1,
                  children: [
                    for (final scope in visibleScopes)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: theme.chipRadius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BankTokens.space2,
                            vertical: 3,
                          ),
                          child: Text(
                            scope,
                            style: BankTokens.labelSmall
                                .copyWith(color: theme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    if (hiddenCount > 0 && !scopesExpanded)
                      InkWell(
                        onTap: onToggleScopes,
                        borderRadius: theme.chipRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BankTokens.space2,
                            vertical: 3,
                          ),
                          child: Text(
                            '+$hiddenCount ${widget.moreScopesSuffix}',
                            style: BankTokens.labelSmall
                                .copyWith(color: theme.primary),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: BankTokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grantedLine,
                        style: BankTokens.bodySmall.copyWith(
                          color: state == BankConsentState.expiringSoon
                              ? BankTokens.warning
                              : theme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (revoking)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!inactive)
                      TextButton(
                        onPressed: onRevoke,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: BankTokens.space2,
                          ),
                        ),
                        child: Text(
                          widget.revokeLabel,
                          style: BankTokens.labelLarge
                              .copyWith(color: BankTokens.danger),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
