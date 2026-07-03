import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
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
    this.sectionLabels = const {
      BankAlertSection.security: 'Security & fraud',
      BankAlertSection.payments: 'Payments',
      BankAlertSection.account: 'Account activity',
      BankAlertSection.marketing: 'Marketing',
    },
    this.channelLabels = const {
      BankAlertChannel.push: 'Push',
      BankAlertChannel.email: 'Email',
      BankAlertChannel.sms: 'SMS',
    },
    this.typeLabels = const {},
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

  final Map<BankAlertSection, String> sectionLabels;
  final Map<BankAlertChannel, String> channelLabels;

  /// Overrides the default English labels per notification type.
  final Map<BankNotificationType, String> typeLabels;

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

  static const Map<BankNotificationType, String> _defaultTypeLabels = {
    BankNotificationType.security: 'Security alerts',
    BankNotificationType.fraud: 'Fraud warnings',
    BankNotificationType.kycUpdate: 'Identity verification',
    BankNotificationType.payment: 'Payments',
    BankNotificationType.transfer: 'Transfers',
    BankNotificationType.cardActivity: 'Card activity',
    BankNotificationType.savingsGoal: 'Savings goals',
    BankNotificationType.priceAlert: 'Price alerts',
    BankNotificationType.system: 'Service updates',
    BankNotificationType.marketing: 'Offers & news',
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
    final channels = BankAlertChannel.values
        .where(availableChannels.contains)
        .toList(growable: false);

    final bySection = <BankAlertSection, List<BankAlertPreference>>{};
    for (final pref in preferences) {
      final section = _sectionOf[pref.type] ?? BankAlertSection.account;
      bySection.putIfAbsent(section, () => []).add(pref);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        for (final section in BankAlertSection.values)
          if (bySection.containsKey(section)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space5,
                BankTokens.space4,
                BankTokens.space2,
              ),
              child: Row(
                children: [
                  if (section == BankAlertSection.security) ...[
                    Icon(
                      BankIcons.shield,
                      size: 14,
                      color: theme.primary,
                    ),
                    const SizedBox(width: BankTokens.space1),
                  ],
                  Expanded(
                    child: Text(
                      sectionLabels[section] ?? '',
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ),
                  for (final channel in channels)
                    SizedBox(
                      width: 56,
                      child: Text(
                        channelLabels[channel] ?? '',
                        textAlign: TextAlign.center,
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant),
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
                    _defaultTypeLabels[pref.type] ??
                    pref.type.name,
                icon: _iconFor(pref.type),
                requiredLabel: requiredLabel,
                theme: theme,
                onChanged: onChanged,
              ),
          ],
      ],
    );
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
  });

  final BankAlertPreference pref;
  final List<BankAlertChannel> channels;
  final String label;
  final IconData icon;
  final String requiredLabel;
  final BankThemeData theme;
  final void Function(BankNotificationType, BankAlertChannel, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space1,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.onSurfaceVariant),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
                ),
                if (pref.locked)
                  Row(
                    children: [
                      Icon(
                        BankIcons.lock,
                        size: 11,
                        color: theme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        requiredLabel,
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          for (final channel in channels)
            SizedBox(
              width: 56,
              height: 44,
              child: Center(
                child: Semantics(
                  label: '$label, ${channel.name}',
                  child: Switch(
                    value: pref.locked || pref.valueFor(channel),
                    activeColor: theme.onPrimary,
                    activeTrackColor: theme.primary,
                    onChanged: pref.locked
                        ? null
                        : (value) => onChanged(pref.type, channel, value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
