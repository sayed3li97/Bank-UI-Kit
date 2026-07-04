import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Single-use virtual card surface, equivalent to a disposable card whose
/// number is retired after every purchase.
///
/// The tile renders a compact card visual: the theme accent gradient at
/// reduced saturation behind a dashed border (so the surface reads as
/// ephemeral), the [title] with a one-time badge, the masked card number
/// showing the current last four digits, and an [infoLine] microtext row.
/// A rotating-arrows watermark sits behind the content at low opacity.
///
/// When [numberUsed] is `true`, a notice row explains that the number was
/// retired and a regenerate button appears. Tapping it awaits
/// [onRegenerate]; while pending, the button shows an inline spinner and is
/// disabled. On success the displayed last four digits crossfade to the new
/// value over [BankTokens.durationBase] (250 ms); on failure an inline
/// error notice in [BankTokens.danger] is shown and the button re-enables.
///
/// Provide [onRevealDetails] to expose a reveal-details text button (for
/// example, to open a secure sheet with the full number and CVV).
///
/// The crossfade is skipped when the platform requests reduced motion.
///
/// ```dart
/// BankDisposableCardTile(
///   cardLast4: '4821',
///   numberUsed: lastPurchaseConsumedNumber,
///   onRegenerate: () async {
///     final card = await cardsApi.regenerateDisposableNumber();
///     return card.last4;
///   },
///   onRevealDetails: () => showSecureDetailsSheet(context),
/// )
/// ```
class BankDisposableCardTile extends StatefulWidget {
  /// Last four digits of the currently active disposable number.
  final String cardLast4;

  /// Whether the current number was consumed by a purchase and retired.
  final bool numberUsed;

  /// Requests a fresh disposable number; resolves with its new last four
  /// digits. Errors are caught and surfaced as an inline failure notice.
  final Future<String> Function() onRegenerate;

  /// Opens the secure card-details view. When `null`, the reveal-details
  /// button is hidden.
  final VoidCallback? onRevealDetails;

  /// Tile heading.
  final String title;

  /// Notice shown when [numberUsed] is `true`.
  final String usedNotice;

  /// Label of the regenerate button.
  final String regenerateLabel;

  /// Microtext explaining the disposable behaviour.
  final String infoLine;

  /// Text inside the one-time badge next to [title].
  final String badgeLabel;

  /// Label of the reveal-details button shown when [onRevealDetails] is
  /// provided.
  final String revealDetailsLabel;

  /// Inline notice shown when [onRegenerate] fails.
  final String regenerateFailedNotice;

  /// Overrides the tile content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the tile and dashed border radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the background gradient. Defaults to the desaturated theme
  /// accent gradient.
  final Gradient? gradient;

  /// Overrides the on-gradient content colour. Defaults to
  /// [BankThemeData.onPrimary].
  final Color? foregroundColor;

  /// Overrides the regenerate button label and spinner colour. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Merged over the computed title style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the masked number style ([BankTokens.numeralMedium]).
  final TextStyle? numberStyle;

  /// Merged over the computed [infoLine] style ([BankTokens.bodySmall]).
  final TextStyle? infoLineStyle;

  /// Merged over the computed badge style ([BankTokens.labelSmall]).
  final TextStyle? badgeLabelStyle;

  /// Background watermark glyph. Defaults to [BankIcons.repeat].
  final IconData watermarkIcon;

  /// Icon of the used-number notice. Defaults to [BankIcons.info].
  final IconData infoIcon;

  /// Icon of the failure notice. Defaults to [BankIcons.error].
  final IconData errorIcon;

  /// Icon of the reveal-details button. Defaults to [BankIcons.visibility].
  final IconData revealDetailsIcon;

  /// Duration of the last-four crossfade. Defaults to
  /// [BankTokens.durationBase]; reduced motion still forces zero.
  final Duration? animationDuration;

  /// Curve of the last-four crossfade. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides the computed tile semantics label. Defaults to the title,
  /// last four digits, and used notice when applicable.
  final String? semanticLabel;

