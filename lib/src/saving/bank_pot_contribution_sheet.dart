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
    required this.accent,
    required this.decimalSemanticLabel,
    required this.deleteSemanticLabel,
    this.deleteIcon,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onDecimal;
  final bool enabled;
  final BankThemeData bankTheme;
  final Color accent;
  final String decimalSemanticLabel;
  final String deleteSemanticLabel;
  final IconData? deleteIcon;

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
          splashColor: accent.withValues(alpha: 0.12),
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
      semanticLabel: decimalSemanticLabel,
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
      semanticLabel: deleteSemanticLabel,
      onTap: () {
        HapticFeedback.selectionClick();
        onDelete();
      },
      child: Icon(
        deleteIcon ?? Icons.backspace_outlined,
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

  /// Contribution title template; `{pot}` is substituted. Defaults to
  /// 'Add to {pot}'.
  final String addTitleTemplate;

  /// Withdrawal title template; `{pot}` is substituted. Defaults to
  /// 'Withdraw from {pot}'.
  final String withdrawTitleTemplate;

  /// Tooltip on the close button. Defaults to 'Close'.
  final String closeTooltip;

  /// Over-target error template; `{amount}` is substituted. Defaults
  /// to 'Maximum contribution is {amount} to reach your goal'.
  final String maxContributionTemplate;

  /// Over-balance withdrawal error template; `{amount}` is
  /// substituted. Defaults to 'You can withdraw at most {amount}'.
  final String maxWithdrawalTemplate;

  /// Over-available-balance error template; `{amount}` is substituted.
  /// Defaults to 'Cannot exceed available balance of {amount}'.
  final String maxAvailableTemplate;

  /// Withdrawal subtitle template; `{amount}` is substituted. Defaults
  /// to 'Available: {amount}'.
  final String availableTemplate;

  /// Contribution subtitle template; `{target}` and `{saved}` are
  /// substituted. Defaults to 'Goal: {target} · Saved: {saved}'.
  final String goalSavedTemplate;

  /// Caption of the confirm button in contribution mode. Defaults to
  /// 'Add Money'.
  final String addButtonLabel;

  /// Caption of the confirm button in withdrawal mode. Defaults to
  /// 'Withdraw'.
  final String withdrawButtonLabel;

  /// Confirm button semantics in contribution mode. Defaults to
  /// 'Confirm contribution'.
  final String confirmContributionSemanticLabel;

  /// Confirm button semantics in withdrawal mode. Defaults to
  /// 'Confirm withdrawal'.
  final String confirmWithdrawalSemanticLabel;

  /// Confirm button semantics while the amount is invalid. Defaults
  /// to 'Enter a valid amount to continue'.
  final String invalidAmountSemanticLabel;

  /// Semantics of the keypad decimal key. Defaults to 'Decimal point'.
  final String decimalKeySemanticLabel;

  /// Semantics of the keypad delete key. Defaults to 'Delete'.
  final String deleteKeySemanticLabel;

  /// Overrides the sheet corner radius. Defaults to the theme
  /// sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the confirm button and keypad splash accent. Defaults
  /// to the theme primary colour.
  final Color? accentColor;

  /// Merged over the computed title style
  /// ([BankTokens.headlineSmall] in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed amount display numeral style.
  final TextStyle? amountStyle;

  /// Overrides the close button glyph. Defaults to [Icons.close].
  final IconData? closeIcon;

  /// Overrides the keypad delete glyph. Defaults to
  /// [Icons.backspace_outlined].
  final IconData? deleteKeyIcon;

  /// Overrides the error reveal duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the error reveal curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  const BankPotContributionSheet({
    required this.pot,
    required this.onConfirm,
    super.key,
    this.isWithdrawal = false,
    this.availableBalance,
    this.onCancel,
    this.addTitleTemplate = 'Add to {pot}',
    this.withdrawTitleTemplate = 'Withdraw from {pot}',
    this.closeTooltip = 'Close',
    this.maxContributionTemplate =
        'Maximum contribution is {amount} to reach your goal',
    this.maxWithdrawalTemplate = 'You can withdraw at most {amount}',
    this.maxAvailableTemplate = 'Cannot exceed available balance of {amount}',
    this.availableTemplate = 'Available: {amount}',
    this.goalSavedTemplate = 'Goal: {target} · Saved: {saved}',
    this.addButtonLabel = 'Add Money',
    this.withdrawButtonLabel = 'Withdraw',
    this.confirmContributionSemanticLabel = 'Confirm contribution',
    this.confirmWithdrawalSemanticLabel = 'Confirm withdrawal',
    this.invalidAmountSemanticLabel = 'Enter a valid amount to continue',
    this.decimalKeySemanticLabel = 'Decimal point',
    this.deleteKeySemanticLabel = 'Delete',
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.amountStyle,
    this.closeIcon,
    this.deleteKeyIcon,
    this.animationDuration,
    this.animationCurve,
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
        return widget.maxContributionTemplate.replaceAll(
          '{amount}',
          formatted,
        );
      case _ValidationError.exceededPotBalance:
        final formatted = BankMoneyFormatter.format(
          amount: widget.pot.current.amount,
          currencyCode: widget.pot.current.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        return widget.maxWithdrawalTemplate.replaceAll('{amount}', formatted);
      case _ValidationError.exceededAvailableBalance:
        final formatted = BankMoneyFormatter.format(
          amount: widget.availableBalance!.amount,
          currencyCode: widget.availableBalance!.currencyCode,
          numeralStyle: scope.numeralStyle,
        );
        return widget.maxAvailableTemplate.replaceAll('{amount}', formatted);
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
        ? widget.withdrawTitleTemplate.replaceAll('{pot}', widget.pot.name)
        : widget.addTitleTemplate.replaceAll('{pot}', widget.pot.name);

    final displayAmount = _raw.isEmpty ? '0' : _raw;
    final currencyCode = widget.pot.current.currencyCode;

    final errorMsg = _errorMessage(bankTheme, scope);
    final hasError = errorMsg.isNotEmpty;

    final accent = widget.accentColor ?? bankTheme.primary;
    final confirmSemanticLabel = widget.isWithdrawal
        ? widget.confirmWithdrawalSemanticLabel
        : widget.confirmContributionSemanticLabel;

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
          color: widget.backgroundColor ?? bankTheme.surface,
          borderRadius: widget.radius ?? bankTheme.sheetRadius,
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
                      style: BankTokens.headlineSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(widget.titleStyle),
                    ),
                  ),
                  IconButton(
                    icon: Icon(widget.closeIcon ?? Icons.close),
                    color: bankTheme.onSurfaceVariant,
                    onPressed: () {
                      widget.onCancel?.call();
                      Navigator.of(context).pop();
                    },
                    tooltip: widget.closeTooltip,
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
                        style: bankTheme.numeralHero
                            .copyWith(
                              color: hasError
                                  ? BankTokens.danger
                                  : bankTheme.onSurface,
                            )
                            .merge(widget.amountStyle),
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
                    ? widget.availableTemplate
                        .replaceAll('{amount}', formattedBalance)
                    : widget.goalSavedTemplate
                        .replaceAll('{target}', formattedTarget)
                        .replaceAll('{saved}', formattedBalance),
                style: BankTokens.bodySmall.copyWith(
                  color: bankTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Error message
            AnimatedSize(
              duration: widget.animationDuration ?? BankTokens.durationFast,
              curve: widget.animationCurve ?? BankTokens.curveStandard,
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
                accent: accent,
                decimalSemanticLabel: widget.decimalKeySemanticLabel,
                deleteSemanticLabel: widget.deleteKeySemanticLabel,
                deleteIcon: widget.deleteKeyIcon,
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
                    ? confirmSemanticLabel
                    : widget.invalidAmountSemanticLabel,
                child: FilledButton(
                  onPressed: _canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bankTheme.onPrimary,
                    disabledBackgroundColor: accent.withValues(alpha: 0.38),
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
                          widget.isWithdrawal
                              ? widget.withdrawButtonLabel
                              : widget.addButtonLabel,
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
