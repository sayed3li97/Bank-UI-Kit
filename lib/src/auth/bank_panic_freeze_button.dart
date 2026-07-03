import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/bank_icon_spec.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Hold-to-activate emergency "freeze everything" control.
///
/// One panic gesture blocks all cards and outgoing payments.
///
/// Two visual states, driven by [frozen]:
///
/// - **Unfrozen**: a large, danger-outlined circular button with a snowflake
///   icon. The user must press **and hold** for [holdDuration]; a circular
///   progress ring fills while held and the button scales down slightly for
///   tactile feedback. Releasing early cancels the gesture and the ring
///   unwinds. When the hold completes, [onToggle] runs with `freeze: true`
///   and a spinner replaces the icon until it resolves; on success the
///   widget flips to the frozen state.
/// - **Frozen**: a filled danger surface showing [frozenLabel], [frozenBody],
///   and an unfreeze button. Unfreezing is deliberately harder to do by
///   accident: it opens a confirmation dialog first, and only then calls
///   [onToggle] with `freeze: false`.
///
/// If [onToggle] returns `false` or throws, the widget stays in its current
/// state and rearms.
///
/// Reduced motion: when animations are disabled (see
/// [MediaQuery.disableAnimationsOf]), the hold is still required for the
/// full [holdDuration], but the progress ring advances in discrete steps
/// instead of sweeping continuously, and the press scale effect is skipped.
///
/// Accessibility: both states expose full [Semantics]. The hold button is
/// announced as a button with a hint describing the press-and-hold gesture
/// and its duration; the unfreeze button announces that a confirmation
/// dialog follows.
///
/// ```dart
/// BankPanicFreezeButton(
///   frozen: account.securityFreezeActive,
///   onToggle: (freeze) => securityRepo.setGlobalFreeze(freeze),
/// )
/// ```
///
/// [References]: colours, radii, spacing, and motion come from
/// [BankThemeData] and [BankTokens]; the snowflake icon is
/// [BankIcons.cardFreeze].
class BankPanicFreezeButton extends StatefulWidget {
  /// Whether everything is currently frozen. The widget also flips its own
  /// state optimistically after a successful [onToggle], so parents may
  /// rebuild lazily.
  final bool frozen;

  /// Executes the freeze (`freeze == true`) or unfreeze (`freeze == false`)
  /// operation. Return `true` on success; `false` (or throw) to keep the
  /// current state.
  final Future<bool> Function(bool freeze) onToggle;

  /// How long the button must be held before the freeze fires.
  final Duration holdDuration;

  /// Label under the circular button in the unfrozen state.
  final String freezeLabel;

  /// Headline of the frozen panel.
  final String frozenLabel;

  /// Label of the unfreeze button and of the confirming dialog action.
  final String unfreezeLabel;

  /// Supporting text of the frozen panel.
  final String frozenBody;

  /// Title of the unfreeze confirmation dialog.
  final String unfreezeConfirmTitle;

  /// Body of the unfreeze confirmation dialog.
  final String unfreezeConfirmBody;

  /// Label of the dialog action that keeps everything frozen.
  final String cancelLabel;

  const BankPanicFreezeButton({
    required this.frozen,
    required this.onToggle,
    super.key,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.freezeLabel = 'Hold to freeze everything',
    this.frozenLabel = 'Everything is frozen',
    this.unfreezeLabel = 'Unfreeze',
    this.frozenBody = 'Cards and outgoing payments are blocked',
    this.unfreezeConfirmTitle = 'Unfreeze everything?',
    this.unfreezeConfirmBody =
        'Your cards and outgoing payments will start working again.',
    this.cancelLabel = 'Cancel',
  });

  @override
  State<BankPanicFreezeButton> createState() => _BankPanicFreezeButtonState();
}

