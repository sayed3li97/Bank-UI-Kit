import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One page of a [BankOnboardingCarousel].
class BankOnboardingPage {
  const BankOnboardingPage({
    required this.title,
    required this.body,
    required this.illustration,
    this.accentColor,
  });

  final String title;
  final String body;

  /// Illustration slot: the kit bundles no image assets.
  final Widget illustration;

  /// Overrides the theme primary for this page's active dot.
  final Color? accentColor;
}

/// First-run value-proposition walkthrough with parallax illustrations,
/// an animated pill dot indicator, and a Next button that morphs into
/// the done label on the last page.
///
/// Auto-advance (when enabled) pauses on user touch and is disabled
/// entirely under `MediaQuery.disableAnimations`.
///
/// ```dart
/// BankOnboardingCarousel(
///   pages: [
///     BankOnboardingPage(
///       title: 'Bank without borders',
///       body: 'Hold, send and exchange 30+ currencies in one place.',
///       illustration: MyIllustration(),
///     ),
///   ],
///   onDone: () => Navigator.of(context).pushReplacement(homeRoute),
/// )
/// ```
class BankOnboardingCarousel extends StatefulWidget {
  const BankOnboardingCarousel({
    required this.pages,
    required this.onDone,
    super.key,
    this.onSkip,
    this.doneLabel = 'Get started',
    this.nextLabel = 'Next',
    this.skipLabel = 'Skip',
    this.autoAdvance = false,
    this.autoAdvanceInterval = const Duration(seconds: 5),
  });

  final List<BankOnboardingPage> pages;

  /// Fired by the last page's primary button.
  final VoidCallback onDone;

  /// Shows a skip affordance on all but the last page when set.
  final VoidCallback? onSkip;

  final String doneLabel;
  final String nextLabel;
  final String skipLabel;

  /// Advances pages automatically; pauses while the user is touching.
  final bool autoAdvance;

  final Duration autoAdvanceInterval;

  @override
  State<BankOnboardingCarousel> createState() => _BankOnboardingCarouselState();
}

class _BankOnboardingCarouselState extends State<BankOnboardingCarousel> {
  final PageController _controller = PageController();
  int _page = 0;
  Timer? _autoTimer;
  bool _touching = false;

  bool get _isLast => _page == widget.pages.length - 1;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoTimer?.cancel();
    final animationsDisabled =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.autoAdvance && !animationsDisabled) {
      _autoTimer = Timer.periodic(widget.autoAdvanceInterval, (_) {
        if (_touching || !mounted) return;
        final next = _isLast ? 0 : _page + 1;
        unawaited(
          _controller.animateToPage(
            next,
            duration: BankTokens.durationSlow,
            curve: BankTokens.curveStandard,
          ),
        );
      });
    }
  }

  void _onNext() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: BankTokens.durationBase,
        curve: BankTokens.curveStandard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Listener(
      onPointerDown: (_) => _touching = true,
      onPointerUp: (_) => _touching = false,
      child: Column(
        children: [
          SizedBox(
            height: BankTokens.space12,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: (!_isLast && widget.onSkip != null)
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: BankTokens.space2,
                      ),
                      child: TextButton(
                        onPressed: widget.onSkip,
                        child: Text(
                          widget.skipLabel,
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.pages.length,
              onPageChanged: (index) {
                setState(() => _page = index);
                SemanticsService.announce(
                  'Page ${index + 1} of ${widget.pages.length}',
                  Directionality.of(context),
                );
              },
              itemBuilder: (context, index) => _ParallaxPage(
                page: widget.pages[index],
                controller: _controller,
                index: index,
                theme: theme,
              ),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          _DotIndicator(
            count: widget.pages.length,
            active: _page,
            color: widget.pages[_page].accentColor ?? theme.primary,
            inactiveColor: theme.outline,
          ),
          Padding(
            padding: const EdgeInsets.all(BankTokens.space5),
            child: SizedBox(
              width: double.infinity,
              height: BankTokens.space12,
              child: FilledButton(
                onPressed: _onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: BankTokens.durationBase,
                  child: Text(
                    _isLast ? widget.doneLabel : widget.nextLabel,
                    key: ValueKey<bool>(_isLast),
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallaxPage extends StatelessWidget {
  const _ParallaxPage({
    required this.page,
    required this.controller,
    required this.index,
    required this.theme,
  });

  final BankOnboardingPage page;
  final PageController controller;
  final int index;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BankTokens.space6),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                var offset = 0.0;
                if (controller.position.haveDimensions) {
                  offset = ((controller.page ?? 0) - index) *
                      -0.5 *
                      MediaQuery.sizeOf(context).width;
                }
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Center(child: page.illustration),
            ),
          ),
          Text(
            page.title,
            style: BankTokens.headlineLarge.copyWith(color: theme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BankTokens.space3),
          Text(
            page.body,
            style:
                BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BankTokens.space4),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.active,
    required this.color,
    required this.inactiveColor,
  });

  final int count;
  final int active;
  final Color color;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: BankTokens.durationBase,
            curve: BankTokens.curveStandard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? color : inactiveColor,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
      ],
    );
  }
}
