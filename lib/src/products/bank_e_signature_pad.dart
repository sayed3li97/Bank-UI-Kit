import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../common/bank_text_field.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------

/// How a signature was captured by [BankESignaturePad].
enum BankESignatureMethod {
  /// The user drew a signature on the canvas with a finger or stylus.
  drawn,

  /// The user typed their full name into the fallback field.
  typed,
}

/// Immutable result handed to [BankESignaturePad.onSigned] when the user
/// confirms their signature.
///
/// Carries the [method] used (drawn vs typed) and, when the user typed a
/// name (or typed one in addition to drawing), the [typedName] they entered.
@immutable
class BankESignatureResult {
  /// Creates a signature result.
  const BankESignatureResult({
    required this.method,
    this.typedName,
  });

  /// Whether the signature was drawn on the canvas or typed as a name.
  final BankESignatureMethod method;

  /// The typed full name, when the user entered one; otherwise `null`.
  final String? typedName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankESignatureResult &&
          other.method == method &&
          other.typedName == typedName;

  @override
  int get hashCode => Object.hash(method, typedName);

  @override
  String toString() =>
      'BankESignatureResult(method: $method, typedName: $typedName)';
}

// ---------------------------------------------------------------------------
// BankESignaturePad
// ---------------------------------------------------------------------------

/// E-signature capture surface for product application journeys.
///
/// Presents a bordered canvas the customer can draw on with a finger or
/// stylus, a `Clear` action, a typed-name fallback field for accessibility
/// and desktop, a captured-timestamp line, and a confirm button that is
/// enabled only once a signature has been drawn OR a name has been typed.
///
/// The [onSigned] callback receives a [BankESignatureResult] describing the
/// capture [BankESignatureMethod] and any typed name. The drawn strokes are
/// intentionally not exported: banks that need the raster can wrap the pad
/// or capture it themselves. The typed field is the accessible path, so the
/// canvas is excluded from semantics while the pad as a whole is labelled.
///
/// Inject [now] to make the timestamp deterministic in tests and golden
/// screenshots; it defaults to [DateTime.now]. The widget owns no animation
/// and so honours [MediaQuery] `disableAnimations` by construction.
///
/// ```dart
/// BankESignaturePad(
///   title: 'Sign to confirm',
///   onSigned: (result) {
///     debugPrint('Signed via ${result.method}: ${result.typedName}');
///   },
/// )
/// ```
class BankESignaturePad extends StatefulWidget {
  /// Creates an e-signature capture pad.
  const BankESignaturePad({
    super.key,
    this.onSigned,
    this.title = 'Your signature',
    this.typedNameHint = 'Or type your full name',
    this.clearLabel = 'Clear',
    this.signLabel = 'Sign',
    this.guideLabel = 'Sign here',
    this.timestampLabel = 'Captured',
    this.semanticLabel = 'Signature pad',
    this.now,
    this.header,
    this.footer,
    this.padding,
    this.radius,
    this.padRadius,
    this.backgroundColor,
    this.padColor,
    this.foregroundColor,
    this.guideColor,
    this.borderColor,
    this.shadow,
    this.titleStyle,
    this.timestampStyle,
    this.padHeight = 160,
    this.penStrokeWidth = 2.5,
  });

  /// Called when the user confirms a signature via the sign button.
  ///
  /// Receives a [BankESignatureResult] with the capture method and any
  /// typed name. When `null` the sign button renders but does nothing.
  final void Function(BankESignatureResult result)? onSigned;

  /// Heading shown above the pad. Defaults to `'Your signature'`.
  final String title;

  /// Hint text for the typed-name fallback field. Defaults to
  /// `'Or type your full name'`.
  final String typedNameHint;

  /// Label for the clear-canvas action. Defaults to `'Clear'`.
  final String clearLabel;

  /// Label for the confirm button. Defaults to `'Sign'`.
  final String signLabel;

  /// Faint prompt drawn on an empty canvas. Defaults to `'Sign here'`.
  final String guideLabel;

  /// Prefix for the captured-timestamp line. Defaults to `'Captured'`.
  final String timestampLabel;

  /// Semantics label describing the pad as a whole. Defaults to
  /// `'Signature pad'`.
  final String semanticLabel;

  /// Injectable clock used for the timestamp line. Defaults to
  /// [DateTime.now]; pass a fixed function for deterministic tests.
  final DateTime Function()? now;

  /// Optional replacement for the default [title] header row.
  final Widget? header;

  /// Optional footer slot for legal microcopy under the pad.
  final Widget? footer;

  /// Overrides the outer content padding. Defaults to a uniform
  /// [BankTokens.space4] inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides the outer card radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the drawing canvas radius. Defaults to
  /// [BankTokens.radiusMedium] on all corners.
  final BorderRadius? padRadius;

  /// Overrides the outer card surface. Defaults to
  /// [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the drawing canvas fill. Defaults to
  /// [BankThemeData.surfaceVariant].
  final Color? padColor;

  /// Overrides the pen (stroke) colour. Defaults to
  /// [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Overrides the guide baseline colour. Defaults to
  /// [BankThemeData.outline].
  final Color? guideColor;

  /// Overrides the canvas border colour. Defaults to
  /// [BankThemeData.outline].
  final Color? borderColor;

  /// Overrides the outer card shadow. Defaults to [BankTokens.shadowCard];
  /// pass `const []` to flatten it.
  final List<BoxShadow>? shadow;

  /// Merged over the computed title style ([BankTokens.headlineSmall]).
  final TextStyle? titleStyle;

  /// Merged over the computed timestamp style ([BankTokens.bodySmall]).
  final TextStyle? timestampStyle;

