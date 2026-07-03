import 'dart:async';

import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One adjustable limit channel in a [BankTransferLimitManager].
class BankLimitChannel {
  const BankLimitChannel({
    required this.id,
    required this.label,
    required this.icon,
    required this.current,
    required this.max,
    required this.used,
  });

  final String id;

  /// e.g. `'Daily online transfers'`.
  final String label;

  final IconData icon;

  /// The currently configured limit.
  final Money current;

  /// The hard ceiling the bank allows.
  final Money max;

  /// Amount already consumed in the current window.
  final Money used;
}

/// Per-channel transfer limit editor, generalizing the spend-limit
/// slider inside `BankCardControlsPanel`.
///
/// Each channel renders its icon and label, a thin used/limit progress
/// bar (danger-tinted beyond 90 %), and a slider with live
/// formatted-money value snapping to sensible increments. Raising a
/// limit above its current value can require strong customer
/// authentication via [onScaRequired] — on refusal the slider animates
/// back. Commits debounce 400 ms before firing [onChanged].
///
/// ```dart
/// BankTransferLimitManager(
///   channels: channels,
///   onChanged: (id, limit) => api.setLimit(id, limit),
///   onScaRequired: () async =>
///       await BankScaApprovalSheet.show(...) ?? false,
/// )
/// ```
class BankTransferLimitManager extends StatelessWidget {
  const BankTransferLimitManager({
    required this.channels,
    required this.onChanged,
    super.key,
    this.requireScaAboveCurrent = true,
    this.onScaRequired,
  });

  final List<BankLimitChannel> channels;

  /// Fired (debounced 400 ms) when a channel's limit changes.
  final void Function(String channelId, Money newLimit) onChanged;

  /// When true, raising a limit above its configured value awaits
  /// [onScaRequired] before committing.
  final bool requireScaAboveCurrent;

  /// Host presents an SCA challenge (e.g. `BankScaApprovalSheet`) and
  /// resolves whether it passed.
  final Future<bool> Function()? onScaRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final channel in channels)
          _ChannelEditor(
            key: ValueKey<String>(channel.id),
            channel: channel,
            requireScaAboveCurrent: requireScaAboveCurrent,
            onScaRequired: onScaRequired,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _ChannelEditor extends StatefulWidget {
  const _ChannelEditor({
    required this.channel,
    required this.requireScaAboveCurrent,
    required this.onScaRequired,
    required this.onChanged,
    super.key,
  });

  final BankLimitChannel channel;
  final bool requireScaAboveCurrent;
  final Future<bool> Function()? onScaRequired;
  final void Function(String channelId, Money newLimit) onChanged;

  @override
  State<_ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<_ChannelEditor> {
  late double _value;
  late double _committed;
  Timer? _debounce;
  bool _awaitingSca = false;

  double get _max => widget.channel.max.amount.toDouble();
  double get _step =>
      _max <= 0 ? 1 : (_max / 100).roundToDouble().clamp(1, _max);

  @override
  void initState() {
    super.initState();
    _committed = widget.channel.current.amount.toDouble();
    _value = _committed;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Money _asMoney(double value) =>
      Money.fromDouble(value, widget.channel.current.currencyCode);

  void _onSliderChanged(double raw) {
    final snapped = (raw / _step).round() * _step;
    setState(() => _value = snapped.clamp(0, _max));
  }

  void _onSliderCommit(double raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _commit);
  }

  Future<void> _commit() async {
    if (_value == _committed) return;
    final raising = _value > _committed;
    if (raising &&
        widget.requireScaAboveCurrent &&
        widget.onScaRequired != null) {
      setState(() => _awaitingSca = true);
      var passed = false;
      try {
        passed = await widget.onScaRequired!();
      } on Object {
        passed = false;
      }
      if (!mounted) return;
      setState(() => _awaitingSca = false);
      if (!passed) {
        setState(() => _value = _committed);
        return;
      }
    }
    _committed = _value;
    widget.onChanged(widget.channel.id, _asMoney(_value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final channel = widget.channel;

    final used = channel.used.amount.toDouble();
    final usedFraction = _value <= 0 ? 1.0 : (used / _value).clamp(0.0, 1.0);
    final nearLimit = usedFraction > 0.9;

    final formattedValue = BankMoneyFormatter.format(
      amount: _asMoney(_value).amount,
      currencyCode: channel.current.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(channel.icon, size: 20, color: theme.primary),
              const SizedBox(width: BankTokens.space2),
              Expanded(
                child: Text(
                  channel.label,
                  style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
                ),
              ),
              if (_awaitingSca)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                BankBalanceText(
                  money: _asMoney(_value),
                  size: BankBalanceSize.medium,
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space2),
          ClipRRect(
            borderRadius: theme.chipRadius,
            child: LinearProgressIndicator(
              value: usedFraction,
              minHeight: 4,
              backgroundColor: theme.surfaceVariant,
              color: nearLimit ? BankTokens.danger : theme.primary,
            ),
          ),
          Semantics(
            slider: true,
            label: '${channel.label}: $formattedValue',
            excludeSemantics: true,
            child: Slider(
              value: _value.clamp(0, _max),
              max: _max <= 0 ? 1 : _max,
              activeColor: theme.primary,
              inactiveColor: theme.surfaceVariant,
              onChanged: _awaitingSca ? null : _onSliderChanged,
              onChangeEnd: _onSliderCommit,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                BankMoneyFormatter.format(
                  amount: Money.zero(channel.current.currencyCode).amount,
                  currencyCode: channel.current.currencyCode,
                  numeralStyle: scope.numeralStyle,
                ),
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
              Text(
                BankMoneyFormatter.format(
                  amount: channel.max.amount,
                  currencyCode: channel.max.currencyCode,
                  numeralStyle: scope.numeralStyle,
                ),
                style: BankTokens.labelSmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
