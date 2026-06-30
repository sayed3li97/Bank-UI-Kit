import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/cards/bank_flip_card.dart';
import '../../src/common/bank_icon_spec.dart';
import '../../src/models/models.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import '../accounts/bank_balance_text.dart';

// ---------------------------------------------------------------------------
// Layout enum
// ---------------------------------------------------------------------------

/// Controls the arrangement of fields on the [BankHorizontalAccountCard] front
/// face.
enum BankHorizontalCardLayout {
  /// Balance hero on the left; account name + masked number on the right.
  balanceLeft,

  /// Account name + balance stack centred; type icon top-left, number
  /// bottom-right.
  centred,

  /// Balance hero at the bottom; account name + icon span the top row.
  balanceBottom,
}

// ---------------------------------------------------------------------------
// Background mode
// ---------------------------------------------------------------------------

/// Background decoration for [BankHorizontalAccountCard].
enum BankHorizontalCardBackground {
  /// Uses [BankThemeData.accentGradient] if present, otherwise solid primary.
  themeGradient,

  /// Solid [BankHorizontalAccountCard.primaryColor] (or
  /// [BankThemeData.primary] as fallback).
  solidColor,

  /// Network or asset image supplied via
  /// [BankHorizontalAccountCard.backgroundImage].
  image,
}

// ---------------------------------------------------------------------------
// BankHorizontalAccountCard
// ---------------------------------------------------------------------------

/// A landscape-format bank account card with a built-in 3-D flip animation.
///
/// **Front face** shows the account name, balance, masked number, and
/// account-type icon in a layout controlled by [layout]. **Back face** shows
/// the full account details (IBAN / account number, sort code / BIC) with a
/// copy-to-clipboard action.
///
/// The card background supports three modes via [background]:
/// - [BankHorizontalCardBackground.themeGradient] — preset accent gradient.
/// - [BankHorizontalCardBackground.solidColor] — [primaryColor] or
///   [BankThemeData.primary].
/// - [BankHorizontalCardBackground.image] — [backgroundImage] widget (any
///   [ImageProvider] — asset, network, memory).
///
/// Flip behaviour is fully configurable via [trigger], [flipButtonBuilder],
/// [isFlipped], and [onFlip] (see [BankFlipCard]).
///
/// ```dart
/// BankHorizontalAccountCard(
///   account: myAccount,
///   cardholderName: 'Alice Johnson',
///   background: BankHorizontalCardBackground.image,
///   backgroundImage: AssetImage('assets/card_bg.jpg'),
///   trigger: BankFlipTrigger.builtInButton,
///   layout: BankHorizontalCardLayout.centred,
/// )
/// ```
class BankHorizontalAccountCard extends StatelessWidget {
  /// The account whose data is displayed.
  final BankAccount account;

  /// Cardholder name shown on front and back. Defaults to [BankAccount.name].
  final String? cardholderName;

  // ── Background ──────────────────────────────────────────────────────────

  /// Which background mode to apply. Defaults to
  /// [BankHorizontalCardBackground.themeGradient].
  final BankHorizontalCardBackground background;

  /// Primary card colour for [BankHorizontalCardBackground.solidColor] and the
  /// gradient fallback.  Falls back to [BankThemeData.primary].
  final Color? primaryColor;

  /// Second gradient stop. Falls back to [BankThemeData.primaryVariant].
  final Color? secondaryColor;

  /// Image provider used when [background] is
  /// [BankHorizontalCardBackground.image]. Can be [AssetImage],
  /// [NetworkImage], [MemoryImage], etc.
  final ImageProvider? backgroundImage;

  /// How the background image is fitted when [background] is
  /// [BankHorizontalCardBackground.image].
  final BoxFit backgroundImageFit;

  /// Optional colour overlay blended on top of [backgroundImage] to ensure
  /// text remains readable.
  final Color? backgroundImageOverlay;

  // ── Layout ────────────────────────────────────────────────────────────────

  /// Field arrangement on the front face.
  final BankHorizontalCardLayout layout;

  /// Asset path for the card-network logo (e.g. `'assets/visa.png'`).
  final String? networkLogoAsset;

  // ── Flip ──────────────────────────────────────────────────────────────────

  /// How the flip is triggered. Defaults to [BankFlipTrigger.tapToFlip].
  final BankFlipTrigger trigger;

