import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/money_formatter.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A single selectable bonus category displayed inside
/// [BankCashbackCategoryPicker].
@immutable
class BankCashbackCategory {
  /// Creates an immutable cashback category description.
  const BankCashbackCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.rateLabel,
    this.selected = false,
  });

  /// Unique identifier reported through
  /// [BankCashbackCategoryPicker.onChanged].
  final String id;

  /// Human readable category name, e.g. `'Dining'`.
  final String label;

  /// Icon rendered on a tinted disc at the top of the card.
  final IconData icon;

  /// Short cashback rate caption, e.g. `'5%'`.
  final String rateLabel;

  /// Whether the category starts out selected.
  final bool selected;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankCashbackCategory &&
        other.id == id &&
        other.label == label &&
        other.icon == icon &&
        other.rateLabel == rateLabel &&
        other.selected == selected;
  }

  @override
  int get hashCode => Object.hash(id, label, icon, rateLabel, selected);
}

/// Bonus-category selection grid for quarterly or monthly cashback
/// programmes (T-Bank quarterly categories, Sber Spasibo selection).
///
/// Renders a header with a title and a live "n of max selected" counter,
/// a three-column grid of tappable category cards (icon on a tinted disc,
/// label, and rate chip), and an optional confirm button. Selected cards
/// receive a primary border and a check badge. Tapping a card beyond
/// [maxSelections] shakes the tapped card instead of selecting it (the
/// shake is skipped when animations are disabled via [MediaQuery]).
///
/// After the user confirms, an [effectiveUntil] date (if provided) is
/// rendered as "Locked until {date}" microtext. The confirm button stays
/// disabled until at least one category is selected.
///
/// ```dart
/// BankCashbackCategoryPicker(
///   categories: const [
///     BankCashbackCategory(
///       id: 'dining',
///       label: 'Dining',
///       icon: BankIcons.dining,
///       rateLabel: '5%',
///     ),
///     BankCashbackCategory(
///       id: 'travel',
///       label: 'Travel',
///       icon: BankIcons.travel,
///       rateLabel: '3%',
///     ),
///   ],
///   maxSelections: 3,
///   onChanged: (ids) => debugPrint('selected: $ids'),
///   effectiveUntil: DateTime(2026, 9, 30),
///   onConfirm: () => submitChoices(),
/// )
/// ```
class BankCashbackCategoryPicker extends StatefulWidget {
  /// Creates a bonus-category selection grid.
  const BankCashbackCategoryPicker({
    required this.categories,
    required this.maxSelections,
    required this.onChanged,
    super.key,
    this.effectiveUntil,
    this.title = 'Choose your cashback categories',
    this.counterTemplate = '{n} of {max} selected',
    this.onConfirm,
    this.confirmLabel = 'Confirm choices',
    this.lockedUntilTemplate = 'Locked until {date}',
  }) : assert(maxSelections > 0, 'maxSelections must be at least 1');

  /// Categories to display, in grid order.
  final List<BankCashbackCategory> categories;

  /// Maximum number of categories the user may select at once.
  final int maxSelections;

  /// Called with the full set of selected category ids after every
  /// selection change.
  final ValueChanged<Set<String>> onChanged;

  /// When the confirmed choice unlocks again. Rendered as microtext
  /// (see [lockedUntilTemplate]) after the user confirms.
  final DateTime? effectiveUntil;

  /// Header title shown above the grid.
  final String title;

  /// Counter template; `{n}` and `{max}` placeholders are replaced with
  /// the current selection count and [maxSelections].
  final String counterTemplate;

  /// Called when the confirm button is pressed. When `null` the confirm
  /// button is not rendered.
  final VoidCallback? onConfirm;

  /// Label of the confirm button.
  final String confirmLabel;

  /// Microtext template shown after confirm when [effectiveUntil] is set;
  /// the `{date}` placeholder is replaced with the formatted date.
  final String lockedUntilTemplate;

  @override
  State<BankCashbackCategoryPicker> createState() =>
      _BankCashbackCategoryPickerState();
}

