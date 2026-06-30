import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../../src/transactions/bank_transaction_cost_split_sheet.dart'
    show BankSplitParticipant;
import 'bank_amount_keypad.dart';

// ---------------------------------------------------------------------------
// BankContactPaymentSheet
// ---------------------------------------------------------------------------

/// Pick a contact (in-network or by phone/email), then send or request money.
///
/// Runs a three-step flow:
/// 1. Contact picker — search contacts and select one.
/// 2. Amount entry — use [BankAmountKeypad], add an optional note, choose
///    Send or Request.
/// 3. Result — loading indicator, then a compact success or failure message.
///
/// Present it with [BankContactPaymentSheet.show]:
///
/// ```dart
/// await BankContactPaymentSheet.show(
///   context,
///   contacts: myContacts,
///   onSend: (id, amount, note) async { await api.send(id, amount, note); },
///   onRequest: (id, amount, note) async { await api.request(id, amount, note); },
/// );
/// ```
class BankContactPaymentSheet extends StatefulWidget {
  /// Contacts available for selection.
  final List<BankSplitParticipant> contacts;

  /// Called when the sheet is closed via its own close button.
  final VoidCallback? onClose;

  /// Called when the user confirms a Send action. The host app is responsible
  /// for executing the payment and should throw on failure.
  final Future<void> Function(String contactId, Money amount, String? note)?
      onSend;

  /// Called when the user confirms a Request action. The host app is
  /// responsible for sending the request and should throw on failure.
  final Future<void> Function(String contactId, Money amount, String? note)?
      onRequest;

  const BankContactPaymentSheet({
    super.key,
    required this.contacts,
    this.onClose,
    this.onSend,
    this.onRequest,
  });

  // ---------------------------------------------------------------------------
  // Static show helper
  // ---------------------------------------------------------------------------

  /// Presents the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<BankSplitParticipant> contacts,
    Future<void> Function(String, Money, String?)? onSend,
    Future<void> Function(String, Money, String?)? onRequest,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankContactPaymentSheet(
          contacts: contacts,
          onSend: onSend,
          onRequest: onRequest,
        ),
      );

  @override
  State<BankContactPaymentSheet> createState() =>
      _BankContactPaymentSheetState();
}

// ---------------------------------------------------------------------------
// _PaymentMode
// ---------------------------------------------------------------------------

enum _PaymentMode { send, request }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _BankContactPaymentSheetState extends State<BankContactPaymentSheet> {
  // Step 0 = contact picker, 1 = amount entry, 2 = result
  int _step = 0;

  BankSplitParticipant? _selected;
  String _amountText = '';
  String _note = '';
  _PaymentMode _mode = _PaymentMode.send;
  bool _loading = false;
  bool _success = false;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<BankSplitParticipant> get _filtered {
    if (_query.isEmpty) return widget.contacts;
    return widget.contacts
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();
  }

  Money get _parsedAmount {
    final raw = _amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(raw) ?? 0.0;
    return Money.fromDouble(val, 'USD');
  }

  bool get _canConfirm =>
      _selected != null &&
      _amountText.isNotEmpty &&
      (_parsedAmount.amount.toDouble() > 0);

  void _selectContact(BankSplitParticipant contact) {
    setState(() {
      _selected = contact;
      _step = 1;
    });
  }

