import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// How a bank app bar sizes and places its title block.
enum BankAppBarTitleMode {
  /// One toolbar row: the title on a single line with [BankAppBar.subtitle]
  /// beneath it as a supporting line.
  ///
  /// The only mode that fits inside a stock [kToolbarHeight] bar, and the
  /// default everywhere so existing screens keep their height.
  standard,

  /// Two tiers: the toolbar row keeps the leading action and the actions,
  /// while the title drops onto its own full-width row underneath at
  /// [BankTokens.headlineLarge].
  ///
  /// The title then aligns to the screen margin rather than to the leading
  /// action, which is what makes a large title read as a page heading instead
  /// of a wide toolbar label.
  large,

  /// [large] that shrinks into a compact centred title as content scrolls
  /// under it — the platform large-title pattern.
  ///
  /// Only [BankSliverAppBar] can collapse: a [Scaffold.appBar] is a sibling of
  /// the body and never sees its scroll position, so on [BankAppBar] this
  /// renders as [large].
  collapsing,
}

/// A themed [AppBar] that reads colours, type, and elevation from
/// [BankThemeData].
///
/// The title block is a two-level hierarchy: the title carries the page, and
/// [subtitle] is a supporting line under it — never a second title. Sizes come
/// from the type tokens, so a screen opens with a heading rather than a label:
///
/// - [BankAppBarTitleMode.standard] — title at [BankTokens.headlineMedium];
/// - [BankAppBarTitleMode.large] — title at [BankTokens.headlineLarge];
/// - the subtitle is [BankTokens.labelLarge] in
///   [BankThemeData.onSurfaceVariant] in both.
///
/// Both lines ellipsize at one line: an app bar has a fixed height, so a long
/// title must lose characters rather than push the toolbar out of shape.
///
/// The bar also suppresses the Material 3 surface tint so it stays a solid
/// brand colour, and uses [BankThemeData.elevationLow] for shadow depth.
///
/// ```dart
/// BankAppBar(
///   title: 'Accounts',
///   subtitle: 'Sara Ahmed',
///   actions: [
///     IconButton(icon: Icon(Icons.search_rounded), onPressed: () {}),
///   ],
/// )
/// ```
///
/// For the collapsing large-title pattern use [BankSliverAppBar] inside a
/// [CustomScrollView].
class BankAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BankAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.bottom,
    this.titleStyle,
    this.subtitleStyle,
    this.elevation,
    this.shadowColor,
    this.toolbarHeight,
    this.titleMode = BankAppBarTitleMode.standard,
    this.largeTitleHeight,
  });

  /// Primary app-bar heading.
  final String? title;

  /// Optional supporting line rendered below [title].
  final String? subtitle;

  final Widget? leading;
  final List<Widget>? actions;

  /// Overrides [BankThemeData.surface] as the background colour.
  final Color? backgroundColor;

  /// Overrides [BankThemeData.onSurface] as the foreground colour.
  final Color? foregroundColor;

  /// Centres the title block. Ignored in [BankAppBarTitleMode.large], where
  /// the title owns its own row and always starts at the screen margin.
  final bool centerTitle;

  /// Optional tab bar or search bar attached below the toolbar.
  final PreferredSizeWidget? bottom;

  /// Merged over the computed [title] style (see the table on [BankAppBar]).
  final TextStyle? titleStyle;

  /// Merged over the computed [subtitle] style ([BankTokens.labelLarge] at
  /// w500 in [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Overrides [BankThemeData.elevationLow] as the bar elevation.
  final double? elevation;

  /// Overrides [BankThemeData.outline] as the elevation shadow colour.
  final Color? shadowColor;

  /// Overrides [kToolbarHeight] as the toolbar height.
  final double? toolbarHeight;

  /// How the title block is sized and placed. Defaults to
  /// [BankAppBarTitleMode.standard].
  final BankAppBarTitleMode titleMode;

  /// Overrides the height of the large-title tier.
  ///
  /// The default is derived from the token metrics of the two lines, because
  /// [preferredSize] has to answer without a [BuildContext] and therefore
  /// cannot consult [MediaQuery.textScalerOf] — the same trade Material makes
  /// for its own large app bar. Raise it for hosts that ship a very large
  /// accessibility text scale; the tier clips rather than overflowing the body.
  final double? largeTitleHeight;

  bool get _showsLargeTier =>
      titleMode != BankAppBarTitleMode.standard && title != null;

  double get _largeTierExtent => _showsLargeTier
      ? largeTitleHeight ??
          _largeTitleTierExtent(
            hasSubtitle: subtitle != null,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
          )
      : 0;

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) +
            _largeTierExtent +
            (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;
    final fg = foregroundColor ?? theme.onSurface;
    final large = _showsLargeTier;

    final block = title == null
        ? null
        : _BankAppBarTitleBlock(
            title: title!,
            subtitle: subtitle,
            titleStyle: _bankAppBarTitleStyle(
              theme,
              fg,
              large ? BankTokens.headlineLarge : BankTokens.headlineMedium,
            ).merge(titleStyle),
            subtitleStyle: _bankAppBarSubtitleStyle(theme).merge(subtitleStyle),
            centred: !large && centerTitle,
          );

    return AppBar(
      leading: leading,
      title: large ? null : block,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: elevation ?? theme.elevationLow,
      shadowColor: shadowColor ?? theme.outline,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      bottom: large
          ? _BankLargeTitleTier(
              height: _largeTierExtent,
              bottom: bottom,
              // The tier lives outside AppBar's title slot, which is what
              // normally contributes the heading to the semantics tree.
              child: Semantics(header: true, child: block),
            )
          : bottom,
    );
  }
}

