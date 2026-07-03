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
      duration: _pulseDuration,
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
      label: 'Stage ${index + 1} of $total: '
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
          color: theme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 14, color: theme.onPrimary),
      ),
    );
  }

  Widget _buildFailedCircle(BankThemeData theme) {
    return const SizedBox(
      width: _circleSize,
      height: _circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BankTokens.danger,
          shape: BoxShape.circle,
        ),
        // White is the only legible foreground on the fixed danger red;
        // matches the precedent set by BankFraudAlertBanner.
        child: Icon(BankIcons.close, size: 14, color: Color(0xFFFFFFFF)),
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
          border: Border.all(color: theme.outline, width: 2),
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
            final t = BankTokens.curveStandard.transform(
              _pulseController.value,
            );
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
                          color: theme.primary.withValues(
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
                      color: theme.primary,
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

  Widget _buildConnector(BankThemeData theme, int index) {
    // Connector below stage `index` links it to stage `index + 1`.
    if (widget.failed && index >= widget.currentIndex) {
      return Center(
        child: SizedBox(
          width: _connectorWidth,
          height: double.infinity,
          child: CustomPaint(
            painter: _DashedConnectorPainter(color: theme.outline),
          ),
        ),
      );
    }

    final color = index < widget.currentIndex ? theme.primary : theme.outline;
    return Center(
      child: SizedBox(
        width: _connectorWidth,
        height: double.infinity,
        child: ColoredBox(color: color),
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
                  style: BankTokens.labelLarge.copyWith(color: titleColor),
                ),
              ),
              if (stage.timestamp != null) ...[
                const SizedBox(width: BankTokens.space2),
                Text(
                  BankDateFormatter.formatShort(stage.timestamp!),
                  style: BankTokens.bodySmall.copyWith(
                    color: theme.onSurfaceVariant,
                  ),
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
              style: BankTokens.bodySmall.copyWith(
                color: theme.onSurfaceVariant,
              ),
            ),
          ],
          if (isFailedStage && widget.failureReason != null) ...[
            const SizedBox(height: BankTokens.space1),
            Text(
              widget.failureReason!,
              style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed connector painter
// ---------------------------------------------------------------------------

class _DashedConnectorPainter extends CustomPainter {
  const _DashedConnectorPainter({required this.color});

  final Color color;

  static const double _dashLength = 4;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + _dashLength, size.height)),
        paint,
      );
      y += _dashLength + _gapLength;
    }
  }

  @override
  bool shouldRepaint(_DashedConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}
