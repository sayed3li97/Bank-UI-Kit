import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_emblem.dart';
import '../common/bank_format_context.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_surface_depth.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A participant in a [BankMoneyCircleCard] rotating savings circle.
///
/// Immutable value object. [turnIndex] is 1-based: the member with
/// `turnIndex == 1` collects the pot in the first cycle.
@immutable
class BankCircleMember {
  /// Creates an immutable money-circle member.
  const BankCircleMember({
    required this.id,
    required this.name,
    required this.turnIndex,
    this.avatarUrl,
    this.paidThisCycle = false,
    this.isMe = false,
    this.isAdmin = false,
  });

  /// Stable unique identifier for the member.
  final String id;

  /// Display name, also used for the emblem initials fallback.
  final String name;

  /// Optional avatar URL, resolved via [BankUiScope.imageProviderFor].
  final String? avatarUrl;

  /// 1-based position in the collection rotation.
  final int turnIndex;

  /// Whether this member's contribution was collected this cycle.
  final bool paidThisCycle;

  /// Whether this member is the signed-in user.
  final bool isMe;

  /// Whether this member administers the circle.
  final bool isAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankCircleMember &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.turnIndex == turnIndex &&
        other.paidThisCycle == paidThisCycle &&
        other.isMe == isMe &&
        other.isAdmin == isAdmin;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        avatarUrl,
        turnIndex,
        paidThisCycle,
        isMe,
        isAdmin,
      );

  @override
  String toString() =>
      'BankCircleMember(id: $id, name: $name, turnIndex: $turnIndex)';
}

/// Summary card for one money circle: a digitized rotating savings
/// circle (ROSCA, "jamiyah") where every member contributes a fixed
/// amount each cycle and one member, by turn order, collects the pot.
///
/// The card shows the circle name, the monthly contribution, the pot
/// per cycle (contribution multiplied by member count) as the hero
/// amount, a horizontal turn tracker of member avatars in turn order,
/// the next collection date, the signed-in user's turn, and a payment
/// status strip for the current cycle. All money rendering goes
/// through [BankBalanceText], so privacy mode masks automatically.
///
/// Set [isAdminView] to true for the circle administrator: unpaid
/// members receive a quiet warning tint in the tracker and the
/// [onRemind] action becomes available.
///
/// When [currentCycle] exceeds [totalCycles] the circle is complete
/// and the card swaps the schedule details for a celebratory line.
///
/// ```dart
/// BankMoneyCircleCard(
///   name: 'Family circle',
///   contribution: Money.fromDouble(100, 'BHD'),
///   members: members,
///   currentCycle: 3,
///   totalCycles: 8,
///   nextCollectionDate: DateTime(2026, 8, 1),
///   isAdminView: true,
///   onRemind: sendReminders,
///   onViewDetails: openCircleDetails,
/// )
/// ```
class BankMoneyCircleCard extends StatelessWidget {
  /// Creates a money-circle summary card.
  const BankMoneyCircleCard({
    required this.name,
    required this.contribution,
    required this.members,
    required this.currentCycle,
    required this.totalCycles,
    required this.nextCollectionDate,
    super.key,
    this.isAdminView = false,
    this.onRemind,
    this.onViewDetails,
    this.potPerCycleLabel = 'Pot per cycle',
    this.monthlyContributionLabel = 'Monthly contribution',
    this.nextCollectionLabel = 'Next collection',
    this.myTurnTemplate = 'Your turn: {month} ({n} of {total})',
    this.paidTemplate = '{paid} of {total} paid',
    this.cycleTemplate = 'Cycle {n} of {total}',
    this.meLabel = 'You',
    this.dueLabel = 'Due',
    this.remindLabel = 'Send reminder',
    this.viewDetailsLabel = 'View details',
    this.completedLabel = 'Circle complete. Every member has received '
        'the pot.',
    this.semanticLabel,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.shadow,
    this.border,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.header,
    this.footer,
    this.collectionDateIcon,
    this.paidBadgeIcon,
    this.completedIcon,
    this.avatarSize,
    this.maxVisibleMembers,
    this.memberOverflowTemplate = '+{n}',
  });

  /// Display name of the circle.
  final String name;

