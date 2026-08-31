import 'package:flutter/material.dart';

import '../../src/common/bank_surface_depth.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';

// ---------------------------------------------------------------------------
// BankTransferReviewCard
// ---------------------------------------------------------------------------

/// Confirm-before-send summary card shown to the user before they authorise a
/// transfer.
///
/// Displays the beneficiary, amount, fee, exchange rate (for international
/// transfers), estimated arrival time, and an optional [additionalInfo] slot.
///
/// ## Hierarchy
///
/// The card carries three tiers, because a review screen has exactly one
/// question to answer — *am I sending the right money to the right place?*
///
/// 1. **The amount** is the hero: a [BankThemeData.numeralLarge] figure under
///    a caps micro-label, not one more label/value row. Set at the same
///    optical weight as "Arrives", it forces the customer to read the whole
///    card to find the number they came to check.
/// 2. **The destination mask** is a verification affordance, so it is set in
///    tabular numerals at body size in the full [BankThemeData.onSurface]
///    ink. A masked account nobody can read verifies nothing; this is the
///    one caption-sized string on the card that must never be caption-sized.
/// 3. **Everything else** — fee, rate, arrival — recedes to small muted
///    labels against body-size values.
///
/// ```dart
/// BankTransferReviewCard(
///   amount: Money.fromDouble(500, 'GBP'),
///   beneficiary: selected,
///   fee: Money.fromDouble(0, 'GBP'),
///   estimatedArrival: 'Within 2 hours',
/// )
/// ```
class BankTransferReviewCard extends StatelessWidget {
  /// The amount being sent.
  final Money amount;

  /// The beneficiary receiving the transfer.
  final BankBeneficiary beneficiary;

  /// Transfer fee. Pass `null` or a zero [Money] to show "Free".
  final Money? fee;

  /// Exchange rate for international transfers. When non-null, additional
  /// "You send" and "They receive" rows are rendered below the rate row.
  final ExchangeRate? exchangeRate;

  /// Human-readable estimated arrival string, e.g. `'Within 2 hours'`.
  /// Ignored when [isScheduled] is `true`.
  final String? estimatedArrival;

  /// When `true`, the arrival row displays the scheduled date instead of
  /// [estimatedArrival].
  final bool isScheduled;

  /// The date the transfer is scheduled for. Only used when [isScheduled] is
  /// `true`.
  final DateTime? scheduledDate;

  /// Optional widget rendered below the summary rows: use for disclaimers,
  /// T&C links, or exchange-rate freshness notes.
  final Widget? additionalInfo;

  /// Overrides the card content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card background color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Legacy depth opt-out. The card renders the kit shadow language
  /// ([BankTokens.shadowCardFor] of the theme background brightness) instead
  /// of Material elevation; pass `0` — or use a theme whose `elevationLow`
  /// is `0`, such as Voltage — to flatten the card to hairline-only depth.
  final double? elevation;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Replaces the beneficiary header row. Defaults to the built-in
  /// avatar-name-account header.
  final Widget? header;

  /// Merged over the beneficiary name style
  /// (BankTokens.headlineSmall in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the bank-name line under the account mask
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the account-mask line (theme numeralSmall in onSurface).
  ///
  /// Separate from [subtitleStyle] because the mask and the bank name are
  /// no longer the same tier: the mask is the string the customer checks
  /// the transfer against, the bank name is context.
  final TextStyle? maskStyle;

  /// Merged over each supporting row's label style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? labelStyle;

  /// Merged over each plain row value style
  /// (BankTokens.bodyMedium, w500).
  final TextStyle? valueStyle;

  /// Merged over the highlighted money styles of the hero amount (theme
  /// numeralLarge) and the "They receive" row (theme numeralMedium).
  final TextStyle? amountStyle;

  /// Label of the hero amount block, rendered as an ALL-CAPS micro-label.
  /// Defaults to `'Amount'`.
  ///
  /// Pass it in sentence case as written in the host's copy deck; the card
  /// applies the casing, the way it applies the type style.
  final String amountLabel;

