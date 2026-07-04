import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The connectivity condition a [BankConnectivityBanner] communicates.
enum BankConnectivityStatus {
  /// The user's own device has no network connection.
  deviceOffline,

  /// The device is online but one or more bank-side services are degraded.
  serviceDegraded,

  /// Connectivity was just restored; shown transiently, then auto-dismissed.
  reconnected,
}

/// Persistent, non-blocking degraded-state banner that sits above content
/// (typically directly under the app bar) while the rest of the app stays
/// usable: partial degradation never gets a full-screen gate.
///
/// Driven by [BankConnectivityStatus], it distinguishes the user's own
/// connection being down ([BankConnectivityStatus.deviceOffline], neutral
/// [BankThemeData.surfaceVariant] background), a bank-side problem
/// ([BankConnectivityStatus.serviceDegraded], [BankTokens.warning] tint and
/// a 3 px warning start border), and a transient success state
/// ([BankConnectivityStatus.reconnected], positive tint) that fades out
/// after [reconnectedDisplayDuration] and then calls [onDismissed].
/// The offline and degraded variants never auto-dismiss and expose no close
/// button, because the condition, not the user, ends them.
///
/// Optional extras:
/// - [lastSyncedAt] renders a staleness line using
///   [BankDateFormatter.formatRelative], escalating to
///   [BankDateFormatter.formatLong] plus a [BankTokens.warning] colour and a
///   [BankIcons.warning] adornment once older than [staleThreshold], so age
///   is never signalled by colour alone.
/// - [onRetry] shows a compact "Try now" button; [nextRetryAt] drives an
///   in-place auto-retry countdown ticked by a one-second [Timer] computed
///   against [clock]. When it reaches zero the widget calls [onAutoRetry]
///   once and shows [retryingLabel] with a small progress indicator until
///   the parent swaps [status] or [nextRetryAt]. Reschedule policy (backoff,
///   jitter, caps) stays entirely with the host; [retriesExhausted] switches
///   the retry area to [retriesExhaustedLabel] as the terminal state.
/// - [onViewStatus] renders an underlined link for the degraded variant,
///   pointing to the in-app service status list or status page.
///
/// The banner animates in with a height-plus-fade transition; when
/// [MediaQuery.disableAnimationsOf] is `true` all transitions run at
/// [Duration.zero], though the reconnected variant still waits
/// [reconnectedDisplayDuration] before calling [onDismissed]. Status
/// transitions are announced once via a live region, while per-second
/// countdown text is excluded from semantics and mirrored by a coarse
/// label that only changes on 10-second boundaries.
///
/// The widget renders no money and performs no connectivity detection:
/// status, timestamps, and retry scheduling are injected, keeping it a
/// pure presentation component.
///
/// ```dart
/// BankConnectivityBanner(
///   status: BankConnectivityStatus.serviceDegraded,
///   message: 'Bank transfers are delayed right now. '
///       'Card payments are working normally.',
///   lastSyncedAt: lastSuccessfulSync,
///   nextRetryAt: DateTime.now().add(const Duration(seconds: 15)),
///   onRetry: () => bloc.add(RefreshNowEvent()),
///   onAutoRetry: () => bloc.add(AutoRefreshEvent()),
///   onViewStatus: () => navigator.push(ServiceStatusRoute()),
/// )
/// ```
class BankConnectivityBanner extends StatefulWidget {
  /// The connectivity condition to display.
  final BankConnectivityStatus status;

  /// Title text. Defaults to a per-status English title.
  final String? title;

  /// Optional supporting message, e.g. 'Bank transfers are delayed right
  /// now. Card payments are working normally.'.
  final String? message;

  /// When non-null, renders a staleness line telling the user how old the
  /// data on screen is.
  final DateTime? lastSyncedAt;

  /// Age beyond which the staleness line escalates to a warning colour,
  /// a [BankIcons.warning] adornment, and an absolute timestamp.
  final Duration staleThreshold;

  /// Prefix for the staleness line. Defaults to 'Showing info from '.
  final String lastSyncedPrefix;

  /// Called when the user taps the manual retry button. The button is
  /// omitted when `null`.
  final VoidCallback? onRetry;

