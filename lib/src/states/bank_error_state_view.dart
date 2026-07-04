import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Error state with a specific reason.
///
/// Never uses a generic "Something went wrong" message. Callers must supply
/// a [title] and [message] that explain what failed and why. An optional
/// [onRetry] and [onContactSupport] callback are shown as action buttons when
/// non-null.
///
/// Layout: a vertically centred [Column] with a 48 px icon, [title] in
/// [BankTokens.headlineSmall], [message] in [BankTokens.bodyMedium] with
/// [BankThemeData.onSurfaceVariant] colour, then action buttons.
///
/// ```dart
/// BankErrorStateView(
///   title: 'Transfer failed',
///   message: "We could not reach the recipient's bank. "
///       'Please try again later.',
///   onRetry: () => bloc.add(RetryTransferEvent()),
///   onContactSupport: () => launchSupportChat(),
/// )
/// ```
class BankErrorStateView extends StatelessWidget {
  /// Short title describing what went wrong.
  final String title;

  /// A specific explanation of the error: never a generic fallback.
  final String message;

  /// Label for the retry action button.
  final String retryLabel;

  /// Label for the support action button.
  final String? supportLabel;

  /// Callback for the retry button. Button is omitted when `null`.
  final VoidCallback? onRetry;

  /// Callback for the contact-support button. Button is omitted when `null`.
  final VoidCallback? onContactSupport;

  /// Custom icon widget. Defaults to [Icons.error_outline] in
  /// [BankTokens.danger] colour at 48 px.
  final Widget? icon;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: BankTokens.space8)`.
  final EdgeInsetsGeometry? padding;

  /// Background of the retry button. Defaults to
  /// [BankThemeData.primary].
  final Color? accentColor;

  /// Merged over the computed title style ([BankTokens.headlineSmall]
  /// in [BankThemeData.onSurface]).
  final TextStyle? titleStyle;

  /// Merged over the computed message style ([BankTokens.bodyMedium]
  /// in [BankThemeData.onSurfaceVariant]).
  final TextStyle? messageStyle;

  /// Container semantics label for the whole view. Defaults to none
  /// (children are read individually, as today).
  final String? semanticLabel;

  const BankErrorStateView({
    required this.title,
    required this.message,
    super.key,
    this.retryLabel = 'Retry',
    this.supportLabel,
    this.onRetry,
    this.onContactSupport,
    this.icon,
    this.padding,
    this.accentColor,
    this.titleStyle,
    this.messageStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final resolvedIcon = icon ??
        const Icon(
          Icons.error_outline,
          size: 48,
          color: BankTokens.danger,
        );

    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: BankTokens.space8);

    Widget content = Center(
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            resolvedIcon,
            const SizedBox(height: BankTokens.space4),
            Text(
              title,
              style: BankTokens.headlineSmall
                  .copyWith(color: theme.onSurface)
                  .merge(titleStyle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BankTokens.space2),
            Text(
              message,
              style: BankTokens.bodyMedium
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(messageStyle),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BankTokens.space6),
              Semantics(
                button: true,
                label: retryLabel,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor ?? theme.primary,
                    foregroundColor: theme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(retryLabel),
                ),
              ),
            ],
            if (onContactSupport != null) ...[
              const SizedBox(height: BankTokens.space2),
              Semantics(
                button: true,
                label: supportLabel ?? 'Contact Support',
                child: TextButton(
                  onPressed: onContactSupport,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.onSurfaceVariant,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(supportLabel ?? 'Contact Support'),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (semanticLabel != null) {
      content = Semantics(
        container: true,
        label: semanticLabel,
        child: content,
      );
    }
    return content;
  }
}
