import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// User-controlled credit limit card, equivalent to Nubank's
/// drag-your-own-limit slider.
///
/// Shows the currently selected limit as a large numeral that updates
/// live while dragging, above a slider spanning from the amount already
/// used (the limit can never drop below current usage) up to the bank
/// approved maximum. Values snap to round increments and a subtle
/// marker on the track pins the limit configured today. A thin
/// used-versus-limit progress bar turns [BankTokens.danger] once
/// utilisation passes 90 percent of the selection.
///
/// A commit button appears only when the selection differs from the
/// configured limit: it shows an inline spinner while [onCommit] runs,
/// flashes a success check when it resolves `true`, and reverts the
/// slider to the configured limit when it resolves `false` or throws.
///
/// Money is rendered through [BankBalanceText] and
/// [BankMoneyFormatter], so privacy mode and numeral style from the
/// ambient [BankUiScope] are respected. The slider announces formatted
/// values to assistive technologies.
///
/// ```dart
/// BankCreditLimitAdjuster(
///   currentLimit: Money.fromDouble(4500, 'USD'),
///   maxApproved: Money.fromDouble(8000, 'USD'),
///   used: Money.fromDouble(1250, 'USD'),
///   onCommit: (newLimit) async => api.setCardLimit(newLimit),
/// )
/// ```
class BankCreditLimitAdjuster extends StatefulWidget {
  const BankCreditLimitAdjuster({
    required this.currentLimit,
    required this.maxApproved,
    required this.used,
    required this.onCommit,
    super.key,
    this.title = 'Your card limit',
    this.usedTemplate = '{used} used of {limit}',
    this.maxLabel = 'Bank approved maximum',
    this.commitLabel = 'Confirm new limit',
  });

  /// The limit configured on the card today, drawn as a subtle marker
  /// on the slider track.
  final Money currentLimit;

  /// The hard ceiling the bank has approved.
  final Money maxApproved;

  /// Amount of the limit already consumed. The slider cannot go below
  /// this value.
  final Money used;

  /// Persists the newly selected limit. Resolve `true` to accept (a
  /// success check is flashed) or `false` to reject (the slider
  /// reverts to the configured limit).
  final Future<bool> Function(Money newLimit) onCommit;

  /// Card heading.
  final String title;

  /// Microtext template under the progress bar. `{used}` and `{limit}`
  /// are replaced with formatted amounts.
  final String usedTemplate;

  /// Caption shown next to the formatted [maxApproved] amount.
  final String maxLabel;

  /// Label of the commit button shown when the selection changed.
  final String commitLabel;

  @override
  State<BankCreditLimitAdjuster> createState() =>
      _BankCreditLimitAdjusterState();
}

class _BankCreditLimitAdjusterState extends State<BankCreditLimitAdjuster> {
  late double _selected;
  late double _committed;
  bool _busy = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  String get _currency => widget.currentLimit.currencyCode;
  double get _min => widget.used.amount.toDouble();
  double get _max => widget.maxApproved.amount.toDouble();
  bool get _hasRange => _max > _min;

