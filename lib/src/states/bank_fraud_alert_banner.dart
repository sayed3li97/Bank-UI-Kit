import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/button_text_style.dart';
import '../../src/theme/tokens.dart';

/// High-priority fraud warning banner.
///
/// Deliberately resists accidental dismissal:
/// - No swipe-to-dismiss gesture.
/// - The [onDismiss] button is small and positioned as a secondary action.
/// - The primary action ([onPrimaryAction]) is the prominent call to act.
///
/// Visual treatment:
/// - A neutral [BankThemeData.surface] card washed with the danger colour at
///   10% alpha, wrapped in a [BankTokens.hairlineWidth] hairline border —
///   never a full-saturation colour slab.
/// - A [Icons.gpp_bad_outlined] fraud icon at the inline start, tinted with
///   the brightness-appropriate [BankTokens.danger] / [BankTokens.dangerDark].
/// - [title] in [BankTokens.labelLarge] (danger colour).
/// - [body] in [BankTokens.bodySmall] ([BankThemeData.onSurface]).
/// - Two action buttons side by side: a danger-filled [FilledButton] for
///   [primaryActionLabel], [TextButton] for [dismissLabel].
///
/// Accessibility: the entire widget is annotated as `Fraud alert: $title` via
/// [Semantics].
///
/// ```dart
/// BankFraudAlertBanner(
///   title: 'Suspicious transaction detected',
///   body: 'A payment of £420 to an unknown recipient was attempted '
///       'on your account. Did you authorise this?',
///   primaryActionLabel: 'Secure My Account',
///   dismissLabel: 'Not me: dismiss',
///   onPrimaryAction: () => navigator.push(SecureAccountRoute()),
///   onDismiss: () => bloc.add(DismissFraudAlertEvent()),
/// )
/// ```
class BankFraudAlertBanner extends StatelessWidget {
  /// Short title summarising the security event.
  final String title;

  /// Detailed description of the suspected fraud.
  final String body;

  /// Label for the primary action button.
  final String primaryActionLabel;

  /// Label for the dismiss action button.
  final String dismissLabel;

  /// Called when the user taps the primary action (e.g. "Secure My Account").
  final VoidCallback onPrimaryAction;

  /// Called when the user explicitly taps the dismiss button.
  final VoidCallback onDismiss;

  /// Overrides the content padding. Defaults to
  /// [EdgeInsets.all] of [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Overrides the banner corner radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the banner background. Defaults to [BankThemeData.surface]
  /// washed with the accent colour at 10% alpha.
  final Color? backgroundColor;

  /// Overrides the body text colour. Defaults to
  /// [BankThemeData.onSurface].
  final Color? foregroundColor;

  /// Accent for the icon, title, and primary button. Defaults to the
  /// brightness-appropriate [BankTokens.danger] / [BankTokens.dangerDark].
  final Color? accentColor;

  /// Overrides the fraud glyph. Defaults to [Icons.gpp_bad_outlined].
  final IconData? icon;

  /// Merged over the computed title style ([BankTokens.labelLarge] in
  /// the accent colour).
  final TextStyle? titleStyle;

  /// Merged over the computed body style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurface]).
  final TextStyle? bodyStyle;

  /// Overrides the container semantics label. Defaults to
  /// 'Fraud alert: $title'.
  final String? semanticLabel;

  const BankFraudAlertBanner({
    required this.title,
    required this.body,
    required this.primaryActionLabel,
    required this.dismissLabel,
    required this.onPrimaryAction,
    required this.onDismiss,
    super.key,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.icon,
    this.titleStyle,
    this.bodyStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    // Brightness of the painted surface picks the AA-safe danger variant
    // and the hairline strength.
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(theme.surface);
    final accent = accentColor ??
        (surfaceBrightness == Brightness.dark
            ? BankTokens.dangerDark
            : BankTokens.danger);

    // Neutral surface washed with a low-alpha danger tint, never a
    // full-saturation slab; blended to stay opaque over any backdrop.
    final background = backgroundColor ??
        Color.alphaBlend(accent.withValues(alpha: 0.10), theme.surface);
    final bodyColor = foregroundColor ?? theme.onSurface;
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);

    return Semantics(
      label: semanticLabel ?? 'Fraud alert: $title',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius ?? theme.cardRadius,
          border: Border.fromBorderSide(
            BorderSide(
              color: BankTokens.hairlineColor(
                theme.onSurface,
                surfaceBrightness,
              ),
              // Matches BorderSide's default today; keep the token as the
              // source of truth for hairline geometry.
              // ignore: avoid_redundant_argument_values
              width: BankTokens.hairlineWidth,
            ),
          ),
        ),
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon ?? Icons.gpp_bad_outlined,
                    color: accent,
                    size: 24,
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: BankTokens.labelLarge
                              .copyWith(color: accent)
                              .merge(titleStyle),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          body,
                          style: BankTokens.bodySmall
                              .copyWith(color: bodyColor)
                              .merge(bodyStyle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BankTokens.space4),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: primaryActionLabel,
                      child: FilledButton(
                        onPressed: onPrimaryAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          // On light themes the accent is deep (light label);
                          // on dark themes the accent is a light tint (dark
                          // label). The theme surface tracks exactly that
                          // inversion, so it stays legible on both.
                          foregroundColor: theme.surface,
                          minimumSize: const Size(
                            double.infinity,
                            BankTokens.minTapTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: theme.buttonRadius,
                          ),
                          textStyle: bankButtonTextStyle(context),
                        ),
                        child: Text(primaryActionLabel),
                      ),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Semantics(
                    button: true,
                    label: dismissLabel,
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.onSurfaceVariant,
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BankTokens.space3,
                        ),
                        textStyle: bankButtonTextStyle(
                          context,
                          BankTokens.labelMedium,
                        ),
                      ),
                      child: Text(dismissLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
