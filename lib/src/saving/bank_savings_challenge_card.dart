import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Gamified stepped savings challenge card (26-week or 52-week style).
///
/// Presents a savings challenge as a grid of stamp circles, one per step:
/// completed steps are filled with the brand colour and a check mark, the
/// current step pulses with an animated ring (static when the platform
/// requests reduced motion), and future steps are outlined. Below the grid
/// the card shows a "{completed} of {total}" progress line, the next
/// deposit amount (rendered with [BankBalanceText], so it masks in privacy
/// mode) with an optional due date, and an async deposit button with an
/// inline spinner and success check.
///
/// A flame streak chip appears next to the title while [streak] is greater
/// than zero. For long challenges the grid caps at 30 visible stamps and
/// appends a "+N more" tail chip.
///
/// Use it on a savings or goals screen wherever a recurring stepped
/// challenge (the classic 26-week saving challenge) needs a
/// glanceable, tappable summary.
///
/// ```dart
/// BankSavingsChallengeCard(
///   title: '52 week challenge',
///   totalSteps: 52,
///   completedSteps: 17,
///   nextDeposit: Money.fromDouble(18, 'USD'),
///   nextDepositDate: DateTime(2026, 7, 10),
///   streak: 17,
///   onDepositNow: () => api.deposit(challengeId),
///   onTap: () => openChallengeDetail(challengeId),
/// )
/// ```
class BankSavingsChallengeCard extends StatefulWidget {
  const BankSavingsChallengeCard({
    required this.title,
    required this.totalSteps,
    required this.completedSteps,
    required this.nextDeposit,
    super.key,
    this.nextDepositDate,
    this.streak = 0,
    this.onDepositNow,
    this.onTap,
    this.depositLabel = 'Deposit now',
    this.streakTemplate = '{n} week streak',
    this.progressTemplate = '{completed} of {total}',
    this.moreTemplate = '+{n} more',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.shadow,
    this.titleStyle,
    this.subtitleStyle,
    this.semanticLabel,
    this.checkIcon,
    this.streakIcon,
    this.scheduleIcon,
    this.animationDuration,
    this.stampSize,
  })  : assert(totalSteps > 0, 'totalSteps must be positive'),
        assert(
          completedSteps >= 0 && completedSteps <= totalSteps,
          'completedSteps must be between 0 and totalSteps',
        ),
        assert(streak >= 0, 'streak must not be negative');

  /// Challenge name, e.g. `'52 week challenge'`.
  final String title;

  /// Total number of deposits in the challenge.
  final int totalSteps;

  /// Deposits completed so far. Must be between 0 and [totalSteps].
  final int completedSteps;

  /// Amount of the next scheduled deposit.
  final Money nextDeposit;

  /// Due date of the next deposit; hidden when `null`.
  final DateTime? nextDepositDate;

  /// Consecutive on-time deposits. A flame chip renders when above zero.
  final int streak;

  /// Performs the next deposit; return `true` on success to show the
  /// inline success check. The button hides when `null`.
  final Future<bool> Function()? onDepositNow;

  /// Called when the card body is tapped.
  final VoidCallback? onTap;

  /// Label of the deposit button.
  final String depositLabel;

  /// Streak chip text; `{n}` is substituted with [streak].
  final String streakTemplate;

  /// Progress line text; `{completed}` and `{total}` are substituted.
  final String progressTemplate;

  /// Tail chip text for capped grids; `{n}` is substituted with the
  /// number of hidden stamps.
  final String moreTemplate;

  /// Overrides the card content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the stamp, ring, and deposit-button accent. Defaults
  /// to the theme primary colour.
  final Color? accentColor;

  /// Overrides the card shadow. Defaults to the theme glow when
  /// enabled, else [BankTokens.shadowCard]; pass `const []` to
  /// flatten.
  final List<BoxShadow>? shadow;

  /// Merged over the computed title style ([BankTokens.headlineSmall]
  /// in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed progress-line style
  /// ([BankTokens.labelMedium] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Overrides the card semantics. Defaults to a label built from the
  /// title, progress, and streak.
  final String? semanticLabel;

