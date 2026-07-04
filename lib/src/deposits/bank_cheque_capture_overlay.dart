import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../accounts/bank_product_item_tile.dart';
import '../models/bank_account.dart';
import '../models/money.dart';
import '../onboarding/bank_document_capture_overlay.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Which side of the cheque is being captured.
enum BankChequeSide { front, back }

/// Remote-deposit-capture overlay: the landscape sibling of
/// `BankDocumentCaptureOverlay`, reusing its [BankDocumentFramingState]
/// vocabulary. Renders a 2.2:1 cheque frame guide with corner marks over
/// the host's camera preview, a side indicator chip, an endorsement
/// reminder when capturing the back, and an amount chip when the
/// customer pre-entered one.
///
/// ```dart
/// BankChequeCaptureOverlay(
///   cameraChild: CameraPreview(controller),
///   side: BankChequeSide.front,
///   framingState: _framing,
///   enteredAmount: Money.fromDouble(1250, 'USD'),
///   onCapture: _capture,
/// )
/// ```
class BankChequeCaptureOverlay extends StatelessWidget {
  const BankChequeCaptureOverlay({
    required this.cameraChild,
    required this.side,
    required this.framingState,
    super.key,
    this.enteredAmount,
    this.onCapture,
    this.onRetake,
    this.frontLabel = 'Front of check',
    this.backLabel = 'Back of check',
    this.endorseReminder = 'Sign the back before capturing',
    this.captureLabel = 'Capture',
    this.retakeLabel = 'Retake',
    this.alignHint = 'Fit the check inside the frame',
    this.scrimColor,
    this.foregroundColor,
    this.accentColor,
    this.warningColor,
    this.chipBackgroundColor,
    this.chipRadius,
    this.frameAspectRatio,
    this.labelStyle,
    this.animationDuration,
  });

  /// The host's camera preview.
  final Widget cameraChild;

  final BankChequeSide side;

  /// Reuses the document-capture framing vocabulary.
  final BankDocumentFramingState framingState;

  /// Shows the pre-entered deposit amount above the frame.
  final Money? enteredAmount;

  /// Enables the shutter button when aligned.
  final VoidCallback? onCapture;

  /// Shows a retake affordance next to the shutter.
  final VoidCallback? onRetake;

  final String frontLabel;
  final String backLabel;
  final String endorseReminder;
  final String captureLabel;
  final String retakeLabel;
  final String alignHint;

  /// Overrides the darkening scrim over the camera preview. Defaults to
  /// black at 45 % opacity.
  final Color? scrimColor;

  /// Overrides the white chrome colour (texts, idle frame, shutter ring).
  final Color? foregroundColor;

  /// Overrides [BankThemeData.positiveBalance] on the aligned frame and
  /// the enabled shutter fill.
  final Color? accentColor;

  /// Overrides [BankTokens.warning] on the misaligned frame and the
  /// endorsement reminder chip.
  final Color? warningColor;

  /// Overrides the side indicator chip fill. Defaults to black at 50 %
  /// opacity.
  final Color? chipBackgroundColor;

  /// Overrides the chip corner radius. Defaults to
  /// [BankThemeData.chipRadius].
  final BorderRadius? chipRadius;

  /// Overrides the 2.2:1 cheque frame aspect ratio.
  final double? frameAspectRatio;

  /// Merged over the computed styles of the side chip, endorsement
  /// reminder, align hint, and retake texts.
  final TextStyle? labelStyle;

  /// Overrides the shutter state-change animation duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  Color get _foreground => foregroundColor ?? const Color(0xFFFFFFFF);