  /// Label of the fee row. Defaults to `'Fee'`.
  final String feeLabel;

  /// Value shown when the fee is zero or null. Defaults to `'Free'`.
  final String freeLabel;

  /// Label of the exchange-rate row. Defaults to `'Exchange Rate'`.
  final String exchangeRateLabel;

  /// Label of the sent-amount row. Defaults to `'You send'`.
  final String youSendLabel;

  /// Label of the converted-amount row. Defaults to `'They receive'`.
  final String theyReceiveLabel;

  /// Label of the arrival row. Defaults to `'Arrives'`.
  final String arrivesLabel;

  /// Prefix of the scheduled arrival value. Defaults to `'Scheduled:'`.
  final String scheduledPrefix;

  /// Arrival value when no arrival information is available. Defaults to
  /// `'-'`.
  final String noArrivalLabel;

  /// Overrides the verified-beneficiary glyph. Defaults to
  /// [Icons.verified_outlined].
  final IconData? verifiedIcon;

  /// Overrides the accent of the avatar fallback and verified badge.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the color of the free fee value. Defaults to the theme's
  /// [BankThemeData.positiveBalance], which is brightness-corrected per
  /// preset — the raw token is a light-surface green.
  final Color? freeColor;

  /// When non-null, wraps the card in a [Semantics] label. Defaults to no
  /// extra semantics node.
  final String? semanticLabel;

