import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_summary_stack.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// How binding an offer is: an early [indicative] quote versus a [firm]
/// offer the customer can accept as shown.
enum BankOfferFirmness {
  /// A provisional, subject-to-change quote (e.g. a soft check result).
  indicative,

  /// A binding offer whose figures will not change on acceptance.
  firm,
}

/// A pre-acceptance summary of a financing offer.
///
/// Presents the headline periodic payment as a hero figure, a
/// [BankSummaryStack] breakdown (amount, rate, term, total repayable,
/// total interest or profit, and any fee rows), an optional
/// representative-example line, an indicative-versus-firm chip, and the
/// accept / adjust / decline actions.
///
/// The rate label honours `islamicFinanceMode` (profit rate instead of
/// APR) unless [rateLabel] overrides it; likewise the interest row becomes
/// a profit row via [interestLabel]. All monetary values render through
/// [BankBalanceText], so they mask automatically when privacy mode is
/// active on the ambient [BankUiScope].
///
/// ```dart
/// BankOfferSummaryCard(
///   payment: Money.fromDouble(486.20, 'SAR'),
///   onAccept: acceptOffer,
///   amount: Money.fromDouble(25000, 'SAR'),
///   rate: '5.9%',
///   term: '60 months',
///   totalRepayable: Money.fromDouble(29172, 'SAR'),
///   totalInterest: Money.fromDouble(4172, 'SAR'),
///   firmness: BankOfferFirmness.firm,
///   representativeExample: 'Representative example. 5.9% APR fixed.',
///   onAdjust: adjustOffer,
/// )
/// ```
class BankOfferSummaryCard extends StatelessWidget {
  /// Creates a pre-acceptance offer summary card.
  const BankOfferSummaryCard({
    required this.payment,
    required this.onAccept,
    super.key,
    this.amount,
    this.rate,
    this.term,
    this.totalRepayable,
    this.totalInterest,
    this.fees = const <BankSummaryItem>[],
    this.representativeExample,
    this.firmness = BankOfferFirmness.indicative,
    this.onAdjust,
    this.onDecline,
    this.title = 'Your offer',
    this.periodLabel = 'per month',
    this.amountLabel = 'Amount',
    this.rateLabel,
    this.aprLabel = 'APR',
    this.profitRateLabel = 'Profit rate',
    this.termLabel = 'Term',
    this.totalRepayableLabel = 'Total repayable',
    this.interestLabel,
    this.totalInterestLabel = 'Total interest',
    this.totalProfitLabel = 'Total profit',
    this.indicativeLabel = 'Indicative',
    this.firmLabel = 'Firm',
    this.acceptLabel = 'Accept and continue',
    this.adjustLabel = 'Adjust offer',
    this.declineLabel = 'Decline',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.accentColor,
    this.firmIcon,
    this.indicativeIcon,
    this.titleStyle,
    this.amountStyle,
    this.periodStyle,
    this.representativeStyle,
    this.header,
    this.footer,
    this.semanticLabel,
  });

  /// The headline periodic payment (e.g. the monthly instalment).
  final Money payment;

  /// Fired by the primary CTA when the customer accepts the offer.
  final VoidCallback onAccept;

  /// The principal / financed amount row. Hidden when null.
  final Money? amount;

  /// The rate value shown against the rate label (e.g. `'5.9%'`). The
  /// caller formats the figure; hidden when null.
  final String? rate;

  /// The term / tenor value (e.g. `'60 months'`). Hidden when null.
  final String? term;

  /// Total amount repayable over the term. Hidden when null.
  final Money? totalRepayable;

  /// Total interest (or profit) payable. Hidden when null.
  final Money? totalInterest;

  /// Extra fee rows appended to the breakdown, in order. Each is a
  /// [BankSummaryItem] so callers may render text or monetary values.
  final List<BankSummaryItem> fees;

  /// Representative-example / disclosure microcopy shown in a quiet style
  /// beneath the breakdown. Hidden when null.
  final String? representativeExample;

  /// Whether the offer is [BankOfferFirmness.indicative] or
  /// [BankOfferFirmness.firm]. Drives the status chip.
  final BankOfferFirmness firmness;

  /// Optional secondary action to adjust the offer. Hidden when null.
  final VoidCallback? onAdjust;

  /// Optional secondary action to decline the offer. Hidden when null.
  final VoidCallback? onDecline;

  /// Card heading. Defaults to `'Your offer'`.
  final String title;

  /// Suffix shown after the hero payment. Defaults to `'per month'`.
  final String periodLabel;

  /// Label for the amount row. Defaults to `'Amount'`.
  final String amountLabel;

  /// Overrides the rate row label entirely. When null, resolves to
  /// [profitRateLabel] in Islamic finance mode, otherwise [aprLabel].
  final String? rateLabel;

  /// Rate label used outside Islamic finance mode. Defaults to `'APR'`.
  final String aprLabel;

  /// Rate label used in Islamic finance mode. Defaults to `'Profit rate'`.
  final String profitRateLabel;

  /// Label for the term row. Defaults to `'Term'`.
  final String termLabel;

  /// Label for the total-repayable row. Defaults to `'Total repayable'`.
  final String totalRepayableLabel;

  /// Overrides the interest row label entirely. When null, resolves to
  /// [totalProfitLabel] in Islamic finance mode, otherwise
  /// [totalInterestLabel].
  final String? interestLabel;

  /// Interest row label outside Islamic finance mode. Defaults to
  /// `'Total interest'`.
  final String totalInterestLabel;

