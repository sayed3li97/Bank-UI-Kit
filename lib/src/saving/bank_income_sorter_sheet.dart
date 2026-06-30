import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/money_formatter.dart';
import '../../controllers/bank_income_sorter_controller.dart';
import '../../models/savings_pot.dart';
import '../../scope/bank_ui_scope.dart';
import '../../theme/bank_theme_data.dart';
import '../../theme/tokens.dart';

/// Triggered on a large incoming payment. Splits across pots by percentage
/// or fixed amount. Backed by [BankIncomeSorterController].
class BankIncomeSorterSheet extends StatefulWidget {
  final BankIncomeSorterController controller;
  final VoidCallback? onDismiss;

  const BankIncomeSorterSheet({
    super.key,
    required this.controller,
    this.onDismiss,
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

  void _onControllerChanged() => setState(() => _syncControllers());

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
        isPercentage: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final ctrl = widget.controller;

    final usedPotIds = ctrl.entries.map((e) => e.potId).toSet();
    final availablePots = ctrl.availablePots
        .where((p) => !usedPotIds.contains(p.id))
        .toList();

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

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.sheetRadius,
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
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space2,
                BankTokens.space4,
                BankTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Received',
                    style: BankTokens.headlineSmall
                        .copyWith(color: theme.onSurface),
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    incomingFormatted,
                    style: BankTokens.numeralHero
                        .copyWith(color: theme.primary),
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
                    );
                  }),
                  const SizedBox(height: BankTokens.space2),
                  _RemainingRow(
                    label: 'Remaining',
                    amount: remainingFormatted,
                    isValid: ctrl.isValid,
                    theme: theme,
                  ),
                  if (availablePots.isNotEmpty) ...[
                    const SizedBox(height: BankTokens.space3),
                    TextButton.icon(
                      onPressed: () => _showPotPicker(context, availablePots),
                      icon: const Icon(Icons.add),
                      label: const Text('Add pot'),
                    ),
                  ],
                  const SizedBox(height: BankTokens.space3),
                  SwitchListTile(
                    value: ctrl.saveForNext,
                    onChanged: widget.controller.setSaveForNext,
                    title: Text(
                      'Repeat this split automatically next time',
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurface),
                    ),
                    activeColor: theme.primary,
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
                      child: const Text('Confirm'),
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

  const _EntryRow({
    super.key,
    required this.entry,
    required this.amountController,
    required this.onChanged,
    required this.onDelete,
    required this.theme,
    required this.scope,
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
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textAlign: TextAlign.end,
                style:
                    BankTokens.numeralSmall.copyWith(color: theme.onSurface),
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
              icon: Icon(Icons.close, color: theme.onSurfaceVariant, size: 20),
              onPressed: onDelete,
              tooltip: 'Remove',
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
            style: BankTokens.labelMedium
                .copyWith(color: theme.onSurfaceVariant),
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
