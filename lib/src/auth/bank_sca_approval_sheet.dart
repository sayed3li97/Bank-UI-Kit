import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_bidi.dart';
import '../common/bank_emblem.dart';
import '../common/bank_icon_spec.dart';
import '../common/bank_sheet.dart';
import '../common/money_formatter.dart';
import '../l10n/bank_strings.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_biometric_prompt_button.dart';
import 'bank_pin_dots.dart';
import 'bank_pin_keypad.dart';

/// Authentication methods a [BankScaApprovalSheet] can offer.
enum BankScaMethod {
  /// Device biometric (fingerprint / face).
  biometric,

  /// Transaction PIN entered on the in-sheet keypad.
  pin,

  /// Out-of-band confirmation in another device or authenticator app.
  pushConfirm,
}

/// Called when the customer completes an authentication attempt.
///
/// [pin] is non-null only for [BankScaMethod.pin]. Return `true` to
/// approve, `false` to signal a failed verification (the sheet shakes and
/// offers an alternate method).
typedef BankScaApproveCallback = Future<bool> Function(
  BankScaMethod method,
  String? pin,
);

/// A payment-bound strong-customer-authentication sheet implementing the
/// PSD2 dynamic-linking pattern: the amount and payee stay visible and
/// cannot be scrolled away while the customer authenticates.
///
/// The amount is deliberately rendered WITHOUT the scope privacy mask -
/// dynamic linking requires the customer to see exactly what they are
/// approving.
///
/// ## Colour
///
/// This is the highest-stakes surface in the kit, so it spends exactly two
/// kinds of colour and no decoration:
///
/// - **one accent** ([accentColor], the theme primary) for the security
///   mark, the alternate-method link, and the waiting spinner — the parts
///   that say "this is your bank asking";
/// - **one status colour at a time**, and only when there is a status to
///   report: [BankThemeData.pending] once the countdown is genuinely short,
///   [BankThemeData.negativeBalance] on a failed verification,
///   [BankThemeData.positiveBalance] on approval. They are mutually
///   exclusive by construction.
///
/// A permanently amber header and a permanently amber countdown chip
/// (which is what this sheet used to ship) spend the alarm colour before
/// anything is wrong, so nothing is left to say when the timer actually
/// runs out. Everything else is theme ink on the theme surface.
///
/// Present it with [BankScaApprovalSheet.show], which resolves `true` on
/// approval, `false` on rejection or expiry, and blocks drag/tap dismissal.
///
/// ```dart
/// final approved = await BankScaApprovalSheet.show(
///   context,
///   amount: Money.fromDouble(1250.00, 'SAR'),
///   payeeName: 'Acme Trading LLC',
///   payeeAccountMasked: 'SA44 •••• 9021',
///   onApprove: (method, pin) => verifyWithBackend(method, pin),
///   onReject: () {},
/// );
/// ```
class BankScaApprovalSheet extends StatefulWidget {
  // The shipped English for each copy parameter, kept as a constant so
  // `BankStrings.override` can tell a host's wording from the default.
  static const String _kTitle = 'Confirm payment';
  static const String _kRejectLabel = 'Reject payment';
  static const String _kUsePinLabel = 'Use PIN instead';
  static const String _kUseBiometricLabel = 'Use biometrics instead';
  static const String _kPushWaitingLabel =
      'Approve this payment in your authenticator';
  static const String _kExpiresPrefix = 'Expires in';
  static const String _kAmountSemanticPrefix = 'Amount';

  const BankScaApprovalSheet({
    required this.amount,
    required this.payeeName,
    required this.onApprove,
    required this.onReject,
    super.key,
    this.payeeAccountMasked,
    this.reference,
    this.expiresAt,
    this.methods = const {BankScaMethod.biometric, BankScaMethod.pin},
    this.pinLength = 4,
    this.title = _kTitle,
    this.rejectLabel = _kRejectLabel,
    this.usePinLabel = _kUsePinLabel,
    this.useBiometricLabel = _kUseBiometricLabel,
    this.pushWaitingLabel = _kPushWaitingLabel,
    this.expiresPrefix = _kExpiresPrefix,
    this.expiryWarningThreshold = const Duration(minutes: 1),
    this.padding,
    this.amountStyle,
    this.titleStyle,
    this.headerIcon,
    this.successIcon,
    this.successColor,
    this.accentColor,
    this.rejectColor,
    this.amountSemanticPrefix = _kAmountSemanticPrefix,
  });

