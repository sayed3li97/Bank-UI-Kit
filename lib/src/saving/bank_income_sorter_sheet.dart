import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/money_formatter.dart';
import '../../src/controllers/bank_income_sorter_controller.dart';
import '../../src/models/savings_pot.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Triggered on a large incoming payment. Splits across pots by percentage
/// or fixed amount. Backed by [BankIncomeSorterController].
class BankIncomeSorterSheet extends StatefulWidget {
  final BankIncomeSorterController controller;
  final VoidCallback? onDismiss;

  /// Heading of the sheet. Defaults to 'Income Received'.
  final String title;

  /// Label of the remaining row. Defaults to 'Remaining'.
  final String remainingLabel;

  /// Caption of the add-pot action. Defaults to 'Add pot'.
  final String addPotLabel;

  /// Caption of the repeat switch. Defaults to
  /// 'Repeat this split automatically next time'.
  final String repeatLabel;

  /// Caption of the confirm button. Defaults to 'Confirm'.
  final String confirmLabel;

  /// Tooltip on each entry's remove button. Defaults to 'Remove'.
  final String removeEntryTooltip;

  /// Overrides the sheet content padding. Defaults to space4 with a
  /// space2 top inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the sheet corner radius. Defaults to the theme
  /// sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the incoming amount and switch accent. Defaults to the
  /// theme primary colour.
  final Color? accentColor;

  /// Merged over the computed heading style
  /// ([BankTokens.headlineSmall] in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed incoming-amount style
  /// ([BankTokens.numeralHero] in the accent colour).
  final TextStyle? amountStyle;

  /// Overrides the add-pot glyph. Defaults to [Icons.add].
  final IconData? addPotIcon;

  /// Overrides the entry remove glyph. Defaults to [Icons.close].
  final IconData? removeEntryIcon;

  const BankIncomeSorterSheet({
    required this.controller,
    super.key,
    this.onDismiss,
    this.title = 'Income Received',
    this.remainingLabel = 'Remaining',
    this.addPotLabel = 'Add pot',
    this.repeatLabel = 'Repeat this split automatically next time',
    this.confirmLabel = 'Confirm',
    this.removeEntryTooltip = 'Remove',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.amountStyle,
    this.addPotIcon,
    this.removeEntryIcon,
  });

  static Future<void> show(
    BuildContext context, {
    required BankIncomeSorterController controller,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankIncomeSorterSheet(controller: controller),
      );

  @override
  State<BankIncomeSorterSheet> createState() => _BankIncomeSorterSheetState();
}

class _BankIncomeSorterSheetState extends State<BankIncomeSorterSheet> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() => setState(_syncControllers);

  void _syncControllers() {
    final entries = widget.controller.entries;
    while (_controllers.length < entries.length) {
      final index = _controllers.length;
      _controllers.add(
        TextEditingController(
          text: entries[index].fractionOrFixed.toStringAsFixed(2),
        ),
      );
    }
    while (_controllers.length > entries.length) {
      _controllers.removeLast().dispose();
    }
  }

