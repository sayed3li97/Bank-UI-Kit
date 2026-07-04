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

  /// Overrides the scrollable content padding. Defaults to
  /// [BankTokens.space4] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the sheet corner radius. Defaults to the theme sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet background. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the drag handle color. Defaults to the theme outline.
  final Color? handleColor;

  /// Overrides the primary accents (selected chips, focused fields,
  /// apply button). Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the sheet title style ([BankTokens.headlineSmall]).
  final TextStyle? titleStyle;

  /// Overrides the close button glyph. Defaults to [Icons.close].
  final IconData? closeIcon;

  /// Overrides the sheet title. Defaults to 'Filter Transactions'.
  final String title;

  /// Overrides the category section heading. Defaults to 'Category'.
  final String categorySectionLabel;

  /// Overrides the date section heading. Defaults to 'Date Range'.
  final String dateRangeSectionLabel;

  /// Overrides the amount section heading. Defaults to 'Amount Range'.
  final String amountRangeSectionLabel;

  /// Overrides the empty from-date button text. Defaults to 'From'.
  final String fromLabel;

  /// Overrides the empty to-date button text. Defaults to 'To'.
  final String toLabel;

  /// Overrides the from-date semantics prefix. Defaults to 'From date'.
  final String fromDateSemanticLabel;

  /// Overrides the to-date semantics prefix. Defaults to 'To date'.
  final String toDateSemanticLabel;

  /// Overrides the clear-dates button text. Defaults to 'Clear dates'.
  final String clearDatesLabel;

  /// Overrides the minimum amount field label. Defaults to 'Min'.
  final String minLabel;

  /// Overrides the maximum amount field label. Defaults to 'Max'.
  final String maxLabel;

  /// Overrides the clear-all button text. Defaults to 'Clear All'.
  final String clearAllLabel;

  /// Overrides the apply button text. Defaults to 'Apply'.
  final String applyLabel;

  /// Overrides the apply button semantics. Defaults to 'Apply filters'.
  final String applySemanticLabel;

  /// Overrides the category display name. Defaults to built-in
  /// English labels.
  final String Function(TransactionCategory)? categoryLabelBuilder;

  /// Overrides the button date format. Defaults to dd/mm/yyyy.
  final String Function(DateTime)? dateFormatter;

  const BankTransactionFilterSheet({
    required this.onApply,
    super.key,
    this.initial,
    this.onClear,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.handleColor,
    this.accentColor,
    this.titleStyle,
    this.closeIcon,
    this.title = 'Filter Transactions',
    this.categorySectionLabel = 'Category',
    this.dateRangeSectionLabel = 'Date Range',
    this.amountRangeSectionLabel = 'Amount Range',
    this.fromLabel = 'From',
    this.toLabel = 'To',
    this.fromDateSemanticLabel = 'From date',
    this.toDateSemanticLabel = 'To date',
    this.clearDatesLabel = 'Clear dates',
    this.minLabel = 'Min',
    this.maxLabel = 'Max',
    this.clearAllLabel = 'Clear All',
    this.applyLabel = 'Apply',
    this.applySemanticLabel = 'Apply filters',
    this.categoryLabelBuilder,
    this.dateFormatter,
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
    final minAmount = double.tryParse(_minController.text);
    final maxAmount = double.tryParse(_maxController.text);
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

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/'
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
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final s = scope.strings;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final formatDate = widget.dateFormatter ?? _formatDate;
    final categoryLabel = widget.categoryLabelBuilder ?? _categoryLabel;
    final accent = widget.accentColor ?? bankTheme.primary;

    final range = _dateRange;
    final fromLabel = widget.fromDateSemanticLabel +
        (range != null ? ': ${formatDate(range.start)}' : '');
    final toLabel = widget.toDateSemanticLabel +
        (range != null ? ': ${formatDate(range.end)}' : '');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? bankTheme.surface,
          borderRadius: widget.radius ?? bankTheme.sheetRadius,
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
                    color: widget.handleColor ?? bankTheme.outline,
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
                      widget.title,
                      style: BankTokens.headlineSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(widget.titleStyle),
                    ),
                  ),
                  IconButton(
                    icon: Icon(widget.closeIcon ?? Icons.close),
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
                padding:
                    widget.padding ?? const EdgeInsets.all(BankTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Category section ----
                    Text(
                      widget.categorySectionLabel,
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
                          label: categoryLabel(cat),
                          selected: selected,
                          child: FilterChip(
                            label: Text(categoryLabel(cat)),
                            selected: selected,
                            onSelected: (_) => _toggleCategory(cat),
                            selectedColor: accent.withValues(alpha: 0.15),
                            checkmarkColor: accent,
                            labelStyle: BankTokens.labelMedium.copyWith(
                              color: selected ? accent : bankTheme.onSurface,
                            ),
                            side: BorderSide(
                              color: selected ? accent : bankTheme.outline,
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
                      widget.dateRangeSectionLabel,
                      style: BankTokens.labelLarge.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: fromLabel,
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
                                    ? formatDate(_dateRange!.start)
                                    : widget.fromLabel,
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
                            label: toLabel,
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
                                    ? formatDate(_dateRange!.end)
                                    : widget.toLabel,
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
                            widget.clearDatesLabel,
                            style: BankTokens.labelMedium.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: BankTokens.space6),

                    // ---- Amount range section ----
                    Text(
                      widget.amountRangeSectionLabel,
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
                              labelText: widget.minLabel,
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
                                borderSide: BorderSide(color: accent),
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
                              labelText: widget.maxLabel,
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
                                borderSide: BorderSide(color: accent),
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
                        widget.clearAllLabel,
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
                      label: widget.applySemanticLabel,
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
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
                          widget.applyLabel,
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
