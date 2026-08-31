import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../l10n/bank_strings.dart';

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
  /// color (theme primary, [BankTokens.warning] above 60%,
  /// [BankTokens.danger] above 80%; dark variants on dark surfaces).
  final Color? accentColor;

  /// Overrides the arc track color. Defaults to the theme onSurface at
  /// 10% opacity (16% on dark surfaces).
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
    this.availableLabel = _kAvailableLabel,
    this.usedLabel = _kUsedLabel,
    this.limitLabel = _kLimitLabel,
    this.semanticLabel,
    this.amountStyle,
    this.subtitleStyle,
    this.legendLabelStyle,
    this.legendValueStyle,
  });

  static const String _kAvailableLabel = 'available';
  static const String _kUsedLabel = 'Used';
  static const String _kLimitLabel = 'Limit';

  double get _fraction {
    final limit = creditLimit.amount.toDouble();
    if (limit <= 0) return 0;
    final used = usedAmount.amount.toDouble().clamp(0.0, limit);
    return used / limit;
  }

  /// Start angle of the gauge arc, in radians (135 degrees).
  static const double gaugeStartAngle = math.pi * 0.75;

  /// Sweep of the gauge arc, in radians: exactly 270 degrees.
  static const double gaugeSweepAngle = math.pi * 1.5;

  /// Computes the arc centre and radius so the whole stroke — including
  /// the round caps at the 270 degree endpoints — stays inside [size].
  @visibleForTesting
  static ({Offset center, double radius}) gaugeGeometry(
    Size size,
    double strokeWidth,
  ) {
    // The arc endpoints sit sin(45°) below the centre, so the painted
    // height is radius * (1 + sin(45°)) plus one stroke width.
    final maxByWidth = (size.width - strokeWidth) / 2;
    final maxByHeight =
        (size.height - strokeWidth) / (1 + math.sin(math.pi / 4));
    final radius = math.max(math.min(maxByWidth, maxByHeight), 0).toDouble();
    return (
      center: Offset(size.width / 2, strokeWidth / 2 + radius),
      radius: radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final strings = BankStrings.of(context);

    // Each caption arrives as a non-nullable String defaulted to the shipped
    // English, so `override` tells a host's wording from the default and the
    // gauge speaks the device's language without the parameter changing type.
    // All three resolve together: a legend whose "available" is translated
    // while "Used" and "Limit" are not is a half-translated surface, which
    // reads as a bug in the bank rather than as a missing translation.
    final availableLabel =
        BankStrings.override(this.availableLabel, _kAvailableLabel) ??
            strings.labelAvailableLower;
    final usedLabel =
        BankStrings.override(this.usedLabel, _kUsedLabel) ?? strings.labelUsed;
    final limitLabel = BankStrings.override(this.limitLabel, _kLimitLabel) ??
        strings.labelLimit;

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

    final isDark =
        ThemeData.estimateBrightnessForColor(theme.surface) == Brightness.dark;
    final fraction = _fraction;
    final gaugeColor = accentColor ??
        (fraction > 0.8
            ? (isDark ? BankTokens.dangerDark : BankTokens.danger)
            : fraction > 0.6
                ? (isDark ? BankTokens.warningDark : BankTokens.warning)
                : theme.primary);
    final resolvedTrack =
        trackColor ?? theme.onSurface.withValues(alpha: isDark ? 0.16 : 0.10);

    return Semantics(
      label: semanticLabel ??
          strings.a11yCreditLimit(
            label ?? strings.creditLimit,
            usedStr,
            limitStr,
            availableStr,
          ),
      child: Column(
        children: [
          SizedBox(
            width: gaugeWidth ?? 200,
            height: gaugeHeight ?? 120,
            child: CustomPaint(
              painter: _GaugePainter(
                fraction: fraction,
                gaugeColor: gaugeColor,
                trackColor: resolvedTrack,
                knobColor: theme.surface,
                strokeWidth: strokeWidth ?? 14,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          // Legend pinned centrally beneath the arc endpoints rather
          // than flung to the component's extreme corners.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: gaugeColor,
                label: usedLabel,
                value: usedStr,
                theme: theme,
                labelStyle: legendLabelStyle,
                valueStyle: legendValueStyle,
              ),
              const SizedBox(width: BankTokens.space6),
              _LegendItem(
                color: resolvedTrack,
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
  final Color knobColor;
  final double strokeWidth;

  const _GaugePainter({
    required this.fraction,
    required this.gaugeColor,
    required this.trackColor,
    required this.knobColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry is clamped so the stroke (round caps included) never
    // paints outside the canvas.
    final geometry = BankCreditLimitGauge.gaugeGeometry(size, strokeWidth);
    final center = geometry.center;
    final radius = geometry.radius;
    if (radius <= 0) return;
    const startAngle = BankCreditLimitGauge.gaugeStartAngle;
    const sweepAngle = BankCreditLimitGauge.gaugeSweepAngle;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..isAntiAlias = true
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    final clamped = fraction.clamp(0.0, 1.0);
    if (clamped > 0) {
      final gaugePaint = Paint()
        ..isAntiAlias = true
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle * clamped, false, gaugePaint);

      // Anti-aliased knob at the progress endpoint: a surface-coloured
      // core ringed in the gauge tint.
      final knobAngle = startAngle + sweepAngle * clamped;
      final knobCenter = Offset(
        center.dx + radius * math.cos(knobAngle),
        center.dy + radius * math.sin(knobAngle),
      );
      canvas
        ..drawCircle(
          knobCenter,
          strokeWidth * 0.32,
          Paint()
            ..isAntiAlias = true
            ..color = knobColor,
        )
        ..drawCircle(
          knobCenter,
          strokeWidth * 0.32,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = gaugeColor,
        );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.gaugeColor != gaugeColor ||
      old.trackColor != trackColor ||
      old.knobColor != knobColor ||
      old.strokeWidth != strokeWidth;
}
