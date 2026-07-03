import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Bullet character used to obscure card PAN groups.
const String _obscureChar = '•';

/// Matches a single IBAN-legal character (letter or digit).
final RegExp _alphanumericChar = RegExp('[A-Za-z0-9]');

/// Matches a single ASCII digit.
final RegExp _digitChar = RegExp('[0-9]');

// -----------------------------------------------------------------------------
// Mask definitions
// -----------------------------------------------------------------------------

/// Describes how a [BankMaskedInputField] filters, formats, and validates
/// what the user types.
///
/// Built-in masks:
///
/// * [BankInputMask.iban] — uppercase alphanumerics in groups of four,
///   capped at 34 characters, validated with the ISO 13616 mod-97 checksum.
/// * [BankInputMask.cardPan] — digits in groups of four, capped at 19,
///   validated with the Luhn checksum; can obscure all but the last four
///   digits.
/// * [BankInputMask.sortCode] — six-digit UK sort code shown as `NN-NN-NN`.
/// * [BankInputMask.custom] — arbitrary digit patterns such as
///   `'## ### ###'`.
///
/// The checksum routines are also available directly via the static
/// [isValidIban] and [isValidLuhn] hooks for use in form-level validation.
sealed class BankInputMask {
  const BankInputMask();

  /// International Bank Account Number mask.
  ///
  /// Accepts letters and digits, uppercases them, renders groups of four
  /// separated by spaces, and caps input at 34 characters. [validate]
  /// checks shape (`CC00…`) plus the ISO 13616 mod-97 checksum.
  const factory BankInputMask.iban() = _BankIbanMask;

  /// Payment-card primary account number mask.
  ///
  /// Accepts digits only, renders groups of four separated by spaces, and
  /// caps input at 19 digits. [validate] runs the Luhn checksum.
  ///
  /// When [obscureAllButLast4] is `true`, every digit except the final
  /// four is rendered as a bullet (`•`) while the underlying raw value is
  /// preserved.
  const factory BankInputMask.cardPan({
    bool obscureAllButLast4,
  }) = _BankCardPanMask;

  /// UK sort code mask rendered as `NN-NN-NN`.
  ///
  /// Accepts exactly six digits; [validate] checks that all six are
  /// present.
  const factory BankInputMask.sortCode() = _BankSortCodeMask;

  /// Custom digit mask driven by [pattern].
  ///
  /// Every occurrence of [digitChar] (default `#`) in [pattern] is a digit
  /// slot; every other character is a literal separator inserted as the
  /// user types. Example: `BankInputMask.custom('+## ### ####')`.
  /// [validate] checks that every slot is filled.
  const factory BankInputMask.custom(
    String pattern, {
    String digitChar,
  }) = _BankCustomMask;

  // ---------------------------------------------------------------------------
  // Public validation API
  // ---------------------------------------------------------------------------

  /// Returns `true` when the raw (unmasked) [raw] value passes this mask's
  /// validation: mod-97 for IBAN, Luhn for card PAN, and completeness for
  /// sort codes and custom patterns.
  bool validate(String raw);

  /// Returns `true` when [input] is a structurally valid IBAN with a
  /// correct ISO 13616 mod-97 checksum. Spaces are ignored and letters are
  /// case-insensitive.
  static bool isValidIban(String input) {
    final raw = input.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (raw.length < 15 || raw.length > 34) return false;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(raw)) return false;
    final rearranged = raw.substring(4) + raw.substring(0, 4);
    var remainder = 0;
    for (final code in rearranged.codeUnits) {
      // 'A'–'Z' → 10–35, '0'–'9' → 0–9.
      final value = code >= 0x41 ? code - 55 : code - 48;
      remainder = value >= 10
          ? (remainder * 100 + value) % 97
          : (remainder * 10 + value) % 97;
    }
    return remainder == 1;
  }

  /// Returns `true` when the digits in [input] pass the Luhn checksum and
  /// form a plausible card number (12–19 digits). Non-digits are ignored.
  static bool isValidLuhn(String input) {
    final digits = input.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length < 12 || digits.length > 19) return false;
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = digits.codeUnitAt(i) - 0x30;
      if (doubleIt) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  // ---------------------------------------------------------------------------
  // Internal mask contract
  // ---------------------------------------------------------------------------

  /// Maximum number of raw (unmasked) characters this mask accepts.
  int get _maxRawLength;

  /// Keyboard type most appropriate for this mask.
  TextInputType get _keyboardType;

  /// Capitalisation behaviour for the soft keyboard.
  TextCapitalization get _textCapitalization => TextCapitalization.none;

  /// English fallback message shown when focus-loss validation fails.
  String get _defaultErrorMessage;

  /// Whether [char] is accepted as raw input for this mask.
  bool _isRawChar(String char);

  /// Normalises an accepted raw character (e.g. uppercasing for IBAN).
  String _normalize(String char) => char;

  /// Extracts the raw value from (possibly user-edited) display [text].
  ///
  /// Bullets produced by an obscuring mask are mapped back to the digits
  /// of [previousRaw] by ordinal, so edits over obscured text never lose
  /// the hidden digits.
  String _filter(String text, String previousRaw) {
    final buffer = StringBuffer();
    var bulletIndex = 0;
    for (var i = 0; i < text.length && buffer.length < _maxRawLength; i++) {
      final char = text[i];
      if (char == _obscureChar) {
        if (bulletIndex < previousRaw.length) {
          buffer.write(previousRaw[bulletIndex]);
        }
        bulletIndex++;
      } else if (_isRawChar(char)) {
        buffer.write(_normalize(char));
      }
    }
    return buffer.toString();
  }

  /// Produces the display text and caret-offset table for [raw].
  _MaskLayout _layout(String raw);
}

