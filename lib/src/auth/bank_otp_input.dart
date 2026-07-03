import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Imperative handle for a [BankOtpInput].
///
/// Attach one via [BankOtpInput.controller] to clear the entered code after
/// a failed verification without rebuilding the widget with a new [Key]:
///
/// ```dart
/// final otpController = BankOtpInputController();
///
/// BankOtpInput(
///   onCompleted: (code) => _verify(code),
///   controller: otpController,
/// );
///
/// // Later, when verification fails:
/// otpController.clear();
/// ```
class BankOtpInputController {
  _BankOtpInputState? _state;

  /// The code entered so far (always ASCII digits).
  String get value => _state?._textController.text ?? '';

  /// Clears the entered code and refocuses the input if it had focus.
  void clear() => _state?._clear();
}

// ---------------------------------------------------------------------------
// BankOtpInput
// ---------------------------------------------------------------------------

/// Segmented one-time-code (OTP / 2FA) entry field.
///
/// Renders [length] 48 px boxes backed by a single invisible text field, so
/// platform SMS autofill (`AutofillHints.oneTimeCode`) works out of the box
/// and a pasted code distributes across the boxes automatically.
///
/// Visual behaviour:
/// - The focused box gets a [BankThemeData.primary] border; all boxes use
///   [BankThemeData.chipRadius].
/// - When [error] flips to `true`, boxes turn [BankTokens.danger] and the
///   row plays a short ±4 px horizontal shake (300 ms), skipped when
///   [MediaQuery.disableAnimationsOf] is `true`.
/// - Digits are displayed using the ambient [NumeralStyle] from
///   [BankUiScope], while [onCompleted] and [onChanged] always report ASCII
///   digits.
///
/// When [resendCooldown] is provided, a countdown text button ("Resend in
/// 0:NN") is shown below the boxes. It stays disabled until the countdown
/// reaches zero, then enables, calls [onResend] on tap, and restarts the
/// countdown.
///
/// The host owns verification. Clear the input after a failure either by
/// rebuilding with a new [Key] or via a [BankOtpInputController].
///
/// ```dart
/// BankOtpInput(
///   onCompleted: (code) => context.read<AuthBloc>().add(VerifyOtp(code)),
///   error: state.otpRejected,
///   resendCooldown: const Duration(seconds: 30),
///   onResend: () => context.read<AuthBloc>().add(ResendOtp()),
/// )
/// ```
class BankOtpInput extends StatefulWidget {
  /// Called with the full ASCII code once all [length] digits are entered.
  final ValueChanged<String> onCompleted;

  /// Number of code digits (and boxes). Defaults to `6`.
  final int length;

  /// Called with the ASCII digits entered so far on every change.
  final ValueChanged<String>? onChanged;

  /// When flipped to `true`, boxes show danger borders and the row shakes.
  final bool error;

  /// Whether the input accepts digits. Defaults to `true`.
  final bool enabled;

  /// When `true`, entered digits are masked with a bullet character.
  final bool obscure;

  /// When provided, shows a resend button with a countdown of this length.
  final Duration? resendCooldown;

  /// Called when the enabled resend button is tapped.
  final VoidCallback? onResend;

  /// Label for the resend button once the cooldown has elapsed.
  final String? resendLabel;

  /// Whether the invisible text field autofocuses. Defaults to `true`.
  final bool autofocus;

  /// Optional imperative handle, e.g. to clear the code after a failure.
  final BankOtpInputController? controller;

  /// Prefix shown before the countdown, e.g. `Resend in 0:29`.
  final String resendCountdownPrefix;

  /// Screen-reader announcement made when [error] is `true`.
  final String errorAnnouncement;

  /// Screen-reader announcement made when the resend button enables.
  final String resendAvailableAnnouncement;

  /// Semantic label describing the input to assistive technology.
  final String semanticLabel;

  const BankOtpInput({
    required this.onCompleted,
    super.key,
    this.length = 6,
    this.onChanged,
    this.error = false,
    this.enabled = true,
    this.obscure = false,
    this.resendCooldown,
    this.onResend,
    this.resendLabel,
    this.autofocus = true,
    this.controller,
    this.resendCountdownPrefix = 'Resend in',
    this.errorAnnouncement = 'Incorrect code, try again',
    this.resendAvailableAnnouncement = 'You can request a new code now',
    this.semanticLabel = 'One-time code',
  }) : assert(length > 0, 'length must be greater than 0');

  @override
  State<BankOtpInput> createState() => _BankOtpInputState();
}

