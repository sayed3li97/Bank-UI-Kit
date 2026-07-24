import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_pressable.dart';

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
/// shown by fill and weight (no checkmark glyph, so segment geometry never
/// shifts on tap), every colour and radius defaults to [BankThemeData]
/// tokens, and the control sizes segments to their content instead of
/// stretching them until labels fracture.
///
/// Layout contract: when the labels fit the available width, the row fills
/// it with equal-width segments (the familiar segmented silhouette). When
/// they do not — narrow phones, large text scales, long localized labels —
/// the row keeps its intrinsic width and scrolls horizontally instead of
/// wrapping or shrinking text. Labels are laid out with `softWrap: false`
/// and `maxLines: 1`, so a mid-word break is impossible by construction;
/// ellipsis exists only as a last resort under pathological constraints.
///
/// The control is stateless and controlled: pass the [selected] value and
/// rebuild with the value received in [onChanged].
///
/// ```dart
/// BankSegmentedControl<Period>(
///   segments: const [
///     BankSegmentItem(value: Period.week, label: 'Week'),
///     BankSegmentItem(value: Period.month, label: 'Month'),
///     BankSegmentItem(value: Period.year, label: 'Year'),
///   ],
///   selected: _period,
///   onChanged: (value) => setState(() => _period = value),
/// )
/// ```
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
  }) : assert(segments.length > 0, 'segments must not be empty');

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

  /// Label text style. Defaults to [BankTokens.labelLarge]; the selected
  /// segment additionally renders at [FontWeight.w700].
  final TextStyle? labelStyle;

  /// Padding inside each segment. Defaults to a horizontal
  /// [BankTokens.space4] inset.
  final EdgeInsetsGeometry? segmentPadding;

  /// Semantic label for the whole control.
  final String? semanticLabel;

  /// Inset between the track border and the segment pills.
  static const double _trackInset = 3;

  @override
  Widget build(BuildContext context) {
    final bank = BankThemeData.of(context);

    final resolvedSelectedFill = selectedColor ?? bank.primary;
    final resolvedSelectedFg = selectedForegroundColor ?? bank.onPrimary;
    final resolvedFg = foregroundColor ?? bank.onSurface;
    final trackRadius = radius ?? bank.chipRadius;
    // Concentric inner radius so pill corners follow the track corners.
    final pillRadius = _deflate(trackRadius, _trackInset);
    final resolvedPadding = segmentPadding ??
        const EdgeInsetsDirectional.symmetric(horizontal: BankTokens.space4);
    final baseStyle = BankTokens.labelLarge.merge(labelStyle);

    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? bank.surface,
        borderRadius: trackRadius,
        border: Border.all(
          color: borderColor ?? bank.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_trackInset),
        child: IntrinsicWidth(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final segment in segments)
                Expanded(
                  child: _Segment<T>(
                    item: segment,
                    isSelected: segment.value == selected,
                    onChanged: onChanged,
                    selectedFill: resolvedSelectedFill,
                    selectedForeground: resolvedSelectedFg,
                    foreground: resolvedFg,
                    radius: pillRadius,
                    padding: resolvedPadding,
                    baseStyle: baseStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Equal-width segments while the labels fit; horizontal scrolling —
    // never mid-word wrapping or text shrinking — when they do not.
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    constraints.hasBoundedWidth ? constraints.maxWidth : 0,
              ),
              child: track,
            ),
          );
        },
      ),
    );
  }

  static BorderRadius _deflate(BorderRadius radius, double inset) {
    Radius shrink(Radius r) => Radius.elliptical(
          (r.x - inset).clamp(0, double.infinity),
          (r.y - inset).clamp(0, double.infinity),
        );
    return BorderRadius.only(
      topLeft: shrink(radius.topLeft),
      topRight: shrink(radius.topRight),
      bottomLeft: shrink(radius.bottomLeft),
      bottomRight: shrink(radius.bottomRight),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.isSelected,
    required this.onChanged,
    required this.selectedFill,
    required this.selectedForeground,
    required this.foreground,
    required this.radius,
    required this.padding,
    required this.baseStyle,
  });

  final BankSegmentItem<T> item;
  final bool isSelected;
  final ValueChanged<T> onChanged;
  final Color selectedFill;
  final Color selectedForeground;
  final Color foreground;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final selectedStyle = baseStyle.copyWith(
      color: selectedForeground,
      fontWeight: FontWeight.w700,
    );
    final unselectedStyle = baseStyle.copyWith(color: foreground);

    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: BankPressable(
        onTap: () {
          if (!isSelected) onChanged(item.value);
        },
        borderRadius: radius,
        semanticLabel: item.semanticLabel ?? item.label,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: BankTokens.durationFast,
          curve: BankTokens.curveEmphasized,
          constraints: const BoxConstraints(
            minHeight: BankTokens.minTapTarget,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : Colors.transparent,
            borderRadius: radius,
          ),
          padding: padding,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Invisible bold ghost: reserves the selected-weight width so
              // the control's intrinsic width — and therefore the equal-flex
              // division — never shifts when the selection changes.
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(
                  item.label,
                  style: selectedStyle,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: BankTokens.durationFast,
                curve: BankTokens.curveEmphasized,
                style: isSelected ? selectedStyle : unselectedStyle,
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
