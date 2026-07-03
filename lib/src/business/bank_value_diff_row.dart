import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Layout variant for [BankValueDiffRow].
enum BankValueDiffStyle {
  /// Old and new values on one line: the old value struck through in a
  /// secondary colour, followed by an arrow icon and the new value.
  inline,

  /// Old and new values on two lines, each introduced by a microlabel
  /// (`'Previous'` / `'New'` by default).
  stacked,
}

/// An old-vs-new change display for approval and profile-change review
/// screens.
///
/// Shows a single changed field as a labelled row. Use it wherever a
/// reviewer must understand exactly what an approval request modifies:
/// limit increases, beneficiary edits, profile updates, mandate changes.
///
/// Provide the previous value via [oldValue] *or* [oldMoney], and the new
/// value via [newValue] *or* [newMoney]:
///
/// - Both present: rendered per [style]: [BankValueDiffStyle.inline]
///   strikes through the old value and points an arrow at the new one;
///   [BankValueDiffStyle.stacked] lists them on two microlabelled lines.
/// - Old absent: the field was **added**: the new value is shown with a
///   positive `'+ Added'` chip.
/// - New absent: the field was **removed**: the old value is shown struck
///   through with a danger `'– Removed'` chip.
///
/// Monetary values render through [BankBalanceText] (small tier), so they
/// mask automatically when privacy mode is active on the ambient
/// [BankUiScope]. When [highlightIncrease] is `true` and both sides are
/// [Money] in the same currency, an increased new value is tinted with
/// [BankTokens.warning]: use this for limits and amounts where an
/// increase deserves reviewer attention.
///
/// Assistive technologies announce the row as
/// `'label changed from X to Y'` (or the added/removed equivalent);
/// override with [semanticLabel] for localisation.
///
/// For a whole change-set, compose rows with [BankValueDiffList], which
/// renders them in a `BankSummaryStack`-consistent card.
///
/// ```dart
/// BankValueDiffRow(
///   label: 'Daily transfer limit',
///   oldMoney: Money.fromDouble(5000, 'USD'),
///   newMoney: Money.fromDouble(25000, 'USD'),
///   highlightIncrease: true,
/// )
/// ```
class BankValueDiffRow extends StatelessWidget {
  /// Name of the changed field (e.g. `'Daily transfer limit'`).
  final String label;

  /// Previous plain-text value. Mutually exclusive with [oldMoney].
  final String? oldValue;

  /// New plain-text value. Mutually exclusive with [newMoney].
  final String? newValue;

  /// Previous monetary value. Mutually exclusive with [oldValue].
  final Money? oldMoney;

  /// New monetary value. Mutually exclusive with [newValue].
  final Money? newMoney;

  /// How the old and new values are laid out when both are present.
  final BankValueDiffStyle style;

  /// When `true` and both [oldMoney] and [newMoney] are provided in the
  /// same currency, a new value greater than the old one is tinted with
  /// [BankTokens.warning]. Enable for limit/amount fields.
  final bool highlightIncrease;

  /// Microlabel above/next to the previous value in
  /// [BankValueDiffStyle.stacked].
  final String previousLabel;

  /// Microlabel above/next to the new value in
  /// [BankValueDiffStyle.stacked].
  final String newLabel;

  /// Chip text (minus the `'+ '` prefix) for added fields.
  final String addedLabel;

  /// Chip text (minus the `'– '` prefix) for removed fields.
  final String removedLabel;

  /// Overrides the generated semantic announcement
  /// (`'label changed from X to Y'`). Supply for non-English locales.
  final String? semanticLabel;

  /// Creates an old-vs-new change row.
  const BankValueDiffRow({
    required this.label,
    super.key,
    this.oldValue,
    this.newValue,
    this.oldMoney,
    this.newMoney,
    this.style = BankValueDiffStyle.inline,
    this.highlightIncrease = false,
    this.previousLabel = 'Previous',
    this.newLabel = 'New',
    this.addedLabel = 'Added',
    this.removedLabel = 'Removed',
    this.semanticLabel,
  })  : assert(
          oldValue == null || oldMoney == null,
          'Provide at most one of oldValue or oldMoney.',
        ),
        assert(
          newValue == null || newMoney == null,
          'Provide at most one of newValue or newMoney.',
        ),
        assert(
          oldValue != null ||
              oldMoney != null ||
              newValue != null ||
              newMoney != null,
          'Provide at least one old or new value.',
        );

  bool get _hasOld => oldValue != null || oldMoney != null;

  bool get _hasNew => newValue != null || newMoney != null;

  bool get _isIncrease =>
      highlightIncrease &&
      oldMoney != null &&
      newMoney != null &&
      oldMoney!.currencyCode == newMoney!.currencyCode &&
      newMoney!.amount > oldMoney!.amount;

