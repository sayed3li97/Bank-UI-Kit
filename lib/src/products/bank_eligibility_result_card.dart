import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The graded result of a soft (pre-qualification) eligibility check.
///
/// The ordering runs from most to least favourable and each value maps to
/// a tone in [BankEligibilityResultCard]:
/// - [likely] uses the positive tone.
/// - [possible] uses the warning tone.
/// - [unlikely] uses the danger tone.
/// - [ineligible] uses a neutral (muted) tone.
enum BankEligibilityOutcome { likely, possible, unlikely, ineligible }

/// Result card for a soft / pre-qualification eligibility check.
///
/// Summarises the outcome of a no-obligation check without pulling a hard
/// credit search. A tone-coloured header pairs an outcome [outcome] icon
/// with a headline drawn from the per-outcome label params (English
/// defaults). Below it an optional estimated rate range ([estimatedRate])
/// carries a Shariah-safe rate label (APR by default, swapped for the
/// profit-rate label under `islamicFinanceMode`, or overridden via
/// [rateLabel]) and an optional [rateCaption] for microcopy such as
/// "representative" or "as of 4 Jul 2026". An optional maximum eligible
/// amount ([maxAmount]) renders through [BankBalanceText] so it masks with
/// privacy mode. A prominent reassurance chip states there is no impact to
/// the credit score when [noCreditImpact] is `true`. An optional [reasons]
/// list explains what would help (or why the check did not pass). The
/// primary call to action ([onApply]) is shown only for the likely and
/// possible outcomes.
///
/// Every visual decision is overridable and every user-facing string is a
/// constructor parameter with an English default.
///
/// ```dart
/// BankEligibilityResultCard(
///   outcome: BankEligibilityOutcome.likely,
///   estimatedRate: '5.9% to 8.4%',
///   maxAmount: Money.fromDouble(25000, 'GBP'),
///   rateCaption: 'Representative, subject to full application',
///   reasons: const [
///     'Add your annual income to refine your rate',
///     'A longer term could lower monthly payments',
///   ],
///   onApply: () => startApplication(),
/// )
/// ```
class BankEligibilityResultCard extends StatelessWidget {
  const BankEligibilityResultCard({
    required this.outcome,
    super.key,
    this.estimatedRate,
    this.maxAmount,
    this.reasons,
    this.onApply,
    this.noCreditImpact = true,
    this.likelyLabel = 'You are likely to be approved',
    this.possibleLabel = 'You may be approved',
    this.unlikelyLabel = 'Approval looks unlikely',
    this.ineligibleLabel = 'Not eligible right now',
    this.rateLabel,
    this.aprLabel = 'APR',
    this.profitRateLabel = 'Profit rate',
    this.estimatedRatePrefix = 'Estimated',
    this.rateCaption,
    this.maxAmountLabel = 'You could borrow up to',
    this.noCreditImpactLabel = 'No impact to your credit score',
    this.reasonsTitle = 'What could help',
    this.applyLabel = 'Continue to apply',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.positiveColor,
    this.warningColor,
    this.dangerColor,
    this.neutralColor,
    this.likelyIcon,
    this.possibleIcon,
    this.unlikelyIcon,
    this.ineligibleIcon,
    this.noCreditImpactIcon,
    this.reasonIcon,
    this.headlineStyle,
    this.rateLabelStyle,
    this.rateValueStyle,
    this.rateCaptionStyle,
    this.amountLabelStyle,
    this.amountStyle,
    this.reasonsTitleStyle,
    this.reasonStyle,
    this.header,
    this.footer,
    this.semanticLabel,
  });

  /// The graded outcome that drives the tone, icon, and headline.
  final BankEligibilityOutcome outcome;

  /// Estimated rate or rate range, e.g. `'5.9% to 8.4%'`. Hidden when
  /// `null`.
  final String? estimatedRate;

  /// Maximum eligible amount, shown via [BankBalanceText]. Hidden when
  /// `null`.
  final Money? maxAmount;

  /// Optional supporting reasons ("what would help" or "why not"). Hidden
  /// when `null` or empty.
  final List<String>? reasons;

  /// Primary action callback. The CTA is shown only for the likely and
  /// possible outcomes, and only when this is non-null.
  final VoidCallback? onApply;

  /// Whether to show the "no impact to your credit score" reassurance
  /// chip. Defaults to `true`.
  final bool noCreditImpact;

  /// Headline for the [BankEligibilityOutcome.likely] outcome.
  final String likelyLabel;

  /// Headline for the [BankEligibilityOutcome.possible] outcome.
  final String possibleLabel;

  /// Headline for the [BankEligibilityOutcome.unlikely] outcome.
  final String unlikelyLabel;

