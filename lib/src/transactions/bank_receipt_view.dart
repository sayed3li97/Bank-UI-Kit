import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/button_text_style.dart';
import '../../src/theme/tokens.dart';
import '../common/bank_format_context.dart';
import '../common/bank_surface_depth.dart';

/// Shareable receipt layout. The package renders the view;
/// the host app wires up PDF generation or share-sheet logic.
///
/// Wrap in a [RepaintBoundary] and call `toImage()` for PDF export.
///
/// Unlike every other surface in the kit, the receipt does **not** invert in
/// dark themes: it is a printed artefact, so it keeps printing on light
/// stock (see [paperFor]) and inks itself from the *paper*, never from the
/// ambient theme's on-surface roles.
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

  /// Overrides the paper color. Defaults to [paperFor] — the brand's own
  /// receipt stock.
  ///
  /// Every ink on the receipt is derived from the resolved paper's
  /// brightness, so a dark override re-inks the whole receipt rather than
  /// leaving dark text on a dark sheet.
  final Color? backgroundColor;

  /// Overrides the drop shadow. Defaults to the brightness-aware resting
  /// card shadow; pass const [] to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the dashed divider color. Defaults to the border-outline role
  /// matching the paper's brightness.
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

  /// The receipt stock [theme] prints on.
  ///
  /// A receipt reads as a printed artefact, so the paper stays light in dark
  /// themes instead of inverting with the rest of the UI — an inverted sheet
  /// is what used to swallow the hero amount, because theme-driven ink was
  /// being painted on a hardcoded white sheet. It is not a raw white constant
  /// either: [BankThemeData.primary] is composited over [BankTokens.neutral50]
  /// at [BankTokens.alphaFaint], so each preset prints on its own faintly
  /// tinted stock while staying light enough for [BankTokens.inkStrong] to
  /// clear WCAG AA.
  ///
  /// Exposed because a host exporting the view to PDF has to paint the same
  /// stock behind the rasterised page.
  static Color paperFor(BankThemeData theme) => Color.alphaBlend(
        theme.primary.withValues(alpha: BankTokens.alphaFaint),
        BankTokens.neutral50,
      );

  /// Minimum contrast a coloured ink must clear against the paper before it
  /// is used instead of the neutral fallback (WCAG AA for body text).
  static const double _minInkContrast = 4.5;

  /// Width of the label column in the detail rows.
  static const double _rowLabelWidth = 100;

  /// Side of the square QR placeholder frame.
  static const double _qrPlaceholderSize = 120;

  /// [seed] when it clears [_minInkContrast] against [paper], else [fallback].
  ///
  /// A brand's semantic inks are tuned for its own surfaces, and the
  /// dark-mode variants (emerald-400 and family) land near 3:1 on receipt
  /// stock. Since the paper does not invert with the theme, the ink on it
  /// cannot be chosen by the theme's brightness alone — it has to be
  /// measured against the sheet actually being printed.
  static Color _legibleOn(Color seed, Color paper, {required Color fallback}) =>
      _contrastRatio(seed, paper) >= _minInkContrast ? seed : fallback;

  static double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

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

    // Ink follows the *paper*, not the theme: the sheet stays light in dark
    // mode, so onSurface ink would be white-on-white there.
    final paper = backgroundColor ?? paperFor(bankTheme);
    final paperBrightness = ThemeData.estimateBrightnessForColor(paper);
    final onDarkPaper = paperBrightness == Brightness.dark;
    final ink = onDarkPaper ? BankTokens.inkStrongDark : BankTokens.inkStrong;
    final inkMuted =
        onDarkPaper ? BankTokens.inkMutedDark : BankTokens.inkMuted;
    final inkFaint =
        onDarkPaper ? BankTokens.inkFaintDark : BankTokens.inkFaint;
    final paperOutline =
        onDarkPaper ? BankTokens.borderOutlineDark : BankTokens.borderOutline;

    final amountColor = isCredit
        ? _legibleOn(
            bankTheme.positiveBalance,
            paper,
            fallback: onDarkPaper
                ? BankTokens.positiveBalanceDark
                : BankTokens.positiveBalance,
          )
        : ink;

    final depth = BankSurfaceDepth.resolve(
      bankTheme,
      surfaceColor: paper,
      shadow: shadow,
    );

    final sectionPadding = padding ?? const EdgeInsets.all(BankTokens.space6);
    final resolvedDividerColor = dividerColor ?? paperOutline;
    final resolvedCategoryLabel =
        (categoryLabelBuilder ?? _categoryLabel)(transaction.category);

    return Semantics(
      label: semanticLabel ??
          'Receipt for ${transaction.merchantName}, $formattedAmount',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius:
              radius ?? BorderRadius.circular(BankTokens.radiusMedium),
          boxShadow: depth.shadow,
          border: depth.border,
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
                        .copyWith(color: ink)
                        .merge(titleStyle),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    BankDateFormatter.formatLong(transaction.settledAt),
                    style: BankTokens.bodySmall
                        .copyWith(color: inkMuted)
                        .merge(subtitleStyle),
                  ),
                  const SizedBox(height: BankTokens.space6),
                  // Merchant name
                  Text(
                    transaction.merchantName,
                    style: BankTokens.labelLarge
                        .copyWith(color: inkMuted)
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
                      labelColor: inkMuted,
                      valueColor: ink,
                    ),
                  if (toName != null)
                    _ReceiptRow(
                      label: toLabel,
                      value: toName!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                      labelColor: inkMuted,
                      valueColor: ink,
                    ),
                  if (referenceNumber != null)
                    _ReceiptRow(
                      label: referenceLabel,
                      value: referenceNumber!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                      labelColor: inkMuted,
                      valueColor: ink,
                    ),
                  _ReceiptRow(
                    label: categoryLabel,
                    value: resolvedCategoryLabel,
                    labelStyle: rowLabelStyle,
                    valueStyle: rowValueStyle,
                    labelColor: inkMuted,
                    valueColor: ink,
                  ),
                  _ReceiptRow(
                    label: statusRowLabel,
                    value: _statusLabel(transaction.status, scope),
                    labelStyle: rowLabelStyle,
                    valueStyle: rowValueStyle,
                    labelColor: inkMuted,
                    valueColor: ink,
                  ),
                  if (transaction.reference != null)
                    _ReceiptRow(
                      label: transactionIdLabel,
                      value: transaction.reference!,
                      labelStyle: rowLabelStyle,
                      valueStyle: rowValueStyle,
                      labelColor: inkMuted,
                      valueColor: ink,
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
                    width: _qrPlaceholderSize,
                    height: _qrPlaceholderSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: paperOutline,
                        // Matches Border.all's default today; keep the token
                        // as the source of truth for hairline geometry.
                        // ignore: avoid_redundant_argument_values
                        width: BankTokens.hairlineWidth,
                      ),
                      borderRadius:
                          BorderRadius.circular(BankTokens.radiusSmall),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          qrIcon ?? BankIcons.scan,
                          size: BankTokens.iconXLarge,
                          color: inkFaint,
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          qrLabel,
                          style: BankTokens.bodySmall.copyWith(color: inkFaint),
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
                          size: BankTokens.iconMedium,
                        ),
                        label: Text(
                          exportLabel,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor ?? bankTheme.primary,
                          textStyle: bankButtonTextStyle(context),
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

  /// Ink for the label column, resolved from the paper's brightness.
  final Color labelColor;

  /// Ink for the value column, resolved from the paper's brightness.
  final Color valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: BankTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: BankReceiptView._rowLabelWidth,
            child: Text(
              label,
              style: BankTokens.bodySmall
                  .copyWith(color: labelColor)
                  .merge(labelStyle),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          Expanded(
            child: Text(
              value,
              style: BankTokens.bodyMedium
                  .copyWith(color: valueColor)
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
