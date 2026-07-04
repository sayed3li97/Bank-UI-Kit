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

  /// Overrides the screen background color. Defaults to the theme background.
  final Color? backgroundColor;

  /// Overrides the screen content padding. Defaults to
  /// `EdgeInsets.symmetric(horizontal: space6, vertical: space6)`.
  final EdgeInsetsGeometry? padding;

  /// Merged over the result title style
  /// (BankTokens.headlineLarge in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the beneficiary line style
  /// (BankTokens.bodyLarge in onSurfaceVariant).
  final TextStyle? beneficiaryStyle;

  /// Merged over the amount style
  /// (BankTokens.headlineMedium in onSurface).
  final TextStyle? amountStyle;

  /// Merged over the reference line style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? referenceStyle;

  /// Merged over the failure reason style
  /// (BankTokens.bodyMedium in onSurfaceVariant).
  final TextStyle? failureReasonStyle;

  /// Overrides the failure icon. Defaults to `Icons.error_outline`.
  final IconData errorIcon;

  /// Overrides the failure icon color. Defaults to `BankTokens.danger`.
  final Color? errorColor;

  /// Diameter of the success animation. Defaults to `96`.
  final double? successAnimationSize;

  /// Whether the success animation shows confetti. Defaults to `true`.
  final bool showConfetti;

  /// Overrides the share-receipt button icon. Defaults to
  /// `Icons.share_outlined`.
  final IconData shareReceiptIcon;

  /// Overrides the new-transfer button icon. Defaults to `Icons.add`.
  final IconData newTransferIcon;

  /// Overrides the primary button background. Defaults to the theme primary.
  final Color? buttonColor;

  /// Overrides the primary button foreground. Defaults to the theme
  /// onPrimary.
  final Color? buttonForegroundColor;

  /// Overrides the button corner radius. Defaults to the theme buttonRadius.
  final BorderRadius? buttonRadius;

  /// Semantics label on the success animation. Defaults to
  /// `'Transfer sent successfully'`.
  final String successSemanticLabel;

  /// Semantics label on the failure icon. Defaults to `'Transfer failed'`.
  final String failureSemanticLabel;

  /// Preposition before the beneficiary name. Defaults to `'To'`.
  final String toLabel;

  /// Prefix before the reference number. Defaults to `'Ref: '`.
  final String referenceLabel;

  /// Prefix for the reference number semantics label. Defaults to
  /// `'Reference number: '`.
  final String referenceSemanticPrefix;

  /// Label of the share-receipt button. Defaults to `'Share Receipt'`.
  final String shareReceiptLabel;

  /// Label of the new-transfer button. Defaults to `'New Transfer'`.
  final String newTransferLabel;

  /// Label of the primary done button. Defaults to `'Done'`.
  final String doneLabel;

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
    this.backgroundColor,
    this.padding,
    this.titleStyle,
    this.beneficiaryStyle,
    this.amountStyle,
    this.referenceStyle,
    this.failureReasonStyle,
    this.errorIcon = Icons.error_outline,
    this.errorColor,
    this.successAnimationSize,
    this.showConfetti = true,
    this.shareReceiptIcon = Icons.share_outlined,
    this.newTransferIcon = Icons.add,
    this.buttonColor,
    this.buttonForegroundColor,
    this.buttonRadius,
    this.successSemanticLabel = 'Transfer sent successfully',
    this.failureSemanticLabel = 'Transfer failed',
    this.toLabel = 'To',
    this.referenceLabel = 'Ref: ',
    this.referenceSemanticPrefix = 'Reference number: ',
    this.shareReceiptLabel = 'Share Receipt',
    this.newTransferLabel = 'New Transfer',
    this.doneLabel = 'Done',
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? bankTheme.background,
      body: SafeArea(
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
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
                        semanticLabel: successSemanticLabel,
                        animationSize: successAnimationSize,
                        showConfetti: showConfetti,
                        titleStyle: titleStyle,
                        toLabel: toLabel,
                        beneficiaryStyle: beneficiaryStyle,
                        amountStyle: amountStyle,
                        referenceLabel: referenceLabel,
                        referenceSemanticPrefix: referenceSemanticPrefix,
                        referenceStyle: referenceStyle,
                      )
                    : _FailureContent(
                        failureReason: failureReason,
                        bankTheme: bankTheme,
                        semanticLabel: failureSemanticLabel,
                        errorIcon: errorIcon,
                        errorColor: errorColor ?? BankTokens.danger,
                        titleStyle: titleStyle,
                        failureReasonStyle: failureReasonStyle,
                      ),
              ),
              const SizedBox(height: BankTokens.space6),
              // Action buttons
              _ActionButtons(
                bankTheme: bankTheme,
                onDone: onDone,
                onShareReceipt: isSuccess ? onShareReceipt : null,
                onNewTransfer: isSuccess ? onNewTransfer : null,
                shareReceiptLabel: shareReceiptLabel,
                shareReceiptIcon: shareReceiptIcon,
                newTransferLabel: newTransferLabel,
                newTransferIcon: newTransferIcon,
                doneLabel: doneLabel,
                buttonColor: buttonColor ?? bankTheme.primary,
                buttonForegroundColor:
                    buttonForegroundColor ?? bankTheme.onPrimary,
                buttonRadius: buttonRadius ?? bankTheme.buttonRadius,
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
    required this.semanticLabel,
    required this.animationSize,
    required this.showConfetti,
    required this.toLabel,
    required this.referenceLabel,
    required this.referenceSemanticPrefix,
    this.titleStyle,
    this.beneficiaryStyle,
    this.amountStyle,
    this.referenceStyle,
  });

  final Money? amount;
  final String? beneficiaryName;
  final String? referenceNumber;
  final BankThemeData bankTheme;
  final BankUiScopeData scope;
  final String semanticLabel;
  final double? animationSize;
  final bool showConfetti;
  final String toLabel;
  final String referenceLabel;
  final String referenceSemanticPrefix;
  final TextStyle? titleStyle;
  final TextStyle? beneficiaryStyle;
  final TextStyle? amountStyle;
  final TextStyle? referenceStyle;

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
          label: semanticLabel,
          child: BankSuccessAnimation(
            size: animationSize ?? 96,
            showConfetti: showConfetti,
          ),
        ),
        const SizedBox(height: BankTokens.space6),
        Text(
          scope.strings.transferSuccess,
          style: BankTokens.headlineLarge
              .copyWith(color: bankTheme.onSurface)
              .merge(titleStyle),
          textAlign: TextAlign.center,
        ),
        if (beneficiaryName != null || formattedAmount != null) ...[
          const SizedBox(height: BankTokens.space3),
          if (beneficiaryName != null)
            Text(
              '$toLabel ${beneficiaryName!}',
              style: BankTokens.bodyLarge
                  .copyWith(color: bankTheme.onSurfaceVariant)
                  .merge(beneficiaryStyle),
              textAlign: TextAlign.center,
            ),
          if (formattedAmount != null) ...[
            const SizedBox(height: BankTokens.space2),
            Text(
              formattedAmount,
              style: BankTokens.headlineMedium
                  .copyWith(color: bankTheme.onSurface)
                  .merge(amountStyle),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        if (referenceNumber != null) ...[
          const SizedBox(height: BankTokens.space4),
          Semantics(
            label: '$referenceSemanticPrefix$referenceNumber',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  referenceLabel,
                  style: BankTokens.bodySmall
                      .copyWith(color: bankTheme.onSurfaceVariant)
                      .merge(referenceStyle),
                ),
                SelectableText(
                  referenceNumber!,
                  style: BankTokens.bodySmall.copyWith(
                    color: bankTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ).merge(referenceStyle),
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
    required this.semanticLabel,
    required this.errorIcon,
    required this.errorColor,
    this.titleStyle,
    this.failureReasonStyle,
  });

  final String? failureReason;
  final BankThemeData bankTheme;
  final String semanticLabel;
  final IconData errorIcon;
  final Color errorColor;
  final TextStyle? titleStyle;
  final TextStyle? failureReasonStyle;

  @override
  Widget build(BuildContext context) {
    final scope = BankUiScope.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: semanticLabel,
          child: Icon(
            errorIcon,
            size: 80,
            color: errorColor,
          ),
        ),
        const SizedBox(height: BankTokens.space6),
        Text(
          scope.strings.transferFailure,
          style: BankTokens.headlineLarge
              .copyWith(color: bankTheme.onSurface)
              .merge(titleStyle),
          textAlign: TextAlign.center,
        ),
        if (failureReason != null) ...[
          const SizedBox(height: BankTokens.space3),
          Text(
            failureReason!,
            style: BankTokens.bodyMedium
                .copyWith(color: bankTheme.onSurfaceVariant)
                .merge(failureReasonStyle),
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
    required this.shareReceiptLabel,
    required this.shareReceiptIcon,
    required this.newTransferLabel,
    required this.newTransferIcon,
    required this.doneLabel,
    required this.buttonColor,
    required this.buttonForegroundColor,
    required this.buttonRadius,
  });

  final BankThemeData bankTheme;
  final VoidCallback onDone;
  final VoidCallback? onShareReceipt;
  final VoidCallback? onNewTransfer;
  final String shareReceiptLabel;
  final IconData shareReceiptIcon;
  final String newTransferLabel;
  final IconData newTransferIcon;
  final String doneLabel;
  final Color buttonColor;
  final Color buttonForegroundColor;
  final BorderRadius buttonRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Secondary actions row: only when at least one callback is provided.
        if (onShareReceipt != null || onNewTransfer != null) ...[
          Row(
            children: [
              if (onShareReceipt != null)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: shareReceiptLabel,
                    child: OutlinedButton.icon(
                      onPressed: onShareReceipt,
                      icon: Icon(shareReceiptIcon, size: 18),
                      label: Text(shareReceiptLabel),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        side: BorderSide(color: bankTheme.outline),
                        foregroundColor: bankTheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: buttonRadius,
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
                    label: newTransferLabel,
                    child: OutlinedButton.icon(
                      onPressed: onNewTransfer,
                      icon: Icon(newTransferIcon, size: 18),
                      label: Text(newTransferLabel),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          BankTokens.minTapTarget,
                          BankTokens.minTapTarget,
                        ),
                        side: BorderSide(color: bankTheme.outline),
                        foregroundColor: bankTheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: buttonRadius,
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
          label: doneLabel,
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonForegroundColor,
              minimumSize: const Size(
                double.infinity,
                BankTokens.minTapTarget,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: buttonRadius,
              ),
            ),
            child: Text(doneLabel),
          ),
        ),
      ],
    );
  }
}