  /// The exact amount being authorized. Never privacy-masked here.
  final Money amount;

  final String payeeName;

  /// Verifies the attempt with the host backend.
  final BankScaApproveCallback onApprove;

  /// Fired when the customer explicitly rejects. The sheet pops `false`.
  final VoidCallback onReject;

  /// Masked destination account, e.g. `'SA44 •••• 9021'`.
  final String? payeeAccountMasked;

  /// Payment reference shown under the payee row.
  final String? reference;

  /// When set, a countdown chip ticks down and the sheet auto-resolves
  /// `false` at zero.
  final DateTime? expiresAt;

  /// Which authentication methods to offer. The first available of
  /// biometric → pin → pushConfirm becomes the initial method.
  final Set<BankScaMethod> methods;

  /// Digits required for [BankScaMethod.pin].
  final int pinLength;

  final String title;
  final String rejectLabel;
  final String usePinLabel;
  final String useBiometricLabel;
  final String pushWaitingLabel;
  final String expiresPrefix;

  /// How much time must be left before the countdown chip escalates from
  /// neutral ink to the theme's pending colour. Defaults to one minute.
  ///
  /// The chip is factual until it is urgent: a countdown that is amber for
  /// its whole five minutes has told the customer nothing by the time it
  /// has thirty seconds left.
  final Duration expiryWarningThreshold;

  /// Outer content padding of the sheet. Defaults to symmetric horizontal
  /// [BankTokens.space5] and vertical [BankTokens.space4] when null.
  final EdgeInsetsGeometry? padding;

  /// Text style merged over the computed amount style (numeral hero in the
  /// theme foreground and font family). Null applies no override.
  final TextStyle? amountStyle;

  /// Text style merged over the computed header title style (headline small
  /// in the theme foreground). Null applies no override.
  final TextStyle? titleStyle;

  /// Glyph for the header security icon. Defaults to [BankIcons.shield]
  /// when null.
  ///
  /// A shield, not the warning-badged [Icons.gpp_maybe_outlined] this used
  /// to draw: nothing has gone wrong yet, and the header's job is to say
  /// the request is authentic.
  final IconData? headerIcon;

  /// Glyph for the success confirmation icon. Defaults to
  /// [Icons.check_circle_rounded] when null.
  final IconData? successIcon;

  /// Color of the success confirmation icon. Defaults to the theme
  /// `positiveBalance` when null.
  final Color? successColor;

  /// The sheet's single accent: the header security mark, the
  /// alternate-method link, and the out-of-band spinner. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Ink of the reject action. Defaults to
  /// [BankThemeData.negativeBalance], which is brightness-corrected per
  /// preset — unlike the raw [BankTokens.danger] this used to paint, which
  /// fails contrast on the kit's dark surfaces.
  final Color? rejectColor;

  /// Prefix used in the amount accessibility label, joined as
  /// `'<prefix>: <amount>'`. Defaults to `'Amount'`.
  final String amountSemanticPrefix;

