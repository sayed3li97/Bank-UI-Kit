import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';
import 'money_formatter.dart';

// ---------------------------------------------------------------------------
// Stage model
// ---------------------------------------------------------------------------

/// A single milestone displayed by [BankStatusTracker].
///
/// Purely descriptive: the stage's visual state (completed, current,
/// upcoming, failed) is derived by the tracker from its `currentIndex`
/// and `failed` properties, not stored on the stage itself.
@immutable
class BankTrackerStage {
  /// Short milestone title, e.g. `'Payment initiated'`.
  final String title;

  /// Optional supporting detail rendered under [title].
  final String? subtitle;

  /// When the milestone occurred. Rendered end-aligned via
  /// [BankDateFormatter.formatShort]; omitted when `null`.
  final DateTime? timestamp;

  /// Optional slot rendered at the end of the stage row, after the
  /// timestamp (e.g. a receipt chip or info button).
  final Widget? trailing;

  const BankTrackerStage({
    required this.title,
    this.subtitle,
    this.timestamp,
    this.trailing,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankTrackerStage &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.timestamp == timestamp &&
        other.trailing == trailing;
  }

  @override
  int get hashCode => Object.hash(title, subtitle, timestamp, trailing);
}

// ---------------------------------------------------------------------------
// Tracker widget
// ---------------------------------------------------------------------------

/// Vertical milestone tracker for payment, application, dispute, or KYC
/// progress.
///
/// Distinct from a wizard step indicator (which drives forward navigation):
/// this widget *displays* the historical / asynchronous state of a
/// back-office process the user is waiting on.
///
/// Visual grammar:
/// - **Completed** stages (before [currentIndex]): filled primary circle
///   with a check mark, connected by a solid primary line.
/// - **Current** stage: pulsing primary ring (1600 ms cycle, static when
///   `MediaQuery.disableAnimationsOf` is `true`).
/// - **Upcoming** stages: outlined grey circles with grey connectors.
/// - **Failed**: when [failed] is `true`, the stage at [currentIndex]
///   renders a [BankTokens.danger] circle with an X, [failureReason]
///   appears in danger text below it, and subsequent connectors are
///   dashed grey.
///
/// Each stage row exposes a semantic label such as
/// `'Stage 2 of 5: In review, completed'`.
///
/// Feed it from a `BankKycStatus` or `BankTransferStatus` sealed state
/// (see `BankKycFlowController` / `BankTransferFlowController`).
///
/// ```dart
/// BankStatusTracker(
///   stages: [
///     BankTrackerStage(
///       title: 'Payment initiated',
///       subtitle: 'To Acme Ltd',
///       timestamp: DateTime(2026, 7, 1, 9, 30),
///     ),
///     BankTrackerStage(
///       title: 'Compliance review',
///       timestamp: DateTime(2026, 7, 1, 9, 32),
///     ),
///     const BankTrackerStage(title: 'Funds released'),
///     const BankTrackerStage(title: 'Delivered to beneficiary'),
///   ],
///   currentIndex: 1,
/// )
/// ```
class BankStatusTracker extends StatefulWidget {
  /// Ordered milestones, first to last. Must not be empty.
  final List<BankTrackerStage> stages;

  /// Index of the stage currently in progress (or failed, when [failed]
  /// is `true`). Stages before it render as completed.
  final int currentIndex;

  /// Whether the process failed at [currentIndex].
  final bool failed;

  /// Explanation rendered in danger text below the failed stage.
  /// Only shown when [failed] is `true`.
  final String? failureReason;

  /// Passed to the outer [Column]; defaults to [MainAxisSize.min].
  final MainAxisSize mainAxisSize;

  /// Semantic status word for completed stages.
  final String completedLabel;

  /// Semantic status word for the in-progress stage.
  final String inProgressLabel;

  /// Semantic status word for the failed stage.
  final String failedLabel;

  /// Semantic status word for not-yet-reached stages.
  final String upcomingLabel;

  /// Overrides [BankThemeData.primary] on completed/current circles and
  /// completed connectors.
  final Color? accentColor;

  /// Overrides [BankThemeData.outline] on upcoming circles and on
  /// upcoming/dashed connectors.
  final Color? inactiveColor;

  /// Overrides [BankTokens.danger] on the failed circle and the
  /// [failureReason] text.
  final Color? failureColor;

  /// Overrides the check glyph inside completed circles. Defaults to
  /// [Icons.check].
  final IconData? completedIcon;

  /// Overrides the X glyph inside the failed circle. Defaults to
  /// [BankIcons.close].
  final IconData? failedIcon;

  /// Merged over the computed stage title style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Merged over the computed timestamp style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? timestampStyle;

  /// Merged over the computed failure reason style ([BankTokens.bodySmall]
  /// in [BankTokens.danger]).
  final TextStyle? failureReasonStyle;