  const BankDisposableCardTile({
    required this.cardLast4,
    required this.numberUsed,
    required this.onRegenerate,
    super.key,
    this.onRevealDetails,
    this.title = 'Disposable card',
    this.usedNotice = 'This number was used and has been retired',
    this.regenerateLabel = 'Generate new number',
    this.infoLine = 'The card number changes after every purchase',
    this.badgeLabel = 'One-time',
    this.revealDetailsLabel = 'Reveal details',
    this.regenerateFailedNotice = 'Could not generate a new number. Try again.',
    this.padding,
    this.radius,
    this.gradient,
    this.foregroundColor,
    this.accentColor,
    this.titleStyle,
    this.numberStyle,
    this.infoLineStyle,
    this.badgeLabelStyle,
    this.watermarkIcon = BankIcons.repeat,
    this.infoIcon = BankIcons.info,
    this.errorIcon = BankIcons.error,
    this.revealDetailsIcon = BankIcons.visibility,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  @override
  State<BankDisposableCardTile> createState() => _BankDisposableCardTileState();
}

class _BankDisposableCardTileState extends State<BankDisposableCardTile> {
  late String _displayLast4;
  bool _regenerating = false;
  bool _renewedLocally = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _displayLast4 = widget.cardLast4;
  }

  @override
  void didUpdateWidget(BankDisposableCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardLast4 != oldWidget.cardLast4) {
      _displayLast4 = widget.cardLast4;
      _renewedLocally = false;
    }
    if (widget.numberUsed != oldWidget.numberUsed) {
      _renewedLocally = false;
      _failed = false;
    }
  }

  /// The used section stays visible until the host clears
  /// [BankDisposableCardTile.numberUsed], except right after a successful
  /// in-tile regeneration.
  bool get _showUsedSection => widget.numberUsed && !_renewedLocally;