  String _describe(
    BankUiScopeData scope, {
    String? value,
    Money? money,
  }) {
    if (money != null) {
      if (scope.privacyEnabled) return scope.strings.balanceHidden;
      return BankMoneyFormatter.format(
        amount: money.amount,
        currencyCode: money.currencyCode,
        numeralStyle: scope.numeralStyle,
      );
    }
    return value ?? '';
  }

  String _buildSemanticLabel(BankUiScopeData scope) {
    if (semanticLabel != null) return semanticLabel!;
    final oldText = _describe(scope, value: oldValue, money: oldMoney);
    final newText = _describe(scope, value: newValue, money: newMoney);
    if (_hasOld && _hasNew) {
      return '$label changed from $oldText to $newText';
    }
    if (_hasNew) return '$label $addedLabel: $newText';
    return '$label $removedLabel: $oldText';
  }

  Widget _buildOldValue(BankThemeData theme) {
    final struckStyle = theme.numeralSmall.copyWith(
      color: theme.onSurfaceVariant,
      decoration: TextDecoration.lineThrough,
      decorationColor: theme.onSurfaceVariant,
    );
    if (oldMoney != null) {
      return BankBalanceText(
        money: oldMoney!,
        size: BankBalanceSize.small,
        style: struckStyle,
      );
    }
    return Text(
      oldValue ?? '',
      style: BankTokens.bodyMedium.copyWith(
        color: theme.onSurfaceVariant,
        decoration: TextDecoration.lineThrough,
        decorationColor: theme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildNewValue(BankThemeData theme) {
    final color = _isIncrease ? BankTokens.warning : theme.onSurface;
    if (newMoney != null) {
      return BankBalanceText(
        money: newMoney!,
        size: BankBalanceSize.small,
        style: theme.numeralSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      newValue ?? '',
      style: BankTokens.bodyMedium.copyWith(
        color: theme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChip(BankThemeData theme, String text, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1,
        ),
        child: Text(
          text,
          style: BankTokens.labelSmall.copyWith(color: color),
        ),
      ),
    );
  }

  List<Widget> _buildValueCluster(BuildContext context, BankThemeData theme) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (_hasOld && _hasNew) {
      return [
        _buildOldValue(theme),
        Icon(
          isRtl ? BankIcons.back : BankIcons.forward,
          size: 14,
          color: theme.onSurfaceVariant,
        ),
        _buildNewValue(theme),
      ];
    }
    if (_hasNew) {
      return [
        _buildNewValue(theme),
        _buildChip(theme, '+ $addedLabel', theme.positiveBalance),
      ];
    }
    return [
      _buildOldValue(theme),
      _buildChip(theme, '– $removedLabel', BankTokens.danger),
    ];
  }

  Widget _buildInline(BuildContext context, BankThemeData theme) {
    return Row(
      children: [
        Text(
          label,
          style: BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
        ),
        const SizedBox(width: BankTokens.space4),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: BankTokens.space2,
              runSpacing: BankTokens.space1,
              children: _buildValueCluster(context, theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedLine(
    BankThemeData theme,
    String microlabel,
    Widget value,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            microlabel,
            style:
                BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: value,
          ),
        ),
      ],
    );
  }

  Widget _buildStacked(BuildContext context, BankThemeData theme) {
    final List<Widget> lines;
    if (_hasOld && _hasNew) {
      lines = [
        _buildStackedLine(theme, previousLabel, _buildOldValue(theme)),
        const SizedBox(height: BankTokens.space1),
        _buildStackedLine(theme, newLabel, _buildNewValue(theme)),
      ];
    } else if (_hasNew) {
      lines = [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space1,
          children: [
            _buildChip(theme, '+ $addedLabel', theme.positiveBalance),
            _buildNewValue(theme),
          ],
        ),
      ];
    } else {
      lines = [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space1,
          children: [
            _buildChip(theme, '– $removedLabel', BankTokens.danger),
            _buildOldValue(theme),
          ],
        ),
      ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
        ),
        const SizedBox(height: BankTokens.space1),
        ...lines,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final content = style == BankValueDiffStyle.inline
        ? _buildInline(context, theme)
        : _buildStacked(context, theme);

    return Semantics(
      label: _buildSemanticLabel(scope),
      container: true,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Describes one changed field inside a [BankValueDiffList].
///
/// Provide the previous value via [oldValue] *or* [oldMoney], and the new
/// value via [newValue] *or* [newMoney]. Leaving the old side `null` marks
/// the field as added; leaving the new side `null` marks it as removed.
@immutable
class BankValueDiffItem {
  /// Name of the changed field.
  final String label;

  /// Previous plain-text value. Mutually exclusive with [oldMoney].
  final String? oldValue;

  /// New plain-text value. Mutually exclusive with [newMoney].
  final String? newValue;

  /// Previous monetary value. Mutually exclusive with [oldValue].
  final Money? oldMoney;

  /// New monetary value. Mutually exclusive with [newValue].
  final Money? newMoney;

  /// See [BankValueDiffRow.highlightIncrease].
  final bool highlightIncrease;

  /// See [BankValueDiffRow.semanticLabel].
  final String? semanticLabel;

  /// Creates an immutable description of one changed field.
  const BankValueDiffItem({
    required this.label,
    this.oldValue,
    this.newValue,
    this.oldMoney,
    this.newMoney,
    this.highlightIncrease = false,
    this.semanticLabel,
  })  : assert(
          oldValue == null || oldMoney == null,
          'Provide at most one of oldValue or oldMoney.',
        ),
        assert(
          newValue == null || newMoney == null,
          'Provide at most one of newValue or newMoney.',
        ),
        assert(
          oldValue != null ||
              oldMoney != null ||
              newValue != null ||
              newMoney != null,
          'Provide at least one old or new value.',
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankValueDiffItem &&
        other.label == label &&
        other.oldValue == oldValue &&
        other.newValue == newValue &&
        other.oldMoney == oldMoney &&
        other.newMoney == newMoney &&
        other.highlightIncrease == highlightIncrease &&
        other.semanticLabel == semanticLabel;
  }

  @override
  int get hashCode => Object.hash(
        label,
        oldValue,
        newValue,
        oldMoney,
        newMoney,
        highlightIncrease,
        semanticLabel,
      );
}

/// A card listing every field changed by an approval request.
///
/// Renders each [BankValueDiffItem] as a [BankValueDiffRow], separated by
/// 1 px dividers at 8% [BankThemeData.onSurface] opacity, inside a
/// `BankSummaryStack`-consistent card: [BankThemeData.surface] background,
/// [BankThemeData.cardRadius] corners, and a hairline
/// [BankThemeData.outline] border. Renders nothing when [items] is empty.
///
/// ```dart
/// BankValueDiffList(
///   items: [
///     BankValueDiffItem(
///       label: 'Daily limit',
///       oldMoney: Money.fromDouble(5000, 'USD'),
///       newMoney: Money.fromDouble(25000, 'USD'),
///       highlightIncrease: true,
///     ),
///     const BankValueDiffItem(
///       label: 'Nickname',
///       oldValue: 'Ops account',
///       newValue: 'Operations: EMEA',
///     ),
///     const BankValueDiffItem(
///       label: 'Second approver',
///       newValue: 'Lina Haddad',
///     ),
///   ],
///   title: 'Requested changes',
/// )
/// ```
class BankValueDiffList extends StatelessWidget {
  /// The changed fields to display, in order.
  final List<BankValueDiffItem> items;

  /// Layout variant applied to every row.
  final BankValueDiffStyle style;

  /// Optional heading rendered above the rows.
  final String? title;

  /// Whether to draw a 1 px divider between consecutive rows.
  final bool showDividers;

  /// Inner padding of the card. Defaults to [BankTokens.space4] all round.
  final EdgeInsetsGeometry? padding;

  /// See [BankValueDiffRow.previousLabel].
  final String previousLabel;

  /// See [BankValueDiffRow.newLabel].
  final String newLabel;

  /// See [BankValueDiffRow.addedLabel].
  final String addedLabel;

  /// See [BankValueDiffRow.removedLabel].
  final String removedLabel;

  /// Creates a card of old-vs-new change rows.
  const BankValueDiffList({
    required this.items,
    super.key,
    this.style = BankValueDiffStyle.inline,
    this.title,
    this.showDividers = true,
    this.padding,
    this.previousLabel = 'Previous',
    this.newLabel = 'New',
    this.addedLabel = 'Added',
    this.removedLabel = 'Removed',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = BankThemeData.of(context);
    final dividerColor = theme.onSurface.withValues(alpha: 0.08);

    final children = <Widget>[];
    if (title != null) {
      children
        ..add(
          Text(
            title!,
            style: BankTokens.labelLarge.copyWith(color: theme.onSurface),
          ),
        )
        ..add(const SizedBox(height: BankTokens.space2));
    }
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      children.add(
        BankValueDiffRow(
          label: item.label,
          oldValue: item.oldValue,
          newValue: item.newValue,
          oldMoney: item.oldMoney,
          newMoney: item.newMoney,
          style: style,
          highlightIncrease: item.highlightIncrease,
          previousLabel: previousLabel,
          newLabel: newLabel,
          addedLabel: addedLabel,
          removedLabel: removedLabel,
          semanticLabel: item.semanticLabel,
        ),
      );
      if (showDividers && i < items.length - 1) {
        children.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BankTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