// ---------------------------------------------------------------------------
// BankSliverAppBar
// ---------------------------------------------------------------------------

/// The [BankAppBar] title hierarchy as a sliver, with the collapsing
/// large-title pattern.
///
/// In [BankAppBarTitleMode.collapsing] (the default here) the bar opens with
/// the large title anchored to its bottom edge and, as content scrolls under
/// it, the large title scales down and fades out while a compact centred
/// title fades into the toolbar row. Exactly one of the two is in the
/// semantics tree at a time, so the heading is announced once.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     BankSliverAppBar(title: 'Accounts', subtitle: 'Sara Ahmed'),
///     SliverList.list(children: accountTiles),
///   ],
/// )
/// ```
///
/// Pass [titleMode] to opt out: [BankAppBarTitleMode.standard] gives a plain
/// pinned bar, and [BankAppBarTitleMode.large] keeps the large title without
/// the hand-off, so it simply scrolls away.
class BankSliverAppBar extends StatelessWidget {
  const BankSliverAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle,
    this.bottom,
    this.titleStyle,
    this.subtitleStyle,
    this.collapsedTitleStyle,
    this.elevation,
    this.shadowColor,
    this.toolbarHeight,
    this.titleMode = BankAppBarTitleMode.collapsing,
    this.largeTitleHeight,
    this.expandedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
  });

  /// Primary app-bar heading.
  final String? title;

  /// Optional supporting line rendered below [title] while expanded.
  final String? subtitle;

  /// Leading action of the toolbar row.
  final Widget? leading;

  /// Whether to imply a leading back button when [leading] is null.
  final bool automaticallyImplyLeading;

  /// Trailing actions of the toolbar row. They stay in the toolbar at every
  /// collapse position, so they never travel with the large title.
  final List<Widget>? actions;

  /// Overrides [BankThemeData.surface] as the background colour.
  final Color? backgroundColor;

  /// Overrides [BankThemeData.onSurface] as the foreground colour.
  final Color? foregroundColor;

  /// Alignment of the compact toolbar title. Defaults to `true` in
  /// [BankAppBarTitleMode.collapsing] — the large title hands off to a centred
  /// compact title — and `false` otherwise.
  final bool? centerTitle;

  /// Optional tab bar or search bar attached below the toolbar. It stays
  /// pinned with the toolbar, so the large title is inset above it.
  final PreferredSizeWidget? bottom;

  /// Merged over the computed expanded-title style.
  final TextStyle? titleStyle;

  /// Merged over the computed [subtitle] style.
  final TextStyle? subtitleStyle;

  /// Merged over the computed collapsed-title style
  /// ([BankTokens.headlineSmall] at w700).
  final TextStyle? collapsedTitleStyle;

  /// Overrides [BankThemeData.elevationLow] as the bar elevation.
  final double? elevation;

  /// Overrides [BankThemeData.outline] as the elevation shadow colour.
  final Color? shadowColor;

  /// Overrides [kToolbarHeight] as the collapsed toolbar height.
  final double? toolbarHeight;

  /// How the title block is sized and placed. Defaults to
  /// [BankAppBarTitleMode.collapsing].
  final BankAppBarTitleMode titleMode;

  /// Overrides the height of the large-title tier. See
  /// [BankAppBar.largeTitleHeight].
  final double? largeTitleHeight;

  /// Overrides the fully-expanded bar height. Defaults to the toolbar, the
  /// large-title tier, and [bottom] stacked.
  final double? expandedHeight;

  /// Whether the collapsed toolbar stays on screen. Defaults to `true`: a
  /// collapsing large title needs somewhere to land.
  final bool pinned;

  /// Whether the bar reappears as soon as the user scrolls back up, rather
  /// than only at the top of the list.
  final bool floating;

  /// Whether a [floating] bar snaps fully open or closed when the scroll ends.
  final bool snap;

  /// Whether the bar stretches past its expanded height on overscroll.
  final bool stretch;

  bool get _showsLargeTier =>
      titleMode != BankAppBarTitleMode.standard && title != null;

  bool get _collapses =>
      titleMode == BankAppBarTitleMode.collapsing && title != null;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = backgroundColor ?? theme.surface;
    final fg = foregroundColor ?? theme.onSurface;
    final large = _showsLargeTier;

    final toolbarExtent = toolbarHeight ?? kToolbarHeight;
    final bottomExtent = bottom?.preferredSize.height ?? 0;
    final tierExtent = large
        ? largeTitleHeight ??
            _largeTitleTierExtent(
              hasSubtitle: subtitle != null,
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
            )
        : 0.0;

    final resolvedSubtitleStyle =
        _bankAppBarSubtitleStyle(theme).merge(subtitleStyle);
    final expandedTitleStyle = _bankAppBarTitleStyle(
      theme,
      fg,
      large ? BankTokens.headlineLarge : BankTokens.headlineMedium,
    ).merge(titleStyle);
    final compactTitleStyle =
        _bankAppBarTitleStyle(theme, fg, BankTokens.headlineSmall)
            .merge(large ? collapsedTitleStyle : titleStyle);

    // A `large` bar that never hands off has no compact title at all: its
    // heading simply scrolls away with the tier.
    Widget? compact;
    if (title != null && (!large || _collapses)) {
      compact = _BankAppBarTitleBlock(
        title: title!,
        subtitle: large ? null : subtitle,
        titleStyle: compactTitleStyle,
        subtitleStyle: resolvedSubtitleStyle,
        centred: centerTitle ?? _collapses,
      );
      if (_collapses) {
        compact = _BankCollapsedTitle(child: compact);
      }
    }

    return SliverAppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: compact,
      centerTitle: centerTitle ?? _collapses,
      actions: actions,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: elevation ?? theme.elevationLow,
      shadowColor: shadowColor ?? theme.outline,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarExtent,
      expandedHeight:
          expandedHeight ?? toolbarExtent + tierExtent + bottomExtent,
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      bottom: bottom,
      // The tier carries its own header semantics; without this AppBar wraps
      // the whole flexible space in a second, unlabelled header node.
      excludeHeaderSemantics: large && compact == null,
      flexibleSpace: large
          ? _BankExpandedTitle(
              bottomInset: bottomExtent,
              collapses: _collapses,
              // Scaling to the compact size instead of re-laying-out the text
              // keeps the hand-off off the layout path on every scroll frame.
              collapsedScale: (compactTitleStyle.fontSize ?? 18) /
                  (expandedTitleStyle.fontSize ?? 28),
              child: _BankAppBarTitleBlock(
                title: title!,
                subtitle: subtitle,
                titleStyle: expandedTitleStyle,
                subtitleStyle: resolvedSubtitleStyle,
                centred: false,
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared type resolution
// ---------------------------------------------------------------------------

/// Title ink for [base] in the brand's display voice.
///
/// The title sits in a headline slot, so it takes
/// [BankThemeData.displayFontFamily] when the brand pairs an expressive
/// display face with a workhorse body face, and falls back to the body family.
TextStyle _bankAppBarTitleStyle(
  BankThemeData theme,
  Color foreground,
  TextStyle base,
) =>
    base.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
      fontFamily: theme.displayFontFamily ?? theme.fontFamily,
    );

/// The supporting line under a title: same optical weight class as a list
/// tile's secondary line, so it reads as support rather than a second title.
TextStyle _bankAppBarSubtitleStyle(BankThemeData theme) =>
    BankTokens.labelLarge.copyWith(
      color: theme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFamily: theme.fontFamily,
    );

/// Vertical extent of one line of [base] with [override] merged over it.
double _lineExtent(TextStyle base, TextStyle? override) {
  final size = override?.fontSize ?? base.fontSize ?? 14;
  final height = override?.height ?? base.height ?? 1.2;
  return size * height;
}

/// Natural height of the large-title tier: breathing room, the title line, the
/// optional supporting line, and the gap that anchors the block to the bottom
/// edge of the bar.
double _largeTitleTierExtent({
  required bool hasSubtitle,
  required TextStyle? titleStyle,
  required TextStyle? subtitleStyle,
}) =>
    BankTokens.space2 +
    _lineExtent(BankTokens.headlineLarge, titleStyle) +
    (hasSubtitle
        ? BankTokens.space1 + _lineExtent(BankTokens.labelLarge, subtitleStyle)
        : 0) +
    BankTokens.space3;

/// Collapse progress published by the enclosing [SliverAppBar]: `0` fully
/// expanded, `1` fully collapsed.
double _collapseProgress(BuildContext context) {
  final settings =
      context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
  if (settings == null) return 0;
  final range = settings.maxExtent - settings.minExtent;
  if (range <= 0) return 1;
  return ((settings.maxExtent - settings.currentExtent) / range)
      .clamp(0.0, 1.0);
}

/// Collapse progress at which the heading changes hands.
///
/// Both titles cross-fade around it, but the semantics switch is a hard cut so
/// a screen reader never finds the same heading twice mid-scroll.
const double _titleHandoff = 0.55;

// ---------------------------------------------------------------------------
// Title block
// ---------------------------------------------------------------------------

/// The title plus its supporting line, as one block.
class _BankAppBarTitleBlock extends StatelessWidget {
  const _BankAppBarTitleBlock({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.centred,
  });

  final String title;
  final String? subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final bool centred;

  @override
  Widget build(BuildContext context) {
    final align = centred ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment:
          centred ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: titleStyle,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: BankTokens.space1),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Large-title tier (non-scrolling)
// ---------------------------------------------------------------------------

/// The second tier of a [BankAppBarTitleMode.large] bar, stacked above any
/// caller-supplied [bottom].
class _BankLargeTitleTier extends StatelessWidget
    implements PreferredSizeWidget {
  const _BankLargeTitleTier({
    required this.height,
    required this.child,
    required this.bottom,
  });

  final double height;
  final Widget child;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              BankTokens.space4,
              BankTokens.space2,
              BankTokens.space4,
              BankTokens.space3,
            ),
            // The tier height is computed from unscaled token metrics, so a
            // very large accessibility text scale can outgrow it. An
            // OverflowBox lets the block take the height it needs (no
            // RenderFlex overflow) and the clip keeps it off the body.
            child: ClipRect(
              child: OverflowBox(
                alignment: AlignmentDirectional.bottomStart,
                // A tight incoming height would otherwise be handed straight
                // through as the child's *minimum*, and the block would stop
                // shrink-wrapping — which is what the bottom anchor needs.
                minHeight: 0,
                maxHeight: double.infinity,
                child: child,
              ),
            ),
          ),
        ),
        if (bottom != null) bottom!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsing large title
