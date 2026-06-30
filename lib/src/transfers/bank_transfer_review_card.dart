import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/exchange_rate.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

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

  /// Optional widget rendered below the summary rows — use for disclaimers,
  /// T&C links, or exchange-rate freshness notes.
  final Widget? additionalInfo;

  const BankTransferReviewCard({
    super.key,
    required this.amount,
    required this.beneficiary,
    this.fee,
    this.exchangeRate,
    this.estimatedArrival,
    this.isScheduled = false,
    this.scheduledDate,
    this.additionalInfo,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isFree => fee == null || fee!.isZero;

  String _formatMoney(Money m, BankUiScopeData scope) =>
      BankMoneyFormatter.format(
        amount: m.amount,
        currencyCode: m.currencyCode,
        numeralStyle: scope.numeralStyle,
      );

  String _formatArrival(BankUiScopeData scope) {
    if (isScheduled && scheduledDate != null) {
      return 'Scheduled: ${BankDateFormatter.formatFull(scheduledDate!)}';
    }
    return estimatedArrival ?? '—';
  }

  String _formatRate() {
    if (exchangeRate == null) return '';
    final rate = exchangeRate!.rate.toDouble();
    // Show 4 decimal places for the rate.
    return '1 ${exchangeRate!.fromCurrency} = ${rate.toStringAsFixed(4)} ${exchangeRate!.toCurrency}';
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

    return Card(
      elevation: bankTheme.elevationLow,
      color: bankTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: bankTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----------------------------------------------------------------
            // Beneficiary header
            // ----------------------------------------------------------------
            _BeneficiaryHeader(
              beneficiary: beneficiary,
              initials: _initials,
              bankTheme: bankTheme,
            ),
            const SizedBox(height: BankTokens.space4),
            Divider(color: bankTheme.outline.withOpacity(0.4), height: 1),
            const SizedBox(height: BankTokens.space4),
            // ----------------------------------------------------------------
            // Amount row
            // ----------------------------------------------------------------
            _ReviewRow(
              label: 'Amount',
              value: _formatMoney(amount, scope),
              bankTheme: bankTheme,
              valueStyle: bankTheme.numeralMedium.copyWith(
                color: bankTheme.onSurface,
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            // ----------------------------------------------------------------
            // Fee row
            // ----------------------------------------------------------------
            _ReviewRow(
              label: 'Fee',
              value: _isFree ? 'Free' : _formatMoney(fee!, scope),
              bankTheme: bankTheme,
              valueColor:
                  _isFree ? BankTokens.positiveBalance : bankTheme.onSurface,
            ),
            // ----------------------------------------------------------------
            // Exchange rate rows (international transfers)
            // ----------------------------------------------------------------
            if (hasExchangeRate) ...[
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: 'Exchange Rate',
                value: _formatRate(),
                bankTheme: bankTheme,
              ),
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: 'You send',
                value: _formatMoney(amount, scope),
                bankTheme: bankTheme,
              ),
              const SizedBox(height: BankTokens.space3),
              _ReviewRow(
                label: 'They receive',
                value: _formatMoney(convertedAmount!, scope),
                bankTheme: bankTheme,
                valueStyle: bankTheme.numeralMedium.copyWith(
                  color: bankTheme.positiveBalance,
                ),
              ),
            ],
            // ----------------------------------------------------------------
            // Arrival row
            // ----------------------------------------------------------------
            const SizedBox(height: BankTokens.space3),
            _ReviewRow(
              label: 'Arrives',
              value: _formatArrival(scope),
              bankTheme: bankTheme,
            ),
            // ----------------------------------------------------------------
            // Additional info slot
            // ----------------------------------------------------------------
            if (additionalInfo != null) ...[
              const SizedBox(height: BankTokens.space4),
              Divider(color: bankTheme.outline.withOpacity(0.4), height: 1),
              const SizedBox(height: BankTokens.space4),
              additionalInfo!,
            ],
          ],
        ),
      ),
    );
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
  });

  final BankBeneficiary beneficiary;
  final String initials;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        beneficiary.avatarUrl != null
            ? CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(beneficiary.avatarUrl!),
                backgroundColor: bankTheme.surfaceVariant,
              )
            : CircleAvatar(
                radius: 24,
                backgroundColor: bankTheme.primary.withOpacity(0.15),
                child: Text(
                  initials,
                  style: BankTokens.labelLarge.copyWith(
                    color: bankTheme.primary,
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
                      style: BankTokens.headlineSmall.copyWith(
                        color: bankTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (beneficiary.isVerified) ...[
                    const SizedBox(width: BankTokens.space1),
                    Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: bankTheme.primary,
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
                style: BankTokens.bodySmall.copyWith(
                  color: bankTheme.onSurfaceVariant,
                ),
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
  });

  final String label;
  final String value;
  final BankThemeData bankTheme;
  final TextStyle? valueStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final resolvedValueStyle = valueStyle ??
        BankTokens.bodyMedium.copyWith(
          color: valueColor ?? bankTheme.onSurface,
          fontWeight: FontWeight.w500,
        );

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BankTokens.bodyMedium.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
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