  /// Glyph for completed stamps and the deposit success state.
  /// Defaults to [Icons.check_rounded].
  final IconData? checkIcon;

  /// Overrides the streak chip glyph. Defaults to
  /// [Icons.local_fire_department_rounded].
  final IconData? streakIcon;

  /// Overrides the next-deposit row glyph. Defaults to
  /// [BankIcons.schedule].
  final IconData? scheduleIcon;

  /// Base duration of the current-stamp pulse (and, doubled, of the
  /// success hold). Defaults to [BankTokens.durationXSlow].
  final Duration? animationDuration;

  /// Diameter of each stamp circle. Defaults to 28.
  final double? stampSize;

  /// Maximum number of stamp circles rendered before the tail chip.
  static const int maxVisibleStamps = 30;

  @override
  State<BankSavingsChallengeCard> createState() =>
      _BankSavingsChallengeCardState();
}

enum _DepositPhase { idle, busy, success }

class _BankSavingsChallengeCardState extends State<BankSavingsChallengeCard>
    with SingleTickerProviderStateMixin {
  static const double _stampDiameter = 28;

  late final AnimationController _pulse;
  _DepositPhase _phase = _DepositPhase.idle;

  double get _stampSize => widget.stampSize ?? _stampDiameter;

  Duration get _pulseDuration =>
      widget.animationDuration ?? BankTokens.durationXSlow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );
  }

  @override
  void didUpdateWidget(BankSavingsChallengeCard old) {
    super.didUpdateWidget(old);
    if (old.animationDuration != widget.animationDuration) {
      _pulse.duration = _pulseDuration;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hasCurrentStamp = widget.completedSteps < widget.totalSteps &&
        widget.completedSteps < BankSavingsChallengeCard.maxVisibleStamps;
    if (reduceMotion || !hasCurrentStamp) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    setState(() => _phase = _DepositPhase.busy);
    var success = false;
    try {
      success = await widget.onDepositNow!();
    } on Object {
      // The host surfaces failures; the button simply re-enables.
    }
    if (!mounted) return;
    if (!success) {
      setState(() => _phase = _DepositPhase.idle);
      return;
    }
    setState(() => _phase = _DepositPhase.success);
    await Future<void>.delayed(_pulseDuration * 2);
    if (mounted) setState(() => _phase = _DepositPhase.idle);
  }

  String _fill(String template, Map<String, String> values) {
    var result = template;
    values.forEach((token, value) {
      result = result.replaceAll('{$token}', value);
    });
    return result;
  }

  Widget _stamp(BankThemeData theme, Color accent, int index) {
    final isCompleted = index < widget.completedSteps;
    final isCurrent = index == widget.completedSteps;

    if (isCompleted) {
      return Container(
        width: _stampSize,
        height: _stampSize,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.checkIcon ?? Icons.check_rounded,
          size: 16,
          color: theme.onPrimary,
        ),
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final glow = 0.35 + 0.65 * _pulse.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: glow),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25 * _pulse.value),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: SizedBox(
              width: _stampSize,
              height: _stampSize,
            ),
          );
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.outline),
      ),
      child: SizedBox(width: _stampSize, height: _stampSize),
    );
  }

  Widget _streakChip(BankThemeData theme) {
    final label = _fill(widget.streakTemplate, {'n': widget.streak.toString()});
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BankTokens.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1 / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.streakIcon ?? Icons.local_fire_department_rounded,
              size: 14,
              color: BankTokens.warning,
            ),
            const SizedBox(width: BankTokens.space1 / 2),
            Text(
              label,
              style: BankTokens.labelSmall.copyWith(color: BankTokens.warning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreChip(BankThemeData theme, int hidden) {
    final label = _fill(widget.moreTemplate, {'n': hidden.toString()});
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
      ),
      child: SizedBox(
        height: _stampSize,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space2,
          ),
          child: Center(
            child: Text(
              label,
              style:
                  BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  Widget _depositButton(BankThemeData theme, Color accent) {
    final busy = _phase == _DepositPhase.busy;
    final content = switch (_phase) {
      _DepositPhase.busy => SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.onPrimary,
          ),
        ),
      _DepositPhase.success => Icon(
          widget.checkIcon ?? Icons.check_rounded,
          size: 20,
          color: theme.onPrimary,
        ),
      _DepositPhase.idle => Text(widget.depositLabel),
    };

    return Semantics(
      button: true,
      enabled: !busy,
      label: widget.depositLabel,
      child: SizedBox(
        width: double.infinity,
        height: BankTokens.minTapTarget,
        child: FilledButton(
          onPressed: busy ? null : _handleDeposit,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: theme.onPrimary,
            disabledBackgroundColor: accent.withValues(alpha: 0.6),
            textStyle: BankTokens.labelLarge,
            shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          ),
          child: AnimatedSwitcher(
            duration: BankTokens.durationFast,
            switchInCurve: BankTokens.curveStandard,
            switchOutCurve: BankTokens.curveStandard,
            child: KeyedSubtree(
              key: ValueKey<_DepositPhase>(_phase),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final visibleStamps =
        widget.totalSteps.clamp(0, BankSavingsChallengeCard.maxVisibleStamps);
    final hiddenStamps = widget.totalSteps - visibleStamps;

    final progressLabel = _fill(widget.progressTemplate, {
      'completed': widget.completedSteps.toString(),
      'total': widget.totalSteps.toString(),
    });

    final streakLabel = widget.streak > 0
        ? _fill(widget.streakTemplate, {'n': widget.streak.toString()})
        : null;
    final semanticLabel = widget.semanticLabel ??
        [
          widget.title,
          progressLabel,
          if (streakLabel != null) streakLabel,
        ].join(', ');

    final accent = widget.accentColor ?? theme.primary;
    final resolvedPadding =
        widget.padding ?? const EdgeInsets.all(BankTokens.space4);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedBackground = widget.backgroundColor ?? theme.surface;
    final resolvedShadow = widget.shadow ??
        (theme.useGlow && theme.glowColor != null
            ? [
                BoxShadow(
                  color: theme.glowColor!.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : BankTokens.shadowCard);

    return Semantics(
      label: semanticLabel,
      button: widget.onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolvedBackground,
          borderRadius: resolvedRadius,
          boxShadow: resolvedShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: resolvedRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: resolvedRadius,
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: Padding(
              padding: resolvedPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + streak chip.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: BankTokens.headlineSmall
                              .copyWith(color: theme.onSurface)
                              .merge(widget.titleStyle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.streak > 0) ...[
                        const SizedBox(width: BankTokens.space2),
                        _streakChip(theme),
                      ],
                    ],
                  ),

                  const SizedBox(height: BankTokens.space4),

                  // Stamp grid.
                  ExcludeSemantics(
                    child: Wrap(
                      spacing: BankTokens.space2,
                      runSpacing: BankTokens.space2,
                      children: [
                        for (var i = 0; i < visibleStamps; i++)
                          _stamp(theme, accent, i),
                        if (hiddenStamps > 0) _moreChip(theme, hiddenStamps),
                      ],
                    ),
                  ),

                  const SizedBox(height: BankTokens.space3),

                  // Progress line.
                  ExcludeSemantics(
                    child: Text(
                      progressLabel,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(widget.subtitleStyle),
                    ),
                  ),

                  const SizedBox(height: BankTokens.space3),

                  // Next deposit row.
                  Row(
                    children: [
                      Icon(
                        widget.scheduleIcon ?? BankIcons.schedule,
                        size: 16,
                        color: theme.onSurfaceVariant,
                      ),
                      const SizedBox(width: BankTokens.space2),
                      BankBalanceText(
                        money: widget.nextDeposit,
                        size: BankBalanceSize.small,
                      ),
                      if (widget.nextDepositDate != null) ...[
                        const SizedBox(width: BankTokens.space2),
                        Flexible(
                          child: Text(
                            BankDateFormatter.formatShort(
                              widget.nextDepositDate!,
                            ),
                            style: BankTokens.bodySmall
                                .copyWith(color: theme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (widget.onDepositNow != null) ...[
                    const SizedBox(height: BankTokens.space4),
                    _depositButton(theme, accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
