import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
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

    final semanticLabel = [
      atm.name,
      atm.address,
      distance,
      if (atm.feeFree) feeFreeLabel,
      if (atm.depositCapable) depositLabel,
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: theme.chipRadius,
                    ),
                    child: Center(
                      child: Icon(
                        BankIcons.location,
                        size: 22,
                        color: theme.primary,
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
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        atm.address,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant),
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
                      BankIcons.receive,
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
                      Icons.directions_outlined,
                      color: theme.primary,
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

  String _formatRemaining(Duration duration, NumeralStyle numeralStyle) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final raw = '$minutes:${seconds.toString().padLeft(2, '0')}';
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
    final ringColor = expired ? BankTokens.danger : theme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
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
                style: theme.numeralHero.copyWith(
                  color: expired ? theme.onSurfaceVariant : theme.onSurface,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: BankTokens.space2),
            BankBalanceText(
              money: widget.amount,
              size: BankBalanceSize.medium,
            ),
            const SizedBox(height: BankTokens.space4),
            Semantics(
              label: expired
                  ? widget.expiredLabel
                  : 'Time remaining '
                      '${_formatRemaining(_remaining, NumeralStyle.western)}',
              excludeSemantics: true,
              child: SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: CustomPaint(
                  painter: _CountdownRingPainter(
                    progress: progress,
                    color: ringColor,
                    trackColor: theme.surfaceVariant,
                  ),
                  child: Center(
                    child: Text(
                      _formatRemaining(_remaining, scope.numeralStyle),
                      style: theme.numeralSmall.copyWith(
                        color: expired ? BankTokens.danger : theme.onSurface,
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
