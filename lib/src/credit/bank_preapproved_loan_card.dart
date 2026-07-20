import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/button_text_style.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// Pre-approved financing offer card with quick-pick amounts and a
/// one-tap continue action.
///
/// Shows the maximum pre-approved amount as a hero figure under an
/// `accentGradient` header strip (title plus offer badge), quick-pick
/// chips at 25%, 50%, and 100% of the maximum (plus [quickAmount] when
/// provided), a live estimated monthly installment for the selection
/// (standard amortization over [maxMonths], the same math as
/// `BankLoanCalculatorCard`), a rate and tenor microline, and a
/// full-width CTA that fires [onContinue] with the selected amount.
///
/// The rate label honours `islamicFinanceMode` (profit rate instead of
/// APR) unless [rateLabel] overrides it. An expiry countdown chip
/// appears when [offerExpires] falls within 14 days; once the offer
/// has expired the chips and the CTA are disabled. All digits respect
/// the ambient `NumeralStyle`, and amounts mask automatically when
/// privacy mode is active.
///
/// ```dart
/// BankPreapprovedLoanCard(
///   maxAmount: Money.fromDouble(250000, 'SAR'),
///   annualRate: 0.049, // a FRACTION: 0.049 renders as 4.9% APR
///   maxMonths: 60,
///   onContinue: startApplication,
///   quickAmount: Money.fromDouble(30000, 'SAR'),
///   offerExpires: DateTime.now().add(const Duration(days: 10)),
/// )
/// ```
class BankPreapprovedLoanCard extends StatefulWidget {
  const BankPreapprovedLoanCard({
    required this.maxAmount,
    required this.annualRate,
    required this.maxMonths,
    required this.onContinue,
    super.key,
    this.quickAmount,
    this.offerExpires,
    this.title = 'You are pre-approved',
    this.rateLabel,
    this.ctaLabel = 'Get the money',
    this.badgeLabel = 'Exclusive offer',
    this.upToLabel = 'Up to',
    this.monthlyLabel = 'Est. monthly payment',
    this.tenorTemplate = 'up to {n} months',
    this.expiresTemplate = 'Expires in {n} days',
    this.expiresTodayLabel = 'Expires today',
    this.expiredLabel = 'Offer expired',
    this.aprLabel = 'APR',
    this.profitRateLabel = 'Profit rate',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.border,
    this.gradient,
    this.accentColor,
    this.badgeIcon,
    this.expiryIcon,
    this.titleStyle,
    this.amountStyle,
    this.monthlyStyle,
    this.header,
    this.animationDuration,
    this.animationCurve,
  })  : assert(maxMonths > 0, 'maxMonths must be positive'),
        assert(
          annualRate >= 0 && annualRate < 1.5,
          'annualRate is a fraction: 0.089 means 8.9% APR',
        );

  /// The maximum pre-approved financing amount.
  final Money maxAmount;

  /// Nominal annual rate as a **fraction of 1, not a percentage**:
  /// pass `0.089` for 8.9 % APR — passing `8.9` would mean 890 % and is
  /// rejected by an assert. The same fraction drives both the displayed
  /// rate (via [formattedApr]) and the amortized monthly-payment
  /// estimate, so the two can never disagree.
  final double annualRate;

  /// The longest available tenor, used for the installment estimate.
  final int maxMonths;

  /// Fired by the CTA with the currently selected amount.
  final void Function(Money amount) onContinue;

  /// Optional extra quick-pick amount (e.g. a personalised suggestion).
  /// Must share [maxAmount]'s currency.
  final Money? quickAmount;

  /// When the offer lapses. A countdown chip renders once this falls
  /// within 14 days; past dates disable the card.
  final DateTime? offerExpires;

  final String title;

  /// Overrides the APR / profit-rate label entirely.
  final String? rateLabel;

  final String ctaLabel;
  final String badgeLabel;
  final String upToLabel;
  final String monthlyLabel;

  /// `{n}` is substituted with [maxMonths].
  final String tenorTemplate;

  /// `{n}` is substituted with the days remaining.
  final String expiresTemplate;

  final String expiresTodayLabel;
  final String expiredLabel;
  final String aprLabel;
  final String profitRateLabel;

  /// Overrides the body content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to the hero shadow appropriate
  /// for the theme background brightness ([BankTokens.shadowHeroFor]);
  /// pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor]
  /// (a shadow alone cannot separate the card there); light surfaces
  /// keep an invisible border of the same width so geometry is
  /// identical across brightness. Pass `const Border()` to remove it.
  final BoxBorder? border;

  /// Overrides the header strip gradient. Defaults to the theme
  /// accentGradient (falling back to primary tones).
  final Gradient? gradient;

  /// Accent for the monthly figure, selected chip, and CTA. Defaults
  /// to the theme primary.
  final Color? accentColor;

  /// Glyph inside the offer badge. Defaults to [BankIcons.success].
  final IconData? badgeIcon;

  /// Glyph inside the expiry chip. Defaults to [BankIcons.schedule].
  final IconData? expiryIcon;

