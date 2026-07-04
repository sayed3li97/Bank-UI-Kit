import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Local enum: avoids cross-module import
// ---------------------------------------------------------------------------

enum BankCardMaterial { plastic, metal }

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class BankPlanTier {
  final String id;
  final String name;
  final Money monthlyPrice;
  final String? tagline;
  final BankCardMaterial? material;
  final Color? accentColor;
  final List<BankPlanFeature> features;

  const BankPlanTier({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.features,
    this.tagline,
    this.material,
    this.accentColor,
  });
}

class BankPlanFeature {
  final String label;

  /// Maps tierId → true (included) / false (not included) / null (partial).
  final Map<String, bool?> tierSupport;

  const BankPlanFeature({required this.label, required this.tierSupport});
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Side-by-side plan tier comparison table.
///
/// Horizontally scrollable when there are more than 3 tiers. Each tier header
/// is tappable when [onSelectTier] is provided. The tier identified by
/// [highlightedTierId] receives a primary-coloured 2px emphasis border.
class BankPlanComparisonTable extends StatelessWidget {
  final List<BankPlanTier> tiers;
  final String? highlightedTierId;
  final ValueChanged<BankPlanTier>? onSelectTier;

  /// Width of each tier column. Defaults to 120.
  final double? columnWidth;

  /// Width of the fixed feature-label column. Defaults to 140.
  final double? labelColumnWidth;

  /// Height of each feature row. Defaults to 44.
  final double? rowHeight;

  /// Height of the tier header block. Defaults to 120.
  final double? headerHeight;

  /// Overrides the emphasis border colour of the highlighted tier.
  /// Defaults to the theme primary.
  final Color? highlightColor;

  /// Overrides the fallback tier accent when a tier has no
  /// [BankPlanTier.accentColor]. Defaults to the theme primary.
  final Color? accentColor;

  /// Colour of the included-feature check. Defaults to
  /// [BankTokens.success].
  final Color? includedColor;

  /// Colour of the not-included cross. Defaults to the theme
  /// onSurfaceVariant.
  final Color? excludedColor;

  /// Colour of the partially-included dash. Defaults to
  /// [BankTokens.pending].
  final Color? partialColor;

  /// Glyph for included features. Defaults to [Icons.check].
  final IconData? includedIcon;

  /// Glyph for not-included features. Defaults to [Icons.close].
  final IconData? excludedIcon;

  /// Glyph for partially-included features. Defaults to
  /// [Icons.horizontal_rule].
  final IconData? partialIcon;

  /// Merged over the feature-label style (BankTokens.bodySmall in
  /// onSurfaceVariant).
  final TextStyle? featureLabelStyle;

  /// Merged over the tier-name style (BankTokens.labelLarge in the tier
  /// accent).
  final TextStyle? tierNameStyle;

  /// Merged over the price style (theme numeralSmall in onSurface).
  final TextStyle? priceStyle;

  /// Suffix under each monthly price. Defaults to `'/mo'`.
  final String perMonthLabel;

  /// Screen-reader value for included cells. Defaults to `'included'`.
  final String includedSemanticsLabel;

  /// Screen-reader value for not-included cells. Defaults to
  /// `'not included'`.
  final String notIncludedSemanticsLabel;

  /// Screen-reader value for partial cells. Defaults to
  /// `'partially included'`.
  final String partialSemanticsLabel;

  /// Overrides the generated table semantics label
  /// (`'Plan comparison table with <n> tiers'`).
  final String? semanticLabel;

  const BankPlanComparisonTable({
    required this.tiers,
    super.key,
    this.highlightedTierId,
    this.onSelectTier,
    this.columnWidth,
    this.labelColumnWidth,
    this.rowHeight,
    this.headerHeight,
    this.highlightColor,
    this.accentColor,
    this.includedColor,
    this.excludedColor,
    this.partialColor,
    this.includedIcon,
    this.excludedIcon,
    this.partialIcon,
    this.featureLabelStyle,
    this.tierNameStyle,
    this.priceStyle,
    this.perMonthLabel = '/mo',
    this.includedSemanticsLabel = 'included',
    this.notIncludedSemanticsLabel = 'not included',
    this.partialSemanticsLabel = 'partially included',
    this.semanticLabel,
  });

  static const double _columnWidth = 120;
  static const double _labelColumnWidth = 140;
  static const double _rowHeight = 44;
  static const double _headerHeight = 120;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final needsScroll = tiers.length > 3;

    final resolvedColumnWidth = columnWidth ?? _columnWidth;
    final resolvedLabelColumnWidth = labelColumnWidth ?? _labelColumnWidth;
    final resolvedRowHeight = rowHeight ?? _rowHeight;
    final resolvedHeaderHeight = headerHeight ?? _headerHeight;
    final resolvedHighlight = highlightColor ?? bankTheme.primary;

    // Collect all unique feature labels preserving insertion order.
    final allFeatures = _collectFeatures();

