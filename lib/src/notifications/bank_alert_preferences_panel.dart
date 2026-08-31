import 'package:flutter/material.dart';

import '../common/bank_control_theme.dart';
import '../common/bank_icon_spec.dart';
import '../l10n/bank_strings.dart';
import '../models/bank_notification.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Delivery channels a bank alert can use.
enum BankAlertChannel { push, email, sms }

/// Per-event alert preference row data.
class BankAlertPreference {
  const BankAlertPreference({
    required this.type,
    this.push = false,
    this.email = false,
    this.sms = false,
    this.locked = false,
  });

  final BankNotificationType type;
  final bool push;
  final bool email;
  final bool sms;

  /// Compliance alerts that cannot be disabled: switches render on and
  /// disabled with a lock icon.
  final bool locked;

  bool valueFor(BankAlertChannel channel) => switch (channel) {
        BankAlertChannel.push => push,
        BankAlertChannel.email => email,
        BankAlertChannel.sms => sms,
      };
}

/// Per-event, per-channel alert preference matrix for the notification
/// settings screen.
///
/// Rows group into Security & fraud / Payments / Account activity /
/// Marketing sections with the security section pinned first. Locked
/// (compliance) rows render their switches on and disabled. Changes fire
/// [onChanged] immediately: hosts debounce persistence.
///
/// ```dart
/// BankAlertPreferencesPanel(
///   preferences: prefs,
///   onChanged: (type, channel, enabled) =>
///       api.setAlertPref(type, channel, enabled),
/// )
/// ```
class BankAlertPreferencesPanel extends StatelessWidget {
  const BankAlertPreferencesPanel({
    required this.preferences,
    required this.onChanged,
    super.key,
    this.availableChannels = const {
      BankAlertChannel.push,
      BankAlertChannel.email,
    },
    this.header,
    this.requiredLabel = 'Required',
    this.sectionLabels = const {},
    this.channelLabels = const {},
    this.typeLabels = const {},
    this.footer,
    this.sectionHeaderPadding,
    this.rowPadding,
    this.accentColor,
    this.switchThumbColor,
    this.iconColor,
    this.sectionLabelStyle,
    this.channelLabelStyle,
    this.titleStyle,
    this.requiredLabelStyle,
    this.typeIcons = const {},
    this.securityIcon,
    this.lockIcon,
    this.channelColumnWidth,
    this.semanticLabel,
  });

  final List<BankAlertPreference> preferences;

  /// Fired immediately on every switch flip.
  final void Function(
    BankNotificationType type,
    BankAlertChannel channel,
    bool enabled,
  ) onChanged;

  /// Which channel columns to render.
  final Set<BankAlertChannel> availableChannels;

  /// Optional slot above the matrix.
  final Widget? header;

  /// Helper shown on locked rows.
  final String requiredLabel;

  /// Overrides section headings. Keys absent from the map fall back to the
  /// kit's own copy in the ambient language, so a host that renames one
  /// section keeps the rest translated.
  final Map<BankAlertSection, String> sectionLabels;

  /// Overrides channel column headings, with the same per-key fallback as
  /// [sectionLabels].
  final Map<BankAlertChannel, String> channelLabels;

  /// Overrides the default English labels per notification type.
  final Map<BankNotificationType, String> typeLabels;

  /// Optional slot below the matrix. Defaults to no footer.
  final Widget? footer;

  /// Overrides the section header padding. Defaults to
  /// `EdgeInsets.fromLTRB(space4, space5, space4, space2)`.
  final EdgeInsetsGeometry? sectionHeaderPadding;

  /// Overrides each preference row padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: space4, vertical: space1)`.
  final EdgeInsetsGeometry? rowPadding;

  /// Overrides the accent used for the security header icon and the switch
  /// active track. Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the switch thumb color when on. Defaults to the theme
  /// onPrimary.
  final Color? switchThumbColor;

  /// Overrides the per-row type icon and lock icon color. Defaults to the
  /// theme onSurfaceVariant.
  final Color? iconColor;

  /// Merged over the section label style
  /// (BankTokens.labelMedium in onSurfaceVariant).
  final TextStyle? sectionLabelStyle;

  /// Merged over the channel column header style
  /// (BankTokens.labelSmall in onSurfaceVariant).
  final TextStyle? channelLabelStyle;

