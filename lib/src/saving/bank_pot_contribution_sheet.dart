import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/numeral_style.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Sheet handle bar
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
// Inline number pad
// ---------------------------------------------------------------------------

/// A compact inline numeric keypad that appends digits to a string amount.
/// Implemented inline to avoid circular imports with BankAmountKeypad.
class _InlineNumPad extends StatelessWidget {
  const _InlineNumPad({
    required this.onDigit,
    required this.onDelete,
    required this.onDecimal,
    required this.enabled,
    required this.bankTheme,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onDecimal;
  final bool enabled;
  final BankThemeData bankTheme;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          _buildRow(row.map(_buildDigitKey).toList()),
          const SizedBox(height: BankTokens.space2),
        ],
        _buildRow([
          _buildDecimalKey(),
          _buildDigitKey('0'),
          _buildDeleteKey(),
        ]),
      ],
    );
  }

  Widget _buildRow(List<Widget> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: BankTokens.space2),
          keys[i],
        ],
      ],
    );
  }

  Widget _buildKeyCell({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: bankTheme.buttonRadius,
          splashColor: bankTheme.primary.withValues(alpha: 0.12),
          child: Container(
            width: 88,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: bankTheme.buttonRadius,
              color: bankTheme.surfaceVariant,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildDigitKey(String digit) {
    return _buildKeyCell(
      semanticLabel: digit,
      onTap: () {
        HapticFeedback.selectionClick();
        onDigit(digit);
      },
      child: Text(
        digit,
        style: BankTokens.headlineMedium.copyWith(
          color: enabled ? bankTheme.onSurface : bankTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDecimalKey() {
    return _buildKeyCell(
      semanticLabel: 'Decimal point',
      onTap: () {
        HapticFeedback.selectionClick();
        onDecimal();
      },
      child: Text(
        '.',
        style: BankTokens.headlineMedium.copyWith(
          color: enabled ? bankTheme.onSurface : bankTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return _buildKeyCell(
      semanticLabel: 'Delete',
      onTap: () {
        HapticFeedback.selectionClick();
        onDelete();
      },
      child: Icon(
        Icons.backspace_outlined,
        size: 22,
        color: enabled ? bankTheme.onSurface : bankTheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validation helper
// ---------------------------------------------------------------------------

enum _ValidationError {
  none,
  exceededPotTarget,
  exceededPotBalance,
  exceededAvailableBalance,
}

// ---------------------------------------------------------------------------
// Main sheet widget
// ---------------------------------------------------------------------------

/// Manual add-to-pot or withdraw-from-pot flow.
///
/// Presents a large amount display, an inline number pad, real-time
/// validation, and a confirm button that triggers the supplied [onConfirm]
/// callback. Shows a loading spinner while awaiting the async callback.
///
/// Use [BankPotContributionSheet.show] to display the sheet as a modal bottom
/// sheet.
class BankPotContributionSheet extends StatefulWidget {
  /// The target savings pot.
  final SavingsPot pot;

  /// When `true`, the sheet is in withdrawal mode; otherwise contribution mode.
  final bool isWithdrawal;

  /// Maximum available balance for withdrawals (e.g. the pot's current balance
  /// or the main account balance). `null` means uncapped.
  final Money? availableBalance;

  /// Called with the confirmed [Money] amount. May be async; a loading state
  /// is shown while it completes.
  final Future<void> Function(Money amount) onConfirm;

  /// Called when the user cancels. When `null`, only the back gesture closes
  /// the sheet.
  final VoidCallback? onCancel;

  const BankPotContributionSheet({
    required this.pot,
    required this.onConfirm,
    super.key,
    this.isWithdrawal = false,
    this.availableBalance,
    this.onCancel,
  });

  /// Convenience helper to push the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SavingsPot pot,
    required Future<void> Function(Money) onConfirm,
    bool isWithdrawal = false,
    Money? availableBalance,
    VoidCallback? onCancel,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankPotContributionSheet(
          pot: pot,
          isWithdrawal: isWithdrawal,
          availableBalance: availableBalance,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      );

  @override
  State<BankPotContributionSheet> createState() =>
      _BankPotContributionSheetState();
}

class _BankPotContributionSheetState extends State<BankPotContributionSheet> {
  /// Raw digit string, e.g. '12.50'.
  String _raw = '';
  bool _isLoading = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Amount helpers
  // ──────────────────────────────────────────────────────────────────────────

  Decimal get _parsedAmount {
    if (_raw.isEmpty) return Decimal.zero;
    return Decimal.tryParse(_raw) ?? Decimal.zero;
  }

  bool get _isZero => _parsedAmount == Decimal.zero;

  _ValidationError get _validationError {
    if (_isZero) return _ValidationError.none;

    final amount = _parsedAmount;

    if (widget.isWithdrawal) {
      // Cannot withdraw more than the pot holds.
      if (amount > widget.pot.current.amount) {
        return _ValidationError.exceededPotBalance;
      }
      // Cannot withdraw more than the main account can receive (optional).
      if (widget.availableBalance != null &&
          amount > widget.availableBalance!.amount) {
        return _ValidationError.exceededAvailableBalance;
      }
    } else {
      // Cannot add more than what's needed to reach the target.
      final remaining = widget.pot.target.amount - widget.pot.current.amount;
      if (remaining > Decimal.zero && amount > remaining) {
        return _ValidationError.exceededPotTarget;
      }
    }

    return _ValidationError.none;
  }

  bool get _canConfirm =>
      !_isZero && _validationError == _ValidationError.none && !_isLoading;

  String _errorMessage(BankThemeData bankTheme, BankUiScopeData scope) {
    switch (_validationError) {
      case _ValidationError.none:
        return '';
      case _ValidationError.exceededPotTarget:
        final remaining = widget.pot.target.amount - widget.pot.current.amount;
        final formatted = BankMoneyFormatter.format(
          amount: remaining,
          currencyCode: widget.pot.target.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        return 'Maximum contribution is $formatted to reach your goal';
      case _ValidationError.exceededPotBalance:
        final formatted = BankMoneyFormatter.format(
          amount: widget.pot.current.amount,
          currencyCode: widget.pot.current.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        return 'You can withdraw at most $formatted';
      case _ValidationError.exceededAvailableBalance:
        final formatted = BankMoneyFormatter.format(
          amount: widget.availableBalance!.amount,
          currencyCode: widget.availableBalance!.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        return 'Cannot exceed available balance of $formatted';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Keypad handlers
  // ──────────────────────────────────────────────────────────────────────────

  void _handleDigit(String digit) {
    setState(() {
      // Prevent leading zeros (except '0.xx').
      if (_raw == '0' && digit != '.') {
        _raw = digit;
        return;
      }
      // Max 2 decimal places.
      final dotIndex = _raw.indexOf('.');
      if (dotIndex != -1 && _raw.length - dotIndex > 2) return;
      // Max total length guard.
      if (_raw.length >= 12) return;
      _raw += digit;
    });
  }

  void _handleDelete() {
    setState(() {
      if (_raw.isNotEmpty) {
        _raw = _raw.substring(0, _raw.length - 1);
      }
    });
  }

  void _handleDecimal() {
    setState(() {
      if (_raw.contains('.')) return;
      if (_raw.isEmpty) {
        _raw = '0.';
      } else {
        _raw += '.';
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Confirm
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    if (!_canConfirm) return;

    final money = Money(
      amount: _parsedAmount,
      currencyCode: widget.pot.current.currencyCode,
    );

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm(money);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final title = widget.isWithdrawal
        ? 'Withdraw from ${widget.pot.name}'
        : 'Add to ${widget.pot.name}';

    final displayAmount = _raw.isEmpty ? '0' : _raw;
    final currencyCode = widget.pot.current.currencyCode;

    final errorMsg = _errorMessage(bankTheme, scope);
    final hasError = errorMsg.isNotEmpty;

    final confirmAction = widget.isWithdrawal ? 'withdrawal' : 'contribution';

    final formattedBalance = BankMoneyFormatter.format(
      amount: widget.pot.current.amount,
      currencyCode: currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final formattedTarget = BankMoneyFormatter.format(
      amount: widget.pot.target.amount,
      currencyCode: currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bankTheme.surface,
          borderRadius: bankTheme.sheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandleBar(),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: BankTokens.headlineSmall.copyWith(
                        color: bankTheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: bankTheme.onSurfaceVariant,
                    onPressed: () {
                      widget.onCancel?.call();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: BankTokens.minTapTarget,
                      minHeight: BankTokens.minTapTarget,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Amount display ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space6,
                BankTokens.space4,
                BankTokens.space2,
              ),
              child: Semantics(
                label: '$currencyCode $displayAmount',
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currencyCode,
                      style: BankTokens.headlineMedium.copyWith(
                        color: bankTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: BankTokens.space2),
                    Flexible(
                      child: Text(
                        scope.numeralStyle.convert(displayAmount),
                        style: bankTheme.numeralHero.copyWith(
                          color: hasError
                              ? BankTokens.danger
                              : bankTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pot context subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Text(
                widget.isWithdrawal
                    ? 'Available: $formattedBalance'
                    : 'Goal: $formattedTarget · Saved: $formattedBalance',
                style: BankTokens.bodySmall.copyWith(
                  color: bankTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Error message
            AnimatedSize(
              duration: BankTokens.durationFast,
              curve: BankTokens.curveStandard,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BankTokens.space4,
                        BankTokens.space2,
                        BankTokens.space4,
                        0,
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          errorMsg,
                          style: BankTokens.bodySmall.copyWith(
                            color: BankTokens.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: BankTokens.space5),

            // ── Inline number pad ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: _InlineNumPad(
                onDigit: _handleDigit,
                onDelete: _handleDelete,
                onDecimal: _handleDecimal,
                enabled: !_isLoading,
                bankTheme: bankTheme,
              ),
            ),

            const SizedBox(height: BankTokens.space5),

            // ── Confirm button ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                BankTokens.space4,
                0,
                BankTokens.space4,
                BankTokens.space4 + MediaQuery.of(context).padding.bottom,
              ),
              child: Semantics(
                button: true,
                label: _canConfirm
                    ? 'Confirm $confirmAction'
                    : 'Enter a valid amount to continue',
                child: FilledButton(
                  onPressed: _canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: bankTheme.primary,
                    foregroundColor: bankTheme.onPrimary,
                    disabledBackgroundColor:
                        bankTheme.primary.withValues(alpha: 0.38),
                    disabledForegroundColor:
                        bankTheme.onPrimary.withValues(alpha: 0.6),
                    minimumSize: const Size(
                      double.infinity,
                      BankTokens.minTapTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: bankTheme.buttonRadius,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              bankTheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          widget.isWithdrawal ? 'Withdraw' : 'Add Money',
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
    );
  }
}
