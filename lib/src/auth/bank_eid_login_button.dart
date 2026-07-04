import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankEidAuthState
// ---------------------------------------------------------------------------

/// The externally driven phase of a national eID sign-in flow rendered by
/// [BankEidLoginButton].
enum BankEidAuthState {
  /// Nothing in flight: the branded sign-in button is shown.
  idle,

  /// A push request was sent to the eID provider app; the user must approve
  /// it there.
  awaitingApproval,

  /// The provider requires number matching: the user picks the two-digit
  /// number shown in the provider app (the Nafath pattern).
  numberMatch,

  /// The provider approved the sign-in.
  approved,

  /// The sign-in failed, timed out, or was rejected.
  failed,
}

// ---------------------------------------------------------------------------
// BankEidLoginButton
// ---------------------------------------------------------------------------

/// National eID authentication button with a number-match prompt.
///
/// Covers the sign-in pattern used with national identity schemes such
/// as Nafath, Singpass, and UAE Pass: the app starts an
/// authentication request with the national
/// identity provider, the user approves it in the provider's own app, and,
/// for providers such as Nafath, confirms by picking the two-digit number
/// displayed in the provider app from 2-3 candidates shown here.
///
/// The widget is fully state driven: the host owns the flow and rebuilds
/// with a new [state]. No network or platform calls happen inside.
///
/// Per-state rendering (every state keeps a 48 px minimum height):
/// - [BankEidAuthState.idle]: full-width branded button on
///   [BankThemeData.surface] with an outline border, showing [providerMark]
///   (if any) and [providerLabel]. Tapping fires [onPressed].
/// - [BankEidAuthState.awaitingApproval]: a pulsing waiting panel with
///   [awaitingApprovalText], an optional countdown derived from [timeout],
///   and a cancel link when [onCancel] is set. The pulse is disabled when
///   the platform requests reduced motion.
/// - [BankEidAuthState.numberMatch]: shows [numberMatchInstruction] and a
///   row of large tappable tiles, one per entry in [matchNumbers]. Tapping
///   a tile fires [onNumberPicked] and highlights the tile: with
///   [correctNumber] provided, a matching pick tints positive and a
///   mismatch tints danger; without it the pick tints with the brand
///   primary.
/// - [BankEidAuthState.approved]: positive check confirmation panel.
/// - [BankEidAuthState.failed]: danger panel with a retry button (fires
///   [onPressed]) and an optional cancel link.
///
/// ```dart
/// BankEidLoginButton(
///   providerLabel: 'Sign in with Nafath',
///   providerMark: Image.asset('assets/nafath.png', width: 24),
///   state: authCubit.state.eidState,
///   matchNumbers: const ['17', '42', '83'],
///   correctNumber: '42',
///   timeout: const Duration(seconds: 90),
///   onPressed: authCubit.startEidSignIn,
///   onNumberPicked: authCubit.confirmMatchNumber,
///   onCancel: authCubit.cancelEidSignIn,
/// )
/// ```
class BankEidLoginButton extends StatefulWidget {
  /// Branded call to action, e.g. `'Sign in with Nafath'`.
  final String providerLabel;

  /// Current phase of the authentication flow.
  final BankEidAuthState state;

  /// Called when the idle button, or the retry button in the failed state,
  /// is tapped.
  final VoidCallback onPressed;

  /// Optional provider logo shown before [providerLabel] in the idle state.
  final Widget? providerMark;

  /// Candidate two-digit numbers for the number-match step, e.g.
  /// `['17', '42', '83']`. Required (non-empty) whenever [state] is
  /// [BankEidAuthState.numberMatch].
  final List<String>? matchNumbers;

  /// The number actually displayed in the provider app, when known to the
  /// host. Used only to tint the picked tile as correct or incorrect; the
  /// widget never blocks a pick based on it.
  final String? correctNumber;

  /// Called with the tapped candidate number during the number-match step.
  final void Function(String picked)? onNumberPicked;

  /// Shows a cancel link in the awaiting-approval, number-match and failed
  /// states when non-null.
  final VoidCallback? onCancel;

  /// Total time the user has to approve in the provider app. When set, the
  /// awaiting-approval state shows a live countdown. Expiry is not acted
  /// on here: the host is expected to move [state] to
  /// [BankEidAuthState.failed].
  final Duration? timeout;

  /// Copy shown while waiting for approval in the provider app.
  final String awaitingApprovalText;

  /// Copy shown above the number-match tiles.
  final String numberMatchInstruction;

  /// Copy shown in the approved state.
  final String approvedText;

  /// Copy shown in the failed state.
  final String failedText;

  /// Label of the retry button in the failed state.
  final String retryLabel;

