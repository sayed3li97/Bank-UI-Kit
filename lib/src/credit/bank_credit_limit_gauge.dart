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

  const BankCreditLimitGauge({
    super.key,
    required this.creditLimit,
    required this.usedAmount,
    this.label,
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
    final gaugeColor = fraction > 0.8
        ? BankTokens.investmentLoss
        : fraction > 0.6
            ? Colors.amber
            : theme.primary;

    return Semantics(
      label:
          '${label ?? 'Credit limit'}: $usedStr used of $limitStr, $availableStr available',
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(
                fraction: fraction,
                gaugeColor: gaugeColor,
                trackColor: theme.outline.withOpacity(0.3),
                strokeWidth: 14,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      availableStr,
                      style: BankTokens.numeralMedium
                          .copyWith(color: theme.onSurface),
                    ),
                    Text(
                      'available',
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
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
                label: 'Used',
                value: usedStr,
                theme: theme,
              ),
              _LegendItem(
                color: theme.outline.withOpacity(0.5),
                label: 'Limit',
                value: limitStr,
                theme: theme,
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

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
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
            Text(label,
                style:
                    BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant)),
            Text(value,
                style: BankTokens.labelSmall.copyWith(color: theme.onSurface)),
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
      old.trackColor != trackColor;
}