  /// Headline for the [BankEligibilityOutcome.ineligible] outcome.
  final String ineligibleLabel;

  /// Overrides the resolved rate label. When `null` the label falls back
  /// to [profitRateLabel] under `islamicFinanceMode`, else [aprLabel].
  final String? rateLabel;

  /// Conventional rate label used when not in Islamic finance mode.
  /// Defaults to `'APR'`.
  final String aprLabel;

  /// Shariah-safe rate label used under `islamicFinanceMode`. Defaults to
  /// `'Profit rate'`.
  final String profitRateLabel;

  /// Word placed before the rate label, e.g. `'Estimated APR'`. Pass an
  /// empty string to show the rate label alone.
  final String estimatedRatePrefix;

  /// Optional microcopy under the rate, e.g. `'Representative'` or
  /// `'as of 4 Jul 2026'`. Hidden when `null`.
  final String? rateCaption;

  /// Caption above the [maxAmount] figure. Defaults to
  /// `'You could borrow up to'`.
  final String maxAmountLabel;

  /// Label of the reassurance chip. Defaults to
  /// `'No impact to your credit score'`.
  final String noCreditImpactLabel;

  /// Heading above the [reasons] list. Defaults to `'What could help'`.
  final String reasonsTitle;

  /// Label of the primary CTA. Defaults to `'Continue to apply'`.
  final String applyLabel;

  /// Overrides the card content padding. Defaults to space5 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard]; pass
  /// `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the tone for the likely outcome. Defaults to the theme
  /// positiveBalance colour.
  final Color? positiveColor;

  /// Overrides the tone for the possible outcome. Defaults to
  /// [BankTokens.warning].
  final Color? warningColor;

  /// Overrides the tone for the unlikely outcome. Defaults to
  /// [BankTokens.danger].
  final Color? dangerColor;

  /// Overrides the tone for the ineligible outcome. Defaults to the
  /// theme onSurfaceVariant colour.
  final Color? neutralColor;

  /// Overrides the likely header glyph. Defaults to [BankIcons.success].
  final IconData? likelyIcon;

  /// Overrides the possible header glyph. Defaults to [BankIcons.info].
  final IconData? possibleIcon;

  /// Overrides the unlikely header glyph. Defaults to [BankIcons.warning].
  final IconData? unlikelyIcon;

  /// Overrides the ineligible header glyph. Defaults to [Icons.block].
  final IconData? ineligibleIcon;

  /// Overrides the reassurance chip glyph. Defaults to [BankIcons.shield].
  final IconData? noCreditImpactIcon;

  /// Overrides the reasons row glyph. Defaults to [BankIcons.success].
  final IconData? reasonIcon;

  /// Merged over the outcome headline style (headlineSmall, tone colour).
  final TextStyle? headlineStyle;

  /// Merged over the rate label style (labelMedium, onSurfaceVariant).
  final TextStyle? rateLabelStyle;

  /// Merged over the rate value style (numeralMedium, onSurface).
  final TextStyle? rateValueStyle;

  /// Merged over the rate caption style (bodySmall, onSurfaceVariant).
  final TextStyle? rateCaptionStyle;

  /// Merged over the amount caption style (bodySmall, onSurfaceVariant).
  final TextStyle? amountLabelStyle;

  /// Overrides the [maxAmount] figure style passed to [BankBalanceText].
  /// Defaults to the hero numeral style in onSurface.
  final TextStyle? amountStyle;

  /// Merged over the reasons heading style (labelMedium, onSurface).
  final TextStyle? reasonsTitleStyle;

  /// Merged over each reason row style (bodyMedium, onSurfaceVariant).
  final TextStyle? reasonStyle;

  /// Optional widget rendered above the outcome header.
  final Widget? header;

  /// Optional widget rendered below the CTA (e.g. legal microcopy).
  final Widget? footer;

  /// Overrides the computed container semantics label.
  final String? semanticLabel;

  bool get _showCta =>
      onApply != null &&
      (outcome == BankEligibilityOutcome.likely ||
          outcome == BankEligibilityOutcome.possible);

  Color _tone(BankThemeData theme) => switch (outcome) {
        BankEligibilityOutcome.likely => positiveColor ?? theme.positiveBalance,
        BankEligibilityOutcome.possible => warningColor ?? BankTokens.warning,
        BankEligibilityOutcome.unlikely => dangerColor ?? BankTokens.danger,
        BankEligibilityOutcome.ineligible =>
          neutralColor ?? theme.onSurfaceVariant,
      };