  void _onDigit(String d) {
    setState(() {
      if (_amountText == '0') {
        _amountText = d;
      } else {
        _amountText += d;
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_amountText.isNotEmpty) {
        _amountText = _amountText.substring(0, _amountText.length - 1);
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (!_amountText.contains('.')) {
        _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
      }
    });
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() {
      _loading = true;
      _error = null;
      _step = 2;
    });

    final amount = _parsedAmount;
    final note = _note.isNotEmpty ? _note : null;
    final id = _selected!.id;

    try {
      if (_mode == _PaymentMode.send) {
        await widget.onSend?.call(id, amount, note);
      } else {
        await widget.onRequest?.call(id, amount, note);
      }
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.92,
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: bankTheme.sheetRadius,
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: BankTokens.space3),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: bankTheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(BankTokens.radiusFull),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space4,
              BankTokens.space3,
              BankTokens.space2,
              0,
            ),
            child: Row(
              children: [
                if (_step > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: () {
                      setState(() {
                        if (_step == 1) {
                          _step = 0;
                          _amountText = '';
                          _note = '';
                          _noteController.clear();
                        } else {
                          _step = 1;
                          _loading = false;
                          _success = false;
                          _error = null;
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _stepTitle(),
                    style: BankTokens.headlineSmall.copyWith(
                      color: bankTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: _close,
                ),
              ],
            ),
          ),
          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: BankTokens.durationBase,
              switchInCurve: BankTokens.curveEmphasized,
              switchOutCurve: BankTokens.curveStandard,
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: switch (_step) {
                  0 => _ContactPickerStep(
                      contacts: _filtered,
                      searchController: _searchController,
                      bankTheme: bankTheme,
                      onSelect: _selectContact,
                    ),
                  1 => _AmountStep(
                      selected: _selected!,
                      amountText: _amountText,
                      note: _note,
                      noteController: _noteController,
                      mode: _mode,
                      canConfirm: _canConfirm,
                      bankTheme: bankTheme,
                      hasSend: widget.onSend != null,
                      hasRequest: widget.onRequest != null,
                      onDigit: _onDigit,
                      onDelete: _onDelete,
                      onDecimal: _onDecimal,
                      onModeChanged: (m) => setState(() => _mode = m),
                      onNoteChanged: (v) => setState(() => _note = v),
                      onConfirm: _confirm,
                    ),
                  _ => _ResultStep(
                      loading: _loading,
                      success: _success,
                      error: _error,
                      mode: _mode,
                      selected: _selected,
                      bankTheme: bankTheme,
                      onDone: _close,
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle() => switch (_step) {
    0 => 'Select Contact',
    1 => _mode == _PaymentMode.send ? 'Send Money' : 'Request Money',
    _ => _loading
        ? 'Processing…'
        : _success
            ? 'Done'
            : 'Something went wrong',
  };
}

// ---------------------------------------------------------------------------
// Step 0 — Contact picker
// ---------------------------------------------------------------------------

class _ContactPickerStep extends StatelessWidget {
  const _ContactPickerStep({
    required this.contacts,
    required this.searchController,
    required this.bankTheme,
    required this.onSelect,
  });

  final List<BankSplitParticipant> contacts;
  final TextEditingController searchController;
  final BankThemeData bankTheme;
  final ValueChanged<BankSplitParticipant> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space3,
            BankTokens.space4,
            BankTokens.space2,
          ),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style:
                BankTokens.bodyLarge.copyWith(color: bankTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search contacts',
              hintStyle: BankTokens.bodyLarge
                  .copyWith(color: bankTheme.onSurfaceVariant),
              prefixIcon: Icon(BankIcons.search,
                  color: bankTheme.onSurfaceVariant, size: 20),
              filled: true,
              fillColor: bankTheme.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              border: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide(color: bankTheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
        // Grid of avatar buttons
        Expanded(
          child: contacts.isEmpty
              ? Center(
                  child: Text(
                    'No contacts found',
                    style: BankTokens.bodyMedium.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(BankTokens.space4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: BankTokens.space4,
                    crossAxisSpacing: BankTokens.space3,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: contacts.length,
                  itemBuilder: (context, i) {
                    final c = contacts[i];
                    return _ContactCell(
                      contact: c,
                      bankTheme: bankTheme,
                      onTap: () => onSelect(c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ContactCell extends StatelessWidget {
  const _ContactCell({
    required this.contact,
    required this.bankTheme,
    required this.onTap,
  });

  final BankSplitParticipant contact;
  final BankThemeData bankTheme;
  final VoidCallback onTap;

  String get _initials {
    final parts = contact.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: contact.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            contact.avatarUrl != null
                ? CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(contact.avatarUrl!),
                    backgroundColor: bankTheme.surfaceVariant,
                  )
                : CircleAvatar(
                    radius: 28,
                    backgroundColor: bankTheme.primary.withOpacity(0.15),
                    child: Text(
                      _initials,
                      style: BankTokens.labelMedium.copyWith(
                        color: bankTheme.primary,
                      ),
                    ),
                  ),
            const SizedBox(height: BankTokens.space2),
            Text(
              contact.name.split(' ').first,
              style: BankTokens.bodySmall.copyWith(
                color: bankTheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Amount entry
// ---------------------------------------------------------------------------

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.selected,
    required this.amountText,
    required this.note,
    required this.noteController,
    required this.mode,
    required this.canConfirm,
    required this.bankTheme,
    required this.hasSend,
    required this.hasRequest,
    required this.onDigit,
    required this.onDelete,
    required this.onDecimal,
    required this.onModeChanged,
    required this.onNoteChanged,
    required this.onConfirm,
  });

  final BankSplitParticipant selected;
  final String amountText;
  final String note;
  final TextEditingController noteController;
  final _PaymentMode mode;
  final bool canConfirm;
  final BankThemeData bankTheme;
  final bool hasSend;
  final bool hasRequest;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onDecimal;
  final ValueChanged<_PaymentMode> onModeChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onConfirm;

  String get _initials {
    final parts = selected.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BankTokens.space4,
        BankTokens.space3,
        BankTokens.space4,
        BankTokens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected contact chip
          Center(
            child: Column(
              children: [
                selected.avatarUrl != null
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(selected.avatarUrl!),
                        backgroundColor: bankTheme.surfaceVariant,
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: bankTheme.primary.withOpacity(0.15),
                        child: Text(
                          _initials,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.primary,
                          ),
                        ),
                      ),
                const SizedBox(height: BankTokens.space2),
                Text(
                  selected.name,
                  style: BankTokens.bodyLarge.copyWith(
                    color: bankTheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          // Send / Request toggle (only show if both callbacks available)
          if (hasSend && hasRequest) ...[
            SegmentedButton<_PaymentMode>(
              segments: const [
                ButtonSegment(
                  value: _PaymentMode.send,
                  label: Text('Send'),
                  icon: Icon(Icons.send_outlined, size: 16),
                ),
                ButtonSegment(
                  value: _PaymentMode.request,
                  label: Text('Request'),
                  icon: Icon(Icons.download_outlined, size: 16),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) onModeChanged(s.first);
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
                minimumSize: WidgetStateProperty.all(
                  const Size(0, BankTokens.minTapTarget),
                ),
              ),
            ),
            const SizedBox(height: BankTokens.space4),
          ],
          // Amount keypad
          BankAmountKeypad(
            amountText: amountText,
            currencyCode: 'USD',
            onDigit: onDigit,
            onDelete: onDelete,
            onDecimalPoint: onDecimal,
          ),
          const SizedBox(height: BankTokens.space4),
          // Note field
          TextField(
            controller: noteController,
            onChanged: onNoteChanged,
            maxLength: 100,
            style:
                BankTokens.bodyMedium.copyWith(color: bankTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: BankTokens.bodyMedium
                  .copyWith(color: bankTheme.onSurfaceVariant),
              filled: true,
              fillColor: bankTheme.surfaceVariant,
              prefixIcon: Icon(Icons.edit_note,
                  size: 20, color: bankTheme.onSurfaceVariant),
              counterStyle: BankTokens.bodySmall
                  .copyWith(color: bankTheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: bankTheme.chipRadius,
                borderSide: BorderSide(color: bankTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          // Confirm button
          Semantics(
            button: true,
            label: mode == _PaymentMode.send ? 'Send money' : 'Request money',
            child: FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: bankTheme.primary,
                foregroundColor: bankTheme.onPrimary,
                disabledBackgroundColor: bankTheme.outline.withOpacity(0.3),
                minimumSize: const Size(
                  double.infinity,
                  BankTokens.minTapTarget,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(
                mode == _PaymentMode.send ? 'Send' : 'Request',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Result
// ---------------------------------------------------------------------------

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    required this.loading,
    required this.success,
    required this.error,
    required this.mode,
    required this.selected,
    required this.bankTheme,
    required this.onDone,
  });

  final bool loading;
  final bool success;
  final String? error;
  final _PaymentMode mode;
  final BankSplitParticipant? selected;
  final BankThemeData bankTheme;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          color: bankTheme.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    final bool isError = error != null;

    return Padding(
      padding: const EdgeInsets.all(BankTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 72,
            color: isError ? BankTokens.danger : BankTokens.success,
          ),
          const SizedBox(height: BankTokens.space4),
          Text(
            isError
                ? 'Something went wrong'
                : mode == _PaymentMode.send
                    ? 'Money Sent!'
                    : 'Request Sent!',
            style: BankTokens.headlineMedium.copyWith(
              color: bankTheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (isError && error != null) ...[
            const SizedBox(height: BankTokens.space3),
            Text(
              error!,
              style: BankTokens.bodyMedium.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (selected != null) ...[
            const SizedBox(height: BankTokens.space2),
            Text(
              mode == _PaymentMode.send
                  ? 'to ${selected!.name}'
                  : 'from ${selected!.name}',
              style: BankTokens.bodyMedium.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: BankTokens.space6),
          FilledButton(
            onPressed: onDone,
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
