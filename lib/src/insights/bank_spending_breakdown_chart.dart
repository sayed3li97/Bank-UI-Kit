import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/models/transaction.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// A category name + money pair for the spending breakdown.
class BankSpendingCategory {
  final TransactionCategory category;
  final Money amount;
  final Color? color;

  const BankSpendingCategory({
    required this.category,
    required this.amount,
    this.color,
  });
}

/// Donut chart showing spending split by category.
class BankSpendingBreakdownChart extends StatefulWidget {
  final List<BankSpendingCategory> categories;

  /// Overrides the amount shown in the donut centre. Defaults to the
  /// formatted total of all [categories].
  final String? centerLabel;

  /// Caption rendered under the centre amount. Defaults to 'Total'.
  final String centerCaption;

  /// Merged over the centre amount style (numeralLarge, onSurface).
  final TextStyle? centerLabelStyle;

  /// Merged over the [centerCaption] style (caption, onSurfaceVariant).
  final TextStyle? centerCaptionStyle;

  /// Overrides the fallback section palette used when a category has
  /// no explicit colour. Cycled when shorter than the category list.
  /// Defaults to a deterministic theme-derived ramp, see
  /// [derivePalette]. Takes precedence over [colors].
  final List<Color>? palette;

  /// Overrides the fallback section palette used when a category has
  /// no explicit colour. Cycled when shorter than the category list.
  final List<Color>? colors;

  /// Overrides the donut height. Defaults to 220.
  final double? chartHeight;

  /// Overrides the donut hole radius. Defaults to 60.
  final double? centerSpaceRadius;

  /// Empty-state text. Defaults to 'No spending data'.
  final String emptyLabel;

  /// Merged over the empty-state style (bodyMedium, onSurfaceVariant).
  final TextStyle? emptyLabelStyle;

  /// Merged over the touched-section percent style (labelSmall, white).
  final TextStyle? sectionTitleStyle;

  /// Merged over the legend category name style (labelSmall,
  /// onSurface).
  final TextStyle? legendLabelStyle;

  /// Merged over the legend amount style (bodySmall, onSurfaceVariant).
  final TextStyle? legendAmountStyle;

  /// Overrides the built-in English category names in the legend.
  final String Function(TransactionCategory category)? categoryNameBuilder;

  /// Wraps the chart in a [Semantics] node when provided; no semantics
  /// node is added by default.
  final String? semanticLabel;

  const BankSpendingBreakdownChart({
    required this.categories,
    super.key,
    this.centerLabel,
    this.centerCaption = 'Total',
    this.centerLabelStyle,
    this.centerCaptionStyle,
    this.palette,
    this.colors,
    this.chartHeight,
    this.centerSpaceRadius,
    this.emptyLabel = 'No spending data',
    this.emptyLabelStyle,
    this.sectionTitleStyle,
    this.legendLabelStyle,
    this.legendAmountStyle,
    this.categoryNameBuilder,
    this.semanticLabel,
  });

  /// Derives the default categorical palette from a brand [seed]
  /// colour.
  ///
  /// The ramp is generated deterministically in HSL space: hues rotate
  /// from the seed in stable 42 degree steps, chroma is clamped to a
  /// matched band, and lightness is anchored per [brightness] (with a
  /// small alternating offset) so neighbouring slices stay distinct and
  /// AA-legible on both light and dark surfaces. Any preset rebrand
  /// therefore recolours the donut with no per-widget configuration.
  static List<Color> derivePalette({
    required Color seed,
    required Brightness brightness,
    int length = 8,
  }) {
    assert(length > 0, 'length must be positive');
    final hsl = HSLColor.fromColor(seed);
    final isDark = brightness == Brightness.dark;
    final saturation = hsl.saturation.clamp(0.45, 0.72);
    final baseLightness = isDark ? 0.62 : 0.38;
    return List<Color>.generate(length, (i) {
      final hue = (hsl.hue + i * 42.0) % 360.0;
      final lightness = (baseLightness +
              (i.isEven
                  ? 0.0
                  : isDark
                      ? 0.08
                      : -0.06))
          .clamp(0.0, 1.0);
      return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    });
  }

  @override
  State<BankSpendingBreakdownChart> createState() =>
      _BankSpendingBreakdownChartState();
}

