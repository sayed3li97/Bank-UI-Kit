import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accounts/bank_balance_text.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';
import 'money_formatter.dart';

/// Describes a single label/value row inside a [BankSummaryStack].
///
/// Provide at most one of [value], [money], or [valueWidget]:
/// - [value] renders plain text;
/// - [money] renders a privacy-aware [BankBalanceText];
/// - [valueWidget] embeds an arbitrary widget (e.g. a status chip).
@immutable
class BankSummaryItem {
  /// Short description shown at the start of the row (e.g. `'Reference'`).
  final String label;

  /// Plain-text value shown at the end of the row.
  final String? value;

  /// Monetary value rendered with [BankBalanceText]. It masks automatically
  /// when privacy mode is enabled on the ambient [BankUiScope].
  final Money? money;

  /// Arbitrary widget rendered in place of a text value.
  final Widget? valueWidget;

  /// When `true`, the value is rendered with stronger emphasis. Use for
  /// totals and other headline figures.
  final bool emphasized;

  /// When `true`, a copy affordance is appended after the value that
  /// copies the row's textual value to the [Clipboard].
  ///
  /// Ignored when the row has no textual value (i.e. only [valueWidget]).
  final bool copyable;

  /// When non-null, the row becomes tappable: it gains a ripple and a
  /// trailing chevron, and is exposed as a button to assistive tech.
  final VoidCallback? onTap;

  /// Creates an immutable description of one summary row.
  const BankSummaryItem({
    required this.label,
    this.value,
    this.money,
    this.valueWidget,
    this.emphasized = false,
    this.copyable = false,
    this.onTap,
  }) : assert(
          (value == null ? 0 : 1) +
                  (money == null ? 0 : 1) +
                  (valueWidget == null ? 0 : 1) <=
              1,
          'Provide at most one of value, money, or valueWidget.',
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankSummaryItem &&
        other.label == label &&
        other.value == value &&
        other.money == money &&
        other.valueWidget == valueWidget &&
        other.emphasized == emphasized &&
        other.copyable == copyable &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(
        label,
        value,
        money,
        valueWidget,
        emphasized,
        copyable,
        onTap,
      );
}

/// A stack of generic label/value rows for review, confirmation, and
/// detail screens.
///
/// Each [BankSummaryItem] renders as a row of at least 44 px: the label at
/// the start in a secondary style, and the value aligned to the end.
/// Monetary values are rendered through [BankBalanceText], so they mask
/// automatically when privacy mode is active on the ambient [BankUiScope].
/// Rows are separated by 1 px dividers at 8% [BankThemeData.onSurface]
/// opacity (disable with [showDividers]).
///
/// Rows can additionally be:
/// - **emphasized**: stronger value styling for totals;
/// - **copyable**: a trailing affordance copies the textual value to the
///   [Clipboard] and briefly confirms with a success icon;
/// - **tappable**: [BankSummaryItem.onTap] adds a ripple and a trailing
///   chevron, and exposes the row as a button.
///
/// Assistive technologies announce each row as `'label: value'`.
///
/// Compose this widget inside transfer-review, receipt, and detail flows
/// instead of hand-rolling per-screen row layouts.
///
/// ```dart
/// BankSummaryStack(
///   items: [
///     const BankSummaryItem(label: 'From', value: 'Everyday Checking'),
///     const BankSummaryItem(
///       label: 'Reference',
///       value: 'INV-2024-00071',
///       copyable: true,
///     ),
///     BankSummaryItem(
///       label: 'Total',
///       money: Money.fromDouble(1249.50, 'USD'),
///       emphasized: true,
///     ),
///   ],
/// )
/// ```
class BankSummaryStack extends StatelessWidget {
  /// The rows to display, in order.
  final List<BankSummaryItem> items;

  /// Whether to draw a 1 px divider between consecutive rows.
  final bool showDividers;

  /// Outer padding around the whole stack. Defaults to none.
  final EdgeInsetsGeometry? padding;

