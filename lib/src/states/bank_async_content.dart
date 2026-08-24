import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/tokens.dart';
import 'bank_empty_state_view.dart';
import 'bank_error_state_view.dart';
import 'bank_skeleton_loader.dart';

/// Which of the four states a data-backed region is in.
///
/// Deliberately four rather than three: "no rows" and "the request failed" are
/// different truths for the customer, and collapsing them into one is how a
/// banking app ends up telling someone their account is empty when the network
/// is simply down.
enum BankAsyncStatus {
  /// The data has been requested and has not arrived.
  loading,

  /// The request failed. The customer needs to know *what* failed.
  error,

  /// The request succeeded and returned nothing.
  empty,

  /// The request succeeded and there is something to show.
  content,
}

/// Switches between the kit's loading, error, empty, and content surfaces for
/// one region of a screen.
///
/// This is the state-handling half of the kit: [BankSkeletonLoader] shapes the
/// wait, [BankErrorStateView] and [BankEmptyStateView] handle the two ways a
/// request can resolve to nothing, and this widget picks between them and
/// cross-fades. Without it every host re-implements the same four-way `if`,
/// and the two failure states are the ones that get skipped.
///
/// It is deliberately ignorant of the data layer: it takes a [status] and
/// builders, never a `Future` or a `Stream`. Whatever the host uses — a bloc, a
/// notifier, a `FutureBuilder` above it — maps onto a [BankAsyncStatus], and
/// nothing about that choice leaks into the kit.
///
/// Only the slots you use need copy. Reaching [BankAsyncStatus.error] without
/// either [errorBuilder] or an [errorTitle]/[errorMessage] pair asserts in
/// debug builds, because the kit refuses to invent a generic
/// "something went wrong" — see [BankErrorStateView].
///
/// Accessibility: a state change is announced to assistive technology via
/// [SemanticsService.sendAnnouncement]. A screen-reader user has no visual cue
/// that a region just swapped a skeleton for a list, so the transition is
/// spoken instead. Two deliberate limits: the first build is silent (arriving
/// on a screen that is loading is not a *change*), and nothing is sent on
/// platforms where [MediaQuery.supportsAnnounceOf] is false — Android
/// deprecated announcement events precisely because they flush TalkBack's
/// speech queue, and the state surfaces carry their own semantics anyway.
///
/// ```dart
/// BankAsyncContent(
///   status: switch (state) {
///     Loading() => BankAsyncStatus.loading,
///     Failed() => BankAsyncStatus.error,
///     Loaded(:final rows) when rows.isEmpty => BankAsyncStatus.empty,
///     _ => BankAsyncStatus.content,
///   },
///   skeletonVariant: BankSkeletonVariant.transactionTile,
///   skeletonCount: 6,
///   errorTitle: 'Transactions unavailable',
///   errorMessage: 'We could not reach your account. Please try again.',
///   onRetry: controller.reload,
///   emptyTitle: 'No transactions yet',
///   emptySubtitle: 'Your payments and transfers will appear here.',
///   contentBuilder: (context) => TransactionList(rows: state.rows),
/// )
/// ```
class BankAsyncContent extends StatefulWidget {
  /// Which surface to show.
  final BankAsyncStatus status;

  /// Builds the loaded content. Called only in [BankAsyncStatus.content], so
  /// it may assume the data is present.
  final WidgetBuilder contentBuilder;

  /// Replaces the default loading surface (a [BankSkeletonLoader] built from
  /// [skeletonVariant] and [skeletonCount]).
  final WidgetBuilder? loadingBuilder;

  /// Replaces the default error surface (a [BankErrorStateView] built from
  /// [errorTitle], [errorMessage], [onRetry], and [onContactSupport]).
  final WidgetBuilder? errorBuilder;

  /// Replaces the default empty surface (a [BankEmptyStateView] built from
  /// [emptyTitle], [emptySubtitle], [emptyIcon], and [onEmptyAction]).
  final WidgetBuilder? emptyBuilder;

  /// Shape of the default loading skeleton. Pick the variant that matches what
  /// [contentBuilder] will render, so the layout does not reflow on arrival.
  final BankSkeletonVariant skeletonVariant;

  /// How many skeleton tiles the default loading surface stacks.
  final int skeletonCount;

  /// Title of the default error surface. Required unless [errorBuilder] is
  /// supplied.
  final String? errorTitle;

  /// Specific explanation of the failure for the default error surface.
  /// Required unless [errorBuilder] is supplied.
  final String? errorMessage;

  /// Label of the default error surface's retry button.
  final String retryLabel;

  /// Retry callback. The retry button is omitted when `null`.
  final VoidCallback? onRetry;

  /// Label of the default error surface's support button.
  final String? supportLabel;

  /// Contact-support callback. The support button is omitted when `null`.
  final VoidCallback? onContactSupport;

  /// Title of the default empty surface. Required unless [emptyBuilder] is
  /// supplied.
  final String? emptyTitle;

