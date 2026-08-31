import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/bank_sheet.dart';
import '../common/money_formatter.dart';
import '../l10n/bank_strings.dart';
import '../states/bank_empty_state_view.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Resolves a copy parameter whose default is the shipped English.
///
/// The card and the revoke dialog both need it, and every label on this
/// surface goes through it, so a chip never sits in one language beside a
/// button in another.
String _resolve(String value, String shipped, String translated) =>
    BankStrings.override(value, shipped) ?? translated;

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

/// Granted data-sharing consents with revocation: the
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
    this.revokeLabel = _kRevokeLabel,
    this.revokeConfirmTitle = _kRevokeConfirmTitle,
    this.revokeConfirmBody = _kRevokeConfirmBody,
    this.cancelLabel = _kCancelLabel,
    this.grantedPrefix = _kGrantedPrefix,
    this.expiresPrefix = _kExpiresPrefix,
    this.revokedLabel = _kRevokedLabel,
    this.expiredLabel = _kExpiredLabel,
    this.expiringSoonLabel = _kExpiringSoonLabel,
    this.activeLabel = _kActiveLabel,
    this.moreScopesSuffix = 'more',
    this.emptyTitle = 'No connected apps',
    this.emptySubtitle = _kEmptySubtitle,
    this.learnMoreLabel = 'How data sharing works',
    this.itemMargin,
    this.cardPadding,
    this.cardRadius,
    this.cardColor,
    this.cardShadow,
    this.titleStyle,
    this.subtitleStyle,
    this.animationDuration,
    this.animationCurve,
  });

  static const String _kRevokeLabel = 'Revoke access';
  static const String _kRevokeConfirmTitle = 'Revoke access?';
  static const String _kRevokeConfirmBody =
      'This app immediately loses access to your data.';
  static const String _kCancelLabel = 'Cancel';
  static const String _kGrantedPrefix = 'Granted';
  static const String _kExpiresPrefix = 'expires';
  static const String _kRevokedLabel = 'Revoked';
  static const String _kExpiredLabel = 'Expired';
  static const String _kExpiringSoonLabel = 'Expiring soon';
  static const String _kActiveLabel = 'Active';
  static const String _kEmptySubtitle =
      'Apps you allow to access your account data appear here.';

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

  /// Label of the [onLearnMore] button. Defaults to
  /// 'How data sharing works'.
  final String learnMoreLabel;

  /// Outer margin around each consent card. Defaults to
  /// [BankTokens.space4] horizontal and [BankTokens.space2] vertical.
  final EdgeInsetsGeometry? itemMargin;

  /// Inner padding of each consent card. Defaults to
  /// [BankTokens.space4] on all sides.
  final EdgeInsetsGeometry? cardPadding;

  /// Corner radius of each consent card. Defaults to the theme
  /// cardRadius.
  final BorderRadius? cardRadius;

  /// Fill of each consent card. Defaults to the theme surface.
  final Color? cardColor;

  /// Shadow of each consent card. Defaults to the card-tier shadow for the
  /// theme background brightness, re-inked with [BankThemeData.shadowTint]
  /// when the brand defines one;
  /// pass `const []` to flatten.
  final List<BoxShadow>? cardShadow;

  /// Merged over the computed grantee name style (bodyLarge).
  final TextStyle? titleStyle;

  /// Merged over the computed granted/expiry line style (bodySmall).
  final TextStyle? subtitleStyle;

  /// Duration of the scope expander resize. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Curve of the scope expander resize. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

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
    final strings = BankStrings.of(context);
    final title = _resolve(
      widget.revokeConfirmTitle,
      BankConsentManagementList._kRevokeConfirmTitle,
      strings.consentRevokeTitle,
    );
    final body = _resolve(
      widget.revokeConfirmBody,
      BankConsentManagementList._kRevokeConfirmBody,
      strings.consentRevokeBody,
    );
    final cancelLabel = _resolve(
      widget.cancelLabel,
      BankConsentManagementList._kCancelLabel,
      strings.actionCancel,
    );
    final revokeLabel = _resolve(
      widget.revokeLabel,
      BankConsentManagementList._kRevokeLabel,
      strings.consentRevoke,
    );
    final confirmed = await BankDialog.show<bool>(
      context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        content: Text(
          body,
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              revokeLabel,
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
    final strings = BankStrings.of(context);

    if (widget.consents.isEmpty) {
      // The subtitle arrives as a non-nullable String defaulted to the
      // shipped English; `override` keeps a host's wording and otherwise
      // falls back to the ambient language.
      return widget.emptyState ??
          BankEmptyStateView(
            title: widget.emptyTitle,
            subtitle: BankStrings.override(
                  widget.emptySubtitle,
                  BankConsentManagementList._kEmptySubtitle,
                ) ??
                strings.consentEmptyBody,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final consent in widget.consents)
          Padding(
            padding: widget.itemMargin ??
                const EdgeInsets.symmetric(
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
              widget.learnMoreLabel,
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

  /// Takes [strings] rather than reading them: it is a plain getter with
  /// no [BuildContext] of its own.
  (String, Color) _stateChip(BankStrings strings) => switch (state) {
        BankConsentState.active => (
            _resolve(
              widget.activeLabel,
              BankConsentManagementList._kActiveLabel,
              strings.statusActive,
            ),
            theme.positiveBalance
          ),
        BankConsentState.expiringSoon => (
            _resolve(
              widget.expiringSoonLabel,
              BankConsentManagementList._kExpiringSoonLabel,
              strings.consentExpiringSoon,
            ),
            BankTokens.warning
          ),
        BankConsentState.expired => (
            _resolve(
              widget.expiredLabel,
              BankConsentManagementList._kExpiredLabel,
              strings.consentExpired,
            ),
            theme.onSurfaceVariant
          ),
        BankConsentState.revoked => (
            _resolve(
              widget.revokedLabel,
              BankConsentManagementList._kRevokedLabel,
              strings.consentRevoked,
            ),
            theme.onSurfaceVariant
          ),
      };

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final inactive =
        state == BankConsentState.revoked || state == BankConsentState.expired;
    final (chipLabel, chipColor) = _stateChip(strings);

    final expiresPrefix = _resolve(
      widget.expiresPrefix,
      BankConsentManagementList._kExpiresPrefix,
      strings.consentExpiresPrefix,
    );
    final grantedPrefix = _resolve(
      widget.grantedPrefix,
      BankConsentManagementList._kGrantedPrefix,
      strings.consentGrantedPrefix,
    );
    final revokeLabel = _resolve(
      widget.revokeLabel,
      BankConsentManagementList._kRevokeLabel,
      strings.consentRevoke,
    );

    final expiryText = consent.expiresAt == null
        ? null
        : '$expiresPrefix '
            '${BankDateFormatter.formatShort(consent.expiresAt!)}';
    final grantedText = '$grantedPrefix '
        '${BankDateFormatter.formatShort(consent.grantedAt)}';
    final grantedLine = [
      grantedText,
      if (expiryText != null) expiryText,
    ].join(' · ');

    final visibleScopes =
        scopesExpanded ? consent.scopes : consent.scopes.take(3).toList();
    final hiddenCount = consent.scopes.length - 3;

    return AnimatedSize(
      duration: widget.animationDuration ?? BankTokens.durationBase,
      curve: widget.animationCurve ?? BankTokens.curveStandard,
      alignment: Alignment.topCenter,
      child: Opacity(
        opacity: inactive ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.cardColor ?? theme.surface,
            borderRadius: widget.cardRadius ?? theme.cardRadius,
            border: Border.all(color: theme.outline),
            boxShadow:
                widget.cardShadow ?? theme.shadowFor(BankElevationTier.card),
          ),
          child: Padding(
            padding:
                widget.cardPadding ?? const EdgeInsets.all(BankTokens.space4),
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
                        style: BankTokens.bodyLarge
                            .copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w600,
                              decoration: state == BankConsentState.revoked
                                  ? TextDecoration.lineThrough
                                  : null,
                            )
                            .merge(widget.titleStyle),
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
                        style: BankTokens.bodySmall
                            .copyWith(
                              color: state == BankConsentState.expiringSoon
                                  ? BankTokens.warning
                                  : theme.onSurfaceVariant,
                            )
                            .merge(widget.subtitleStyle),
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
                          revokeLabel,
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