  /// Label for the manual retry button. Defaults to 'Try now'.
  final String retryLabel;

  /// When non-null, drives the in-place auto-retry countdown.
  final DateTime? nextRetryAt;

  /// Called exactly once when the [nextRetryAt] countdown reaches zero.
  final VoidCallback? onAutoRetry;

  /// Label shown with a progress indicator while an auto retry is in
  /// flight. Defaults to 'Retrying...'.
  final String retryingLabel;

  /// When `true`, the retry area shows [retriesExhaustedLabel] with no
  /// countdown: the terminal state after capped attempts.
  final bool retriesExhausted;

  /// Label for the exhausted-retries state. Defaults to
  /// "We'll keep trying in the background".
  final String retriesExhaustedLabel;

  /// Formats the countdown text from whole seconds remaining. Defaults to
  /// 'Retrying in {seconds}s'.
  final String Function(int secondsRemaining)? formatRetryCountdown;

  /// Called when the user taps the underlined status link. The link is
  /// only rendered for [BankConnectivityStatus.serviceDegraded].
  final VoidCallback? onViewStatus;

  /// Label for the status link. Defaults to 'View status'.
  final String viewStatusLabel;

  /// How long the reconnected variant stays visible before fading out.
  final Duration reconnectedDisplayDuration;

  /// Called after the reconnected variant has finished fading out.
  final VoidCallback? onDismissed;

  /// Clock used for countdown and staleness computations. Defaults to
  /// [DateTime.now]; injectable for deterministic tests and screenshots.
  final DateTime Function()? clock;

  /// Overrides the content padding. Defaults to
  /// [BankTokens.space4] horizontal by [BankTokens.space3] vertical.
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the banner. Defaults to none.
  final EdgeInsetsGeometry? margin;

  /// Overrides the container radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the per-status background colour.
  final Color? backgroundColor;

  /// Overrides the text colour (title and body).
  final Color? foregroundColor;

  /// Overrides the per-status accent used by the icon, the degraded start
  /// border, and the retry progress indicator.
  final Color? accentColor;

  /// Overrides the per-status leading glyph.
  final IconData? statusIcon;

  /// Merged over the computed [BankTokens.labelLarge] title style.
  final TextStyle? titleStyle;

  /// Merged over the computed [BankTokens.bodySmall] message style.
  final TextStyle? messageStyle;

  /// Overrides the entry/exit animation duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the entry/exit animation curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides the live-region semantic label on the banner container.
  final String? semanticLabel;

