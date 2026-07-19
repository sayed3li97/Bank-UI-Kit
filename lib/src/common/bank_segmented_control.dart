import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A single option in a [BankSegmentedControl].
class BankSegmentItem<T> {
  const BankSegmentItem({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  /// The value this segment represents.
  final T value;

  /// The visible segment label.
  final String label;

  /// Optional semantic override for assistive technologies.
  final String? semanticLabel;
}

/// A theme-driven segmented control that never wraps its labels mid-word.
///
/// Replaces stock Material [SegmentedButton] on kit surfaces: selection is
/// shown by fill and weight (no checkmark glyph), every colour and radius
/// defaults to [BankThemeData] tokens, and the control sizes itself to its
/// content instead of stretching segments until labels fracture.
class BankSegmentedControl<T> extends StatelessWidget {
  const BankSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
    this.selectedColor,
    this.selectedForegroundColor,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.radius,
    this.labelStyle,
    this.segmentPadding,
    this.semanticLabel,
  });

  /// The selectable segments, in visual order.
  final List<BankSegmentItem<T>> segments;

  /// The currently selected value.
  final T selected;

  /// Called with the tapped segment's value.
  final ValueChanged<T> onChanged;

  /// Fill behind the selected segment. Defaults to the theme primary.
  final Color? selectedColor;

  /// Label colour on the selected segment. Defaults to the theme onPrimary.
  final Color? selectedForegroundColor;

  /// Label colour on unselected segments. Defaults to the theme onSurface.
  final Color? foregroundColor;

  /// Track fill behind unselected segments. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Outline colour. Defaults to the theme outline at half opacity.
  final Color? borderColor;

  /// Corner radius. Defaults to the theme chip radius.
  final BorderRadius? radius;

  /// Label text style. Defaults to [BankTokens.labelLarge].
  final TextStyle? labelStyle;

  /// Padding inside each segment.
  final EdgeInsetsGeometry? segmentPadding;

  /// Semantic label for the whole control.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bank = BankThemeData.of(context);
    final resolvedRadius =
        radius ?? BorderRadius.circular(BankTokens.radiusMedium);
    return Semantics(
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? bank.surface,
          borderRadius: resolvedRadius,
          border: Border.all(
            color: borderColor ?? bank.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final segment in segments)
              Padding(
                padding: const EdgeInsets.all(BankTokens.space1),
                child: TextButton(
                  onPressed: () => onChanged(segment.value),
                  child: Text(segment.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