// ---------------------------------------------------------------------------

/// The expanded large title, anchored to the bottom edge of the bar and handed
/// off to the compact title as the bar collapses.
class _BankExpandedTitle extends StatelessWidget {
  const _BankExpandedTitle({
    required this.child,
    required this.bottomInset,
    required this.collapses,
    required this.collapsedScale,
  });

  final Widget child;

  /// Height of the pinned [SliverAppBar.bottom], which the title sits above.
  final double bottomInset;

  final bool collapses;

  /// Scale the block reaches at full collapse — the ratio of the compact title
  /// size to the expanded one.
  final double collapsedScale;

  @override
  Widget build(BuildContext context) {
    final t = collapses ? _collapseProgress(context) : 0.0;
    // Fade out slightly ahead of the hand-off so the two titles never both
    // read at full strength.
    final opacity = (1 - t / _titleHandoff).clamp(0.0, 1.0);
    final scale = 1 - (1 - collapsedScale) * t;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        BankTokens.space4,
        0,
        BankTokens.space4,
        bottomInset + BankTokens.space3,
      ),
      // Once collapsed, the bar is shorter than the block; an OverflowBox
      // keeps that from being a RenderFlex overflow, and the clip keeps the
      // (by then invisible) block off the toolbar.
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.bottomStart,
          minHeight: 0,
          maxHeight: double.infinity,
          child: ExcludeSemantics(
            excluding: t >= _titleHandoff,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                alignment: AlignmentDirectional.bottomStart,
                child: Semantics(header: true, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The compact toolbar title of a collapsing bar: absent until the large title
/// has handed over.
class _BankCollapsedTitle extends StatelessWidget {
  const _BankCollapsedTitle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = _collapseProgress(context);
    final opacity = ((t - _titleHandoff) / (1 - _titleHandoff)).clamp(0.0, 1.0);

    return ExcludeSemantics(
      excluding: t < _titleHandoff,
      child: Opacity(opacity: opacity, child: child),
    );
  }
}
