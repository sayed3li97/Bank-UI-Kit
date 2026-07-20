import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';

// -----------------------------------------------------------------------------
// Shared layout constants
// -----------------------------------------------------------------------------

const double _cardWidth = 92;
const double _cardHeight = 120;
const double _ringWidth = 2.5;
const double _ringGap = 2;
const double _ringInset = _ringWidth + _ringGap;
const double _progressBarHeight = 3;

// Story media is arbitrary (photos, illustrations, gradients), so the
// scrims and chrome are deliberately literal black/white rather than themed
// surface colours: they must stay legible over unknown content in both
// light and dark themes.
const Color _chromeForeground = Color(0xFFFFFFFF);
const Color _scrimStrong = Color(0xB3000000);
const Color _scrimSoft = Color(0xA6000000);
const Color _scrimTransparent = Color(0x00000000);
const Color _progressTrack = Color(0x4DFFFFFF);
const Color _viewerBackground = Color(0xFF000000);

// -----------------------------------------------------------------------------
// Model
// -----------------------------------------------------------------------------

/// A single story entry rendered by [BankStoriesCarousel] and
/// [BankStoryViewer].
///
/// The [thumbnail] and [content] fields are widget slots: the kit bundles no
/// image assets, so supply your own media (an `Image`, a gradient panel, a
/// video player, etc.). [thumbnail] is shown on the 92x120 rail card and
/// [content] fills the screen inside the viewer.
///
/// Note: equality compares [thumbnail] and [content] by widget identity
/// (operator ==), which is reference equality for non-const widgets.
@immutable
class BankStory {
  /// Creates an immutable story entry.
  const BankStory({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.content,
    this.unread = false,
  });

  /// Stable identifier reported through `onStoryViewed` callbacks.
  final String id;

  /// Short title shown on the rail card and in the viewer chrome.
  final String title;

  /// Widget shown inside the rail card (no bundled assets).
  final Widget thumbnail;

  /// Full-screen widget shown by [BankStoryViewer].
  final Widget content;

  /// Whether the story has not been viewed yet. Unread cards get a
  /// primary-coloured ring on the rail.
  final bool unread;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankStory &&
        other.id == id &&
        other.title == title &&
        other.thumbnail == thumbnail &&
        other.content == content &&
        other.unread == unread;
  }

  @override
  int get hashCode => Object.hash(id, title, thumbnail, content, unread);
}

// -----------------------------------------------------------------------------
// Rail
// -----------------------------------------------------------------------------

