import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/numeral_style.dart';
import '../../src/theme/tokens.dart';
import '../accounts/bank_balance_text.dart';

// ---------------------------------------------------------------------------
// Progress ring painter
// ---------------------------------------------------------------------------

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.gradient,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Gradient? gradient;
  final double strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw full background circle.
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc.
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (sweepAngle <= 0.0) return;

    if (gradient != null) {
      final gradientPaint = Paint()
        ..shader = gradient!.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, gradientPaint);
    } else {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.gradient != gradient ||
      old.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// Small badge chip
// ---------------------------------------------------------------------------

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: BankTokens.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rate badge helper
// ---------------------------------------------------------------------------

Widget _rateBadge(
  double rate,
  String suffix,
  String semanticsSuffix,
  NumeralStyle numeralStyle,
) {
  final pct = numeralStyle.convert(rate.toStringAsFixed(1));
  return Semantics(
    label: '$pct% $semanticsSuffix',
    child: _BadgeChip(label: '$pct% $suffix', color: BankTokens.success),
  );
}

// ---------------------------------------------------------------------------
// Main card widget
// ---------------------------------------------------------------------------

/// Goal-based sub-account card with progress ring, target, and optional badges.
///
/// Displays a [SavingsPot]'s name, current balance, target goal, progress
/// towards the target, interest rate badge (if applicable), own-account-number
/// badge, and a shared-pot indicator. Optional "Add" and "Withdraw" actions
/// appear in a bottom row when the respective callbacks are provided.
///
/// Supply [itemBuilder] to completely override the card's default content.
class BankSavingsPotCard extends StatelessWidget {
  /// The savings pot to display.
  final SavingsPot pot;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the user taps the "Add" action button.
  final VoidCallback? onAddMoney;

  /// Called when the user taps the "Withdraw" action button.
  final VoidCallback? onWithdraw;

  /// When non-null, completely overrides the card content. Receives the
  /// [BuildContext] and the [SavingsPot] and must return a widget tree that
  /// fills the card.
  final Widget Function(BuildContext, SavingsPot)? itemBuilder;

  /// Suffix on the rate badge in conventional mode. Defaults to 'AER'.
  final String rateSuffix;

  /// Suffix on the rate badge when `islamicFinanceMode` is on.
  /// Defaults to 'expected profit'.
  final String profitRateSuffix;

  /// Target line template; `{amount}` is substituted. Defaults to
  /// 'of {amount} goal'.
  final String goalTemplate;

  /// Caption of the own-account badge. Defaults to 'Own account'.
  final String ownAccountLabel;

  /// Shared badge template; `{n}` is substituted with the member
  /// count. Defaults to '{n} members'.
  final String membersTemplate;

  /// Caption of the add action. Defaults to 'Add'.
  final String addLabel;

  /// Caption of the withdraw action. Defaults to 'Withdraw'.
  final String withdrawLabel;

  /// Overrides the card-level semantics. Defaults to a label built
  /// from the pot name, amounts, and progress.
  final String? semanticLabel;

  /// Semantics of the own-account badge. Defaults to
  /// 'Has own account number'.
  final String ownAccountSemanticLabel;

  /// Shared badge semantics template; `{n}` is substituted. Defaults
  /// to 'Shared pot with {n} members'.
  final String sharedSemanticTemplate;

  /// Add action semantics template; `{pot}` is substituted. Defaults
  /// to 'Add money to {pot}'.
  final String addSemanticTemplate;

  /// Withdraw action semantics template; `{pot}` is substituted.
  /// Defaults to 'Withdraw from {pot}'.
  final String withdrawSemanticTemplate;

  /// Overrides the card content padding. Defaults to space4 all round.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme
  /// cardRadius.
  final BorderRadius? radius;

  /// Overrides the card fill colour. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the ring, balance, and add-action accent. Defaults to
  /// the theme primary colour.
  final Color? accentColor;

  /// Overrides the progress ring gradient. Defaults to the theme
  /// accentGradient.
  final Gradient? gradient;

  /// Overrides the card shadow. Defaults to the theme glow when
  /// enabled, else the resting card shadow for the ambient background
  /// brightness ([BankTokens.shadowCardFor]); pass `const []` to
  /// flatten.
  final List<BoxShadow>? shadow;

  /// Merged over the computed pot-name style ([BankTokens.labelLarge]
  /// in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the computed target-line style
  /// ([BankTokens.bodySmall] in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the computed balance numeral style.
  final TextStyle? amountStyle;

  /// Overrides the own-account badge glyph. Defaults to
  /// [BankIcons.account].
  final IconData? ownAccountIcon;

  /// Overrides the shared badge glyph. Defaults to
  /// [BankIcons.accountJoint].
  final IconData? sharedIcon;

  /// Overrides the add action glyph. Defaults to [BankIcons.add].
  final IconData? addIcon;

  /// Overrides the withdraw action glyph. Defaults to
  /// [BankIcons.receive].
  final IconData? withdrawIcon;

  /// Diameter of the progress ring. Defaults to 56.
  final double? ringSize;

  const BankSavingsPotCard({
    required this.pot,
    super.key,
    this.onTap,
    this.onAddMoney,
    this.onWithdraw,
    this.itemBuilder,
    this.rateSuffix = 'AER',
    this.profitRateSuffix = 'expected profit',
    this.goalTemplate = 'of {amount} goal',
    this.ownAccountLabel = 'Own account',
    this.membersTemplate = '{n} members',
    this.addLabel = 'Add',
    this.withdrawLabel = 'Withdraw',
    this.semanticLabel,
    this.ownAccountSemanticLabel = 'Has own account number',
    this.sharedSemanticTemplate = 'Shared pot with {n} members',
    this.addSemanticTemplate = 'Add money to {pot}',
    this.withdrawSemanticTemplate = 'Withdraw from {pot}',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.gradient,
    this.shadow,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.ownAccountIcon,
    this.sharedIcon,
    this.addIcon,
    this.withdrawIcon,
    this.ringSize,
  });

  // Diameter of the progress ring.
  static const double _ringDiameter = 56;

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return itemBuilder!(context, pot);
    }

    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    // Privacy mode masks both amounts: the current balance widget below
    // masks itself via BankBalanceText, and the target/semantics strings
    // substitute the scope's masked label.
    final hidden = scope.privacyEnabled;
    final formattedCurrent = hidden
        ? scope.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: pot.current.amount,
            currencyCode: pot.current.currencyCode,
            numeralStyle: scope.numeralStyle,
          );
    final formattedTarget = hidden
        ? scope.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: pot.target.amount,
            currencyCode: pot.target.currencyCode,
            numeralStyle: scope.numeralStyle,
          );

    final showActions = onAddMoney != null || onWithdraw != null;
    final isShared = pot.memberIds.length > 1;
    final resolvedSemanticLabel = semanticLabel ??
        'Pot: ${pot.name}, $formattedCurrent of $formattedTarget goal, '
            '${(pot.progressFraction * 100).round()}% complete';

    final accent = accentColor ?? bankTheme.primary;
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);
    final resolvedRadius = radius ?? bankTheme.cardRadius;
    final resolvedBackground = backgroundColor ?? bankTheme.surface;
    final resolvedRingSize = ringSize ?? _ringDiameter;
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(resolvedBackground);
    final backgroundBrightness =
        ThemeData.estimateBrightnessForColor(bankTheme.background);
    final resolvedShadow = shadow ??
        (bankTheme.useGlow && bankTheme.glowColor != null
            ? [
                BoxShadow(
                  color: bankTheme.glowColor!.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : BankTokens.shadowCardFor(backgroundBrightness));

    final Widget card = Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: resolvedRadius,
        boxShadow: resolvedShadow,
        // On dark flat surfaces a hairline separates the card from the
        // background where the shadow alone cannot; light surfaces
        // carry an invisible border of the same width so geometry stays
        // identical across brightness.
        border: Border.all(
          color: surfaceBrightness == Brightness.dark
              ? BankTokens.hairlineColor(bankTheme.onSurface, surfaceBrightness)
              : bankTheme.onSurface.withValues(alpha: 0),
          // Matches Border.all's default today; keep the token as the
          // source of truth for hairline geometry.
          // ignore: avoid_redundant_argument_values
          width: BankTokens.hairlineWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: resolvedRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedRadius,
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: Padding(
            padding: resolvedPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Centred within the card's minHeight so short cards have
              // no dead band beneath the content.
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Top row: ring + info ──────────────────────────────────
                Row(
                  children: [
                    // Progress ring
                    SizedBox(
                      width: resolvedRingSize,
                      height: resolvedRingSize,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: pot.progressFraction,
                          // Visible on-brand track: surfaceVariant on a
                          // surface card is invisible, so a partial ring
                          // read as a detached arc.
                          trackColor: bankTheme.onSurface.withValues(
                            alpha: surfaceBrightness == Brightness.dark
                                ? 0.16
                                : 0.10,
                          ),
                          progressColor: accent,
                          gradient: gradient ?? bankTheme.accentGradient,
                        ),
                        child: Center(
                          child: Text(
                            '${(pot.progressFraction * 100).round()}%',
                            style: BankTokens.labelSmall.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: BankTokens.space3),

                    // Pot info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pot name
                          Text(
                            pot.name,
                            style: BankTokens.labelLarge
                                .copyWith(color: bankTheme.onSurface)
                                .merge(titleStyle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Current balance
                          BankBalanceText(
                            money: pot.current,
                            size: BankBalanceSize.medium,
                            style: bankTheme.numeralMedium
                                .copyWith(color: accent)
                                .merge(amountStyle),
                          ),

                          const SizedBox(height: 2),

                          // Target label
                          Text(
                            goalTemplate.replaceAll(
                              '{amount}',
                              formattedTarget,
                            ),
                            style: BankTokens.bodySmall
                                .copyWith(color: bankTheme.onSurfaceVariant)
                                .merge(subtitleStyle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Badges row
                          if (pot.interestRate != null ||
                              pot.hasOwnAccountNumber ||
                              isShared) ...[
                            const SizedBox(height: BankTokens.space2),
                            Wrap(
                              spacing: BankTokens.space1,
                              runSpacing: BankTokens.space1,
                              children: [
                                if (pot.interestRate != null)
                                  _rateBadge(
                                    pot.interestRate!,
                                    scope.islamicFinanceMode
                                        ? profitRateSuffix
                                        : rateSuffix,
                                    scope.islamicFinanceMode
                                        ? profitRateSuffix
                                        : '$rateSuffix interest rate',
                                    scope.numeralStyle,
                                  ),
                                if (pot.hasOwnAccountNumber)
                                  Semantics(
                                    label: ownAccountSemanticLabel,
                                    child: _BadgeChip(
                                      label: ownAccountLabel,
                                      color: accent,
                                      icon: ownAccountIcon ?? BankIcons.account,
                                    ),
                                  ),
                                if (isShared)
                                  Semantics(
                                    label: sharedSemanticTemplate.replaceAll(
                                      '{n}',
                                      '${pot.memberIds.length}',
                                    ),
                                    child: _BadgeChip(
                                      label: membersTemplate.replaceAll(
                                        '{n}',
                                        '${pot.memberIds.length}',
                                      ),
                                      color: bankTheme.onSurfaceVariant,
                                      icon:
                                          sharedIcon ?? BankIcons.accountJoint,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Action row ────────────────────────────────────────────
                if (showActions) ...[
                  const SizedBox(height: BankTokens.space3),
                  const Divider(height: 1),
                  const SizedBox(height: BankTokens.space1),
                  Row(
                    children: [
                      if (onAddMoney != null)
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: addSemanticTemplate.replaceAll(
                              '{pot}',
                              pot.name,
                            ),
                            child: TextButton.icon(
                              onPressed: onAddMoney,
                              icon: Icon(
                                addIcon ?? BankIcons.add,
                                size: 18,
                                color: accent,
                              ),
                              label: Text(
                                addLabel,
                                style: BankTokens.labelMedium.copyWith(
                                  color: accent,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  BankTokens.minTapTarget,
                                  BankTokens.minTapTarget,
                                ),
                                foregroundColor: accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: bankTheme.buttonRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (onAddMoney != null && onWithdraw != null)
                        Container(
                          width: 1,
                          height: 20,
                          color: bankTheme.outline,
                        ),
                      if (onWithdraw != null)
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: withdrawSemanticTemplate.replaceAll(
                              '{pot}',
                              pot.name,
                            ),
                            child: TextButton.icon(
                              onPressed: onWithdraw,
                              icon: Icon(
                                withdrawIcon ?? BankIcons.receive,
                                size: 18,
                                color: bankTheme.onSurfaceVariant,
                              ),
                              label: Text(
                                withdrawLabel,
                                style: BankTokens.labelMedium.copyWith(
                                  color: bankTheme.onSurfaceVariant,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  BankTokens.minTapTarget,
                                  BankTokens.minTapTarget,
                                ),
                                foregroundColor: bankTheme.onSurfaceVariant,
                                shape: RoundedRectangleBorder(
                                  borderRadius: bankTheme.buttonRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: resolvedSemanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}
