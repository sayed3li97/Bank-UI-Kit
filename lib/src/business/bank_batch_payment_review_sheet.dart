import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One row of an uploaded payment batch.
class BankBatchEntry {
  const BankBatchEntry({
    required this.rowNumber,
    required this.payeeName,
    required this.accountMasked,
    required this.amount,
    this.errorMessage,
  });

  final int rowNumber;
  final String payeeName;
  final String accountMasked;
  final Money amount;

  /// Validation failure for this row; error rows block submission.
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

/// Review surface for an uploaded payment batch (payroll, supplier
/// runs). Presents summary chips (count, single-currency total, error
/// count), a virtualized list of compact rows with per-row validation
/// errors, a show-errors-only filter, and a sticky submit bar that
/// stays disabled while any error remains. Follow submission with
/// `BankScaApprovalSheet`.
///
/// Present modally with [BankBatchPaymentReviewSheet.show].
///
/// ```dart
/// BankBatchPaymentReviewSheet.show(
///   context,
///   batchName: 'July payroll.csv',
///   entries: parsedEntries,
///   onSubmit: _startBatchAuthorization,
/// );
/// ```
class BankBatchPaymentReviewSheet extends StatefulWidget {
  const BankBatchPaymentReviewSheet({
    required this.batchName,
    required this.entries,
    required this.onSubmit,
    super.key,
    this.onCancel,
    this.onEntryTap,
    this.previewCount = 50,
    this.submitTemplate = 'Submit {n} payments · {total}',
    this.errorsChipTemplate = '{n} errors',
    this.paymentsChipTemplate = '{n} payments',
    this.errorsOnlyLabel = 'Show errors only',
    this.showAllTemplate = 'Show all {n} rows',
  });

  final String batchName;

  /// All parsed rows. Must share one currency (asserted).
  final List<BankBatchEntry> entries;

  /// Fired by the submit bar once no error rows remain.
  final VoidCallback onSubmit;

  final VoidCallback? onCancel;
  final void Function(BankBatchEntry entry)? onEntryTap;

  /// Rows rendered before the show-all expander appears.
  final int previewCount;

  /// `{n}` and `{total}` are substituted.
  final String submitTemplate;

  final String errorsChipTemplate;
  final String paymentsChipTemplate;
  final String errorsOnlyLabel;

  /// `{n}` is substituted.
  final String showAllTemplate;

  /// Presents the review as a 92%-height modal sheet resolving when
  /// dismissed.
  static Future<void> show(
    BuildContext context, {
    required String batchName,
    required List<BankBatchEntry> entries,
    required VoidCallback onSubmit,
    VoidCallback? onCancel,
    void Function(BankBatchEntry entry)? onEntryTap,
    int previewCount = 50,
  }) {
    final theme = BankThemeData.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: BankBatchPaymentReviewSheet(
          batchName: batchName,
          entries: entries,
          onSubmit: onSubmit,
          onCancel: onCancel,
          onEntryTap: onEntryTap,
          previewCount: previewCount,
        ),
      ),
    );
  }

  @override
  State<BankBatchPaymentReviewSheet> createState() =>
      _BankBatchPaymentReviewSheetState();
}

