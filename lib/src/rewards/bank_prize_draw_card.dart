import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A single upcoming draw shown inside [BankPrizeDrawCard].
///
/// Describes one prize event of a prize-linked savings programme: what
/// can be won ([prizeLabel]), when the draw happens ([drawDate]), and
/// the deposit cutoff for entering it ([lastDepositDate]). Grand draws
/// ([isGrand]) receive an accent star badge in the list.
@immutable
class BankPrizeDraw {
  /// Stable identifier of the draw.
  final String id;

  /// User-facing prize description, e.g. `'USD 500,000'` or
  /// `'Porsche 911 Carrera S'`.
  final String prizeLabel;

  /// Date on which the draw takes place.
  final DateTime drawDate;

  /// Eligibility cutoff: deposits must land by this date to enter.
  final DateTime lastDepositDate;

  /// Whether this is a grand (headline) draw. Grand draws are marked
  /// with an accent star badge.
  final bool isGrand;

  /// Creates an immutable prize draw descriptor.
  const BankPrizeDraw({
    required this.id,
    required this.prizeLabel,
    required this.drawDate,
    required this.lastDepositDate,
    this.isGrand = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankPrizeDraw &&
        other.id == id &&
        other.prizeLabel == prizeLabel &&
        other.drawDate == drawDate &&
        other.lastDepositDate == lastDepositDate &&
        other.isGrand == isGrand;
  }

  @override
  int get hashCode =>
      Object.hash(id, prizeLabel, drawDate, lastDepositDate, isGrand);

  @override
  String toString() =>
      'BankPrizeDraw(id: $id, prizeLabel: $prizeLabel, isGrand: $isGrand)';
}

/// Card for a prize-linked savings account: deposit to earn draw
/// chances, win monthly prizes, gift entries to loved ones.
///
/// Equivalent surfaces in production apps: ila Bank Al Kanz and GCC
/// prize-linked savings programmes (Mahzooz, Mega, Al Rabeh).
///
/// The card shows the account balance (via [BankBalanceText], so it is
/// masked when privacy mode is active on the ambient [BankUiScope]), a
/// hero count of entries in the next draw, a static countdown to the
/// next draw (days when far, hours and minutes when close; recomputed
/// on each build, never ticking), the list of upcoming draws with
/// deposit cutoffs, an eligibility hint when the balance is below
/// [minDeposit], and Add money / Gift a chance / Past winners actions.
///
/// All colours, radii, spacing, and text styles come from
/// [BankThemeData] and [BankTokens]; every string and visual decision
/// is overridable through optional constructor parameters. Inject
/// [clock] for deterministic countdowns in tests and screenshots.
///
/// ```dart
/// BankPrizeDrawCard(
///   balance: Money.fromDouble(1250, 'BHD'),
///   entriesCount: 25,
///   draws: [
///     BankPrizeDraw(
///       id: 'grand',
///       prizeLabel: 'Porsche 911 Carrera S',
///       drawDate: DateTime(2026, 3, 10),
///       lastDepositDate: DateTime(2026, 3, 1),
///       isGrand: true,
///     ),
///     BankPrizeDraw(
///       id: 'may',
///       prizeLabel: 'USD 500,000',
///       drawDate: DateTime(2026, 5, 13),
///       lastDepositDate: DateTime(2026, 5, 1),
///     ),
///   ],
///   minDeposit: Money.fromDouble(50, 'BHD'),
///   onAddMoney: () => openTopUp(),
///   onSendGift: () => openGifting(),
///   onViewWinners: () => openWinners(),
/// )
/// ```
class BankPrizeDrawCard extends StatelessWidget {
  /// Balance of the prize-linked savings account. Rendered through
  /// [BankBalanceText], so it is masked in privacy mode.
  final Money balance;

  /// Number of chances (entries) held in the next draw, shown in hero
  /// numerals with [NumeralStyle]-aware digits.
  final int entriesCount;

  /// Upcoming draws. Sorted by [BankPrizeDraw.drawDate] for display;
  /// at most [visibleDraws] are listed. An empty list simply hides the
  /// list and the countdown.
  final List<BankPrizeDraw> draws;