class _BankIbanMask extends BankInputMask {
  const _BankIbanMask();

  @override
  int get _maxRawLength => 34;

  @override
  TextInputType get _keyboardType => TextInputType.text;

  @override
  TextCapitalization get _textCapitalization => TextCapitalization.characters;

  @override
  String get _defaultErrorMessage => 'Enter a valid IBAN.';

  @override
  bool _isRawChar(String char) => _alphanumericChar.hasMatch(char);

  @override
  String _normalize(String char) => char.toUpperCase();

  @override
  bool validate(String raw) => BankInputMask.isValidIban(raw);

  @override
  _MaskLayout _layout(String raw) => _groupOfFourLayout(raw, (int i) => raw[i]);

  @override
  bool operator ==(Object other) => other is _BankIbanMask;

  @override
  int get hashCode => (_BankIbanMask).hashCode;
}

class _BankCardPanMask extends BankInputMask {
  const _BankCardPanMask({this.obscureAllButLast4 = false});

  /// When `true`, every digit except the last four renders as `•`.
  final bool obscureAllButLast4;

  @override
  int get _maxRawLength => 19;

  @override
  TextInputType get _keyboardType => TextInputType.number;

  @override
  String get _defaultErrorMessage => 'Enter a valid card number.';

  @override
  bool _isRawChar(String char) => _digitChar.hasMatch(char);

  @override
  bool validate(String raw) => BankInputMask.isValidLuhn(raw);

  @override
  _MaskLayout _layout(String raw) {
    final visibleFrom = raw.length - 4;
    return _groupOfFourLayout(
      raw,
      (int i) => obscureAllButLast4 && i < visibleFrom ? _obscureChar : raw[i],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _BankCardPanMask &&
      other.obscureAllButLast4 == obscureAllButLast4;

  @override
  int get hashCode => Object.hash(_BankCardPanMask, obscureAllButLast4);
}

class _BankSortCodeMask extends BankInputMask {
  const _BankSortCodeMask();

  @override
  int get _maxRawLength => 6;

  @override
  TextInputType get _keyboardType => TextInputType.number;

  @override
  String get _defaultErrorMessage => 'Enter a valid sort code.';

  @override
  bool _isRawChar(String char) => _digitChar.hasMatch(char);

  @override
  bool validate(String raw) => raw.length == 6;

  @override
  _MaskLayout _layout(String raw) {
    final buffer = StringBuffer();
    final offsets = <int>[0];
    for (var i = 0; i < raw.length; i++) {
      if (i == 2 || i == 4) buffer.write('-');
      buffer.write(raw[i]);
      offsets.add(buffer.length);
    }
    return _MaskLayout(buffer.toString(), offsets);
  }

  @override
  bool operator ==(Object other) => other is _BankSortCodeMask;

  @override
  int get hashCode => (_BankSortCodeMask).hashCode;
}

class _BankCustomMask extends BankInputMask {
  const _BankCustomMask(this.pattern, {this.digitChar = '#'})
      : assert(digitChar.length == 1, 'digitChar must be one character');

  /// Pattern whose [digitChar] occurrences are digit slots; every other
  /// character is a literal separator.
  final String pattern;

  /// Placeholder character marking digit slots inside [pattern].
  final String digitChar;

  @override
  int get _maxRawLength => digitChar.allMatches(pattern).length;

  @override
  TextInputType get _keyboardType => TextInputType.number;

  @override
  String get _defaultErrorMessage => 'Enter a valid value.';

  @override
  bool _isRawChar(String char) => _digitChar.hasMatch(char);

  @override
  bool validate(String raw) => raw.length == _maxRawLength;

  @override
  _MaskLayout _layout(String raw) {
    final buffer = StringBuffer();
    final offsets = <int>[0];
    final pendingLiterals = StringBuffer();
    var rawIndex = 0;
    for (var p = 0; p < pattern.length && rawIndex < raw.length; p++) {
      final patternChar = pattern[p];
      if (patternChar == digitChar) {
        buffer.write(pendingLiterals);
        pendingLiterals.clear();
        buffer.write(raw[rawIndex]);
        rawIndex++;
        offsets.add(buffer.length);
      } else {
        pendingLiterals.write(patternChar);
      }
    }
    return _MaskLayout(buffer.toString(), offsets);
  }

  @override
  bool operator ==(Object other) =>
      other is _BankCustomMask &&
      other.pattern == pattern &&
      other.digitChar == digitChar;

  @override
  int get hashCode => Object.hash(_BankCustomMask, pattern, digitChar);
}

/// Builds a groups-of-four layout (`XXXX XXXX …`) where each display
/// character is produced by [charAt].
_MaskLayout _groupOfFourLayout(String raw, String Function(int) charAt) {
  final buffer = StringBuffer();
  final offsets = <int>[0];
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(charAt(i));
    offsets.add(buffer.length);
  }
  return _MaskLayout(buffer.toString(), offsets);
}

/// Display text plus a table mapping raw-character counts to caret offsets.
class _MaskLayout {
  const _MaskLayout(this.text, this.offsets);