/// Horizontal rail of tappable story cards, in the style of the
/// stories feeds and daily-recap snapshots of leading banking apps.
///
/// Each card is 92x120 with the story thumbnail under a bottom scrim and the
/// title in [BankTokens.labelSmall]. Unread stories get a 2.5 px ring in the
/// theme primary colour. Tapping a card opens [BankStoryViewer] at that
/// story; [onStoryViewed] fires with each story id as it is shown.
///
/// Use it at the top of a home feed to surface product news, tips, and
/// personalised insights without pushing them into the transaction list.
///
/// ```dart
/// BankStoriesCarousel(
///   stories: [
///     BankStory(
///       id: 'cashback-boost',
///       title: 'Cashback boosted to 5%',
///       unread: true,
///       thumbnail: Image.asset('assets/cashback_thumb.png',
///           fit: BoxFit.cover),
///       content: CashbackStoryPage(),
///     ),
///   ],
///   onStoryViewed: (id) => analytics.storyViewed(id),
/// )
/// ```
class BankStoriesCarousel extends StatelessWidget {
  /// Creates a horizontal stories rail.
  const BankStoriesCarousel({
    required this.stories,
    super.key,
    this.onStoryViewed,
    this.autoAdvanceDuration = const Duration(seconds: 6),
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: BankTokens.space4,
    ),
    this.unreadSemanticLabel = 'Unread',
    this.closeLabel = 'Close',
    this.announcementBuilder,
    this.unreadRingColor,
    this.cardWidth,
    this.cardHeight,
    this.cardRadius,
    this.cardShadow,
    this.titleStyle,
    this.scrimGradient,
    this.closeIcon,
    this.viewerBackgroundColor,
    this.viewerForegroundColor,
    this.viewerProgressTrackColor,
  });

  /// The stories to display, in rail order.
  final List<BankStory> stories;

  /// Called with a story id each time that story is shown in the viewer.
  final ValueChanged<String>? onStoryViewed;

  /// How long the viewer displays each story before auto-advancing.
  final Duration autoAdvanceDuration;

  /// Outer padding of the rail list.
  final EdgeInsetsGeometry padding;

  /// Appended to a card's semantic label when the story is unread.
  final String unreadSemanticLabel;

  /// Semantic label and tooltip for the viewer's close button.
  final String closeLabel;

  /// Builds the screen-reader announcement made on each page change in the
  /// viewer. Defaults to an English `'<title>. Story <n> of <count>.'`.
  final String Function(BankStory story, int index, int count)?
      announcementBuilder;

  /// Overrides the unread ring colour. Defaults to [BankThemeData.primary].
  final Color? unreadRingColor;

  /// Overrides the 92 px width of each rail card.
  final double? cardWidth;

  /// Overrides the 120 px height of each rail card (the rail grows with it).
  final double? cardHeight;

  /// Overrides the card corner radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? cardRadius;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten it.
  final List<BoxShadow>? cardShadow;

  /// Merged over the computed card title style ([BankTokens.labelSmall]
  /// in white).
  final TextStyle? titleStyle;

  /// Overrides the bottom scrim painted behind the card title. Defaults to
  /// a transparent-to-black vertical gradient.
  final Gradient? scrimGradient;

  /// Overrides the viewer's close glyph. Defaults to [BankIcons.close].
  final IconData? closeIcon;

  /// Overrides the viewer's page background. Defaults to black.
  final Color? viewerBackgroundColor;

  /// Overrides the viewer's chrome colour (title, close button, progress
  /// fill). Defaults to white.
  final Color? viewerForegroundColor;

  /// Overrides the viewer's progress track colour. Defaults to white at
  /// 30 % opacity.
  final Color? viewerProgressTrackColor;

  void _openViewer(BuildContext context, int index) {
    BankStoryViewer.show(
      context,
      stories: stories,
      initialIndex: index,
      autoAdvanceDuration: autoAdvanceDuration,
      onStoryViewed: onStoryViewed,
      closeLabel: closeLabel,
      announcementBuilder: announcementBuilder,
      closeIcon: closeIcon,
      backgroundColor: viewerBackgroundColor,
      foregroundColor: viewerForegroundColor,
      progressTrackColor: viewerProgressTrackColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (cardHeight ?? _cardHeight) + 2 * _ringInset,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: stories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: BankTokens.space3),
        itemBuilder: (context, index) => _StoryCard(
          story: stories[index],
          unreadSemanticLabel: unreadSemanticLabel,
          onTap: () => _openViewer(context, index),
          ringColor: unreadRingColor,
          width: cardWidth,
          height: cardHeight,
          radius: cardRadius,
          shadow: cardShadow,
          titleStyle: titleStyle,
          scrimGradient: scrimGradient,
        ),
      ),
    );
  }
}

