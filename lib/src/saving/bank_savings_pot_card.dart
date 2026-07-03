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

  const BankSavingsPotCard({
    required this.pot,
    super.key,
    this.onTap,
    this.onAddMoney,
    this.onWithdraw,
    this.itemBuilder,
    this.rateSuffix = 'AER',
    this.profitRateSuffix = 'expected profit',
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
    final semanticLabel =
        'Pot: ${pot.name}, $formattedCurrent of $formattedTarget goal, '
        '${(pot.progressFraction * 100).round()}% complete';

    final Widget card = Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: bankTheme.cardRadius,
        boxShadow: bankTheme.useGlow && bankTheme.glowColor != null
            ? [
                BoxShadow(
                  color: bankTheme.glowColor!.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: bankTheme.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: bankTheme.cardRadius,
          splashColor: bankTheme.primary.withValues(alpha: 0.08),
          highlightColor: bankTheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top row: ring + info ──────────────────────────────────
                Row(
                  children: [
                    // Progress ring
                    SizedBox(
                      width: _ringDiameter,
                      height: _ringDiameter,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: pot.progressFraction,
                          trackColor: bankTheme.surfaceVariant,
                          progressColor: bankTheme.primary,
                          gradient: bankTheme.accentGradient,
                        ),
                        child: Center(
                          child: Text(
                            '${(pot.progressFraction * 100).round()}%',
                            style: BankTokens.labelSmall.copyWith(
                              color: bankTheme.primary,
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
                            style: BankTokens.labelLarge.copyWith(
                              color: bankTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Current balance
                          BankBalanceText(
                            money: pot.current,
                            size: BankBalanceSize.medium,
                            style: bankTheme.numeralMedium.copyWith(
                              color: bankTheme.primary,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Target label
                          Text(
                            'of $formattedTarget goal',
                            style: BankTokens.bodySmall.copyWith(
                              color: bankTheme.onSurfaceVariant,
                            ),
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
                                    label: 'Has own account number',
                                    child: _BadgeChip(
                                      label: 'Own account',
                                      color: bankTheme.primary,
                                      icon: BankIcons.account,
                                    ),
                                  ),
                                if (isShared)
                                  Semantics(
                                    label: 'Shared pot with '
                                        '${pot.memberIds.length} members',
                                    child: _BadgeChip(
                                      label: '${pot.memberIds.length} members',
                                      color: bankTheme.onSurfaceVariant,
                                      icon: BankIcons.accountJoint,
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
                            label: 'Add money to ${pot.name}',
                            child: TextButton.icon(
                              onPressed: onAddMoney,
                              icon: Icon(
                                BankIcons.add,
                                size: 18,
                                color: bankTheme.primary,
                              ),
                              label: Text(
                                'Add',
                                style: BankTokens.labelMedium.copyWith(
                                  color: bankTheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  BankTokens.minTapTarget,
                                  BankTokens.minTapTarget,
                                ),
                                foregroundColor: bankTheme.primary,
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
                            label: 'Withdraw from ${pot.name}',
                            child: TextButton.icon(
                              onPressed: onWithdraw,
                              icon: Icon(
                                BankIcons.receive,
                                size: 18,
                                color: bankTheme.onSurfaceVariant,
                              ),
                              label: Text(
                                'Withdraw',
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
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}
