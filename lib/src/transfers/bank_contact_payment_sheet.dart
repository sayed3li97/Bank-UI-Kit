import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
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
/// 1. Contact picker: search contacts and select one.
/// 2. Amount entry: use [BankAmountKeypad], add an optional note, choose
///    Send or Request.
/// 3. Result: loading indicator, then a compact success or failure message.
///
/// Present it with [BankContactPaymentSheet.show]:
///
/// ```dart
/// await BankContactPaymentSheet.show(
///   context,
///   contacts: myContacts,
///   onSend: (id, amount, note) async => api.send(id, amount, note),
///   onRequest: (id, amount, note) async => api.request(id, amount, note),
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

  /// Overrides the sheet background color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the sheet corner radius. Defaults to the theme sheetRadius.
  final BorderRadiusGeometry? radius;

  /// Overrides the accent used for buttons, toggles and highlights.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the success result icon color. Defaults to
  /// `BankTokens.success`.
  final Color? successColor;

  /// Overrides the error result icon color. Defaults to `BankTokens.danger`.
  final Color? errorColor;

  /// Merged over the header and step title style
  /// (BankTokens.headlineSmall in onSurface).
  final TextStyle? titleStyle;

  /// Fraction of screen height the sheet occupies. Defaults to `0.92`.
  final double? heightFactor;

  /// Duration of the step transition. Defaults to `BankTokens.durationBase`.
  final Duration? animationDuration;

  /// Curve for the incoming step. Defaults to `BankTokens.curveEmphasized`.
  final Curve? animationInCurve;

  /// Curve for the outgoing step. Defaults to `BankTokens.curveStandard`.
  final Curve? animationOutCurve;

  /// Currency code used for amount parsing and display. Defaults to `'USD'`.
  final String currencyCode;

  /// Overrides the back navigation icon. Defaults to `Icons.arrow_back`.
  final IconData backIcon;

  /// Overrides the close icon. Defaults to `Icons.close`.
  final IconData closeIcon;

  /// Overrides the search field icon. Defaults to `BankIcons.search`.
  final IconData searchIcon;

  /// Overrides the send segment and button icon. Defaults to
  /// `Icons.send_outlined`.
  final IconData sendIcon;

  /// Overrides the request segment and button icon. Defaults to
  /// `Icons.download_outlined`.
  final IconData requestIcon;

  /// Overrides the note field icon. Defaults to `Icons.edit_note`.
  final IconData noteIcon;

  /// Overrides the success result icon. Defaults to
  /// `Icons.check_circle_outline`.
  final IconData successIcon;

  /// Overrides the error result icon. Defaults to `Icons.error_outline`.
  final IconData errorIcon;

  /// Tooltip on the back button. Defaults to `'Back'`.
  final String backTooltip;

  /// Tooltip on the close button. Defaults to `'Close'`.
  final String closeTooltip;

  /// Hint for the contact search field. Defaults to `'Search contacts'`.
  final String searchHint;

  /// Shown when no contacts match. Defaults to `'No contacts found'`.
  final String emptyContactsLabel;

  /// Title of the contact picker step. Defaults to `'Select Contact'`.
  final String selectContactTitle;

  /// Title of the amount step in send mode. Defaults to `'Send Money'`.
  final String sendMoneyTitle;

  /// Title of the amount step in request mode. Defaults to `'Request Money'`.
  final String requestMoneyTitle;

  /// Title shown while processing. Defaults to `'Processing…'`.
  final String processingTitle;

  /// Title shown on the success step. Defaults to `'Done'`.
  final String doneTitle;

  /// Title shown on the failure step. Defaults to `'Something went wrong'`.
  final String errorTitle;

  /// Label of the send toggle and confirm button. Defaults to `'Send'`.
  final String sendLabel;

  /// Label of the request toggle and confirm button. Defaults to `'Request'`.
  final String requestLabel;

  /// Hint for the note field. Defaults to `'Add a note (optional)'`.
  final String noteHint;

  /// Semantics label on the send confirm button. Defaults to `'Send money'`.
  final String sendSemanticLabel;

  /// Semantics label on the request confirm button. Defaults to
  /// `'Request money'`.
  final String requestSemanticLabel;

  /// Success headline in send mode. Defaults to `'Money Sent!'`.
  final String sendSuccessTitle;

  /// Success headline in request mode. Defaults to `'Request Sent!'`.
  final String requestSuccessTitle;

  /// Preposition before the recipient name in send mode. Defaults to `'to'`.
  final String sentToLabel;

  /// Preposition before the contact name in request mode. Defaults to
  /// `'from'`.
  final String requestedFromLabel;

  /// Label of the result step done button. Defaults to `'Done'`.
  final String doneButtonLabel;

  const BankContactPaymentSheet({
    required this.contacts,
    super.key,
    this.onClose,
    this.onSend,
    this.onRequest,
    this.backgroundColor,
    this.radius,
    this.accentColor,
    this.successColor,
    this.errorColor,
    this.titleStyle,
    this.heightFactor,
    this.animationDuration,
    this.animationInCurve,
    this.animationOutCurve,
    this.currencyCode = 'USD',
    this.backIcon = Icons.arrow_back,
    this.closeIcon = Icons.close,
    this.searchIcon = BankIcons.search,
    this.sendIcon = Icons.send_outlined,
    this.requestIcon = Icons.download_outlined,
    this.noteIcon = Icons.edit_note,
    this.successIcon = Icons.check_circle_outline,
    this.errorIcon = Icons.error_outline,
    this.backTooltip = 'Back',
    this.closeTooltip = 'Close',
    this.searchHint = 'Search contacts',
    this.emptyContactsLabel = 'No contacts found',
    this.selectContactTitle = 'Select Contact',
    this.sendMoneyTitle = 'Send Money',
    this.requestMoneyTitle = 'Request Money',
    this.processingTitle = 'Processing…',
    this.doneTitle = 'Done',
    this.errorTitle = 'Something went wrong',
    this.sendLabel = 'Send',
    this.requestLabel = 'Request',
    this.noteHint = 'Add a note (optional)',
    this.sendSemanticLabel = 'Send money',
    this.requestSemanticLabel = 'Request money',
    this.sendSuccessTitle = 'Money Sent!',
    this.requestSuccessTitle = 'Request Sent!',
    this.sentToLabel = 'to',
    this.requestedFromLabel = 'from',
    this.doneButtonLabel = 'Done',
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
    final raw = _amountText.replaceAll(RegExp('[^0-9.]'), '');
    final val = double.tryParse(raw) ?? 0.0;
    return Money.fromDouble(val, widget.currencyCode);
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

    final accent = widget.accentColor ?? bankTheme.primary;

    return Container(
      height: mediaQuery.size.height * (widget.heightFactor ?? 0.92),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? bankTheme.surface,
        borderRadius: widget.radius ?? bankTheme.sheetRadius,
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
                color: bankTheme.outline.withValues(alpha: 0.4),
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
                    icon: Icon(widget.backIcon),
                    tooltip: widget.backTooltip,
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
                    style: BankTokens.headlineSmall
                        .copyWith(color: bankTheme.onSurface)
                        .merge(widget.titleStyle),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(widget.closeIcon),
                  tooltip: widget.closeTooltip,
                  onPressed: _close,
                ),
              ],
            ),
          ),
          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: widget.animationDuration ?? BankTokens.durationBase,
              switchInCurve:
                  widget.animationInCurve ?? BankTokens.curveEmphasized,
              switchOutCurve:
                  widget.animationOutCurve ?? BankTokens.curveStandard,
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: switch (_step) {
                  0 => _ContactPickerStep(
                      contacts: _filtered,
                      searchController: _searchController,
                      bankTheme: bankTheme,
                      onSelect: _selectContact,
                      accentColor: accent,
                      searchHint: widget.searchHint,
                      emptyLabel: widget.emptyContactsLabel,
                      searchIcon: widget.searchIcon,
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
                      accentColor: accent,
                      currencyCode: widget.currencyCode,
                      sendLabel: widget.sendLabel,
                      requestLabel: widget.requestLabel,
                      noteHint: widget.noteHint,
                      sendIcon: widget.sendIcon,
                      requestIcon: widget.requestIcon,
                      noteIcon: widget.noteIcon,
                      sendSemanticLabel: widget.sendSemanticLabel,
                      requestSemanticLabel: widget.requestSemanticLabel,
                    ),
                  _ => _ResultStep(
                      loading: _loading,
                      success: _success,
                      error: _error,
                      mode: _mode,
                      selected: _selected,
                      bankTheme: bankTheme,
                      onDone: _close,
                      accentColor: accent,
                      successColor: widget.successColor ?? BankTokens.success,
                      errorColor: widget.errorColor ?? BankTokens.danger,
                      successIcon: widget.successIcon,
                      errorIcon: widget.errorIcon,
                      errorTitle: widget.errorTitle,
                      sendSuccessTitle: widget.sendSuccessTitle,
                      requestSuccessTitle: widget.requestSuccessTitle,
                      sentToLabel: widget.sentToLabel,
                      requestedFromLabel: widget.requestedFromLabel,
                      doneLabel: widget.doneButtonLabel,
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
        0 => widget.selectContactTitle,
        1 => _mode == _PaymentMode.send
            ? widget.sendMoneyTitle
            : widget.requestMoneyTitle,
        _ => _loading
            ? widget.processingTitle
            : _success
                ? widget.doneTitle
                : widget.errorTitle,
      };
}

