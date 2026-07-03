import 'package:flutter/material.dart';

import '../common/bank_country_picker.dart';
import '../common/bank_text_field.dart';
import '../common/money_formatter.dart';
import '../models/bank_account.dart';
import '../states/bank_success_animation.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The value object a [BankTravelNoticeForm] submits.
class BankTravelNotice {
  const BankTravelNotice({
    required this.cardIds,
    required this.destinations,
    required this.range,
    this.note,
  });

  final Set<String> cardIds;
  final List<BankCountry> destinations;
  final DateTimeRange range;
  final String? note;
}

/// Travel notification composer: card multi-select chips, destination
/// country chips backed by [BankCountryPicker.show], a validated date
/// range, and an optional note. Submit runs the async callback with a
/// loading state and plays an inline success animation on `true`.
///
/// ```dart
/// BankTravelNoticeForm(
///   cards: eligibleCards,
///   onSubmit: (notice) => api.submitTravelNotice(notice),
/// )
/// ```
class BankTravelNoticeForm extends StatefulWidget {
  const BankTravelNoticeForm({
    required this.cards,
    required this.onSubmit,
    super.key,
    this.initialCountryIsoCodes,
    this.initialRange,
    this.onCancel,
    this.cardsLabel = 'Cards travelling with you',
    this.destinationsLabel = 'Destinations',
    this.addDestinationLabel = 'Add destination',
    this.datesLabel = 'Travel dates',
    this.startLabel = 'Start',
    this.endLabel = 'End',
    this.noteLabel = 'Note (optional)',
    this.submitLabel = 'Submit notice',
    this.cancelLabel = 'Cancel',
    this.dateError = 'End date must be after the start date',
    this.selectionError = 'Pick at least one card and destination',
  });

  /// Cards eligible for a notice (host pre-filters ineligible types).
  final List<BankAccount> cards;

  /// Submits the notice; return `true` on success.
  final Future<bool> Function(BankTravelNotice notice) onSubmit;

  final List<String>? initialCountryIsoCodes;
  final DateTimeRange? initialRange;
  final VoidCallback? onCancel;

  final String cardsLabel;
  final String destinationsLabel;
  final String addDestinationLabel;
  final String datesLabel;
  final String startLabel;
  final String endLabel;
  final String noteLabel;
  final String submitLabel;
  final String cancelLabel;
  final String dateError;
  final String selectionError;

  @override
  State<BankTravelNoticeForm> createState() => _BankTravelNoticeFormState();
}

class _BankTravelNoticeFormState extends State<BankTravelNoticeForm> {
  final Set<String> _selectedCards = <String>{};
  final List<BankCountry> _destinations = [];
  DateTime? _start;
  DateTime? _end;
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;
  bool _succeeded = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.cards.length == 1) _selectedCards.add(widget.cards.first.id);
    for (final iso in widget.initialCountryIsoCodes ?? const <String>[]) {
      for (final country in BankCountry.all) {
        if (country.isoCode == iso) {
          _destinations.add(country);
          break;
        }
      }
    }
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _datesValid =>
      _start != null && _end != null && _end!.isAfter(_start!);

  bool get _selectionValid =>
      _selectedCards.isNotEmpty && _destinations.isNotEmpty;

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = start ? (_start ?? today) : (_end ?? _start ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && !_end!.isAfter(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _addDestination() async {
    final picked = await BankCountryPicker.show(context);
    if (picked == null || !mounted) return;
    if (_destinations.any((c) => c.isoCode == picked.isoCode)) return;
    setState(() => _destinations.add(picked));
  }

  Future<void> _submit() async {
    if (!_datesValid || !_selectionValid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _submitting = true);
    var succeeded = false;
    try {
      succeeded = await widget.onSubmit(
        BankTravelNotice(
          cardIds: Set.of(_selectedCards),
          destinations: List.of(_destinations),
          range: DateTimeRange(start: _start!, end: _end!),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      );
    } on Object {
      succeeded = false;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _succeeded = succeeded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    if (_succeeded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(BankTokens.space6),
          child: BankSuccessAnimation(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.cardsLabel,
          style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space2),
        Wrap(
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space2,
          children: [
            for (final card in widget.cards)
              _CardChip(
                account: card,
                selected: _selectedCards.contains(card.id),
                theme: theme,
                onTap: () => setState(() {
                  if (!_selectedCards.add(card.id)) {
                    _selectedCards.remove(card.id);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        Text(
          widget.destinationsLabel,
          style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space2),
        Wrap(
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space2,
          children: [
            for (final country in _destinations)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.08),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: BankTokens.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(country.flagEmoji),
                      const SizedBox(width: BankTokens.space1),
                      Text(
                        country.name,
                        style: BankTokens.labelMedium
                            .copyWith(color: theme.onSurface),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _destinations.remove(country),
                        ),
                        iconSize: 14,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 16, color: theme.primary),
              label: Text(
                widget.addDestinationLabel,
                style: BankTokens.labelMedium.copyWith(color: theme.primary),
              ),
              backgroundColor: theme.surface,
              side: BorderSide(color: theme.outline),
              onPressed: _addDestination,
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        Text(
          widget.datesLabel,
          style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space2),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: widget.startLabel,
                value: _start,
                theme: theme,
                onTap: () => _pickDate(start: true),
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: _DateField(
                label: widget.endLabel,
                value: _end,
                theme: theme,
                onTap: () => _pickDate(start: false),
              ),
            ),
          ],
        ),
        if (_showErrors && !_datesValid)
          Padding(
            padding: const EdgeInsets.only(top: BankTokens.space1),
            child: Text(
              widget.dateError,
              style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
            ),
          ),
        if (_showErrors && !_selectionValid)
          Padding(
            padding: const EdgeInsets.only(top: BankTokens.space1),
            child: Text(
              widget.selectionError,
              style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
            ),
          ),
        const SizedBox(height: BankTokens.space4),
        BankTextField(
          controller: _note,
          label: widget.noteLabel,
          maxLines: 2,
        ),
        const SizedBox(height: BankTokens.space5),
        Row(
          children: [
            if (widget.onCancel != null) ...[
              TextButton(
                onPressed: _submitting ? null : widget.onCancel,
                child: Text(
                  widget.cancelLabel,
                  style: BankTokens.labelLarge
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: BankTokens.space3),
            ],
            Expanded(
              child: SizedBox(
                height: BankTokens.space12,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.submitLabel,
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onPrimary),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.account,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final BankAccount account;
  final bool selected;
  final BankThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: account.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.chipRadius,
        child: AnimatedContainer(
          duration: BankTokens.durationFast,
          width: 92,
          height: 58,
          decoration: BoxDecoration(
            gradient: theme.accentGradient,
            color: theme.accentGradient == null ? theme.surfaceVariant : null,
            borderRadius: theme.chipRadius,
            border: Border.all(
              color: selected ? theme.primary : theme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.credit_card_outlined,
                  size: 16,
                  color: theme.onPrimary,
                ),
                Text(
                  account.maskedNumber,
                  style: BankTokens.labelSmall.copyWith(color: theme.onPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final BankThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value == null
          ? label
          : '$label: ${BankDateFormatter.formatFull(value!)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.buttonRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: theme.buttonRadius,
            border: Border.all(color: theme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space3,
              vertical: BankTokens.space3,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.onSurfaceVariant,
                ),
                const SizedBox(width: BankTokens.space2),
                Expanded(
                  child: Text(
                    value == null
                        ? label
                        : BankDateFormatter.formatShort(value!),
                    style: BankTokens.bodyMedium.copyWith(
                      color: value == null
                          ? theme.onSurfaceVariant
                          : theme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
