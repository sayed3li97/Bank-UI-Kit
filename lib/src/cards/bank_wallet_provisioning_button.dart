import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The digital wallet a [BankWalletProvisioningButton] targets.
enum BankWalletTarget { appleWallet, googleWallet }

/// Provisioning lifecycle of the card in the target wallet.
enum BankWalletProvisionState { notAdded, adding, added, unavailable }

/// Add-to-wallet button pair with platform-appropriate chrome, free of
/// platform APIs: the host wires the actual push-provisioning SDK into
/// [onPressed].
///
/// Renders the wallet-brand-mandated black button (min-width, padding
/// and typography per both brands' guidelines: replace the glyph and
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
    this.padding,
    this.minWidth = 140,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.labelStyle,
    this.addedLabelStyle,
    this.appleWalletIcon = Icons.wallet_rounded,
    this.googleWalletIcon = Icons.account_balance_wallet_rounded,
    this.addedIcon = Icons.check_circle_rounded,
    this.semanticLabel,
  });

  final BankWalletTarget target;
  final BankWalletProvisionState state;

  /// Starts provisioning via the host's wallet SDK.
  final VoidCallback onPressed;

  final double height;
  final String appleLabel;
  final String googleLabel;
  final String addedLabel;

  /// Overrides the button content padding; defaults to horizontal
  /// [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Minimum button width; defaults to 140 per wallet brand guidance.
  final double minWidth;

  /// Overrides the corner radius of both states; defaults to a
  /// circular radius of 8 per wallet brand guidance.
  final BorderRadius? radius;

  /// Overrides the brand-mandated black button fill; defaults to pure
  /// black. Deviating may breach wallet brand guidelines.
  final Color? backgroundColor;

  /// Overrides the button glyph, label, and spinner color; defaults
  /// to white per wallet brand guidelines.
  final Color? foregroundColor;

  /// Overrides the added-state check icon color; defaults to the
  /// theme positiveBalance color.
  final Color? accentColor;

  /// Merged over the button label style, [BankTokens.labelLarge].
  final TextStyle? labelStyle;

  /// Merged over the added-state label style,
  /// [BankTokens.labelLarge].
  final TextStyle? addedLabelStyle;

  /// Glyph for the Apple Wallet button; defaults to
  /// [Icons.wallet_rounded].
  final IconData appleWalletIcon;

  /// Glyph for the Google Wallet button; defaults to
  /// [Icons.account_balance_wallet_rounded].
  final IconData googleWalletIcon;

  /// Glyph in the added state; defaults to
  /// [Icons.check_circle_rounded].
  final IconData addedIcon;

  /// Overrides the Semantics label; defaults to the visible label of
  /// the current state.
  final String? semanticLabel;

  String get _label => switch (target) {
        BankWalletTarget.appleWallet => appleLabel,
        BankWalletTarget.googleWallet => googleLabel,
      };

  IconData get _glyph => switch (target) {
        BankWalletTarget.appleWallet => appleWalletIcon,
        BankWalletTarget.googleWallet => googleWalletIcon,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final resolvedRadius = radius ?? const BorderRadius.all(Radius.circular(8));
    final resolvedBackground = backgroundColor ?? const Color(0xFF000000);
    final resolvedForeground = foregroundColor ?? const Color(0xFFFFFFFF);
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: BankTokens.space4);
    final resolvedAccent = accentColor ?? theme.positiveBalance;

    switch (state) {
      case BankWalletProvisionState.unavailable:
        return const SizedBox.shrink();

      case BankWalletProvisionState.added:
        return Semantics(
          label: semanticLabel ?? addedLabel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.outline),
              borderRadius: resolvedRadius,
            ),
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(addedIcon, size: 20, color: resolvedAccent),
                  const SizedBox(width: BankTokens.space2),
                  Text(
                    addedLabel,
                    style: BankTokens.labelLarge
                        .copyWith(color: theme.onSurface)
                        .merge(addedLabelStyle),
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
          label: semanticLabel ?? _label,
          child: Material(
            // Both wallet brands mandate a black button irrespective of
            // app theme, so this color is intentionally not tokenized.
            color: resolvedBackground,
            borderRadius: resolvedRadius,
            child: InkWell(
              onTap: adding ? null : onPressed,
              borderRadius: resolvedRadius,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minWidth,
                  minHeight: height,
                ),
                child: Padding(
                  padding: resolvedPadding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: adding
                        ? [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: resolvedForeground,
                              ),
                            ),
                          ]
                        : [
                            Icon(
                              _glyph,
                              size: 22,
                              color: resolvedForeground,
                            ),
                            const SizedBox(width: BankTokens.space2),
                            Flexible(
                              child: Text(
                                _label,
                                style: BankTokens.labelLarge
                                    .copyWith(color: resolvedForeground)
                                    .merge(labelStyle),
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