  /// Horizontal alignment of each value within its cell.
  ///
  /// [CrossAxisAlignment.end] (the default) aligns values to the row end;
  /// [CrossAxisAlignment.start] and [CrossAxisAlignment.center] are also
  /// supported. Any other value falls back to end alignment.
  final CrossAxisAlignment valueAlignment;

  /// Verb used in the semantic label of the copy affordance, announced as
  /// `'$copyActionLabel: <row label>'`.
  final String copyActionLabel;

  /// Overrides the divider colour. Defaults to [BankThemeData.onSurface]
  /// at 8 % opacity.
  final Color? dividerColor;

  /// Merged over the computed row label style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? labelStyle;

  /// Merged over the computed textual value style ([BankTokens.bodyMedium],
  /// or [BankTokens.labelLarge] when emphasized).
  final TextStyle? valueStyle;

  /// Merged over the computed monetary value style used by
  /// [BankBalanceText].
  final TextStyle? amountStyle;

  /// Overrides the copy affordance glyph. Defaults to [BankIcons.copy].
  final IconData? copyIcon;

  /// Overrides the post-copy confirmation glyph. Defaults to
  /// [BankIcons.success].
  final IconData? copiedIcon;

  /// Overrides the trailing chevron of tappable rows. Defaults to a
  /// direction-aware [Icons.chevron_right] / [Icons.chevron_left].
  final IconData? chevronIcon;