/// A single 92x120 rail card with thumbnail, bottom scrim, title, and an
/// unread ring.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.unreadSemanticLabel,
    required this.onTap,
    this.ringColor,
    this.width,
    this.height,
    this.radius,
    this.shadow,
    this.titleStyle,
    this.scrimGradient,
  });

  final BankStory story;
  final String unreadSemanticLabel;
  final VoidCallback onTap;
  final Color? ringColor;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final List<BoxShadow>? shadow;
  final TextStyle? titleStyle;
  final Gradient? scrimGradient;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final cardRadius = radius ?? theme.cardRadius;
    final outerRadius = cardRadius + BorderRadius.circular(_ringInset);
    final resolvedRingColor =
        story.unread ? (ringColor ?? theme.primary) : const Color(0x00000000);

    final semanticLabel =
        story.unread ? '${story.title}, $unreadSemanticLabel' : story.title;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_ringGap),
          decoration: BoxDecoration(
            borderRadius: outerRadius,
            border: Border.all(color: resolvedRingColor, width: _ringWidth),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: cardRadius,
              // Artwork surface: brightness-resolved shadow, no hairline.
              boxShadow: shadow ??
                  BankTokens.shadowCardFor(
                    ThemeData.estimateBrightnessForColor(theme.background),
                  ),
            ),
            child: ClipRRect(
              borderRadius: cardRadius,
              child: SizedBox(
                width: width ?? _cardWidth,
                height: height ?? _cardHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: theme.surfaceVariant,
                      child: story.thumbnail,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: scrimGradient ??
                            const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.45, 1],
                              colors: [_scrimTransparent, _scrimSoft],
                            ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Padding(
                        padding: const EdgeInsets.all(BankTokens.space2),
                        child: Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BankTokens.labelSmall
                              .copyWith(color: _chromeForeground)
                              .merge(titleStyle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Viewer
// -----------------------------------------------------------------------------

/// Full-screen story viewer with segmented auto-advance progress bars.
///
/// Usually opened by [BankStoriesCarousel], but can be pushed directly with
/// [BankStoryViewer.show]. Behaviour:
///
/// - A [PageView] shows each [BankStory.content] full screen.
/// - Segmented progress bars along the top fill over [autoAdvanceDuration]
///   (default 6 seconds); when a segment completes the viewer advances, and
///   after the last story it closes.
/// - Pressing and holding anywhere pauses the timer; releasing resumes it.
/// - Tapping the trailing third of the screen goes to the next story and the
///   leading third returns to the previous one (mirrored automatically for
///   right-to-left locales).
/// - Swiping down, or tapping the close button, dismisses the viewer.
/// - Auto-advance is disabled when [MediaQuery.disableAnimationsOf] reports
///   reduced motion; users then navigate by tap only.
/// - Page changes are announced to screen readers.
///
/// ```dart
/// BankStoryViewer.show(
///   context,
///   stories: stories,
///   initialIndex: 2,
///   onStoryViewed: (id) => repo.markStoryRead(id),
/// );
/// ```
class BankStoryViewer extends StatefulWidget {
  /// Creates a story viewer. Prefer [BankStoryViewer.show] to push it as a
  /// full-screen route.
  const BankStoryViewer({
    required this.stories,
    super.key,
    this.initialIndex = 0,
    this.autoAdvanceDuration = const Duration(seconds: 6),
    this.onStoryViewed,
    this.closeLabel = 'Close',
    this.announcementBuilder,
    this.closeIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.progressTrackColor,
    this.titleStyle,
    this.scrimGradient,
  });

  /// The stories to page through. Must not be empty.
  final List<BankStory> stories;

  /// Index of the story shown first. Clamped to the valid range.
  final int initialIndex;

  /// How long each story is displayed before auto-advancing.
  final Duration autoAdvanceDuration;

  /// Called with a story id each time that story is shown.
  final ValueChanged<String>? onStoryViewed;

  /// Semantic label and tooltip for the close button.
  final String closeLabel;

  /// Builds the screen-reader announcement made on each page change.
  /// Defaults to an English `'<title>. Story <n> of <count>.'`.
  final String Function(BankStory story, int index, int count)?
      announcementBuilder;

  /// Overrides the close button glyph. Defaults to [BankIcons.close].
  final IconData? closeIcon;

  /// Overrides the page background. Defaults to black.
  final Color? backgroundColor;

  /// Overrides the chrome colour (title, close button, progress fill).
  /// Defaults to white.
  final Color? foregroundColor;

  /// Overrides the progress track colour. Defaults to white at 30 %
  /// opacity.
  final Color? progressTrackColor;

  /// Merged over the computed title style ([BankTokens.labelLarge] in the
  /// chrome colour).
  final TextStyle? titleStyle;

  /// Overrides the scrim behind the top chrome. Defaults to a
  /// black-to-transparent vertical gradient.
  final Gradient? scrimGradient;

  /// Pushes a full-screen [BankStoryViewer] route with a fade transition.
  ///
  /// Returns a future that completes when the viewer is dismissed.
  static Future<void> show(
    BuildContext context, {
    required List<BankStory> stories,
    int initialIndex = 0,
    Duration autoAdvanceDuration = const Duration(seconds: 6),
    ValueChanged<String>? onStoryViewed,
    String closeLabel = 'Close',
    String Function(BankStory story, int index, int count)? announcementBuilder,
    IconData? closeIcon,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? progressTrackColor,
    TextStyle? titleStyle,
    Gradient? scrimGradient,
  }) {
    assert(stories.isNotEmpty, 'BankStoryViewer requires at least one story');
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: BankTokens.durationBase,
        reverseTransitionDuration: BankTokens.durationBase,
        pageBuilder: (context, animation, secondaryAnimation) =>
            BankStoryViewer(
          stories: stories,
          initialIndex: initialIndex,
          autoAdvanceDuration: autoAdvanceDuration,
          onStoryViewed: onStoryViewed,
          closeLabel: closeLabel,
          announcementBuilder: announcementBuilder,
          closeIcon: closeIcon,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          progressTrackColor: progressTrackColor,
          titleStyle: titleStyle,
          scrimGradient: scrimGradient,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<BankStoryViewer> createState() => _BankStoryViewerState();
}

class _BankStoryViewerState extends State<BankStoryViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final PageController _pageController;
  late int _index;
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.stories.isNotEmpty,
      'BankStoryViewer requires at least one story',
    );
    final maxIndex = widget.stories.length - 1;
    _index = widget.initialIndex < 0
        ? 0
        : (widget.initialIndex > maxIndex ? maxIndex : widget.initialIndex);
    _pageController = PageController(initialPage: _index);
    _progress = AnimationController(
      vsync: this,
      duration: widget.autoAdvanceDuration,
    )..addStatusListener(_onProgressStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStoryViewed?.call(widget.stories[_index].id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _progress.stop();
    } else if (!_started) {
      _started = true;
      _progress.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goNext();
  }

  void _pause() => _progress.stop();

  void _resume() {
    if (!_reduceMotion && !_progress.isAnimating) _progress.forward();
  }

  void _goNext() {
    if (_index < widget.stories.length - 1) {
      _goToPage(_index + 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrevious() {
    if (_index > 0) {
      _goToPage(_index - 1);
    } else if (!_reduceMotion) {
      _progress.forward(from: 0);
    }
  }

  void _goToPage(int page) {
    if (_reduceMotion) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: BankTokens.durationFast,
        curve: BankTokens.curveStandard,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _index = page);
    _progress.stop();
    _progress.value = 0;
    if (!_reduceMotion) _progress.forward();
    final story = widget.stories[page];
    widget.onStoryViewed?.call(story.id);
    final message =
        widget.announcementBuilder?.call(story, page, widget.stories.length) ??
            '${story.title}. Story ${page + 1} of ${widget.stories.length}.';
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _onTapUp(TapUpDetails details) {
    _resume();
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return;
    final dx = details.globalPosition.dx;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final onRightThird = dx > width * 2 / 3;
    final onLeftThird = dx < width / 3;
    final forward = isRtl ? onLeftThird : onRightThird;
    final backward = isRtl ? onRightThird : onLeftThird;
    if (forward) {
      _goNext();
    } else if (backward) {
      _goPrevious();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 200) {
      Navigator.of(context).pop();
    } else {
      _resume();
    }
  }

  Color get _foreground => widget.foregroundColor ?? _chromeForeground;

  Widget _buildSegment(int segmentIndex) {
    final Widget fill;
    if (segmentIndex == _index && !_reduceMotion) {
      fill = AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: _progress.value,
          child: child,
        ),
        child: ColoredBox(color: _foreground),
      );
    } else {
      // Segments before the current story are full, later ones empty.
      // Under reduced motion the current segment shows as full so the
      // bars still communicate position.
      final viewed =
          segmentIndex < _index || (segmentIndex == _index && _reduceMotion);
      fill = FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: viewed ? 1 : 0,
        child: ColoredBox(color: _foreground),
      );
    }

    return SizedBox(
      height: _progressBarHeight,
      child: ClipRRect(
        borderRadius:
            const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
        child: ColoredBox(
          color: widget.progressTrackColor ?? _progressTrack,
          child: fill,
        ),
      ),
    );
  }

  Widget _buildChrome(BuildContext context) {
    final count = widget.stories.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.scrimGradient ??
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_scrimStrong, _scrimTransparent],
            ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: BankTokens.space4,
            end: BankTokens.space2,
            top: BankTokens.space3,
            bottom: BankTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: BankTokens.space2,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: BankTokens.space1),
                      Expanded(child: _buildSegment(i)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: BankTokens.space2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.stories[_index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BankTokens.labelLarge
                          .copyWith(color: _foreground)
                          .merge(widget.titleStyle),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space2),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: widget.closeLabel,
                    color: _foreground,
                    constraints: const BoxConstraints(
                      minWidth: BankTokens.minTapTarget,
                      minHeight: BankTokens.minTapTarget,
                    ),
                    icon: Icon(widget.closeIcon ?? BankIcons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? _viewerBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _pause(),
        onTapUp: _onTapUp,
        onTapCancel: _resume,
        onLongPressStart: (details) => _pause(),
        onLongPressEnd: (details) => _resume(),
        onVerticalDragStart: (details) => _pause(),
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) => widget.stories[index].content,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildChrome(context),
            ),
          ],
        ),
      ),
    );
  }
}