  /// A round snapping increment (1, 2 or 5 times a power of ten) that
  /// yields roughly forty stops across the adjustable range.
  double get _step {
    final range = _max - _min;
    if (range <= 0) return 1;
    final raw = range / 40;
    final exponent = (math.log(raw) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final residual = raw / magnitude;
    final double nice;
    if (residual >= 5) {
      nice = 10;
    } else if (residual >= 2) {
      nice = 5;
    } else {
      nice = residual >= 1 ? 2 : 1;
    }
    return nice * magnitude;
  }

  @override
  void initState() {
    super.initState();
    _committed = widget.currentLimit.amount.toDouble();
    _selected = _clampToRange(_committed);
  }

  @override
  void didUpdateWidget(BankCreditLimitAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLimit != widget.currentLimit ||
        oldWidget.maxApproved != widget.maxApproved ||
        oldWidget.used != widget.used) {
      _committed = widget.currentLimit.amount.toDouble();
      _selected = _clampToRange(_committed);
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  double _clampToRange(double value) =>
      _hasRange ? value.clamp(_min, _max) : _min;

  Money _asMoney(double value) => Money.fromDouble(value, _currency);

  String _format(double value, BankUiScopeData scope) {
    if (scope.privacyEnabled) return scope.strings.balanceHidden;
    return BankMoneyFormatter.format(
      amount: _asMoney(value).amount,
      currencyCode: _currency,
      numeralStyle: scope.numeralStyle,
    );
  }

  void _onSliderChanged(double raw) {
    _successTimer?.cancel();
    final step = _step;
    final snapped = (raw / step).round() * step;
    setState(() {
      _showSuccess = false;
      _selected = _clampToRange(snapped);
    });
  }

  Future<void> _commit() async {
    if (_busy || _selected == _committed) return;
    final target = _selected;
    setState(() => _busy = true);
    var accepted = false;
    try {
      accepted = await widget.onCommit(_asMoney(target));
    } on Object {
      accepted = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (accepted) {
        _committed = target;
        _showSuccess = true;
      } else {
        _selected = _committed;
      }
    });
    if (accepted) {
      _successTimer?.cancel();
      _successTimer = Timer(BankTokens.durationXSlow * 2, () {
        if (mounted) setState(() => _showSuccess = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final formattedSelected = _format(_selected, scope);
    final formattedUsed = _format(_min, scope);
    final formattedMax = _format(_max, scope);

    final usedFraction =
        _selected <= 0 ? 1.0 : (_min / _selected).clamp(0.0, 1.0);
    final nearLimit = usedFraction > 0.9;

    final microStyle =
        BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant);
    final changed = _selected != _committed;
    final showButton = changed || _busy || _showSuccess;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style:
                  BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
            ),
            const SizedBox(height: BankTokens.space2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BankBalanceText(money: _asMoney(_selected)),
            ),
            const SizedBox(height: BankTokens.space3),
            ClipRRect(
              borderRadius: theme.chipRadius,
              child: LinearProgressIndicator(
                value: usedFraction,
                minHeight: 4,
                backgroundColor: theme.surfaceVariant,
                color: nearLimit ? BankTokens.danger : theme.primary,
              ),
            ),
            const SizedBox(height: BankTokens.space1),
            Text(
              widget.usedTemplate
                  .replaceAll('{used}', formattedUsed)
                  .replaceAll('{limit}', formattedSelected),
              style: microStyle,
            ),
            Stack(
              children: [
                if (_hasRange) _buildCurrentLimitMarker(theme),
                Semantics(
                  slider: true,
                  label: widget.title,
                  value: formattedSelected,
                  excludeSemantics: true,
                  child: Slider(
                    value: _hasRange ? _selected.clamp(_min, _max) : 0,
                    min: _hasRange ? _min : 0,
                    max: _hasRange ? _max : 1,
                    activeColor: theme.primary,
                    inactiveColor: theme.surfaceVariant,
                    onChanged: _busy || !_hasRange ? null : _onSliderChanged,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(widget.maxLabel, style: microStyle)),
                const SizedBox(width: BankTokens.space2),
                Text(formattedMax, style: microStyle),
              ],
            ),
            AnimatedSize(
              duration:
                  disableAnimations ? Duration.zero : BankTokens.durationBase,
              curve: BankTokens.curveStandard,
              child: showButton
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: BankTokens.space3,
                      ),
                      child: _buildCommitButton(theme),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// A subtle tick on the slider track marking the configured limit.
  Widget _buildCurrentLimitMarker(BankThemeData theme) {
    final fraction = ((_committed - _min) / (_max - _min)).clamp(0.0, 1.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          // Matches the default slider track inset (thumb overlay).
          padding: const EdgeInsets.symmetric(horizontal: BankTokens.space6),
          child: Align(
            alignment: AlignmentDirectional(fraction * 2 - 1, 0),
            child: SizedBox(
              width: 2,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(BankTokens.radiusFull),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommitButton(BankThemeData theme) {
    final Widget child;
    if (_busy) {
      child = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.primary,
        ),
      );
    } else if (_showSuccess) {
      child = Icon(BankIcons.success, size: 20, color: theme.onPrimary);
    } else {
      child = Text(widget.commitLabel, style: BankTokens.labelLarge);
    }

    return SizedBox(
      height: BankTokens.minTapTarget,
      child: FilledButton(
        onPressed: _busy || _showSuccess ? null : _commit,
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.onPrimary,
          disabledBackgroundColor:
              _showSuccess ? BankTokens.success : theme.surfaceVariant,
          disabledForegroundColor:
              _showSuccess ? theme.onPrimary : theme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
        ),
        child: child,
      ),
    );
  }
}