class _BankSpendingBreakdownChartState
    extends State<BankSpendingBreakdownChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(
          widget.emptyLabel,
          style: BankTokens.bodyMedium
              .copyWith(color: theme.onSurfaceVariant)
              .merge(widget.emptyLabelStyle),
        ),
      );
    }

    final total = widget.categories.fold<double>(
      0,
      (sum, c) => sum + c.amount.amount.toDouble().abs(),
    );
    final totalStr = BankMoneyFormatter.format(
      amount: Money.fromDouble(
        total,
        widget.categories.first.amount.currencyCode,
      ).amount,
      currencyCode: widget.categories.first.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    final explicitPalette = (widget.palette != null && widget.palette!.isEmpty)
        ? null
        : widget.palette ??
            ((widget.colors == null || widget.colors!.isEmpty)
                ? null
                : widget.colors);
    final palette = explicitPalette ??
        BankSpendingBreakdownChart.derivePalette(
          seed: theme.primary,
          brightness: ThemeData.estimateBrightnessForColor(theme.surface),
        );

    final centerSpaceRadius = widget.centerSpaceRadius ?? 60;

    final chart = RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: widget.chartHeight ?? 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Total anchored in the donut hole: amount + caption.
                SizedBox(
                  width: math.max(centerSpaceRadius * 2 - BankTokens.space2, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.centerLabel ?? totalStr,
                          style: BankTokens.numeralLarge
                              .copyWith(color: theme.onSurface)
                              .merge(widget.centerLabelStyle),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        widget.centerCaption,
                        style: BankTokens.caption
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(widget.centerCaptionStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          setState(() => _touchedIndex = -1);
                          return;
                        }
                        setState(
                          () => _touchedIndex =
                              response.touchedSection!.touchedSectionIndex,
                        );
                      },
                    ),
                    centerSpaceRadius: centerSpaceRadius,
                    sectionsSpace: 2,
                    sections: widget.categories.asMap().entries.map((entry) {
                      final i = entry.key;
                      final cat = entry.value;
                      final isTouched = i == _touchedIndex;
                      final color = cat.color ?? palette[i % palette.length];
                      final value = cat.amount.amount.toDouble().abs();
                      final pct = total > 0 ? (value / total * 100) : 0.0;

                      return PieChartSectionData(
                        value: value,
                        color: color,
                        radius: isTouched ? 60 : 50,
                        showTitle: isTouched,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: BankTokens.labelSmall
                            .copyWith(color: Colors.white)
                            .merge(widget.sectionTitleStyle),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BankTokens.space3),
          // Integrated legend: one row per category with aligned
          // swatch / label / value columns (no orphaned wrap row).
          Column(
            children: widget.categories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final color = cat.color ?? palette[i % palette.length];
              final amountStr = BankMoneyFormatter.format(
                amount: cat.amount.amount,
                currencyCode: cat.amount.currencyCode,
                numeralStyle: scope.numeralStyle,
              );

              return GestureDetector(
                onTap: () => setState(
                  () => _touchedIndex = _touchedIndex == i ? -1 : i,
                ),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BankTokens.space1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: BankTokens.space2),
                      Expanded(
                        child: Text(
                          widget.categoryNameBuilder?.call(cat.category) ??
                              _categoryName(cat.category),
                          style: BankTokens.labelSmall
                              .copyWith(color: theme.onSurface)
                              .merge(widget.legendLabelStyle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: BankTokens.space2),
                      Text(
                        amountStr,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(widget.legendAmountStyle),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (widget.semanticLabel == null) return chart;
    return Semantics(label: widget.semanticLabel, child: chart);
  }

  String _categoryName(TransactionCategory cat) => switch (cat) {
        TransactionCategory.groceries => 'Groceries',
        TransactionCategory.dining => 'Dining',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.health => 'Health',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.travel => 'Travel',
        TransactionCategory.education => 'Education',
        TransactionCategory.subscription => 'Subscription',
        TransactionCategory.transfer => 'Transfer',
        TransactionCategory.income => 'Income',
        TransactionCategory.investment => 'Investment',
        TransactionCategory.creditPayment => 'Credit',
        TransactionCategory.other => 'Other',
      };
}
