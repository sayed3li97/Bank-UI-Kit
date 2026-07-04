import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Numbered step progress indicator. RTL-aware: steps flow right-to-left
/// when [Directionality] is RTL.
class BankStepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep; // 1-indexed
  final List<String>? labels; // optional label per step
  final bool showLabels;

  /// Fill for active/completed bubbles and completed connectors.
  /// Defaults to the theme primary.
  final Color? activeColor;

  /// Fill for upcoming bubbles. Defaults to the theme surfaceVariant.
  final Color? inactiveColor;

  /// Number/check color on active and completed bubbles. Defaults to
  /// white.
  final Color? foregroundColor;

  /// Number color on upcoming bubbles. Defaults to the theme
  /// onSurfaceVariant.
  final Color? inactiveForegroundColor;

  /// Color of connectors between not-yet-completed steps. Defaults to
  /// the theme outline.
  final Color? lineColor;

  /// Glyph inside completed bubbles. Defaults to [Icons.check].
  final IconData? completedIcon;

  /// Merged over the computed step label style (bodySmall).
  final TextStyle? labelStyle;

  /// Merged over the computed in-bubble number style (labelSmall).
  final TextStyle? stepNumberStyle;

  /// Diameter of each step bubble. Defaults to 28.
  final double? bubbleSize;

  /// Duration of bubble/line color animations. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Curve of bubble/line color animations. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides the semantics label. Defaults to 'Step X of Y'.
  final String? semanticLabel;

  const BankStepProgressIndicator({
    required this.totalSteps,
    required this.currentStep,
    super.key,
    this.labels,
    this.showLabels = false,
    this.activeColor,
    this.inactiveColor,
    this.foregroundColor,
    this.inactiveForegroundColor,
    this.lineColor,
    this.completedIcon,
    this.labelStyle,
    this.stepNumberStyle,
    this.bubbleSize,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  })  : assert(totalSteps > 0, 'totalSteps must be positive'),
        assert(
          currentStep >= 1 && currentStep <= totalSteps,
          'currentStep must be between 1 and totalSteps (inclusive)',
        );

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final resolvedActive = activeColor ?? bankTheme.primary;
    final resolvedInactive = inactiveColor ?? bankTheme.surfaceVariant;
    final resolvedForeground = foregroundColor ?? Colors.white;
    final resolvedInactiveForeground =
        inactiveForegroundColor ?? bankTheme.onSurfaceVariant;
    final resolvedLineColor = lineColor ?? bankTheme.outline;
    final resolvedBubbleSize = bubbleSize ?? 28.0;
    final resolvedDuration = animationDuration ?? BankTokens.durationBase;
    final resolvedCurve = animationCurve ?? BankTokens.curveStandard;
    final resolvedLabelStyle = BankTokens.bodySmall
        .copyWith(color: bankTheme.onSurfaceVariant)
        .merge(labelStyle);

    // Build the list of step indices in display order.
    final indices = List<int>.generate(totalSteps, (i) => i + 1);
    final displayIndices = isRtl ? indices.reversed.toList() : indices;

    return Semantics(
      label: semanticLabel ?? 'Step $currentStep of $totalSteps',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepRow(
            displayIndices: displayIndices,
            currentStep: currentStep,
            activeColor: resolvedActive,
            inactiveColor: resolvedInactive,
            foregroundColor: resolvedForeground,
            inactiveForegroundColor: resolvedInactiveForeground,
            lineColor: resolvedLineColor,
            completedIcon: completedIcon ?? Icons.check,
            stepNumberStyle: stepNumberStyle,
            bubbleSize: resolvedBubbleSize,
            duration: resolvedDuration,
            curve: resolvedCurve,
          ),
          if (showLabels && labels != null) ...[
            const SizedBox(height: BankTokens.space2),
            _LabelsRow(
              displayIndices: displayIndices,
              labels: labels!,
              labelStyle: resolvedLabelStyle,
              bubbleSize: resolvedBubbleSize,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step row
// ---------------------------------------------------------------------------

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.displayIndices,
    required this.currentStep,
    required this.activeColor,
    required this.inactiveColor,
    required this.foregroundColor,
    required this.inactiveForegroundColor,
    required this.lineColor,
    required this.completedIcon,
    required this.stepNumberStyle,
    required this.bubbleSize,
    required this.duration,
    required this.curve,
  });

  final List<int> displayIndices;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final Color foregroundColor;
  final Color inactiveForegroundColor;
  final Color lineColor;
  final IconData completedIcon;
  final TextStyle? stepNumberStyle;
  final double bubbleSize;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < displayIndices.length; i++) {
      final stepIndex = displayIndices[i];

      // Connecting line before this bubble (skip for first item).
      if (i > 0) {
        // Determine the logical left neighbour in display order.
        // A line is "completed" when both adjacent steps are completed.
        final leftStepIndex = displayIndices[i - 1];
        final isCompleted =
            leftStepIndex < currentStep && stepIndex <= currentStep;
        children.add(
          Expanded(
            child: _ConnectingLine(
              completed: isCompleted,
              activeColor: activeColor,
              lineColor: lineColor,
              duration: duration,
              curve: curve,
            ),
          ),
        );
      }

      children.add(
        _StepBubble(
          stepNumber: stepIndex,
          currentStep: currentStep,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          foregroundColor: foregroundColor,
          inactiveForegroundColor: inactiveForegroundColor,
          completedIcon: completedIcon,
          stepNumberStyle: stepNumberStyle,
          bubbleSize: bubbleSize,
          duration: duration,
          curve: curve,
        ),
      );
    }

    return Row(
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Labels row
// ---------------------------------------------------------------------------

class _LabelsRow extends StatelessWidget {
  const _LabelsRow({
    required this.displayIndices,
    required this.labels,
    required this.labelStyle,
    required this.bubbleSize,
  });

  final List<int> displayIndices;
  final List<String> labels;
  final TextStyle labelStyle;
  final double bubbleSize;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < displayIndices.length; i++) {
      final stepIndex = displayIndices[i];

      if (i > 0) {
        // Spacer that aligns with the connecting line.
        children.add(const Expanded(child: SizedBox.shrink()));
      }

      // Each label is centred below its bubble.
      final labelText =
          (stepIndex - 1) < labels.length ? labels[stepIndex - 1] : '';

      children.add(
        SizedBox(
          width: bubbleSize,
          child: Text(
            labelText,
            style: labelStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Step bubble
// ---------------------------------------------------------------------------

class _StepBubble extends StatelessWidget {
  const _StepBubble({
    required this.stepNumber,
    required this.currentStep,
    required this.activeColor,
    required this.inactiveColor,
    required this.foregroundColor,
    required this.inactiveForegroundColor,
    required this.completedIcon,
    required this.stepNumberStyle,
    required this.bubbleSize,
    required this.duration,
    required this.curve,
  });

  final int stepNumber;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final Color foregroundColor;
  final Color inactiveForegroundColor;
  final IconData completedIcon;
  final TextStyle? stepNumberStyle;
  final double bubbleSize;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final isCompleted = stepNumber < currentStep;
    final isActive = stepNumber == currentStep;

    final backgroundColor =
        (isCompleted || isActive) ? activeColor : inactiveColor;

    final resolvedForeground =
        (isCompleted || isActive) ? foregroundColor : inactiveForegroundColor;

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                completedIcon,
                size: 16,
                color: resolvedForeground,
              )
            : Text(
                '$stepNumber',
                style: BankTokens.labelSmall
                    .copyWith(
                      color: resolvedForeground,
                      fontSize: 11,
                    )
                    .merge(stepNumberStyle),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connecting line
// ---------------------------------------------------------------------------

class _ConnectingLine extends StatelessWidget {
  const _ConnectingLine({
    required this.completed,
    required this.activeColor,
    required this.lineColor,
    required this.duration,
    required this.curve,
  });

  final bool completed;
  final Color activeColor;
  final Color lineColor;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height: 2,
      color: completed ? activeColor : lineColor,
    );
  }
}
