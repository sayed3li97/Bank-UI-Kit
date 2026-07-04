import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// "Under review" holding-state widget for manual KYC review.
///
/// Distinct from a generic spinner: conveys the human review process with:
/// - An animated pulsing document icon.
/// - Three sequentially-pulsing dots indicating "processing".
/// - A title, body message, and optional estimated-time chip.
/// - Optional "Check Status" and "Contact Support" action buttons.
class BankAsyncVerificationState extends StatefulWidget {
  /// Primary heading. Defaults to `'Verification Under Review'`.
  final String title;

  /// Body message describing the review process.
  final String message;

  /// If provided, rendered in a chip below the message
  /// (e.g. `'1-2 business days'`).
  final String? estimatedTime;

  /// Slot for a custom illustration. When `null`, an animated document icon
  /// is rendered instead.
  final Widget? customIllustration;

  /// Called when the user taps the "Check Status" button. `null` hides it.
  final VoidCallback? onCheckStatus;

  /// Called when the user taps the "Contact Support" button. `null` hides it.
  final VoidCallback? onContactSupport;

  /// Label of the check-status button. Defaults to 'Check Status'.
  final String checkStatusLabel;

  /// Label of the contact-support button. Defaults to
  /// 'Contact Support'.
  final String contactSupportLabel;

  /// Prefix inside the estimated-time chip. Defaults to 'Estimated:'.
  final String estimatedPrefix;

  /// Glyph of the default animated illustration. Defaults to
  /// [Icons.description_outlined].
  final IconData? illustrationIcon;

  /// Glyph inside the estimated-time chip. Defaults to
  /// [Icons.schedule_outlined].
  final IconData? estimatedTimeIcon;

  /// Color of the illustration icon, its halo, and the pulsing dots.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Fill of the estimated-time chip. Defaults to the theme
  /// surfaceVariant.
  final Color? chipBackgroundColor;

  /// Merged over the computed title style (headlineSmall).
  final TextStyle? titleStyle;

  /// Merged over the computed body message style (bodyMedium).
  final TextStyle? messageStyle;

  /// Overrides the outer padding. Defaults to [BankTokens.space6]
  /// horizontal and [BankTokens.space8] vertical.
  final EdgeInsetsGeometry? padding;

  /// Overrides the semantics label. Defaults to [title].
  final String? semanticLabel;

  /// Duration of one icon pulse. Defaults to 1600 ms.
  final Duration? pulseDuration;

  /// Duration of one three-dot cycle. Defaults to 1200 ms.
  final Duration? dotCycleDuration;

  const BankAsyncVerificationState({
    super.key,
    this.title = 'Verification Under Review',
    this.message = 'We\'re reviewing your documents. '
        'This usually takes 1–2 business days.',
    this.estimatedTime,
    this.customIllustration,
    this.onCheckStatus,
    this.onContactSupport,
    this.checkStatusLabel = 'Check Status',
    this.contactSupportLabel = 'Contact Support',
    this.estimatedPrefix = 'Estimated:',
    this.illustrationIcon,
    this.estimatedTimeIcon,
    this.accentColor,
    this.chipBackgroundColor,
    this.titleStyle,
    this.messageStyle,
    this.padding,
    this.semanticLabel,
    this.pulseDuration,
    this.dotCycleDuration,
  });

  @override
  State<BankAsyncVerificationState> createState() =>
      _BankAsyncVerificationStateState();
}