class _BankBatchPaymentReviewSheetState
    extends State<BankBatchPaymentReviewSheet> {
  bool _errorsOnly = false;
  bool _showAll = false;

  int get _errorCount => widget.entries.where((entry) => entry.hasError).length;

  Money get _total {
    assert(
      widget.entries.map((e) => e.amount.currencyCode).toSet().length <= 1,
      'BankBatchPaymentReviewSheet requires a single-currency batch',
    );
    if (widget.entries.isEmpty) return Money.zero('USD');
    var total = Money.zero(widget.entries.first.amount.currencyCode);
    for (final entry in widget.entries) {
      total = total + entry.amount;
    }
    return total;
  }

  List<BankBatchEntry> get _visible {
    final filtered = _errorsOnly
        ? widget.entries.where((entry) => entry.hasError).toList()
        : widget.entries;
    if (_showAll || filtered.length <= widget.previewCount) return filtered;
    return filtered.sublist(0, widget.previewCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final errorCount = _errorCount;
    final total = _total;
    final visible = _visible;
    final filteredLength = _errorsOnly
        ? widget.entries.where((entry) => entry.hasError).length
        : widget.entries.length;
    final truncated = visible.length < filteredLength;

    final submitLabel = widget.submitTemplate
        .replaceAll('{n}', '${widget.entries.length}')
        .replaceAll(
          '{total}',
          '${total.currencyCode} ${total.amount}',
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space4,
              BankTokens.space4,
              BankTokens.space4,
              BankTokens.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.batchName,
                        style: BankTokens.headlineSmall
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onCancel != null)
                      IconButton(
                        onPressed: () {
                          widget.onCancel!();
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: BankTokens.space2),
                Wrap(
                  spacing: BankTokens.space2,
                  runSpacing: BankTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SummaryChip(
                      label: widget.paymentsChipTemplate
                          .replaceAll('{n}', '${widget.entries.length}'),
                      color: theme.primary,
                      theme: theme,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: theme.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space2,
                          vertical: 2,
                        ),
                        child: BankBalanceText(
                          money: total,
                          size: BankBalanceSize.small,
                        ),
                      ),
                    ),
                    if (errorCount > 0)
                      _SummaryChip(
                        label: widget.errorsChipTemplate
                            .replaceAll('{n}', '$errorCount'),
                        color: BankTokens.danger,
                        theme: theme,
                      ),
                  ],
                ),
                if (errorCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: BankTokens.space2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.errorsOnlyLabel,
                            style: BankTokens.bodyMedium
                                .copyWith(color: theme.onSurface),
                          ),
                        ),
                        Switch(
                          value: _errorsOnly,
                          activeColor: theme.onPrimary,
                          activeTrackColor: theme.primary,
                          onChanged: (value) =>
                              setState(() => _errorsOnly = value),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.outline),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length + (truncated ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == visible.length) {
                  return TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    child: Text(
                      widget.showAllTemplate
                          .replaceAll('{n}', '$filteredLength'),
                      style:
                          BankTokens.labelLarge.copyWith(color: theme.primary),
                    ),
                  );
                }
                return _BatchRow(
                  entry: visible[index],
                  theme: theme,
                  onTap: widget.onEntryTap,
                );
              },
            ),
          ),
          Divider(height: 1, color: theme.outline),
          Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
            child: SizedBox(
              height: BankTokens.space12,
              child: FilledButton(
                onPressed: errorCount > 0 ? null : widget.onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  disabledBackgroundColor: theme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
                child: Text(
                  submitLabel,
                  style: BankTokens.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.theme,
  });

  final String label;
  final Color color;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 2,
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: color),
        ),
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.entry,
    required this.theme,
    required this.onTap,
  });

  final BankBatchEntry entry;
  final BankThemeData theme;
  final void Function(BankBatchEntry entry)? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.rowNumber}',
                  style: BankTokens.labelSmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.payeeName,
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      entry.accountMasked,
                      style: BankTokens.labelSmall
                          .copyWith(color: theme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BankBalanceText(
                money: entry.amount,
                size: BankBalanceSize.small,
              ),
            ],
          ),
          if (entry.hasError)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 32,
                top: 2,
              ),
              child: Text(
                entry.errorMessage!,
                style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      label: 'Row ${entry.rowNumber}: ${entry.payeeName}'
          '${entry.hasError ? ', error: ${entry.errorMessage}' : ''}',
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(entry),
        child: entry.hasError
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: BankTokens.danger.withValues(alpha: 0.08),
                  border: BorderDirectional(
                    start: BorderSide(
                      color: BankTokens.danger.withValues(alpha: 0.6),
                      width: 4,
                    ),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: row,
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: row,
              ),
      ),
    );
  }
}