  /// Card heading. Defaults to `'Prize draws'`.
  final String title;

  /// Label preceding the balance. Defaults to `'My balance'`.
  final String balanceLabel;

  /// Unit line under the entries hero numeral. Defaults to
  /// `'chances in the next draw'`.
  final String entriesLabel;

  /// Maximum number of upcoming draws listed. Defaults to 3.
  final int visibleDraws;

  /// Minimum deposit required to be eligible. When set and the balance
  /// amount is below it, an eligibility hint is shown.
  final Money? minDeposit;

  /// Template of the eligibility hint; `{amount}` is replaced with the
  /// formatted [minDeposit]. Defaults to
  /// `'Deposit at least {amount} to be eligible'`.
  final String minDepositTemplate;

  /// Template of each draw's cutoff line; `{date}` is replaced with
  /// the formatted [BankPrizeDraw.lastDepositDate]. Defaults to
  /// `'Deposit by {date} to enter'`.
  final String cutoffTemplate;

  /// Countdown template used when the next draw is a day or more away;
  /// `{days}` is replaced. Defaults to `'Draw in {days} days'`.
  final String countdownDaysTemplate;

  /// Countdown template used when the next draw is less than a day
  /// away; `{hours}` and `{minutes}` are replaced. Defaults to
  /// `'Draw in {hours}h {minutes}m'`.
  final String countdownHoursTemplate;

  /// Semantics label of the star badge on grand draws. Defaults to
  /// `'Grand draw'`.
  final String grandLabel;

  /// Called when the primary Add money button is tapped. When `null`,
  /// the button renders disabled.
  final VoidCallback? onAddMoney;

  /// Called when the Gift a chance button is tapped. When `null`, the
  /// button renders disabled.
  final VoidCallback? onSendGift;

  /// Called when the Past winners link is tapped. When `null`, the
  /// link renders disabled.
  final VoidCallback? onViewWinners;

  /// Label of the primary action. Defaults to `'Add money'`.
  final String addMoneyLabel;

  /// Label of the gifting action. Defaults to `'Gift a chance'`.
  final String sendGiftLabel;

  /// Label of the winners link. Defaults to `'Past winners'`.
  final String winnersLabel;

  /// Clock used for the countdown computation. Inject a fixed clock
  /// for deterministic screenshots. Defaults to [DateTime.now].
  final DateTime Function()? clock;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space5)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to the theme
  /// [BankThemeData.surface].
  final Color? backgroundColor;

  /// Accent for the star badge, countdown icon, and action buttons.
  /// Defaults to the theme [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten the card.
  final List<BoxShadow>? shadow;

  /// Merged over the computed heading style
  /// ([BankTokens.headlineSmall] in the surface colour).
  final TextStyle? titleStyle;

  /// Merged over the computed balance style (theme
  /// [BankThemeData.numeralMedium] in the surface colour).
  final TextStyle? amountStyle;

  /// Merged over the computed entries hero style (theme
  /// [BankThemeData.numeralHero] in the surface colour).
  final TextStyle? entriesStyle;

  /// Glyph of the grand-draw badge. Defaults to
  /// [BankIcons.watchlistFilled] (a filled star).
  final IconData? grandBadgeIcon;

  /// Optional slot rendered above the heading.
  final Widget? header;

  /// Optional slot rendered below the actions.
  final Widget? footer;

  /// Overrides the merged semantics summary of the card.
  final String? semanticLabel;

  /// Creates a prize-linked savings card.
  const BankPrizeDrawCard({
    required this.balance,
    required this.entriesCount,
    required this.draws,
    super.key,
    this.title = 'Prize draws',
    this.balanceLabel = 'My balance',
    this.entriesLabel = 'chances in the next draw',
    this.visibleDraws = 3,
    this.minDeposit,
    this.minDepositTemplate = 'Deposit at least {amount} to be eligible',
    this.cutoffTemplate = 'Deposit by {date} to enter',
    this.countdownDaysTemplate = 'Draw in {days} days',
    this.countdownHoursTemplate = 'Draw in {hours}h {minutes}m',
    this.grandLabel = 'Grand draw',
    this.onAddMoney,
    this.onSendGift,
    this.onViewWinners,
    this.addMoneyLabel = 'Add money',
    this.sendGiftLabel = 'Gift a chance',
    this.winnersLabel = 'Past winners',
    this.clock,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.shadow,
    this.titleStyle,
    this.amountStyle,
    this.entriesStyle,
    this.grandBadgeIcon,
    this.header,
    this.footer,
    this.semanticLabel,
  });

