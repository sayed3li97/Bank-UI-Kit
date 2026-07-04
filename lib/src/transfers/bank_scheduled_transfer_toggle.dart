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
  /// Displayed in the date-picker row when later timing is active.
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

  /// Label of the instant segment. Defaults to `'Instant'`.
  final String instantLabel;

  /// Label of the later segment. Defaults to `'Later'`.
  final String laterLabel;

  /// Label of the recurring segment. Defaults to `'Recurring'`.
  final String recurringLabel;

  /// Options offered by the recurrence dropdown. Defaults to
  /// `['Daily', 'Weekly', 'Biweekly', 'Monthly']`.
  final List<String>? recurringOptions;

  /// Placeholder of the date row before a date is picked. Defaults to
  /// `'Select date & time'`.
  final String selectDateLabel;

  /// Help text of the date picker dialog. Defaults to
  /// `'Select transfer date'`.
  final String datePickerHelpText;

  /// Help text of the time picker dialog. Defaults to
  /// `'Select transfer time'`.
  final String timePickerHelpText;

  /// Overrides the instant segment glyph. Defaults to
  /// [Icons.bolt_outlined].
  final IconData? instantIcon;

  /// Overrides the later segment glyph. Defaults to
  /// [Icons.schedule_outlined].
  final IconData? laterIcon;

  /// Overrides the recurring segment glyph. Defaults to [Icons.repeat].
  final IconData? recurringIcon;

  /// Overrides the date row glyph. Defaults to
  /// [Icons.calendar_today_outlined].
  final IconData? calendarIcon;

  /// Overrides the date row trailing glyph. Defaults to
  /// [Icons.chevron_right].
  final IconData? chevronIcon;

  /// Overrides the dropdown glyph. Defaults to [Icons.expand_more].
  final IconData? dropdownIcon;

  /// Overrides the selected segment background and the picker dialog
  /// primary color. Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the corner radius of the segments, date row, and dropdown.
  /// Defaults to the theme chipRadius.
  final BorderRadius? radius;

  /// Overrides the fill color of the date row and dropdown. Defaults to
  /// the theme surfaceVariant.
  final Color? fieldColor;

  /// Overrides the semantics label of the segmented button. Defaults to
  /// `'Transfer timing: <selection>'`.
  final String? semanticLabel;

  static const List<String> _recurringOptions = [
    'Daily',
    'Weekly',
    'Biweekly',
    'Monthly',
  ];

  const BankScheduledTransferToggle({
    required this.selected,
    required this.onChanged,
    super.key,
    this.scheduledDate,
    this.onDateChanged,
    this.recurringPattern,
    this.onRecurringPatternChanged,
    this.instantLabel = 'Instant',
    this.laterLabel = 'Later',
    this.recurringLabel = 'Recurring',
    this.recurringOptions,
    this.selectDateLabel = 'Select date & time',
    this.datePickerHelpText = 'Select transfer date',
    this.timePickerHelpText = 'Select transfer time',
    this.instantIcon,
    this.laterIcon,
    this.recurringIcon,
    this.calendarIcon,
    this.chevronIcon,
    this.dropdownIcon,
    this.accentColor,
    this.radius,
    this.fieldColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final resolvedAccent = accentColor ?? bankTheme.primary;
    final resolvedRadius = radius ?? bankTheme.chipRadius;
    final resolvedFieldColor = fieldColor ?? bankTheme.surfaceVariant;
    final resolvedOptions = recurringOptions ?? _recurringOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----------------------------------------------------------------
        // Segmented button
        // ----------------------------------------------------------------
        Semantics(
          label: semanticLabel ?? 'Transfer timing: ${selected.name}',
          child: SegmentedButton<BankTransferTiming>(
            segments: [
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.instant,
                label: Text(instantLabel),
                icon: Icon(instantIcon ?? Icons.bolt_outlined, size: 18),
              ),
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.later,
                label: Text(laterLabel),
                icon: Icon(laterIcon ?? Icons.schedule_outlined, size: 18),
              ),
              ButtonSegment<BankTransferTiming>(
                value: BankTransferTiming.recurring,
                label: Text(recurringLabel),
                icon: Icon(recurringIcon ?? Icons.repeat, size: 18),
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
                    ? resolvedAccent
                    : bankTheme.surface,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? bankTheme.onPrimary
                    : bankTheme.onSurface,
              ),
              side: WidgetStateProperty.all(
                BorderSide(color: bankTheme.outline.withValues(alpha: 0.5)),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: resolvedRadius),
              ),
              minimumSize: WidgetStateProperty.all(
                const Size(0, BankTokens.minTapTarget),
              ),
            ),
          ),
        ),
        // ----------------------------------------------------------------
        // "Later": date + time picker row
        // ----------------------------------------------------------------
        if (selected == BankTransferTiming.later && onDateChanged != null) ...[
          const SizedBox(height: BankTokens.space3),
          _DatePickerRow(
            scheduledDate: scheduledDate,
            onDateChanged: onDateChanged!,
            bankTheme: bankTheme,
            selectDateLabel: selectDateLabel,
            datePickerHelpText: datePickerHelpText,
            timePickerHelpText: timePickerHelpText,
            calendarIcon: calendarIcon ?? Icons.calendar_today_outlined,
            chevronIcon: chevronIcon ?? Icons.chevron_right,
            accentColor: resolvedAccent,
            radius: resolvedRadius,
            fieldColor: resolvedFieldColor,
          ),
        ],
        // ----------------------------------------------------------------
        // "Recurring": pattern dropdown
        // ----------------------------------------------------------------
        if (selected == BankTransferTiming.recurring &&
            onRecurringPatternChanged != null) ...[
          const SizedBox(height: BankTokens.space3),
          _RecurringPatternDropdown(
            value: recurringPattern ?? resolvedOptions.first,
            onChanged: onRecurringPatternChanged!,
            bankTheme: bankTheme,
            options: resolvedOptions,
            dropdownIcon: dropdownIcon ?? Icons.expand_more,
            radius: resolvedRadius,
            fieldColor: resolvedFieldColor,
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
    required this.selectDateLabel,
    required this.datePickerHelpText,
    required this.timePickerHelpText,
    required this.calendarIcon,
    required this.chevronIcon,
    required this.accentColor,
    required this.radius,
    required this.fieldColor,
  });

  final DateTime? scheduledDate;
  final ValueChanged<DateTime> onDateChanged;
  final BankThemeData bankTheme;
  final String selectDateLabel;
  final String datePickerHelpText;
  final String timePickerHelpText;
  final IconData calendarIcon;
  final IconData chevronIcon;
  final Color accentColor;
  final BorderRadius radius;
  final Color fieldColor;

  String get _displayText {
    if (scheduledDate == null) return selectDateLabel;
    return BankDateFormatter.formatLong(scheduledDate!);
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledDate != null && scheduledDate!.isAfter(now)
        ? scheduledDate!
        : now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: datePickerHelpText,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: accentColor,
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
      helpText: timePickerHelpText,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: accentColor,
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
        borderRadius: radius,
        child: Container(
          height: BankTokens.minTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: bankTheme.outline.withValues(alpha: 0.5)),
            color: fieldColor,
          ),
          child: Row(
            children: [
              Icon(
                calendarIcon,
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
                chevronIcon,
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
    required this.options,
    required this.dropdownIcon,
    required this.radius,
    required this.fieldColor,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final BankThemeData bankTheme;
  final List<String> options;
  final IconData dropdownIcon;
  final BorderRadius radius;
  final Color fieldColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Recurring pattern: $value',
      child: Container(
        height: BankTokens.minTapTarget,
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: bankTheme.outline.withValues(alpha: 0.5)),
          color: fieldColor,
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: Icon(
            dropdownIcon,
            color: bankTheme.onSurfaceVariant,
            size: 18,
          ),
          dropdownColor: bankTheme.surface,
          style: BankTokens.bodyMedium.copyWith(color: bankTheme.onSurface),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: options
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
