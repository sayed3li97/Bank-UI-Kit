import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// How a [BankProductCategoryTile] arranges its disc, text, and trailing
/// affordance.
enum BankProductCategoryTileLayout {
  /// Measure the available width and pick [horizontal] or [vertical]
  /// automatically (vertical below the compact breakpoint).
  ///
  /// Uses a [LayoutBuilder] internally, so it cannot answer
  /// intrinsic-dimension queries; hosts that rely on [IntrinsicHeight] /
  /// [IntrinsicWidth] must pass an explicit layout instead.
  auto,

  /// The classic single-row anatomy: disc, text column, trailing badge.
  horizontal,

  /// Stacked compact anatomy: disc and badge on a header row, then the
  /// title and subtitle at full tile width.
  vertical,
}

/// A tappable category tile for a product-catalog root grid.
///
/// Renders a semantic [icon] on a tinted disc, a [title] (e.g. `'Loans'`),
/// an optional [subtitle] (e.g. `'Auto, personal, home'`), and a trailing
/// affordance that is either a count badge (when [count] is provided) or a
/// directional chevron. The whole tile is a single 44 px minimum tap target
/// with an [InkWell] ripple, sitting on a [BankThemeData.surface] card with
/// the theme card radius and a resting [BankTokens.shadowCard].
///
/// Pass an [accentColor] to tint the disc and icon per product line (loans,
/// cards, deposits, and so on). Every visual decision is overridable through
/// an optional parameter, and every user-facing string has an English
/// default.
///
/// ```dart
/// GridView.count(
///   crossAxisCount: 2,
///   children: [
///     BankProductCategoryTile(
///       icon: BankIcons.creditPayment,
///       title: 'Loans',
///       subtitle: 'Auto, personal, home',
///       count: 6,
///       onTap: () => openCategory('loans'),
///     ),
///     BankProductCategoryTile(
///       icon: BankIcons.card,
///       title: 'Cards',
///       subtitle: 'Credit and charge',
///       onTap: () => openCategory('cards'),
///     ),
///   ],
/// )
/// ```
class BankProductCategoryTile extends StatelessWidget {
  const BankProductCategoryTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.count,
    this.showChevron = true,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.discColor,
    this.discGradient,
    this.shadow,
    this.titleStyle,
    this.subtitleStyle,
    this.chevronIcon,
    this.countBadgeColor,
    this.countBadgeTextStyle,
    this.leading,
    this.trailing,
    this.discDiameter,
    this.iconSize,
    this.minHeight,
    this.layout = BankProductCategoryTileLayout.auto,
    this.compactBreakpoint,
    this.titleMaxLines,
    this.subtitleMaxLines,
    this.semanticLabel,
  });

  /// Glyph shown inside the tinted disc. Prefer entries from `BankIcons`.
  final IconData icon;

  /// Category name shown as the tile's primary line.
  final String title;

  /// Invoked when the tile is tapped.
  final VoidCallback onTap;

  /// Optional secondary line describing what the category contains.
  final String? subtitle;

  /// Optional count shown in a trailing badge (e.g. number of products).
  /// When null, a chevron is shown instead if [showChevron] is `true`.
  final int? count;

  /// Whether to show a trailing chevron when [count] is null and no custom
  /// [trailing] is supplied. Defaults to `true`.
  final bool showChevron;

  /// Overrides the tile's inner padding. Defaults to a symmetric
  /// [BankTokens.space4] by [BankTokens.space3] inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the card fill. Defaults to [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the disc tint and icon colour. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the disc fill. Defaults to the accent colour at 12 % opacity.
  final Color? discColor;

  /// Optional gradient painted on the disc instead of a flat [discColor].
  final Gradient? discGradient;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard]; pass
  /// `const []` to flatten it.
  final List<BoxShadow>? shadow;

  /// Merged over the computed title style ([BankTokens.labelLarge] in
  /// [BankThemeData.onSurface]).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Overrides the trailing chevron glyph. Defaults to [Icons.chevron_right].
  final IconData? chevronIcon;

  /// Overrides the count badge fill. Defaults to the accent colour at 12 %
  /// opacity.
  final Color? countBadgeColor;

  /// Merged over the computed count badge text style ([BankTokens.labelMedium]
  /// in the accent colour).
  final TextStyle? countBadgeTextStyle;

  /// Replaces the tinted disc entirely (e.g. a brand illustration).
  final Widget? leading;

  /// Replaces the trailing count badge / chevron entirely.
  final Widget? trailing;

  /// Overrides the 48 px disc diameter.
  final double? discDiameter;

  /// Overrides the 24 px icon size inside the disc.
  final double? iconSize;

  /// Overrides the tile's 44 px minimum height.
  final double? minHeight;

  /// How the tile arranges its anatomy. Defaults to
  /// [BankProductCategoryTileLayout.auto], which stacks the tile below
  /// [compactBreakpoint] so titles keep their full width instead of
  /// ellipsizing next to the disc.
  final BankProductCategoryTileLayout layout;

  /// Width below which [BankProductCategoryTileLayout.auto] switches to
  /// the stacked vertical anatomy. Defaults to
  /// [BankTokens.tileCompactBreakpoint].
  final double? compactBreakpoint;

  /// Maximum title lines. Defaults to 1 in the horizontal anatomy and 2
  /// in the vertical anatomy.
  final int? titleMaxLines;

  /// Maximum subtitle lines. Defaults to 1 in the horizontal anatomy and
  /// 2 in the vertical anatomy.
  final int? subtitleMaxLines;

  /// Overrides the computed semantics label (title, subtitle, and count).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final accent = accentColor ?? theme.primary;
    final cardRadius = radius ?? theme.cardRadius;

    final countText =
        count == null ? null : scope.numeralStyle.convert(count.toString());

    final label = semanticLabel ??
        [
          title,
          if (subtitle != null) subtitle!,
          if (countText != null) countText,
        ].join(', ');

    // Explicit layouts build their anatomy directly (no LayoutBuilder), so
    // they keep intrinsic-dimension support for IntrinsicHeight hosts;
    // `auto` measures the available width and picks per tile.
    final content = switch (layout) {
      BankProductCategoryTileLayout.horizontal =>
        _buildHorizontal(theme, accent, countText),
      BankProductCategoryTileLayout.vertical =>
        _buildVertical(theme, accent, countText),
      BankProductCategoryTileLayout.auto => LayoutBuilder(
          builder: (context, constraints) {
            final breakpoint =
                compactBreakpoint ?? BankTokens.tileCompactBreakpoint;
            final compact = constraints.maxWidth.isFinite &&
                constraints.maxWidth < breakpoint;
            return compact
                ? _buildVertical(theme, accent, countText)
                : _buildHorizontal(theme, accent, countText);
          },
        ),
    };

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.surface,
            borderRadius: cardRadius,
            boxShadow: shadow ?? BankTokens.shadowCard,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: cardRadius,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight ?? BankTokens.minTapTarget,
                ),
                child: Padding(
                  padding: padding ??
                      const EdgeInsetsDirectional.symmetric(
                        horizontal: BankTokens.space4,
                        vertical: BankTokens.space3,
                      ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The classic single-row anatomy: disc, text column, trailing badge.
  Widget _buildHorizontal(
    BankThemeData theme,
    Color accent,
    String? countText,
  ) {
    return Row(
      children: [
        leading ??
            _buildDisc(
              theme,
              accent,
              fallbackDiameter: 48,
              fallbackIconSize: 24,
            ),
        const SizedBox(width: BankTokens.space3),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(theme, maxLines: titleMaxLines ?? 1),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                _buildSubtitle(theme, maxLines: subtitleMaxLines ?? 1),
              ],
            ],
          ),
        ),
        const SizedBox(width: BankTokens.space2),
        _buildTrailing(theme, accent, countText),
      ],
    );
  }

  /// Stacked compact anatomy: disc and badge on a header row, then title
  /// and subtitle at full tile width.
  Widget _buildVertical(
    BankThemeData theme,
    Color accent,
    String? countText,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                _buildDisc(
                  theme,
                  accent,
                  fallbackDiameter: 40,
                  fallbackIconSize: 20,
                ),
            const Spacer(),
            _buildTrailing(theme, accent, countText),
          ],
        ),
        const SizedBox(height: BankTokens.space3),
        _buildTitle(theme, maxLines: titleMaxLines ?? 2),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          _buildSubtitle(theme, maxLines: subtitleMaxLines ?? 2),
        ],
      ],
    );
  }

  Widget _buildTitle(BankThemeData theme, {required int maxLines}) {
    return Text(
      title,
      style: BankTokens.labelLarge.copyWith(color: theme.onSurface).merge(
            titleStyle,
          ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(BankThemeData theme, {required int maxLines}) {
    return Text(
      subtitle!,
      style: BankTokens.bodySmall
          .copyWith(color: theme.onSurfaceVariant)
          .merge(subtitleStyle),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDisc(
    BankThemeData theme,
    Color accent, {
    required double fallbackDiameter,
    required double fallbackIconSize,
  }) {
    final diameter = discDiameter ?? fallbackDiameter;
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: discGradient == null
              ? (discColor ?? accent.withValues(alpha: 0.12))
              : null,
          gradient: discGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: iconSize ?? fallbackIconSize, color: accent),
        ),
      ),
    );
  }

  Widget _buildTrailing(
    BankThemeData theme,
    Color accent,
    String? countText,
  ) {
    if (trailing != null) return trailing!;
    if (countText != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: countBadgeColor ?? accent.withValues(alpha: 0.12),
          borderRadius: theme.chipRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space2,
            vertical: 2,
          ),
          child: Text(
            countText,
            style: BankTokens.labelMedium
                .copyWith(color: accent)
                .merge(countBadgeTextStyle),
          ),
        ),
      );
    }
    if (!showChevron) return const SizedBox.shrink();
    return Icon(
      chevronIcon ?? Icons.chevron_right,
      color: theme.onSurfaceVariant,
    );
  }
}
