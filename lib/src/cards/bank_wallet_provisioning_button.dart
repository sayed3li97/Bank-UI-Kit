import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The digital wallet a [BankWalletProvisioningButton] targets.
enum BankWalletTarget { appleWallet, googleWallet }

/// Provisioning lifecycle of the card in the target wallet.
enum BankWalletProvisionState { notAdded, adding, added, unavailable }

/// Add-to-wallet button pair with platform-appropriate chrome, free of
/// platform APIs — the host wires the actual push-provisioning SDK into
/// [onPressed].
///
/// Renders the wallet-brand-mandated black button (min-width, padding
/// and typography per both brands' guidelines — replace the glyph and
/// wording only within what Apple's and Google's marks guidelines
/// allow; misuse risks app-store rejection). `adding` swaps the label
/// for a spinner; `added` becomes a non-interactive outlined
/// confirmation; `unavailable` collapses to nothing so layouts can
/// include the button unconditionally.
///
/// ```dart
/// BankWalletProvisioningButton(
///   target: BankWalletTarget.appleWallet,
///   state: _provisionState,
///   onPressed: _startProvisioning,
/// )
/// ```
class BankWalletProvisioningButton extends StatelessWidget {
  const BankWalletProvisioningButton({
    required this.target,
    required this.state,
    required this.onPressed,
    super.key,
    this.height = 48,
    this.appleLabel = 'Add to Apple Wallet',
    this.googleLabel = 'Add to Google Wallet',
    this.addedLabel = 'Added to wallet',
  });

  final BankWalletTarget target;
  final BankWalletProvisionState state;

  /// Starts provisioning via the host's wallet SDK.
  final VoidCallback onPressed;

  final double height;
  final String appleLabel;
  final String googleLabel;
  final String addedLabel;

  String get _label => switch (target) {
        BankWalletTarget.appleWallet => appleLabel,
        BankWalletTarget.googleWallet => googleLabel,
      };

  IconData get _glyph => switch (target) {
        BankWalletTarget.appleWallet => Icons.wallet_rounded,
        BankWalletTarget.googleWallet => Icons.account_balance_wallet_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    switch (state) {
      case BankWalletProvisionState.unavailable:
        return const SizedBox.shrink();

      case BankWalletProvisionState.added:
        return Semantics(
          label: addedLabel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.outline),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: theme.positiveBalance,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Text(
                    addedLabel,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        );

      case BankWalletProvisionState.notAdded:
      case BankWalletProvisionState.adding:
        final adding = state == BankWalletProvisionState.adding;
        return Semantics(
          button: true,
          enabled: !adding,
          label: _label,
          child: Material(
            // Both wallet brands mandate a black button irrespective of
            // app theme, so this color is intentionally not tokenized.
            color: const Color(0xFF000000),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: InkWell(
              onTap: adding ? null : onPressed,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 140,
                  minHeight: height,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BankTokens.space4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: adding
                        ? const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ]
                        : [
                            Icon(
                              _glyph,
                              size: 22,
                              color: const Color(0xFFFFFFFF),
                            ),
                            const SizedBox(width: BankTokens.space2),
                            Flexible(
                              child: Text(
                                _label,
                                style: BankTokens.labelLarge.copyWith(
                                  color: const Color(0xFFFFFFFF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
