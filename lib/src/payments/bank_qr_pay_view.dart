import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_surface_depth.dart';
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
    this.windowSize,
    this.radius,
    this.accentColor,
    this.cornerColor,
    this.scrimColor,
    this.instructionStyle,
    this.torchOnIcon,
    this.torchOffIcon,
    this.torchOnLabel = 'Torch on',
    this.torchOffLabel = 'Torch off',
    this.animationDuration,
  });

  /// The host's camera preview.
  final Widget cameraChild;

  final BankQrScanState state;

  /// Shows a torch toggle button when set.
  final VoidCallback? onTorchToggle;

  final bool torchOn;
  final String instruction;

  /// Overrides the square viewfinder edge length. Defaults to 240.
  final double? windowSize;

  /// Overrides the viewfinder corner radius. Defaults to the theme
  /// card radius.
  final BorderRadius? radius;

  /// Colour of the sweeping scan line. Defaults to the theme primary.
  final Color? accentColor;

  /// Corner-guide colour while searching. Defaults to the theme
  /// on-primary colour; found/invalid states keep semantic colours.
  final Color? cornerColor;

  /// Overrides the dimmed scrim colour. Defaults to 55% black.
  final Color? scrimColor;

  /// Merged over the computed instruction text style.
  final TextStyle? instructionStyle;

  /// Torch-on glyph. Defaults to [Icons.flash_on_rounded].
  final IconData? torchOnIcon;

  /// Torch-off glyph. Defaults to [Icons.flash_off_rounded].
  final IconData? torchOffIcon;

  /// Semantics label of the torch button while on. Defaults to
  /// 'Torch on'.
  final String torchOnLabel;

  /// Semantics label of the torch button while off. Defaults to
  /// 'Torch off'.
  final String torchOffLabel;

  /// Duration of one scan-line sweep. Defaults to 1800 ms.
  final Duration? animationDuration;

  @override
  State<BankQrScannerOverlay> createState() => _BankQrScannerOverlayState();
}