  /// Fixed contribution each member pays per cycle.
  final Money contribution;

  /// All circle members. Rendered in [BankCircleMember.turnIndex] order.
  final List<BankCircleMember> members;

  /// 1-based index of the cycle currently being collected.
  ///
  /// A value greater than [totalCycles] marks the circle as complete.
  final int currentCycle;

  /// Total number of cycles (normally the member count).
  final int totalCycles;

  /// Date the current cycle's pot is collected.
  final DateTime nextCollectionDate;

  /// Whether the admin view is shown: unpaid members get a quiet
  /// warning tint and [onRemind] becomes available. Defaults to false.
  final bool isAdminView;

  /// Called when the admin taps the reminder action. Only rendered
  /// when [isAdminView] is true and the circle is not complete.
  final VoidCallback? onRemind;

  /// Called when the user taps the view-details action.
  final VoidCallback? onViewDetails;

  /// Label above the hero pot amount. Defaults to 'Pot per cycle'.
  final String potPerCycleLabel;

  /// Label for the per-member contribution row. Defaults to
  /// 'Monthly contribution'.
  final String monthlyContributionLabel;

  /// Label for the next collection date row. Defaults to
  /// 'Next collection'.
  final String nextCollectionLabel;

  /// Template for the signed-in user's turn line. `{month}`, `{n}`,
  /// and `{total}` are substituted. Defaults to
  /// 'Your turn: {month} ({n} of {total})'.
  final String myTurnTemplate;

  /// Template for the payment status strip. `{paid}` and `{total}`
  /// are substituted. Defaults to '{paid} of {total} paid'.
  final String paidTemplate;

  /// Template for the cycle chip. `{n}` and `{total}` are substituted.
  /// Defaults to 'Cycle {n} of {total}'.
  final String cycleTemplate;

  /// Chip label under the signed-in user's avatar. Defaults to 'You'.
  final String meLabel;

  /// Label inside the due pill shown while the user's contribution is
  /// still owed this cycle. Defaults to 'Due'.
  final String dueLabel;

  /// Label of the admin reminder action. Defaults to 'Send reminder'.
  final String remindLabel;

  /// Label of the view-details action. Defaults to 'View details'.
  final String viewDetailsLabel;

  /// Celebratory line shown when the circle is complete.
  final String completedLabel;

  /// Overrides the merged semantics summary (name, pot, turn, next
  /// collection). Defaults to a label built from the resolved strings.
  final String? semanticLabel;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the accent used for the current-turn ring, cycle chip,
  /// me chip, my-turn line, and progress bar. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten the card.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Merged over the computed circle-name style
  /// ([BankTokens.headlineSmall] in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed supporting-label style
  /// ([BankTokens.bodySmall] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the computed hero pot amount style
  /// ([BankThemeData.numeralLarge] in onSurface).
  final TextStyle? amountStyle;

  /// Optional slot rendered above the card content.
  final Widget? header;

  /// Optional slot rendered below the card content.
  final Widget? footer;

  /// Icon beside the next collection date. Defaults to
  /// [BankIcons.calendar].
  final IconData? collectionDateIcon;

  /// Icon inside the paid check badge on past turns. Defaults to a
  /// plain check mark.
  final IconData? paidBadgeIcon;

  /// Icon beside the completed line. Defaults to a celebration glyph.
  final IconData? completedIcon;

  /// Avatar diameter in the turn tracker. Defaults to
  /// [BankEmblemSize.medium].
  final double? avatarSize;

  /// Caps how many member avatars the turn tracker draws before folding the
  /// rest into a `+N` overflow disc.
  ///
  /// `null` (the default) means "as many as fit the card": the tracker
  /// measures its own width and folds the remainder. It never scrolls and
  /// never runs off the edge, which is what used to swallow the seventh
  /// member of a circle without leaving a trace that they existed.
  final int? maxVisibleMembers;

  /// Template for the tracker's overflow disc; `{n}` is substituted.
  /// Defaults to '+{n}'.
  final String memberOverflowTemplate;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final numerals = scope.numeralStyle;

    final completed = currentCycle > totalCycles;
    final memberCount = members.length;

    final pot = Money(
      amount: contribution.amount * Decimal.fromInt(memberCount),
      currencyCode: contribution.currencyCode,
    );

