import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankCardControlsPanel
// ---------------------------------------------------------------------------

/// Panel of toggles and controls for managing a payment card.
///
/// Renders a scrollable [Column] of control rows organised into two groups:
/// 1. Toggle rows for freeze, online payments, contactless, and international.
/// 2. An optional spend-limit [Slider] when [onSpendLimitChanged] is provided.
/// 3. Action rows for PIN change and reporting the card lost or stolen.
///
/// All toggles use [BankThemeData.primary] as their active colour.
/// Each row meets the 44 × 44 px WCAG minimum tap-target requirement.
class BankCardControlsPanel extends StatelessWidget {
  final bool isFrozen;
  final bool isOnlinePaymentsEnabled;
  final bool isContactlessEnabled;
  final bool isInternationalEnabled;

  /// Current spend-limit value. `null` means no limit is set.
  final double? spendLimit;

  /// Maximum value for the spend-limit slider.
  final double maxSpendLimit;

  final ValueChanged<bool> onFreezeChanged;
  final ValueChanged<bool> onOnlinePaymentsChanged;
  final ValueChanged<bool> onContactlessChanged;
  final ValueChanged<bool> onInternationalChanged;

  /// When non-null, a spend-limit slider is shown below the toggles.
  final ValueChanged<double>? onSpendLimitChanged;

  /// Called when the user taps "Change PIN". No-op when `null`.
  final VoidCallback? onChangePinTap;

  /// Called when the user taps "Report Lost or Stolen". No-op when `null`.
  final VoidCallback? onReportLostOrStolen;

  /// Overrides the outer padding around the panel. Defaults to none.
  final EdgeInsetsGeometry? padding;

  /// Overrides the inner padding of every row. Defaults to each row's
  /// current symmetric [BankTokens] spacing.
  final EdgeInsetsGeometry? rowPadding;

