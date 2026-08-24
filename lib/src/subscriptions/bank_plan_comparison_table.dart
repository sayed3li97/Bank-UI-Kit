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
/// The table scrolls horizontally whenever its natural width (the label
/// column plus one column per tier) exceeds the space it is given — tier
/// *count* is a poor proxy for that, and going by it is how three wide
/// columns used to clip off-screen in silence. While columns remain
/// off-screen the corresponding edge fades out, so the row of tiers reads as
/// continuing rather than ending; see [showEdgeFade].
///
/// Each tier header is tappable when [onSelectTier] is provided. The tier
/// identified by [highlightedTierId] is framed by a closed
/// [BankTokens.radiusMedium] emphasis border in [highlightColor], drawn as an
/// overlay so the emphasised column keeps the exact geometry of its
/// neighbours and its rows stay on the same baselines.
class BankPlanComparisonTable extends StatefulWidget {
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

  /// Whether an edge fade marks the direction the table can still scroll in.
  ///
  /// Purely decorative and excluded from semantics — screen readers already
  /// get the whole table. Set to `false` when the table sits on a patterned
  /// or image background that [edgeFadeColor] cannot match.
  final bool showEdgeFade;

  /// The colour the edge fade ramps to. Defaults to the theme surface — the
  /// tone a table is normally carded on. Set it to whatever is actually
  /// behind the table when that differs, otherwise the fade reads as a
  /// coloured bar instead of the content running out.
  final Color? edgeFadeColor;

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
    this.showEdgeFade = true,
    this.edgeFadeColor,
  });

  static const double _columnWidth = 120;
  static const double _labelColumnWidth = 140;
  static const double _rowHeight = 44;
  static const double _headerHeight = 120;

  /// Stroke of the emphasis frame around the highlighted tier.
  static const double _emphasisWidth = 2;

  /// How far the edge fade reaches into the table.
  static const double _edgeFadeWidth = BankTokens.space8;

  @override
  State<BankPlanComparisonTable> createState() =>
      _BankPlanComparisonTableState();

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

class _BankPlanComparisonTableState extends State<BankPlanComparisonTable> {
  /// Whether columns remain off the leading / trailing edge.
  ///
  /// Seeded for a table that has just been laid out overflowing — parked at
  /// offset 0, so everything hidden is on the trailing side. Scroll
  /// notifications take over from there; waiting for one would leave the
  /// affordance missing exactly when it matters most, on first paint.
  bool _hiddenBefore = false;
  bool _hiddenAfter = true;

