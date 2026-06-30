import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Shareable receipt layout. The package renders the view;
/// the host app wires up PDF generation or share-sheet logic.
///
/// Wrap in a [RepaintBoundary] and call `toImage()` for PDF export.
class BankReceiptView extends StatelessWidget {
  final Transaction transaction;
  final String? fromAccountName;
  final String? toName;
  final String? referenceNumber;
  final VoidCallback? onExport;

  /// Optional brand logo shown at the top of the receipt.
  final Widget? logoSlot;

  const BankReceiptView({
    required this.transaction,
    super.key,
    this.fromAccountName,
    this.toName,
    this.referenceNumber,
    this.onExport,
    this.logoSlot,
  });

  String _categoryLabel(TransactionCategory cat) => switch (cat) {
        TransactionCategory.groceries => 'Groceries',
        TransactionCategory.dining => 'Dining',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.health => 'Health',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.travel => 'Travel',
        TransactionCategory.education => 'Education',
        TransactionCategory.subscription => 'Subscription',
        TransactionCategory.transfer => 'Transfer',
        TransactionCategory.income => 'Income',
        TransactionCategory.investment => 'Investment',
        TransactionCategory.creditPayment => 'Credit Payment',
        TransactionCategory.other => 'Other',
      };

  String _statusLabel(TransactionStatus status, BankUiScopeData scope) =>
      switch (status) {
        TransactionStatus.pending => scope.strings.pending,
        TransactionStatus.cleared => scope.strings.cleared,
        TransactionStatus.declined => scope.strings.declined,
        TransactionStatus.refunded => scope.strings.refunded,
        TransactionStatus.scheduled => scope.strings.scheduled,
      };

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final isCredit = !transaction.amount.isNegative;
    final formattedAmount = BankMoneyFormatter.format(
      amount: transaction.amount.amount,
      currencyCode: transaction.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    final amountColor =
        isCredit ? bankTheme.positiveBalance : bankTheme.onSurface;

    return Semantics(
      label: 'Receipt for ${transaction.merchantName}, $formattedAmount',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- Receipt header ----
            Padding(
              padding: const EdgeInsets.all(BankTokens.space6),
              child: Column(
                children: [
                  if (logoSlot != null) ...[
                    logoSlot!,
                    const SizedBox(height: BankTokens.space3),
                  ],
                  Text(
                    'Receipt',
                    style: BankTokens.headlineMedium.copyWith(
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    BankDateFormatter.formatLong(transaction.settledAt),
                    style: BankTokens.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: BankTokens.space6),
                  // Merchant name
                  Text(
                    transaction.merchantName,
                    style: BankTokens.labelLarge.copyWith(
                      color: const Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: BankTokens.space2),
                  // Amount — hero display
                  Text(
                    formattedAmount,
                    style: BankTokens.numeralHero.copyWith(
                      color: amountColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ---- Dashed divider (perforated edge effect) ----
            const _DashedDivider(color: Color(0xFFE5E7EB)),

            // ---- Receipt body ----
            Padding(
              padding: const EdgeInsets.all(BankTokens.space6),
              child: Column(
                children: [
                  if (fromAccountName != null)
                    _ReceiptRow(
                      label: 'From',
                      value: fromAccountName!,
                    ),
                  if (toName != null)
                    _ReceiptRow(
                      label: 'To',
                      value: toName!,
                    ),
                  if (referenceNumber != null)
                    _ReceiptRow(
                      label: 'Reference',
                      value: referenceNumber!,
                    ),
                  _ReceiptRow(
                    label: 'Category',
                    value: _categoryLabel(transaction.category),
                  ),
                  _ReceiptRow(
                    label: 'Status',
                    value: _statusLabel(transaction.status, scope),
                  ),
                  if (transaction.reference != null)
                    _ReceiptRow(
                      label: 'Transaction ID',
                      value: transaction.reference!,
                    ),
                ],
              ),
            ),

            // ---- Dashed divider ----
            const _DashedDivider(color: Color(0xFFE5E7EB)),

            // ---- QR code placeholder ----
            Padding(
              padding: const EdgeInsets.all(BankTokens.space6),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(BankTokens.radiusSmall),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          BankIcons.scan,
                          size: 32,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          'QR code',
                          style: BankTokens.bodySmall.copyWith(
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onExport != null) ...[
                    const SizedBox(height: BankTokens.space4),
                    Semantics(
                      button: true,
                      label: 'Export receipt',
                      child: FilledButton.icon(
                        onPressed: onExport,
                        icon: Icon(
                          BankIcons.share,
                          color: bankTheme.onPrimary,
                          size: 18,
                        ),
                        label: Text(
                          'Export Receipt',
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: bankTheme.primary,
                          minimumSize: const Size(
                            double.infinity,
                            BankTokens.minTapTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: bankTheme.buttonRadius,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BankTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: BankTokens.bodySmall.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          Expanded(
            child: Text(
              value,
              style: BankTokens.bodyMedium.copyWith(
                color: const Color(0xFF111111),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 8;
    const double dashGap = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
