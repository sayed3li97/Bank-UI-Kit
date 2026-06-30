import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Split a single transaction's amount across multiple spending categories.
class BankTransactionCategorySplitSheet extends StatefulWidget {
  final Transaction transaction;
  final ValueChanged<List<TransactionSplit>> onConfirm;

  const BankTransactionCategorySplitSheet({
    super.key,
    required this.transaction,
    required this.onConfirm,
  });

  /// Convenience helper to push the sheet.
  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    required ValueChanged<List<TransactionSplit>> onConfirm,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankTransactionCategorySplitSheet(
          transaction: transaction,
          onConfirm: onConfirm,
        ),
      );

  @override
  State<BankTransactionCategorySplitSheet> createState() =>
      _BankTransactionCategorySplitSheetState();
}

class _BankTransactionCategorySplitSheetState
    extends State<BankTransactionCategorySplitSheet> {
  late List<_SplitEntry> _entries;

  @override
  void initState() {
    super.initState();
    // Start with the original category and the full transaction amount
    _entries = [
      _SplitEntry(
        category: widget.transaction.category,
        controller: TextEditingController(
          text: widget.transaction.amount.amount.abs().toStringAsFixed(2),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  Decimal get _totalAmount => widget.transaction.amount.amount.abs();
  String get _currencyCode => widget.transaction.amount.currencyCode;

  Decimal get _allocatedTotal {
    Decimal sum = Decimal.zero;
    for (final e in _entries) {
      final v = Decimal.tryParse(e.controller.text) ?? Decimal.zero;
      sum += v;
    }
    return sum;
  }

  bool get _isValid {
    if (_entries.length < 2) return false;
    final diff = (_allocatedTotal - _totalAmount).abs();
    return diff <= Decimal.parse('0.01');
  }

  void _addEntry() {
    // Find a category not already used, default to other
    final usedCategories = _entries.map((e) => e.category).toSet();
    final available = TransactionCategory.values
        .where((c) => !usedCategories.contains(c))
        .toList();
    final cat =
        available.isNotEmpty ? available.first : TransactionCategory.other;
    setState(() {
      _entries.add(
        _SplitEntry(
          category: cat,
          controller: TextEditingController(text: '0.00'),
        ),
      );
    });
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    setState(() {
      _entries[index].controller.dispose();
      _entries.removeAt(index);
    });
  }

  void _confirm() {
    final splits = _entries
        .map(
          (e) => TransactionSplit(
            category: e.category,
            amount: Money(
              amount: Decimal.tryParse(e.controller.text) ?? Decimal.zero,
              currencyCode: _currencyCode,
            ),
          ),
        )
        .toList();
    widget.onConfirm(splits);
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

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = BankThemeData.of(context);
    final BankUiScopeData scope = BankUiScope.of(context);
    final s = scope.strings;

    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    final double maxHeight = MediaQuery.of(context).size.height * 0.88;

    final String formattedTotal = BankMoneyFormatter.format(
      amount: _totalAmount,
      currencyCode: _currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final String formattedAllocated = BankMoneyFormatter.format(
      amount: _allocatedTotal,
      currencyCode: _currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: bankTheme.surface,
          borderRadius: bankTheme.sheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: BankTokens.space2),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bankTheme.outline,
                    borderRadius:
                        BorderRadius.circular(BankTokens.radiusFull),
                  ),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Split by Category',
                      style: BankTokens.headlineSmall.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: bankTheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: s.cancel,
                  ),
                ],
              ),
            ),
            // Total display
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Row(
                children: [
                  Text(
                    'Total: ',
                    style: BankTokens.bodyMedium.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: bankTheme.numeralMedium.copyWith(
                      color: bankTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            const Divider(height: 1),
            // Split rows
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: BankTokens.space2,
                ),
                itemCount: _entries.length + 1, // +1 for "Add category" button
                itemBuilder: (ctx, i) {
                  if (i == _entries.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space4,
                        vertical: BankTokens.space2,
                      ),
                      child: Semantics(
                        button: true,
                        label: 'Add category',
                        child: OutlinedButton.icon(
                          onPressed: _addEntry,
                          icon: Icon(
                            BankIcons.add,
                            color: bankTheme.primary,
                            size: 18,
                          ),
                          label: Text(
                            'Add Category',
                            style: BankTokens.labelMedium.copyWith(
                              color: bankTheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: bankTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: bankTheme.buttonRadius,
                            ),
                            minimumSize: const Size(
                              double.infinity,
                              BankTokens.minTapTarget,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final entry = _entries[i];
                  return _CategorySplitRow(
                    entry: entry,
                    index: i,
                    canDelete: _entries.length > 1,
                    bankTheme: bankTheme,
                    categoryLabel: _categoryLabel,
                    onCategoryChanged: (cat) {
                      setState(() => _entries[i] = _SplitEntry(
                            category: cat,
                            controller: entry.controller,
                          ));
                    },
                    onDelete: () => _removeEntry(i),
                    onAmountChanged: (_) => setState(() {}),
                  );
                },
              ),
            ),
            // Running total
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Allocated',
                      style: BankTokens.bodySmall.copyWith(
                        color: bankTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formattedAllocated,
                    style: bankTheme.numeralSmall.copyWith(
                      color: _isValid
                          ? BankTokens.positiveBalance
                          : BankTokens.negativeBalance,
                    ),
                  ),
                  Text(
                    ' / $formattedTotal',
                    style: bankTheme.numeralSmall.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_entries.length < 2)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                ),
                child: Text(
                  'Add at least one more category to split',
                  style: BankTokens.bodySmall.copyWith(
                    color: BankTokens.warning,
                  ),
                ),
              ),
            const Divider(height: 1),
            // Confirm button
            Padding(
              padding: EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space3,
                BankTokens.space4,
                BankTokens.space4,
              ),
              child: Semantics(
                button: true,
                label: s.confirm,
                enabled: _isValid,
                child: FilledButton(
                  onPressed: _isValid ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: bankTheme.primary,
                    foregroundColor: bankTheme.onPrimary,
                    disabledBackgroundColor:
                        bankTheme.primary.withValues(alpha: 0.38),
                    minimumSize: const Size(
                      double.infinity,
                      BankTokens.minTapTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: bankTheme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    s.confirm,
                    style: BankTokens.labelLarge.copyWith(
                      color: bankTheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data model
// ---------------------------------------------------------------------------

class _SplitEntry {
  final TransactionCategory category;
  final TextEditingController controller;

  _SplitEntry({required this.category, required this.controller});
}

// ---------------------------------------------------------------------------
// Private row widget
// ---------------------------------------------------------------------------

class _CategorySplitRow extends StatelessWidget {
  final _SplitEntry entry;
  final int index;
  final bool canDelete;
  final BankThemeData bankTheme;
  final String Function(TransactionCategory) categoryLabel;
  final ValueChanged<TransactionCategory> onCategoryChanged;
  final VoidCallback onDelete;
  final ValueChanged<String> onAmountChanged;

  const _CategorySplitRow({
    required this.entry,
    required this.index,
    required this.canDelete,
    required this.bankTheme,
    required this.categoryLabel,
    required this.onCategoryChanged,
    required this.onDelete,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category icon
          CircleAvatar(
            radius: 16,
            backgroundColor: bankTheme.surfaceVariant,
            child: Icon(
              BankIcons.forCategoryName(entry.category.name),
              size: 16,
              color: bankTheme.primary,
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          // Category dropdown
          Expanded(
            child: Semantics(
              label: 'Category ${index + 1}: ${categoryLabel(entry.category)}',
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space2,
                    vertical: BankTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: bankTheme.outline),
                    borderRadius: bankTheme.buttonRadius,
                  ),
                  child: DropdownButton<TransactionCategory>(
                    value: entry.category,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: bankTheme.surface,
                    style: BankTokens.bodyMedium.copyWith(
                      color: bankTheme.onSurface,
                    ),
                    icon: Icon(
                      BankIcons.expand,
                      size: 16,
                      color: bankTheme.onSurfaceVariant,
                    ),
                    items: TransactionCategory.values
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              categoryLabel(cat),
                              style: BankTokens.bodyMedium.copyWith(
                                color: bankTheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (cat) {
                      if (cat != null) onCategoryChanged(cat);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          // Amount input
          SizedBox(
            width: 90,
            child: TextField(
              controller: entry.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}'),
                ),
              ],
              onChanged: onAmountChanged,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space2,
                  vertical: BankTokens.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: bankTheme.buttonRadius,
                  borderSide: BorderSide(color: bankTheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: bankTheme.buttonRadius,
                  borderSide: BorderSide(color: bankTheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: bankTheme.buttonRadius,
                  borderSide: BorderSide(color: bankTheme.primary),
                ),
              ),
              style: bankTheme.numeralSmall.copyWith(
                color: bankTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space1),
          // Delete button
          SizedBox(
            width: BankTokens.minTapTarget,
            height: BankTokens.minTapTarget,
            child: canDelete
                ? Semantics(
                    button: true,
                    label: 'Remove category ${index + 1}',
                    child: IconButton(
                      icon: Icon(
                        BankIcons.delete,
                        size: 18,
                        color: bankTheme.onSurfaceVariant,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Remove',
                      padding: EdgeInsets.zero,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