  /// The formatted text to display.
  final String text;

  /// `offsets[i]` is the display caret offset after `i` raw characters.
  final List<int> offsets;
}

// -----------------------------------------------------------------------------
// Formatter
// -----------------------------------------------------------------------------

/// Applies a [BankInputMask] as a [TextEditingValue] transformation so the
/// caret survives reformatting (no post-hoc `setText`).
class _BankMaskFormatter extends TextInputFormatter {
  _BankMaskFormatter({required this.mask, required this.onRawChanged});

  final BankInputMask mask;

  /// Invoked with the new raw value on every accepted edit.
  final ValueChanged<String> onRawChanged;

  /// The raw value backing the most recent formatted text; used to map
  /// obscuring bullets back to their hidden digits.
  String _lastRaw = '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final previousRaw = _lastRaw;
    final raw = mask._filter(newValue.text, previousRaw);

    // Count the raw characters sitting before the caret in the edited
    // text, then re-anchor the caret after that many raw characters in
    // the freshly formatted text.
    final selectionEnd = newValue.selection.end.clamp(0, newValue.text.length);
    var rawCaret = mask
        ._filter(newValue.text.substring(0, selectionEnd), previousRaw)
        .length;
    if (rawCaret > raw.length) rawCaret = raw.length;

    _lastRaw = raw;
    onRawChanged(raw);

    final layout = mask._layout(raw);
    return TextEditingValue(
      text: layout.text,
      selection: TextSelection.collapsed(offset: layout.offsets[rawCaret]),
    );
  }
}

// -----------------------------------------------------------------------------
// Widget
// -----------------------------------------------------------------------------

/// A themed text field that applies a live [BankInputMask] (IBAN, card
/// PAN, sort code, or a custom digit pattern) while the user types.
///
/// The field reports only the *raw* unmasked value through [onChanged];
/// grouping separators shown on screen are purely visual. The caret
/// survives reformatting because the mask is applied as a
/// [TextEditingValue] transformation inside a [TextInputFormatter].
///
/// When [validateOnUnfocus] is `true` (the default) the mask's checksum
/// (ISO 13616 mod-97 for IBAN, Luhn for card numbers, completeness for
/// sort codes and custom patterns) runs when the field loses focus with a
/// non-empty value. Failures render the [BankTokens.danger] error state
/// with [validationErrorText], falling back to a mask-specific English
/// default. An externally supplied [errorText] always takes precedence.
///
/// Input text uses the theme's tabular-figure numeral style
/// ([BankThemeData.numeralMedium]) and is always laid out left-to-right,
/// as account and card numbers are LTR in every locale.
///
/// ```dart
/// BankMaskedInputField(
///   mask: const BankInputMask.iban(),
///   label: 'Recipient IBAN',
///   helperText: 'Shown on their bank statement',
///   onChanged: (raw) => setState(() => _iban = raw),
/// )
///
/// BankMaskedInputField(
///   mask: const BankInputMask.cardPan(obscureAllButLast4: true),
///   label: 'Card number',
///   onChanged: (raw) => _pan = raw,
/// )
/// ```
class BankMaskedInputField extends StatefulWidget {
  const BankMaskedInputField({
    required this.mask,
    required this.onChanged,
    super.key,
    this.initialValue,
    this.label,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.validateOnUnfocus = true,
    this.validationErrorText,
    this.textInputAction,
    this.focusNode,
  });