  Future<void> _handleRegenerate() async {
    setState(() {
      _regenerating = true;
      _failed = false;
    });
    String? next;
    try {
      next = await widget.onRegenerate();
    } on Exception {
      next = null;
    }
    if (!mounted) return;
    setState(() {
      _regenerating = false;
      if (next == null) {
        _failed = true;
      } else {
        _displayLast4 = next;
        _renewedLocally = true;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Surface helpers
  // ---------------------------------------------------------------------------

  Color _desaturate(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation(hsl.saturation * 0.55).toColor();
  }

  Gradient _washedGradient(BankThemeData theme) {
    final base = theme.accentGradient;
    final colors = base?.colors ?? [theme.primary, theme.primaryVariant];
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [for (final color in colors) _desaturate(color)],
      stops: base?.stops,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final resolvedDuration =
        widget.animationDuration ?? BankTokens.durationBase;
    final switchDuration = reduceMotion ? Duration.zero : resolvedDuration;

    final fg = widget.foregroundColor ?? theme.onPrimary;
    final fgMuted = fg.withValues(alpha: 0.72);
    final resolvedRadius = widget.radius ?? theme.cardRadius;
    final resolvedGradient = widget.gradient ?? _washedGradient(theme);
    final resolvedPadding =
        widget.padding ?? const EdgeInsets.all(BankTokens.space4);

    final defaultSemanticLabel = _showUsedSection
        ? '${widget.title}, card ending $_displayLast4. ${widget.usedNotice}'
        : '${widget.title}, card ending $_displayLast4';
    final semanticLabel = widget.semanticLabel ?? defaultSemanticLabel;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          radius: resolvedRadius,
          color: fg.withValues(alpha: 0.55),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: resolvedGradient,
            borderRadius: resolvedRadius,
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -16,
                bottom: -20,
                child: ExcludeSemantics(
                  child: Icon(
                    widget.watermarkIcon,
                    size: 116,
                    color: fg.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: resolvedPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(fg),
                    const SizedBox(height: BankTokens.space4),
                    _buildMaskedNumber(fg, switchDuration),
                    const SizedBox(height: BankTokens.space2),
                    Text(
                      widget.infoLine,
                      style: BankTokens.bodySmall
                          .copyWith(color: fgMuted)
                          .merge(widget.infoLineStyle),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: BankTokens.space3),
                      _buildFailureNotice(theme),
                    ],
                    if (_showUsedSection) ...[
                      const SizedBox(height: BankTokens.space3),
                      _buildUsedNotice(fg, fgMuted),
                      const SizedBox(height: BankTokens.space3),
                      _buildRegenerateButton(theme, fg),
                    ],
                    if (widget.onRevealDetails != null) ...[
                      const SizedBox(height: BankTokens.space1),
                      _buildRevealDetailsButton(fg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildHeader(Color fg) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: BankTokens.labelLarge
                .copyWith(color: fg)
                .merge(widget.titleStyle),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: BankTokens.space2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.16),
            borderRadius: BankThemeData.of(context).chipRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space2,
              vertical: BankTokens.space1,
            ),
            child: Text(
              widget.badgeLabel.toUpperCase(),
              style: BankTokens.labelSmall
                  .copyWith(color: fg)
                  .merge(widget.badgeLabelStyle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaskedNumber(Color fg, Duration switchDuration) {
    final resolvedCurve = widget.animationCurve ?? BankTokens.curveStandard;
    return AnimatedSwitcher(
      duration: switchDuration,
      switchInCurve: resolvedCurve,
      switchOutCurve: resolvedCurve,
      child: Text(
        '•••• •••• •••• $_displayLast4',
        key: ValueKey<String>(_displayLast4),
        style: BankTokens.numeralMedium
            .copyWith(
              color: fg,
              letterSpacing: 2.4,
            )
            .merge(widget.numberStyle),
        textDirection: TextDirection.ltr,
      ),
    );
  }

  Widget _buildFailureNotice(BankThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.9),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.errorIcon,
              size: 16,
              color: BankTokens.danger,
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                widget.regenerateFailedNotice,
                style: BankTokens.bodySmall.copyWith(
                  color: BankTokens.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedNotice(Color fg, Color fgMuted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(widget.infoIcon, size: 16, color: fgMuted),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Text(
            widget.usedNotice,
            style: BankTokens.bodySmall.copyWith(color: fg),
          ),
        ),
      ],
    );
  }

  Widget _buildRegenerateButton(BankThemeData theme, Color fg) {
    final accent = widget.accentColor ?? theme.primary;
    return Semantics(
      button: true,
      enabled: !_regenerating,
      label: widget.regenerateLabel,
      child: FilledButton(
        onPressed: _regenerating ? null : _handleRegenerate,
        style: FilledButton.styleFrom(
          backgroundColor: fg,
          foregroundColor: accent,
          disabledBackgroundColor: fg.withValues(alpha: 0.7),
          disabledForegroundColor: accent.withValues(alpha: 0.7),
          minimumSize: const Size(double.infinity, BankTokens.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          textStyle: BankTokens.labelLarge,
        ),
        child: _regenerating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              )
            : Text(widget.regenerateLabel),
      ),
    );
  }

  Widget _buildRevealDetailsButton(Color fg) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        label: widget.revealDetailsLabel,
        child: TextButton.icon(
          onPressed: widget.onRevealDetails,
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
          icon: Icon(widget.revealDetailsIcon, size: 18),
          label: Text(widget.revealDetailsLabel),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed border painter
// ---------------------------------------------------------------------------

/// Paints a dashed rounded-rectangle border so the disposable card surface
/// reads as ephemeral rather than permanent.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.radius,
    required this.color,
  });

  final BorderRadius radius;
  final Color color;

  static const double _strokeWidth = 1.4;
  static const double _dashLength = 6;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = radius.toRRect(Offset.zero & size).deflate(_strokeWidth / 2);
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dashLength),
          paint,
        );
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