// ---------------------------------------------------------------------------
// Step 0: Contact picker
// ---------------------------------------------------------------------------

class _ContactPickerStep extends StatelessWidget {
  const _ContactPickerStep({
    required this.contacts,
    required this.searchController,
    required this.bankTheme,
    required this.onSelect,
    required this.accentColor,
    required this.searchHint,
    required this.emptyLabel,
    required this.searchIcon,
  });

  final List<BankSplitParticipant> contacts;
  final TextEditingController searchController;
  final BankThemeData bankTheme;
  final ValueChanged<BankSplitParticipant> onSelect;
  final Color accentColor;
  final String searchHint;
  final String emptyLabel;
  final IconData searchIcon;

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
            style: BankTokens.bodyLarge.copyWith(color: bankTheme.onSurface),
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: BankTokens.bodyLarge
                  .copyWith(color: bankTheme.onSurfaceVariant),
              prefixIcon: Icon(
                searchIcon,
                color: bankTheme.onSurfaceVariant,
                size: 20,
              ),
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
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ),
        // Grid of avatar buttons
        Expanded(
          child: contacts.isEmpty
              ? Center(
                  child: Text(
                    emptyLabel,
                    style: BankTokens.bodyMedium.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(BankTokens.space4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            if (contact.avatarUrl != null)
              CircleAvatar(
                radius: 28,
                backgroundImage: BankUiScope.imageProviderFor(
                  context,
                  contact.avatarUrl!,
                ),
                backgroundColor: bankTheme.surfaceVariant,
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: bankTheme.primary.withValues(alpha: 0.15),
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
// Step 1: Amount entry
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
    required this.accentColor,
    required this.currencyCode,
    required this.sendLabel,
    required this.requestLabel,
    required this.noteHint,
    required this.sendIcon,
    required this.requestIcon,
    required this.noteIcon,
    required this.sendSemanticLabel,
    required this.requestSemanticLabel,
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
  final Color accentColor;
  final String currencyCode;
  final String sendLabel;
  final String requestLabel;
  final String noteHint;
  final IconData sendIcon;
  final IconData requestIcon;
  final IconData noteIcon;
  final String sendSemanticLabel;
  final String requestSemanticLabel;

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
                if (selected.avatarUrl != null)
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: BankUiScope.imageProviderFor(
                      context,
                      selected.avatarUrl!,
                    ),
                    backgroundColor: bankTheme.surfaceVariant,
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: bankTheme.primary.withValues(alpha: 0.15),
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
              segments: [
                ButtonSegment(
                  value: _PaymentMode.send,
                  label: Text(sendLabel),
                  icon: Icon(sendIcon, size: 16),
                ),
                ButtonSegment(
                  value: _PaymentMode.request,
                  label: Text(requestLabel),
                  icon: Icon(requestIcon, size: 16),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) onModeChanged(s.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? accentColor
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
            currencyCode: currencyCode,
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
            style: BankTokens.bodyMedium.copyWith(color: bankTheme.onSurface),
            decoration: InputDecoration(
              hintText: noteHint,
              hintStyle: BankTokens.bodyMedium
                  .copyWith(color: bankTheme.onSurfaceVariant),
              filled: true,
              fillColor: bankTheme.surfaceVariant,
              prefixIcon: Icon(
                noteIcon,
                size: 20,
                color: bankTheme.onSurfaceVariant,
              ),
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
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          // Confirm button
          Semantics(
            button: true,
            label: mode == _PaymentMode.send
                ? sendSemanticLabel
                : requestSemanticLabel,
            child: FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: bankTheme.onPrimary,
                disabledBackgroundColor:
                    bankTheme.outline.withValues(alpha: 0.3),
                minimumSize: const Size(
                  double.infinity,
                  BankTokens.minTapTarget,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(
                mode == _PaymentMode.send ? sendLabel : requestLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Result
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
    required this.accentColor,
    required this.successColor,
    required this.errorColor,
    required this.successIcon,
    required this.errorIcon,
    required this.errorTitle,
    required this.sendSuccessTitle,
    required this.requestSuccessTitle,
    required this.sentToLabel,
    required this.requestedFromLabel,
    required this.doneLabel,
  });

  final bool loading;
  final bool success;
  final String? error;
  final _PaymentMode mode;
  final BankSplitParticipant? selected;
  final BankThemeData bankTheme;
  final VoidCallback onDone;
  final Color accentColor;
  final Color successColor;
  final Color errorColor;
  final IconData successIcon;
  final IconData errorIcon;
  final String errorTitle;
  final String sendSuccessTitle;
  final String requestSuccessTitle;
  final String sentToLabel;
  final String requestedFromLabel;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          color: accentColor,
          strokeWidth: 2.5,
        ),
      );
    }

    final isError = error != null;

    return Padding(
      padding: const EdgeInsets.all(BankTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? errorIcon : successIcon,
            size: 72,
            color: isError ? errorColor : successColor,
          ),
          const SizedBox(height: BankTokens.space4),
          Text(
            isError
                ? errorTitle
                : mode == _PaymentMode.send
                    ? sendSuccessTitle
                    : requestSuccessTitle,
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
                  ? '$sentToLabel ${selected!.name}'
                  : '$requestedFromLabel ${selected!.name}',
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
              backgroundColor: accentColor,
              foregroundColor: bankTheme.onPrimary,
              minimumSize: const Size(
                double.infinity,
                BankTokens.minTapTarget,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: bankTheme.buttonRadius,
              ),
            ),
            child: Text(doneLabel),
          ),
        ],
      ),
    );
  }
}
