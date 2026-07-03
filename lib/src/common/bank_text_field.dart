import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A themed text input field that reads from [BankThemeData] for consistent
/// styling across presets.
///
/// Renders a label above the field (not floating), an optional helper/error
/// line below, and prefix/suffix icon slots.
///
/// ```dart
/// BankTextField(
///   label: 'Full name',
///   hint: 'Enter your full name',
///   controller: _nameController,
///   prefixIcon: const Icon(Icons.person_outline_rounded),
/// )
/// ```
class BankTextField extends StatelessWidget {
  const BankTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    this.readOnly = false,
  });

  final TextEditingController? controller;

  /// Label rendered above the input. Coloured [BankTokens.danger] on error.
  final String? label;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// Helper text rendered below the field in [BankThemeData.onSurfaceVariant].
  /// Replaced by [errorText] when set.
  final String? helper;

  /// Error message. When non-null the border turns [BankTokens.danger] and
  /// the label is tinted accordingly.
  final String? errorText;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final hasError = errorText != null;

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
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space2),
            child: Text(
              label!,
              style: BankTokens.labelMedium.copyWith(
                color: hasError ? BankTokens.danger : theme.onSurface,
              ),
            ),
          ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          textInputAction: textInputAction,
          readOnly: readOnly,
          style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                BankTokens.bodyLarge.copyWith(color: theme.onSurfaceVariant),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? theme.surface : theme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: OutlineInputBorder(
              borderRadius: theme.buttonRadius,
              borderSide: const BorderSide(color: BankTokens.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: theme.buttonRadius,
              borderSide: const BorderSide(color: BankTokens.danger, width: 2),
            ),
            disabledBorder: disabledBorder,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: BankTokens.space1,
              left: BankTokens.space1,
            ),
            child: Text(
              errorText!,
              style: BankTokens.bodySmall.copyWith(color: BankTokens.danger),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(
              top: BankTokens.space1,
              left: BankTokens.space1,
            ),
            child: Text(
              helper!,
              style:
                  BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