  /// Presents the sheet modally. Resolves `true` when approved, `false`
  /// when rejected or expired, `null` never (dismissal is disabled).
  static Future<bool?> show(
    BuildContext context, {
    required Money amount,
    required String payeeName,
    required BankScaApproveCallback onApprove,
    required VoidCallback onReject,
    String? payeeAccountMasked,
    String? reference,
    DateTime? expiresAt,
    Set<BankScaMethod> methods = const {
      BankScaMethod.biometric,
      BankScaMethod.pin,
    },
    int pinLength = 4,
    String title = _kTitle,
    String rejectLabel = _kRejectLabel,
    String usePinLabel = _kUsePinLabel,
    String useBiometricLabel = _kUseBiometricLabel,
    String pushWaitingLabel = _kPushWaitingLabel,
    String expiresPrefix = _kExpiresPrefix,
    Duration expiryWarningThreshold = const Duration(minutes: 1),
    EdgeInsetsGeometry? padding,
    TextStyle? amountStyle,
    TextStyle? titleStyle,
    IconData? headerIcon,
    IconData? successIcon,
    Color? successColor,
    Color? accentColor,
    Color? rejectColor,
    String amountSemanticPrefix = _kAmountSemanticPrefix,
    Color? backgroundColor,
    BorderRadius? sheetRadius,
    bool? showHandle,
  }) =>
      // Presentation — branded ground, sheet radius, floating depth, token
      // motion, scrim, and the grab handle — all come from BankSheet; this
      // sheet contributes only its body.
      //
      // Strong-customer authentication must be completed or explicitly
      // rejected, so the sheet is neither dismissible nor draggable, and
      // BankSheet's `showHandle ?? enableDrag` rule therefore drops the
      // handle: a grab bar on a surface that cannot be dragged is an
      // affordance that lies. Hosts whose SCA flow *is* dismissible pass
      // [showHandle] explicitly.
      BankSheet.show<bool>(
        context,
        isDismissible: false,
        enableDrag: false,
        showHandle: showHandle,
        backgroundColor: backgroundColor,
        radius: sheetRadius,
        builder: (_) => BankScaApprovalSheet(
          amount: amount,
          payeeName: payeeName,
          onApprove: onApprove,
          onReject: onReject,
          payeeAccountMasked: payeeAccountMasked,
          reference: reference,
          expiresAt: expiresAt,
          methods: methods,
          pinLength: pinLength,
          title: title,
          rejectLabel: rejectLabel,
          usePinLabel: usePinLabel,
          useBiometricLabel: useBiometricLabel,
          pushWaitingLabel: pushWaitingLabel,
          expiresPrefix: expiresPrefix,
          expiryWarningThreshold: expiryWarningThreshold,
          padding: padding,
          amountStyle: amountStyle,
          titleStyle: titleStyle,
          headerIcon: headerIcon,
          successIcon: successIcon,
          successColor: successColor,
          accentColor: accentColor,
          rejectColor: rejectColor,
          amountSemanticPrefix: amountSemanticPrefix,
        ),
      );

  @override
  State<BankScaApprovalSheet> createState() => _BankScaApprovalSheetState();
}

class _BankScaApprovalSheetState extends State<BankScaApprovalSheet> {
  /// How long the success check stays on screen before the sheet pops.
  ///
  /// A confirmation the customer never sees is not a confirmation; a rung
  /// of the motion scale keeps that beat in step with the sheet's own exit
  /// instead of inventing a duration for it.
  static const Duration _successDwell = BankTokens.durationXSlow;

  late BankScaMethod _method;
  String _pin = '';
  bool _pinError = false;
  bool _busy = false;
  bool _succeeded = false;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    _method = _initialMethod();
    final expiry = widget.expiresAt;
    if (expiry != null) {
      _remaining = expiry.difference(DateTime.now());
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  BankScaMethod _initialMethod() {
    for (final method in const [
      BankScaMethod.biometric,
      BankScaMethod.pin,
      BankScaMethod.pushConfirm,
    ]) {
      if (widget.methods.contains(method)) return method;
    }
    return BankScaMethod.pin;
  }

  void _tick() {
    final expiry = widget.expiresAt;
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      if (mounted && !_succeeded) Navigator.of(context).pop(false);
      return;
    }
    setState(() => _remaining = remaining);
  }

  BankScaMethod? get _alternate {
    final others = widget.methods.where((m) => m != _method);
    return others.isEmpty ? null : others.first;
  }