  /// Interest row label in Islamic finance mode. Defaults to
  /// `'Total profit'`.
  final String totalProfitLabel;

  /// Chip label for an indicative offer. Defaults to `'Indicative'`.
  final String indicativeLabel;

  /// Chip label for a firm offer. Defaults to `'Firm'`.
  final String firmLabel;

  /// Primary CTA label. Defaults to `'Accept and continue'`.
  final String acceptLabel;

  /// Adjust action label. Defaults to `'Adjust offer'`.
  final String adjustLabel;

  /// Decline action label. Defaults to `'Decline'`.
  final String declineLabel;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard]; pass
  /// `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Accent for the firm chip and the primary CTA. Defaults to the theme
  /// primary.
  final Color? accentColor;

  /// Glyph inside the firm chip. Defaults to [BankIcons.success].
  final IconData? firmIcon;

  /// Glyph inside the indicative chip. Defaults to [BankIcons.info].
  final IconData? indicativeIcon;

  /// Merged over the computed title style (headlineSmall, onSurface).
  final TextStyle? titleStyle;

  /// Merged over the hero payment style (numeralHero, onSurface).
  final TextStyle? amountStyle;

  /// Merged over the period-suffix style (bodyMedium, onSurfaceVariant).
  final TextStyle? periodStyle;

  /// Merged over the representative-example style (bodySmall,
  /// onSurfaceVariant).
  final TextStyle? representativeStyle;

  /// Replaces the built-in title / firmness header row.
  final Widget? header;

  /// Optional slot rendered below the action buttons (e.g. legal
  /// microcopy).
  final Widget? footer;

  /// Overrides the accessibility label announced for the offer heading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final resolvedRadius = radius ?? theme.cardRadius;
    final accent = accentColor ?? theme.primary;

    final rateName =
        rateLabel ?? (scope.islamicFinanceMode ? profitRateLabel : aprLabel);
    final interestName = interestLabel ??
        (scope.islamicFinanceMode ? totalProfitLabel : totalInterestLabel);

    final rows = <BankSummaryItem>[
      if (amount != null) BankSummaryItem(label: amountLabel, money: amount),
      if (rate != null) BankSummaryItem(label: rateName, value: rate),
      if (term != null) BankSummaryItem(label: termLabel, value: term),
      ...fees,
      if (totalInterest != null)
        BankSummaryItem(label: interestName, money: totalInterest),
      if (totalRepayable != null)
        BankSummaryItem(
          label: totalRepayableLabel,
          money: totalRepayable,
          emphasized: true,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: resolvedRadius,
        boxShadow: shadow ?? BankTokens.shadowCard,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header ?? _header(theme, scope),
            const SizedBox(height: BankTokens.space3),
            _payment(theme, scope),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: BankTokens.space4),
              BankSummaryStack(items: rows),
            ],
            if (representativeExample != null) ...[
              const SizedBox(height: BankTokens.space3),
              Text(
                representativeExample!,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(representativeStyle),
              ),
            ],
            const SizedBox(height: BankTokens.space4),
            _actions(theme, accent),
            if (footer != null) ...[
              const SizedBox(height: BankTokens.space3),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BankThemeData theme, BankUiScopeData scope) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: BankTokens.headlineSmall
                .copyWith(
                  color: theme.onSurface,
                  fontFamily: theme.fontFamily,
                )
                .merge(titleStyle),
          ),
        ),
        const SizedBox(width: BankTokens.space2),
        _firmnessChip(theme),
      ],
    );
  }

  Widget _firmnessChip(BankThemeData theme) {
    final isFirm = firmness == BankOfferFirmness.firm;
    final color = isFirm ? theme.positiveBalance : theme.pending;
    final label = isFirm ? firmLabel : indicativeLabel;
    final icon = isFirm
        ? (firmIcon ?? BankIcons.success)
        : (indicativeIcon ?? BankIcons.info);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: BankTokens.space1),
            Text(
              label,
              style: BankTokens.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payment(BankThemeData theme, BankUiScopeData scope) {
    return Semantics(
      label: semanticLabel ?? _defaultSemanticLabel(scope),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          BankBalanceText(
            money: payment,
            size: BankBalanceSize.hero,
            style: theme.numeralHero
                .copyWith(
                  color: theme.onSurface,
                  fontFamily: theme.fontFamily,
                )
                .merge(amountStyle),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: BankTokens.space2,
              bottom: BankTokens.space2,
            ),
            child: Text(
              periodLabel,
              style: BankTokens.bodyMedium
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(periodStyle),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultSemanticLabel(BankUiScopeData scope) {
    final firmnessName =
        firmness == BankOfferFirmness.firm ? firmLabel : indicativeLabel;
    final paymentText = scope.privacyEnabled
        ? scope.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: payment.amount,
            currencyCode: payment.currencyCode,
            numeralStyle: scope.numeralStyle,
          );
    return '$title, $firmnessName. $paymentText $periodLabel';
  }

  Widget _actions(BankThemeData theme, Color accent) {
    final secondary = <Widget>[
      if (onAdjust != null)
        Expanded(
          child: TextButton(
            onPressed: onAdjust,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: Text(adjustLabel, style: BankTokens.labelLarge),
          ),
        ),
      if (onDecline != null)
        Expanded(
          child: TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: theme.onSurfaceVariant,
            ),
            child: Text(declineLabel, style: BankTokens.labelLarge),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: BankTokens.space12,
          child: FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: theme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
            ),
            child: Text(acceptLabel, style: BankTokens.labelLarge),
          ),
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: BankTokens.space1),
          Row(children: secondary),
        ],
      ],
    );
  }
}