  List<BankPrizeDraw> get _sortedDraws {
    final sorted = List<BankPrizeDraw>.of(draws)
      ..sort((a, b) => a.drawDate.compareTo(b.drawDate));
    return sorted.take(visibleDraws).toList();
  }

  String? _countdownLabel(DateTime now, NumeralStyle numeralStyle) {
    BankPrizeDraw? next;
    for (final draw in draws) {
      if (!draw.drawDate.isAfter(now)) continue;
      if (next == null || draw.drawDate.isBefore(next.drawDate)) {
        next = draw;
      }
    }
    if (next == null) return null;

    final remaining = next.drawDate.difference(now);
    final String raw;
    if (remaining.inDays >= 1) {
      raw = countdownDaysTemplate.replaceFirst(
        '{days}',
        '${remaining.inDays}',
      );
    } else {
      raw = countdownHoursTemplate
          .replaceFirst('{hours}', '${remaining.inHours}')
          .replaceFirst('{minutes}', '${remaining.inMinutes % 60}');
    }
    return numeralStyle.convert(raw);
  }

  bool get _belowMinDeposit =>
      minDeposit != null && balance.amount < minDeposit!.amount;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final now = (clock ?? DateTime.now)();

    final accent = accentColor ?? theme.primary;
    final entriesText = scope.numeralStyle.convert(
      NumberFormat.decimalPattern().format(entriesCount),
    );
    final countdown = _countdownLabel(now, scope.numeralStyle);
    final visible = _sortedDraws;

    String? eligibilityHint;
    if (_belowMinDeposit) {
      final minAmount = BankMoneyFormatter.format(
        amount: minDeposit!.amount,
        currencyCode: minDeposit!.currencyCode,
        numeralStyle: scope.numeralStyle,
      );
      eligibilityHint = minDepositTemplate.replaceFirst('{amount}', minAmount);
    }

    final summary = semanticLabel ?? _summary(scope, entriesText, countdown);

    final resolvedTitleStyle = BankTokens.headlineSmall
        .copyWith(color: theme.onSurface)
        .merge(titleStyle);
    final resolvedAmountStyle =
        theme.numeralMedium.copyWith(color: theme.onSurface).merge(amountStyle);
    final resolvedEntriesStyle =
        theme.numeralHero.copyWith(color: theme.onSurface).merge(entriesStyle);

    return Semantics(
      container: true,
      label: summary,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.surface,
          borderRadius: radius ?? theme.cardRadius,
          boxShadow: shadow ?? BankTokens.shadowCard,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(BankTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: BankTokens.space3),
              ],
              ExcludeSemantics(
                child: Text(title, style: resolvedTitleStyle),
              ),
              const SizedBox(height: BankTokens.space3),
              ExcludeSemantics(
                child: _BalanceLine(
                  balance: balance,
                  balanceLabel: balanceLabel,
                  amountStyle: resolvedAmountStyle,
                ),
              ),
              const SizedBox(height: BankTokens.space4),
              ExcludeSemantics(
                child: Text(
                  entriesText,
                  style: resolvedEntriesStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: BankTokens.space1),
              ExcludeSemantics(
                child: Text(
                  entriesLabel,
                  style: BankTokens.bodyMedium
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ),
              if (countdown != null) ...[
                const SizedBox(height: BankTokens.space3),
                ExcludeSemantics(
                  child: _CountdownChip(label: countdown, accent: accent),
                ),
              ],
              if (eligibilityHint != null) ...[
                const SizedBox(height: BankTokens.space3),
                _EligibilityHint(message: eligibilityHint),
              ],
              if (visible.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space4),
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(height: BankTokens.space3),
                  _DrawRow(
                    draw: visible[i],
                    cutoffTemplate: cutoffTemplate,
                    grandLabel: grandLabel,
                    grandBadgeIcon: grandBadgeIcon ?? BankIcons.watchlistFilled,
                    accent: accent,
                    numeralStyle: scope.numeralStyle,
                  ),
                ],
              ],
              const SizedBox(height: BankTokens.space4),
              _buildActions(theme, accent),
              if (footer != null) ...[
                const SizedBox(height: BankTokens.space3),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _summary(
    BankUiScopeData scope,
    String entriesText,
    String? countdown,
  ) {
    final balanceText = scope.privacyEnabled
        ? scope.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: balance.amount,
            currencyCode: balance.currencyCode,
            numeralStyle: scope.numeralStyle,
          );
    final buffer = StringBuffer()
      ..write('$title. ')
      ..write('$balanceLabel: $balanceText. ')
      ..write('$entriesText $entriesLabel.');
    if (countdown != null) buffer.write(' $countdown.');
    return buffer.toString();
  }