  @override
  void didUpdateWidget(BankPlanComparisonTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different number of columns is a different scroll extent; re-seed
    // rather than inherit the previous table's edges. Compared by length, not
    // by list identity: hosts routinely rebuild the same tiers into a fresh
    // list, and that must not throw the affordance away mid-scroll.
    if (oldWidget.tiers.length != widget.tiers.length) {
      _hiddenBefore = false;
      _hiddenAfter = true;
    }
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    final before = notification.metrics.extentBefore > 0;
    final after = notification.metrics.extentAfter > 0;
    if (before != _hiddenBefore || after != _hiddenAfter) {
      setState(() {
        _hiddenBefore = before;
        _hiddenAfter = after;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final resolvedColumnWidth =
        widget.columnWidth ?? BankPlanComparisonTable._columnWidth;
    final resolvedLabelColumnWidth =
        widget.labelColumnWidth ?? BankPlanComparisonTable._labelColumnWidth;
    final resolvedRowHeight =
        widget.rowHeight ?? BankPlanComparisonTable._rowHeight;
    final resolvedHeaderHeight =
        widget.headerHeight ?? BankPlanComparisonTable._headerHeight;
    final resolvedHighlight = widget.highlightColor ?? bankTheme.primary;

    // One rule definition for the whole table, derived from the surface it is
    // carded on rather than from a fixed alpha, so it holds up in dark mode.
    final rule = BorderSide(
      color: BankTokens.hairlineColor(
        bankTheme.onSurface,
        ThemeData.estimateBrightnessForColor(bankTheme.surface),
      ),
      // Matches BorderSide's default today; keep the token as the source of
      // truth for hairline geometry.
      // ignore: avoid_redundant_argument_values
      width: BankTokens.hairlineWidth,
    );

    // Collect all unique feature labels preserving insertion order.
    final allFeatures = widget._collectFeatures();

    final table = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed label column
        _LabelColumn(
          features: allFeatures,
          bankTheme: bankTheme,
          headerHeight: resolvedHeaderHeight,
          rowHeight: resolvedRowHeight,
          labelColumnWidth: resolvedLabelColumnWidth,
          labelStyle: widget.featureLabelStyle,
          rule: rule,
        ),
        // Tier columns
        ...widget.tiers.map(
          (tier) => _TierColumn(
            tier: tier,
            features: allFeatures,
            bankTheme: bankTheme,
            scope: scope,
            isHighlighted: tier.id == widget.highlightedTierId,
            onSelectTier: widget.onSelectTier,
            columnWidth: resolvedColumnWidth,
            headerHeight: resolvedHeaderHeight,
            rowHeight: resolvedRowHeight,
            table: widget,
            highlightColor: resolvedHighlight,
            rule: rule,
          ),
        ),
      ],
    );

    final naturalWidth =
        resolvedLabelColumnWidth + resolvedColumnWidth * widget.tiers.length;

    return Semantics(
      label: widget.semanticLabel ??
          'Plan comparison table with ${widget.tiers.length} tiers',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // An unbounded parent lays the table out at its natural width, and
          // a table that already fits needs neither scrolling nor a hint.
          if (!constraints.hasBoundedWidth ||
              naturalWidth <= constraints.maxWidth) {
            return table;
          }
          final fadeColor = widget.edgeFadeColor ?? bankTheme.surface;
          return NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: table,
                ),
                if (widget.showEdgeFade) ...[
                  _EdgeFade(
                    color: fadeColor,
                    atStart: true,
                    visible: _hiddenBefore,
                  ),
                  _EdgeFade(
                    color: fadeColor,
                    atStart: false,
                    visible: _hiddenAfter,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scroll affordance
// ---------------------------------------------------------------------------

/// A directional fade over one edge of the scroll view, shown while columns
/// remain hidden on that side.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.color,
    required this.atStart,
    required this.visible,
  });

  final Color color;

  /// Leading edge in the ambient reading direction (left in LTR).
  final bool atStart;

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      bottom: 0,
      start: atStart ? 0 : null,
      end: atStart ? null : 0,
      width: BankPlanComparisonTable._edgeFadeWidth,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: BankTokens.durationFast,
            curve: BankTokens.curveStandard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: atStart
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  end: atStart
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  colors: [color, color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  /// The shared row rule, resolved once by the table.
  final BorderSide rule;

  const _LabelColumn({
    required this.features,
    required this.bankTheme,
    required this.headerHeight,
    required this.rowHeight,
    required this.labelColumnWidth,
    required this.labelStyle,
    required this.rule,
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
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(end: BankTokens.space2),
            decoration: BoxDecoration(
              border: Border(bottom: rule),
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

  /// The shared row rule, resolved once by the table.
  final BorderSide rule;

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
    required this.rule,
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

    Widget header = Container(
      height: headerHeight,
      width: columnWidth,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: BankTokens.alphaSubtle),
        border: Border(bottom: rule),
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

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        ...features.map((feature) {
          final support = feature.tierSupport[tier.id];
          return _FeatureCell(
            support: support,
            bankTheme: bankTheme,
            columnWidth: columnWidth,
            rowHeight: rowHeight,
            featureLabel: feature.label,
            tierName: tier.name,
            table: table,
            rule: rule,
          );
        }),
      ],
    );

    if (!isHighlighted) return column;

    // The emphasis frame is an overlay, not a per-cell border: drawn cell by
    // cell it could only ever close on three sides (the last cell's bottom
    // belongs to the row rule), and the 2 px sides would eat into the
    // emphasised column's content box while its neighbours kept theirs.
    const radius = BorderRadius.all(Radius.circular(BankTokens.radiusMedium));
    return Stack(
      children: [
        ClipRRect(borderRadius: radius, child: column),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: highlightColor,
                  width: BankPlanComparisonTable._emphasisWidth,
                ),
                borderRadius: radius,
              ),
            ),
          ),
        ),
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
  final double columnWidth;
  final double rowHeight;
  final String featureLabel;
  final String tierName;
  final BankPlanComparisonTable table;

  /// The shared row rule, resolved once by the table.
  final BorderSide rule;

  const _FeatureCell({
    required this.support,
    required this.bankTheme,
    required this.columnWidth,
    required this.rowHeight,
    required this.featureLabel,
    required this.tierName,
    required this.table,
    required this.rule,
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

    return Semantics(
      label: '$featureLabel in $tierName: $semanticValue',
      child: Container(
        height: rowHeight,
        width: columnWidth,
        decoration: BoxDecoration(
          // Leading side only: two adjacent cells each drawing their own
          // vertical rule would double the hairline between columns.
          border: BorderDirectional(start: rule, bottom: rule),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: BankTokens.iconMedium, color: color),
      ),
    );
  }
}