    BankCircleMember? me;
    for (final member in members) {
      if (member.isMe) {
        me = member;
        break;
      }
    }

    final paidCount = members.where((member) => member.paidThisCycle).length;
    final paidFraction = memberCount == 0 ? 0.0 : paidCount / memberCount;

    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);
    final resolvedRadius = radius ?? theme.cardRadius;
    final resolvedBackground = backgroundColor ?? theme.surface;
    final resolvedAccent = accentColor ?? theme.primary;
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
    );

    final resolvedTitleStyle = BankTokens.headlineSmall
        .copyWith(color: theme.onSurface)
        .merge(titleStyle);
    final resolvedSubtitleStyle = BankTokens.bodySmall
        .copyWith(color: theme.onSurfaceVariant)
        .merge(subtitleStyle);
    final resolvedAmountStyle = amountStyle == null
        ? null
        : theme.numeralLarge
            .copyWith(color: theme.onSurface)
            .merge(amountStyle);

    final nextCollectionText = numerals.convert(
      BankDateFormatter.formatShort(
        nextCollectionDate,
        locale: context.bankLocale,
      ),
    );

    String? cycleText;
    if (!completed) {
      cycleText = numerals.convert(
        cycleTemplate
            .replaceAll('{n}', '$currentCycle')
            .replaceAll('{total}', '$totalCycles'),
      );
    }

    String? myTurnText;
    if (me != null && !completed) {
      final turnMonth = DateTime(
        nextCollectionDate.year,
        nextCollectionDate.month + (me.turnIndex - currentCycle),
      );
      myTurnText = numerals.convert(
        myTurnTemplate
            .replaceAll(
              '{month}',
              BankDateFormatter.patternFormat(
                'MMMM',
                locale: context.bankLocale,
              ).format(turnMonth),
            )
            .replaceAll('{n}', '${me.turnIndex}')
            .replaceAll('{total}', '$totalCycles'),
      );
    }

    final paidText = numerals.convert(
      paidTemplate
          .replaceAll('{paid}', '$paidCount')
          .replaceAll('{total}', '$memberCount'),
    );

    final potForSemantics = scope.privacyEnabled
        ? scope.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: pot.amount,
            currencyCode: pot.currencyCode,
            numeralStyle: numerals,
          );

    final summary = semanticLabel ??
        <String>[
          name,
          '$potPerCycleLabel: $potForSemantics',
          if (completed)
            completedLabel
          else
            '$nextCollectionLabel: $nextCollectionText',
          if (myTurnText != null) myTurnText,
        ].join(', ');

    final showDuePill = !completed && me != null && !me.paidThisCycle;
    final showRemind = isAdminView && onRemind != null && !completed;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: resolvedTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (cycleText != null) ...[
              const SizedBox(width: BankTokens.space2),
              BankTintChip(label: cycleText, color: resolvedAccent),
            ],
          ],
        ),
        const SizedBox(height: BankTokens.space3),
        Text(potPerCycleLabel, style: resolvedSubtitleStyle),
        const SizedBox(height: BankTokens.space1),
        BankBalanceText(money: pot, style: resolvedAmountStyle),
        const SizedBox(height: BankTokens.space2),
        Row(
          children: [
            Expanded(
              child: Text(
                monthlyContributionLabel,
                style: resolvedSubtitleStyle,
              ),
            ),
            BankBalanceText(
              money: contribution,
              size: BankBalanceSize.small,
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        _CircleTurnTracker(
          members: members,
          currentCycle: currentCycle,
          accent: resolvedAccent,
          isAdminView: isAdminView,
          meLabel: meLabel,
          avatarSize: avatarSize ?? BankEmblemSize.medium.diameter,
          maxVisible: maxVisibleMembers,
          overflowTemplate: memberOverflowTemplate,
          paidBadgeIcon: paidBadgeIcon,
        ),
        const SizedBox(height: BankTokens.space4),
        if (completed)
          Row(
            children: [
              Icon(
                completedIcon ?? Icons.celebration_outlined,
                size: BankTokens.iconMedium,
                color: theme.positiveBalance,
              ),
              const SizedBox(width: BankTokens.space2),
              Expanded(
                child: Text(
                  completedLabel,
                  style: BankTokens.labelMedium
                      .copyWith(color: theme.positiveBalance),
                ),
              ),
            ],
          )
        else ...[
          Row(
            children: [
              Icon(
                collectionDateIcon ?? BankIcons.calendar,
                size: BankTokens.iconSmall,
                color: theme.onSurfaceVariant,
              ),
              const SizedBox(width: BankTokens.space2),
              Text('$nextCollectionLabel: ', style: resolvedSubtitleStyle),
              Expanded(
                child: Text(
                  nextCollectionText,
                  style:
                      BankTokens.labelMedium.copyWith(color: theme.onSurface),
                ),
              ),
            ],
          ),
          if (myTurnText != null) ...[
            const SizedBox(height: BankTokens.space2),
            Text(
              myTurnText,
              style: BankTokens.labelMedium.copyWith(color: resolvedAccent),
            ),
          ],
          if (showDuePill) ...[
            const SizedBox(height: BankTokens.space3),
            _DuePill(label: dueLabel, amount: contribution),
          ],
          const SizedBox(height: BankTokens.space4),
          Text(paidText, style: resolvedSubtitleStyle),
          const SizedBox(height: BankTokens.space2),
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(BankTokens.radiusSmall),
            ),
            child: LinearProgressIndicator(
              value: paidFraction,
              minHeight: BankTokens.space1,
              backgroundColor:
                  theme.outline.withValues(alpha: BankTokens.alphaStrong),
              valueColor: AlwaysStoppedAnimation<Color>(resolvedAccent),
            ),
          ),
        ],
      ],
    );

    final actions = <Widget>[
      if (showRemind)
        Expanded(
          child: SizedBox(
            height: BankTokens.minTapTarget,
            child: OutlinedButton(
              onPressed: onRemind,
              child: Text(remindLabel),
            ),
          ),
        ),
      if (showRemind && onViewDetails != null)
        const SizedBox(width: BankTokens.space3),
      if (onViewDetails != null)
        Expanded(
          child: SizedBox(
            height: BankTokens.minTapTarget,
            child: TextButton(
              onPressed: onViewDetails,
              child: Text(viewDetailsLabel),
            ),
          ),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: resolvedRadius,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: BankTokens.space3),
            ],
            Semantics(
              container: true,
              label: summary,
              excludeSemantics: true,
              child: info,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: BankTokens.space3),
              Row(children: actions),
            ],
            if (footer != null) ...[
              const SizedBox(height: BankTokens.space3),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal avatar rail of members in turn order.
///
/// Past turns are dimmed and badged with a check; the current turn is
/// ringed in the accent colour; the signed-in user is labelled with a
/// chip. In admin view, members who have not paid this cycle receive
/// a quiet ring in [BankThemeData.pending].
///
/// The rail is width-bounded rather than scrollable: it measures the space it
/// was given, draws as many turns as fit, and folds the rest into a `+N`
/// overflow disc. A silently scrolling rail hid later members behind a gesture
/// nobody knew to make — a circle's *last* turn is exactly the one a member
/// wants to find. Because every item is [BankEmblem]-sized from the identity
/// ladder, and a ring is inset rather than added around the disc, each slot is
/// exactly one avatar wide whatever state it is in.
///
/// This is not a [BankEmblemStack] because each turn carries a caption below
/// it (the "You" chip); the stack is the uncaptioned, overlapping form of the
/// same vocabulary.
class _CircleTurnTracker extends StatelessWidget {
  const _CircleTurnTracker({
    required this.members,
    required this.currentCycle,
    required this.accent,
    required this.isAdminView,
    required this.meLabel,
    required this.avatarSize,
    required this.overflowTemplate,
    this.maxVisible,
    this.paidBadgeIcon,
  });

  final List<BankCircleMember> members;
  final int currentCycle;
  final Color accent;
  final bool isAdminView;
  final String meLabel;
  final double avatarSize;
  final int? maxVisible;
  final String overflowTemplate;
  final IconData? paidBadgeIcon;

  /// Gap between two turn slots.
  static const double _gap = BankTokens.space3;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final ordered = [...members]
      ..sort((a, b) => a.turnIndex.compareTo(b.turnIndex));

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = avatarSize + _gap;
        final fits = constraints.maxWidth.isFinite
            ? ((constraints.maxWidth + _gap) / slot).floor()
            : ordered.length;
        var capacity = fits < 1 ? 1 : fits;
        final cap = maxVisible;
        if (cap != null && cap < capacity) capacity = cap;

        final int visible;
        if (ordered.length <= capacity) {
          visible = ordered.length;
        } else {
          // One slot goes to the overflow disc.
          visible = capacity - 1 < 0 ? 0 : capacity - 1;
        }
        final hidden = ordered.length - visible;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _TurnAvatar(
                member: ordered[i],
                currentCycle: currentCycle,
                accent: accent,
                isAdminView: isAdminView,
                meLabel: meLabel,
                size: avatarSize,
                paidBadgeIcon: paidBadgeIcon,
              ),
            ],
            if (hidden > 0) ...[
              if (visible > 0) const SizedBox(width: _gap),
              BankEmblem(
                label: overflowTemplate.replaceAll('{n}', '$hidden'),
                size: avatarSize,
                tintColor: theme.onSurfaceVariant,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// One avatar in the turn tracker, with turn-state decorations.
class _TurnAvatar extends StatelessWidget {
  const _TurnAvatar({
    required this.member,
    required this.currentCycle,
    required this.accent,
    required this.isAdminView,
    required this.meLabel,
    required this.size,
    this.paidBadgeIcon,
  });

  final BankCircleMember member;
  final int currentCycle;
  final Color accent;
  final bool isAdminView;
  final String meLabel;
  final double size;
  final IconData? paidBadgeIcon;

  /// A collected turn is history, not a disabled control: it recedes but
  /// stays readable.
  static const double _spentTurnOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final past = member.turnIndex < currentCycle;
    final current = member.turnIndex == currentCycle;

    BankEmblemRing? ring;
    if (current) {
      ring = BankEmblemRing(color: accent);
    } else if (isAdminView && !member.paidThisCycle) {
      ring = BankEmblemRing(color: theme.pending);
    }

    Widget emblem = BankEmblem(
      imageUrl: member.avatarUrl,
      initialsFrom: member.name,
      size: size,
      ring: ring,
      badgeOverlay:
          past ? _PaidBadge(surface: theme.surface, icon: paidBadgeIcon) : null,
    );

    if (past) {
      emblem = Opacity(opacity: _spentTurnOpacity, child: emblem);
    }

    if (!member.isMe) return SizedBox(width: size, child: emblem);

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblem,
          const SizedBox(height: BankTokens.space1),
          BankTintChip(label: meLabel, color: accent),
        ],
      ),
    );
  }
}

