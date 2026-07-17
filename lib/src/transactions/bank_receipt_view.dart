import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';

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

  /// Overrides the padding of each receipt section. Defaults to
  /// [BankTokens.space6] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the receipt corner radius. Defaults to
  /// [BankTokens.radiusMedium].
  final BorderRadius? radius;

  /// Overrides the paper color. Defaults to white.
  final Color? backgroundColor;

  /// Overrides the drop shadow. Defaults to a soft black shadow;
  /// pass const [] to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the dashed divider color. Defaults to a light grey.
  final Color? dividerColor;

  /// Overrides the export button background. Defaults to theme primary.
  final Color? accentColor;

  /// Merged over the receipt heading style ([BankTokens.headlineMedium]).
  final TextStyle? titleStyle;

  /// Merged over the date line style ([BankTokens.bodySmall]).
  final TextStyle? subtitleStyle;

  /// Merged over the merchant name style ([BankTokens.labelLarge]).
  final TextStyle? merchantStyle;

  /// Merged over the hero amount style ([BankTokens.numeralHero]).
  final TextStyle? amountStyle;

  /// Merged over the detail row label style ([BankTokens.bodySmall]).
  final TextStyle? rowLabelStyle;

  /// Merged over the detail row value style ([BankTokens.bodyMedium]).
  final TextStyle? rowValueStyle;

  /// Overrides the receipt heading. Defaults to 'Receipt'.
  final String titleText;

  /// Overrides the sender row label. Defaults to 'From'.
  final String fromLabel;

  /// Overrides the recipient row label. Defaults to 'To'.
  final String toLabel;

  /// Overrides the reference row label. Defaults to 'Reference'.
  final String referenceLabel;

  /// Overrides the category row label. Defaults to 'Category'.
  final String categoryLabel;

  /// Overrides the status row label. Defaults to 'Status'.
  final String statusRowLabel;

  /// Overrides the transaction id row label. Defaults to
  /// 'Transaction ID'.
  final String transactionIdLabel;

  /// Overrides the QR placeholder caption. Defaults to 'QR code'.
  final String qrLabel;

  /// Overrides the export button text. Defaults to 'Export Receipt'.
  final String exportLabel;

  /// Overrides the export button semantics. Defaults to
  /// 'Export receipt'.
  final String exportSemanticLabel;

  /// Overrides the receipt semantics label. Defaults to
  /// 'Receipt for merchant, amount'.
  final String? semanticLabel;

  /// Overrides the category display name. Defaults to built-in
  /// English labels.
  final String Function(TransactionCategory)? categoryLabelBuilder;

  /// Overrides the QR placeholder glyph. Defaults to [BankIcons.scan].
  final IconData? qrIcon;

  /// Overrides the export button glyph. Defaults to [BankIcons.share].
  final IconData? exportIcon;

  const BankReceiptView({
    required this.transaction,
    super.key,
    this.fromAccountName,
    this.toName,
    this.referenceNumber,
    this.onExport,
    this.logoSlot,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.dividerColor,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.merchantStyle,
    this.amountStyle,
    this.rowLabelStyle,
    this.rowValueStyle,
    this.titleText = 'Receipt',
    this.fromLabel = 'From',
    this.toLabel = 'To',
    this.referenceLabel = 'Reference',
    this.categoryLabel = 'Category',
    this.statusRowLabel = 'Status',
    this.transactionIdLabel = 'Transaction ID',
    this.qrLabel = 'QR code',
    this.exportLabel = 'Export Receipt',
    this.exportSemanticLabel = 'Export receipt',
    this.semanticLabel,
    this.categoryLabelBuilder,
    this.qrIcon,
    this.exportIcon,
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
      locale: context.bankLocale,
      numeralStyle: scope.numeralStyle,
      showSign: isCredit,
    );

    final amountColor =
        isCredit ? bankTheme.positiveBalance : bankTheme.onSurface;

    final sectionPadding = padding ?? const EdgeInsets.all(BankTokens.space6);
    final resolvedDividerColor = dividerColor ?? const Color(0xFFE5E7EB);
    final resolvedCategoryLabel =
        (categoryLabelBuilder ?? _categoryLabel)(transaction.category);

    return Semantics(
      label: semanticLabel ??
          'Receipt for ${transaction.merchantName}, $formattedAmount',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius:
              radius ?? BorderRadius.circular(BankTokens.radiusMedium),
          boxShadow: shadow ??
              [
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
              padding: sectionPadding,
              child: Column(
                children: [
                  if (logoSlot != null) ...[
                    logoSlot!,
                    const SizedBox(height: BankTokens.space3),
                  ],
                  Text(
                    titleText,
                    style: BankTokens.headlineMedium
                        .copyWith(color: const Color(0xFF111111))
                        .merge(titleStyle),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    BankDateFormatter.formatLong(transaction.settledAt),
                    style: BankTokens.bodySmall
                        .copyWith(color: const Color(0xFF6B7280))
                        .merge(subtitleStyle),
                  ),
                  const SizedBox(height: BankTokens.space6),
                  // Merchant name
                  Text(
                    transaction.merchantName,
                    style: BankTokens.labelLarge
                        .copyWith(color: const Color(0xFF374151))
                        .merge(merchantStyle),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: BankTokens.space2),
                  // Amount: hero display
                  Text(
                    formattedAmount,
                    style: BankTokens.numeralHero
                        .copyWith(color: amountColor)
                        .merge(amountStyle),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ---- Dashed divider (perforated edge effect) ----
            _DashedDivider(color: resolvedDividerColor),

            // ---- Receipt body ----
            Padding(
              padding: sectionPadding,
              child: Column(
                children: [
                  if (fromAccountName != null)
                    _ReceiptRow(
                      label: fromLabel,
                      value: fromAccountName!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                    ),
                  if (toName != null)
                    _ReceiptRow(
                      label: toLabel,
                      value: toName!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                    ),
                  if (referenceNumber != null)
                    _ReceiptRow(
                      label: referenceLabel,
                      value: referenceNumber!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                    ),
                  _ReceiptRow(
                    label: categoryLabel,
                    value: resolvedCategoryLabel,
                    labelStyle: rowLabelStyle,
                    valueStyle: rowValueStyle,
                  ),
                  _ReceiptRow(
                    label: statusRowLabel,
                    value: _statusLabel(transaction.status, scope),
                    labelStyle: rowLabelStyle,
                    valueStyle: rowValueStyle,
                  ),
                  if (transaction.reference != null)
                    _ReceiptRow(
                      label: transactionIdLabel,
                      value: transaction.reference!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                    ),
                ],
              ),
            ),

            // ---- Dashed divider ----
            _DashedDivider(color: resolvedDividerColor),

            // ---- QR code placeholder ----
            Padding(
              padding: sectionPadding,
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
                        Icon(
                          qrIcon ?? BankIcons.scan,
                          size: 32,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          qrLabel,
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
                      label: exportSemanticLabel,
                      child: FilledButton.icon(
                        onPressed: onExport,
                        icon: Icon(
                          exportIcon ?? BankIcons.share,
                          color: bankTheme.onPrimary,
                          size: 18,
                        ),
                        label: Text(
                          exportLabel,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor ?? bankTheme.primary,
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
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

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
              style: BankTokens.bodySmall
                  .copyWith(color: const Color(0xFF6B7280))
                  .merge(labelStyle),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          Expanded(
            child: Text(
              value,
              style: BankTokens.bodyMedium
                  .copyWith(color: const Color(0xFF111111))
                  .merge(valueStyle),
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
