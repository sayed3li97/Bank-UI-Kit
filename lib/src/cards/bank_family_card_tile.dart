import 'package:flutter/material.dart';

import '../../src/common/bank_emblem.dart';
import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/numeral_style.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankFamilyMemberCard model
// ---------------------------------------------------------------------------

/// Immutable description of a dependent (child or teen) card member as
/// rendered by [BankFamilyCardTile].
///
/// Instances are value objects: two members with identical fields compare
/// equal, which lets list diffing and rebuild checks work cheaply.
@immutable
class BankFamilyMemberCard {
  const BankFamilyMemberCard({
    required this.id,
    required this.memberName,
    required this.cardLast4,
    required this.spendLimit,
    required this.spentThisPeriod,
    this.age,
    this.frozen = false,
    this.notificationsOnSpend = false,
  });

  /// Unique identifier of the family member.
  final String id;

  /// Display name of the member, also used for the emblem initials.
  final String memberName;

  /// Age shown in a small chip next to the name. Hidden when `null`.
  final int? age;

  /// Last four digits of the member's card number.
  final String cardLast4;

  /// Spending cap for the current period.
  final Money spendLimit;

  /// Amount already spent in the current period.
  final Money spentThisPeriod;

  /// Whether the member's card is currently frozen.
  final bool frozen;

  /// Whether the guardian is notified on every spend from this card.
  final bool notificationsOnSpend;

  /// Returns a copy with the given fields replaced.
  ///
  /// [age] cannot be cleared back to `null` through this method; construct
  /// a new [BankFamilyMemberCard] instead.
  BankFamilyMemberCard copyWith({
    String? id,
    String? memberName,
    int? age,
    String? cardLast4,
    Money? spendLimit,
    Money? spentThisPeriod,
    bool? frozen,
    bool? notificationsOnSpend,
  }) =>
      BankFamilyMemberCard(
        id: id ?? this.id,
        memberName: memberName ?? this.memberName,
        cardLast4: cardLast4 ?? this.cardLast4,
        spendLimit: spendLimit ?? this.spendLimit,
        spentThisPeriod: spentThisPeriod ?? this.spentThisPeriod,
        age: age ?? this.age,
        frozen: frozen ?? this.frozen,
        notificationsOnSpend: notificationsOnSpend ?? this.notificationsOnSpend,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankFamilyMemberCard &&
        other.id == id &&
        other.memberName == memberName &&
        other.age == age &&
        other.cardLast4 == cardLast4 &&
        other.spendLimit == spendLimit &&
        other.spentThisPeriod == spentThisPeriod &&
        other.frozen == frozen &&
        other.notificationsOnSpend == notificationsOnSpend;
  }

  @override
  int get hashCode => Object.hash(
        id,
        memberName,
        age,
        cardLast4,
        spendLimit,
        spentThisPeriod,
        frozen,
        notificationsOnSpend,
      );
}

// ---------------------------------------------------------------------------
// BankFamilyCardTile
// ---------------------------------------------------------------------------

