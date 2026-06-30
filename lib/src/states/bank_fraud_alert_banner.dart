import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// High-priority fraud warning banner.
///
/// Deliberately resists accidental dismissal:
/// - No swipe-to-dismiss gesture.
/// - The [onDismiss] button is small and positioned as a secondary action.
/// - The primary action ([onPrimaryAction]) is the prominent call to act.
///
/// Visual treatment:
/// - A 4 px [BankTokens.danger]-coloured left border on a
///   `danger.withValues(alpha: 0.08)` background.
/// - A [Icons.gpp_bad_outlined] fraud icon at the top-left.
/// - [title] in [BankTokens.labelLarge] (danger colour).
/// - [body] in [BankTokens.bodySmall] ([BankThemeData.onSurface]).
/// - Two action buttons side by side: [FilledButton] for [primaryActionLabel],
///   [TextButton] for [dismissLabel].
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
///   dismissLabel: 'Not me — dismiss',
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

  const BankFraudAlertBanner({
    required this.title,
    required this.body,
    required this.primaryActionLabel,
    required this.dismissLabel,
    required this.onPrimaryAction,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    const dangerColor = BankTokens.danger;
    final dangerBg = dangerColor.withValues(alpha: 0.08);

    return Semantics(
      label: 'Fraud alert: $title',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dangerBg,
          borderRadius: theme.cardRadius,
          border: const Border(
            left: BorderSide(
              color: dangerColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.gpp_bad_outlined,
                    color: dangerColor,
                    size: 24,
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: BankTokens.labelLarge.copyWith(
                            color: dangerColor,
                          ),
                        ),
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          body,
                          style: BankTokens.bodySmall.copyWith(
                            color: theme.onSurface,
                          ),
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
                          backgroundColor: dangerColor,
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(
                            double.infinity,
                            BankTokens.minTapTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: theme.buttonRadius,
                          ),
                          textStyle: BankTokens.labelLarge,
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
                        textStyle: BankTokens.labelMedium,
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
