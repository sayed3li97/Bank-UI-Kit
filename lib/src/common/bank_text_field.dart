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
    this.radius,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorColor,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
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

  /// Overrides the field's border radius. Defaults to
  /// [BankThemeData.buttonRadius].
  final BorderRadius? radius;

  /// Overrides the field fill for both enabled and disabled states.
  /// Defaults to [BankThemeData.surface] (enabled) or
  /// [BankThemeData.surfaceVariant] (disabled).
  final Color? fillColor;

  /// Overrides the resting border colour. Defaults to
  /// [BankThemeData.outline].
  final Color? borderColor;

  /// Overrides the focused border colour. Defaults to
  /// [BankThemeData.primary].
  final Color? focusedBorderColor;

  /// Overrides [BankTokens.danger] as the error tint used by the label,
  /// borders, and error text.
  final Color? errorColor;

  /// Overrides the input's inner padding. Defaults to a symmetric
  /// [BankTokens.space4] by [BankTokens.space3] inset.
  final EdgeInsetsGeometry? contentPadding;

  /// Merged over the computed input text style ([BankTokens.bodyLarge] in
  /// [BankThemeData.onSurface]).
  final TextStyle? textStyle;

  /// Merged over the computed label style ([BankTokens.labelMedium]).
  final TextStyle? labelStyle;

  /// Merged over the computed hint style ([BankTokens.bodyLarge] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? hintStyle;

  /// Merged over the computed helper style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? helperStyle;

  /// Merged over the computed error style ([BankTokens.bodySmall] in the
  /// error tint).
  final TextStyle? errorStyle;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final hasError = errorText != null;

    final resolvedRadius = radius ?? theme.buttonRadius;
    final dangerColor = errorColor ?? BankTokens.danger;
    final restingColor = borderColor ?? theme.outline;
    final resolvedBorderColor = hasError ? dangerColor : restingColor;
    final focusedColor =
        hasError ? dangerColor : (focusedBorderColor ?? theme.primary);

    final border = OutlineInputBorder(
      borderRadius: resolvedRadius,
      borderSide: BorderSide(color: resolvedBorderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: resolvedRadius,
      borderSide: BorderSide(color: focusedColor, width: 2),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: resolvedRadius,
      borderSide: BorderSide(color: restingColor.withValues(alpha: 0.4)),
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
              style: BankTokens.labelMedium
                  .copyWith(
                    color: hasError ? dangerColor : theme.onSurface,
                  )
                  .merge(labelStyle),
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
          style: BankTokens.bodyLarge
              .copyWith(color: theme.onSurface)
              .merge(textStyle),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: BankTokens.bodyLarge
                .copyWith(color: theme.onSurfaceVariant)
                .merge(hintStyle),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                fillColor ?? (enabled ? theme.surface : theme.surfaceVariant),
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: OutlineInputBorder(
              borderRadius: resolvedRadius,
              borderSide: BorderSide(color: dangerColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: resolvedRadius,
              borderSide: BorderSide(color: dangerColor, width: 2),
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
              style: BankTokens.bodySmall
                  .copyWith(color: dangerColor)
                  .merge(errorStyle),
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
              style: BankTokens.bodySmall
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(helperStyle),
            ),
          ),
      ],
    );
  }
}
