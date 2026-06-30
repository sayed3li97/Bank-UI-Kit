import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// "Under review" holding-state widget for manual KYC review.
///
/// Distinct from a generic spinner — conveys the human review process with:
/// - An animated pulsing document icon.
/// - Three sequentially-pulsing dots indicating "processing".
/// - A title, body message, and optional estimated-time chip.
/// - Optional "Check Status" and "Contact Support" action buttons.
class BankAsyncVerificationState extends StatefulWidget {
  /// Primary heading. Defaults to `'Verification Under Review'`.
  final String title;

  /// Body message describing the review process.
  final String message;

  /// If provided, rendered in a chip below the message (e.g. `'1-2 business days'`).
  final String? estimatedTime;

  /// Slot for a custom illustration. When `null`, an animated document icon
  /// is rendered instead.
  final Widget? customIllustration;

  /// Called when the user taps the "Check Status" button. `null` hides it.
  final VoidCallback? onCheckStatus;

  /// Called when the user taps the "Contact Support" button. `null` hides it.
  final VoidCallback? onContactSupport;

  const BankAsyncVerificationState({
    super.key,
    this.title = 'Verification Under Review',
    this.message =
        'We\'re reviewing your documents. This usually takes 1–2 business days.',
    this.estimatedTime,
    this.customIllustration,
    this.onCheckStatus,
    this.onContactSupport,
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
  static const double _dotSize = 8.0;
  static const double _dotActiveOpacity = 1.0;
  static const double _dotIdleOpacity = 0.25;

  @override
  void initState() {
    super.initState();

    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconPulseController,
        curve: BankTokens.curveStandard,
      ),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: _dotCycleDuration,
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
    const double window = 0.5;
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
      label: widget.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(
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
              style: BankTokens.headlineSmall.copyWith(
                color: bankTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BankTokens.space3),

            // Body message.
            Text(
              widget.message,
              style: BankTokens.bodyMedium.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Estimated-time chip.
            if (widget.estimatedTime != null) ...[
              const SizedBox(height: BankTokens.space4),
              _EstimatedTimeChip(
                estimatedTime: widget.estimatedTime!,
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

    return RepaintBoundary(
      child: ScaleTransition(
        scale: _iconScale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: bankTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.description_outlined,
            size: 48,
            color: bankTheme.primary,
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
                      color: bankTheme.primary,
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
              child: const Text('Check Status'),
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
              child: const Text('Contact Support'),
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
    required this.bankTheme,
  });

  final String estimatedTime;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space2,
      ),
      decoration: BoxDecoration(
        color: bankTheme.surfaceVariant,
        borderRadius:
            const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 14,
            color: bankTheme.onSurfaceVariant,
          ),
          const SizedBox(width: BankTokens.space2),
          Text(
            'Estimated: $estimatedTime',
            style: BankTokens.labelSmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