class _BankAsyncVerificationStateState extends State<BankAsyncVerificationState>
    with TickerProviderStateMixin {
  // Document icon pulse: 0.9 → 1.0 → 0.9 …
  late final AnimationController _iconPulseController;
  late final Animation<double> _iconScale;

  // Three-dot sequenced animation controller.
  late final AnimationController _dotsController;

  static const int _dotCount = 3;
  static const Duration _dotCycleDuration = Duration(milliseconds: 1200);
  static const double _dotSize = 8;
  static const double _dotActiveOpacity = 1;
  static const double _dotIdleOpacity = 0.25;

  @override
  void initState() {
    super.initState();

    _iconPulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration ?? const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.90, end: 1).animate(
      CurvedAnimation(
        parent: _iconPulseController,
        curve: BankTokens.curveStandard,
      ),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: widget.dotCycleDuration ?? _dotCycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  // Computes the opacity for each dot index given the current animation value.
  // The three dots are offset by 1/3 of the cycle each.
  double _dotOpacity(int index) {
    // Each dot has a window of 0.5 (50% of the cycle) where it peaks.
    const window = 0.5;
    final offset = index / _dotCount;
    final t = (_dotsController.value - offset) % 1.0;
    // Use a triangle wave within the window.
    if (t < window) {
      final relative = t / window;
      return _dotIdleOpacity +
          (_dotActiveOpacity - _dotIdleOpacity) *
              (relative < 0.5 ? relative * 2 : (1 - relative) * 2);
    }
    return _dotIdleOpacity;
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return Semantics(
      label: widget.semanticLabel ?? widget.title,
      child: Padding(
        padding: widget.padding ??
            const EdgeInsets.symmetric(
              horizontal: BankTokens.space6,
              vertical: BankTokens.space8,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or animated document icon.
            _buildIllustration(bankTheme),

            const SizedBox(height: BankTokens.space4),

            // Three pulsing dots.
            _buildDots(bankTheme),

            const SizedBox(height: BankTokens.space6),

            // Title.
            Text(
              widget.title,
              style: BankTokens.headlineSmall
                  .copyWith(color: bankTheme.onSurface)
                  .merge(widget.titleStyle),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BankTokens.space3),

            // Body message.
            Text(
              widget.message,
              style: BankTokens.bodyMedium
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(widget.messageStyle),
              textAlign: TextAlign.center,
            ),

            // Estimated-time chip.
            if (widget.estimatedTime != null) ...[
              const SizedBox(height: BankTokens.space4),
              _EstimatedTimeChip(
                estimatedTime: widget.estimatedTime!,
                estimatedPrefix: widget.estimatedPrefix,
                icon: widget.estimatedTimeIcon ?? Icons.schedule_outlined,
                backgroundColor:
                    widget.chipBackgroundColor ?? bankTheme.surfaceVariant,
                bankTheme: bankTheme,
              ),
            ],

            // Action buttons.
            if (widget.onCheckStatus != null ||
                widget.onContactSupport != null) ...[
              const SizedBox(height: BankTokens.space8),
              _buildActions(bankTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(BankThemeData bankTheme) {
    if (widget.customIllustration != null) {
      return widget.customIllustration!;
    }

    final accent = widget.accentColor ?? bankTheme.primary;
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _iconScale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.illustrationIcon ?? Icons.description_outlined,
            size: 48,
            color: accent,
          ),
        ),
      ),
    );
  }

  Widget _buildDots(BankThemeData bankTheme) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _dotsController,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_dotCount, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space1,
                ),
                child: Opacity(
                  opacity: _dotOpacity(index),
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: widget.accentColor ?? bankTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildActions(BankThemeData bankTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onCheckStatus != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onCheckStatus,
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, BankTokens.minTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(widget.checkStatusLabel),
            ),
          ),
        if (widget.onCheckStatus != null && widget.onContactSupport != null)
          const SizedBox(height: BankTokens.space3),
        if (widget.onContactSupport != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onContactSupport,
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, BankTokens.minTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: bankTheme.buttonRadius,
                ),
              ),
              child: Text(widget.contactSupportLabel),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Estimated-time chip
// ---------------------------------------------------------------------------

class _EstimatedTimeChip extends StatelessWidget {
  const _EstimatedTimeChip({
    required this.estimatedTime,
    required this.estimatedPrefix,
    required this.icon,
    required this.backgroundColor,
    required this.bankTheme,
  });

  final String estimatedTime;
  final String estimatedPrefix;
  final IconData icon;
  final Color backgroundColor;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: bankTheme.onSurfaceVariant,
          ),
          const SizedBox(width: BankTokens.space2),
          Text(
            '$estimatedPrefix $estimatedTime',
            style: BankTokens.labelSmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
