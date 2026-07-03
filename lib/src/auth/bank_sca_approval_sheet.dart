import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/money_formatter.dart';
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
    this.title = 'Confirm payment',
    this.rejectLabel = 'Reject payment',
    this.usePinLabel = 'Use PIN instead',
    this.useBiometricLabel = 'Use biometrics instead',
    this.pushWaitingLabel = 'Approve this payment in your authenticator',
    this.expiresPrefix = 'Expires in',
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
    String title = 'Confirm payment',
    String rejectLabel = 'Reject payment',
    String usePinLabel = 'Use PIN instead',
    String useBiometricLabel = 'Use biometrics instead',
    String pushWaitingLabel = 'Approve this payment in your authenticator',
    String expiresPrefix = 'Expires in',
  }) {
    final theme = BankThemeData.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
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
      ),
    );
  }

  @override
  State<BankScaApprovalSheet> createState() => _BankScaApprovalSheetState();
}

class _BankScaApprovalSheetState extends State<BankScaApprovalSheet> {
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
      await Future<void>.delayed(const Duration(milliseconds: 750));
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

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    // Dynamic linking: the approved amount is always visible, never masked.
    final formattedAmount = BankMoneyFormatter.format(
      amount: widget.amount.amount,
      currencyCode: widget.amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BankTokens.space5,
          BankTokens.space4,
          BankTokens.space5,
          BankTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: widget.title,
              theme: theme,
              expiryChip: widget.expiresAt == null
                  ? null
                  : '${widget.expiresPrefix} ${_formatRemaining()}',
            ),
            const SizedBox(height: BankTokens.space4),
            Semantics(
              label: 'Amount: $formattedAmount',
              excludeSemantics: true,
              child: Text(
                formattedAmount,
                style: BankTokens.numeralHero.copyWith(
                  color: theme.onSurface,
                  fontFamily: theme.fontFamily,
                ),
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
                  Icons.check_circle_rounded,
                  size: 64,
                  color: theme.positiveBalance,
                ),
              )
            else
              _methodWidget(theme),
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
                        ? widget.usePinLabel
                        : widget.useBiometricLabel,
                    style: BankTokens.labelLarge.copyWith(color: theme.primary),
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
                  widget.rejectLabel,
                  style:
                      BankTokens.labelLarge.copyWith(color: BankTokens.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodWidget(BankThemeData theme) {
    switch (_method) {
      case BankScaMethod.biometric:
        return BankBiometricPromptButton(
          onAuthenticate: () => widget.onApprove(BankScaMethod.biometric, null),
          onSuccess: () {
            setState(() => _succeeded = true);
            _ticker?.cancel();
            unawaited(
              Future<void>.delayed(
                const Duration(milliseconds: 750),
              ).then((_) {
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
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: BankTokens.space4),
              Text(
                widget.pushWaitingLabel,
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
    this.expiryChip,
  });

  final String title;
  final BankThemeData theme;
  final String? expiryChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.gpp_maybe_outlined,
          size: 22,
          color: BankTokens.warning,
        ),
        const SizedBox(width: BankTokens.space2),
        Expanded(
          child: Text(
            title,
            style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
          ),
        ),
        if (expiryChip != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: BankTokens.warning.withValues(alpha: 0.12),
              borderRadius: theme.chipRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space2,
                vertical: 2,
              ),
              child: Text(
                expiryChip!,
                style:
                    BankTokens.labelSmall.copyWith(color: BankTokens.warning),
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
    final secondary = [
      if (accountMasked != null) accountMasked!,
      if (reference != null) reference!,
    ].join(' · ');

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
              if (secondary.isNotEmpty)
                Text(
                  secondary,
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
