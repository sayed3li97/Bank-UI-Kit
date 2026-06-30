import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/states/bank_success_animation.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankTransferResultScreen
// ---------------------------------------------------------------------------

/// Full-screen success or failure state shown after a transfer completes.
///
/// On success, plays [BankSuccessAnimation] with confetti, then shows the
/// transfer amount, beneficiary name, and reference number. On failure,
/// shows a red error icon and the [failureReason].
///
/// Action buttons are conditionally rendered based on which callbacks are
/// provided.
///
/// ```dart
/// BankTransferResultScreen(
///   isSuccess: true,
///   amount: Money.fromDouble(250, 'GBP'),
///   beneficiaryName: 'Alice Mensah',
///   referenceNumber: 'TXN-20240101-001234',
///   onDone: () => Navigator.of(context).pop(),
///   onShareReceipt: () => shareReceipt(),
///   onNewTransfer: () => Navigator.of(context).push(newTransferRoute),
/// )
/// ```
class BankTransferResultScreen extends StatelessWidget {
  /// `true` for a success state; `false` for a failure state.
  final bool isSuccess;

  /// The amount transferred. Shown below the animation on success.
  final Money? amount;

  /// Name of the beneficiary who received the transfer. Shown on success.
  final String? beneficiaryName;

  /// Reference number for the transfer. Shown in a smaller style on success.
  final String? referenceNumber;

  /// Human-readable failure reason. Shown on failure.
  final String? failureReason;

  /// Called when the primary "Done" button is tapped.
  final VoidCallback onDone;

  /// When non-null, a secondary "Share Receipt" button is shown.
  final VoidCallback? onShareReceipt;

  /// When non-null, a secondary "New Transfer" button is shown.
  final VoidCallback? onNewTransfer;

  const BankTransferResultScreen({
    required this.isSuccess,
    required this.onDone,
    super.key,
    this.amount,
    this.beneficiaryName,
    this.referenceNumber,
    this.failureReason,
    this.onShareReceipt,
    this.onNewTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    return Scaffold(
      backgroundColor: bankTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space6,
            vertical: BankTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: isSuccess
                    ? _SuccessContent(
                        amount: amount,
                        beneficiaryName: beneficiaryName,
                        referenceNumber: referenceNumber,
                        bankTheme: bankTheme,
                        scope: scope,
                      )
                    : _FailureContent(
                        failureReason: failureReason,
                        bankTheme: bankTheme,
                      ),
              ),
              const SizedBox(height: BankTokens.space6),
              // Action buttons
              _ActionButtons(
                bankTheme: bankTheme,
                onDone: onDone,
                onShareReceipt: isSuccess ? onShareReceipt : null,
                onNewTransfer: isSuccess ? onNewTransfer : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success content
// ---------------------------------------------------------------------------

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    required this.amount,
    required this.beneficiaryName,
    required this.referenceNumber,
    required this.bankTheme,
    required this.scope,
  });

  final Money? amount;
  final String? beneficiaryName;
  final String? referenceNumber;
  final BankThemeData bankTheme;
  final BankUiScopeData scope;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = amount != null
        ? BankMoneyFormatter.format(
            amount: amount!.amount,
            currencyCode: amount!.currencyCode,
            numeralStyle: scope.numeralStyle,
          )
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'Transfer sent successfully',
          child: const BankSuccessAnimation(
            size: 96,
            showConfetti: true,
          ),
        ),
        const SizedBox(height: BankTokens.space6),
        Text(
          scope.strings.transferSuccess,
          style: BankTokens.headlineLarge.copyWith(
            color: bankTheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        if (beneficiaryName != null || formattedAmount != null) ...[
          const SizedBox(height: BankTokens.space3),
          if (beneficiaryName != null)
            Text(
              'To ${beneficiaryName!}',
              style: BankTokens.bodyLarge.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          if (formattedAmount != null) ...[
            const SizedBox(height: BankTokens.space2),
            Text(
              formattedAmount,
              style: BankTokens.headlineMedium.copyWith(
                color: bankTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        if (referenceNumber != null) ...[
          const SizedBox(height: BankTokens.space4),
          Semantics(
            label: 'Reference number: $referenceNumber',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ref: ',
                  style: BankTokens.bodySmall.copyWith(
                    color: bankTheme.onSurfaceVariant,
                  ),
                ),
                SelectableText(
                  referenceNumber!,
                  style: BankTokens.bodySmall.copyWith(
                    color: bankTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Failure content
// ---------------------------------------------------------------------------

class _FailureContent extends StatelessWidget {
  const _FailureContent({
    required this.failureReason,
    required this.bankTheme,
  });

  final String? failureReason;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    final scope = BankUiScope.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'Transfer failed',
          child: const Icon(
            Icons.error_outline,
            size: 80,
            color: BankTokens.danger,
          ),
        ),
        const SizedBox(height: BankTokens.space6),
        Text(
          scope.strings.transferFailure,
          style: BankTokens.headlineLarge.copyWith(
            color: bankTheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        if (failureReason != null) ...[
          const SizedBox(height: BankTokens.space3),
          Text(
            failureReason!,
            style: BankTokens.bodyMedium.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.bankTheme,
    required this.onDone,
    required this.onShareReceipt,
    required this.onNewTransfer,
  });

  final BankThemeData bankTheme;
  final VoidCallback onDone;
  final VoidCallback? onShareReceipt;
  final VoidCallback? onNewTransfer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Secondary actions row — only when at least one callback is provided.
        if (onShareReceipt != null || onNewTransfer != null) ...[
          Row(
            children: [
              if (onShareReceipt != null)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Share Receipt',
                    child: OutlinedButton.icon(
                      onPressed: onShareReceipt,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share Receipt'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        side: BorderSide(color: bankTheme.outline),
                        foregroundColor: bankTheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: bankTheme.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              if (onShareReceipt != null && onNewTransfer != null)
                const SizedBox(width: BankTokens.space3),
              if (onNewTransfer != null)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'New Transfer',
                    child: OutlinedButton.icon(
                      onPressed: onNewTransfer,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Transfer'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        side: BorderSide(color: bankTheme.outline),
                        foregroundColor: bankTheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: bankTheme.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space3),
        ],
        // Primary "Done" button
        Semantics(
          button: true,
          label: 'Done',
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: bankTheme.primary,
              foregroundColor: bankTheme.onPrimary,
              minimumSize: const Size(
                double.infinity,
                BankTokens.minTapTarget,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: bankTheme.buttonRadius,
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