/// Small check badge marking a completed turn, in the theme's own positive
/// colour so it stays AA in dark mode.
class _PaidBadge extends StatelessWidget {
  const _PaidBadge({
    required this.surface,
    this.icon,
  });

  final Color surface;
  final IconData? icon;

  /// The check glyph inside the bubble. Off the icon ladder on purpose: this
  /// is a mark stamped inside a 16 px disc that already spends 4 px on its
  /// surface ring, not an icon in its own right.
  static const double _glyphSize = 10;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final fill = theme.positiveBalance;
    // A solid fill, so the check takes a plain black/white ink rather than
    // the tinted-container ink: the dark-mode positive green is light enough
    // that a white check on it falls under AA.
    final ink = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? BankTokens.neutral0
        : BankTokens.neutral950;
    return Container(
      width: BankTokens.iconSmall,
      height: BankTokens.iconSmall,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: surface,
          width: BankTokens.hairlineWidth * 2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon ?? Icons.check, size: _glyphSize, color: ink),
    );
  }
}

/// Pending-tinted chip showing the user's outstanding contribution.
class _DuePill extends StatelessWidget {
  const _DuePill({
    required this.label,
    required this.amount,
  });

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final ink = BankTintChip.inkFor(theme, theme.pending);
    return BankTintChip(
      color: theme.pending,
      semanticLabel: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: BankTokens.caption.copyWith(color: ink),
          ),
          BankBalanceText(
            money: amount,
            style: theme.numeralSmall.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}
