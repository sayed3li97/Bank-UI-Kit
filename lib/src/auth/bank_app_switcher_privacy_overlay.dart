import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// BankAppSwitcherPrivacyOverlay
// ---------------------------------------------------------------------------

/// Blurs or redacts sensitive content when the app loses foreground focus,
/// for example when the system app-switcher (recent-apps) is open.
///
/// Wrap around the [Scaffold] body or any widget that contains sensitive
/// financial data. The overlay activates when [AppLifecycleState] becomes
/// [AppLifecycleState.inactive] or [AppLifecycleState.paused].
///
/// **Blur mode** (default: when [placeholder] is `null`): the [child] is
/// covered by a `sigma 12` Gaussian blur and a `Colors.black26` dark scrim.
///
/// **Placeholder mode** (when [placeholder] is non-null): the [child] is
/// replaced entirely by [placeholder].
///
/// The overlay fades in and out with a 200 ms [AnimatedOpacity] transition to
/// avoid jarring cuts.
///
/// ```dart
/// BankAppSwitcherPrivacyOverlay(
///   child: Scaffold(
///     body: DashboardBody(),
///   ),
/// )
/// ```
class BankAppSwitcherPrivacyOverlay extends StatefulWidget {
  /// The widget tree to protect.
  final Widget child;

  /// Whether the overlay is active. Defaults to `true`. Set to `false` to
  /// disable the overlay entirely (e.g. on non-sensitive screens) without
  /// removing the widget from the tree.
  final bool enabled;

  /// When non-null, replaces the [child] entirely when the overlay is active.
  /// When null, a blurred-and-dimmed version of the child is shown instead.
  final Widget? placeholder;

  /// Overrides the Gaussian blur sigma in blur mode. Defaults to `12`.
  final double? blurSigma;

  /// Overrides the dark scrim painted over the blurred child in blur mode.
  /// Defaults to [Colors.black26].
  final Color? scrimColor;

  /// Overrides the fade in/out duration. Defaults to 200 ms.
  final Duration? animationDuration;

  /// Overrides the fade in/out curve. Defaults to [Curves.easeInOut].
  final Curve? animationCurve;

  const BankAppSwitcherPrivacyOverlay({
    required this.child,
    super.key,
    this.enabled = true,
    this.placeholder,
    this.blurSigma,
    this.scrimColor,
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<BankAppSwitcherPrivacyOverlay> createState() =>
      _BankAppSwitcherPrivacyOverlayState();
}

class _BankAppSwitcherPrivacyOverlayState
    extends State<BankAppSwitcherPrivacyOverlay> with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    final shouldObscure = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused;
    if (shouldObscure != _obscured) {
      setState(() => _obscured = shouldObscure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _obscured;
    final resolvedDuration =
        widget.animationDuration ?? const Duration(milliseconds: 200);
    final resolvedCurve = widget.animationCurve ?? Curves.easeInOut;

    if (widget.placeholder != null) {
      // Placeholder mode: cross-fade between child and placeholder.
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          AnimatedOpacity(
            opacity: active ? 1.0 : 0.0,
            duration: resolvedDuration,
            curve: resolvedCurve,
            // Absorb pointer events only when visible to avoid blocking the
            // child during fade-out.
            child: IgnorePointer(
              ignoring: !active,
              child: widget.placeholder,
            ),
          ),
        ],
      );
    }

    // Blur mode: apply ImageFilter + dark scrim over the existing child.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        // Pointer absorber prevents interaction with the child while obscured.
        if (active) const Positioned.fill(child: AbsorbPointer()),
        AnimatedOpacity(
          opacity: active ? 1.0 : 0.0,
          duration: resolvedDuration,
          curve: resolvedCurve,
          child: IgnorePointer(
            ignoring: !active,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma ?? 12,
                  sigmaY: widget.blurSigma ?? 12,
                ),
                child: Container(
                  color: widget.scrimColor ?? Colors.black26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