  Color _frameColor(BankThemeData theme) => switch (framingState) {
        BankDocumentFramingState.aligned =>
          accentColor ?? theme.positiveBalance,
        BankDocumentFramingState.idle ||
        BankDocumentFramingState.detecting =>
          _foreground,
        _ => warningColor ?? BankTokens.warning,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final aligned = framingState == BankDocumentFramingState.aligned;
    final resolvedChipRadius = chipRadius ?? theme.chipRadius;

    return Stack(
      fit: StackFit.expand,
      children: [
        cameraChild,
        ColoredBox(
          color: scrimColor ?? const Color(0xFF000000).withValues(alpha: 0.45),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: BankTokens.space4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: chipBackgroundColor ??
                      const Color(0xFF000000).withValues(alpha: 0.5),
                  borderRadius: resolvedChipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space3,
                    vertical: BankTokens.space1,
                  ),
                  child: Text(
                    side == BankChequeSide.front ? frontLabel : backLabel,
                    style: BankTokens.labelMedium
                        .copyWith(color: _foreground)
                        .merge(labelStyle),
                  ),
                ),
              ),
              if (enteredAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: BankTokens.space2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: resolvedChipRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space3,
                        vertical: BankTokens.space1,
                      ),
                      child: BankBalanceText(
                        money: enteredAmount!,
                        size: BankBalanceSize.small,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              AspectRatio(
                aspectRatio: frameAspectRatio ?? 2.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space5,
                  ),
                  child: CustomPaint(
                    painter: _ChequeFramePainter(
                      color: _frameColor(theme),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BankTokens.space3),
              if (side == BankChequeSide.back)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: (warningColor ?? BankTokens.warning)
                        .withValues(alpha: 0.9),
                    borderRadius: resolvedChipRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BankTokens.space3,
                      vertical: BankTokens.space1,
                    ),
                    child: Text(
                      endorseReminder,
                      style: BankTokens.labelMedium
                          .copyWith(color: const Color(0xFF000000))
                          .merge(labelStyle),
                    ),
                  ),
                )
              else
                Text(
                  alignHint,
                  style: BankTokens.bodyMedium
                      .copyWith(color: _foreground)
                      .merge(labelStyle),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetake != null) ...[
                    TextButton(
                      onPressed: onRetake,
                      child: Text(
                        retakeLabel,
                        style: BankTokens.labelLarge
                            .copyWith(color: _foreground)
                            .merge(labelStyle),
                      ),
                    ),
                    const SizedBox(width: BankTokens.space5),
                  ],
                  Semantics(
                    button: true,
                    enabled: aligned && onCapture != null,
                    label: captureLabel,
                    child: GestureDetector(
                      onTap: aligned ? onCapture : null,
                      child: AnimatedContainer(
                        duration: animationDuration ?? BankTokens.durationFast,
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: aligned
                              ? (accentColor ?? theme.positiveBalance)
                              : _foreground.withValues(alpha: 0.4),
                          border: Border.all(
                            color: _foreground,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space5),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChequeFramePainter extends CustomPainter {
  const _ChequeFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 26.0;
    const r = 12.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, len)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(len, 0)
      ..moveTo(w - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, len)
      ..moveTo(w, h - len)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(w - len, h)
      ..moveTo(len, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, h - len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChequeFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The RDC review step: captured front/back thumbnails, the deposit
/// amount, the deposit-to account rendered with [BankProductItemTile],
/// a funds-availability disclaimer slot, and the submit button.
class BankChequeDepositSummary extends StatelessWidget {
  const BankChequeDepositSummary({
    required this.amount,
    required this.depositTo,
    required this.onSubmit,
    super.key,
    this.frontThumbnail,
    this.backThumbnail,
    this.disclaimerSlot,
    this.submitting = false,
    this.submitLabel = 'Deposit check',
    this.frontLabel = 'Front',
    this.backLabel = 'Back',
    this.submitBackgroundColor,
    this.submitForegroundColor,
    this.submitLabelStyle,
    this.placeholderIcon,
  });

  final Money amount;
  final BankAccount depositTo;
  final VoidCallback onSubmit;

  /// Captured image slots: the kit never touches camera APIs.
  final Widget? frontThumbnail;
  final Widget? backThumbnail;

  /// Regulatory funds-availability text.
  final Widget? disclaimerSlot;

  final bool submitting;
  final String submitLabel;
  final String frontLabel;
  final String backLabel;

  /// Overrides the submit button fill. Defaults to [BankThemeData.primary].
  final Color? submitBackgroundColor;

  /// Overrides the submit button text colour. Defaults to
  /// [BankThemeData.onPrimary].
  final Color? submitForegroundColor;

  /// Merged over the computed submit label style ([BankTokens.labelLarge]).
  final TextStyle? submitLabelStyle;

  /// Overrides the empty-thumbnail glyph. Defaults to
  /// [Icons.image_outlined].
  final IconData? placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BankBalanceText(
            money: amount,
            size: BankBalanceSize.hero,
          ),
        ),
        const SizedBox(height: BankTokens.space4),
        Row(
          children: [
            Expanded(
              child: _Thumbnail(
                label: frontLabel,
                theme: theme,
                placeholderIcon: placeholderIcon,
                child: frontThumbnail,
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: _Thumbnail(
                label: backLabel,
                theme: theme,
                placeholderIcon: placeholderIcon,
                child: backThumbnail,
              ),
            ),
          ],
        ),
        const SizedBox(height: BankTokens.space4),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: theme.cardRadius,
            border: Border.all(color: theme.outline),
          ),
          child: BankProductItemTile(account: depositTo),
        ),
        if (disclaimerSlot != null) ...[
          const SizedBox(height: BankTokens.space3),
          disclaimerSlot!,
        ],
        const SizedBox(height: BankTokens.space5),
        SizedBox(
          height: BankTokens.space12,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: submitBackgroundColor ?? theme.primary,
              foregroundColor: submitForegroundColor ?? theme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: theme.buttonRadius,
              ),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    submitLabel,
                    style: BankTokens.labelLarge
                        .copyWith(
                          color: submitForegroundColor ?? theme.onPrimary,
                        )
                        .merge(submitLabelStyle),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.label,
    required this.theme,
    required this.child,
    this.placeholderIcon,
  });

  final String label;
  final BankThemeData theme;
  final Widget? child;
  final IconData? placeholderIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2.2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: theme.chipRadius,
              border: Border.all(color: theme.outline),
            ),
            child: child == null
                ? Icon(
                    placeholderIcon ?? Icons.image_outlined,
                    color: theme.onSurfaceVariant,
                  )
                : ClipRRect(
                    borderRadius: theme.chipRadius,
                    child: child,
                  ),
          ),
        ),
        const SizedBox(height: BankTokens.space1),
        Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: theme.onSurfaceVariant),
        ),
      ],
    );
  }
}