    Widget table = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed label column
        _LabelColumn(
          features: allFeatures,
          bankTheme: bankTheme,
          headerHeight: resolvedHeaderHeight,
          rowHeight: resolvedRowHeight,
          labelColumnWidth: resolvedLabelColumnWidth,
          labelStyle: featureLabelStyle,
        ),
        // Tier columns
        ...tiers.map(
          (tier) => _TierColumn(
            tier: tier,
            features: allFeatures,
            bankTheme: bankTheme,
            scope: scope,
            isHighlighted: tier.id == highlightedTierId,
            onSelectTier: onSelectTier,
            columnWidth: resolvedColumnWidth,
            headerHeight: resolvedHeaderHeight,
            rowHeight: resolvedRowHeight,
            table: this,
            highlightColor: resolvedHighlight,
          ),
        ),
      ],
    );

    if (needsScroll) {
      table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      );
    }

    return Semantics(
      label:
          semanticLabel ?? 'Plan comparison table with ${tiers.length} tiers',
      child: table,
    );
  }

  List<BankPlanFeature> _collectFeatures() {
    final seen = <String>{};
    final result = <BankPlanFeature>[];
    for (final tier in tiers) {
      for (final feature in tier.features) {
        if (seen.add(feature.label)) {
          result.add(feature);
        }
      }
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Label column
// ---------------------------------------------------------------------------

class _LabelColumn extends StatelessWidget {
  final List<BankPlanFeature> features;
  final BankThemeData bankTheme;
  final double headerHeight;
  final double rowHeight;
  final double labelColumnWidth;
  final TextStyle? labelStyle;

  const _LabelColumn({
    required this.features,
    required this.bankTheme,
    required this.headerHeight,
    required this.rowHeight,
    required this.labelColumnWidth,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spacer to match header height
        SizedBox(height: headerHeight),
        ...features.map(
          (f) => Container(
            height: rowHeight,
            width: labelColumnWidth,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(right: BankTokens.space2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: bankTheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              f.label,
              style: BankTokens.bodySmall
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(labelStyle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Per-tier column
// ---------------------------------------------------------------------------

class _TierColumn extends StatelessWidget {
  final BankPlanTier tier;
  final List<BankPlanFeature> features;
  final BankThemeData bankTheme;
  final BankUiScopeData scope;
  final bool isHighlighted;
  final ValueChanged<BankPlanTier>? onSelectTier;
  final double columnWidth;
  final double headerHeight;
  final double rowHeight;
  final BankPlanComparisonTable table;
  final Color highlightColor;

  const _TierColumn({
    required this.tier,
    required this.features,
    required this.bankTheme,
    required this.scope,
    required this.isHighlighted,
    required this.onSelectTier,
    required this.columnWidth,
    required this.headerHeight,
    required this.rowHeight,
    required this.table,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tier.accentColor ?? table.accentColor ?? bankTheme.primary;
    final formattedPrice = BankMoneyFormatter.format(
      amount: tier.monthlyPrice.amount,
      currencyCode: tier.monthlyPrice.currencyCode,
      numeralStyle: scope.numeralStyle,
      hideFraction: true,
    );

    final highlightSide = isHighlighted
        ? BorderSide(color: highlightColor, width: 2)
        : BorderSide.none;

    Widget header = Container(
      height: headerHeight,
      width: columnWidth,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border(
          top: highlightSide,
          left: highlightSide,
          right: highlightSide,
          bottom: BorderSide(
            color: bankTheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        borderRadius: isHighlighted
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(BankTokens.space2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tier.tagline != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(BankTokens.radiusFull),
              ),
              child: Text(
                tier.tagline!,
                style: BankTokens.labelSmall.copyWith(
                  color: bankTheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: BankTokens.space1),
          ],
          Text(
            tier.name,
            style: BankTokens.labelLarge
                .copyWith(color: accent)
                .merge(table.tierNameStyle),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: BankTokens.space1),
          Text(
            formattedPrice,
            style: bankTheme.numeralSmall
                .copyWith(color: bankTheme.onSurface)
                .merge(table.priceStyle),
            textAlign: TextAlign.center,
          ),
          Text(
            table.perMonthLabel,
            style: BankTokens.bodySmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onSelectTier != null) {
      header = Semantics(
        label: 'Select ${tier.name} plan at $formattedPrice per month',
        button: true,
        child: InkWell(
          onTap: () => onSelectTier!(tier),
          child: header,
        ),
      );
    }

    return Column(
      children: [
        header,
        ...features.map((feature) {
          final support = feature.tierSupport[tier.id];
          return _FeatureCell(
            support: support,
            bankTheme: bankTheme,
            isHighlighted: isHighlighted,
            columnWidth: columnWidth,
            rowHeight: rowHeight,
            featureLabel: feature.label,
            tierName: tier.name,
            table: table,
            highlightColor: highlightColor,
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature cell
// ---------------------------------------------------------------------------

class _FeatureCell extends StatelessWidget {
  final bool? support;
  final BankThemeData bankTheme;
  final bool isHighlighted;
  final double columnWidth;
  final double rowHeight;
  final String featureLabel;
  final String tierName;
  final BankPlanComparisonTable table;
  final Color highlightColor;

  const _FeatureCell({
    required this.support,
    required this.bankTheme,
    required this.isHighlighted,
    required this.columnWidth,
    required this.rowHeight,
    required this.featureLabel,
    required this.tierName,
    required this.table,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String semanticValue;

    if (support == true) {
      icon = table.includedIcon ?? Icons.check;
      color = table.includedColor ?? BankTokens.success;
      semanticValue = table.includedSemanticsLabel;
    } else if (support == false) {
      icon = table.excludedIcon ?? Icons.close;
      color = table.excludedColor ?? bankTheme.onSurfaceVariant;
      semanticValue = table.notIncludedSemanticsLabel;
    } else {
      icon = table.partialIcon ?? Icons.horizontal_rule;
      color = table.partialColor ?? BankTokens.pending;
      semanticValue = table.partialSemanticsLabel;
    }

    final highlightSide = isHighlighted
        ? BorderSide(color: highlightColor, width: 2)
        : BorderSide(
            color: bankTheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          );

    return Semantics(
      label: '$featureLabel in $tierName: $semanticValue',
      child: Container(
        height: rowHeight,
        width: columnWidth,
        decoration: BoxDecoration(
          border: Border(
            left: highlightSide,
            right: highlightSide,
            bottom: BorderSide(
              color: bankTheme.outline.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
