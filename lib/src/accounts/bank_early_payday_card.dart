import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';
import 'bank_balance_text.dart';

/// Early salary access banner card.
///
/// Advertises (and toggles) an early-payday feature: salary lands up
/// to two days early. The card shows a
/// calendar icon on an accent tint band, a title, a body line with the
/// computed number of days the salary can arrive early, the expected
/// amount (via [BankBalanceText], privacy-mask aware) when provided, and
/// a comparison row: the struck-through normal payday next to the
/// highlighted early payday, both formatted with
/// [BankDateFormatter.formatFull]. A [Switch] bound to [enabled] and
/// [onChanged] turns the feature on and off; while enabled the body line
/// is swapped for [enabledLabel] with a positive check icon.
///
/// Use it on an account home screen or in a payday settings flow.
///
/// ```dart
/// BankEarlyPaydayCard(
///   normalPayday: DateTime(2026, 7, 31),
///   earlyPayday: DateTime(2026, 7, 29),
///   expectedAmount: Money.fromDouble(2450, 'GBP'),
///   enabled: earlyPayEnabled,
///   onChanged: (value) => setState(() => earlyPayEnabled = value),
/// )
/// ```
class BankEarlyPaydayCard extends StatelessWidget {
  /// The date the salary would normally arrive.
  final DateTime normalPayday;

  /// The earlier date the salary can arrive with the feature enabled.
  final DateTime earlyPayday;

  /// Whether early payday is currently switched on.
  final bool enabled;

  /// Called when the user toggles the switch.
  final ValueChanged<bool> onChanged;

  /// The expected salary amount. When non-null it is rendered with
  /// [BankBalanceText] so privacy mode masks it automatically.
  final Money? expectedAmount;

  /// Card headline.
  final String title;

  /// Body copy shown while the feature is off. The `{days}` placeholder
  /// is replaced with the computed day difference between [normalPayday]
  /// and [earlyPayday].
  final String bodyTemplate;

  /// Body copy shown with a positive check while the feature is on.
  final String enabledLabel;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsetsDirectional.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// `cardRadius`.
  final BorderRadius? radius;

  /// Overrides the card background colour. Defaults to the theme
  /// `surface`.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the accent used for the tint band, calendar icon, early
  /// date and switch. Defaults to the theme `primary`.
  final Color? accentColor;

  /// Overrides the tint-band gradient. Defaults to the theme
  /// `accentGradient` when the preset provides one.
  final Gradient? gradient;

  /// Overrides the leading calendar glyph. Defaults to
  /// [BankIcons.calendar].
  final IconData? icon;

  /// Overrides the check glyph shown while the feature is on. Defaults
  /// to [BankIcons.success].
  final IconData? enabledIcon;

  /// Overrides the arrow glyph between the two paydays. Defaults to
  /// [BankIcons.forward].
  final IconData? forwardIcon;

  /// Merged over the headline style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the body-line style ([BankTokens.bodySmall]) in both
  /// the off and on states.
  final TextStyle? bodyStyle;

  /// Merged over the expected-amount style (theme `numeralSmall`).
  final TextStyle? amountStyle;

  /// Overrides the body cross-fade duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the body cross-fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Accessibility label template for the payday comparison row. The
  /// `{normal}` and `{early}` placeholders are replaced with the two
  /// formatted dates. Defaults to
  /// `'Normal payday {normal}, early payday {early}'`.
  final String dateSemanticTemplate;

  const BankEarlyPaydayCard({
    required this.normalPayday,
    required this.earlyPayday,
    required this.enabled,
    required this.onChanged,
    super.key,
    this.expectedAmount,
    this.title = 'Get paid early',
    this.bodyTemplate = 'Your salary can arrive {days} days early',
    this.enabledLabel = 'Early pay is on',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.accentColor,
    this.gradient,
    this.icon,
    this.enabledIcon,
    this.forwardIcon,
    this.titleStyle,
    this.bodyStyle,
    this.amountStyle,
    this.animationDuration,
    this.animationCurve,
    this.dateSemanticTemplate = 'Normal payday {normal}, early payday {early}',
  });

