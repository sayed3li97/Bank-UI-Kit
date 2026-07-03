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

  Color _frameColor(BankThemeData theme) => switch (framingState) {
        BankDocumentFramingState.aligned => theme.positiveBalance,
        BankDocumentFramingState.idle ||
        BankDocumentFramingState.detecting =>
          const Color(0xFFFFFFFF),
        _ => BankTokens.warning,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final aligned = framingState == BankDocumentFramingState.aligned;

    return Stack(
      fit: StackFit.expand,
      children: [
        cameraChild,
        ColoredBox(color: const Color(0xFF000000).withValues(alpha: 0.45)),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: BankTokens.space4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withValues(alpha: 0.5),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space3,
                    vertical: BankTokens.space1,
                  ),
                  child: Text(
                    side == BankChequeSide.front ? frontLabel : backLabel,
                    style: BankTokens.labelMedium
                        .copyWith(color: const Color(0xFFFFFFFF)),
                  ),
                ),
              ),
              if (enteredAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: BankTokens.space2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: theme.chipRadius,
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
                aspectRatio: 2.2,
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
                    color: BankTokens.warning.withValues(alpha: 0.9),
                    borderRadius: theme.chipRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BankTokens.space3,
                      vertical: BankTokens.space1,
                    ),
                    child: Text(
                      endorseReminder,
                      style: BankTokens.labelMedium
                          .copyWith(color: const Color(0xFF000000)),
                    ),
                  ),
                )
              else
                Text(
                  alignHint,
                  style: BankTokens.bodyMedium
                      .copyWith(color: const Color(0xFFFFFFFF)),
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
                            .copyWith(color: const Color(0xFFFFFFFF)),
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
                        duration: BankTokens.durationFast,
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: aligned
                              ? theme.positiveBalance
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.4),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF),
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
                child: frontThumbnail,
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: _Thumbnail(
                label: backLabel,
                theme: theme,
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
              backgroundColor: theme.primary,
              foregroundColor: theme.onPrimary,
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
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onPrimary),
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
  });

  final String label;
  final BankThemeData theme;
  final Widget? child;

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
                    Icons.image_outlined,
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
