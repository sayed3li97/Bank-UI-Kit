import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Describes the severity and colour of a [BankToastBanner].
enum BankToastVariant { success, error, info, warning }

/// A toast-style banner that slides in from the top of its parent.
///
/// The host app controls visibility via [isVisible]. When [isVisible] becomes
/// `true` the banner animates in and, after [autoHideDuration], calls
/// [onDismiss] so the host can set [isVisible] back to `false`.
///
/// Colours:
/// - [BankToastVariant.success]  `#34C759` (white text)
/// - [BankToastVariant.error]    `#FF3B30` (white text)
/// - [BankToastVariant.info]     `BankThemeData.primary` (white text)
/// - [BankToastVariant.warning]  `#FF9500` (white text)
///
/// Accessibility: the widget is marked as a `liveRegion` so screen readers
/// announce the [message] as soon as it appears.
///
/// ```dart
/// BankToastBanner(
///   variant: BankToastVariant.success,
///   message: 'Payment sent successfully.',
///   isVisible: _showToast,
///   onDismiss: () => setState(() => _showToast = false),
/// )
/// ```
class BankToastBanner extends StatefulWidget {
  /// Visual variant that determines the background colour and leading icon.
  final BankToastVariant variant;

  /// The message text displayed in the banner.
  final String message;

  /// Optional label for an action button inside the banner.
  final String? actionLabel;

  /// Callback invoked when the action button is tapped.
  final VoidCallback? onAction;

  /// Callback invoked when the banner should be dismissed.
  ///
  /// This is called both when [autoHideDuration] elapses and when the close
  /// icon button is tapped. The host must update [isVisible] in response.
  final VoidCallback? onDismiss;

  /// Whether the banner is currently visible.
  final bool isVisible;

  /// How long to wait before auto-dismissing the banner.
  final Duration autoHideDuration;

  /// When `true`, calls [HapticFeedback.lightImpact] when the banner appears.
  final bool hapticFeedback;

  const BankToastBanner({
    required this.variant,
    required this.message,
    required this.isVisible,
    super.key,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.autoHideDuration = const Duration(seconds: 4),
    this.hapticFeedback = true,
  });

  @override
  State<BankToastBanner> createState() => _BankToastBannerState();
}

class _BankToastBannerState extends State<BankToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  // Tracks the current dismiss timer so it can be cancelled on rebuild.
  // We store the _expire timestamp instead of a Timer to avoid import of
  // dart:async; we use WidgetsBinding instead.
  bool _autoDismissScheduled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: BankTokens.durationBase,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BankTokens.curveDecelerate,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6),
      ),
    );

    if (widget.isVisible) {
      _show();
    }
  }

  @override
  void didUpdateWidget(BankToastBanner old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) {
      _show();
    } else if (!widget.isVisible && old.isVisible) {
      _hide();
    }
  }

  void _show() {
    _controller.forward(from: 0);

    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (widget.onDismiss != null && !_autoDismissScheduled) {
      _autoDismissScheduled = true;
      Future.delayed(widget.autoHideDuration, () {
        if (mounted && widget.isVisible) {
          widget.onDismiss?.call();
        }
        _autoDismissScheduled = false;
      });
    }
  }

  void _hide() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor(BankThemeData theme) => switch (widget.variant) {
        BankToastVariant.success => const Color(0xFF34C759),
        BankToastVariant.error => const Color(0xFFFF3B30),
        BankToastVariant.info => theme.primary,
        BankToastVariant.warning => const Color(0xFFFF9500),
      };

  IconData _leadingIcon() => switch (widget.variant) {
        BankToastVariant.success => Icons.check_circle_outline,
        BankToastVariant.error => Icons.error_outline,
        BankToastVariant.info => Icons.info_outline,
        BankToastVariant.warning => Icons.warning_amber_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final bg = _backgroundColor(theme);
    const fg = Color(0xFFFFFFFF);
    final showAction = widget.actionLabel != null && widget.onAction != null;

    return Semantics(
      liveRegion: widget.isVisible,
      label: widget.isVisible ? '${_variantLabel()}: ${widget.message}' : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.value == 0 && !widget.isVisible) {
            return const SizedBox.shrink();
          }
          return FractionalTranslation(
            translation: _slideAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: RepaintBoundary(
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space3,
              ),
              child: Row(
                children: [
                  Icon(_leadingIcon(), color: fg, size: 20),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: BankTokens.bodyMedium.copyWith(color: fg),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showAction) ...[
                    const SizedBox(width: BankTokens.space2),
                    Semantics(
                      button: true,
                      label: widget.actionLabel,
                      child: TextButton(
                        onPressed: widget.onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          minimumSize: const Size(
                            BankTokens.minTapTarget,
                            BankTokens.minTapTarget,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: BankTokens.space2,
                          ),
                          textStyle: BankTokens.labelMedium,
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    ),
                  ],
                  Semantics(
                    button: true,
                    label: 'Dismiss',
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: fg,
                      onPressed: widget.onDismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: BankTokens.minTapTarget,
                        minHeight: BankTokens.minTapTarget,
                      ),
                      tooltip: 'Dismiss',
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

  String _variantLabel() => switch (widget.variant) {
        BankToastVariant.success => 'Success',
        BankToastVariant.error => 'Error',
        BankToastVariant.info => 'Info',
        BankToastVariant.warning => 'Warning',
      };
}