  /// Merged over the header [title] style (headlineSmall, onPrimary).
  final TextStyle? titleStyle;

  /// Merged over the hero amount style (numeralHero, onSurface).
  final TextStyle? amountStyle;

  /// Merged over the monthly estimate style (numeralMedium, accent).
  final TextStyle? monthlyStyle;

  /// Replaces the entire gradient header strip. Defaults to the
  /// built-in title and badge row.
  final Widget? header;

  /// Duration of the monthly figure cross-fade. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Curve of the monthly figure cross-fade. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// [annualRate] rendered as display percentage text, e.g. `0.089`
  /// gives `'8.9%'` (up to two decimals, trailing zeros trimmed).
  ///
  /// This is the exact text the card shows in its rate microline, so a
  /// percent-style input like `8.9` can never silently render as
  /// `'890.00%'` — it is rejected by the constructor assert instead.
  String get formattedApr => formatAnnualRate(annualRate);

  /// Formats a fractional annual [rate] (`0.089` means 8.9 %) as
  /// percentage text with up to two decimals and no trailing zeros,
  /// converted through [numeralStyle]: `0.089`, `0.0499`, and `0.05`
  /// give `'8.9%'`, `'4.99%'`, and `'5%'`.
  static String formatAnnualRate(
    double rate, {
    NumeralStyle numeralStyle = NumeralStyle.western,
  }) {
    var text = (rate * 100).toStringAsFixed(2);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return numeralStyle.convert('$text%');
  }

  @override
  State<BankPreapprovedLoanCard> createState() =>
      _BankPreapprovedLoanCardState();
}