  /// Supporting sentence on the default empty surface.
  final String? emptySubtitle;

  /// Glyph of the default empty surface's fallback illustration.
  final IconData? emptyIcon;

  /// Label of the default empty surface's call to action. Shown only alongside
  /// [onEmptyAction].
  final String? emptyActionLabel;

  /// Call-to-action callback on the default empty surface.
  final VoidCallback? onEmptyAction;

  /// Duration of the cross-fade between states. Defaults to
  /// [BankTokens.durationBase], and collapses to zero under
  /// [MediaQuery.disableAnimationsOf].
  final Duration? transitionDuration;

  /// Spoken when the region enters [BankAsyncStatus.loading]. Pass an empty
  /// string to stay silent.
  final String loadingAnnouncement;

  /// Spoken when the region enters [BankAsyncStatus.content].
  final String contentAnnouncement;

  /// Spoken when the region enters [BankAsyncStatus.error]. Defaults to
  /// [errorTitle].
  final String? errorAnnouncement;

  /// Spoken when the region enters [BankAsyncStatus.empty]. Defaults to
  /// [emptyTitle].
  final String? emptyAnnouncement;

  const BankAsyncContent({
    required this.status,
    required this.contentBuilder,
    super.key,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.skeletonVariant = BankSkeletonVariant.listTile,
    this.skeletonCount = 3,
    this.errorTitle,
    this.errorMessage,
    this.retryLabel = 'Retry',
    this.onRetry,
    this.supportLabel,
    this.onContactSupport,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.transitionDuration,
    this.loadingAnnouncement = 'Loading',
    this.contentAnnouncement = 'Content loaded',
    this.errorAnnouncement,
    this.emptyAnnouncement,
  });

  @override
  State<BankAsyncContent> createState() => _BankAsyncContentState();
}

class _BankAsyncContentState extends State<BankAsyncContent> {
  @override
  void didUpdateWidget(BankAsyncContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _announce();
  }

  /// Speaks the new state. Screen-reader users get no visual cue when a
  /// skeleton is replaced by a list, so the swap is announced instead of being
  /// left to whatever happens to take focus.
  void _announce() {
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    final message = switch (widget.status) {
      BankAsyncStatus.loading => widget.loadingAnnouncement,
      BankAsyncStatus.content => widget.contentAnnouncement,
      BankAsyncStatus.error => widget.errorAnnouncement ?? widget.errorTitle,
      BankAsyncStatus.empty => widget.emptyAnnouncement ?? widget.emptyTitle,
    };
    if (message == null || message.isEmpty) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : widget.transitionDuration ?? BankTokens.durationBase;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: BankTokens.curveStandard,
      switchOutCurve: BankTokens.curveStandard,
      // Keyed on the status alone: the four surfaces are distinct states of one
      // region, so the switcher must cross-fade between them even when two of
      // them happen to build the same widget type.
      child: KeyedSubtree(
        key: ValueKey<BankAsyncStatus>(widget.status),
        child: _surface(context),
      ),
    );
  }

  Widget _surface(BuildContext context) => switch (widget.status) {
        BankAsyncStatus.loading => _loading(context),
        BankAsyncStatus.error => _error(context),
        BankAsyncStatus.empty => _empty(context),
        BankAsyncStatus.content => widget.contentBuilder(context),
      };

  Widget _loading(BuildContext context) {
    final builder = widget.loadingBuilder;
    if (builder != null) return builder(context);
    return BankSkeletonLoader(
      variant: widget.skeletonVariant,
      count: widget.skeletonCount,
    );
  }

  Widget _error(BuildContext context) {
    final builder = widget.errorBuilder;
    if (builder != null) return builder(context);

    final title = widget.errorTitle;
    final message = widget.errorMessage;
    assert(
      title != null && message != null,
      'BankAsyncContent reached BankAsyncStatus.error without errorTitle and '
      'errorMessage (or an errorBuilder). The kit will not invent generic '
      'failure copy — say what failed and why.',
    );
    if (title == null || message == null) return const SizedBox.shrink();

    return BankErrorStateView(
      title: title,
      message: message,
      retryLabel: widget.retryLabel,
      supportLabel: widget.supportLabel,
      onRetry: widget.onRetry,
      onContactSupport: widget.onContactSupport,
    );
  }

  Widget _empty(BuildContext context) {
    final builder = widget.emptyBuilder;
    if (builder != null) return builder(context);

    final title = widget.emptyTitle;
    assert(
      title != null,
      'BankAsyncContent reached BankAsyncStatus.empty without emptyTitle '
      '(or an emptyBuilder). An unlabelled empty state is indistinguishable '
      'from a broken screen.',
    );
    if (title == null) return const SizedBox.shrink();

    return BankEmptyStateView(
      title: title,
      subtitle: widget.emptySubtitle,
      emptyIcon: widget.emptyIcon,
      actionLabel: widget.emptyActionLabel,
      onAction: widget.onEmptyAction,
    );
  }
}
