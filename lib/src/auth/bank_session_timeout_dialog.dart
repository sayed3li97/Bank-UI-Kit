import 'dart:async';

import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankSessionTimeoutDialog
// ---------------------------------------------------------------------------

/// A modal dialog that counts down from [remainingTime] and fires [onLogout]
/// when it reaches zero.
///
/// Show via `showDialog` and provide the same [onExtend] / [onLogout] callbacks
/// that the dialog buttons use:
///
/// ```dart
/// showDialog<void>(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => BankSessionTimeoutDialog(
///     remainingTime: const Duration(seconds: 30),
///     onExtend: () {
///       Navigator.of(context).pop();
///       _resetSessionTimer();
///     },
///     onLogout: () {
///       Navigator.of(context).pop();
///       _signOut();
///     },
///   ),
/// );
/// ```
///
/// The countdown text is marked as a `liveRegion` so screen readers announce
/// the changing value. The timer is automatically cancelled on `dispose`.
class BankSessionTimeoutDialog extends StatefulWidget {
  /// How much time remains before the session expires. The countdown starts
  /// from this value and decrements by one second every tick.
  final Duration remainingTime;

  /// Called when the user taps the primary action ("Stay Logged In").
  /// The host app is responsible for dismissing the dialog and resetting any
  /// external session timers.
  final VoidCallback onExtend;

  /// Called either when the user taps the secondary action ("Log Out") or
  /// when the countdown reaches zero. The host app is responsible for
  /// dismissing the dialog and navigating to the login screen.
  final VoidCallback onLogout;

  /// Dialog title. Defaults to `'Session Expiring'`.
  final String title;

  /// Dialog body text shown above the countdown. Defaults to a generic
  /// session-expiry message.
  final String body;

  /// Label for the primary (extend) button. Defaults to `'Stay Logged In'`.
  final String extendLabel;

  /// Label for the secondary (logout) button. Defaults to `'Log Out'`.
  final String logoutLabel;

  /// Content padding inside the dialog. Defaults to [BankTokens.space6] on
  /// all sides when null.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the dialog. Defaults to the theme `cardRadius` when
  /// null.
  final BorderRadius? radius;

  /// Background color of the dialog surface. Defaults to the theme `surface`
  /// when null.
  final Color? backgroundColor;

  /// Text style merged over the computed title style (headline small in the
  /// theme foreground). Null applies no override.
  final TextStyle? titleStyle;

  /// Text style merged over the computed body style (body medium in the
  /// theme secondary foreground). Null applies no override.
  final TextStyle? bodyStyle;

  /// Text style merged over the computed countdown style (display medium in
  /// the active / expired color). Null applies no override.
  final TextStyle? countdownStyle;

  /// Color of the countdown while time remains. Defaults to the theme
  /// `primary` when null.
  final Color? accentColor;

  /// Color of the countdown once it reaches zero. Defaults to the theme
  /// `negativeBalance` when null.
  final Color? expiredColor;

  /// Suffix appended after the countdown in the screen-reader label, joined
  /// as `'<time> <suffix>'`. Defaults to `'remaining'`.
  final String remainingLabel;

  const BankSessionTimeoutDialog({
    required this.remainingTime,
    required this.onExtend,
    required this.onLogout,
    super.key,
    this.title = 'Session Expiring',
    this.body = 'Your session will expire soon. Stay logged in?',
    this.extendLabel = 'Stay Logged In',
    this.logoutLabel = 'Log Out',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.titleStyle,
    this.bodyStyle,
    this.countdownStyle,
    this.accentColor,
    this.expiredColor,
    this.remainingLabel = 'remaining',
  });

  @override
  State<BankSessionTimeoutDialog> createState() =>
      _BankSessionTimeoutDialogState();
}

class _BankSessionTimeoutDialogState extends State<BankSessionTimeoutDialog> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.remainingTime.inSeconds.clamp(0, 86400);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _expired = true;
        });
        // Fire logout callback after the frame settles to avoid calling
        // setState-like operations during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onLogout();
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Formats seconds as `M:SS` (e.g. `0:30`, `1:05`).
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return Dialog(
      backgroundColor: widget.backgroundColor ?? bankTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: widget.radius ?? bankTheme.cardRadius,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(BankTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              widget.title,
              style: BankTokens.headlineSmall
                  .copyWith(color: bankTheme.onSurface)
                  .merge(widget.titleStyle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BankTokens.space4),
            // Body
            Text(
              widget.body,
              style: BankTokens.bodyMedium
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(widget.bodyStyle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BankTokens.space4),
            // Countdown
            Semantics(
              liveRegion: true,
              label: '${_formatTime(_secondsRemaining)} '
                  '${widget.remainingLabel}',
              excludeSemantics: true,
              child: Text(
                _formatTime(_secondsRemaining),
                style: BankTokens.displayMedium.copyWith(
                  color: _expired
                      ? (widget.expiredColor ?? bankTheme.negativeBalance)
                      : (widget.accentColor ?? bankTheme.primary),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ).merge(widget.countdownStyle),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: BankTokens.space6),
            // Primary action
            FilledButton(
              onPressed: _expired ? null : widget.onExtend,
              style: FilledButton.styleFrom(
                backgroundColor: bankTheme.primary,
                foregroundColor: bankTheme.onPrimary,
                minimumSize: const Size.fromHeight(BankTokens.minTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(widget.extendLabel),
            ),
            const SizedBox(height: BankTokens.space2),
            // Secondary action
            TextButton(
              onPressed: widget.onLogout,
              style: TextButton.styleFrom(
                foregroundColor: bankTheme.onSurfaceVariant,
                minimumSize: const Size.fromHeight(BankTokens.minTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(widget.logoutLabel),
            ),
          ],
        ),
      ),
    );
  }
}