  /// Merged over the row title style
  /// (BankTokens.bodyLarge in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the locked helper label style
  /// (BankTokens.labelSmall in onSurfaceVariant).
  final TextStyle? requiredLabelStyle;

  /// Overrides the per-type icon glyphs. Missing entries fall back to the
  /// built-in defaults.
  final Map<BankNotificationType, IconData> typeIcons;

  /// Overrides the security section header icon. Defaults to
  /// `BankIcons.shield`.
  final IconData? securityIcon;

  /// Overrides the locked row icon. Defaults to `BankIcons.lock`.
  final IconData? lockIcon;

  /// Overrides the width of each channel column. Defaults to `56`.
  final double? channelColumnWidth;

  /// When non-null, wraps the panel in a [Semantics] label. Defaults to no
  /// extra semantics node.
  final String? semanticLabel;

  static const Map<BankNotificationType, BankAlertSection> _sectionOf = {
    BankNotificationType.security: BankAlertSection.security,
    BankNotificationType.fraud: BankAlertSection.security,
    BankNotificationType.kycUpdate: BankAlertSection.security,
    BankNotificationType.payment: BankAlertSection.payments,
    BankNotificationType.transfer: BankAlertSection.payments,
    BankNotificationType.cardActivity: BankAlertSection.payments,
    BankNotificationType.savingsGoal: BankAlertSection.account,
    BankNotificationType.priceAlert: BankAlertSection.account,
    BankNotificationType.system: BankAlertSection.account,
    BankNotificationType.marketing: BankAlertSection.marketing,
  };

  /// The shipped heading for [section].
  static String _defaultSectionLabel(
    BankStrings strings,
    BankAlertSection section,
  ) =>
      switch (section) {
        BankAlertSection.security => strings.notifGroupSecurity,
        BankAlertSection.payments => strings.notifGroupPayments,
        BankAlertSection.account => strings.notifGroupAccount,
        BankAlertSection.marketing => strings.notifGroupMarketing,
      };

  /// The shipped heading for [channel].
  static String _defaultChannelLabel(
    BankStrings strings,
    BankAlertChannel channel,
  ) =>
      switch (channel) {
        BankAlertChannel.push => strings.notifChannelPush,
        BankAlertChannel.email => strings.notifChannelEmail,
        BankAlertChannel.sms => strings.notifChannelSms,
      };

  /// The shipped label for [type], used wherever [typeLabels] carries no
  /// entry of its own.
  ///
  /// Exhaustive over [BankNotificationType], so every row has a name
  /// without falling back to an enum identifier.
  static String _defaultTypeLabel(
    BankStrings strings,
    BankNotificationType type,
  ) =>
      switch (type) {
        BankNotificationType.security => strings.notifSecurityAlerts,
        BankNotificationType.fraud => strings.notifFraudWarnings,
        BankNotificationType.kycUpdate => strings.notifIdentityVerification,
        BankNotificationType.payment => strings.notifPayments,
        BankNotificationType.transfer => strings.notifTransfers,
        BankNotificationType.cardActivity => strings.notifCardActivity,
        BankNotificationType.savingsGoal => strings.notifSavingsGoals,
        BankNotificationType.priceAlert => strings.notifPriceAlerts,
        BankNotificationType.system => strings.notifServiceUpdates,
        BankNotificationType.marketing => strings.notifOffersAndNews,
      };