  /// Creates a stack of label/value summary rows.
  const BankSummaryStack({
    required this.items,
    super.key,
    this.showDividers = true,
    this.padding,
    this.valueAlignment = CrossAxisAlignment.end,
    this.copyActionLabel = 'Copy',
    this.dividerColor,
    this.labelStyle,
    this.valueStyle,
    this.amountStyle,
    this.copyIcon,
    this.copiedIcon,
    this.chevronIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = BankThemeData.of(context);
    final resolvedDividerColor =
        dividerColor ?? theme.onSurface.withValues(alpha: 0.08);

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(
        _BankSummaryRow(
          item: items[i],
          valueAlignment: valueAlignment,
          copyActionLabel: copyActionLabel,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
          amountStyle: amountStyle,
          copyIcon: copyIcon,
          copiedIcon: copiedIcon,
          chevronIcon: chevronIcon,
        ),
      );
      if (showDividers && i < items.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, color: resolvedDividerColor),
        );
      }
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _BankSummaryRow extends StatelessWidget {
  final BankSummaryItem item;
  final CrossAxisAlignment valueAlignment;
  final String copyActionLabel;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final TextStyle? amountStyle;
  final IconData? copyIcon;
  final IconData? copiedIcon;
  final IconData? chevronIcon;

  const _BankSummaryRow({
    required this.item,
    required this.valueAlignment,
    required this.copyActionLabel,
    this.labelStyle,
    this.valueStyle,
    this.amountStyle,
    this.copyIcon,
    this.copiedIcon,
    this.chevronIcon,
  });

  AlignmentGeometry get _valueCellAlignment => switch (valueAlignment) {
        CrossAxisAlignment.start => AlignmentDirectional.centerStart,
        CrossAxisAlignment.center => Alignment.center,
        _ => AlignmentDirectional.centerEnd,
      };

  TextAlign get _valueTextAlign => switch (valueAlignment) {
        CrossAxisAlignment.start => TextAlign.start,
        CrossAxisAlignment.center => TextAlign.center,
        _ => TextAlign.end,
      };

  Widget _buildValue(BankThemeData theme) {
    if (item.valueWidget != null) return item.valueWidget!;
    if (item.money != null) {
      final computed = item.emphasized
          ? theme.numeralSmall.copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w600,
            )
          : null;
      // Merge over the same base style BankBalanceText derives on its own
      // so partial amountStyle overrides behave as expected.
      final merged = amountStyle == null
          ? computed
          : (computed ?? theme.numeralSmall.copyWith(color: theme.onSurface))
              .merge(amountStyle);
      return BankBalanceText(
        money: item.money!,
        size: BankBalanceSize.small,
        style: merged,
      );
    }
    final style = item.emphasized
        ? BankTokens.labelLarge.copyWith(color: theme.onSurface)
        : BankTokens.bodyMedium.copyWith(color: theme.onSurface);
    return Text(
      item.value ?? '',
      style: style.merge(valueStyle),
      textAlign: _valueTextAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    String? formattedMoney;
    if (item.money != null) {
      formattedMoney = BankMoneyFormatter.format(
        amount: item.money!.amount,
        currencyCode: item.money!.currencyCode,
        numeralStyle: scope.numeralStyle,
      );
    }

    final String? semanticValue;
    if (item.valueWidget != null) {
      semanticValue = null;
    } else if (item.money != null) {
      semanticValue =
          scope.privacyEnabled ? scope.strings.balanceHidden : formattedMoney;
    } else {
      semanticValue = item.value;
    }

    // Money rows never copy the raw amount while privacy mode is on;
    // the affordance disappears rather than copying a masked string.
    final moneyCopyBlocked = item.money != null && scope.privacyEnabled;
    final copyText = item.value ?? formattedMoney;
    final showCopy = item.copyable && copyText != null && !moneyCopyBlocked;

    Widget cluster = Row(
      children: [
        Text(
          item.label,
          style: BankTokens.bodySmall
              .copyWith(color: theme.onSurfaceVariant)
              .merge(labelStyle),
        ),
        const SizedBox(width: BankTokens.space4),
        Expanded(
          child: Align(
            alignment: _valueCellAlignment,
            child: _buildValue(theme),
          ),
        ),
      ],
    );

    // Merge each row into a single 'label: value' announcement. Rows with
    // an opaque valueWidget merge whatever semantics the widget exposes.
    cluster = semanticValue == null
        ? MergeSemantics(child: cluster)
        : Semantics(
            label: '${item.label}: $semanticValue',
            excludeSemantics: true,
            child: cluster,
          );

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BankTokens.space1),
        child: Row(
          children: [
            Expanded(child: cluster),
            if (showCopy) ...[
              const SizedBox(width: BankTokens.space1),
              _CopyAffordance(
                text: copyText,
                semanticLabel: '$copyActionLabel: ${item.label}',
                copyIcon: copyIcon,
                copiedIcon: copiedIcon,
              ),
            ],
            if (item.onTap != null) ...[
              const SizedBox(width: BankTokens.space1),
              Icon(
                chevronIcon ??
                    (isRtl ? Icons.chevron_left : Icons.chevron_right),
                size: 20,
                color: theme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    if (item.onTap != null) {
      row = Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: item.onTap,
            child: row,
          ),
        ),
      );
    } else if (showCopy) {
      // The copy affordance's ink response needs a Material ancestor.
      row = Material(type: MaterialType.transparency, child: row);
    }

    return row;
  }
}

/// Tap target that copies [text] to the clipboard and briefly swaps the
/// copy icon for a success check as confirmation.
class _CopyAffordance extends StatefulWidget {
  final String text;
  final String semanticLabel;
  final IconData? copyIcon;
  final IconData? copiedIcon;

  const _CopyAffordance({
    required this.text,
    required this.semanticLabel,
    this.copyIcon,
    this.copiedIcon,
  });

  @override
  State<_CopyAffordance> createState() => _CopyAffordanceState();
}

class _CopyAffordanceState extends State<_CopyAffordance> {
  static const Duration _confirmFor = Duration(milliseconds: 1500);

  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(_confirmFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: _copy,
      excludeSemantics: true,
      child: SizedBox(
        width: BankTokens.minTapTarget,
        height: BankTokens.minTapTarget,
        child: InkResponse(
          onTap: _copy,
          radius: BankTokens.minTapTarget / 2,
          child: AnimatedSwitcher(
            duration:
                disableAnimations ? Duration.zero : BankTokens.durationFast,
            switchInCurve: BankTokens.curveStandard,
            switchOutCurve: BankTokens.curveStandard,
            child: Icon(
              _copied
                  ? (widget.copiedIcon ?? BankIcons.success)
                  : (widget.copyIcon ?? BankIcons.copy),
              key: ValueKey<bool>(_copied),
              size: 18,
              color: _copied ? BankTokens.success : theme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