  /// The mask that filters, formats, and validates input.
  final BankInputMask mask;

  /// Called with the raw (unmasked) value after every accepted edit.
  final ValueChanged<String> onChanged;

  /// Optional initial value; masked characters are stripped on ingest.
  final String? initialValue;

  /// Label rendered above the input. Tinted [BankTokens.danger] on error.
  final String? label;

  /// External error message. When non-null it takes precedence over any
  /// message produced by focus-loss validation.
  final String? errorText;

  /// Helper text rendered below the field. Replaced by an error message
  /// when one is showing.
  final String? helperText;

  /// Whether the field accepts input.
  final bool enabled;

  /// When `true`, the mask's [BankInputMask.validate] hook runs on focus
  /// loss (for non-empty values) and failures show the danger error state.
  final bool validateOnUnfocus;

  /// Overrides the English default message shown when focus-loss
  /// validation fails.
  final String? validationErrorText;

  /// Keyboard action button (next, done, …).
  final TextInputAction? textInputAction;

  /// Optional external focus node. When omitted the field manages its own.
  final FocusNode? focusNode;

  @override
  State<BankMaskedInputField> createState() => _BankMaskedInputFieldState();
}

class _BankMaskedInputFieldState extends State<BankMaskedInputField> {
  late TextEditingController _controller;
  late _BankMaskFormatter _formatter;
  FocusNode? _ownedFocusNode;
  String _raw = '';
  String? _validationError;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _formatter = _BankMaskFormatter(
      mask: widget.mask,
      // The subsequent TextField.onChanged callback forwards the raw
      // value to the caller.
      onRawChanged: (String raw) => _raw = raw,
    );
    _raw = widget.mask._filter(widget.initialValue ?? '', '');
    _formatter._lastRaw = _raw;
    final layout = widget.mask._layout(_raw);
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: layout.text,
        selection: TextSelection.collapsed(offset: layout.text.length),
      ),
    );
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(BankMaskedInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)
          ?.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.mask != widget.mask) {
      _formatter = _BankMaskFormatter(
        mask: widget.mask,
        onRawChanged: (String raw) => _raw = raw,
      );
      _raw = widget.mask._filter(_raw, '');
      _formatter._lastRaw = _raw;
      final layout = widget.mask._layout(_raw);
      _controller.value = TextEditingValue(
        text: layout.text,
        selection: TextSelection.collapsed(offset: layout.text.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged(String _) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
    widget.onChanged(_raw);
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_validationError != null) {
        setState(() => _validationError = null);
      }
      return;
    }
    if (!widget.validateOnUnfocus || _raw.isEmpty) return;
    if (!widget.mask.validate(_raw)) {
      setState(() {
        _validationError =
            widget.validationErrorText ?? widget.mask._defaultErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final effectiveError = widget.errorText ?? _validationError;
    final hasError = effectiveError != null;

    final borderColor = hasError ? BankTokens.danger : theme.outline;
    final focusedColor = hasError ? BankTokens.danger : theme.primary;

    final border = OutlineInputBorder(
      borderRadius: theme.buttonRadius,
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: theme.buttonRadius,
      borderSide: BorderSide(color: focusedColor, width: 2),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: theme.buttonRadius,
      borderSide: BorderSide(color: theme.outline.withValues(alpha: 0.4)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space2),
            child: Text(
              widget.label!,
              style: BankTokens.labelMedium.copyWith(
                color: hasError ? BankTokens.danger : theme.onSurface,
              ),
            ),
          ),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: widget.mask._keyboardType,
          textCapitalization: widget.mask._textCapitalization,
          textInputAction: widget.textInputAction,
          // Account and card numbers read left-to-right in every locale.
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [_formatter],
          onChanged: _handleTextChanged,
          style: theme.numeralMedium.copyWith(color: theme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.enabled ? theme.surface : theme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            disabledBorder: disabledBorder,
          ),
        ),
        if (effectiveError != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: BankTokens.space1,
              start: BankTokens.space1,
            ),
            child: Text(
              effectiveError,
              style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
            ),
          )
        else if (widget.helperText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: BankTokens.space1,
              start: BankTokens.space1,
            ),
            child: Text(
              widget.helperText!,
              style:
                  BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
