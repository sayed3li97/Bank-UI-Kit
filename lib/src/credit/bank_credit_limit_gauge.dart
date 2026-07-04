import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// 270° arc gauge showing used credit vs total credit limit.
class BankCreditLimitGauge extends StatelessWidget {
  final Money creditLimit;
  final Money usedAmount;
  final String? label;

  /// Width of the gauge arc area. Defaults to 200.
  final double? gaugeWidth;

  /// Height of the gauge arc area. Defaults to 120.
  final double? gaugeHeight;

  /// Stroke thickness of the gauge arc. Defaults to 14.
  final double? strokeWidth;

  /// Overrides the arc fill color. Defaults to a utilisation-driven
  /// color (theme primary, amber above 60%, loss red above 80%).
  final Color? accentColor;

  /// Overrides the arc track color. Defaults to the theme outline at
  /// 30% opacity.
  final Color? trackColor;

  /// Caption under the available amount. Defaults to `'available'`.
  final String availableLabel;

  /// Legend caption for the used amount. Defaults to `'Used'`.
  final String usedLabel;

  /// Legend caption for the credit limit. Defaults to `'Limit'`.
  final String limitLabel;

  /// Overrides the whole computed semantics label.
  final String? semanticLabel;

  /// Merged over the available-amount style (numeralMedium, onSurface).
  final TextStyle? amountStyle;

  /// Merged over the [availableLabel] caption style (bodySmall,
  /// variant color).
  final TextStyle? subtitleStyle;

  /// Merged over both legend caption styles (bodySmall, variant color).
  final TextStyle? legendLabelStyle;

  /// Merged over both legend value styles (labelSmall, onSurface).
  final TextStyle? legendValueStyle;

  const BankCreditLimitGauge({
    required this.creditLimit,
    required this.usedAmount,
    super.key,
    this.label,
    this.gaugeWidth,
    this.gaugeHeight,
    this.strokeWidth,
    this.accentColor,
    this.trackColor,
    this.availableLabel = 'available',
    this.usedLabel = 'Used',
    this.limitLabel = 'Limit',
    this.semanticLabel,
    this.amountStyle,
    this.subtitleStyle,
    this.legendLabelStyle,
    this.legendValueStyle,
  });

  double get _fraction {
    final limit = creditLimit.amount.toDouble();
    if (limit <= 0) return 0;
    final used = usedAmount.amount.toDouble().clamp(0.0, limit);
    return used / limit;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final usedStr = BankMoneyFormatter.format(
      amount: usedAmount.amount,
      currencyCode: usedAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );
    final limitStr = BankMoneyFormatter.format(
      amount: creditLimit.amount,
      currencyCode: creditLimit.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final availableAmount = creditLimit - usedAmount;
    final availableStr = BankMoneyFormatter.format(
      amount: availableAmount.amount,
      currencyCode: availableAmount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final fraction = _fraction;
    final gaugeColor = accentColor ??
        (fraction > 0.8
            ? BankTokens.investmentLoss
            : fraction > 0.6
                ? Colors.amber
                : theme.primary);

    return Semantics(
      label: semanticLabel ??
          '${label ?? 'Credit limit'}: $usedStr used of $limitStr, '
              '$availableStr available',
      child: Column(
        children: [
          SizedBox(
            width: gaugeWidth ?? 200,
            height: gaugeHeight ?? 120,
            child: CustomPaint(
              painter: _GaugePainter(
                fraction: fraction,
                gaugeColor: gaugeColor,
                trackColor: trackColor ?? theme.outline.withValues(alpha: 0.3),
                strokeWidth: strokeWidth ?? 14,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      availableStr,
                      style: BankTokens.numeralMedium
                          .copyWith(color: theme.onSurface)
                          .merge(amountStyle),
                    ),
                    Text(
                      availableLabel,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(subtitleStyle),
                    ),
                    const SizedBox(height: BankTokens.space2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                color: gaugeColor,
                label: usedLabel,
                value: usedStr,
                theme: theme,
                labelStyle: legendLabelStyle,
                valueStyle: legendValueStyle,
              ),
              _LegendItem(
                color: theme.outline.withValues(alpha: 0.5),
                label: limitLabel,
                value: limitStr,
                theme: theme,
                labelStyle: legendLabelStyle,
                valueStyle: legendValueStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final BankThemeData theme;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: BankTokens.bodySmall
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(labelStyle),
            ),
            Text(
              value,
              style: BankTokens.labelSmall
                  .copyWith(color: theme.onSurface)
                  .merge(valueStyle),
            ),
          ],
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color gaugeColor;
  final Color trackColor;
  final double strokeWidth;

  const _GaugePainter({
    required this.fraction,
    required this.gaugeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = (size.width / 2) - strokeWidth / 2;
    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.3;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    if (fraction > 0) {
      final gaugePaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fraction.clamp(0.0, 1.0),
        false,
        gaugePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.gaugeColor != gaugeColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
