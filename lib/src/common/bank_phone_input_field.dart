import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';
import 'bank_country_picker.dart';
import 'bank_text_field.dart';

/// Phone number entry with an in-field country / dial-code selector.
///
/// The leading affordance shows the selected country's flag and dial code
/// and opens [BankCountryPicker.show]. The national number formats live
/// with simple 3-3-4 grouping; [onChanged] always emits a normalized
/// E.164 string (`+<dialcode><national digits>`). Hosts needing
/// carrier-grade per-country validation can layer their own
/// `inputFormatters` upstream: this widget deliberately avoids a
/// libphonenumber dependency.
///
/// Digits display through the ambient [NumeralStyle] while the emitted
/// value is always ASCII.
///
/// ```dart
/// BankPhoneInputField(
///   label: 'Mobile number',
///   onChanged: (e164, country) => setState(() => _phone = e164),
/// )
/// ```
class BankPhoneInputField extends StatefulWidget {
  const BankPhoneInputField({
    required this.onChanged,
    super.key,
    this.initialCountry,
    this.initialNumber,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.preferredCountryIsoCodes,
    this.focusNode,
  });

  /// Emits the normalized E.164 value and the selected country on every
  /// edit or country change. The E.164 string is empty while the national
  /// number is empty.
  final void Function(String e164, BankCountry country) onChanged;

  /// Preselected country. Defaults to the first entry of
  /// [BankCountry.all] when null.
  final BankCountry? initialCountry;

  /// Initial national number (digits only or pre-grouped: separators
  /// are stripped).
  final String? initialNumber;

  final String? label;
  final String? hint;
  final String? helper;

  /// Non-null shows the danger error state, matching [BankTextField].
  final String? errorText;

  final bool enabled;

  /// ISO codes surfaced in the picker's recent section.
  final List<String>? preferredCountryIsoCodes;

  final FocusNode? focusNode;

  @override
  State<BankPhoneInputField> createState() => _BankPhoneInputFieldState();
}

class _BankPhoneInputFieldState extends State<BankPhoneInputField> {
  late BankCountry _country;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry ?? BankCountry.all.first;
    _controller = TextEditingController(
      text: _PhoneGroupingFormatter.groupAscii(
        _PhoneGroupingFormatter.normalizeDigits(widget.initialNumber ?? ''),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _nationalDigits =>
      _PhoneGroupingFormatter.normalizeDigits(_controller.text);

  void _emit() {
    final digits = _nationalDigits;
    final dial = _PhoneGroupingFormatter.normalizeDigits(_country.dialCode);
    widget.onChanged(digits.isEmpty ? '' : '+$dial$digits', _country);
  }

  Future<void> _pickCountry() async {
    final picked = await BankCountryPicker.show(
      context,
      selected: _country,
      showDialCode: true,
      recentIsoCodes: widget.preferredCountryIsoCodes ?? const <String>[],
    );
    if (picked == null || !mounted) return;
    setState(() => _country = picked);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final numeralStyle = BankUiScope.of(context).numeralStyle;

    return BankTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      label: widget.label,
      hint: widget.hint,
      helper: widget.helper,
      errorText: widget.errorText,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [_PhoneGroupingFormatter(numeralStyle)],
      onChanged: (_) => _emit(),
      prefixIcon: _CountryAffordance(
        country: _country,
        enabled: widget.enabled,
        theme: theme,
        numeralStyle: numeralStyle,
        onTap: _pickCountry,
      ),
    );
  }
}

class _CountryAffordance extends StatelessWidget {
  const _CountryAffordance({
    required this.country,
    required this.enabled,
    required this.theme,
    required this.numeralStyle,
    required this.onTap,
  });

  final BankCountry country;
  final bool enabled;
  final BankThemeData theme;
  final NumeralStyle numeralStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${country.name}, ${country.dialCode}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.all(theme.buttonRadius.topLeft),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: BankTokens.space3,
            end: BankTokens.space2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                country.flagEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: BankTokens.space1),
              Text(
                numeralStyle.convert(country.dialCode),
                style: BankTokens.bodyLarge.copyWith(
                  color: enabled ? theme.onSurface : theme.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: theme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Strips separators, normalizes Arabic-Indic digits to ASCII, caps at
/// 15 digits (the E.164 maximum), groups 3-3-4-style for display, and
/// re-renders through the ambient [NumeralStyle].
class _PhoneGroupingFormatter extends TextInputFormatter {
  _PhoneGroupingFormatter(this.numeralStyle);

  final NumeralStyle numeralStyle;

  static const _easternZero = 0x0660;
  static const _extendedZero = 0x06F0;

  static String normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final code in input.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code);
      } else if (code >= _easternZero && code <= _easternZero + 9) {
        buffer.writeCharCode(0x30 + (code - _easternZero));
      } else if (code >= _extendedZero && code <= _extendedZero + 9) {
        buffer.writeCharCode(0x30 + (code - _extendedZero));
      }
    }
    final digits = buffer.toString();
    return digits.length > 15 ? digits.substring(0, 15) : digits;
  }

  static String groupAscii(String digits) {
    final groups = <String>[];
    var index = 0;
    for (final size in const [3, 3]) {
      if (index >= digits.length) break;
      final end = index + size > digits.length ? digits.length : index + size;
      groups.add(digits.substring(index, end));
      index = end;
    }
    if (index < digits.length) groups.add(digits.substring(index));
    return groups.join(' ');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = normalizeDigits(newValue.text);
    final display = numeralStyle.convert(groupAscii(digits));
    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}