class _BankQrScannerOverlayState extends State<BankQrScannerOverlay>
    with SingleTickerProviderStateMixin {
  static const _window = 240.0;
  static const _defaultSweepDuration = Duration(milliseconds: 1800);

  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? _defaultSweepDuration,
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
    if (widget.animationDuration != oldWidget.animationDuration) {
      _sweep.duration = widget.animationDuration ?? _defaultSweepDuration;
      if (_sweep.isAnimating) {
        _sweep
          ..stop()
          ..repeat();
      }
    }
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
        BankQrScanState.searching => widget.cornerColor ?? theme.onPrimary,
        BankQrScanState.found => theme.positiveBalance,
        BankQrScanState.invalid => BankTokens.danger,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final window = widget.windowSize ?? _window;
    final windowRadius = widget.radius ?? theme.cardRadius;
    final accent = widget.accentColor ?? theme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.cameraChild,
        // Dimmed scrim with a clear window.
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            widget.scrimColor ??
                const Color(0xFF000000).withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0x01000000)),
              Center(
                child: Container(
                  width: window,
                  height: window,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: windowRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            width: window,
            height: window,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.square(window),
                  painter: _CornerGuidePainter(
                    color: _cornerColor(theme),
                    radius: windowRadius.topLeft.x,
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
                              accent.withValues(alpha: 0),
                              accent,
                              accent.withValues(alpha: 0),
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
                      label: widget.torchOn
                          ? widget.torchOnLabel
                          : widget.torchOffLabel,
                      child: IconButton(
                        onPressed: widget.onTorchToggle,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF000000).withValues(alpha: 0.4),
                          minimumSize: const Size(44, 44),
                        ),
                        icon: Icon(
                          widget.torchOn
                              ? widget.torchOnIcon ?? Icons.flash_on_rounded
                              : widget.torchOffIcon ?? Icons.flash_off_rounded,
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
                    .copyWith(color: const Color(0xFFFFFFFF))
                    .merge(widget.instructionStyle),
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
    this.padding,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.shadow,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.setAmountIcon,
    this.shareIcon,
    this.semanticLabel,
  });

  /// The encoded payment string (IBAN URI, EMVCo payload, deep link…).
  final String payload;

  final String displayName;
  final String? accountMasked;

  /// Renders a requested-amount chip above the QR when set.
  final Money? requestAmount;

  /// Optional center overlay (e.g. bank mark): keep under 20% of the
  /// QR area so error correction still decodes.
  final Widget? logo;

  final VoidCallback? onShare;
  final VoidCallback? onSetAmount;
  final String shareLabel;
  final String setAmountLabel;
  final double qrSize;

  /// Overrides the card content padding. Defaults to
  /// [BankTokens.space5] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme card
  /// radius.
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card border colour. By default the raised card carries
  /// **no visible border on light surfaces** (depth comes from the shadow);
  /// dark surfaces get a [BankTokens.hairlineWidth] hairline in
  /// [BankTokens.hairlineColor] where a shadow alone cannot separate the
  /// card from the background.
  final Color? borderColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten the card.
  final List<BoxShadow>? shadow;

  /// Tint of the amount chip and action buttons. Defaults to the
  /// theme primary.
  final Color? accentColor;

  /// Merged over the computed display-name style.
  final TextStyle? titleStyle;

  /// Merged over the computed masked-account style.
  final TextStyle? subtitleStyle;

  /// Merged over the computed requested-amount style.
  final TextStyle? amountStyle;

  /// Glyph of the set-amount action. Defaults to [Icons.tag_rounded].
  final IconData? setAmountIcon;

  /// Glyph of the share action. Defaults to [BankIcons.share].
  final IconData? shareIcon;

  /// Overrides the QR semantics label. Defaults to
  /// 'Payment QR code for {displayName}'.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    // errorCorrectLevel defaults to QrErrorCorrectLevel.medium (~15%),
    // matching the previous explicit level.
    final qrCode = QrCode(payload: QrPayload.fromString(payload));
    final qrImage = QrImage(qrCode);
    final accent = accentColor ?? theme.primary;
    final resolvedAmountStyle = amountStyle == null
        ? null
        : theme.numeralSmall
            .copyWith(color: theme.onSurface)
            .merge(amountStyle);

    // Raised card: shadow-only depth — no doubled outline+shadow. The
    // resolver adds the dark-surface hairline (invisible on light) unless
    // the caller supplies an explicit borderColor.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: borderColor == null ? null : Border.all(color: borderColor!),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surface,
        borderRadius: radius ?? theme.cardRadius,
        border: depth.border,
        boxShadow: depth.shadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BankTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (requestAmount != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
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
                    style: resolvedAmountStyle,
                  ),
                ),
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            Semantics(
              label: semanticLabel ?? 'Payment QR code for $displayName',
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
              style: BankTokens.bodyLarge
                  .copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w600,
                  )
                  .merge(titleStyle),
            ),
            if (accountMasked != null) ...[
              const SizedBox(height: 2),
              Text(
                accountMasked!,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(subtitleStyle),
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
                        setAmountIcon ?? Icons.tag_rounded,
                        size: 18,
                        color: accent,
                      ),
                      label: Text(
                        setAmountLabel,
                        style: BankTokens.labelLarge.copyWith(color: accent),
                      ),
                    ),
                  if (onShare != null && onSetAmount != null)
                    const SizedBox(width: BankTokens.space3),
                  if (onShare != null)
                    TextButton.icon(
                      onPressed: onShare,
                      icon: Icon(
                        shareIcon ?? BankIcons.share,
                        size: 18,
                        color: accent,
                      ),
                      label: Text(
                        shareLabel,
                        style: BankTokens.labelLarge.copyWith(color: accent),
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