class _BankPreapprovedLoanCardState extends State<BankPreapprovedLoanCard> {
  late Money _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.quickAmount ?? widget.maxAmount;
  }

  @override
  void didUpdateWidget(BankPreapprovedLoanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_options.contains(_selected)) {
      _selected = widget.quickAmount ?? widget.maxAmount;
    }
  }

  /// Quick-pick amounts: 25%, 50%, and 100% of the maximum, plus
  /// [BankPreapprovedLoanCard.quickAmount] when given, sorted ascending.
  List<Money> get _options {
    final maxValue = widget.maxAmount.amount.toDouble();
    final currency = widget.maxAmount.currencyCode;
    final options = <Money>[
      Money.fromDouble(maxValue * 0.25, currency),
      Money.fromDouble(maxValue * 0.5, currency),
      widget.maxAmount,
    ];
    final quick = widget.quickAmount;
    if (quick != null && !options.contains(quick)) {
      options.add(quick);
    }
    options.sort((a, b) => a.amount.compareTo(b.amount));
    return options;
  }

  /// Standard amortization: P * r / (1 - (1+r)^-n), degrading to P/n at
  /// a zero rate.
  double get _monthlyPayment {
    final principal = _selected.amount.toDouble();
    final r = widget.annualRate / 12;
    if (r <= 0) return principal / widget.maxMonths;
    return principal * r / (1 - math.pow(1 + r, -widget.maxMonths));
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final expires = widget.offerExpires;
    var expired = false;
    String? expiryText;
    if (expires != null) {
      final remaining = expires.difference(DateTime.now());
      if (remaining.isNegative) {
        expired = true;
        expiryText = widget.expiredLabel;
      } else if (remaining.inDays == 0) {
        expiryText = widget.expiresTodayLabel;
      } else if (remaining.inDays <= 14) {
        expiryText = widget.expiresTemplate.replaceAll(
          '{n}',
          scope.numeralStyle.convert('${remaining.inDays}'),
        );
      }
    }

    final rateName = widget.rateLabel ??
        (scope.islamicFinanceMode ? widget.profitRateLabel : widget.aprLabel);
    final ratePercent = BankPreapprovedLoanCard.formatAnnualRate(
      widget.annualRate,
      numeralStyle: scope.numeralStyle,
    );
    final tenorText = widget.tenorTemplate
        .replaceAll('{n}', scope.numeralStyle.convert('${widget.maxMonths}'));
    final microline = '$rateName $ratePercent · $tenorText';

    final monthly =
        Money.fromDouble(_monthlyPayment, widget.maxAmount.currencyCode);

    final gradient = widget.gradient ??
        theme.accentGradient ??
        LinearGradient(colors: [theme.primary, theme.primaryVariant]);
    final accent = widget.accentColor ?? theme.primary;
    final resolvedRadius = widget.radius ?? theme.cardRadius;

    // Brightness of the painted surface drives the hairline; brightness
    // of the theme background drives the resting shadow (matching the
    // kit-wide BankAccountCard treatment).
    final resolvedSurface = widget.backgroundColor ?? theme.surface;
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(resolvedSurface);
    final backgroundBrightness =
        ThemeData.estimateBrightnessForColor(theme.background);

    // On dark surfaces a hairline separates the card where the shadow
    // alone cannot; light surfaces carry an invisible border of the same
    // width so geometry stays identical across brightness.
    final resolvedBorder = widget.border ??
        Border.all(
          color: surfaceBrightness == Brightness.dark
              ? BankTokens.hairlineColor(theme.onSurface, surfaceBrightness)
              : theme.onSurface.withValues(alpha: 0),
          // Matches Border.all's default today; keep the token as the
          // source of truth for hairline geometry.
          // ignore: avoid_redundant_argument_values
          width: BankTokens.hairlineWidth,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedSurface,
        borderRadius: resolvedRadius,
        border: resolvedBorder,
        boxShadow:
            widget.shadow ?? BankTokens.shadowHeroFor(backgroundBrightness),
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header ?? _header(theme, gradient),
            Padding(
              padding:
                  widget.padding ?? const EdgeInsets.all(BankTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.upToLabel,
                    style: BankTokens.labelMedium
                        .copyWith(color: theme.onSurfaceVariant),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  BankBalanceText(
                    money: widget.maxAmount,
                    size: BankBalanceSize.hero,
                    style: theme.numeralHero
                        .copyWith(
                          color: theme.onSurface,
                          fontFamily: theme.fontFamily,
                        )
                        .merge(widget.amountStyle),
                  ),
                  const SizedBox(height: BankTokens.space3),
                  Wrap(
                    spacing: BankTokens.space2,
                    runSpacing: BankTokens.space2,
                    children: [
                      for (final option in _options)
                        _amountChip(
                          option: option,
                          selected: option == _selected,
                          enabled: !expired,
                          theme: theme,
                          scope: scope,
                        ),
                    ],
                  ),
                  const SizedBox(height: BankTokens.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.monthlyLabel,
                          style: BankTokens.labelMedium
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: BankTokens.space2),
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : widget.animationDuration ??
                                BankTokens.durationFast,
                        switchInCurve:
                            widget.animationCurve ?? BankTokens.curveStandard,
                        switchOutCurve:
                            widget.animationCurve ?? BankTokens.curveStandard,
                        child: BankBalanceText(
                          key: ValueKey<String>(monthly.amount.toString()),
                          money: monthly,
                          size: BankBalanceSize.medium,
                          style: theme.numeralMedium
                              .copyWith(
                                color: accent,
                                fontFamily: theme.fontFamily,
                              )
                              .merge(widget.monthlyStyle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BankTokens.space2),
                  Wrap(
                    spacing: BankTokens.space2,
                    runSpacing: BankTokens.space1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        microline,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant),
                      ),
                      if (expiryText != null)
                        _expiryChip(expiryText, expired: expired, theme: theme),
                    ],
                  ),
                  const SizedBox(height: BankTokens.space4),
                  SizedBox(
                    width: double.infinity,
                    height: BankTokens.space12,
                    child: FilledButton(
                      onPressed:
                          expired ? null : () => widget.onContinue(_selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: theme.onPrimary,
                        textStyle: bankButtonTextStyle(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: theme.buttonRadius,
                        ),
                      ),
                      child: Text(widget.ctaLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gradient strip carrying the title and the offer badge.
  Widget _header(BankThemeData theme, Gradient gradient) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: BankTokens.headlineSmall
                    .copyWith(
                      color: theme.onPrimary,
                      fontFamily: theme.fontFamily,
                    )
                    .merge(widget.titleStyle),
              ),
            ),
            const SizedBox(width: BankTokens.space2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.onPrimary.withValues(alpha: 0.16),
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
                    Icon(
                      widget.badgeIcon ?? BankIcons.success,
                      size: 14,
                      color: theme.onPrimary,
                    ),
                    const SizedBox(width: BankTokens.space1),
                    Text(
                      widget.badgeLabel,
                      style: BankTokens.labelSmall
                          .copyWith(color: theme.onPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountChip({
    required Money option,
    required bool selected,
    required bool enabled,
    required BankThemeData theme,
    required BankUiScopeData scope,
  }) {
    final formatted = BankMoneyFormatter.format(
      amount: option.amount,
      currencyCode: option.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final semanticLabel =
        scope.privacyEnabled ? scope.strings.balanceHidden : formatted;
    final accent = widget.accentColor ?? theme.primary;
    final background = selected && enabled ? accent : theme.surfaceVariant;
    final foreground = !enabled
        ? theme.onSurfaceVariant
        : selected
            ? theme.onPrimary
            : theme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: theme.chipRadius,
        child: InkWell(
          borderRadius: theme.chipRadius,
          onTap: enabled ? () => setState(() => _selected = option) : null,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: BankTokens.minTapTarget),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: BankTokens.space3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BankBalanceText(
                    money: option,
                    size: BankBalanceSize.small,
                    compact: true,
                    style: BankTokens.numeralSmall.copyWith(
                      color: foreground,
                      fontFamily: theme.fontFamily,
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

  Widget _expiryChip(
    String text, {
    required bool expired,
    required BankThemeData theme,
  }) {
    final color = expired ? BankTokens.danger : BankTokens.pending;
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
            Icon(
              widget.expiryIcon ?? BankIcons.schedule,
              size: 14,
              color: color,
            ),
            const SizedBox(width: BankTokens.space1),
            Text(
              text,
              style: BankTokens.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
