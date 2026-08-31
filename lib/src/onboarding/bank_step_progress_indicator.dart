import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/bank_pressable.dart';
import '../common/bank_sheet.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Which steps of a [BankStepProgressIndicator] render their help affordance.
enum BankStepHelpVisibility {
  /// Only the step the user is on.
  ///
  /// The default: one glyph per stepper keeps the row legible at eight steps
  /// on a 320 px screen, and the live step is the only one whose question the
  /// applicant is actually being asked right now.
  currentStep,

  /// Every step that carries help copy — for a review screen where the user
  /// looks back at what each step asked for.
  allSteps,
}

/// Numbered step progress indicator. RTL-aware: steps flow right-to-left
/// when [Directionality] is RTL.
///
/// Geometry follows the standard enterprise-stepper anatomy: every step
/// gets one equal-flex cell containing its bubble and (optionally) its
/// label, and each connector is drawn as two half-lines inside the
/// neighbouring cells, so labels get the full cell width instead of the
/// bubble width and never break mid-word for realistic label lengths.
///
/// ### Step-level help
///
/// Pass [stepHelp] to give a step a "why do we ask this?" affordance — the
/// disclosure a regulated origination or KYC flow owes the applicant at the
/// moment it asks for a document or an identifier, rather than in a policy
/// page they will never open:
///
/// ```dart
/// BankStepProgressIndicator(
///   totalSteps: 3,
///   currentStep: 2,
///   showLabels: true,
///   labels: const ['Identity', 'Income', 'Review'],
///   stepHelp: const [
///     'We check your ID against the national register — a legal requirement '
///         'before we can open an account.',
///     'Your income tells us which products you can afford to be offered.',
///     '',
///   ],
/// )
/// ```
///
/// The affordance sits *under* the step label, not beside it: a cell is as
/// narrow as ~40 px in an eight-step stepper on a small screen, so an inline
/// control would take back exactly the width the equal-flex cell layout gave
/// the label, and labels would break mid-word again. Stacking spends height,
/// which the stepper has.
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

  /// Optional per-step explanatory copy. Index `i` belongs to step `i + 1`;
  /// a missing or empty entry leaves that step without an affordance.
  ///
  /// Opt-in: with [stepHelp] null the stepper renders exactly as before.
  final List<String>? stepHelp;

  /// Which steps render their [stepHelp] affordance. Defaults to
  /// [BankStepHelpVisibility.currentStep].
  final BankStepHelpVisibility helpVisibility;

  /// Called when the user opens a step's help, with the 1-indexed step and
  /// its copy.
  ///
  /// When null the widget presents the copy itself in a [BankSheet] titled
  /// with the step's label, so [stepHelp] alone is a working affordance.
  /// Provide it to route the disclosure somewhere else — an analytics event,
  /// a full compliance screen, an in-app help centre.
  final void Function(int step, String helpText)? onStepHelp;

  /// Screen-reader label and tooltip for the help affordance, and the sheet
  /// title for steps with no label. Defaults to 'Why do we ask this?'.
  final String helpLabel;

  /// Glyph for the help affordance. Defaults to [BankIcons.info].
  final IconData? helpIcon;

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
    this.stepHelp,
    this.helpVisibility = BankStepHelpVisibility.currentStep,
    this.onStepHelp,
    this.helpLabel = 'Why do we ask this?',
    this.helpIcon,
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

    /// Label slot of [step]: null when labels are hidden, and an empty string
    /// for a step the caller did not name — the empty line keeps every cell
    /// the same height so the bubbles stay on one baseline.
    String? labelFor(int step) {
      final all = labels;
      if (!showLabels || all == null) return null;
      return step - 1 < all.length ? all[step - 1] : '';
    }

    /// Help copy of [step], or null when the step has none.
    String? helpFor(int step) {
      final all = stepHelp;
      if (all == null || step - 1 >= all.length) return null;
      final copy = all[step - 1];
      return copy.isEmpty ? null : copy;
    }

    Widget? helpActionFor(int step) {
      if (helpVisibility == BankStepHelpVisibility.currentStep &&
          step != currentStep) {
        return null;
      }
      final copy = helpFor(step);
      if (copy == null) return null;
      return _StepHelpAction(
        step: step,
        helpText: copy,
        stepLabel: labels != null && step - 1 < labels!.length
            ? labels![step - 1]
            : null,
        label: helpLabel,
        icon: helpIcon ?? BankIcons.info,
        // The glyph inherits the step's own state colour, so an affordance on
        // the live step reads as live rather than as decoration.
        color:
            step == currentStep ? resolvedActive : resolvedInactiveForeground,
        onStepHelp: onStepHelp,
      );
    }

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
                label: labelFor(displayIndices[i]),
                helpAction: helpActionFor(displayIndices[i]),
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
    required this.helpAction,
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

  /// The step's help affordance, or `null` when it has none.
  final Widget? helpAction;

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
        if (helpAction != null) ...[
          const SizedBox(height: BankTokens.space1),
          helpAction!,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step help affordance
// ---------------------------------------------------------------------------

/// The per-step "why do we ask this?" button.
///
/// The tap target is a full [BankTokens.minTapTarget] square wherever the cell
/// is wide enough to hold one; in a stepper dense enough that the cell is
/// narrower, [SizedBox] clamps it to the cell rather than overflowing the row,
/// which is the widest target the layout can honestly offer.
class _StepHelpAction extends StatelessWidget {
  const _StepHelpAction({
    required this.step,
    required this.helpText,
    required this.stepLabel,
    required this.label,
    required this.icon,
    required this.color,
    required this.onStepHelp,
  });

  final int step;
  final String helpText;

  /// The step's own label, used as the sheet title when the widget presents
  /// the copy itself.
  final String? stepLabel;

  /// Screen-reader label and tooltip.
  final String label;

  final IconData icon;
  final Color color;
  final void Function(int step, String helpText)? onStepHelp;

  void _open(BuildContext context) {
    final handler = onStepHelp;
    if (handler != null) {
      handler(step, helpText);
      return;
    }
    final theme = BankThemeData.of(context);
    unawaited(
      BankSheet.show<void>(
        context,
        title:
            (stepLabel != null && stepLabel!.isNotEmpty) ? stepLabel! : label,
        builder: (_) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BankTokens.space4,
            0,
            BankTokens.space4,
            BankTokens.space6,
          ),
          child: Text(
            helpText,
            style: BankTokens.bodyMedium.copyWith(color: theme.onSurface),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The stepper's own 'Step X of Y' annotation absorbs every non-boundary
    // descendant into one node; without this container the button's label and
    // tap action would be swallowed by it and the affordance would be
    // unreachable by assistive technology.
    return Semantics(
      container: true,
      child: Tooltip(
        message: label,
        // BankPressable already names the button; a tooltip node on top of it
        // would have a screen reader read the same sentence twice.
        excludeFromSemantics: true,
        child: BankPressable(
          onTap: () => _open(context),
          borderRadius: const BorderRadius.all(
            Radius.circular(BankTokens.radiusFull),
          ),
          semanticLabel: label,
          child: SizedBox(
            width: BankTokens.minTapTarget,
            height: BankTokens.minTapTarget,
            child: Center(
              child: Icon(icon, size: BankTokens.iconSmall, color: color),
            ),
          ),
        ),
      ),
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