  Widget _buildActions(BankThemeData theme, Color accent) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: radius == null ? theme.buttonRadius : radius!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: BankTokens.minTapTarget,
                child: FilledButton(
                  onPressed: onAddMoney,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: theme.onPrimary,
                    shape: buttonShape,
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(addMoneyLabel),
                ),
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: SizedBox(
                height: BankTokens.minTapTarget,
                child: OutlinedButton(
                  onPressed: onSendGift,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: theme.outline),
                    shape: buttonShape,
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(sendGiftLabel),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space1),
        SizedBox(
          height: BankTokens.minTapTarget,
          child: TextButton(
            onPressed: onViewWinners,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              shape: buttonShape,
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(winnersLabel),
          ),
        ),
      ],
    );
  }
}

/// Balance label + privacy-aware amount line.
class _BalanceLine extends StatelessWidget {
  final Money balance;
  final String balanceLabel;
  final TextStyle amountStyle;

  const _BalanceLine({
    required this.balance,
    required this.balanceLabel,
    required this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Wrap(
      spacing: BankTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          balanceLabel,
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        BankBalanceText(
          money: balance,
          size: BankBalanceSize.medium,
          style: amountStyle,
        ),
      ],
    );
  }
}

/// Static countdown chip (recomputed per build, no ticking animation).
class _CountdownChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _CountdownChip({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: BankTokens.space3,
          vertical: BankTokens.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(BankIcons.schedule, size: 16, color: accent),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                label,
                style: BankTokens.labelMedium.copyWith(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Warning-tinted eligibility hint shown below the entries hero.
class _EligibilityHint extends StatelessWidget {
  final String message;

  const _EligibilityHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              BankIcons.warning,
              size: 16,
              color: BankTokens.warning,
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                message,
                style:
                    BankTokens.labelMedium.copyWith(color: BankTokens.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One upcoming draw: optional grand badge, prize, cutoff, and date.
class _DrawRow extends StatelessWidget {
  final BankPrizeDraw draw;
  final String cutoffTemplate;
  final String grandLabel;
  final IconData grandBadgeIcon;
  final Color accent;
  final NumeralStyle numeralStyle;

  const _DrawRow({
    required this.draw,
    required this.cutoffTemplate,
    required this.grandLabel,
    required this.grandBadgeIcon,
    required this.accent,
    required this.numeralStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final drawDate = numeralStyle.convert(
      BankDateFormatter.formatShort(draw.drawDate),
    );
    final cutoff = cutoffTemplate.replaceFirst(
      '{date}',
      numeralStyle.convert(
        BankDateFormatter.formatShort(draw.lastDepositDate),
      ),
    );

    final label = draw.isGrand
        ? '$grandLabel. ${draw.prizeLabel}, $drawDate. $cutoff'
        : '${draw.prizeLabel}, $drawDate. $cutoff';

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (draw.isGrand) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space1),
                  child: Icon(grandBadgeIcon, size: 16, color: accent),
                ),
              ),
              const SizedBox(width: BankTokens.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    draw.prizeLabel,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BankTokens.space1),
                  Text(
                    cutoff,
                    style: BankTokens.bodySmall
                        .copyWith(color: theme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Text(
              drawDate,
              style: theme.numeralSmall.copyWith(color: theme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
