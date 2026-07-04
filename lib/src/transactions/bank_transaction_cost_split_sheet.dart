import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Participant model
// ---------------------------------------------------------------------------

/// A person who can receive a split of a transaction's cost.
class BankSplitParticipant {
  final String id;
  final String name;
  final String? avatarUrl;

  const BankSplitParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

/// Split the cost of a single transaction between multiple people.
class BankTransactionCostSplitSheet extends StatefulWidget {
  final Transaction transaction;
  final List<BankSplitParticipant> participants;

  /// Called when the user confirms; maps participantId → allocated [Money].
  final ValueChanged<Map<String, Money>> onConfirm;

  /// Overrides the sheet corner radius. Defaults to the theme sheetRadius.
  final BorderRadius? radius;

  /// Overrides the sheet background. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the drag handle color. Defaults to the theme outline.
  final Color? handleColor;

  /// Overrides the primary accents (active toggle, initials, confirm
  /// button). Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the participant avatar background. Defaults to the theme
  /// surfaceVariant.
  final Color? avatarBackgroundColor;

  /// Merged over the sheet title style ([BankTokens.headlineSmall]).
  final TextStyle? titleStyle;

  /// Overrides the max sheet height as a screen fraction. Defaults to
  /// 0.88.
  final double? maxHeightFraction;

  /// Overrides the close button glyph. Defaults to [Icons.close].
  final IconData? closeIcon;

  /// Overrides the sheet title. Defaults to 'Split Cost'.
  final String title;

  /// Overrides the total prefix. Defaults to 'Total: '.
  final String totalLabel;

  /// Overrides the running total label. Defaults to 'Allocated'.
  final String allocatedLabel;

  /// Overrides the toggle animation duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the toggle animation curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  const BankTransactionCostSplitSheet({
    required this.transaction,
    required this.participants,
    required this.onConfirm,
    super.key,
    this.radius,
    this.backgroundColor,
    this.handleColor,
    this.accentColor,
    this.avatarBackgroundColor,
    this.titleStyle,
    this.maxHeightFraction,
    this.closeIcon,
    this.title = 'Split Cost',
    this.totalLabel = 'Total: ',
    this.allocatedLabel = 'Allocated',
    this.animationDuration,
    this.animationCurve,
  });

  /// Convenience helper to push the sheet.
  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    required List<BankSplitParticipant> participants,
    required ValueChanged<Map<String, Money>> onConfirm,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankTransactionCostSplitSheet(
          transaction: transaction,
          participants: participants,
          onConfirm: onConfirm,
        ),
      );

  @override
  State<BankTransactionCostSplitSheet> createState() =>
      _BankTransactionCostSplitSheetState();
}