  /// Whole days between the normal and early paydays, never negative.
  int get _daysEarly {
    final normal =
        DateTime(normalPayday.year, normalPayday.month, normalPayday.day);
    final early =
        DateTime(earlyPayday.year, earlyPayday.month, earlyPayday.day);
    final diff = normal.difference(early).inDays;
    return diff < 0 ? 0 : diff;
  }

  Widget _buildBody(BuildContext context, BankThemeData theme) {
    final scope = BankUiScope.of(context);

    final Widget body;
    if (enabled) {
      body = Row(
        key: const ValueKey<bool>(true),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabledIcon ?? BankIcons.success,
            size: 16,
            color: theme.positiveBalance,
          ),
          const SizedBox(width: BankTokens.space1),
          Flexible(
            child: Text(
              enabledLabel,
              style: BankTokens.bodySmall
                  .copyWith(color: theme.positiveBalance)
                  .merge(bodyStyle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      final days = scope.numeralStyle.convert('$_daysEarly');
      body = Text(
        bodyTemplate.replaceAll('{days}', days),
        key: const ValueKey<bool>(false),
        style: BankTokens.bodySmall
            .copyWith(color: theme.onSurfaceVariant)
            .merge(bodyStyle),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: disableAnimations
          ? Duration.zero
          : animationDuration ?? BankTokens.durationBase,
      switchInCurve: animationCurve ?? BankTokens.curveStandard,
      switchOutCurve: animationCurve ?? BankTokens.curveStandard,
      child: Align(
        key: ValueKey<bool>(enabled),
        alignment: AlignmentDirectional.centerStart,
        child: body,
      ),
    );
  }

  Widget _buildDateComparison(BuildContext context, BankThemeData theme) {
    final scope = BankUiScope.of(context);
    final normalLabel =
        scope.numeralStyle.convert(BankDateFormatter.formatFull(normalPayday));
    final earlyLabel =
        scope.numeralStyle.convert(BankDateFormatter.formatFull(earlyPayday));

    return Semantics(
      label: dateSemanticTemplate
          .replaceAll('{normal}', normalLabel)
          .replaceAll('{early}', earlyLabel),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: theme.chipRadius,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space3,
            vertical: BankTokens.space2,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  normalLabel,
                  style: BankTokens.bodySmall.copyWith(
                    color: theme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: theme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BankTokens.space2),
              Icon(
                forwardIcon ?? BankIcons.forward,
                size: 16,
                color: theme.onSurfaceVariant,
              ),
              const SizedBox(width: BankTokens.space2),
              Flexible(
                child: Text(
                  earlyLabel,
                  style: BankTokens.labelMedium
                      .copyWith(color: accentColor ?? theme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = accentColor ?? theme.primary;

    // Accent tint band running along the start edge of the card.
    final bandGradient = gradient ?? theme.accentGradient;
    final bandDecoration = bandGradient != null
        ? BoxDecoration(gradient: bandGradient)
        : BoxDecoration(color: accent);

    final content = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(BankTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(BankTokens.space2),
                  child: Icon(
                    icon ?? BankIcons.calendar,
                    size: 20,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BankTokens.labelLarge
                          .copyWith(color: theme.onSurface)
                          .merge(titleStyle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BankTokens.space1),
                    _buildBody(context, theme),
                  ],
                ),
              ),
              const SizedBox(width: BankTokens.space2),
              SizedBox(
                height: BankTokens.minTapTarget,
                child: Semantics(
                  label: title,
                  child: Switch(
                    value: enabled,
                    onChanged: onChanged,
                    activeColor: accent,
                  ),
                ),
              ),
            ],
          ),
          if (expectedAmount != null) ...[
            const SizedBox(height: BankTokens.space3),
            BankBalanceText(
              money: expectedAmount!,
              size: BankBalanceSize.small,
              style: amountStyle == null
                  ? null
                  : theme.numeralSmall
                      .copyWith(color: theme.onSurface)
                      .merge(amountStyle),
            ),
          ],
          const SizedBox(height: BankTokens.space3),
          _buildDateComparison(context, theme),
        ],
      ),
    );

    final resolvedRadius = radius ?? theme.cardRadius;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.surface,
          borderRadius: resolvedRadius,
          boxShadow: shadow ?? BankTokens.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: bandDecoration,
                  child: const SizedBox(width: BankTokens.space1),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
