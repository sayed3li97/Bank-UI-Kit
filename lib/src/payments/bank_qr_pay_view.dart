import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// What the host's QR decoder currently reports.
enum BankQrScanState { searching, found, invalid }

/// Scan-to-pay overlay, camera-plugin-agnostic like the KYC overlays:
/// the host renders its camera preview as [cameraChild] and drives
/// [state] from its own decoder.
///
/// A 240px rounded viewfinder with animated corner guides sits over a
/// dimmed scrim; a scan line sweeps while searching (still under
/// reduced motion), the corners flash positive on [BankQrScanState.found]
/// and shake on [BankQrScanState.invalid]. A torch toggle renders when
/// [onTorchToggle] is provided.
///
/// ```dart
/// BankQrScannerOverlay(
///   cameraChild: CameraPreview(controller),
///   state: _scanState,
///   onTorchToggle: _toggleTorch,
///   torchOn: _torchOn,
/// )
/// ```
class BankQrScannerOverlay extends StatefulWidget {
  const BankQrScannerOverlay({
    required this.cameraChild,
    required this.state,
    super.key,
    this.onTorchToggle,
    this.torchOn = false,
    this.instruction = 'Point your camera at a payment code',
  });

  /// The host's camera preview.
  final Widget cameraChild;

  final BankQrScanState state;

  /// Shows a torch toggle button when set.
  final VoidCallback? onTorchToggle;

  final bool torchOn;
  final String instruction;

  @override
  State<BankQrScannerOverlay> createState() => _BankQrScannerOverlayState();
}

class _BankQrScannerOverlayState extends State<BankQrScannerOverlay>
    with SingleTickerProviderStateMixin {
  static const _window = 240.0;

  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced || widget.state != BankQrScanState.searching) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void didUpdateWidget(BankQrScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.state == BankQrScanState.searching && !reduced) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Color _cornerColor(BankThemeData theme) => switch (widget.state) {
        BankQrScanState.searching => theme.onPrimary,
        BankQrScanState.found => theme.positiveBalance,
        BankQrScanState.invalid => BankTokens.danger,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.cameraChild,
        // Dimmed scrim with a clear window.
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            const Color(0xFF000000).withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0x01000000)),
              Center(
                child: Container(
                  width: _window,
                  height: _window,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: theme.cardRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            width: _window,
            height: _window,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size.square(_window),
                  painter: _CornerGuidePainter(
                    color: _cornerColor(theme),
                    radius: theme.cardRadius.topLeft.x,
                  ),
                ),
                if (widget.state == BankQrScanState.searching)
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => Align(
                      alignment: Alignment(
                        0,
                        _sweep.value * 2 - 1,
                      ),
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withValues(alpha: 0),
                              theme.primary,
                              theme.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space3),
              child: widget.onTorchToggle == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      button: true,
                      label: widget.torchOn ? 'Torch on' : 'Torch off',
                      child: IconButton(
                        onPressed: widget.onTorchToggle,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF000000).withValues(alpha: 0.4),
                          minimumSize: const Size(44, 44),
                        ),
                        icon: Icon(
                          widget.torchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space6),
              child: Text(
                widget.instruction,
                textAlign: TextAlign.center,
                style: BankTokens.bodyMedium
                    .copyWith(color: const Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  const _CornerGuidePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final r = radius.clamp(8.0, 24.0);
    final w = size.width;
    final h = size.height;

    final path = Path()
      // Top-left
      ..moveTo(0, len)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(len, 0)
      // Top-right
      ..moveTo(w - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, len)
      // Bottom-right
      ..moveTo(w, h - len)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(w - len, h)
      // Bottom-left
      ..moveTo(len, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, h - len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// "My QR" receive-payment card: encodes [payload] locally with a pure
/// Dart QR encoder (no network, no plugin) on a white card. QR modules
/// stay black-on-white in every preset for scanner reliability; only
/// the surrounding chrome themes.
///
/// ```dart
/// BankMyQrCard(
///   payload: 'bank://pay/SA4420000001234567891234',
///   displayName: 'Sara Al Amoudi',
///   accountMasked: 'SA44 •••• 1234',
///   onShare: _shareQr,
/// )
/// ```
class BankMyQrCard extends StatelessWidget {
  const BankMyQrCard({
    required this.payload,
    required this.displayName,
    super.key,
    this.accountMasked,
    this.requestAmount,
    this.logo,
    this.onShare,
    this.onSetAmount,
    this.shareLabel = 'Share',
    this.setAmountLabel = 'Set amount',
    this.qrSize = 200,
  });

  /// The encoded payment string (IBAN URI, EMVCo payload, deep link…).
  final String payload;

  final String displayName;
  final String? accountMasked;

  /// Renders a requested-amount chip above the QR when set.
  final Money? requestAmount;

  /// Optional center overlay (e.g. bank mark) — keep under 20% of the
  /// QR area so error correction still decodes.
  final Widget? logo;

  final VoidCallback? onShare;
  final VoidCallback? onSetAmount;
  final String shareLabel;
  final String setAmountLabel;
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: theme.outline),
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (requestAmount != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space3,
                    vertical: BankTokens.space1,
                  ),
                  child: BankBalanceText(
                    money: requestAmount!,
                    size: BankBalanceSize.small,
                  ),
                ),
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            Semantics(
              label: 'Payment QR code for $displayName',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: theme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space3),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(qrSize),
                        painter: _QrPainter(qrImage),
                      ),
                      if (logo != null)
                        SizedBox(
                          width: qrSize * 0.18,
                          height: qrSize * 0.18,
                          child: logo,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: BankTokens.space4),
            Text(
              displayName,
              style: BankTokens.bodyLarge.copyWith(
                color: theme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (accountMasked != null) ...[
              const SizedBox(height: 2),
              Text(
                accountMasked!,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
            if (onShare != null || onSetAmount != null) ...[
              const SizedBox(height: BankTokens.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onSetAmount != null)
                    TextButton.icon(
                      onPressed: onSetAmount,
                      icon: Icon(
                        Icons.tag_rounded,
                        size: 18,
                        color: theme.primary,
                      ),
                      label: Text(
                        setAmountLabel,
                        style: BankTokens.labelLarge
                            .copyWith(color: theme.primary),
                      ),
                    ),
                  if (onShare != null && onSetAmount != null)
                    const SizedBox(width: BankTokens.space3),
                  if (onShare != null)
                    TextButton.icon(
                      onPressed: onShare,
                      icon: Icon(
                        BankIcons.share,
                        size: 18,
                        color: theme.primary,
                      ),
                      label: Text(
                        shareLabel,
                        style: BankTokens.labelLarge
                            .copyWith(color: theme.primary),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF000000);
    final module = size.width / image.moduleCount;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * module, row * module, module, module),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