  Future<void> _attempt(BankScaMethod method, String? pin) async {
    setState(() {
      _busy = true;
      _pinError = false;
    });
    var approved = false;
    try {
      approved = await widget.onApprove(method, pin);
    } on Object {
      approved = false;
    }
    if (!mounted) return;
    if (approved) {
      setState(() => _succeeded = true);
      _ticker?.cancel();
      await Future<void>.delayed(_successDwell);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _pinError = method == BankScaMethod.pin;
    });
  }

  void _onDigit(String digit) {
    if (_busy || _pin.length >= widget.pinLength) return;
    setState(() {
      _pin += digit;
      _pinError = false;
    });
    if (_pin.length == widget.pinLength) {
      unawaited(_attempt(BankScaMethod.pin, _pin));
    }
  }

  void _onDelete() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  String _formatRemaining() {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Whether the countdown has entered the window where the remaining time
  /// is itself the message.
  bool get _expiringSoon =>
      widget.expiresAt != null &&
      _remaining > Duration.zero &&
      _remaining <= widget.expiryWarningThreshold;

  /// Resolves a copy parameter whose default is the shipped English.
  ///
  /// The parameter is non-nullable, so nullability cannot say whether the
  /// host chose this wording; comparing against the constant can, and does
  /// so without changing the sheet's signature.
  String _resolve(String value, String shipped, String translated) =>
      BankStrings.override(value, shipped) ?? translated;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final strings = BankStrings.of(context);
    final accent = widget.accentColor ?? theme.primary;
    final expiresPrefix = _resolve(
      widget.expiresPrefix,
      BankScaApprovalSheet._kExpiresPrefix,
      strings.scaExpiresIn,
    );
    final amountPrefix = _resolve(
      widget.amountSemanticPrefix,
      BankScaApprovalSheet._kAmountSemanticPrefix,
      strings.labelAmount,
    );

    // Dynamic linking: the approved amount is always visible, never masked.
    final formattedAmount = BankMoneyFormatter.format(
      amount: widget.amount.amount,
      currencyCode: widget.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return SafeArea(
      child: Padding(
        padding: widget.padding ??
            const EdgeInsets.fromLTRB(
              BankTokens.space5,
              BankTokens.space4,
              BankTokens.space5,
              BankTokens.space4,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: _resolve(
                widget.title,
                BankScaApprovalSheet._kTitle,
                strings.scaConfirmPayment,
              ),
              theme: theme,
              accent: accent,
              expiryChip: widget.expiresAt == null
                  ? null
                  : '$expiresPrefix ${_formatRemaining()}',
              expiringSoon: _expiringSoon,
              titleStyle: widget.titleStyle,
              icon: widget.headerIcon,
            ),
            const SizedBox(height: BankTokens.space4),
            Semantics(
              label: '$amountPrefix: $formattedAmount',
              excludeSemantics: true,
              child: Text(
                formattedAmount,
                style: BankTokens.numeralHero
                    .copyWith(
                      color: theme.onSurface,
                      fontFamily: theme.fontFamily,
                    )
                    .merge(widget.amountStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: BankTokens.space4),
            _PayeeRow(
              name: widget.payeeName,
              accountMasked: widget.payeeAccountMasked,
              reference: widget.reference,
              theme: theme,
            ),
            const SizedBox(height: BankTokens.space5),
            if (_succeeded)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: BankTokens.space6,
                ),
                child: Icon(
                  widget.successIcon ?? Icons.check_circle_rounded,
                  size: BankTokens.iconHero,
                  color: widget.successColor ?? theme.positiveBalance,
                ),
              )
            else
              _methodWidget(theme, accent, strings),
            if (!_succeeded) ...[
              const SizedBox(height: BankTokens.space3),
              if (_alternate != null && !_busy)
                TextButton(
                  onPressed: () => setState(() {
                    _method = _alternate!;
                    _pin = '';
                    _pinError = false;
                    _pushStarted = false;
                  }),
                  child: Text(
                    _alternate == BankScaMethod.pin
                        ? _resolve(
                            widget.usePinLabel,
                            BankScaApprovalSheet._kUsePinLabel,
                            strings.scaUsePinInstead,
                          )
                        : _resolve(
                            widget.useBiometricLabel,
                            BankScaApprovalSheet._kUseBiometricLabel,
                            strings.scaUseBiometricsInstead,
                          ),
                    style: BankTokens.labelLarge.copyWith(color: accent),
                  ),
                ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        widget.onReject();
                        Navigator.of(context).pop(false);
                      },
                child: Text(
                  _resolve(
                    widget.rejectLabel,
                    BankScaApprovalSheet._kRejectLabel,
                    strings.scaRejectPayment,
                  ),
                  style: BankTokens.labelLarge.copyWith(
                    color: widget.rejectColor ?? theme.negativeBalance,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodWidget(
    BankThemeData theme,
    Color accent,
    BankStrings strings,
  ) {
    switch (_method) {
      case BankScaMethod.biometric:
        return BankBiometricPromptButton(
          onAuthenticate: () => widget.onApprove(BankScaMethod.biometric, null),
          onSuccess: () {
            setState(() => _succeeded = true);
            _ticker?.cancel();
            unawaited(
              Future<void>.delayed(_successDwell).then((_) {
                if (mounted) Navigator.of(context).pop(true);
              }),
            );
          },
        );
      case BankScaMethod.pin:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BankPinDots(
              filled: _pin.length,
              length: widget.pinLength,
              error: _pinError,
            ),
            const SizedBox(height: BankTokens.space4),
            BankPinKeypad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              enabled: !_busy,
            ),
          ],
        );
      case BankScaMethod.pushConfirm:
        if (!_pushStarted) {
          _pushStarted = true;
          unawaited(_attempt(BankScaMethod.pushConfirm, null));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: BankTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: BankTokens.iconHero,
                height: BankTokens.iconHero,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: accent,
                ),
              ),
              const SizedBox(height: BankTokens.space4),
              Text(
                _resolve(
                  widget.pushWaitingLabel,
                  BankScaApprovalSheet._kPushWaitingLabel,
                  strings.scaAuthenticatorPrompt,
                ),
                style: BankTokens.bodyMedium
                    .copyWith(color: theme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.theme,
    required this.accent,
    required this.expiringSoon,
    this.expiryChip,
    this.titleStyle,
    this.icon,
  });

  final String title;
  final BankThemeData theme;
  final Color accent;
  final bool expiringSoon;
  final String? expiryChip;
  final TextStyle? titleStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // The chip carries the accent's neutral tier until the countdown is
    // actually short, at which point — and only then — it takes the
    // pending colour. One escalation, one meaning.
    final chipInk = expiringSoon ? theme.pending : theme.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          icon ?? BankIcons.shield,
          size: BankTokens.iconLarge,
          color: accent,
        ),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Text(
            title,
            style: BankTokens.headlineSmall
                .copyWith(color: theme.onSurface, fontFamily: theme.fontFamily)
                .merge(titleStyle),
          ),
        ),
        if (expiryChip != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: chipInk.withValues(alpha: BankTokens.alphaMuted),
              borderRadius: theme.chipRadius,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: BankTokens.space2,
                vertical: 2,
              ),
              child: Text(
                expiryChip!,
                // Tabular numerals: without them the countdown's digits
                // change width every second and the chip twitches.
                style: theme.numeralSmall.copyWith(
                  color: chipInk,
                  fontSize: BankTokens.labelSmall.fontSize,
                  fontWeight: BankTokens.labelSmall.fontWeight,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PayeeRow extends StatelessWidget {
  const _PayeeRow({
    required this.name,
    required this.theme,
    this.accountMasked,
    this.reference,
  });

  final String name;
  final BankThemeData theme;
  final String? accountMasked;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BankEmblem(initialsFrom: name),
        const SizedBox(width: BankTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: BankTokens.bodyLarge.copyWith(
                  color: theme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // The destination mask is what dynamic linking asks the
              // customer to check, so it keeps full ink and tabular
              // numerals instead of sharing a caption-grey line with the
              // payment reference.
              if (accountMasked != null)
                Text(
                  // The one string on this sheet the customer is asked to
                  // check character by character before approving, so its
                  // groups keep their order in an Arabic paragraph. The
                  // payment reference below is left alone: it is as often
                  // free-form remittance text as it is a token, and an
                  // isolate around prose changes how that prose lays out.
                  BankBidi.isolate(accountMasked!),
                  style: theme.numeralSmall.copyWith(color: theme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (reference != null)
                Text(
                  reference!,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
