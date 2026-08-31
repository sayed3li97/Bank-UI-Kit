import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Layout variant for [BankValueDiffRow].
///
/// Both variants speak the same grammar — old value, arrow, new value. They
/// differ only in where that phrase sits relative to the field label, which
/// is a density decision, not a change in what the reader is being told.
enum BankValueDiffStyle {
  /// Field label and the change phrase share one line, the phrase pushed to
  /// the trailing edge.
  inline,

  /// The change phrase sits on its own line beneath the field label, for
  /// narrow columns and long values.
  stacked,
}

/// What a change *means* to the person reviewing it.
///
/// Drives the colour of the change marker (the arrow) — and only that
/// marker. The new value itself is content, not a verdict, so it stays in
/// [BankThemeData.onSurface]: painting it amber turned every routine limit
/// edit into something that looked like a warning about the number itself.
enum BankValueDiffMeaning {
  /// The change is a fact. The default: most edits are neither good nor bad.
  neutral,

  /// The change is in the reviewer's favour (a fee going down, a rate
  /// improving).
  favourable,

  /// The change deserves scrutiny before approval — more exposure, weaker
  /// control, a limit going up.
  adverse,
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
/// - Both present: the old value struck through, an arrow, then the new
///   value — one grammar, in both [BankValueDiffStyle] variants.
/// - Old absent: the field was **added**: the new value is shown with a
///   positive `'+ Added'` chip.
/// - New absent: the field was **removed**: the old value is shown struck
///   through with a `'– Removed'` chip in the theme's negative colour.
///
/// Monetary values render through [BankBalanceText] (small tier), so they
/// mask automatically when privacy mode is active on the ambient
/// [BankUiScope].
///
/// Colour encodes *meaning*, and only on the arrow — see
/// [BankValueDiffMeaning] and [meaning]. [highlightIncrease] is the
/// shorthand for the common case: an increase between two [Money] values in
/// the same currency reads as [BankValueDiffMeaning.adverse].
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

  /// What this change means to the reviewer; colours the arrow.
  ///
  /// Defaults to [BankValueDiffMeaning.neutral]. Set it whenever the host
  /// knows the direction of travel — [highlightIncrease] only ever infers
  /// [BankValueDiffMeaning.adverse], and only for same-currency [Money].
  final BankValueDiffMeaning meaning;

  /// When `true` and both [oldMoney] and [newMoney] are provided in the
  /// same currency, a new value greater than the old one is treated as
  /// [BankValueDiffMeaning.adverse]. Enable for limit/amount fields.
  ///
  /// An explicit [meaning] wins over this inference.
  final bool highlightIncrease;

  /// No longer rendered. Kept so 0.2.0 call sites still compile.
  ///
  /// Up to 0.2.0 [BankValueDiffStyle.stacked] printed this string as a
  /// microlabel above the old value. In 0.3.0 the row settled on a single
  /// grammar — old value, arrow, new value — in *both*
  /// [BankValueDiffStyle] variants, so the `'Previous'` / `'New'`
  /// microlabels are gone from the rendering. Passing a value has no effect.
  ///
  /// There is no replacement parameter: the old/new relationship is carried
  /// by the struck-through value and the arrow, which need no caption. To
  /// localise what assistive technology says about the row, pass
  /// [semanticLabel].
  @Deprecated(
    'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
    'old-to-new grammar with no microlabels. Delete the argument; localise '
    'the spoken row with semanticLabel. Removed in 0.5.0.',
  )
  final String previousLabel;

  /// No longer rendered. Kept so 0.2.0 call sites still compile. See
  /// [previousLabel] for the migration.
  @Deprecated(
    'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
    'old-to-new grammar with no microlabels. Delete the argument; localise '
    'the spoken row with semanticLabel. Removed in 0.5.0.',
  )
  final String newLabel;

  /// Chip text (minus the `'+ '` prefix) for added fields.
  final String addedLabel;

  /// Chip text (minus the `'– '` prefix) for removed fields.
  final String removedLabel;

  /// Overrides the generated semantic announcement
  /// (`'label changed from X to Y'`). Supply for non-English locales.
  final String? semanticLabel;

  /// Overrides the row padding. Defaults to
  /// `EdgeInsets.symmetric(vertical: BankTokens.space2)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the arrow glyph between old and new values. Defaults to
  /// the direction-aware [BankIcons.forward] (or [BankIcons.back] in RTL).
  final IconData? arrowIcon;

  /// Overrides the "added" chip colour. Defaults to the theme
  /// positiveBalance.
  final Color? addedColor;

  /// Overrides the "removed" chip colour. Defaults to the theme
  /// negativeBalance, which — unlike the raw [BankTokens.danger] constant —
  /// is already the right red for the ambient brightness.
  final Color? removedColor;

  /// Overrides the arrow tint for an [BankValueDiffMeaning.adverse] change.
  /// Defaults to the theme pending colour.
  final Color? increaseColor;