class _BankOtpInputState extends State<BankOtpInput> {
  static const double _boxSize = BankTokens.space12;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _cooldownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _focusNode.addListener(_onFocusChanged);
    _startCooldown();
  }

  @override
  void didUpdateWidget(BankOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
    if (widget.resendCooldown != oldWidget.resendCooldown) {
      _startCooldown();
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _cooldownTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _clear() {
    if (_textController.text.isEmpty) return;
    setState(_textController.clear);
    widget.onChanged?.call('');
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    final cooldown = widget.resendCooldown;
    if (cooldown == null || cooldown <= Duration.zero) {
      _remainingSeconds = 0;
      return;
    }
    _remainingSeconds = cooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted(value);
    }
  }

  void _handleResend() {
    widget.onResend?.call();
    setState(_startCooldown);
  }

  String _formatCountdown(NumeralStyle numeralStyle) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return numeralStyle.convert('$minutes:$seconds');
  }

  bool get _canResend => _remainingSeconds == 0;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final numeralStyle = BankUiScope.of(context).numeralStyle;
    final text = _textController.text;

    final announcement = widget.error
        ? widget.errorAnnouncement
        : (widget.resendCooldown != null && _canResend)
            ? widget.resendAvailableAnnouncement
            : '';

    // Digits always read left-to-right, even in RTL locales, so the box row
    // is pinned to LTR to keep box order aligned with the code string.
    final boxes = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : BankTokens.space2,
            ),
            child: _buildBox(theme, numeralStyle, text, index),
          );
        }),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          label: announcement,
          child: const SizedBox.shrink(),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: _OtpShake(
                  shake: widget.error,
                  child: boxes,
                ),
              ),
              Positioned.fill(
                child: Semantics(
                  label: '${widget.semanticLabel}, '
                      '${text.length} of ${widget.length} digits entered',
                  child: Opacity(
                    opacity: 0,
                    alwaysIncludeSemantics: true,
                    child: _buildInvisibleField(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.resendCooldown != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: BankTokens.space3),
            child: _buildResendButton(theme, numeralStyle),
          ),
      ],
    );
  }

  Widget _buildInvisibleField() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus && widget.enabled,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        _AsciiDigitsFormatter(),
        LengthLimitingTextInputFormatter(widget.length),
      ],
      maxLines: null,
      expands: true,
      showCursor: false,
      enableInteractiveSelection: false,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: Color(0x00000000), fontSize: 1),
      cursorColor: const Color(0x00000000),
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: '',
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: _handleChanged,
    );
  }

  Widget _buildBox(
    BankThemeData theme,
    NumeralStyle numeralStyle,
    String text,
    int index,
  ) {
    final filled = index < text.length;
    final display = !filled
        ? ''
        : widget.obscure
            ? '●'
            : numeralStyle.convert(text[index]);

    final focusedIndex =
        text.length < widget.length ? text.length : widget.length - 1;
    final isFocused =
        widget.enabled && _focusNode.hasFocus && index == focusedIndex;

    final Color borderColor;
    if (widget.error) {
      borderColor = BankTokens.danger;
    } else if (isFocused) {
      borderColor = theme.primary;
    } else {
      borderColor = theme.outline;
    }

    final textColor = widget.enabled
        ? (widget.error ? BankTokens.danger : theme.onSurface)
        : theme.onSurfaceVariant;

    return AnimatedContainer(
      duration: BankTokens.durationFast,
      curve: BankTokens.curveStandard,
      width: _boxSize,
      height: _boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.enabled
            ? theme.surfaceVariant
            : theme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: theme.chipRadius,
        border: Border.all(
          color: borderColor,
          width: isFocused || widget.error ? 2 : 1,
        ),
      ),
      child: Text(
        display,
        style: theme.numeralLarge.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildResendButton(BankThemeData theme, NumeralStyle numeralStyle) {
    final enabled = _canResend && widget.enabled && widget.onResend != null;
    final label = _canResend
        ? (widget.resendLabel ?? 'Resend code')
        : '${widget.resendCountdownPrefix} '
            '${_formatCountdown(numeralStyle)}';

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: TextButton(
        onPressed: enabled ? _handleResend : null,
        style: TextButton.styleFrom(
          foregroundColor: theme.primary,
          disabledForegroundColor: theme.onSurfaceVariant,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          textStyle: BankTokens.labelLarge,
        ),
        child: Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input formatter
// ---------------------------------------------------------------------------

/// Keeps only digits and transliterates Eastern Arabic-Indic (٠-٩) and
/// Extended Arabic-Indic (۰-۹) digits to ASCII, so the reported code is
/// always ASCII regardless of the keyboard's numeral script.
class _AsciiDigitsFormatter extends TextInputFormatter {
  static const int _ascii0 = 0x30;
  static const int _ascii9 = 0x39;
  static const int _arabicIndic0 = 0x0660;
  static const int _arabicIndic9 = 0x0669;
  static const int _extendedArabicIndic0 = 0x06F0;
  static const int _extendedArabicIndic9 = 0x06F9;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      if (rune >= _ascii0 && rune <= _ascii9) {
        buffer.writeCharCode(rune);
      } else if (rune >= _arabicIndic0 && rune <= _arabicIndic9) {
        buffer.writeCharCode(rune - _arabicIndic0 + _ascii0);
      } else if (rune >= _extendedArabicIndic0 &&
          rune <= _extendedArabicIndic9) {
        buffer.writeCharCode(rune - _extendedArabicIndic0 + _ascii0);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ---------------------------------------------------------------------------
// Shake animation helper
// ---------------------------------------------------------------------------

/// Internal widget that shakes its [child] horizontally when [shake] flips
/// from `false` to `true`: a ±4 px oscillation over 300 ms, skipped when the
/// platform requests reduced motion.
class _OtpShake extends StatefulWidget {
  const _OtpShake({
    required this.shake,
    required this.child,
  });

  final bool shake;
  final Widget child;

  @override
  State<_OtpShake> createState() => _OtpShakeState();
}

class _OtpShakeState extends State<_OtpShake>
    with SingleTickerProviderStateMixin {
  static const double _amplitude = 4;

  late final AnimationController _controller;
  late final Animation<double> _dx;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dx = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: _amplitude)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _amplitude, end: -_amplitude)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -_amplitude, end: _amplitude)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _amplitude, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_OtpShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dx,
      builder: (context, child) => Transform.translate(
        offset: Offset(_dx.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
