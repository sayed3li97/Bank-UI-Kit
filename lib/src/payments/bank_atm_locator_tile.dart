import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_surface_depth.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A nearby ATM or cash point surfaced by the locator.
///
/// Plain immutable data holder consumed by [BankAtmLocatorTile]; the host
/// app supplies instances from its own geo search.
@immutable
class BankAtmLocation {
  const BankAtmLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceMeters,
    this.feeFree = false,
    this.depositCapable = false,
  });

  /// Stable identifier from the host's ATM directory.
  final String id;

  /// Display name of the ATM or branch (e.g. 'Main Street Branch').
  final String name;

  /// Single-line street address shown under the name.
  final String address;

  /// Straight-line or walking distance from the user, in metres.
  final double distanceMeters;

  /// Whether withdrawals at this ATM are free of charge.
  final bool feeFree;

  /// Whether this ATM accepts cash or cheque deposits.
  final bool depositCapable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAtmLocation &&
          other.id == id &&
          other.name == name &&
          other.address == address &&
          other.distanceMeters == distanceMeters &&
          other.feeFree == feeFree &&
          other.depositCapable == depositCapable;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        address,
        distanceMeters,
        feeFree,
        depositCapable,
      );
}

/// A 64 px ATM-locator row: pin icon on a brand tint, name and address,
/// a distance chip ('350 m' or '1.2 km'), a positive 'Fee-free' chip when
/// the ATM waives fees, a deposit icon when it accepts deposits, and a
/// trailing directions button.
///
/// Use it inside the results list of an ATM / branch finder, the
/// cardless-cash flow, or a 'Cash nearby' section on the home screen.
/// Distance digits follow the active [NumeralStyle] from [BankUiScope].
///
/// ```dart
/// BankAtmLocatorTile(
///   atm: const BankAtmLocation(
///     id: 'atm-1',
///     name: 'Main Street Branch',
///     address: '12 Main Street, Downtown',
///     distanceMeters: 350,
///     feeFree: true,
///     depositCapable: true,
///   ),
///   onTap: () => showAtmDetails(atm),
///   onNavigate: () => openDirections(atm),
/// )
/// ```
class BankAtmLocatorTile extends StatelessWidget {
  const BankAtmLocatorTile({
    required this.atm,
    super.key,
    this.onTap,
    this.onNavigate,
    this.feeFreeLabel = 'Fee-free',
    this.depositLabel = 'Accepts deposits',
    this.navigateLabel = 'Directions',
    this.padding,
    this.height,
    this.leading,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.locationIcon,
    this.depositIcon,
    this.navigateIcon,
    this.semanticLabel,
  });

  /// The ATM to display.
  final BankAtmLocation atm;

  /// Called when the row body is tapped (e.g. open details or map pin).
  final VoidCallback? onTap;

  /// Called when the trailing directions button is pressed. The button is
  /// hidden when `null`.
  final VoidCallback? onNavigate;

  /// Label of the positive chip shown when [BankAtmLocation.feeFree].
  final String feeFreeLabel;

  /// Accessibility / tooltip label for the deposit-capable icon.
  final String depositLabel;

  /// Accessibility / tooltip label for the directions button.
  final String navigateLabel;

  /// Overrides the row content padding. Defaults to horizontal
  /// [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Overrides the row height. Defaults to 64.
  final double? height;

  /// Replaces the leading tinted pin block when set.
  final Widget? leading;

  /// Tint of the pin block and directions button. Defaults to the
  /// theme primary.
  final Color? accentColor;

  /// Merged over the computed ATM-name style.
  final TextStyle? titleStyle;

  /// Merged over the computed address style.
  final TextStyle? subtitleStyle;

  /// Glyph inside the leading pin block. Defaults to
  /// [BankIcons.location].
  final IconData? locationIcon;

  /// Glyph marking deposit-capable ATMs. Defaults to
  /// [BankIcons.receive].
  final IconData? depositIcon;

  /// Glyph of the directions button. Defaults to
  /// [Icons.directions_outlined].
  final IconData? navigateIcon;

  /// Overrides the computed row semantics label.
  final String? semanticLabel;

