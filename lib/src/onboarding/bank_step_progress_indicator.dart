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

  const BankStepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.labels,
    this.showLabels = false,
  })  : assert(totalSteps > 0, 'totalSteps must be positive'),
        assert(
          currentStep >= 1 && currentStep <= totalSteps,
          'currentStep must be between 1 and totalSteps (inclusive)',
        );

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Build the list of step indices in display order.
    final indices = List<int>.generate(totalSteps, (i) => i + 1);
    final displayIndices = isRtl ? indices.reversed.toList() : indices;

    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepRow(
            displayIndices: displayIndices,
            currentStep: currentStep,
            bankTheme: bankTheme,
          ),
          if (showLabels && labels != null) ...[
            const SizedBox(height: BankTokens.space2),
            _LabelsRow(
              displayIndices: displayIndices,
              labels: labels!,
              bankTheme: bankTheme,
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
    required this.bankTheme,
  });

  final List<int> displayIndices;
  final int currentStep;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i < displayIndices.length; i++) {
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
              bankTheme: bankTheme,
            ),
          ),
        );
      }

      children.add(
        _StepBubble(
          stepNumber: stepIndex,
          currentStep: currentStep,
          bankTheme: bankTheme,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
    required this.bankTheme,
  });

  final List<int> displayIndices;
  final List<String> labels;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i < displayIndices.length; i++) {
      final stepIndex = displayIndices[i];

      if (i > 0) {
        // Spacer that aligns with the connecting line.
        children.add(const Expanded(child: SizedBox.shrink()));
      }

      // Each label is centred below its bubble (28 px wide).
      final labelText =
          (stepIndex - 1) < labels.length ? labels[stepIndex - 1] : '';

      children.add(
        SizedBox(
          width: 28,
          child: Text(
            labelText,
            style: BankTokens.bodySmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
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
    required this.bankTheme,
  });

  final int stepNumber;
  final int currentStep;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final isCompleted = stepNumber < currentStep;
    final isActive = stepNumber == currentStep;

    final backgroundColor = (isCompleted || isActive)
        ? bankTheme.primary
        : bankTheme.surfaceVariant;

    final foregroundColor =
        (isCompleted || isActive) ? Colors.white : bankTheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: BankTokens.durationBase,
      curve: BankTokens.curveStandard,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                size: 16,
                color: foregroundColor,
              )
            : Text(
                '$stepNumber',
                style: BankTokens.labelSmall.copyWith(
                  color: foregroundColor,
                  fontSize: 11,
                ),
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
    required this.bankTheme,
  });

  final bool completed;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BankTokens.durationBase,
      curve: BankTokens.curveStandard,
      height: 2,
      color: completed ? bankTheme.primary : bankTheme.outline,
    );
  }
}
