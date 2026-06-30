import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Full-viewport empty-state widget.
///
/// Displays an optional illustration, a required [title], an optional
/// [subtitle], and an optional call-to-action [FilledButton].
///
/// The layout is a vertically and horizontally centred [Column]. If
/// [illustration] is non-null it is shown with a maximum height of 180 px and
/// a [BankTokens.space6] gap below it.
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
  /// not bundle illustration assets.
  final Widget? illustration;

  /// Short descriptive title. Required.
  final String title;

  /// Optional supporting sentence beneath the title.
  final String? subtitle;

  /// Label for the call-to-action button. Only shown when [onAction] is also
  /// non-null.
  final String? actionLabel;

  /// Callback invoked when the call-to-action button is tapped.
  final VoidCallback? onAction;

  const BankEmptyStateView({
    required this.title,
    super.key,
    this.illustration,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: illustration,
              ),
              const SizedBox(height: BankTokens.space6),
            ],
            Text(
              title,
              style: BankTokens.headlineMedium.copyWith(
                color: theme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: BankTokens.space2),
              Text(
                subtitle!,
                style: BankTokens.bodyMedium.copyWith(
                  color: theme.onSurfaceVariant,
                ),
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
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: theme.buttonRadius,
                    ),
                    textStyle: BankTokens.labelLarge,
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