  static IconData _iconFor(BankNotificationType type) => switch (type) {
        BankNotificationType.security => BankIcons.shield,
        BankNotificationType.fraud => BankIcons.fraud,
        BankNotificationType.kycUpdate => Icons.badge_outlined,
        BankNotificationType.payment => BankIcons.send,
        BankNotificationType.transfer => BankIcons.transfer,
        BankNotificationType.cardActivity => BankIcons.card,
        BankNotificationType.savingsGoal => BankIcons.pot,
        BankNotificationType.priceAlert => BankIcons.trending,
        BankNotificationType.system => BankIcons.info,
        BankNotificationType.marketing => BankIcons.gift,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final strings = BankStrings.of(context);
    final channels = BankAlertChannel.values
        .where(availableChannels.contains)
        .toList(growable: false);

    final resolvedAccent = accentColor ?? theme.primary;
    final resolvedThumb = switchThumbColor ?? theme.onPrimary;
    final resolvedIconColor = iconColor ?? theme.onSurfaceVariant;
    final resolvedColumnWidth = channelColumnWidth ?? 56;
    final resolvedHeaderPadding = sectionHeaderPadding ??
        const EdgeInsets.fromLTRB(
          BankTokens.space4,
          BankTokens.space5,
          BankTokens.space4,
          BankTokens.space2,
        );

    final bySection = <BankAlertSection, List<BankAlertPreference>>{};
    for (final pref in preferences) {
      final section = _sectionOf[pref.type] ?? BankAlertSection.account;
      bySection.putIfAbsent(section, () => []).add(pref);
    }

    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        for (final section in BankAlertSection.values)
          if (bySection.containsKey(section)) ...[
            Padding(
              padding: resolvedHeaderPadding,
              child: Row(
                children: [
                  if (section == BankAlertSection.security) ...[
                    Icon(
                      securityIcon ?? BankIcons.shield,
                      size: 14,
                      color: resolvedAccent,
                    ),
                    const SizedBox(width: BankTokens.space1),
                  ],
                  Expanded(
                    child: Text(
                      sectionLabels[section] ??
                          _defaultSectionLabel(strings, section),
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(sectionLabelStyle),
                    ),
                  ),
                  for (final channel in channels)
                    SizedBox(
                      width: resolvedColumnWidth,
                      child: Text(
                        channelLabels[channel] ??
                            _defaultChannelLabel(strings, channel),
                        textAlign: TextAlign.center,
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(channelLabelStyle),
                      ),
                    ),
                ],
              ),
            ),
            for (final pref in bySection[section]!)
              _PreferenceRow(
                pref: pref,
                channels: channels,
                label: typeLabels[pref.type] ??
                    _defaultTypeLabel(strings, pref.type),
                icon: typeIcons[pref.type] ?? _iconFor(pref.type),
                requiredLabel: requiredLabel,
                theme: theme,
                onChanged: onChanged,
                padding: rowPadding,
                titleStyle: titleStyle,
                requiredLabelStyle: requiredLabelStyle,
                iconColor: resolvedIconColor,
                lockIcon: lockIcon ?? BankIcons.lock,
                trackColor: resolvedAccent,
                thumbColor: resolvedThumb,
                columnWidth: resolvedColumnWidth,
              ),
          ],
        if (footer != null) footer!,
      ],
    );

    if (semanticLabel == null) return panel;
    return Semantics(label: semanticLabel, child: panel);
  }
}

/// Grouping sections of a [BankAlertPreferencesPanel].
enum BankAlertSection { security, payments, account, marketing }

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.pref,
    required this.channels,
    required this.label,
    required this.icon,
    required this.requiredLabel,
    required this.theme,
    required this.onChanged,
    required this.iconColor,
    required this.lockIcon,
    required this.trackColor,
    required this.thumbColor,
    required this.columnWidth,
    this.padding,
    this.titleStyle,
    this.requiredLabelStyle,
  });

  final BankAlertPreference pref;
  final List<BankAlertChannel> channels;
  final String label;
  final IconData icon;
  final String requiredLabel;
  final BankThemeData theme;
  final void Function(BankNotificationType, BankAlertChannel, bool) onChanged;
  final Color iconColor;
  final IconData lockIcon;
  final Color trackColor;
  final Color thumbColor;
  final double columnWidth;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  final TextStyle? requiredLabelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space1,
          ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BankTokens.bodyLarge
                      .copyWith(color: theme.onSurface)
                      .merge(titleStyle),
                ),
                if (pref.locked)
                  Row(
                    children: [
                      Icon(
                        lockIcon,
                        size: 11,
                        color: iconColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        requiredLabel,
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(requiredLabelStyle),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          for (final channel in channels)
            SizedBox(
              width: columnWidth,
              height: 44,
              child: Center(
                child: Semantics(
                  label: '$label, ${channel.name}',
                  child: SwitchTheme(
                    data: BankControlTheme.switchTheme(
                      theme,
                      accent: trackColor,
                      onAccent: thumbColor,
                    ),
                    child: Switch(
                      value: pref.locked || pref.valueFor(channel),
                      onChanged: pref.locked
                          ? null
                          : (value) => onChanged(pref.type, channel, value),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