  /// Label of the cancel link.
  final String cancelLabel;

  /// Overrides the content padding of every state surface. Defaults to
  /// the per-state [BankTokens] spacing used today.
  final EdgeInsetsGeometry? padding;

  /// Overrides the corner radius of every state surface. Defaults to
  /// [BankThemeData.buttonRadius].
  final BorderRadius? radius;

  /// Overrides the idle button and waiting-panel background. Defaults to
  /// [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the primary text colour. Defaults to
  /// [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Overrides the waiting shield and picked-tile accent. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Overrides the outline colour of the idle button, panels, and unpicked
  /// tiles. Defaults to [BankThemeData.outline].
  final Color? borderColor;

  /// Overrides the positive colour of the approved state and a correct
  /// number pick. Defaults to [BankThemeData.positiveBalance].
  final Color? successColor;

  /// Overrides the danger colour of the failed state and a wrong number
  /// pick. Defaults to [BankTokens.danger].
  final Color? dangerColor;

  /// Overrides the waiting glyph. Defaults to [BankIcons.shield].
  final IconData? awaitingIcon;

  /// Overrides the approved glyph. Defaults to [BankIcons.success].
  final IconData? approvedIcon;

  /// Overrides the failed glyph. Defaults to [BankIcons.error].
  final IconData? failedIcon;

  /// Merged over the computed [providerLabel] and [approvedText] styles
  /// ([BankTokens.labelLarge]).
  final TextStyle? labelStyle;

  /// Merged over the computed body copy style ([BankTokens.bodyMedium]).
  final TextStyle? bodyStyle;

  /// Merged over the computed countdown style
  /// ([BankThemeData.numeralMedium]).
  final TextStyle? countdownStyle;

  /// Merged over the computed number-tile style
  /// ([BankThemeData.numeralLarge]).
  final TextStyle? numberStyle;

  /// Overrides the state cross-fade duration. Defaults to
  /// [BankTokens.durationBase].
  final Duration? animationDuration;

  /// Overrides the state cross-fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides one pulse cycle of the waiting shield. Defaults to
  /// [BankTokens.durationXSlow].
  final Duration? pulseDuration;

  /// Overrides the minimum height of every state surface. Defaults to
  /// [minControlHeight].
  final double? minHeight;

  /// Semantics prefix announced before a match number. Defaults to
  /// `'Match number'`.
  final String matchNumberSemanticPrefix;

  const BankEidLoginButton({
    required this.providerLabel,
    required this.state,
    required this.onPressed,
    super.key,
    this.providerMark,
    this.matchNumbers,
    this.correctNumber,
    this.onNumberPicked,
    this.onCancel,
    this.timeout,
    this.awaitingApprovalText = 'Approve the request in the provider app',
    this.numberMatchInstruction = 'Select the number shown in the provider app',
    this.approvedText = 'Identity verified',
    this.failedText = 'Authentication failed',
    this.retryLabel = 'Try again',
    this.cancelLabel = 'Cancel',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.borderColor,
    this.successColor,
    this.dangerColor,
    this.awaitingIcon,
    this.approvedIcon,
    this.failedIcon,
    this.labelStyle,
    this.bodyStyle,
    this.countdownStyle,
    this.numberStyle,
    this.animationDuration,
    this.animationCurve,
    this.pulseDuration,
    this.minHeight,
    this.matchNumberSemanticPrefix = 'Match number',
  }) : assert(
          state != BankEidAuthState.numberMatch || matchNumbers != null,
          'matchNumbers is required in the numberMatch state',
        );

  /// Minimum height of every state's control surface, per the eID
  /// provider guidelines (larger than [BankTokens.minTapTarget]).
  static const double minControlHeight = 48;

  @override
  State<BankEidLoginButton> createState() => _BankEidLoginButtonState();
}