  String get _headline => switch (outcome) {
        BankEligibilityOutcome.likely => likelyLabel,
        BankEligibilityOutcome.possible => possibleLabel,
        BankEligibilityOutcome.unlikely => unlikelyLabel,
        BankEligibilityOutcome.ineligible => ineligibleLabel,
      };

  IconData get _icon => switch (outcome) {
        BankEligibilityOutcome.likely => likelyIcon ?? BankIcons.success,
        BankEligibilityOutcome.possible => possibleIcon ?? BankIcons.info,
        BankEligibilityOutcome.unlikely => unlikelyIcon ?? BankIcons.warning,
        BankEligibilityOutcome.ineligible => ineligibleIcon ?? Icons.block,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final tone = _tone(theme);

    final rateName =
        rateLabel ?? (scope.islamicFinanceMode ? profitRateLabel : aprLabel);
    final rateHeading = estimatedRatePrefix.isEmpty
        ? rateName
        : '$estimatedRatePrefix '
            '$rateName';
    final reasonList = reasons ?? const <String>[];

    final semantics = semanticLabel ??
        [
          _headline,
          if (estimatedRate != null) '$rateHeading $estimatedRate',
          if (noCreditImpact) noCreditImpactLabel,
        ].join('. ');

    return Semantics(
      container: true,
      label: semantics,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.surface,
          borderRadius: radius ?? theme.cardRadius,
          boxShadow: shadow ?? BankTokens.shadowCard,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(BankTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: BankTokens.space4),
              ],
              _buildHeader(theme, tone),
              if (maxAmount != null || estimatedRate != null) ...[
                const SizedBox(height: BankTokens.space4),
                _buildFigures(theme, rateHeading),
              ],
              if (noCreditImpact) ...[
                const SizedBox(height: BankTokens.space4),
                _buildReassurance(theme),
              ],
              if (reasonList.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space4),
                _buildReasons(theme, tone, reasonList),
              ],
              if (_showCta) ...[
                const SizedBox(height: BankTokens.space5),
                _buildCta(theme),
              ],
              if (footer != null) ...[
                const SizedBox(height: BankTokens.space4),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BankThemeData theme, Color tone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space2),
            child: Icon(_icon, color: tone, size: 24),
          ),
        ),
        const SizedBox(width: BankTokens.space3),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: BankTokens.space1),
            child: Text(
              _headline,
              style: BankTokens.headlineSmall
                  .copyWith(color: theme.onSurface)
                  .merge(headlineStyle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFigures(BankThemeData theme, String rateHeading) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (maxAmount != null) ...[
              Text(
                maxAmountLabel,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(amountLabelStyle),
              ),
              const SizedBox(height: BankTokens.space1),
              BankBalanceText(
                money: maxAmount!,
                size: BankBalanceSize.hero,
                style: amountStyle,
              ),
            ],
            if (maxAmount != null && estimatedRate != null)
              const SizedBox(height: BankTokens.space3),
            if (estimatedRate != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      rateHeading,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(rateLabelStyle),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Text(
                    estimatedRate!,
                    style: BankTokens.numeralMedium
                        .copyWith(color: theme.onSurface)
                        .merge(rateValueStyle),
                  ),
                ],
              ),
              if (rateCaption != null) ...[
                const SizedBox(height: BankTokens.space1),
                Text(
                  rateCaption!,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(rateCaptionStyle),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReassurance(BankThemeData theme) {
    final tint = positiveColor ?? theme.positiveBalance;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space3,
          vertical: BankTokens.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noCreditImpactIcon ?? BankIcons.shield,
              color: tint,
              size: 18,
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                noCreditImpactLabel,
                style: BankTokens.labelMedium.copyWith(color: tint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasons(
    BankThemeData theme,
    Color tone,
    List<String> reasonList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reasonsTitle,
          style: BankTokens.labelMedium
              .copyWith(color: theme.onSurface)
              .merge(reasonsTitleStyle),
        ),
        const SizedBox(height: BankTokens.space2),
        for (final reason in reasonList)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: BankTokens.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 2),
                  child: Icon(
                    reasonIcon ?? BankIcons.success,
                    color: tone,
                    size: 16,
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                Expanded(
                  child: Text(
                    reason,
                    style: BankTokens.bodyMedium
                        .copyWith(color: theme.onSurfaceVariant)
                        .merge(reasonStyle),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCta(BankThemeData theme) {
    return Semantics(
      button: true,
      label: applyLabel,
      child: SizedBox(
        width: double.infinity,
        height: BankTokens.space12,
        child: FilledButton(
          onPressed: onApply,
          style: FilledButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          ),
          child: Text(
            applyLabel,
            style: BankTokens.labelLarge.copyWith(color: theme.onPrimary),
          ),
        ),
      ),
    );
  }
}