class _BankTransactionCostSplitSheetState
    extends State<BankTransactionCostSplitSheet> {
  bool _equalSplit = true;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final p in widget.participants)
        p.id: TextEditingController(text: _equalShare.toStringAsFixed(2)),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Decimal get _totalAmount => widget.transaction.amount.amount.abs();
  String get _currencyCode => widget.transaction.amount.currencyCode;
  int get _count => widget.participants.length;

  Decimal get _equalShare {
    if (_count == 0) return Decimal.zero;
    // Divide and round to 2 decimal places
    final raw = _totalAmount / Decimal.fromInt(_count);
    return Decimal.parse(raw.toDouble().toStringAsFixed(2));
  }

  Decimal get _customTotal {
    var sum = Decimal.zero;
    for (final c in _controllers.values) {
      final v = Decimal.tryParse(c.text) ?? Decimal.zero;
      sum += v;
    }
    return sum;
  }

  bool get _isValid {
    if (_equalSplit) return true;
    final diff = (_customTotal - _totalAmount).abs();
    // ±1 cent tolerance
    return diff <= Decimal.parse('0.01');
  }

  void _confirm() {
    final result = <String, Money>{};
    for (final p in widget.participants) {
      final amount = _equalSplit
          ? _equalShare
          : (Decimal.tryParse(_controllers[p.id]!.text) ?? Decimal.zero);
      result[p.id] = Money(amount: amount, currencyCode: _currencyCode);
    }
    widget.onConfirm(result);
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final s = scope.strings;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    final maxHeight =
        MediaQuery.of(context).size.height * (widget.maxHeightFraction ?? 0.88);
    final accent = widget.accentColor ?? bankTheme.primary;

    final formattedTotal = BankMoneyFormatter.format(
      amount: _totalAmount,
      currencyCode: _currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? bankTheme.surface,
          borderRadius: widget.radius ?? bankTheme.sheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: BankTokens.space2),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.handleColor ?? bankTheme.outline,
                    borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: BankTokens.headlineSmall
                          .copyWith(color: bankTheme.onSurface)
                          .merge(widget.titleStyle),
                    ),
                  ),
                  IconButton(
                    icon: Icon(widget.closeIcon ?? Icons.close),
                    color: bankTheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: s.cancel,
                  ),
                ],
              ),
            ),
            // Total display
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Row(
                children: [
                  Text(
                    widget.totalLabel,
                    style: BankTokens.bodyMedium.copyWith(
                      color: bankTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: bankTheme.numeralMedium.copyWith(
                      color: bankTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            // Toggle: Equal / Custom
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: s.splitEqually,
                      selected: _equalSplit,
                      child: _ToggleButton(
                        label: s.splitEqually,
                        active: _equalSplit,
                        bankTheme: bankTheme,
                        activeColor: accent,
                        duration: widget.animationDuration,
                        curve: widget.animationCurve,
                        onTap: () => setState(() => _equalSplit = true),
                        isLeading: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: s.custom,
                      selected: !_equalSplit,
                      child: _ToggleButton(
                        label: s.custom,
                        active: !_equalSplit,
                        bankTheme: bankTheme,
                        activeColor: accent,
                        duration: widget.animationDuration,
                        curve: widget.animationCurve,
                        onTap: () => setState(() => _equalSplit = false),
                        isLeading: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            const Divider(height: 1),
            // Participant list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: BankTokens.space2,
                ),
                itemCount: widget.participants.length,
                itemBuilder: (ctx, i) {
                  final p = widget.participants[i];
                  return _ParticipantRow(
                    participant: p,
                    equalSplit: _equalSplit,
                    equalAmount: BankMoneyFormatter.format(
                      amount: _equalShare,
                      currencyCode: _currencyCode,
                      numeralStyle: scope.numeralStyle,
                    ),
                    controller: _controllers[p.id]!,
                    bankTheme: bankTheme,
                    accentColor: accent,
                    avatarBackgroundColor: widget.avatarBackgroundColor,
                    onChanged: (_) => setState(() {}),
                  );
                },
              ),
            ),
            // Running total for custom mode
            if (!_equalSplit) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.allocatedLabel,
                        style: BankTokens.bodySmall.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      BankMoneyFormatter.format(
                        amount: _customTotal,
                        currencyCode: _currencyCode,
                        numeralStyle: scope.numeralStyle,
                      ),
                      style: bankTheme.numeralSmall.copyWith(
                        color: _isValid
                            ? BankTokens.positiveBalance
                            : BankTokens.negativeBalance,
                      ),
                    ),
                    Text(
                      ' / $formattedTotal',
                      style: bankTheme.numeralSmall.copyWith(
                        color: bankTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BankTokens.space4,
                BankTokens.space3,
                BankTokens.space4,
                BankTokens.space4,
              ),
              child: Semantics(
                button: true,
                label: s.confirm,
                enabled: _isValid,
                child: FilledButton(
                  onPressed: _isValid ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bankTheme.onPrimary,
                    disabledBackgroundColor: accent.withValues(alpha: 0.38),
                    minimumSize: const Size(
                      double.infinity,
                      BankTokens.minTapTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: bankTheme.buttonRadius,
                    ),
                  ),
                  child: Text(
                    s.confirm,
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

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final BankThemeData bankTheme;
  final Color activeColor;
  final Duration? duration;
  final Curve? curve;
  final VoidCallback onTap;
  final bool isLeading;

  const _ToggleButton({
    required this.label,
    required this.active,
    required this.bankTheme,
    required this.activeColor,
    required this.onTap,
    required this.isLeading,
    this.duration,
    this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration ?? BankTokens.durationFast,
        curve: curve ?? BankTokens.curveStandard,
        height: BankTokens.minTapTarget,
        decoration: BoxDecoration(
          color: active ? activeColor : bankTheme.surfaceVariant,
          borderRadius: isLeading
              ? BorderRadius.only(
                  topLeft: bankTheme.buttonRadius.topLeft,
                  bottomLeft: bankTheme.buttonRadius.bottomLeft,
                )
              : BorderRadius.only(
                  topRight: bankTheme.buttonRadius.topRight,
                  bottomRight: bankTheme.buttonRadius.bottomRight,
                ),
          border: Border.all(color: bankTheme.outline),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: BankTokens.labelMedium.copyWith(
            color: active ? bankTheme.onPrimary : bankTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatefulWidget {
  final BankSplitParticipant participant;
  final bool equalSplit;
  final String equalAmount;
  final TextEditingController controller;
  final BankThemeData bankTheme;
  final Color accentColor;
  final Color? avatarBackgroundColor;
  final ValueChanged<String> onChanged;

  const _ParticipantRow({
    required this.participant,
    required this.equalSplit,
    required this.equalAmount,
    required this.controller,
    required this.bankTheme,
    required this.accentColor,
    required this.onChanged,
    this.avatarBackgroundColor,
  });

  @override
  State<_ParticipantRow> createState() => _ParticipantRowState();
}

class _ParticipantRowState extends State<_ParticipantRow> {
  bool _avatarFailed = false;

  @override
  Widget build(BuildContext context) {
    final bankTheme = widget.bankTheme;
    final p = widget.participant;

    final avatarBackground =
        widget.avatarBackgroundColor ?? bankTheme.surfaceVariant;

    Widget avatar;
    if (p.avatarUrl != null && !_avatarFailed) {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: avatarBackground,
        backgroundImage: BankUiScope.imageProviderFor(context, p.avatarUrl!),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _avatarFailed = true);
        },
      );
    } else {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: avatarBackground,
        child: Text(
          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
          style: BankTokens.labelLarge.copyWith(
            color: widget.accentColor,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Text(
              p.name,
              style: BankTokens.bodyMedium.copyWith(
                color: bankTheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BankTokens.space3),
          SizedBox(
            width: 100,
            child: widget.equalSplit
                ? Text(
                    widget.equalAmount,
                    style: bankTheme.numeralSmall.copyWith(
                      color: bankTheme.onSurface,
                    ),
                    textAlign: TextAlign.end,
                  )
                : TextField(
                    controller: widget.controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: widget.onChanged,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space2,
                        vertical: BankTokens.space2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: bankTheme.buttonRadius,
                        borderSide: BorderSide(color: bankTheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: bankTheme.buttonRadius,
                        borderSide: BorderSide(color: bankTheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: bankTheme.buttonRadius,
                        borderSide: BorderSide(color: widget.accentColor),
                      ),
                    ),
                    style: bankTheme.numeralSmall.copyWith(
                      color: bankTheme.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