  /// Overrides the active colour of switches and the slider. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the row label colour. Defaults to [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Merged over the computed row label style ([BankTokens.labelLarge]).
  final TextStyle? labelStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodySmall]).
  final TextStyle? subtitleStyle;

  /// Merged over the spend-limit value style ([BankTokens.bodyMedium]).
  final TextStyle? limitValueStyle;

  /// Icon of the freeze row. Defaults to [BankIcons.cardFreeze].
  final IconData freezeIcon;

  /// Icon of the online payments row. Defaults to [BankIcons.cardOnline].
  final IconData onlinePaymentsIcon;

  /// Icon of the contactless row. Defaults to [BankIcons.cardContactless].
  final IconData contactlessIcon;

  /// Icon of the international row. Defaults to
  /// [BankIcons.cardInternational].
  final IconData internationalIcon;

  /// Icon of the spend-limit row. Defaults to [BankIcons.cardLimit].
  final IconData spendLimitIcon;

  /// Icon of the change PIN action row. Defaults to [BankIcons.lock].
  final IconData changePinIcon;

  /// Icon of the report lost or stolen row. Defaults to
  /// [BankIcons.warning].
  final IconData reportLostOrStolenIcon;

  /// Trailing chevron of the action rows. Defaults to [BankIcons.forward].
  final IconData forwardIcon;

  /// Label of the freeze toggle. Defaults to `'Freeze Card'`.
  final String freezeLabel;

  /// Subtitle of the freeze toggle. Defaults to
  /// `'Temporarily block all transactions'`.
  final String freezeSubtitle;

  /// Label of the online payments toggle. Defaults to `'Online Payments'`.
  final String onlinePaymentsLabel;

  /// Subtitle of the online payments toggle. Defaults to
  /// `'Allow card-not-present purchases'`.
  final String onlinePaymentsSubtitle;

  /// Label of the contactless toggle. Defaults to `'Contactless Payments'`.
  final String contactlessLabel;

  /// Subtitle of the contactless toggle. Defaults to `'Tap-to-pay via NFC'`.
  final String contactlessSubtitle;

  /// Label of the international toggle. Defaults to
  /// `'International Payments'`.
  final String internationalLabel;

  /// Subtitle of the international toggle. Defaults to
  /// `'Use card outside home country'`.
  final String internationalSubtitle;

  /// Heading of the spend-limit row. Defaults to `'Spend Limit'`.
  final String spendLimitLabel;

  /// Text shown when no spend limit is set. Defaults to `'No limit'`.
  final String noLimitLabel;

  /// Overrides the spend-limit row semantics label. Defaults to
  /// `'Spend limit: <current value>'`.
  final String? spendLimitSemanticLabel;

  /// Label of the change PIN action row. Defaults to `'Change PIN'`.
  final String changePinLabel;

  /// Label of the report action row. Defaults to `'Report Lost or Stolen'`.
  final String reportLostOrStolenLabel;

  /// Semantics value announced for a toggle that is on. Defaults to
  /// `'enabled'`.
  final String enabledSemanticValue;

  /// Semantics value announced for a toggle that is off. Defaults to
  /// `'disabled'`.
  final String disabledSemanticValue;

  /// Semantics label wrapped around the whole panel. Defaults to none.
  final String? semanticLabel;

  const BankCardControlsPanel({
    required this.isFrozen,
    required this.isOnlinePaymentsEnabled,
    required this.isContactlessEnabled,
    required this.isInternationalEnabled,
    required this.onFreezeChanged,
    required this.onOnlinePaymentsChanged,
    required this.onContactlessChanged,
    required this.onInternationalChanged,
    super.key,
    this.spendLimit,
    this.maxSpendLimit = 10000,
    this.onSpendLimitChanged,
    this.onChangePinTap,
    this.onReportLostOrStolen,
    this.padding,
    this.rowPadding,
    this.accentColor,
    this.foregroundColor,
    this.labelStyle,
    this.subtitleStyle,
    this.limitValueStyle,
    this.freezeIcon = BankIcons.cardFreeze,
    this.onlinePaymentsIcon = BankIcons.cardOnline,
    this.contactlessIcon = BankIcons.cardContactless,
    this.internationalIcon = BankIcons.cardInternational,
    this.spendLimitIcon = BankIcons.cardLimit,
    this.changePinIcon = BankIcons.lock,
    this.reportLostOrStolenIcon = BankIcons.warning,
    this.forwardIcon = BankIcons.forward,
    this.freezeLabel = 'Freeze Card',
    this.freezeSubtitle = 'Temporarily block all transactions',
    this.onlinePaymentsLabel = 'Online Payments',
    this.onlinePaymentsSubtitle = 'Allow card-not-present purchases',
    this.contactlessLabel = 'Contactless Payments',
    this.contactlessSubtitle = 'Tap-to-pay via NFC',
    this.internationalLabel = 'International Payments',
    this.internationalSubtitle = 'Use card outside home country',
    this.spendLimitLabel = 'Spend Limit',
    this.noLimitLabel = 'No limit',
    this.spendLimitSemanticLabel,
    this.changePinLabel = 'Change PIN',
    this.reportLostOrStolenLabel = 'Report Lost or Stolen',
    this.enabledSemanticValue = 'enabled',
    this.disabledSemanticValue = 'disabled',
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final resolvedAccent = accentColor ?? bankTheme.primary;
    final resolvedForeground = foregroundColor ?? bankTheme.onSurface;

    Widget panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Toggle group ────────────────────────────────────────────────────
        _ControlRow(
          icon: freezeIcon,
          label: freezeLabel,
          subtitle: freezeSubtitle,
          value: isFrozen,
          onChanged: onFreezeChanged,
          bankTheme: bankTheme,
          labelColor: resolvedForeground,
          activeColor: resolvedAccent,
          enabledValue: enabledSemanticValue,
          disabledValue: disabledSemanticValue,
          iconColor: bankTheme.frozen,
          padding: rowPadding,
          labelStyle: labelStyle,
          subtitleStyle: subtitleStyle,
        ),
        _ControlRow(
          icon: onlinePaymentsIcon,
          label: onlinePaymentsLabel,
          subtitle: onlinePaymentsSubtitle,
          value: isOnlinePaymentsEnabled,
          onChanged: onOnlinePaymentsChanged,
          bankTheme: bankTheme,
          labelColor: resolvedForeground,
          activeColor: resolvedAccent,
          enabledValue: enabledSemanticValue,
          disabledValue: disabledSemanticValue,
          padding: rowPadding,
          labelStyle: labelStyle,
          subtitleStyle: subtitleStyle,
        ),
        _ControlRow(
          icon: contactlessIcon,
          label: contactlessLabel,
          subtitle: contactlessSubtitle,
          value: isContactlessEnabled,
          onChanged: onContactlessChanged,
          bankTheme: bankTheme,
          labelColor: resolvedForeground,
          activeColor: resolvedAccent,
          enabledValue: enabledSemanticValue,
          disabledValue: disabledSemanticValue,
          padding: rowPadding,
          labelStyle: labelStyle,
          subtitleStyle: subtitleStyle,
        ),
        _ControlRow(
          icon: internationalIcon,
          label: internationalLabel,
          subtitle: internationalSubtitle,
          value: isInternationalEnabled,
          onChanged: onInternationalChanged,
          bankTheme: bankTheme,
          labelColor: resolvedForeground,
          activeColor: resolvedAccent,
          enabledValue: enabledSemanticValue,
          disabledValue: disabledSemanticValue,
          padding: rowPadding,
          labelStyle: labelStyle,
          subtitleStyle: subtitleStyle,
        ),

        // ── Spend limit slider ───────────────────────────────────────────────
        if (onSpendLimitChanged != null) ...[
          const Divider(height: 1),
          _SpendLimitRow(
            currentLimit: spendLimit,
            maxLimit: maxSpendLimit,
            onChanged: onSpendLimitChanged!,
            bankTheme: bankTheme,
            icon: spendLimitIcon,
            label: spendLimitLabel,
            noLimitLabel: noLimitLabel,
            labelColor: resolvedForeground,
            activeColor: resolvedAccent,
            padding: rowPadding,
            semanticLabel: spendLimitSemanticLabel,
            labelStyle: labelStyle,
            valueStyle: limitValueStyle,
          ),
        ],

        // ── Divider ──────────────────────────────────────────────────────────
        const Divider(height: 1),

        // ── Action group ─────────────────────────────────────────────────────
        if (onChangePinTap != null)
          _ActionRow(
            label: changePinLabel,
            icon: changePinIcon,
            onTap: onChangePinTap!,
            bankTheme: bankTheme,
            forwardIcon: forwardIcon,
            labelColor: resolvedForeground,
            padding: rowPadding,
            labelStyle: labelStyle,
          ),

        if (onReportLostOrStolen != null)
          _ActionRow(
            label: reportLostOrStolenLabel,
            icon: reportLostOrStolenIcon,
            onTap: onReportLostOrStolen!,
            bankTheme: bankTheme,
            forwardIcon: forwardIcon,
            labelColor: BankTokens.danger,
            iconColor: BankTokens.danger,
            padding: rowPadding,
            labelStyle: labelStyle,
          ),
      ],
    );

    if (padding != null) {
      panel = Padding(padding: padding!, child: panel);
    }
    if (semanticLabel != null) {
      panel = Semantics(container: true, label: semanticLabel, child: panel);
    }
    return panel;
  }
}