  /// Replaces the default flip button when
  /// [trigger] == [BankFlipTrigger.builtInButton].
  final Widget Function(BuildContext context, VoidCallback flip)?
      flipButtonBuilder;

  /// External flip state. Pair with [onFlip] to control from outside.
  final bool? isFlipped;

  /// Called when the flip trigger fires. Required when [isFlipped] is
  /// provided.
  final VoidCallback? onFlip;

  /// Duration of the flip. Defaults to 500 ms.
  final Duration flipDuration;

  /// Curve of the flip. Defaults to [Curves.easeInOutCubic].
  final Curve flipCurve;

  /// Axis of rotation. Defaults to [BankFlipAxis.horizontal].
  final BankFlipAxis flipAxis;

  // ── Size ──────────────────────────────────────────────────────────────────

  /// Card width. Defaults to 340.
  final double width;

  /// Card height. Defaults to 200.
  final double height;

  static const double _cardRadius = 16;

  const BankHorizontalAccountCard({
    required this.account,
    super.key,
    this.cardholderName,
    this.background = BankHorizontalCardBackground.themeGradient,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundImage,
    this.backgroundImageFit = BoxFit.cover,
    this.backgroundImageOverlay,
    this.layout = BankHorizontalCardLayout.balanceLeft,
    this.networkLogoAsset,
    this.trigger = BankFlipTrigger.tapToFlip,
    this.flipButtonBuilder,
    this.isFlipped,
    this.onFlip,
    this.flipDuration = const Duration(milliseconds: 500),
    this.flipCurve = Curves.easeInOutCubic,
    this.flipAxis = BankFlipAxis.horizontal,
    this.width = 340,
    this.height = 200,
  });

  // ── Decoration helpers ────────────────────────────────────────────────────

  BoxDecoration _buildDecoration(BankThemeData bankTheme) {
    final baseRadius = BorderRadius.circular(_cardRadius);

    switch (background) {
      case BankHorizontalCardBackground.themeGradient:
        return BoxDecoration(
          gradient: bankTheme.accentGradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor ?? bankTheme.primary,
                  secondaryColor ?? bankTheme.primaryVariant,
                ],
              ),
          borderRadius: baseRadius,
        );

      case BankHorizontalCardBackground.solidColor:
        return BoxDecoration(
          color: primaryColor ?? bankTheme.primary,
          borderRadius: baseRadius,
        );