/// Management row for a dependent or teen card, one per family member.
///
/// Use it in a family or dependents section of a card-management screen,
/// one tile per [BankFamilyMemberCard]. Each tile (72 px minimum height)
/// shows a [BankEmblem] with the member's initials, the member's name with
/// an optional age chip, the card's last four digits, a thin spent/limit
/// progress bar (switching to [BankTokens.warning] above 80 percent), and
/// a caption built from [limitTemplate].
///
/// The trailing freeze [Switch] drives [onFreezeToggle] and shows an
/// inline progress indicator while the returned future is pending; the
/// resolved value becomes the displayed frozen state, so a backend that
/// rejects the change simply resolves with the previous value. While
/// frozen, the row content dims and a frost chip appears next to the
/// name, matching the frozen treatment used across the kit.
///
/// [onTap] makes the whole row tappable and adds a trailing chevron,
/// typically opening the full card controls. [onLimits] adds a
/// "Set limits" [TextButton] under the progress bar.
///
/// Monetary amounts respect privacy mode: when
/// [BankUiScopeData.privacyEnabled] is `true`, both amounts in the
/// [limitTemplate] caption are replaced with the scope's hidden-balance
/// placeholder.
///
/// ```dart
/// BankFamilyCardTile(
///   member: member,
///   onFreezeToggle: (frozen) =>
///       cardApi.setFrozen(member.id, frozen: frozen),
///   onTap: () => openCardControls(member),
///   onLimits: () => openSpendLimits(member),
/// )
/// ```
class BankFamilyCardTile extends StatefulWidget {
  const BankFamilyCardTile({
    required this.member,
    required this.onFreezeToggle,
    super.key,
    this.onTap,
    this.onLimits,
    this.limitTemplate = '{spent} of {limit} this month',
    this.setLimitsLabel = 'Set limits',
    this.freezeSwitchLabel = 'Freeze card',
    this.cardNumberPrefix = '•• ',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.frozenChipBackgroundColor,
    this.frozenChipForegroundColor,
    this.titleStyle,
    this.subtitleStyle,
    this.freezeChipIcon,
    this.notificationIcon,
    this.chevronIcon,
    this.leading,
    this.semanticLabel,
    this.minHeight,
    this.animationDuration,
    this.animationCurve,
  });

  /// The family member whose card this tile manages.
  final BankFamilyMemberCard member;

  /// Called when the freeze switch is toggled with the requested state.
  ///
  /// The future's value is the state to display once the operation
  /// completes; resolve with the previous state to signal a rejected
  /// change. If the future throws, the tile reverts to the previous
  /// state.
  final Future<bool> Function(bool frozen) onFreezeToggle;

  /// Makes the row tappable (e.g. to open full card controls) and shows
  /// a trailing chevron. No chevron is rendered when `null`.
  final VoidCallback? onTap;

  /// When non-null, a "Set limits" [TextButton] appears under the
  /// progress bar and invokes this callback.
  final VoidCallback? onLimits;

  /// Template for the caption under the progress bar. The `{spent}` and
  /// `{limit}` placeholders are replaced with formatted amounts.
  final String limitTemplate;

  /// Label of the [TextButton] shown when [onLimits] is provided.
  final String setLimitsLabel;

  /// Semantics label for the trailing freeze [Switch].
  final String freezeSwitchLabel;

  /// Prefix rendered before the card's last four digits. Defaults to
  /// `'•• '`.
  final String cardNumberPrefix;

  /// Overrides the tile's content padding. Defaults to
  /// [BankTokens.space4] horizontal by [BankTokens.space3] vertical.
  final EdgeInsetsGeometry? padding;

  /// Overrides the ink splash radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the tile background color. Defaults to transparent.
  final Color? backgroundColor;

  /// Overrides the accent used by the progress bar, freeze switch,
  /// pending spinner, and "Set limits" button. Defaults to the theme
  /// primary color.
  final Color? accentColor;

  /// Overrides the frost chip background. Defaults to the kit's
  /// ice-blue `Color(0xFFB3E5FC)`.
  final Color? frozenChipBackgroundColor;

  /// Overrides the frost chip text and icon color. Defaults to
  /// `Color(0xFF333333)`.
  final Color? frozenChipForegroundColor;

  /// Merged over the member name style ([BankTokens.labelLarge] in the
  /// theme onSurface color), so partial overrides work.
  final TextStyle? titleStyle;

  /// Merged over the card number and limit caption style
  /// ([BankTokens.bodySmall] in the theme onSurfaceVariant color).
  final TextStyle? subtitleStyle;

  /// Overrides the frost chip glyph. Defaults to [BankIcons.cardFreeze].
  final IconData? freezeChipIcon;

  /// Overrides the spend notification glyph next to the card number.
  /// Defaults to [BankIcons.notification].
  final IconData? notificationIcon;

  /// Overrides the trailing chevron shown when [onTap] is set. Defaults
  /// to [BankIcons.forward].
  final IconData? chevronIcon;

