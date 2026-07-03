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
    final switchDuration =
        reduceMotion ? Duration.zero : BankTokens.durationBase;

    final fg = theme.onPrimary;
    final fgMuted = fg.withValues(alpha: 0.72);

    final semanticLabel = _showUsedSection
        ? '${widget.title}, card ending $_displayLast4. ${widget.usedNotice}'
        : '${widget.title}, card ending $_displayLast4';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          radius: theme.cardRadius,
          color: fg.withValues(alpha: 0.55),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: _washedGradient(theme),
            borderRadius: theme.cardRadius,
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -16,
                bottom: -20,
                child: ExcludeSemantics(
                  child: Icon(
                    BankIcons.repeat,
                    size: 116,
                    color: fg.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BankTokens.space4),
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
                      style: BankTokens.bodySmall.copyWith(color: fgMuted),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: BankTokens.space3),
                      _buildFailureNotice(theme),
                    ],
                    if (_showUsedSection) ...[
                      const SizedBox(height: BankTokens.space3),
                      _buildUsedNotice(fg, fgMuted),
                      const SizedBox(height: BankTokens.space3),
                      _buildRegenerateButton(theme),
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
            style: BankTokens.labelLarge.copyWith(color: fg),
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
              style: BankTokens.labelSmall.copyWith(color: fg),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaskedNumber(Color fg, Duration switchDuration) {
    return AnimatedSwitcher(
      duration: switchDuration,
      switchInCurve: BankTokens.curveStandard,
      switchOutCurve: BankTokens.curveStandard,
      child: Text(
        '•••• •••• •••• $_displayLast4',
        key: ValueKey<String>(_displayLast4),
        style: BankTokens.numeralMedium.copyWith(
          color: fg,
          letterSpacing: 2.4,
        ),
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
            const Icon(
              BankIcons.error,
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
        Icon(BankIcons.info, size: 16, color: fgMuted),
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

  Widget _buildRegenerateButton(BankThemeData theme) {
    return Semantics(
      button: true,
      enabled: !_regenerating,
      label: widget.regenerateLabel,
      child: FilledButton(
        onPressed: _regenerating ? null : _handleRegenerate,
        style: FilledButton.styleFrom(
          backgroundColor: theme.onPrimary,
          foregroundColor: theme.primary,
          disabledBackgroundColor: theme.onPrimary.withValues(alpha: 0.7),
          disabledForegroundColor: theme.primary.withValues(alpha: 0.7),
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
                  color: theme.primary,
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
          icon: const Icon(BankIcons.visibility, size: 18),
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