  void _addPot(SavingsPot pot) {
    widget.controller.addEntry(
      IncomeSorterEntry(
        potId: pot.id,
        potName: pot.name,
        fractionOrFixed: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final ctrl = widget.controller;

    final usedPotIds = ctrl.entries.map((e) => e.potId).toSet();
    final availablePots =
        ctrl.availablePots.where((p) => !usedPotIds.contains(p.id)).toList();

    final incomingFormatted = BankMoneyFormatter.format(
      amount: ctrl.incomingAmount.amount,
      currencyCode: ctrl.incomingAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final remainingFormatted = BankMoneyFormatter.format(
      amount: ctrl.remaining.amount,
      currencyCode: ctrl.remaining.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final accent = widget.accentColor ?? theme.primary;
    final resolvedPadding = widget.padding ??
        const EdgeInsets.fromLTRB(
          BankTokens.space4,
          BankTokens.space2,
          BankTokens.space4,
          BankTokens.space4,
        );

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.surface,
        borderRadius: widget.radius ?? theme.sheetRadius,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(theme: theme),
            Padding(
              padding: resolvedPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: BankTokens.headlineSmall
                        .copyWith(color: theme.onSurface)
                        .merge(widget.titleStyle),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    incomingFormatted,
                    style: BankTokens.numeralHero
                        .copyWith(color: accent)
                        .merge(widget.amountStyle),
                  ),
                  const SizedBox(height: BankTokens.space4),
                  ...List.generate(ctrl.entries.length, (i) {
                    final entry = ctrl.entries[i];
                    return _EntryRow(
                      key: ValueKey(entry.potId),
                      entry: entry,
                      amountController: _controllers[i],
                      onChanged: (value) {
                        final updated = entry.copyWith(fractionOrFixed: value);
                        widget.controller.updateEntry(i, updated);
                      },
                      onDelete: () => widget.controller.removeEntry(i),
                      theme: theme,
                      scope: scope,
                      removeTooltip: widget.removeEntryTooltip,
                      removeIcon: widget.removeEntryIcon,
                    );
                  }),
                  const SizedBox(height: BankTokens.space2),
                  _RemainingRow(
                    label: widget.remainingLabel,
                    amount: remainingFormatted,
                    isValid: ctrl.isValid,
                    theme: theme,
                  ),
                  if (availablePots.isNotEmpty) ...[
                    const SizedBox(height: BankTokens.space3),
                    TextButton.icon(
                      onPressed: () => _showPotPicker(context, availablePots),
                      icon: Icon(widget.addPotIcon ?? Icons.add),
                      label: Text(widget.addPotLabel),
                    ),
                  ],
                  const SizedBox(height: BankTokens.space3),
                  SwitchListTile(
                    value: ctrl.saveForNext,
                    onChanged: widget.controller.setSaveForNext,
                    title: Text(
                      widget.repeatLabel,
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurface),
                    ),
                    activeColor: accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: BankTokens.space4),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: ctrl.isValid
                          ? () {
                              ctrl.confirm();
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text(widget.confirmLabel),
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

  Future<void> _showPotPicker(
    BuildContext context,
    List<SavingsPot> pots,
  ) async {
    final picked = await showModalBottomSheet<SavingsPot>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: pots
            .map(
              (p) => ListTile(
                title: Text(p.name),
                onTap: () => Navigator.of(context).pop(p),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null) _addPot(picked);
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.theme});
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: BankTokens.space3),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _EntryRow extends StatelessWidget {
  final IncomeSorterEntry entry;
  final TextEditingController amountController;
  final ValueChanged<double> onChanged;
  final VoidCallback onDelete;
  final BankThemeData theme;
  final BankUiScopeData scope;
  final String removeTooltip;
  final IconData? removeIcon;

  const _EntryRow({
    required this.entry,
    required this.amountController,
    required this.onChanged,
    required this.onDelete,
    required this.theme,
    required this.scope,
    required this.removeTooltip,
    super.key,
    this.removeIcon,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BankTokens.space3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.potName,
                style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                ],
                textAlign: TextAlign.end,
                style: BankTokens.numeralSmall.copyWith(color: theme.onSurface),
                decoration: InputDecoration(
                  suffixText: entry.isPercentage ? '%' : '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space2,
                    vertical: BankTokens.space2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                  ),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) onChanged(parsed);
                },
              ),
            ),
            IconButton(
              icon: Icon(
                removeIcon ?? Icons.close,
                color: theme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: onDelete,
              tooltip: removeTooltip,
            ),
          ],
        ),
      );
}

class _RemainingRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isValid;
  final BankThemeData theme;

  const _RemainingRow({
    required this.label,
    required this.amount,
    required this.isValid,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                BankTokens.labelMedium.copyWith(color: theme.onSurfaceVariant),
          ),
          Text(
            amount,
            style: BankTokens.numeralSmall.copyWith(
              color: isValid ? theme.positiveBalance : theme.negativeBalance,
            ),
          ),
        ],
      );
}