// ---------------------------------------------------------------------------
// _ControlRow: icon + label/subtitle + switch
// ---------------------------------------------------------------------------

class _ControlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final BankThemeData bankTheme;
  final Color labelColor;
  final Color activeColor;
  final String enabledValue;
  final String disabledValue;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final TextStyle? subtitleStyle;

  const _ControlRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.bankTheme,
    required this.labelColor,
    required this.activeColor,
    required this.enabledValue,
    required this.disabledValue,
    this.iconColor,
    this.padding,
    this.labelStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        );
    final resolvedLabelStyle =
        BankTokens.labelLarge.copyWith(color: labelColor).merge(labelStyle);
    final resolvedSubtitleStyle = BankTokens.bodySmall
        .copyWith(color: bankTheme.onSurfaceVariant)
        .merge(subtitleStyle);

    return Semantics(
      label: label,
      value: value ? enabledValue : disabledValue,
      toggled: value,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: resolvedPadding,
              child: Row(
                children: [
                  // Icon
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(
                        icon,
                        size: 22,
                        color: iconColor ?? bankTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),

                  // Label + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: resolvedLabelStyle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: resolvedSubtitleStyle,
                        ),
                      ],
                    ),
                  ),

                  // Switch: min 44×44 via SizedBox wrapper
                  SizedBox(
                    height: BankTokens.minTapTarget,
                    child: Center(
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        activeColor: activeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SpendLimitRow: label + current value display + Slider
// ---------------------------------------------------------------------------

class _SpendLimitRow extends StatelessWidget {
  final double? currentLimit;
  final double maxLimit;
  final ValueChanged<double> onChanged;
  final BankThemeData bankTheme;
  final IconData icon;
  final String label;
  final String noLimitLabel;
  final Color labelColor;
  final Color activeColor;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SpendLimitRow({
    required this.currentLimit,
    required this.maxLimit,
    required this.onChanged,
    required this.bankTheme,
    required this.icon,
    required this.label,
    required this.noLimitLabel,
    required this.labelColor,
    required this.activeColor,
    this.padding,
    this.semanticLabel,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final sliderValue = (currentLimit ?? 0).clamp(0.0, maxLimit);
    final hasLimit = currentLimit != null && currentLimit! > 0;
    final limitLabel = hasLimit
        ? '${currentLimit!.toStringAsFixed(0)} / ${maxLimit.toStringAsFixed(0)}'
        : noLimitLabel;
    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );
    final resolvedLabelStyle =
        BankTokens.labelLarge.copyWith(color: labelColor).merge(labelStyle);
    final resolvedValueStyle = BankTokens.bodyMedium
        .copyWith(color: bankTheme.onSurfaceVariant)
        .merge(valueStyle);

    return Semantics(
      label: semanticLabel ?? 'Spend limit: $limitLabel',
      excludeSemantics: true,
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: resolvedLabelStyle,
                  ),
                ),
                Text(
                  limitLabel,
                  style: resolvedValueStyle,
                ),
              ],
            ),
            Slider(
              value: sliderValue,
              max: maxLimit,
              divisions: maxLimit > 0 ? maxLimit.toInt() ~/ 100 : null,
              activeColor: activeColor,
              inactiveColor: bankTheme.outline,
              label: sliderValue > 0
                  ? sliderValue.toStringAsFixed(0)
                  : noLimitLabel,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionRow: tappable row with forward arrow
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final BankThemeData bankTheme;
  final IconData forwardIcon;
  final Color? labelColor;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bankTheme,
    required this.forwardIcon,
    this.labelColor,
    this.iconColor,
    this.padding,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = labelColor ?? bankTheme.onSurface;
    final resolvedIcon = iconColor ?? bankTheme.onSurfaceVariant;
    final resolvedPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        );
    final resolvedLabelStyle =
        BankTokens.labelLarge.copyWith(color: resolvedLabel).merge(labelStyle);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: resolvedPadding,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(icon, size: 22, color: resolvedIcon),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Text(
                      label,
                      style: resolvedLabelStyle,
                    ),
                  ),
                  Icon(
                    forwardIcon,
                    size: 20,
                    color: bankTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
