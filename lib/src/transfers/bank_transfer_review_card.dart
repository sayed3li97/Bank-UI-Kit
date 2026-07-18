import 'package:flutter/material.dart';

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

  /// Overrides the card elevation. Defaults to the theme elevationLow.
  final double? elevation;

  /// Replaces the beneficiary header row. Defaults to the built-in
  /// avatar-name-account header.
  final Widget? header;

  /// Merged over the beneficiary name style
  /// (BankTokens.headlineSmall in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the account details style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over each row label style
  /// (BankTokens.bodyMedium in onSurfaceVariant).
  final TextStyle? labelStyle;

  /// Merged over each plain row value style
  /// (BankTokens.bodyMedium, w500).
  final TextStyle? valueStyle;

  /// Merged over the highlighted money styles of the amount and
  /// "They receive" rows (theme numeralMedium).
  final TextStyle? amountStyle;

  /// Label of the amount row. Defaults to `'Amount'`.
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

  /// Overrides the color of the free fee value. Defaults to
  /// BankTokens.positiveBalance.
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
    this.header,
    this.titleStyle,
    this.subtitleStyle,
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

    final card = Card(
      elevation: elevation ?? bankTheme.elevationLow,
      color: backgroundColor ?? bankTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius ?? bankTheme.cardRadius,
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
                  verifiedIcon: verifiedIcon ?? Icons.verified_outlined,
                  accentColor: accentColor ?? bankTheme.primary,
                ),
            const SizedBox(height: BankTokens.space4),
            Divider(color: bankTheme.outline.withValues(alpha: 0.4), height: 1),
            const SizedBox(height: BankTokens.space4),
            // ----------------------------------------------------------------
            // Amount row
            // ----------------------------------------------------------------
            _ReviewRow(
              label: amountLabel,
              value: _formatMoney(context, amount, scope),
              bankTheme: bankTheme,
              valueStyle: bankTheme.numeralMedium.copyWith(
                color: bankTheme.onSurface,
              ),
              labelStyle: labelStyle,
              valueOverride: amountStyle,
            ),
            const SizedBox(height: BankTokens.space3),
            // ----------------------------------------------------------------
            // Fee row
            // ----------------------------------------------------------------
            _ReviewRow(
              label: feeLabel,
              value: _isFree ? freeLabel : _formatMoney(context, fee!, scope),
              bankTheme: bankTheme,
              valueColor: _isFree
                  ? (freeColor ?? BankTokens.positiveBalance)
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
              Divider(
                color: bankTheme.outline.withValues(alpha: 0.4),
                height: 1,
              ),
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
    required this.verifiedIcon,
    required this.accentColor,
  });

  final BankBeneficiary beneficiary;
  final String initials;
  final BankThemeData bankTheme;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
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
                      size: 14,
                      color: accentColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: BankTokens.space1),
              Text(
                [
                  beneficiary.maskedAccount,
                  if (beneficiary.bankName != null) beneficiary.bankName!,
                ].join(' · '),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BankTokens.bodyMedium
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