  /// Overrides the pulse cycle duration of the current-stage ring.
  /// Defaults to 1600 ms.
  final Duration? animationDuration;

  /// Overrides the pulse easing curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Builds each stage row's semantics label. Receives the 1-based stage
  /// number, the stage count, the stage, and its status word. Defaults to
  /// an English `'Stage <n> of <count>: <title>, <status>'`.
  final String Function(
    int stageNumber,
    int stageCount,
    BankTrackerStage stage,
    String statusLabel,
  )? semanticLabelBuilder;

  const BankStatusTracker({
    required this.stages,
    super.key,
    this.currentIndex = 0,
    this.failed = false,
    this.failureReason,
    this.mainAxisSize = MainAxisSize.min,
    this.completedLabel = 'completed',
    this.inProgressLabel = 'in progress',
    this.failedLabel = 'failed',
    this.upcomingLabel = 'upcoming',
    this.accentColor,
    this.inactiveColor,
    this.failureColor,
    this.completedIcon,
    this.failedIcon,
    this.titleStyle,
    this.subtitleStyle,
    this.timestampStyle,
    this.failureReasonStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabelBuilder,
  })  : assert(stages.length > 0, 'stages must not be empty'),
        assert(
          currentIndex >= 0 && currentIndex < stages.length,
          'currentIndex must be a valid index into stages',
        );