  const BankConnectivityBanner({
    required this.status,
    super.key,
    this.title,
    this.message,
    this.lastSyncedAt,
    this.staleThreshold = const Duration(hours: 1),
    this.lastSyncedPrefix = 'Showing info from ',
    this.onRetry,
    this.retryLabel = 'Try now',
    this.nextRetryAt,
    this.onAutoRetry,
    this.retryingLabel = 'Retrying...',
    this.retriesExhausted = false,
    this.retriesExhaustedLabel = "We'll keep trying in the background",
    this.formatRetryCountdown,
    this.onViewStatus,
    this.viewStatusLabel = 'View status',
    this.reconnectedDisplayDuration = const Duration(seconds: 4),
    this.onDismissed,
    this.clock,
    this.padding,
    this.margin,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.statusIcon,
    this.titleStyle,
    this.messageStyle,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  @override
  State<BankConnectivityBanner> createState() => _BankConnectivityBannerState();
}

class _BankConnectivityBannerState extends State<BankConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late CurvedAnimation _entryAnimation;

  Timer? _ticker;
  Timer? _dismissTimer;
  bool _autoRetrying = false;
  bool _entryStarted = false;
  bool _disableAnimations = false;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  Duration get _resolvedDuration => _disableAnimations
      ? Duration.zero
      : widget.animationDuration ?? BankTokens.durationBase;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? BankTokens.durationBase,
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: widget.animationCurve ?? BankTokens.curveStandard,
    );
    if (widget.status == BankConnectivityStatus.reconnected) {
      _scheduleDismiss();
    }
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
    _entryController.duration = _resolvedDuration;
    if (!_entryStarted) {
      _entryStarted = true;
      _entryController.forward();
    }
  }

  @override
  void didUpdateWidget(BankConnectivityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animationDuration != oldWidget.animationDuration) {
      _entryController.duration = _resolvedDuration;
    }
    if (widget.animationCurve != oldWidget.animationCurve) {
      _entryAnimation.dispose();
      _entryAnimation = CurvedAnimation(
        parent: _entryController,
        curve: widget.animationCurve ?? BankTokens.curveStandard,
      );
    }

    if (widget.nextRetryAt != oldWidget.nextRetryAt) {
      _autoRetrying = false;
    }
    if (widget.status != oldWidget.status) {
      _autoRetrying = false;
      _dismissTimer?.cancel();
      _dismissTimer = null;
      if (widget.status == BankConnectivityStatus.reconnected) {
        _scheduleDismiss();
      } else {
        _entryController.forward();
      }
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _dismissTimer?.cancel();
    _entryAnimation.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Timers
  // ---------------------------------------------------------------------

  bool get _countdownActive =>
      widget.nextRetryAt != null && !widget.retriesExhausted && !_autoRetrying;

  void _syncTicker() {
    final needsTicker = _countdownActive || widget.lastSyncedAt != null;
    if (needsTicker) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), _tick);
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick(Timer timer) {
    if (!mounted) return;
    var fired = false;
    final next = widget.nextRetryAt;
    if (next != null &&
        !widget.retriesExhausted &&
        !_autoRetrying &&
        !next.isAfter(_now())) {
      _autoRetrying = true;
      fired = true;
    }
    setState(() {});
    if (fired) {
      widget.onAutoRetry?.call();
      _syncTicker();
    }
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.reconnectedDisplayDuration, _beginDismiss);
  }

  void _beginDismiss() {
    if (!mounted) return;
    _entryController.reverse().whenComplete(() {
      if (mounted) widget.onDismissed?.call();
    });
  }

  // ---------------------------------------------------------------------
  // Per-status defaults
  // ---------------------------------------------------------------------

  String get _defaultTitle => switch (widget.status) {
        BankConnectivityStatus.deviceOffline => "You're offline",
        BankConnectivityStatus.serviceDegraded => 'Some services are affected',
        BankConnectivityStatus.reconnected =>
          'Back online. Your accounts are up to date.',
      };

  IconData get _defaultIcon => switch (widget.status) {
        BankConnectivityStatus.deviceOffline => Icons.cloud_off_outlined,
        BankConnectivityStatus.serviceDegraded => BankIcons.warning,
        BankConnectivityStatus.reconnected => BankIcons.success,
      };

  Color _defaultAccent(BankThemeData theme) => switch (widget.status) {
        BankConnectivityStatus.deviceOffline => theme.onSurfaceVariant,
        BankConnectivityStatus.serviceDegraded => BankTokens.warning,
        BankConnectivityStatus.reconnected => theme.positiveBalance,
      };

  Color _defaultBackground(BankThemeData theme, Color accent) =>
      switch (widget.status) {
        BankConnectivityStatus.deviceOffline => theme.surfaceVariant,
        BankConnectivityStatus.serviceDegraded =>
          accent.withValues(alpha: 0.12),
        BankConnectivityStatus.reconnected => accent.withValues(alpha: 0.12),
      };

  String _countdownText(int seconds) =>
      widget.formatRetryCountdown?.call(seconds) ?? 'Retrying in ${seconds}s';

  // ---------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------

  Widget? _buildStalenessLine(Color bodyColor) {
    final lastSynced = widget.lastSyncedAt;
    if (lastSynced == null) return null;

    final now = _now();
    final isStale = now.difference(lastSynced) > widget.staleThreshold;
    final formatted = isStale
        ? BankDateFormatter.formatLong(lastSynced)
        : BankDateFormatter.formatRelative(lastSynced, now: now);
    final text = '${widget.lastSyncedPrefix}$formatted';
    final color = isStale ? BankTokens.warning : bodyColor;
    final icon = isStale ? BankIcons.warning : BankIcons.schedule;

    // Relative-time text updates every tick; expose a single coarse label
    // that only changes when the formatted string itself changes.
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: BankTokens.space1),
            Flexible(
              child: Text(
                text,
                style: BankTokens.bodySmall.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRetryLine(Color accent, Color bodyColor) {
    if (widget.retriesExhausted) {
      return Text(
        widget.retriesExhaustedLabel,
        style: BankTokens.bodySmall.copyWith(color: bodyColor),
      );
    }
    final next = widget.nextRetryAt;
    if (next == null) return null;

    if (_autoRetrying) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
          const SizedBox(width: BankTokens.space2),
          Flexible(
            child: Text(
              widget.retryingLabel,
              style: BankTokens.bodySmall.copyWith(color: bodyColor),
            ),
          ),
        ],
      );
    }

    final millis = next.difference(_now()).inMilliseconds;
    final seconds = millis <= 0 ? 0 : (millis / 1000).ceil();
    // Coarse bucket so screen readers are not re-announced every second:
    // the parallel label only changes on 10-second boundaries.
    final bucket = seconds <= 0 ? 0 : ((seconds + 9) ~/ 10) * 10;

    return Semantics(
      label: _countdownText(bucket),
      child: ExcludeSemantics(
        child: Text(
          _countdownText(seconds),
          style: BankTokens.bodySmall.copyWith(color: bodyColor),
        ),
      ),
    );
  }

  Widget _buildRetryButton(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.retryLabel,
      child: TextButton(
        onPressed: widget.onRetry,
        style: TextButton.styleFrom(
          foregroundColor: theme.primary,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space2,
          ),
          textStyle: BankTokens.labelMedium,
        ),
        child: Text(widget.retryLabel),
      ),
    );
  }

  Widget _buildViewStatusLink(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.viewStatusLabel,
      child: TextButton(
        onPressed: widget.onViewStatus,
        style: TextButton.styleFrom(
          foregroundColor: theme.onSurfaceVariant,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space2,
          ),
          textStyle: BankTokens.labelMedium,
        ),
        child: Text(
          widget.viewStatusLabel,
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final accent = widget.accentColor ?? _defaultAccent(theme);
    final background =
        widget.backgroundColor ?? _defaultBackground(theme, accent);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedPadding = widget.padding ??
        const EdgeInsetsDirectional.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space3,
        );
    final titleColor = widget.foregroundColor ?? theme.onSurface;
    final bodyColor = widget.foregroundColor ?? theme.onSurfaceVariant;
    final resolvedTitleStyle = BankTokens.labelLarge
        .copyWith(color: titleColor)
        .merge(widget.titleStyle);
    final resolvedMessageStyle = BankTokens.bodySmall
        .copyWith(color: bodyColor)
        .merge(widget.messageStyle);

    final stalenessLine = _buildStalenessLine(bodyColor);
    final retryLine = _buildRetryLine(accent, bodyColor);

    final showRetry = widget.onRetry != null;
    final showViewStatus =
        widget.status == BankConnectivityStatus.serviceDegraded &&
            widget.onViewStatus != null;

    Widget banner = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: resolvedRadius,
        border: widget.status == BankConnectivityStatus.serviceDegraded
            ? BorderDirectional(
                start: BorderSide(color: accent, width: 3),
              )
            : null,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.statusIcon ?? _defaultIcon,
              color: accent,
              size: 24,
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? _defaultTitle,
                    style: resolvedTitleStyle,
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    Text(widget.message!, style: resolvedMessageStyle),
                  ],
                  if (stalenessLine != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    stalenessLine,
                  ],
                  if (retryLine != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    retryLine,
                  ],
                ],
              ),
            ),
            if (showRetry || showViewStatus) ...[
              const SizedBox(width: BankTokens.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showRetry) _buildRetryButton(theme),
                  if (showViewStatus) _buildViewStatusLink(theme),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.margin != null) {
      banner = Padding(padding: widget.margin!, child: banner);
    }

    return SizeTransition(
      sizeFactor: _entryAnimation,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _entryAnimation,
        child: Semantics(
          container: true,
          liveRegion: true,
          label: widget.semanticLabel,
          child: banner,
        ),
      ),
    );
  }
}
