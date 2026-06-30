import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankTransferTiming
// ---------------------------------------------------------------------------

/// Determines when a transfer should be executed.
enum BankTransferTiming {
  /// Send immediately.
  instant,

  /// Send at a specific future date and time.
  later,

  /// Send on a repeating schedule.
  recurring,
}

// ---------------------------------------------------------------------------
// BankScheduledTransferToggle
// ---------------------------------------------------------------------------

/// Instant / Later / Recurring selector for a transfer, built on Flutter's
/// built-in [SegmentedButton].
///
/// When [BankTransferTiming.later] is selected and [onDateChanged] is
/// non-null, a date-and-time picker row is shown below the segmented button.
///
/// When [BankTransferTiming.recurring] is selected and
/// [onRecurringPatternChanged] is non-null, a dropdown for picking the
/// recurrence pattern is shown.
///
/// ```dart
/// BankScheduledTransferToggle(
///   selected: _timing,
///   onChanged: (t) => setState(() => _timing = t),
///   scheduledDate: _scheduledDate,
///   onDateChanged: (d) => setState(() => _scheduledDate = d),
///   recurringPattern: _pattern,
///   onRecurringPatternChanged: (p) => setState(() => _pattern = p),
/// )
/// ```
class BankScheduledTransferToggle extends StatelessWidget {
  /// The currently selected [BankTransferTiming] value.
  final BankTransferTiming selected;

  /// Called when the user taps a different segment.
  final ValueChanged<BankTransferTiming> onChanged;

  /// The currently selected scheduled date for [BankTransferTiming.later].
  /// Displayed in the date-picker row when [later] is active.
  final DateTime? scheduledDate;

  /// When non-null and [BankTransferTiming.later] is selected, a date-and-time
  /// picker row is rendered below the segmented button and this callback
  /// receives the chosen [DateTime].
  final ValueChanged<DateTime>? onDateChanged;

  /// The currently selected recurrence pattern for
  /// [BankTransferTiming.recurring], e.g. `'Weekly'` or `'Monthly'`.
  final String? recurringPattern;

  /// When non-null and [BankTransferTiming.recurring] is selected, a pattern
  /// dropdown is rendered below the segmented button.
  final ValueChanged<String>? onRecurringPatternChanged;

  static const List<String> _recurringOptions = [
    'Daily',
    'Weekly',
    'Biweekly',
    'Monthly',
  ];

  const BankScheduledTransferToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.scheduledDate,
    this.onDateChanged,
    this.recurringPattern,
    this.onRecurringPatternChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----------------------------------------------------------------
        // Segmented button
        // ----------------------------------------------------------------
        Semantics(
          label: 'Transfer timing: ${selected.name}',
          child: SegmentedButton<BankTransferTiming>(
            segments: const [
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.instant,
                label: Text('Instant'),
                icon: Icon(Icons.bolt_outlined, size: 18),
              ),
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.later,
                label: Text('Later'),
                icon: Icon(Icons.schedule_outlined, size: 18),
              ),
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.recurring,
                label: Text('Recurring'),
                icon: Icon(Icons.repeat, size: 18),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? bankTheme.primary
                    : bankTheme.surface,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? bankTheme.onPrimary
                    : bankTheme.onSurface,
              ),
              side: WidgetStateProperty.all(
                BorderSide(color: bankTheme.outline.withOpacity(0.5)),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: bankTheme.chipRadius),
              ),
              minimumSize: WidgetStateProperty.all(
                const Size(0, BankTokens.minTapTarget),
              ),
            ),
          ),
        ),
        // ----------------------------------------------------------------
        // "Later" — date + time picker row
        // ----------------------------------------------------------------
        if (selected == BankTransferTiming.later &&
            onDateChanged != null) ...[
          const SizedBox(height: BankTokens.space3),
          _DatePickerRow(
            scheduledDate: scheduledDate,
            onDateChanged: onDateChanged!,
            bankTheme: bankTheme,
          ),
        ],
        // ----------------------------------------------------------------
        // "Recurring" — pattern dropdown
        // ----------------------------------------------------------------
        if (selected == BankTransferTiming.recurring &&
            onRecurringPatternChanged != null) ...[
          const SizedBox(height: BankTokens.space3),
          _RecurringPatternDropdown(
            value: recurringPattern ?? _recurringOptions.first,
            onChanged: onRecurringPatternChanged!,
            bankTheme: bankTheme,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker row
// ---------------------------------------------------------------------------

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.scheduledDate,
    required this.onDateChanged,
    required this.bankTheme,
  });

  final DateTime? scheduledDate;
  final ValueChanged<DateTime> onDateChanged;
  final BankThemeData bankTheme;

  String get _displayText {
    if (scheduledDate == null) return 'Select date & time';
    return BankDateFormatter.formatLong(scheduledDate!);
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledDate != null &&
            scheduledDate!.isAfter(now)
        ? scheduledDate!
        : now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select transfer date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: bankTheme.primary,
            onPrimary: bankTheme.onPrimary,
            surface: bankTheme.surface,
            onSurface: bankTheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: 'Select transfer time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: bankTheme.primary,
            onPrimary: bankTheme.onPrimary,
            surface: bankTheme.surface,
            onSurface: bankTheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onDateChanged(combined);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Schedule date and time: $_displayText',
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: bankTheme.chipRadius,
        child: Container(
          height: BankTokens.minTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
          decoration: BoxDecoration(
            borderRadius: bankTheme.chipRadius,
            border: Border.all(color: bankTheme.outline.withOpacity(0.5)),
            color: bankTheme.surfaceVariant,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: bankTheme.onSurfaceVariant,
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Text(
                  _displayText,
                  style: BankTokens.bodyMedium.copyWith(
                    color: scheduledDate != null
                        ? bankTheme.onSurface
                        : bankTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: bankTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recurring pattern dropdown
// ---------------------------------------------------------------------------

class _RecurringPatternDropdown extends StatelessWidget {
  const _RecurringPatternDropdown({
    required this.value,
    required this.onChanged,
    required this.bankTheme,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final BankThemeData bankTheme;

  static const List<String> _options = [
    'Daily',
    'Weekly',
    'Biweekly',
    'Monthly',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Recurring pattern: $value',
      child: Container(
        height: BankTokens.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        decoration: BoxDecoration(
          borderRadius: bankTheme.chipRadius,
          border: Border.all(color: bankTheme.outline.withOpacity(0.5)),
          color: bankTheme.surfaceVariant,
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: Icon(
            Icons.expand_more,
            color: bankTheme.onSurfaceVariant,
            size: 18,
          ),
          dropdownColor: bankTheme.surface,
          style: BankTokens.bodyMedium.copyWith(color: bankTheme.onSurface),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: _options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
