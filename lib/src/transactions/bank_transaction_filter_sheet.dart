import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Filter model
// ---------------------------------------------------------------------------

/// Immutable value object capturing the current filter state.
class BankTransactionFilter {
  final Set<TransactionCategory> categories;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;

  const BankTransactionFilter({
    this.categories = const {},
    this.dateRange,
    this.minAmount,
    this.maxAmount,
  });

  BankTransactionFilter copyWith({
    Set<TransactionCategory>? categories,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) =>
      BankTransactionFilter(
        categories: categories ?? this.categories,
        dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
        minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
        maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      );

  /// Returns `true` when no filters are active.
  bool get isEmpty =>
      categories.isEmpty &&
      dateRange == null &&
      minAmount == null &&
      maxAmount == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankTransactionFilter &&
          _setsEqual(categories, other.categories) &&
          dateRange == other.dateRange &&
          minAmount == other.minAmount &&
          maxAmount == other.maxAmount;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(categories), dateRange, minAmount, maxAmount);

  static bool _setsEqual(
    Set<TransactionCategory> a,
    Set<TransactionCategory> b,
  ) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

/// Bottom sheet with category, date-range, and amount-range filters.
class BankTransactionFilterSheet extends StatefulWidget {
  final BankTransactionFilter? initial;
  final ValueChanged<BankTransactionFilter> onApply;
  final VoidCallback? onClear;

  const BankTransactionFilterSheet({
    super.key,
    this.initial,
    required this.onApply,
    this.onClear,
  });

  /// Convenience helper to push the sheet and await the result.
  static Future<BankTransactionFilter?> show(
    BuildContext context, {
    BankTransactionFilter? initial,
  }) =>
      showModalBottomSheet<BankTransactionFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BankTransactionFilterSheet(
          initial: initial,
          onApply: (f) => Navigator.of(ctx).pop(f),
        ),
      );

  @override
  State<BankTransactionFilterSheet> createState() =>
      _BankTransactionFilterSheetState();
}

