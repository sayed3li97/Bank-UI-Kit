import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Numbered step progress indicator. RTL-aware: steps flow right-to-left
/// when [Directionality] is RTL.
///
/// Geometry follows the standard enterprise-stepper anatomy: every step
/// gets one equal-flex cell containing its bubble and (optionally) its
/// label, and each connector is drawn as two half-lines inside the
/// neighbouring cells, so labels get the full cell width instead of the
/// bubble width and never break mid-word for realistic label lengths.
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

  /// Maximum number of lines a step label may occupy before it
  /// ellipsizes. Defaults to 2.
  final int labelMaxLines;

  /// Optional cap on each label's width. By default a label may use its
  /// whole step cell; set this to keep labels compact on very wide
  /// layouts.
  final double? labelMaxWidth;

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
    this.labelMaxLines = 2,
    this.labelMaxWidth,
    this.semanticLabel,
  })  : assert(totalSteps > 0, 'totalSteps must be positive'),
        assert(
          currentStep >= 1 && currentStep <= totalSteps,
          'currentStep must be between 1 and totalSteps (inclusive)',
        ),
        assert(labelMaxLines > 0, 'labelMaxLines must be positive');

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

    // A connector between two steps is completed once the later of the two
    // steps has been reached; computing it order-independently keeps LTR
    // and RTL in the same state.
    bool connectorCompleted(int stepA, int stepB) {
      final hi = stepA > stepB ? stepA : stepB;
      return currentStep >= hi;
    }

    return Semantics(
      label: semanticLabel ?? 'Step $currentStep of $totalSteps',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < displayIndices.length; i++)
            Expanded(
              child: _StepCell(
                stepIndex: displayIndices[i],
                currentStep: currentStep,
                // Half-connector toward the previous display neighbour;
                // null at the leading edge.
                leadingConnectorCompleted: i == 0
                    ? null
                    : connectorCompleted(
                        displayIndices[i - 1],
                        displayIndices[i],
                      ),
                // Half-connector toward the next display neighbour;
                // null at the trailing edge.
                trailingConnectorCompleted: i == displayIndices.length - 1
                    ? null
                    : connectorCompleted(
                        displayIndices[i],
                        displayIndices[i + 1],
                      ),
                label: (showLabels && labels != null)
                    ? ((displayIndices[i] - 1) < labels!.length
                        ? labels![displayIndices[i] - 1]
                        : '')
                    : null,
                labelStyle: resolvedLabelStyle,
                labelMaxLines: labelMaxLines,
                labelMaxWidth: labelMaxWidth,
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
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step cell
// ---------------------------------------------------------------------------

/// One equal-flex stepper cell: the bubble flanked by its two connector
/// halves, with the (optional) label centred underneath on the full cell
/// width.
class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.stepIndex,
    required this.currentStep,
    required this.leadingConnectorCompleted,
    required this.trailingConnectorCompleted,
    required this.label,
    required this.labelStyle,
    required this.labelMaxLines,
    required this.labelMaxWidth,
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

  final int stepIndex;
  final int currentStep;

  /// Completed state of the connector half toward the previous display
  /// neighbour, or `null` at the leading edge of the stepper.
  final bool? leadingConnectorCompleted;

  /// Completed state of the connector half toward the next display
  /// neighbour, or `null` at the trailing edge of the stepper.
  final bool? trailingConnectorCompleted;

  /// Label text, or `null` when labels are hidden.
  final String? label;
  final TextStyle labelStyle;
  final int labelMaxLines;
  final double? labelMaxWidth;

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

  Widget _connectorHalf(bool? completed) {
    if (completed == null) {
      // Edge cell: an empty spacer keeps the bubble centred in its cell.
      return const Expanded(child: SizedBox.shrink());
    }
    return Expanded(
      child: _ConnectingLine(
        completed: completed,
        activeColor: activeColor,
        lineColor: lineColor,
        duration: duration,
        curve: curve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? labelWidget;
    if (label != null) {
      labelWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space1),
        child: Text(
          label!,
          style: labelStyle,
          textAlign: TextAlign.center,
          maxLines: labelMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      );
      if (labelMaxWidth != null) {
        labelWidget = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelMaxWidth!),
            child: labelWidget,
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: bubbleSize,
          child: Row(
            children: [
              _connectorHalf(leadingConnectorCompleted),
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
              _connectorHalf(trailingConnectorCompleted),
            ],
          ),
        ),
        if (labelWidget != null) ...[
          const SizedBox(height: BankTokens.space2),
          labelWidget,
        ],
      ],
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
