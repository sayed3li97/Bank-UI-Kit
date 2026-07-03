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
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Toggle group ────────────────────────────────────────────────────
        _ControlRow(
          icon: BankIcons.cardFreeze,
          label: 'Freeze Card',
          subtitle: 'Temporarily block all transactions',
          value: isFrozen,
          onChanged: onFreezeChanged,
          bankTheme: bankTheme,
          iconColor: bankTheme.frozen,
        ),
        _ControlRow(
          icon: BankIcons.cardOnline,
          label: 'Online Payments',
          subtitle: 'Allow card-not-present purchases',
          value: isOnlinePaymentsEnabled,
          onChanged: onOnlinePaymentsChanged,
          bankTheme: bankTheme,
        ),
        _ControlRow(
          icon: BankIcons.cardContactless,
          label: 'Contactless Payments',
          subtitle: 'Tap-to-pay via NFC',
          value: isContactlessEnabled,
          onChanged: onContactlessChanged,
          bankTheme: bankTheme,
        ),
        _ControlRow(
          icon: BankIcons.cardInternational,
          label: 'International Payments',
          subtitle: 'Use card outside home country',
          value: isInternationalEnabled,
          onChanged: onInternationalChanged,
          bankTheme: bankTheme,
        ),

        // ── Spend limit slider ───────────────────────────────────────────────
        if (onSpendLimitChanged != null) ...[
          const Divider(height: 1),
          _SpendLimitRow(
            currentLimit: spendLimit,
            maxLimit: maxSpendLimit,
            onChanged: onSpendLimitChanged!,
            bankTheme: bankTheme,
          ),
        ],

        // ── Divider ──────────────────────────────────────────────────────────
        const Divider(height: 1),

        // ── Action group ─────────────────────────────────────────────────────
        if (onChangePinTap != null)
          _ActionRow(
            label: 'Change PIN',
            icon: BankIcons.lock,
            onTap: onChangePinTap!,
            bankTheme: bankTheme,
          ),

        if (onReportLostOrStolen != null)
          _ActionRow(
            label: 'Report Lost or Stolen',
            icon: BankIcons.warning,
            onTap: onReportLostOrStolen!,
            bankTheme: bankTheme,
            labelColor: BankTokens.danger,
            iconColor: BankTokens.danger,
          ),
      ],
    );
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
  final Color? iconColor;

  const _ControlRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.bankTheme,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value ? 'enabled' : 'disabled',
      toggled: value,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
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
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: BankTokens.bodySmall.copyWith(
                            color: bankTheme.onSurfaceVariant,
                          ),
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
                        activeColor: bankTheme.primary,
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

  const _SpendLimitRow({
    required this.currentLimit,
    required this.maxLimit,
    required this.onChanged,
    required this.bankTheme,
  });

  @override
  Widget build(BuildContext context) {
    final sliderValue = (currentLimit ?? 0).clamp(0.0, maxLimit);
    final hasLimit = currentLimit != null && currentLimit! > 0;
    final limitLabel = hasLimit
        ? '${currentLimit!.toStringAsFixed(0)} / ${maxLimit.toStringAsFixed(0)}'
        : 'No limit';

    return Semantics(
      label: 'Spend limit: $limitLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        ),
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
                      BankIcons.cardLimit,
                      size: 22,
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Text(
                    'Spend Limit',
                    style: BankTokens.labelLarge.copyWith(
                      color: bankTheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  limitLabel,
                  style: BankTokens.bodyMedium.copyWith(
                    color: bankTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Slider(
              value: sliderValue,
              max: maxLimit,
              divisions: maxLimit > 0 ? maxLimit.toInt() ~/ 100 : null,
              activeColor: bankTheme.primary,
              inactiveColor: bankTheme.outline,
              label:
                  sliderValue > 0 ? sliderValue.toStringAsFixed(0) : 'No limit',
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
  final Color? labelColor;
  final Color? iconColor;

  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bankTheme,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = labelColor ?? bankTheme.onSurface;
    final resolvedIcon = iconColor ?? bankTheme.onSurfaceVariant;

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
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
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
                      style: BankTokens.labelLarge.copyWith(
                        color: resolvedLabel,
                      ),
                    ),
                  ),
                  Icon(
                    BankIcons.forward,
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