class _BankTransactionFilterSheetState
    extends State<BankTransactionFilterSheet> {
  late Set<TransactionCategory> _categories;
  DateTimeRange? _dateRange;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _categories = initial != null ? Set.of(initial.categories) : {};
    _dateRange = initial?.dateRange;
    _minController = TextEditingController(
      text: initial?.minAmount?.toStringAsFixed(2) ?? '',
    );
    _maxController = TextEditingController(
      text: initial?.maxAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _toggleCategory(TransactionCategory cat) {
    setState(() {
      if (_categories.contains(cat)) {
        _categories = Set.of(_categories)..remove(cat);
      } else {
        _categories = Set.of(_categories)..add(cat);
      }
    });
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRange?.start ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: _dateRange?.end ?? now,
    );
    if (picked != null) {
      setState(() {
        final end = _dateRange?.end;
        _dateRange = end != null && !end.isBefore(picked)
            ? DateTimeRange(start: picked, end: end)
            : DateTimeRange(start: picked, end: picked);
      });
    }
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRange?.end ?? now,
      firstDate: _dateRange?.start ?? DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        final start = _dateRange?.start ?? picked;
        _dateRange = DateTimeRange(
          start: start.isAfter(picked) ? picked : start,
          end: picked,
        );
      });
    }
  }

  void _apply() {
    final double? minAmount = double.tryParse(_minController.text);
    final double? maxAmount = double.tryParse(_maxController.text);
    widget.onApply(
      BankTransactionFilter(
        categories: Set.unmodifiable(_categories),
        dateRange: _dateRange,
        minAmount: minAmount,
        maxAmount: maxAmount,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _categories = {};
      _dateRange = null;
      _minController.clear();
      _maxController.clear();
    });
    widget.onClear?.call();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

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
        TransactionCategory.creditPayment => 'Credit',
        TransactionCategory.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final BankThemeData bankTheme = BankThemeData.of(context);
    final BankUiScopeData scope = BankUiScope.of(context);
    final s = scope.strings;

    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
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
                    borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Transactions',
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
            const Divider(height: 1),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BankTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Category section ----
                    Text(
                      'Category',
                      style: BankTokens.labelLarge.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Wrap(
                      spacing: BankTokens.space2,
                      runSpacing: BankTokens.space2,
                      children: TransactionCategory.values.map((cat) {
                        final selected = _categories.contains(cat);
                        return Semantics(
                          label: _categoryLabel(cat),
                          selected: selected,
                          child: FilterChip(
                            label: Text(_categoryLabel(cat)),
                            selected: selected,
                            onSelected: (_) => _toggleCategory(cat),
                            selectedColor:
                                bankTheme.primary.withValues(alpha: 0.15),
                            checkmarkColor: bankTheme.primary,
                            labelStyle: BankTokens.labelMedium.copyWith(
                              color: selected
                                  ? bankTheme.primary
                                  : bankTheme.onSurface,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? bankTheme.primary
                                  : bankTheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: bankTheme.chipRadius,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: BankTokens.space6),

                    // ---- Date range section ----
                    Text(
                      'Date Range',
                      style: BankTokens.labelLarge.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'From date${_dateRange != null ? ': ${_formatDate(_dateRange!.start)}' : ''}',
                            button: true,
                            child: OutlinedButton(
                              onPressed: _pickFrom,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: bankTheme.onSurface,
                                side: BorderSide(color: bankTheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: bankTheme.buttonRadius,
                                ),
                                minimumSize: const Size(
                                  double.infinity,
                                  BankTokens.minTapTarget,
                                ),
                              ),
                              child: Text(
                                _dateRange != null
                                    ? _formatDate(_dateRange!.start)
                                    : 'From',
                                style: BankTokens.bodyMedium.copyWith(
                                  color: _dateRange != null
                                      ? bankTheme.onSurface
                                      : bankTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: BankTokens.space2),
                        Expanded(
                          child: Semantics(
                            label: 'To date${_dateRange != null ? ': ${_formatDate(_dateRange!.end)}' : ''}',
                            button: true,
                            child: OutlinedButton(
                              onPressed: _pickTo,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: bankTheme.onSurface,
                                side: BorderSide(color: bankTheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: bankTheme.buttonRadius,
                                ),
                                minimumSize: const Size(
                                  double.infinity,
                                  BankTokens.minTapTarget,
                                ),
                              ),
                              child: Text(
                                _dateRange != null
                                    ? _formatDate(_dateRange!.end)
                                    : 'To',
                                style: BankTokens.bodyMedium.copyWith(
                                  color: _dateRange != null
                                      ? bankTheme.onSurface
                                      : bankTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_dateRange != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => setState(() => _dateRange = null),
                          child: Text(
                            'Clear dates',
                            style: BankTokens.labelMedium.copyWith(
                              color: bankTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: BankTokens.space6),

                    // ---- Amount range section ----
                    Text(
                      'Amount Range',
                      style: BankTokens.labelLarge.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Min',
                              labelStyle: BankTokens.bodyMedium.copyWith(
                                color: bankTheme.onSurfaceVariant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: BankTokens.space3,
                                vertical: BankTokens.space3,
                              ),
                            ),
                            style: BankTokens.bodyMedium.copyWith(
                              color: bankTheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: BankTokens.space2),
                        Expanded(
                          child: TextField(
                            controller: _maxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Max',
                              labelStyle: BankTokens.bodyMedium.copyWith(
                                color: bankTheme.onSurfaceVariant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: bankTheme.buttonRadius,
                                borderSide:
                                    BorderSide(color: bankTheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: BankTokens.space3,
                                vertical: BankTokens.space3,
                              ),
                            ),
                            style: BankTokens.bodyMedium.copyWith(
                              color: bankTheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BankTokens.space8),
                  ],
                ),
              ),
            ),
            // Footer
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space3,
                BankTokens.space4,
                BankTokens.space4 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: s.cancel,
                    child: TextButton(
                      onPressed: _clearAll,
                      style: TextButton.styleFrom(
                        foregroundColor: bankTheme.onSurfaceVariant,
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                      ),
                      child: Text(
                        'Clear All',
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Apply filters',
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: bankTheme.primary,
                          foregroundColor: bankTheme.onPrimary,
                          minimumSize: const Size(
                            double.infinity,
                            BankTokens.minTapTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: bankTheme.buttonRadius,
                          ),
                        ),
                        child: Text(
                          'Apply',
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
          ],
        ),
      ),
    );
  }
}