  const BankTransferReviewCard({
    required this.amount,
    required this.beneficiary,
    super.key,
    this.fee,
    this.exchangeRate,
    this.estimatedArrival,
    this.isScheduled = false,
    this.scheduledDate,
    this.additionalInfo,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.elevation,
    this.shadow,
    this.border,
    this.header,
    this.titleStyle,
    this.subtitleStyle,
    this.maskStyle,
    this.labelStyle,
    this.valueStyle,
    this.amountStyle,
    this.amountLabel = 'Amount',
    this.feeLabel = 'Fee',
    this.freeLabel = 'Free',
    this.exchangeRateLabel = 'Exchange Rate',
    this.youSendLabel = 'You send',
    this.theyReceiveLabel = 'They receive',
    this.arrivesLabel = 'Arrives',
    this.scheduledPrefix = 'Scheduled:',
    this.noArrivalLabel = '-',
    this.verifiedIcon,
    this.accentColor,
    this.freeColor,
    this.semanticLabel,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isFree => fee == null || fee!.isZero;

  /// Formats [m] for display, substituting the scope's masked label when
  /// privacy mode is enabled so no monetary value is rendered or announced.
  String _formatMoney(BuildContext context, Money m, BankUiScopeData scope) =>
      scope.privacyEnabled
          ? scope.strings.balanceHidden
          : BankMoneyFormatter.format(
              amount: m.amount,
              currencyCode: m.currencyCode,
              locale: context.bankLocale,
              numeralStyle: scope.numeralStyle,
            );

  String _formatArrival(BankUiScopeData scope) {
    if (isScheduled && scheduledDate != null) {
      return '$scheduledPrefix ${BankDateFormatter.formatFull(scheduledDate!)}';
    }
    return estimatedArrival ?? noArrivalLabel;
  }

  String _formatRate() {
    if (exchangeRate == null) return '';
    final rate = exchangeRate!.rate.toDouble().toStringAsFixed(4);
    final from = exchangeRate!.fromCurrency;
    final to = exchangeRate!.toCurrency;
    // Show 4 decimal places for the rate.
    return '1 $from = $rate $to';
  }

  String get _initials {
    final parts = beneficiary.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final hasExchangeRate = exchangeRate != null;
    final convertedAmount =
        hasExchangeRate ? exchangeRate!.convert(amount) : null;
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);

    // One depth language for every card: token shadows resolved against the
    // theme background brightness, with the dark-surface hairline. Themes
    // that declare flat depth (elevationLow == 0, e.g. Voltage) — or an
    // explicit `elevation: 0` — keep hairline-only separation. The margin
    // preserves the footprint of the Material [Card] this replaces.
    final depth = BankSurfaceDepth.resolve(
      bankTheme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
      tier: (elevation ?? bankTheme.elevationLow) <= 0
          ? BankSurfaceDepthTier.flat
          : BankSurfaceDepthTier.card,
    );

    // The kit's hairline, derived from the ambient ink, rather than an
    // ad-hoc alpha on the outline: it holds the same perceived weight on a
    // light card and a dark one.
    final hairline = BankTokens.hairlineColor(
      bankTheme.onSurface,
      ThemeData.estimateBrightnessForColor(
        backgroundColor ?? bankTheme.surface,
      ),
    );

    final card = Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor ?? bankTheme.surface,
        borderRadius: radius ?? bankTheme.cardRadius,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----------------------------------------------------------------
            // Beneficiary header
            // ----------------------------------------------------------------
            header ??
                _BeneficiaryHeader(
                  beneficiary: beneficiary,
                  initials: _initials,
                  bankTheme: bankTheme,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                  maskStyle: maskStyle,
                  verifiedIcon: verifiedIcon ?? Icons.verified_outlined,
                  accentColor: accentColor ?? bankTheme.primary,
                ),
            const SizedBox(height: BankTokens.space4),
            Divider(color: hairline, height: BankTokens.hairlineWidth),
            const SizedBox(height: BankTokens.space4),
            // ----------------------------------------------------------------
            // Hero amount — the one figure the customer opened this card for
            // ----------------------------------------------------------------
            _HeroAmount(
              label: amountLabel,
              value: _formatMoney(context, amount, scope),
              bankTheme: bankTheme,
              labelStyle: labelStyle,
              valueOverride: amountStyle,
            ),
            const SizedBox(height: BankTokens.space4),
            // ----------------------------------------------------------------
            // Fee row
            // ----------------------------------------------------------------
            _ReviewRow(
              label: feeLabel,
              value: _isFree ? freeLabel : _formatMoney(context, fee!, scope),
              bankTheme: bankTheme,
              valueColor: _isFree
                  ? (freeColor ?? bankTheme.positiveBalance)
                  : bankTheme.onSurface,
              labelStyle: labelStyle,
              valueOverride: valueStyle,
            ),
            // ----------------------------------------------------------------
            // Exchange rate rows (international transfers)
            // ----------------------------------------------------------------
            if (hasExchangeRate) ...[
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: exchangeRateLabel,
                value: _formatRate(),
                bankTheme: bankTheme,
                labelStyle: labelStyle,
                valueOverride: valueStyle,
              ),
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: youSendLabel,
                value: _formatMoney(context, amount, scope),
                bankTheme: bankTheme,
                labelStyle: labelStyle,
                valueOverride: valueStyle,
              ),
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: theyReceiveLabel,
                value: _formatMoney(context, convertedAmount!, scope),
                bankTheme: bankTheme,
                valueStyle: bankTheme.numeralMedium.copyWith(
                  color: bankTheme.positiveBalance,
                ),
                labelStyle: labelStyle,
                valueOverride: amountStyle,
              ),
            ],
            // ----------------------------------------------------------------
            // Arrival row
            // ----------------------------------------------------------------
            const SizedBox(height: BankTokens.space3),
            _ReviewRow(
              label: arrivesLabel,
              value: _formatArrival(scope),
              bankTheme: bankTheme,
              labelStyle: labelStyle,
              valueOverride: valueStyle,
            ),
            // ----------------------------------------------------------------
            // Additional info slot
            // ----------------------------------------------------------------
            if (additionalInfo != null) ...[
              const SizedBox(height: BankTokens.space4),
              Divider(color: hairline, height: BankTokens.hairlineWidth),
              const SizedBox(height: BankTokens.space4),
              additionalInfo!,
            ],
          ],
        ),
      ),
    );

    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, child: card);
  }
}

// ---------------------------------------------------------------------------
// Beneficiary header
// ---------------------------------------------------------------------------

