import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Sheet handle bar helper
// ---------------------------------------------------------------------------

class _SheetHandleBar extends StatelessWidget {
  const _SheetHandleBar();

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    return Padding(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Multiplier chip
// ---------------------------------------------------------------------------

class _MultiplierChip extends StatelessWidget {
  const _MultiplierChip({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.accent,
    required this.label,
    required this.semanticLabel,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;
  final Color accent;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    final bgColor = selected ? accent : bankTheme.surfaceVariant;
    final fgColor = selected
        ? bankTheme.onPrimary
        : (enabled ? bankTheme.onSurface : bankTheme.onSurfaceVariant);

    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: enabled ? onSelected : null,
        child: AnimatedContainer(
          duration: BankTokens.durationFast,
          curve: BankTokens.curveStandard,
          constraints: const BoxConstraints(
            minWidth: BankTokens.minTapTarget,
            minHeight: BankTokens.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            border: Border.all(
              color: selected ? accent : bankTheme.outline,
              width: selected ? 0 : 1,
            ),
          ),
          child: Text(
            label,
            style: BankTokens.labelLarge.copyWith(color: fgColor),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round-up settings sheet
// ---------------------------------------------------------------------------

/// Round-up configuration bottom sheet: toggle, multiplier, and destination
/// pot picker.
///
/// The sheet is stateless with respect to persistence; callers own the state
/// and supply it via the constructor parameters. Changes are surfaced through
/// the respective callbacks.
///
/// Use [BankRoundUpSettingsSheet.show] to display the sheet as a modal bottom
/// sheet.
class BankRoundUpSettingsSheet extends StatefulWidget {
  /// Whether round-ups are currently enabled.
  final bool isEnabled;

  /// Current round-up multiplier. Must be one of `1`, `2`, `5`, or `10`.
  final int multiplier;

  /// Savings pots the user may direct round-ups into.
  final List<SavingsPot> availablePots;

  /// The [SavingsPot.id] of the currently selected destination pot.
  final String? selectedPotId;

  /// Invoked when the user toggles the round-up switch.
  final ValueChanged<bool> onEnabledChanged;

  /// Invoked when the user selects a multiplier chip.
  final ValueChanged<int> onMultiplierChanged;

  /// Invoked when the user picks a destination pot. `null` when deselected.
  final ValueChanged<String?> onPotSelected;

  /// Heading of the sheet. Defaults to 'Round Up Spare Change'.
  final String title;

  /// Label above the multiplier chips. Defaults to 'Round up by'.
  final String multiplierSectionLabel;

  /// Label above the pot picker. Defaults to 'Save to'.
  final String potSectionLabel;

  /// Empty state shown when [availablePots] is empty. Defaults to
  /// 'No savings pots available. Create a pot first.'.
  final String emptyPotsLabel;

  /// Pot goal line template; `{amount}` is substituted. Defaults to
  /// 'Goal: {amount}'.
  final String goalTemplate;

  /// Pot row semantics template; `{pot}` and `{amount}` are
  /// substituted. Defaults to '{pot}, goal {amount}'.
  final String potSemanticTemplate;

  /// Multiplier chip text template; `{n}` is substituted. Defaults to
  /// '{n}' followed by a multiplication sign.
  final String multiplierTemplate;

  /// Multiplier chip semantics template; `{n}` is substituted.
  /// Defaults to '{n}x multiplier'.
  final String multiplierSemanticTemplate;

  /// Switch semantics while round-ups are on. Defaults to
  /// 'Round Up enabled'.
  final String enabledSemanticLabel;

  /// Switch semantics while round-ups are off. Defaults to
  /// 'Round Up disabled'.
  final String disabledSemanticLabel;

  /// Explanation shown at the bottom; `{multiplier}` is substituted
  /// with the multiplied-by suffix (empty at 1x). Defaults to the
  /// built-in English copy.
  final String explanationTemplate;

  /// Overrides the sheet corner radius. Defaults to the theme
  /// sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the switch, chip, and pot picker accent. Defaults to
  /// the theme primary colour.
  final Color? accentColor;

  /// Merged over the computed heading style
  /// ([BankTokens.headlineSmall] in onSurface).
  final TextStyle? titleStyle;

  /// Overrides the heading glyph. Defaults to [BankIcons.roundUp].
  final IconData? titleIcon;

  /// Overrides the pot row glyph. Defaults to [BankIcons.pot].
  final IconData? potIcon;

  /// Overrides the selected pot glyph. Defaults to
  /// [Icons.check_circle].
  final IconData? selectedIcon;

  /// Overrides the explanation glyph. Defaults to [BankIcons.info].
  final IconData? infoIcon;

  /// Overrides the enable/disable fade duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the enable/disable fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  static const List<int> _multiplierOptions = [1, 2, 5, 10];

  const BankRoundUpSettingsSheet({
    required this.isEnabled,
    required this.multiplier,
    required this.availablePots,
    required this.onEnabledChanged,
    required this.onMultiplierChanged,
    required this.onPotSelected,
    super.key,
    this.selectedPotId,
    this.title = 'Round Up Spare Change',
    this.multiplierSectionLabel = 'Round up by',
    this.potSectionLabel = 'Save to',
    this.emptyPotsLabel = 'No savings pots available. Create a pot first.',
    this.goalTemplate = 'Goal: {amount}',
    this.potSemanticTemplate = '{pot}, goal {amount}',
    this.multiplierTemplate = '{n}×',
    this.multiplierSemanticTemplate = '{n}x multiplier',
    this.enabledSemanticLabel = 'Round Up enabled',
    this.disabledSemanticLabel = 'Round Up disabled',
    this.explanationTemplate = 'We\'ll round up every purchase to the '
        'nearest £1 and save the difference{multiplier} automatically.',
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.titleIcon,
    this.potIcon,
    this.selectedIcon,
    this.infoIcon,
    this.animationDuration,
    this.animationCurve,
  }) : assert(
          multiplier == 1 ||
              multiplier == 2 ||
              multiplier == 5 ||
              multiplier == 10,
          'multiplier must be 1, 2, 5, or 10',
        );

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required bool isEnabled,
    required int multiplier,
    required List<SavingsPot> availablePots,
    required ValueChanged<bool> onEnabledChanged,
    required ValueChanged<int> onMultiplierChanged,
    required ValueChanged<String?> onPotSelected,
    String? selectedPotId,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankRoundUpSettingsSheet(
          isEnabled: isEnabled,
          multiplier: multiplier,
          availablePots: availablePots,
          selectedPotId: selectedPotId,
          onEnabledChanged: onEnabledChanged,
          onMultiplierChanged: onMultiplierChanged,
          onPotSelected: onPotSelected,
        ),
      );

  @override
  State<BankRoundUpSettingsSheet> createState() =>
      _BankRoundUpSettingsSheetState();
}

class _BankRoundUpSettingsSheetState extends State<BankRoundUpSettingsSheet> {
  late bool _isEnabled;
  late int _multiplier;
  late String? _selectedPotId;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
    _multiplier = widget.multiplier;
    _selectedPotId = widget.selectedPotId;
  }

  @override
  void didUpdateWidget(BankRoundUpSettingsSheet old) {
    super.didUpdateWidget(old);
    if (old.isEnabled != widget.isEnabled) _isEnabled = widget.isEnabled;
    if (old.multiplier != widget.multiplier) _multiplier = widget.multiplier;
    if (old.selectedPotId != widget.selectedPotId) {
      _selectedPotId = widget.selectedPotId;
    }
  }

  void _handleToggle(bool value) {
    setState(() => _isEnabled = value);
    widget.onEnabledChanged(value);
  }

  void _handleMultiplier(int value) {
    setState(() => _multiplier = value);
    widget.onMultiplierChanged(value);
  }

  void _handlePotSelected(String? potId) {
    setState(() => _selectedPotId = potId);
    widget.onPotSelected(potId);
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = widget.accentColor ?? bankTheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? bankTheme.surface,
          borderRadius: widget.radius ?? bankTheme.sheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandleBar(),
            // ── Title ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.titleIcon ?? BankIcons.roundUp,
                    color: accent,
                    size: 22,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: BankTokens.headlineSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(widget.titleStyle),
                    ),
                  ),
                  // Toggle switch in title row
                  Semantics(
                    label: _isEnabled
                        ? widget.enabledSemanticLabel
                        : widget.disabledSemanticLabel,
                    toggled: _isEnabled,
                    child: Switch(
                      value: _isEnabled,
                      onChanged: _handleToggle,
                      activeThumbColor: accent,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Scrollable body ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  BankTokens.space4,
                  BankTokens.space4,
                  BankTokens.space4,
                  BankTokens.space4 + MediaQuery.of(context).padding.bottom,
                ),
                child: AnimatedOpacity(
                  opacity: _isEnabled ? 1.0 : 0.38,
                  duration: widget.animationDuration ?? BankTokens.durationBase,
                  curve: widget.animationCurve ?? BankTokens.curveStandard,
                  child: IgnorePointer(
                    ignoring: !_isEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Multiplier ─────────────────────────────────────
                        Text(
                          widget.multiplierSectionLabel,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: BankTokens.space3),
                        Row(
                          children: BankRoundUpSettingsSheet._multiplierOptions
                              .map(
                                (v) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: BankTokens.space2,
                                  ),
                                  child: _MultiplierChip(
                                    value: v,
                                    selected: _multiplier == v,
                                    enabled: _isEnabled,
                                    onSelected: () => _handleMultiplier(v),
                                    accent: accent,
                                    label: widget.multiplierTemplate
                                        .replaceAll('{n}', '$v'),
                                    semanticLabel: widget
                                        .multiplierSemanticTemplate
                                        .replaceAll('{n}', '$v'),
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: BankTokens.space6),

                        // ── Pot picker ─────────────────────────────────────
                        Text(
                          widget.potSectionLabel,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: BankTokens.space2),

                        if (widget.availablePots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: BankTokens.space3,
                            ),
                            child: Text(
                              widget.emptyPotsLabel,
                              style: BankTokens.bodyMedium.copyWith(
                                color: bankTheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...widget.availablePots.map((pot) {
                            final isSelected = _selectedPotId == pot.id;
                            final formattedTarget = BankMoneyFormatter.format(
                              amount: pot.target.amount,
                              currencyCode: pot.target.currencyCode,
                              numeralStyle: scope.numeralStyle,
                            );
                            return Semantics(
                              label: widget.potSemanticTemplate
                                  .replaceAll('{pot}', pot.name)
                                  .replaceAll('{amount}', formattedTarget),
                              selected: isSelected,
                              button: true,
                              child: InkWell(
                                onTap: () => _handlePotSelected(
                                  isSelected ? null : pot.id,
                                ),
                                borderRadius: bankTheme.buttonRadius,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: BankTokens.minTapTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BankTokens.space3,
                                    vertical: BankTokens.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: bankTheme.buttonRadius,
                                    border: Border.all(
                                      color: isSelected
                                          ? accent
                                          : bankTheme.outline,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  margin: const EdgeInsets.only(
                                    bottom: BankTokens.space2,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        widget.potIcon ?? BankIcons.pot,
                                        size: 20,
                                        color: isSelected
                                            ? accent
                                            : bankTheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(
                                        width: BankTokens.space3,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pot.name,
                                              style: BankTokens.labelLarge
                                                  .copyWith(
                                                color: isSelected
                                                    ? accent
                                                    : bankTheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              widget.goalTemplate.replaceAll(
                                                '{amount}',
                                                formattedTarget,
                                              ),
                                              style:
                                                  BankTokens.bodySmall.copyWith(
                                                color:
                                                    bankTheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          widget.selectedIcon ??
                                              Icons.check_circle,
                                          color: accent,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: BankTokens.space6),

                        // ── Explanation text ───────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(BankTokens.space3),
                          decoration: BoxDecoration(
                            color: bankTheme.surfaceVariant,
                            borderRadius: bankTheme.cardRadius,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                BankIcons.info,
                                size: 16,
                                color: bankTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: BankTokens.space2),
                              Expanded(
                                child: Text(
                                  'We\'ll round up every purchase to the '
                                  'nearest £1 and save the difference'
                                  '${_multiplier > 1 ? ' × $_multiplier' : ''} '
                                  'automatically.',
                                  style: BankTokens.bodySmall.copyWith(
                                    color: bankTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