  /// Replaces the leading emblem. Defaults to a 44 px [BankEmblem] with
  /// the member's initials.
  final Widget? leading;

  /// Semantics label for the whole tile. Defaults to none, letting the
  /// child semantics describe the row.
  final String? semanticLabel;

  /// Overrides the tile's minimum height. Defaults to 72.
  final double? minHeight;

  /// Overrides the pending/switch cross-fade duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the pending/switch cross-fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  @override
  State<BankFamilyCardTile> createState() => _BankFamilyCardTileState();
}

class _BankFamilyCardTileState extends State<BankFamilyCardTile> {
  /// Whether a freeze toggle request is currently in flight.
  bool _pending = false;

  /// Local frozen state resolved from [BankFamilyCardTile.onFreezeToggle],
  /// overriding the model until the parent rebuilds with fresh data.
  bool? _frozenOverride;

  bool get _frozen => _frozenOverride ?? widget.member.frozen;

  @override
  void didUpdateWidget(BankFamilyCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member.id != oldWidget.member.id ||
        widget.member.frozen != oldWidget.member.frozen) {
      _frozenOverride = null;
    }
  }

  Future<void> _toggleFreeze(bool next) async {
    setState(() => _pending = true);
    var resolved = _frozen;
    try {
      resolved = await widget.onFreezeToggle(next);
    } on Exception {
      // Keep the previous state when the toggle fails.
    }
    if (!mounted) return;
    setState(() {
      _pending = false;
      _frozenOverride = resolved;
    });
  }

  String _formatAmount(BankUiScopeData scope, Money money) =>
      scope.privacyEnabled
          ? scope.strings.balanceHidden
          : BankMoneyFormatter.format(
              amount: money.amount,
              currencyCode: money.currencyCode,
              numeralStyle: scope.numeralStyle,
            );

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final member = widget.member;
    final frozen = _frozen;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final resolvedAccentColor = widget.accentColor ?? theme.primary;
    final resolvedTitleStyle = BankTokens.labelLarge
        .copyWith(color: theme.onSurface)
        .merge(widget.titleStyle);
    final resolvedSubtitleStyle = BankTokens.bodySmall
        .copyWith(color: theme.onSurfaceVariant)
        .merge(widget.subtitleStyle);
    final resolvedDuration =
        widget.animationDuration ?? BankTokens.durationFast;
    final resolvedCurve = widget.animationCurve ?? BankTokens.curveStandard;

    // ── Spent / limit progress ────────────────────────────────────────────
    final limitAmount = member.spendLimit.amount.toDouble();
    final spentAmount = member.spentThisPeriod.amount.toDouble();
    var ratio = 0.0;
    if (limitAmount > 0) {
      ratio = (spentAmount / limitAmount).clamp(0, 1).toDouble();
    }
    final barColor = ratio > 0.8 ? BankTokens.warning : resolvedAccentColor;

    final limitLine = widget.limitTemplate
        .replaceAll('{spent}', _formatAmount(scope, member.spentThisPeriod))
        .replaceAll('{limit}', _formatAmount(scope, member.spendLimit));

    // ── Name row: name + optional age chip + frost chip when frozen ──────
    final nameRow = Row(
      children: [
        Flexible(
          child: Text(
            member.memberName,
            style: resolvedTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (member.age != null) ...[
          const SizedBox(width: BankTokens.space2),
          _MiniChip(
            label: scope.numeralStyle.convert('${member.age}'),
            background: theme.surfaceVariant,
            foreground: theme.onSurfaceVariant,
            chipRadius: theme.chipRadius,
          ),
        ],
        if (frozen) ...[
          const SizedBox(width: BankTokens.space2),
          _MiniChip(
            label: scope.strings.frozen,
            // Ice-blue frost chip, matching the kit's frozen-account chip.
            background:
                widget.frozenChipBackgroundColor ?? const Color(0xFFB3E5FC),
            foreground:
                widget.frozenChipForegroundColor ?? const Color(0xFF333333),
            chipRadius: theme.chipRadius,
            icon: widget.freezeChipIcon ?? BankIcons.cardFreeze,
          ),
        ],
      ],
    );

    // ── Card number line ──────────────────────────────────────────────────
    final cardLine = Row(
      children: [
        Text(
          '${widget.cardNumberPrefix}${member.cardLast4}',
          style: resolvedSubtitleStyle,
          // Masked card digits always read left-to-right.
          textDirection: TextDirection.ltr,
        ),
        if (member.notificationsOnSpend) ...[
          const SizedBox(width: BankTokens.space1),
          Icon(
            widget.notificationIcon ?? BankIcons.notification,
            size: 14,
            color: theme.onSurfaceVariant,
          ),
        ],
      ],
    );

    // ── Details column ────────────────────────────────────────────────────
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        nameRow,
        const SizedBox(height: BankTokens.space1),
        cardLine,
        const SizedBox(height: BankTokens.space2),
        // The caption below carries the same information for screen
        // readers, so the bar itself is decorative.
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(BankTokens.radiusFull),
            ),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              color: barColor,
              backgroundColor: theme.surfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: BankTokens.space1),
        Text(
          limitLine,
          style: resolvedSubtitleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.onLimits != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: widget.onLimits,
              style: TextButton.styleFrom(
                foregroundColor: resolvedAccentColor,
                minimumSize: const Size(
                  BankTokens.minTapTarget,
                  BankTokens.minTapTarget,
                ),
                padding: EdgeInsets.zero,
                textStyle: BankTokens.labelMedium,
              ),
              child: Text(widget.setLimitsLabel),
            ),
          ),
      ],
    );

    // ── Leading emblem + details, dimmed while frozen ─────────────────────
    Widget body = Row(
      children: [
        widget.leading ?? BankEmblem(initialsFrom: member.memberName, size: 44),
        const SizedBox(width: BankTokens.space3),
        Expanded(child: details),
      ],
    );
    if (frozen) {
      body = Opacity(opacity: 0.55, child: body);
    }

    // ── Trailing freeze switch with async pending state ───────────────────
    Widget freezeControl = SizedBox(
      height: BankTokens.minTapTarget,
      child: Center(
        child: AnimatedSwitcher(
          duration: disableAnimations ? Duration.zero : resolvedDuration,
          switchInCurve: resolvedCurve,
          switchOutCurve: resolvedCurve,
          child: _pending
              ? SizedBox(
                  key: const ValueKey<String>('bank_family_card_pending'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: resolvedAccentColor,
                  ),
                )
              : Switch(
                  key: const ValueKey<String>('bank_family_card_switch'),
                  value: frozen,
                  onChanged: _toggleFreeze,
                  activeColor: resolvedAccentColor,
                ),
        ),
      ),
    );
    freezeControl = MergeSemantics(
      child: Semantics(
        label: widget.freezeSwitchLabel,
        child: freezeControl,
      ),
    );

    // ── Assembled row ─────────────────────────────────────────────────────
    final content = Row(
      children: [
        Expanded(child: body),
        const SizedBox(width: BankTokens.space3),
        freezeControl,
        if (widget.onTap != null) ...[
          const SizedBox(width: BankTokens.space1),
          Icon(
            widget.chevronIcon ?? BankIcons.forward,
            size: 20,
            color: theme.onSurfaceVariant,
          ),
        ],
      ],
    );

    final resolvedPadding = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Material(
        color: widget.backgroundColor ?? Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.radius ?? theme.cardRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight ?? 72),
            child: Padding(
              padding: resolvedPadding,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MiniChip: compact label chip used for age and frost states
// ---------------------------------------------------------------------------

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.chipRadius,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BorderRadius chipRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: foreground),
              const SizedBox(width: BankTokens.space1),
            ],
            Text(
              label,
              style: BankTokens.labelSmall.copyWith(color: foreground),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