      case BankHorizontalCardBackground.image:
        return BoxDecoration(
          borderRadius: baseRadius,
          color: primaryColor ?? bankTheme.primary,
          image: backgroundImage != null
              ? DecorationImage(
                  image: backgroundImage!,
                  fit: backgroundImageFit,
                  colorFilter: backgroundImageOverlay != null
                      ? ColorFilter.mode(
                          backgroundImageOverlay!,
                          BlendMode.srcATop,
                        )
                      : ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.25),
                          BlendMode.darken,
                        ),
                )
              : null,
        );
    }
  }

  // ── Icon helper ───────────────────────────────────────────────────────────

  IconData _iconForType(BankAccountType type) => switch (type) {
        BankAccountType.savings => BankIcons.accountSavings,
        BankAccountType.joint => BankIcons.accountJoint,
        BankAccountType.business => BankIcons.accountBusiness,
        BankAccountType.crypto => BankIcons.accountCrypto,
        BankAccountType.current || BankAccountType.isa => BankIcons.account,
      };

  // ── Front face ────────────────────────────────────────────────────────────

  Widget _buildFront(BuildContext context, BankThemeData bankTheme) {
    const primary = Colors.white;
    final secondary = Colors.white.withValues(alpha: 0.72);
    final dec = _buildDecoration(bankTheme);

    final typeIcon = Icon(
      _iconForType(account.type),
      color: secondary,
      size: 22,
    );
    final networkBadge = networkLogoAsset != null
        ? Image.asset(networkLogoAsset!, height: 26, fit: BoxFit.contain)
        : Text(
            account.type.name.toUpperCase(),
            style: BankTokens.labelSmall.copyWith(
              color: secondary,
              letterSpacing: 1,
            ),
          );
    final balanceWidget = BankBalanceText(
      money: account.balance,
      style: bankTheme.numeralLarge.copyWith(color: primary),
    );
    final maskedNumber = Text(
      account.maskedNumber,
      style: BankTokens.bodySmall.copyWith(
        color: secondary,
        letterSpacing: 2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      textDirection: TextDirection.ltr,
    );
    final accountName = Text(
      cardholderName ?? account.name,
      style: BankTokens.labelLarge.copyWith(color: primary),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    Widget content;
    switch (layout) {
      case BankHorizontalCardLayout.balanceLeft:
        content = Padding(
          padding: const EdgeInsets.all(BankTokens.space5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: balance hero + account name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    typeIcon,
                    const Spacer(),
                    balanceWidget,
                    const SizedBox(height: BankTokens.space1),
                    accountName,
                  ],
                ),
              ),
              const SizedBox(width: BankTokens.space4),
              // Right column: network logo + masked number
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  networkBadge,
                  maskedNumber,
                ],
              ),
            ],
          ),
        );

      case BankHorizontalCardLayout.centred:
        content = Padding(
          padding: const EdgeInsets.all(BankTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [typeIcon, networkBadge],
              ),
              const Spacer(),
              Center(child: accountName),
              const SizedBox(height: BankTokens.space1),
              Center(child: balanceWidget),
              const Spacer(),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: maskedNumber,
              ),
            ],
          ),
        );

      case BankHorizontalCardLayout.balanceBottom:
        content = Padding(
          padding: const EdgeInsets.all(BankTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      typeIcon,
                      const SizedBox(width: BankTokens.space2),
                      accountName,
                    ],
                  ),
                  networkBadge,
                ],
              ),
              const Spacer(),
              balanceWidget,
              const SizedBox(height: BankTokens.space1),
              maskedNumber,
            ],
          ),
        );
    }

    return Container(
      width: width,
      height: height,
      decoration: dec,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  // ── Back face ─────────────────────────────────────────────────────────────

  Widget _buildBack(BuildContext context, BankThemeData bankTheme) {
    const primary = Colors.white;
    final secondary = Colors.white.withValues(alpha: 0.72);
    final dec = _buildDecoration(bankTheme);
    final holder = cardholderName ?? account.name;

    Widget detailRow({
      required String label,
      required String value,
      bool copyable = false,
    }) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BankTokens.labelSmall.copyWith(color: secondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: BankTokens.bodySmall.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: value.contains(' ') ? 1.0 : 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textDirection: TextDirection.ltr,
              ),
              if (copyable) ...[
                const SizedBox(width: BankTokens.space1),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                  },
                  child: Icon(
                    Icons.copy_outlined,
                    size: 14,
                    color: secondary,
                    semanticLabel: 'Copy $label',
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: dec,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holder,
              style: BankTokens.labelLarge.copyWith(color: primary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const Spacer(),
            if (account.ibanOrAccountNumber != null) ...[
              detailRow(
                label: 'IBAN / Account',
                value: account.ibanOrAccountNumber!,
                copyable: true,
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            if (account.sortCodeOrBic != null) ...[
              detailRow(
                label: 'Sort Code / BIC',
                value: account.sortCodeOrBic!,
                copyable: true,
              ),
              const SizedBox(height: BankTokens.space3),
            ],
            detailRow(
              label: 'Currency',
              value: account.currencyCode,
            ),
            const Spacer(),
            // Tap-to-copy hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.touch_app_outlined, size: 12, color: secondary),
                const SizedBox(width: BankTokens.space1),
                Text(
                  'Tap values to copy',
                  style: BankTokens.labelSmall.copyWith(
                    color: secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final semanticBalance =
        '${account.balance.amount} ${account.balance.currencyCode}';

    return Semantics(
      label: 'Account card: ${account.name}, balance $semanticBalance',
      child: BankFlipCard(
        isFlipped: isFlipped,
        onFlip: onFlip,
        trigger: trigger,
        flipButtonBuilder: flipButtonBuilder,
        flipDuration: flipDuration,
        flipCurve: flipCurve,
        flipAxis: flipAxis,
        width: width,
        height: height,
        frontBuilder: (ctx, _) => _buildFront(ctx, bankTheme),
        backBuilder: (ctx, _) => _buildBack(ctx, bankTheme),
      ),
    );
  }
}