class _BankEidLoginButtonState extends State<BankEidLoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  Timer? _countdownTimer;
  Duration? _remaining;
  String? _picked;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration ?? BankTokens.durationXSlow,
      value: 1,
    );
    _pulse = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: BankTokens.curveStandard,
      ),
    );
    _syncCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _syncPulse();
  }

  @override
  void didUpdateWidget(BankEidLoginButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseDuration != oldWidget.pulseDuration) {
      _pulseController.duration =
          widget.pulseDuration ?? BankTokens.durationXSlow;
    }
    if (widget.state != oldWidget.state ||
        widget.matchNumbers != oldWidget.matchNumbers) {
      _picked = null;
    }
    if (widget.state != oldWidget.state ||
        widget.timeout != oldWidget.timeout) {
      _syncCountdown();
    }
    _syncPulse();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pulse & countdown plumbing
  // ---------------------------------------------------------------------------

  void _syncPulse() {
    final shouldPulse =
        widget.state == BankEidAuthState.awaitingApproval && !_reduceMotion;
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 1;
    }
  }

  void _syncCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (widget.state == BankEidAuthState.awaitingApproval &&
        widget.timeout != null) {
      _remaining = widget.timeout;
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        _onCountdownTick,
      );
    } else {
      _remaining = null;
    }
  }

  void _onCountdownTick(Timer timer) {
    final current = _remaining;
    if (current == null) {
      timer.cancel();
      return;
    }
    final next = current - const Duration(seconds: 1);
    setState(() => _remaining = next.isNegative ? Duration.zero : next);
    if (next <= Duration.zero) timer.cancel();
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _pickNumber(String number) {
    if (_picked != null) return;
    setState(() => _picked = number);
    widget.onNumberPicked?.call(number);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  double get _minHeight =>
      widget.minHeight ?? BankEidLoginButton.minControlHeight;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final switchCurve = widget.animationCurve ?? BankTokens.curveStandard;

    return AnimatedSwitcher(
      duration: _reduceMotion
          ? Duration.zero
          : widget.animationDuration ?? BankTokens.durationBase,
      switchInCurve: switchCurve,
      switchOutCurve: switchCurve,
      child: KeyedSubtree(
        key: ValueKey<BankEidAuthState>(widget.state),
        child: switch (widget.state) {
          BankEidAuthState.idle => _buildIdle(theme),
          BankEidAuthState.awaitingApproval => _buildAwaitingApproval(theme),
          BankEidAuthState.numberMatch => _buildNumberMatch(theme),
          BankEidAuthState.approved => _buildApproved(theme),
          BankEidAuthState.failed => _buildFailed(theme),
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // idle
  // ---------------------------------------------------------------------------

  Widget _buildIdle(BankThemeData theme) {
    final resolvedRadius = widget.radius ?? theme.buttonRadius;
    return Semantics(
      button: true,
      label: widget.providerLabel,
      child: Material(
        color: widget.backgroundColor ?? theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: resolvedRadius,
          side: BorderSide(color: widget.borderColor ?? theme.outline),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: resolvedRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _minHeight,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsetsDirectional.symmetric(
                    horizontal: BankTokens.space4,
                    vertical: BankTokens.space3,
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.providerMark != null) ...[
                    widget.providerMark!,
                    const SizedBox(width: BankTokens.space3),
                  ],
                  Flexible(
                    child: Text(
                      widget.providerLabel,
                      style: BankTokens.labelLarge
                          .copyWith(
                            color: widget.foregroundColor ?? theme.onSurface,
                          )
                          .merge(widget.labelStyle),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // awaitingApproval
  // ---------------------------------------------------------------------------

  Widget _buildAwaitingApproval(BankThemeData theme) {
    final remaining = _remaining;

    return Semantics(
      container: true,
      label: widget.awaitingApprovalText,
      child: _StatePanel(
        theme: theme,
        backgroundColor: widget.backgroundColor,
        borderColor: widget.borderColor,
        radius: widget.radius,
        padding: widget.padding,
        minHeight: _minHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _pulse,
                  child: Icon(
                    widget.awaitingIcon ?? BankIcons.shield,
                    color: widget.accentColor ?? theme.primary,
                    size: BankTokens.space6,
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Flexible(
                  child: Text(
                    widget.awaitingApprovalText,
                    style: BankTokens.bodyMedium
                        .copyWith(
                          color: widget.foregroundColor ?? theme.onSurface,
                        )
                        .merge(widget.bodyStyle),
                  ),
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: BankTokens.space2),
              Text(
                _formatRemaining(remaining),
                style: theme.numeralMedium
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(widget.countdownStyle),
              ),
            ],
            if (widget.onCancel != null) ...[
              const SizedBox(height: BankTokens.space2),
              _buildCancelLink(theme),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // numberMatch
  // ---------------------------------------------------------------------------

  Widget _buildNumberMatch(BankThemeData theme) {
    final numbers = widget.matchNumbers ?? const <String>[];

    return Semantics(
      container: true,
      label: widget.numberMatchInstruction,
      child: _StatePanel(
        theme: theme,
        backgroundColor: widget.backgroundColor,
        borderColor: widget.borderColor,
        radius: widget.radius,
        padding: widget.padding,
        minHeight: _minHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.numberMatchInstruction,
              style: BankTokens.bodyMedium
                  .copyWith(color: widget.foregroundColor ?? theme.onSurface)
                  .merge(widget.bodyStyle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BankTokens.space4),
            Row(
              children: [
                for (var i = 0; i < numbers.length; i++) ...[
                  if (i > 0) const SizedBox(width: BankTokens.space3),
                  Expanded(child: _buildNumberTile(theme, numbers[i])),
                ],
              ],
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: BankTokens.space3),
              _buildCancelLink(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumberTile(BankThemeData theme, String number) {
    final isPicked = _picked == number;
    final hasVerdict = widget.correctNumber != null;
    final isCorrectPick = isPicked && widget.correctNumber == number;

    final positive = widget.successColor ?? theme.positiveBalance;
    final danger = widget.dangerColor ?? BankTokens.danger;
    final accent = widget.accentColor ?? theme.primary;
    final resolvedRadius = widget.radius ?? theme.buttonRadius;

    final Color background;
    final Color foreground;
    final Color border;
    if (isPicked && hasVerdict && isCorrectPick) {
      background = positive.withValues(alpha: 0.14);
      foreground = positive;
      border = positive;
    } else if (isPicked && hasVerdict) {
      background = danger.withValues(alpha: 0.1);
      foreground = danger;
      border = danger;
    } else if (isPicked) {
      background = accent;
      foreground = theme.onPrimary;
      border = accent;
    } else {
      background = theme.surfaceVariant;
      foreground = widget.foregroundColor ?? theme.onSurface;
      border = widget.borderColor ?? theme.outline;
    }

    return Semantics(
      button: true,
      selected: isPicked,
      label: '${widget.matchNumberSemanticPrefix} $number',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: resolvedRadius,
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: _picked == null ? () => _pickNumber(number) : null,
          borderRadius: resolvedRadius,
          child: SizedBox(
            height: BankTokens.space16,
            child: Center(
              child: Text(
                number,
                style: theme.numeralLarge
                    .copyWith(color: foreground)
                    .merge(widget.numberStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // approved
  // ---------------------------------------------------------------------------

  Widget _buildApproved(BankThemeData theme) {
    final positive = widget.successColor ?? theme.positiveBalance;
    return Semantics(
      container: true,
      label: widget.approvedText,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: positive.withValues(alpha: 0.12),
          borderRadius: widget.radius ?? theme.buttonRadius,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _minHeight,
            minWidth: double.infinity,
          ),
          child: Padding(
            padding: widget.padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.approvedIcon ?? BankIcons.success,
                  color: positive,
                  size: BankTokens.space6,
                ),
                const SizedBox(width: BankTokens.space3),
                Flexible(
                  child: Text(
                    widget.approvedText,
                    style: BankTokens.labelLarge
                        .copyWith(color: positive)
                        .merge(widget.labelStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // failed
  // ---------------------------------------------------------------------------

  Widget _buildFailed(BankThemeData theme) {
    final danger = widget.dangerColor ?? BankTokens.danger;
    return Semantics(
      container: true,
      label: widget.failedText,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.08),
          borderRadius: widget.radius ?? theme.buttonRadius,
          border: Border.all(
            color: danger.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: widget.padding ??
              const EdgeInsetsDirectional.all(BankTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.failedIcon ?? BankIcons.error,
                    color: danger,
                    size: BankTokens.space6,
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Flexible(
                    child: Text(
                      widget.failedText,
                      style: BankTokens.bodyMedium
                          .copyWith(
                            color: widget.foregroundColor ?? theme.onSurface,
                          )
                          .merge(widget.bodyStyle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space3),
              Semantics(
                button: true,
                label: widget.retryLabel,
                child: FilledButton(
                  onPressed: widget.onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: const Color(0xFFFFFFFF),
                    minimumSize: Size(double.infinity, _minHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: widget.radius ?? theme.buttonRadius,
                    ),
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(widget.retryLabel),
                ),
              ),
              if (widget.onCancel != null) ...[
                const SizedBox(height: BankTokens.space1),
                _buildCancelLink(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _buildCancelLink(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.cancelLabel,
      child: TextButton(
        onPressed: widget.onCancel,
        style: TextButton.styleFrom(
          foregroundColor: theme.onSurfaceVariant,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space3,
          ),
          textStyle: BankTokens.labelMedium,
        ),
        child: Text(widget.cancelLabel),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatePanel
// ---------------------------------------------------------------------------

/// Shared outlined surface used by the awaiting-approval and number-match
/// states of [BankEidLoginButton].
class _StatePanel extends StatelessWidget {
  final BankThemeData theme;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? padding;
  final double minHeight;

  const _StatePanel({
    required this.theme,
    required this.child,
    required this.minHeight,
    this.backgroundColor,
    this.borderColor,
    this.radius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: radius ?? theme.buttonRadius,
        border: Border.all(color: borderColor ?? theme.outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding:
              padding ?? const EdgeInsetsDirectional.all(BankTokens.space4),
          child: child,
        ),
      ),
    );
  }
}