  @override
  State<BankStatusTracker> createState() => _BankStatusTrackerState();
}

class _BankStatusTrackerState extends State<BankStatusTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const Duration _pulseDuration = Duration(milliseconds: 1600);
  static const double _indicatorExtent = 40;
  static const double _circleSize = 24;
  static const double _connectorWidth = 2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? _pulseDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(BankStatusTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _pulseController.duration = widget.animationDuration ?? _pulseDuration;
    }
    _syncPulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Starts or stops the current-stage pulse depending on the failed flag
  /// and the ambient reduced-motion setting.
  void _syncPulse() {
    final shouldPulse =
        !widget.failed && !MediaQuery.disableAnimationsOf(context);
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  Color _accent(BankThemeData theme) => widget.accentColor ?? theme.primary;

  Color _inactive(BankThemeData theme) => widget.inactiveColor ?? theme.outline;

  Color get _failure => widget.failureColor ?? BankTokens.danger;

  String _statusLabel(int index) {
    if (widget.failed && index == widget.currentIndex) {
      return widget.failedLabel;
    }
    if (index < widget.currentIndex) return widget.completedLabel;
    if (index == widget.currentIndex) return widget.inProgressLabel;
    return widget.upcomingLabel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Column(
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.stages.length; i++) _buildStageRow(theme, i),
      ],
    );
  }

  Widget _buildStageRow(BankThemeData theme, int index) {
    final stage = widget.stages[index];
    final isLast = index == widget.stages.length - 1;
    final total = widget.stages.length;

    return Semantics(
      container: true,
      label: widget.semanticLabelBuilder?.call(
            index + 1,
            total,
            stage,
            _statusLabel(index),
          ) ??
          'Stage ${index + 1} of $total: '
              '${stage.title}, ${_statusLabel(index)}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _indicatorExtent,
              child: Column(
                children: [
                  _buildIndicator(theme, index),
                  if (!isLast) Expanded(child: _buildConnector(theme, index)),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(child: _buildContent(theme, index, isLast: isLast)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Indicator circles
  // ---------------------------------------------------------------------

  Widget _buildIndicator(BankThemeData theme, int index) {
    final Widget circle;
    if (widget.failed && index == widget.currentIndex) {
      circle = _buildFailedCircle(theme);
    } else if (index < widget.currentIndex) {
      circle = _buildCompletedCircle(theme);
    } else if (index == widget.currentIndex) {
      circle = _buildCurrentCircle(theme);
    } else {
      circle = _buildUpcomingCircle(theme);
    }

    return SizedBox(
      width: _indicatorExtent,
      height: _indicatorExtent,
      child: Center(child: circle),
    );
  }

  Widget _buildCompletedCircle(BankThemeData theme) {
    return SizedBox(
      width: _circleSize,
      height: _circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _accent(theme),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.completedIcon ?? Icons.check,
          size: 14,
          color: theme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildFailedCircle(BankThemeData theme) {
    return SizedBox(
      width: _circleSize,
      height: _circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _failure,
          shape: BoxShape.circle,
        ),
        // White is the only legible foreground on the fixed danger red;
        // matches the precedent set by BankFraudAlertBanner.
        child: Icon(
          widget.failedIcon ?? BankIcons.close,
          size: 14,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }

  Widget _buildUpcomingCircle(BankThemeData theme) {
    return SizedBox(
      width: _circleSize,
      height: _circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _inactive(theme), width: 2),
        ),
      ),
    );
  }

  /// Pulsing ring around a solid primary core. The ring scales up and
  /// fades out over the 1600 ms cycle; when animations are disabled the
  /// controller stays at 0 and the ring renders as a static halo.
  Widget _buildCurrentCircle(BankThemeData theme) {
    return RepaintBoundary(
      child: SizedBox(
        width: _indicatorExtent,
        height: _indicatorExtent,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final t = (widget.animationCurve ?? BankTokens.curveStandard)
                .transform(_pulseController.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + 0.35 * t,
                  child: SizedBox(
                    width: _circleSize,
                    height: _circleSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accent(theme).withValues(
                            alpha: 0.65 - 0.5 * t,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _circleSize / 2,
                  height: _circleSize / 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _accent(theme),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Connectors
  // ---------------------------------------------------------------------

  /// Vertical distance between the indicator box edge and the circle edge:
  /// the amount each connector must extend beyond its layout slot (above
  /// into this row's indicator box, below into the next row's) so the line
  /// meets both circles' edges exactly.
  static const double _connectorOvershoot =
      (_indicatorExtent - _circleSize) / 2;

  Widget _buildConnector(BankThemeData theme, int index) {
    // Connector below stage `index` links it to stage `index + 1`. Its
    // layout slot spans from this indicator box's bottom edge to the next
    // one's top edge; the painter overshoots by the box-to-circle gap on
    // both ends so the segment joins the two circle edges with no float.
    if (widget.failed && index >= widget.currentIndex) {
      return Center(
        child: SizedBox(
          width: _connectorWidth,
          height: double.infinity,
          child: CustomPaint(
            painter: _DashedConnectorPainter(
              color: _inactive(theme),
              overshoot: _connectorOvershoot,
            ),
          ),
        ),
      );
    }

    final color =
        index < widget.currentIndex ? _accent(theme) : _inactive(theme);
    return Center(
      child: SizedBox(
        width: _connectorWidth,
        height: double.infinity,
        child: CustomPaint(
          painter: _SolidConnectorPainter(
            color: color,
            overshoot: _connectorOvershoot,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Stage content
  // ---------------------------------------------------------------------

  Widget _buildContent(
    BankThemeData theme,
    int index, {
    required bool isLast,
  }) {
    final stage = widget.stages[index];
    final isUpcoming = !widget.failed && index > widget.currentIndex;
    final isFailedStage = widget.failed && index == widget.currentIndex;
    final titleColor = isUpcoming ? theme.onSurfaceVariant : theme.onSurface;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: BankTokens.space1,
        bottom: isLast ? 0 : BankTokens.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stage.title,
                  style: BankTokens.labelLarge
                      .copyWith(color: titleColor)
                      .merge(widget.titleStyle),
                ),
              ),
              if (stage.timestamp != null) ...[
                const SizedBox(width: BankTokens.space2),
                Text(
                  BankDateFormatter.formatShort(stage.timestamp!),
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(widget.timestampStyle),
                ),
              ],
              if (stage.trailing != null) ...[
                const SizedBox(width: BankTokens.space2),
                stage.trailing!,
              ],
            ],
          ),
          if (stage.subtitle != null) ...[
            const SizedBox(height: BankTokens.space1),
            Text(
              stage.subtitle!,
              style: BankTokens.bodySmall
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(widget.subtitleStyle),
            ),
          ],
          if (isFailedStage && widget.failureReason != null) ...[
            const SizedBox(height: BankTokens.space1),
            Text(
              widget.failureReason!,
              style: BankTokens.bodySmall
                  .copyWith(color: _failure)
                  .merge(widget.failureReasonStyle),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connector painters
//
// Both painters deliberately draw beyond their layout slot by `overshoot`
// on each end (their ancestors do not clip), so every segment runs from
// the bottom edge of one step circle to the top edge of the next.
// ---------------------------------------------------------------------------

class _SolidConnectorPainter extends CustomPainter {
  const _SolidConnectorPainter({
    required this.color,
    this.overshoot = 0,
  });

  final Color color;
  final double overshoot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTRB(0, -overshoot, size.width, size.height + overshoot),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SolidConnectorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.overshoot != overshoot;
}

class _DashedConnectorPainter extends CustomPainter {
  const _DashedConnectorPainter({
    required this.color,
    this.overshoot = 0,
  });

  final Color color;
  final double overshoot;

  static const double _dashLength = 4;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    final endY = size.height + overshoot;
    var y = -overshoot;
    while (y < endY) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + _dashLength, endY)),
        paint,
      );
      y += _dashLength + _gapLength;
    }
  }

  @override
  bool shouldRepaint(_DashedConnectorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.overshoot != overshoot;
}