  /// Height of the drawing canvas in logical pixels. Defaults to `160`.
  final double padHeight;

  /// Width of the drawn pen stroke in logical pixels. Defaults to `2.5`.
  final double penStrokeWidth;

  @override
  State<BankESignaturePad> createState() => _BankESignaturePadState();
}

class _BankESignaturePadState extends State<BankESignaturePad> {
  final TextEditingController _nameController = TextEditingController();
  final List<List<Offset>> _strokes = <List<Offset>>[];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  bool get _hasDrawn => _strokes.isNotEmpty;

  bool get _hasTyped => _nameController.text.trim().isNotEmpty;

  bool get _canSign => _hasDrawn || _hasTyped;

  void _startStroke(Offset point) =>
      setState(() => _strokes.add(<Offset>[point]));

  void _extendStroke(Offset point) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(point));
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(_strokes.clear);
  }

  void _sign() {
    if (!_canSign) return;
    final method =
        _hasDrawn ? BankESignatureMethod.drawn : BankESignatureMethod.typed;
    final typedName = _hasTyped ? _nameController.text.trim() : null;
    widget.onSigned?.call(
      BankESignatureResult(method: method, typedName: typedName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final resolvedPadding =
        widget.padding ?? const EdgeInsets.all(BankTokens.space4);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedPadRadius = widget.padRadius ??
        const BorderRadius.all(Radius.circular(BankTokens.radiusMedium));
    final resolvedBackground = widget.backgroundColor ?? theme.surface;
    final resolvedPadColor = widget.padColor ?? theme.surfaceVariant;
    final resolvedPen = widget.foregroundColor ?? theme.onSurface;
    final resolvedGuide = widget.guideColor ?? theme.outline;
    final resolvedBorder = widget.borderColor ?? theme.outline;
    final resolvedShadow = widget.shadow ?? BankTokens.shadowCard;

    final clock = widget.now ?? DateTime.now;
    final timestamp = BankDateFormatter.formatLong(clock());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: resolvedRadius,
        boxShadow: resolvedShadow,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.header ??
                Text(
                  widget.title,
                  style: BankTokens.headlineSmall
                      .copyWith(color: theme.onSurface)
                      .merge(widget.titleStyle),
                ),
            const SizedBox(height: BankTokens.space3),
            Semantics(
              label: widget.semanticLabel,
              excludeSemantics: true,
              child: _SignatureCanvas(
                strokes: _strokes,
                padColor: resolvedPadColor,
                penColor: resolvedPen,
                guideColor: resolvedGuide,
                borderColor: resolvedBorder,
                radius: resolvedPadRadius,
                height: widget.padHeight,
                strokeWidth: widget.penStrokeWidth,
                guideLabel: widget.guideLabel,
                showGuide: !_hasDrawn,
                onStart: _startStroke,
                onExtend: _extendStroke,
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.timestampLabel}: $timestamp',
                    style: BankTokens.bodySmall
                        .copyWith(color: theme.onSurfaceVariant)
                        .merge(widget.timestampStyle),
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                Semantics(
                  button: true,
                  enabled: _hasDrawn,
                  label: widget.clearLabel,
                  child: TextButton.icon(
                    onPressed: _hasDrawn ? _clear : null,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(widget.clearLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BankTokens.space3),
            BankTextField(
              controller: _nameController,
              hint: widget.typedNameHint,
              textInputAction: TextInputAction.done,
            ),
            if (widget.footer != null) ...[
              const SizedBox(height: BankTokens.space3),
              widget.footer!,
            ],
            const SizedBox(height: BankTokens.space4),
            Semantics(
              button: true,
              enabled: _canSign,
              label: widget.signLabel,
              child: FilledButton(
                onPressed: _canSign ? _sign : null,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.buttonRadius,
                  ),
                ),
                child: Text(widget.signLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawing canvas
// ---------------------------------------------------------------------------

class _SignatureCanvas extends StatelessWidget {
  const _SignatureCanvas({
    required this.strokes,
    required this.padColor,
    required this.penColor,
    required this.guideColor,
    required this.borderColor,
    required this.radius,
    required this.height,
    required this.strokeWidth,
    required this.guideLabel,
    required this.showGuide,
    required this.onStart,
    required this.onExtend,
  });

  final List<List<Offset>> strokes;
  final Color padColor;
  final Color penColor;
  final Color guideColor;
  final Color borderColor;
  final BorderRadius radius;
  final double height;
  final double strokeWidth;
  final String guideLabel;
  final bool showGuide;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onExtend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: padColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: GestureDetector(
            onPanStart: (details) => onStart(details.localPosition),
            onPanUpdate: (details) => onExtend(details.localPosition),
            child: CustomPaint(
              painter: _SignaturePainter(
                strokes: strokes,
                penColor: penColor,
                guideColor: guideColor,
                strokeWidth: strokeWidth,
                showGuide: showGuide,
              ),
              child: showGuide
                  ? Center(
                      child: Text(
                        guideLabel,
                        style: BankTokens.bodyMedium.copyWith(
                          color: guideColor,
                        ),
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.strokes,
    required this.penColor,
    required this.guideColor,
    required this.strokeWidth,
    required this.showGuide,
  });

  final List<List<Offset>> strokes;
  final Color penColor;
  final Color guideColor;
  final double strokeWidth;
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    // Guide baseline sits at 75% height, inset from both edges.
    final baselineY = size.height * 0.75;
    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(BankTokens.space4, baselineY),
      Offset(size.width - BankTokens.space4, baselineY),
      guidePaint,
    );

    final penPaint = Paint()
      ..color = penColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawPoints(PointMode.points, stroke, penPaint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, penPaint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.penColor != penColor ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.showGuide != showGuide;
}