  /// Formats [BankAtmLocation.distanceMeters] as '350 m' below one
  /// kilometre and '1.2 km' above, then converts digits to [numeralStyle].
  String _formatDistance(double meters, NumeralStyle numeralStyle) {
    final String raw;
    if (meters < 1000) {
      raw = '${meters.round()} m';
    } else {
      var km = (meters / 1000).toStringAsFixed(1);
      if (km.endsWith('.0')) {
        km = km.substring(0, km.length - 2);
      }
      raw = '$km km';
    }
    return numeralStyle.convert(raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final distance = _formatDistance(atm.distanceMeters, scope.numeralStyle);
    final accent = accentColor ?? theme.primary;

    final computedSemantics = [
      atm.name,
      atm.address,
      distance,
      if (atm.feeFree) feeFreeLabel,
      if (atm.depositCapable) depositLabel,
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? computedSemantics,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height ?? 64,
          child: Padding(
            padding: padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: BankTokens.space4,
                ),
            child: Row(
              children: [
                leading ??
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: theme.chipRadius,
                        ),
                        child: Center(
                          child: Icon(
                            locationIcon ?? BankIcons.location,
                            size: 22,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atm.name,
                        style: BankTokens.bodyLarge
                            .copyWith(color: theme.onSurface)
                            .merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        atm.address,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(subtitleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                _AtmChip(
                  label: distance,
                  foreground: theme.onSurfaceVariant,
                  background: theme.surfaceVariant,
                  radius: theme.chipRadius,
                ),
                if (atm.feeFree) ...[
                  const SizedBox(width: BankTokens.space1),
                  _AtmChip(
                    label: feeFreeLabel,
                    foreground: theme.positiveBalance,
                    background: theme.positiveBalance.withValues(alpha: 0.12),
                    radius: theme.chipRadius,
                  ),
                ],
                if (atm.depositCapable) ...[
                  const SizedBox(width: BankTokens.space2),
                  Tooltip(
                    message: depositLabel,
                    child: Icon(
                      depositIcon ?? BankIcons.receive,
                      size: 16,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (onNavigate != null) ...[
                  const SizedBox(width: BankTokens.space1),
                  IconButton(
                    onPressed: onNavigate,
                    tooltip: navigateLabel,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        BankTokens.minTapTarget,
                        BankTokens.minTapTarget,
                      ),
                    ),
                    icon: Icon(
                      navigateIcon ?? Icons.directions_outlined,
                      color: accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tinted pill used for the distance and fee-free chips.
class _AtmChip extends StatelessWidget {
  const _AtmChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.radius,
  });

  final String label;
  final Color foreground;
  final Color background;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 2,
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// One-time cardless-cash withdrawal code card.
///
/// Shows the code in large spaced numerals (hero numeral scale, split
/// into groups of two or three digits), the withdrawal amount through
/// [BankBalanceText] (so privacy mode masks it), a circular countdown
/// ring that depletes toward [expiresAt] ticking once per second, an
/// expiry text line, and a cancel button. [onExpired] fires exactly once
/// when the ring reaches zero. Code and countdown digits follow the
/// active [NumeralStyle] from [BankUiScope].
///
/// Use it after the customer requests an ATM withdrawal without a card
/// (the cardless cash pattern), typically above a [BankAtmLocatorTile]
/// list of nearby ATMs.
///
/// ```dart
/// BankCardlessCashCode(
///   code: '48219306',
///   expiresAt: DateTime.now().add(const Duration(minutes: 10)),
///   amount: Money.fromDouble(200, 'AED'),
///   onCancel: cancelWithdrawal,
///   onExpired: showExpiredSheet,
/// )
/// ```
class BankCardlessCashCode extends StatefulWidget {
  const BankCardlessCashCode({
    required this.code,
    required this.expiresAt,
    required this.amount,
    super.key,
    this.onCancel,
    this.onExpired,
    this.cancelLabel = 'Cancel',
    this.expiredLabel = 'Code expired',
    this.expiresPrefix = 'Expires at',
    this.codeSemanticLabel = 'Cardless cash code',
    this.timeRemainingLabel = 'Time remaining',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.border,
    this.accentColor,
    this.ringSize,
    this.codeStyle,
    this.amountStyle,
  });

  /// The one-time withdrawal code (digits only).
  final String code;

  /// Moment the code stops working; drives the countdown ring.
  final DateTime expiresAt;

  /// The amount that will be dispensed, rendered via [BankBalanceText].
  final Money amount;

  /// Called when the cancel button is pressed. The button is hidden when
  /// `null` and disabled once the code has expired.
  final VoidCallback? onCancel;

  /// Fired exactly once when the countdown reaches zero.
  final VoidCallback? onExpired;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Text shown on the expiry line after the code has expired.
  final String expiredLabel;

  /// Prefix of the expiry line, followed by the expiry time.
  final String expiresPrefix;

  /// Accessibility prefix announced before the code digits.
  final String codeSemanticLabel;

  /// Accessibility prefix announced before the remaining time.
  final String timeRemainingLabel;

  /// Overrides the card content padding. Defaults to
  /// [BankTokens.space5] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme card
  /// radius.
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten the card.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Colour of the countdown ring while active. Defaults to the theme
  /// primary; the expired state keeps [BankTokens.danger].
  final Color? accentColor;

  /// Diameter of the countdown ring. Defaults to 72.
  final double? ringSize;

  /// Merged over the computed hero code style.
  final TextStyle? codeStyle;

  /// Merged over the computed amount style.
  final TextStyle? amountStyle;

  @override
  State<BankCardlessCashCode> createState() => _BankCardlessCashCodeState();
}

class _BankCardlessCashCodeState extends State<BankCardlessCashCode> {
  static const double _ringSize = 72;

  Timer? _ticker;
  Duration _window = Duration.zero;
  Duration _remaining = Duration.zero;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(BankCardlessCashCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expiresAt != oldWidget.expiresAt) {
      _expiredFired = false;
      _start();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    var window = widget.expiresAt.difference(DateTime.now());
    if (window.isNegative) window = Duration.zero;
    _window = window;
    _remaining = window;
    if (window == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fireExpired());
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
  }

  void _onTick(Timer timer) {
    var remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) remaining = Duration.zero;
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero) {
      timer.cancel();
      _fireExpired();
    }
  }

  void _fireExpired() {
    if (_expiredFired || !mounted) return;
    _expiredFired = true;
    widget.onExpired?.call();
  }

  /// Splits the code into groups of two or three digits, preferring
  /// threes and never leaving a lone trailing digit.
  String _groupedCode(String code) {
    final groups = <String>[];
    var index = 0;
    while (index < code.length) {
      final left = code.length - index;
      var take = 3;
      if (left == 4) take = 2;
      if (left <= 3) take = left;
      groups.add(code.substring(index, index + take));
      index += take;
    }
    return groups.join(' ');
  }

  /// Formats the remaining window at the precision that fits the ring:
  /// `m:ss` under an hour, `h:mm` under a day, whole days beyond that.
  /// Cardless codes live on minute scales, but a pathological input must
  /// still render as a short, non-overflowing string.
  String _formatRemaining(Duration duration, NumeralStyle numeralStyle) {
    final String raw;
    if (duration.inHours < 1) {
      final seconds = duration.inSeconds % 60;
      raw = '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
    } else if (duration.inDays < 1) {
      final minutes = duration.inMinutes % 60;
      raw = '${duration.inHours}:${minutes.toString().padLeft(2, '0')}';
    } else {
      raw = '${duration.inDays}d';
    }
    return numeralStyle.convert(raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final expired = _remaining == Duration.zero;

    final displayCode = scope.numeralStyle.convert(_groupedCode(widget.code));
    final expiryTime = scope.numeralStyle
        .convert(BankDateFormatter.formatTime(widget.expiresAt));
    final progress =
        _window.inSeconds == 0 ? 0.0 : _remaining.inSeconds / _window.inSeconds;
    final ringColor =
        expired ? BankTokens.danger : widget.accentColor ?? theme.primary;
    final ringSize = widget.ringSize ?? _ringSize;

    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: widget.backgroundColor,
      shadow: widget.shadow,
      border: widget.border,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.surface,
        borderRadius: widget.radius ?? theme.cardRadius,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(BankTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: '${widget.codeSemanticLabel}: $displayCode',
              excludeSemantics: true,
              child: Text(
                displayCode,
                // A numeric code reads as a fixed digit sequence in
                // every locale, so pin the run direction.
                textDirection: TextDirection.ltr,
                style: theme.numeralHero
                    .copyWith(
                      color: expired ? theme.onSurfaceVariant : theme.onSurface,
                      letterSpacing: 2,
                    )
                    .merge(widget.codeStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            BankBalanceText(
              money: widget.amount,
              size: BankBalanceSize.medium,
              style: widget.amountStyle == null
                  ? null
                  : theme.numeralMedium
                      .copyWith(color: theme.onSurface)
                      .merge(widget.amountStyle),
            ),
            const SizedBox(height: BankTokens.space4),
            Semantics(
              label: expired
                  ? widget.expiredLabel
                  : '${widget.timeRemainingLabel} '
                      '${_formatRemaining(_remaining, NumeralStyle.western)}',
              excludeSemantics: true,
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  painter: _CountdownRingPainter(
                    progress: progress,
                    color: ringColor,
                    trackColor: theme.surfaceVariant,
                  ),
                  child: Padding(
                    // Keep the digits inside the ring's inner circle; the
                    // FittedBox scales any still-longer string down instead
                    // of letting it wrap over the ring stroke.
                    padding: const EdgeInsets.all(
                      _CountdownRingPainter._stroke + BankTokens.space2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatRemaining(_remaining, scope.numeralStyle),
                        maxLines: 1,
                        style: theme.numeralSmall.copyWith(
                          color: expired ? BankTokens.danger : theme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BankTokens.space3),
            Text(
              expired
                  ? widget.expiredLabel
                  : '${widget.expiresPrefix} $expiryTime',
              style: BankTokens.bodySmall.copyWith(
                color: expired ? BankTokens.danger : theme.onSurfaceVariant,
              ),
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: BankTokens.space2),
              SizedBox(
                height: BankTokens.minTapTarget,
                child: TextButton(
                  onPressed: expired ? null : widget.onCancel,
                  child: Text(
                    widget.cancelLabel,
                    style: BankTokens.labelLarge.copyWith(
                      color:
                          expired ? theme.onSurfaceVariant : BankTokens.danger,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Paints the depleting countdown ring: a full muted track with the
/// remaining fraction drawn on top, starting at twelve o'clock.
class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  /// Remaining fraction of the window, 1.0 (full) to 0.0 (expired).
  final double progress;
  final Color color;
  final Color trackColor;

  static const double _stroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = (Offset.zero & size).deflate(_stroke / 2);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawOval(inner, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      inner,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
