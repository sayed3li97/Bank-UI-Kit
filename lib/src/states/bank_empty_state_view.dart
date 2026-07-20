import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/button_text_style.dart';
import '../../src/theme/tokens.dart';

/// Full-viewport empty-state widget.
///
/// Displays an illustration, a required [title], an optional [subtitle],
/// and an optional call-to-action [FilledButton].
///
/// The layout is a vertically and horizontally centred [Column]. If
/// [illustration] is non-null it is shown with a maximum height of 180 px and
/// a [BankTokens.space6] gap below it. When [illustration] is null a themed
/// fallback is drawn instead: a soft circle tinted with the theme primary
/// colour holding a brand-tinted glyph, so empty moments never render as a
/// bare wireframe.
///
/// ```dart
/// BankEmptyStateView(
///   illustration: Image.asset('assets/empty_transactions.png'),
///   title: 'No transactions yet',
///   subtitle: 'Your payments and transfers will appear here.',
///   actionLabel: 'Make a Payment',
///   onAction: () => navigator.push(PaymentRoute()),
/// )
/// ```
class BankEmptyStateView extends StatelessWidget {
  /// Optional illustration widget placed above the title.
  ///
  /// The host app or a preset-specific helper supplies this; Bank UI Kit does
  /// not bundle illustration assets. When null, a themed fallback is shown:
  /// a 72 px circle filled with [BankThemeData.primary] at 10% alpha holding
  /// [emptyIcon] in the primary colour.
  final Widget? illustration;

  /// Glyph of the default illustration fallback shown when [illustration]
  /// is null. Defaults to [Icons.inbox_outlined].
  final IconData? emptyIcon;

  /// Short descriptive title. Required.
  final String title;

  /// Optional supporting sentence beneath the title.
  final String? subtitle;

  /// Label for the call-to-action button. Only shown when [onAction] is also
  /// non-null.
  final String? actionLabel;

  /// Callback invoked when the call-to-action button is tapped.
  final VoidCallback? onAction;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: BankTokens.space8)`.
  final EdgeInsetsGeometry? padding;

  /// Background of the call-to-action button and tint of the default
  /// illustration fallback. Defaults to [BankThemeData.primary].
  final Color? accentColor;

  /// Merged over the computed title style ([BankTokens.headlineMedium]
  /// in [BankThemeData.onSurface]).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodyMedium]
  /// in [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Container semantics label for the whole view. Defaults to none
  /// (children are read individually, as today).
  final String? semanticLabel;

  const BankEmptyStateView({
    required this.title,
    super.key,
    this.illustration,
    this.emptyIcon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.accentColor,
    this.titleStyle,
    this.subtitleStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final showAction = actionLabel != null && onAction != null;
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: BankTokens.space8);

    Widget content = Center(
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: illustration ?? _defaultIllustration(theme),
            ),
            const SizedBox(height: BankTokens.space6),
            Text(
              title,
              style: BankTokens.headlineMedium
                  .copyWith(color: theme.onSurface)
                  .merge(titleStyle),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: BankTokens.space2),
              Text(
                subtitle!,
                style: BankTokens.bodyMedium
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(subtitleStyle),
                textAlign: TextAlign.center,
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: BankTokens.space6),
              Semantics(
                button: true,
                label: actionLabel,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor ?? theme.primary,
                    foregroundColor: theme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                    textStyle: bankButtonTextStyle(context),
                  ),
                  child: Text(actionLabel!),
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

  /// Themed fallback illustration: a soft primary-tinted circle holding a
  /// brand-tinted glyph. Excluded from semantics — it is decorative.
  Widget _defaultIllustration(BankThemeData theme) {
    final accent = accentColor ?? theme.primary;
    return ExcludeSemantics(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(
          emptyIcon ?? Icons.inbox_outlined,
          size: 32,
          color: accent,
        ),
      ),
    );
  }
}
