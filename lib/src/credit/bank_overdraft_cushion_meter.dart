import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Fee-free overdraft cushion display, equivalent to a "SpotMe" style
/// meter: how much of a no-fee overdraft allowance has been used and how
/// much cushion remains.
///
/// The card shows a title with a positive [feeFreeLabel] chip, a thick
/// rounded meter of [used] against [limit] (the fill turns
/// [BankTokens.warning] above 70 percent and [BankTokens.danger] above
/// 90 percent), the computed remaining amount, limit labels at the track
/// ends, an optional increase hint when [nextEligibleIncrease] is set,
/// and an enable [Switch] when [onChanged] is provided. When [enabled] is
/// `false` the meter dims and [disabledExplainer] replaces the remaining
/// line.
///
/// All monetary values render through [BankBalanceText], so they mask
/// automatically when privacy mode is active.
///
/// ```dart
/// BankOverdraftCushionMeter(
///   limit: Money.fromDouble(200, 'USD'),
///   used: Money.fromDouble(48.50, 'USD'),
///   nextEligibleIncrease: Money.fromDouble(50, 'USD'),
///   enabled: true,
///   onChanged: (value) => setCushionEnabled(value),
///   onAdjust: openIncreaseFlow,
/// )
/// ```
class BankOverdraftCushionMeter extends StatelessWidget {
  /// Total fee-free overdraft allowance.
  final Money limit;

  /// Portion of [limit] currently drawn down.
  final Money used;

  /// Whether the overdraft cushion is currently active.
  final bool enabled;

  /// Next limit increase the customer is eligible for. When set, a hint
  /// row is shown beneath the meter (only while [enabled] is `true`).
  final Money? nextEligibleIncrease;

  /// Called when the customer toggles the cushion on or off. When `null`,
  /// no [Switch] is shown.
  final ValueChanged<bool>? onChanged;

  /// Called when the customer taps the increase hint row. When `null`,
  /// the hint row is static and shows no chevron.
  final VoidCallback? onAdjust;

  /// Card title.
  final String title;

  /// Label for the positive "no fees" chip next to the title.
  final String feeFreeLabel;

  /// Template for the remaining-cushion line. The `{remaining}` token is
  /// replaced with the computed remaining [Money].
  final String remainingTemplate;

  /// Template for the increase hint row. The `{amount}` token is replaced
  /// with [nextEligibleIncrease].
  final String increaseTemplate;

  /// Explainer shown instead of the remaining line while [enabled] is
  /// `false`.
  final String disabledExplainer;

  const BankOverdraftCushionMeter({
    required this.limit,
    required this.used,
    required this.enabled,
    super.key,
    this.nextEligibleIncrease,
    this.onChanged,
    this.onAdjust,
    this.title = 'Overdraft cushion',
    this.feeFreeLabel = 'Fee-free',
    this.remainingTemplate = '{remaining} remaining',
    this.increaseTemplate = 'Increase available: {amount}',
    this.disabledExplainer = 'Your cushion is off. Turn it on to spend a '
        'little past zero without fees.',
  });

  double get _fraction {
    final total = limit.amount.toDouble();
    if (total <= 0) return 0;
    return (used.amount.toDouble() / total).clamp(0.0, 1.0);
  }

  Money get _remaining {
    final diff = limit - used;
    return diff.isNegative ? Money.zero(limit.currencyCode) : diff;
  }

  Color _fillColor(BankThemeData theme) {
    final fraction = _fraction;
    if (fraction > 0.9) return BankTokens.danger;
    if (fraction > 0.7) return BankTokens.warning;
    return theme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final increase = nextEligibleIncrease;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: theme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const SizedBox(height: BankTokens.space3),
              Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMeter(theme, disableAnimations),
                    const SizedBox(height: BankTokens.space2),
                    _buildTrackEndLabels(theme),
                  ],
                ),
              ),
              const SizedBox(height: BankTokens.space3),
              if (enabled)
                _TemplatedMoneyLine(
                  template: remainingTemplate,
                  placeholder: '{remaining}',
                  money: _remaining,
                  textStyle: BankTokens.bodyMedium
                      .copyWith(color: theme.onSurfaceVariant),
                  moneyStyle:
                      BankTokens.numeralSmall.copyWith(color: theme.onSurface),
                )
              else
                Text(
                  disabledExplainer,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              if (enabled && increase != null) ...[
                const SizedBox(height: BankTokens.space2),
                _buildIncreaseRow(context, theme, increase),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BankThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: BankTokens.space2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.positiveBalance.withValues(alpha: 0.12),
            borderRadius: theme.chipRadius,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space2,
              vertical: BankTokens.space1,
            ),
            child: Text(
              feeFreeLabel,
              style:
                  BankTokens.labelSmall.copyWith(color: theme.positiveBalance),
            ),
          ),
        ),
        if (onChanged != null) ...[
          const SizedBox(width: BankTokens.space2),
          Semantics(
            label: title,
            child: SizedBox(
              height: BankTokens.minTapTarget,
              child: FittedBox(
                child: Switch(
                  value: enabled,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMeter(BankThemeData theme, bool disableAnimations) {
    final percentUsed = (_fraction * 100).round();
    final semanticLabel =
        enabled ? '$title: $percentUsed percent used' : '$title is turned off';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: 14,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: theme.primary.withValues(alpha: 0.12),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration:
                    disableAnimations ? Duration.zero : BankTokens.durationBase,
                curve: BankTokens.curveEmphasized,
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _fillColor(theme),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BankTokens.radiusFull),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackEndLabels(BankThemeData theme) {
    final labelStyle =
        BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BankBalanceText(
          money: Money.zero(limit.currencyCode),
          size: BankBalanceSize.small,
          style: labelStyle,
        ),
        BankBalanceText(
          money: limit,
          size: BankBalanceSize.small,
          style: labelStyle,
        ),
      ],
    );
  }

  Widget _buildIncreaseRow(
    BuildContext context,
    BankThemeData theme,
    Money increase,
  ) {
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;

    return Semantics(
      button: onAdjust != null,
      child: InkWell(
        onTap: onAdjust,
        borderRadius: theme.chipRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
          child: Row(
            children: [
              Expanded(
                child: _TemplatedMoneyLine(
                  template: increaseTemplate,
                  placeholder: '{amount}',
                  money: increase,
                  textStyle:
                      BankTokens.bodyMedium.copyWith(color: theme.primary),
                  moneyStyle:
                      BankTokens.numeralSmall.copyWith(color: theme.primary),
                ),
              ),
              if (onAdjust != null)
                Icon(
                  chevron,
                  size: 20,
                  color: theme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a text [template] with a single [placeholder] token replaced by
/// a privacy-aware [BankBalanceText] for [money].
class _TemplatedMoneyLine extends StatelessWidget {
  final String template;
  final String placeholder;
  final Money money;
  final TextStyle textStyle;
  final TextStyle moneyStyle;

  const _TemplatedMoneyLine({
    required this.template,
    required this.placeholder,
    required this.money,
    required this.textStyle,
    required this.moneyStyle,
  });

  @override
  Widget build(BuildContext context) {
    final index = template.indexOf(placeholder);
    if (index < 0) {
      return Text(template, style: textStyle);
    }
    final prefix = template.substring(0, index);
    final suffix = template.substring(index + placeholder.length);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix.isNotEmpty)
          Flexible(
            child: Text(
              prefix,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        BankBalanceText(
          money: money,
          size: BankBalanceSize.small,
          style: moneyStyle,
        ),
        if (suffix.isNotEmpty)
          Flexible(
            child: Text(
              suffix,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