  /// Merged over the field-label style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? labelStyle;

  /// Merged over the struck-through old-value style.
  final TextStyle? oldValueStyle;

  /// Merged over the new-value style.
  final TextStyle? newValueStyle;

  /// Creates an old-vs-new change row.
  const BankValueDiffRow({
    required this.label,
    super.key,
    this.oldValue,
    this.newValue,
    this.oldMoney,
    this.newMoney,
    this.style = BankValueDiffStyle.inline,
    this.meaning = BankValueDiffMeaning.neutral,
    this.highlightIncrease = false,
    @Deprecated(
      'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
      'old-to-new grammar with no microlabels. Delete the argument; localise '
      'the spoken row with semanticLabel. Removed in 0.5.0.',
    )
    this.previousLabel = 'Previous',
    @Deprecated(
      'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
      'old-to-new grammar with no microlabels. Delete the argument; localise '
      'the spoken row with semanticLabel. Removed in 0.5.0.',
    )
    this.newLabel = 'New',
    this.addedLabel = 'Added',
    this.removedLabel = 'Removed',
    this.semanticLabel,
    this.padding,
    this.arrowIcon,
    this.addedColor,
    this.removedColor,
    this.increaseColor,
    this.labelStyle,
    this.oldValueStyle,
    this.newValueStyle,
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

  /// [meaning], or the one [highlightIncrease] infers from the two amounts.
  BankValueDiffMeaning get _meaning =>
      meaning != BankValueDiffMeaning.neutral || !_isIncrease
          ? meaning
          : BankValueDiffMeaning.adverse;

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
        style: struckStyle.merge(oldValueStyle),
      );
    }
    return Text(
      oldValue ?? '',
      style: BankTokens.bodyMedium
          .copyWith(
            color: theme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
            decorationColor: theme.onSurfaceVariant,
          )
          .merge(oldValueStyle),
    );
  }

  Widget _buildNewValue(BankThemeData theme) {
    // Always onSurface: the new value is what the field will *be*, and a
    // number is not a warning. Whether the change deserves attention is the
    // arrow's job — see [_changeColor].
    if (newMoney != null) {
      return BankBalanceText(
        money: newMoney!,
        size: BankBalanceSize.small,
        style: theme.numeralSmall
            .copyWith(
              color: theme.onSurface,
              fontWeight: FontWeight.w600,
            )
            .merge(newValueStyle),
      );
    }
    return Text(
      newValue ?? '',
      style: BankTokens.bodyMedium
          .copyWith(
            color: theme.onSurface,
            fontWeight: FontWeight.w600,
          )
          .merge(newValueStyle),
    );
  }

  /// The ink of the change marker, by [_meaning].
  Color _changeColor(BankThemeData theme) => switch (_meaning) {
        BankValueDiffMeaning.neutral => theme.onSurfaceVariant,
        BankValueDiffMeaning.favourable => theme.positiveBalance,
        // Theme pending, not the raw BankTokens.warning constant: the token
        // is the light-surface amber and drops below AA on a dark card.
        BankValueDiffMeaning.adverse => increaseColor ?? theme.pending,
      };

  /// The arrow, bundled with the value it points at.
  ///
  /// Kept in one un-splittable [Row] because the cluster wraps: an arrow
  /// stranded at the end of a line points at nothing and reads as a stray
  /// glyph. The value is [Flexible] (loose, in a min-size row, so it is also
  /// safe under unbounded width) — the bundle must yield to a narrow column
  /// rather than run off the end of it.
  Widget _buildChangeMarkerAndNewValue(
    BuildContext context,
    BankThemeData theme,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          arrowIcon ?? (isRtl ? BankIcons.back : BankIcons.forward),
          size: BankTokens.iconXSmall,
          color: _changeColor(theme),
        ),
        const SizedBox(width: BankTokens.space2),
        Flexible(child: _buildNewValue(theme)),
      ],
    );
  }

  Widget _buildChip(BankThemeData theme, String text, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: BankTokens.alphaMuted),
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
    if (_hasOld && _hasNew) {
      return [
        _buildOldValue(theme),
        _buildChangeMarkerAndNewValue(context, theme),
      ];
    }
    if (_hasNew) {
      return [
        _buildNewValue(theme),
        _buildChip(
          theme,
          '+ $addedLabel',
          addedColor ?? theme.positiveBalance,
        ),
      ];
    }
    return [
      _buildOldValue(theme),
      _buildChip(
        theme,
        '– $removedLabel',
        removedColor ?? theme.negativeBalance,
      ),
    ];
  }

  Widget _buildInline(BuildContext context, BankThemeData theme) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: BankTokens.bodySmall
                .copyWith(color: theme.onSurfaceVariant)
                .merge(labelStyle),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

  /// The same value cluster as [_buildInline], moved under the field label
  /// instead of beside it — a density variant, not a second grammar.
  Widget _buildStacked(BuildContext context, BankThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BankTokens.bodySmall
              .copyWith(color: theme.onSurfaceVariant)
              .merge(labelStyle),
        ),
        const SizedBox(height: BankTokens.space1),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BankTokens.space2,
          runSpacing: BankTokens.space1,
          children: _buildValueCluster(context, theme),
        ),
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
          padding: padding ??
              const EdgeInsets.symmetric(vertical: BankTokens.space2),
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

  /// See [BankValueDiffRow.meaning].
  final BankValueDiffMeaning meaning;

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
    this.meaning = BankValueDiffMeaning.neutral,
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
        other.meaning == meaning &&
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
        meaning,
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

  /// No longer rendered, and no longer forwarded to the rows. See
  /// [BankValueDiffRow.previousLabel] for the migration.
  @Deprecated(
    'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
    'old-to-new grammar with no microlabels. Delete the argument; localise '
    'each row with BankValueDiffItem.semanticLabel. Removed in 0.5.0.',
  )
  final String previousLabel;

  /// No longer rendered, and no longer forwarded to the rows. See
  /// [BankValueDiffRow.previousLabel] for the migration.
  @Deprecated(
    'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
    'old-to-new grammar with no microlabels. Delete the argument; localise '
    'each row with BankValueDiffItem.semanticLabel. Removed in 0.5.0.',
  )
  final String newLabel;

  /// See [BankValueDiffRow.addedLabel].
  final String addedLabel;

  /// See [BankValueDiffRow.removedLabel].
  final String removedLabel;

  /// Overrides the card background colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card border colour. Defaults to the theme outline.
  final Color? borderColor;

  /// Overrides the inter-row divider colour. Defaults to the theme
  /// onSurface at 8% opacity.
  final Color? dividerColor;

  /// Merged over the title style (BankTokens.labelLarge in onSurface).
  final TextStyle? titleStyle;

  /// See [BankValueDiffRow.arrowIcon].
  final IconData? arrowIcon;

  /// See [BankValueDiffRow.addedColor].
  final Color? addedColor;

  /// See [BankValueDiffRow.removedColor].
  final Color? removedColor;

  /// See [BankValueDiffRow.increaseColor].
  final Color? increaseColor;

  /// See [BankValueDiffRow.labelStyle].
  final TextStyle? labelStyle;

  /// See [BankValueDiffRow.oldValueStyle].
  final TextStyle? oldValueStyle;

  /// See [BankValueDiffRow.newValueStyle].
  final TextStyle? newValueStyle;

  /// Creates a card of old-vs-new change rows.
  const BankValueDiffList({
    required this.items,
    super.key,
    this.style = BankValueDiffStyle.inline,
    this.title,
    this.showDividers = true,
    this.padding,
    @Deprecated(
      'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
      'old-to-new grammar with no microlabels. Delete the argument; localise '
      'each row with BankValueDiffItem.semanticLabel. Removed in 0.5.0.',
    )
    this.previousLabel = 'Previous',
    @Deprecated(
      'No longer rendered: 0.3.0 gave both BankValueDiffStyle variants one '
      'old-to-new grammar with no microlabels. Delete the argument; localise '
      'each row with BankValueDiffItem.semanticLabel. Removed in 0.5.0.',
    )
    this.newLabel = 'New',
    this.addedLabel = 'Added',
    this.removedLabel = 'Removed',
    this.backgroundColor,
    this.radius,
    this.borderColor,
    this.dividerColor,
    this.titleStyle,
    this.arrowIcon,
    this.addedColor,
    this.removedColor,
    this.increaseColor,
    this.labelStyle,
    this.oldValueStyle,
    this.newValueStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = BankThemeData.of(context);
    final resolvedDividerColor =
        dividerColor ?? theme.onSurface.withValues(alpha: 0.08);

    final children = <Widget>[];
    if (title != null) {
      children
        ..add(
          Text(
            title!,
            style: BankTokens.labelLarge
                .copyWith(color: theme.onSurface)
                .merge(titleStyle),
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
          meaning: item.meaning,
          highlightIncrease: item.highlightIncrease,
          // previousLabel / newLabel are deliberately not forwarded: both are
          // deprecated no-ops on the row, and passing them here would only
          // hide the analyzer warning an adopter needs to see.
          addedLabel: addedLabel,
          removedLabel: removedLabel,
          semanticLabel: item.semanticLabel,
          arrowIcon: arrowIcon,
          addedColor: addedColor,
          removedColor: removedColor,
          increaseColor: increaseColor,
          labelStyle: labelStyle,
          oldValueStyle: oldValueStyle,
          newValueStyle: newValueStyle,
        ),
      );
      if (showDividers && i < items.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, color: resolvedDividerColor),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: radius ?? theme.cardRadius,
        border: Border.all(color: borderColor ?? theme.outline),
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