class _BankCashbackCategoryPickerState extends State<BankCashbackCategoryPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late Set<String> _selectedIds;
  String? _shakingId;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedIds =
        widget.categories.where((c) => c.selected).map((c) => c.id).toSet();
    _shakeController = AnimationController(
      vsync: this,
      duration: BankTokens.durationSlow,
    );
  }

  @override
  void didUpdateWidget(BankCashbackCategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.categories, oldWidget.categories)) {
      final ids = widget.categories.map((c) => c.id).toSet();
      _selectedIds.retainAll(ids);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap(BankCashbackCategory category) {
    if (_selectedIds.contains(category.id)) {
      setState(() {
        _selectedIds.remove(category.id);
        _confirmed = false;
      });
      widget.onChanged(Set<String>.of(_selectedIds));
      return;
    }
    if (_selectedIds.length >= widget.maxSelections) {
      _shakeCard(category.id);
      return;
    }
    setState(() {
      _selectedIds.add(category.id);
      _confirmed = false;
    });
    widget.onChanged(Set<String>.of(_selectedIds));
  }

  void _shakeCard(String id) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _shakingId = id);
    _shakeController.stop();
    _shakeController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _shakingId = null);
    });
  }

  void _handleConfirm() {
    widget.onConfirm?.call();
    setState(() => _confirmed = true);
  }

  String _counterText(BankUiScopeData scope) {
    final text = widget.counterTemplate
        .replaceAll('{n}', '${_selectedIds.length}')
        .replaceAll('{max}', '${widget.maxSelections}');
    return scope.numeralStyle.convert(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final showLock = _confirmed && widget.effectiveUntil != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: BankTokens.headlineSmall.copyWith(
                  color: theme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Text(
              _counterText(scope),
              style: BankTokens.labelMedium.copyWith(
                color: _selectedIds.length >= widget.maxSelections
                    ? theme.primary
                    : theme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: BankTokens.space3,
          crossAxisSpacing: BankTokens.space3,
          childAspectRatio: 0.78,
          children: [
            for (final category in widget.categories)
              _CategoryCard(
                category: category,
                selected: _selectedIds.contains(category.id),
                shakeAnimation:
                    _shakingId == category.id ? _shakeController : null,
                onTap: () => _handleTap(category),
              ),
          ],
        ),
        if (widget.onConfirm != null) ...[
          const SizedBox(height: BankTokens.space4),
          SizedBox(
            width: double.infinity,
            height: BankTokens.minTapTarget,
            child: FilledButton(
              onPressed: _selectedIds.isEmpty ? null : _handleConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
              ),
              child: Text(widget.confirmLabel),
            ),
          ),
        ],
        if (showLock) ...[
          const SizedBox(height: BankTokens.space2),
          Text(
            widget.lockedUntilTemplate.replaceAll(
              '{date}',
              scope.numeralStyle.convert(
                BankDateFormatter.formatFull(widget.effectiveUntil!),
              ),
            ),
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// One tappable category tile inside the grid.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.shakeAnimation,
    required this.onTap,
  });

  final BankCashbackCategory category;
  final bool selected;

  /// Non-null while this card is the one being shaken for exceeding the
  /// selection limit.
  final Animation<double>? shakeAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Material(
        color: selected ? theme.primary.withValues(alpha: 0.08) : theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: theme.cardRadius,
          side: selected
              ? BorderSide(color: theme.primary, width: 2)
              : BorderSide(color: theme.outline),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: theme.cardRadius,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.all(BankTokens.space2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primary.withValues(alpha: 0.12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(BankTokens.space2),
                        child: Icon(
                          category.icon,
                          color: theme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: BankTokens.space2),
                    Text(
                      category.label,
                      style: BankTokens.labelMedium.copyWith(
                        color: theme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BankTokens.space1),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.primary.withValues(alpha: 0.16)
                            : theme.surfaceVariant,
                        borderRadius: theme.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: BankTokens.space2,
                          vertical: BankTokens.space1,
                        ),
                        child: Text(
                          category.rateLabel,
                          style: BankTokens.labelSmall.copyWith(
                            color: selected
                                ? theme.primary
                                : theme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: BankTokens.space1,
                  end: BankTokens.space1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primary,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: theme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final animated = shakeAnimation == null
        ? card
        : AnimatedBuilder(
            animation: shakeAnimation!,
            builder: (context, child) {
              final t = shakeAnimation!.value;
              final dx = math.sin(t * math.pi * 5) * 6 * (1 - t);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: card,
          );

    return Semantics(
      button: true,
      selected: selected,
      label: '${category.label}, ${category.rateLabel}',
      child: animated,
    );
  }
}