class _BankPanicFreezeButtonState extends State<BankPanicFreezeButton>
    with SingleTickerProviderStateMixin {
  static const double _ringDiameter = 128;
  static const double _ringStrokeWidth = 5;
  static const int _reducedMotionSteps = 5;
  static const Color _onDanger = Color(0xFFFFFFFF);

  late final AnimationController _holdController;
  late bool _frozen;
  bool _pressed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _frozen = widget.frozen;
    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener(_onHoldStatus);
  }

  @override
  void didUpdateWidget(BankPanicFreezeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holdDuration != oldWidget.holdDuration) {
      _holdController.duration = widget.holdDuration;
    }
    if (widget.frozen != oldWidget.frozen) {
      _frozen = widget.frozen;
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Hold gesture
  // ---------------------------------------------------------------------------

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(_completeHold());
    }
  }

  void _startHold(TapDownDetails details) {
    if (_busy || _frozen) return;
    setState(() => _pressed = true);
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    if (!_holdController.isCompleted) {
      unawaited(
        _holdController.animateBack(
          0,
          duration: BankTokens.durationFast,
          curve: BankTokens.curveStandard,
        ),
      );
    }
  }

  Future<void> _completeHold() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _pressed = false);
    final ok = await _runToggle(freeze: true);
    if (!mounted) return;
    if (ok) {
      _holdController.value = 0;
    } else {
      unawaited(
        _holdController.animateBack(
          0,
          duration: BankTokens.durationBase,
          curve: BankTokens.curveStandard,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Toggle plumbing
  // ---------------------------------------------------------------------------

  Future<bool> _runToggle({required bool freeze}) async {
    setState(() => _busy = true);
    var ok = false;
    try {
      ok = await widget.onToggle(freeze);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return ok;
    setState(() {
      _busy = false;
      if (ok) _frozen = freeze;
    });
    return ok;
  }

  Future<void> _onUnfreezePressed() async {
    if (_busy) return;
    final theme = BankThemeData.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
        title: Text(
          widget.unfreezeConfirmTitle,
          style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        ),
        content: Text(
          widget.unfreezeConfirmBody,
          style: BankTokens.bodyMedium.copyWith(
            color: theme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: theme.onSurfaceVariant,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(widget.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: BankTokens.danger,
              foregroundColor: _onDanger,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: theme.buttonRadius,
              ),
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(widget.unfreezeLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runToggle(freeze: false);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reducedMotion ? Duration.zero : BankTokens.durationBase,
      switchInCurve: BankTokens.curveStandard,
      switchOutCurve: BankTokens.curveStandard,
      child: _frozen
          ? _FrozenPanel(
              key: const ValueKey<String>('frozen'),
              theme: theme,
              frozenLabel: widget.frozenLabel,
              frozenBody: widget.frozenBody,
              unfreezeLabel: widget.unfreezeLabel,
              busy: _busy,
              onDanger: _onDanger,
              onUnfreeze: _onUnfreezePressed,
            )
          : _buildHoldButton(theme, reducedMotion),
    );
  }

  Widget _buildHoldButton(BankThemeData theme, bool reducedMotion) {
    final seconds = widget.holdDuration.inMilliseconds / 1000;
    final secondsText = seconds == seconds.roundToDouble()
        ? seconds.round().toString()
        : seconds.toStringAsFixed(1);
    return Semantics(
      key: const ValueKey<String>('unfrozen'),
      button: true,
      enabled: !_busy,
      label: widget.freezeLabel,
      hint: 'Press and hold for $secondsText seconds to freeze all cards '
          'and outgoing payments',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: _startHold,
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _ringDiameter,
              height: _ringDiameter,
              child: AnimatedBuilder(
                animation: _holdController,
                builder: (context, child) {
                  var progress = _holdController.value;
                  if (reducedMotion && progress < 1) {
                    progress =
                        (progress * _reducedMotionSteps).floorToDouble() /
                            _reducedMotionSteps;
                  }
                  return CustomPaint(
                    painter: _HoldRingPainter(
                      progress: progress,
                      trackColor: BankTokens.danger.withValues(alpha: 0.15),
                      ringColor: BankTokens.danger,
                      strokeWidth: _ringStrokeWidth,
                    ),
                    child: child,
                  );
                },
                child: Center(
                  child: AnimatedScale(
                    scale: _pressed && !reducedMotion ? 0.92 : 1,
                    duration: BankTokens.durationFast,
                    curve: BankTokens.curveEmphasized,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BankTokens.danger.withValues(alpha: 0.08),
                        border: Border.all(
                          color: BankTokens.danger,
                          width: 2,
                        ),
                      ),
                      child: SizedBox(
                        width: _ringDiameter - BankTokens.space6,
                        height: _ringDiameter - BankTokens.space6,
                        child: Center(
                          child: _busy
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: BankTokens.danger,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  BankIcons.cardFreeze,
                                  size: 44,
                                  color: BankTokens.danger,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          Text(
            widget.freezeLabel,
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Frozen panel
// ---------------------------------------------------------------------------

class _FrozenPanel extends StatelessWidget {
  final BankThemeData theme;
  final String frozenLabel;
  final String frozenBody;
  final String unfreezeLabel;
  final bool busy;
  final Color onDanger;
  final VoidCallback onUnfreeze;

  const _FrozenPanel({
    required this.theme,
    required this.frozenLabel,
    required this.frozenBody,
    required this.unfreezeLabel,
    required this.busy,
    required this.onDanger,
    required this.onUnfreeze,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$frozenLabel. $frozenBody',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BankTokens.danger,
          borderRadius: theme.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(BankTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                BankIcons.cardFreeze,
                size: 40,
                color: onDanger,
              ),
              const SizedBox(height: BankTokens.space3),
              Text(
                frozenLabel,
                style: BankTokens.headlineSmall.copyWith(color: onDanger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BankTokens.space1),
              Text(
                frozenBody,
                style: BankTokens.bodySmall.copyWith(
                  color: onDanger.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BankTokens.space4),
              Semantics(
                button: true,
                enabled: !busy,
                label: unfreezeLabel,
                hint: 'Opens a confirmation dialog before unfreezing',
                child: FilledButton(
                  onPressed: busy ? null : onUnfreeze,
                  style: FilledButton.styleFrom(
                    backgroundColor: onDanger,
                    foregroundColor: BankTokens.danger,
                    disabledBackgroundColor: onDanger.withValues(alpha: 0.7),
                    minimumSize: const Size(
                      double.infinity,
                      BankTokens.minTapTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: BankTokens.danger,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(unfreezeLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter
// ---------------------------------------------------------------------------

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color ringColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = ringColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