class _BeneficiaryHeader extends StatelessWidget {
  const _BeneficiaryHeader({
    required this.beneficiary,
    required this.initials,
    required this.bankTheme,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.maskStyle,
    required this.verifiedIcon,
    required this.accentColor,
  });

  final BankBeneficiary beneficiary;
  final String initials;
  final BankThemeData bankTheme;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? maskStyle;
  final IconData verifiedIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        if (beneficiary.avatarUrl != null)
          CircleAvatar(
            radius: 24,
            backgroundImage: BankUiScope.imageProviderFor(
              context,
              beneficiary.avatarUrl!,
            ),
            backgroundColor: bankTheme.surfaceVariant,
          )
        else
          CircleAvatar(
            radius: 24,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: BankTokens.labelLarge.copyWith(
                color: accentColor,
              ),
            ),
          ),
        const SizedBox(width: BankTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      beneficiary.name,
                      style: BankTokens.headlineSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(titleStyle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (beneficiary.isVerified) ...[
                    const SizedBox(width: BankTokens.space1),
                    Icon(
                      verifiedIcon,
                      size: BankTokens.iconXSmall,
                      color: accentColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: BankTokens.space1),
              // The mask gets its own line and full ink: joined onto the
              // bank name in caption grey it was the smallest thing on a
              // card whose whole job is letting the customer verify it.
              // Tabular numerals keep the digit groups from shifting
              // between one beneficiary and the next.
              Text(
                beneficiary.maskedAccount,
                style: bankTheme.numeralSmall
                    .copyWith(color: bankTheme.onSurface)
                    .merge(maskStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (beneficiary.bankName != null)
                Text(
                  beneficiary.bankName!,
                  style: BankTokens.bodySmall
                      .copyWith(color: bankTheme.onSurfaceVariant)
                      .merge(subtitleStyle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero amount
// ---------------------------------------------------------------------------

/// The transfer amount, set as the card's single hero figure: a caps
/// micro-label above a large numeral, left-aligned so the digits start on
/// the reading edge in both directions rather than hugging a trailing edge
/// the eye has to hunt for.
class _HeroAmount extends StatelessWidget {
  const _HeroAmount({
    required this.label,
    required this.value,
    required this.bankTheme,
    this.labelStyle,
    this.valueOverride,
  });

  final String label;
  final String value;
  final BankThemeData bankTheme;
  final TextStyle? labelStyle;
  final TextStyle? valueOverride;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Announced as the same label/value pair as the rows below it, so
      // the visual promotion does not change what a screen reader hears.
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: BankTokens.captionCaps
                .copyWith(color: bankTheme.onSurfaceVariant)
                .merge(labelStyle),
          ),
          const SizedBox(height: BankTokens.space1),
          Text(
            value,
            style: bankTheme.numeralLarge
                .copyWith(color: bankTheme.onSurface)
                .merge(valueOverride),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review row
// ---------------------------------------------------------------------------

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.bankTheme,
    this.valueStyle,
    this.valueColor,
    this.labelStyle,
    this.valueOverride,
  });

  final String label;
  final String value;
  final BankThemeData bankTheme;
  final TextStyle? valueStyle;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueOverride;

  @override
  Widget build(BuildContext context) {
    final resolvedValueStyle = (valueStyle ??
            BankTokens.bodyMedium.copyWith(
              color: valueColor ?? bankTheme.onSurface,
              fontWeight: FontWeight.w500,
            ))
        .merge(valueOverride);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // Label and value are now different sizes, so aligning their tops
        // would leave the two strings visibly off the same line. Baseline
        // alignment keeps the row reading as one line of text.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Supporting labels sit a step below their values: with both at
          // body size the fee row read as loudly as the amount.
          Text(
            label,
            style: BankTokens.bodySmall
                .copyWith(color: bankTheme.onSurfaceVariant)
                .merge(labelStyle),
          ),
          const SizedBox(width: BankTokens.space4),
          Flexible(
            child: Text(
              value,
              style: resolvedValueStyle,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
