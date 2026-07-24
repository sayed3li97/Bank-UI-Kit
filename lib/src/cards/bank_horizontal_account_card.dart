import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/cards/bank_card_network_badge.dart';
import '../../src/cards/bank_flip_card.dart';
import '../../src/common/bank_icon_spec.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/card_pattern.dart';
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
/// - [BankHorizontalCardBackground.themeGradient]: preset accent gradient.
/// - [BankHorizontalCardBackground.solidColor]: [primaryColor] or
///   [BankThemeData.primary].
/// - [BankHorizontalCardBackground.image]: [backgroundImage] widget (any
///   [ImageProvider]: asset, network, memory).
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

  /// Fixed card width. When null (the default) the card fills the available
  /// width up to [maxWidth] (340 when [maxWidth] is also null), so it renders
  /// at 340 in unconstrained contexts, exactly as older versions did.
  final double? width;

  /// Fixed card height. When null (the default) the height is derived from
  /// the resolved width using the ISO 7810 ID-1 card ratio
  /// ([kBankCardAspectRatio], 1.586) so this card matches the rest of the
  /// card family.
  final double? height;

  /// Upper bound on the card width when [width] is null. Defaults to 340,
  /// matching the previous fixed width.
  final double? maxWidth;

  // Customization overrides (all optional; null keeps current behaviour).

  /// Content padding of both faces. Defaults to
  /// `EdgeInsets.all(BankTokens.space5)`.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the card. Defaults to [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the gradient painted in
  /// [BankHorizontalCardBackground.themeGradient] mode. Defaults to
  /// [BankThemeData.accentGradient], with a [primaryColor] to
  /// [secondaryColor] fallback.
  final Gradient? gradient;

  /// Base colour of all text and icons on the card. Defaults to
  /// [BankThemeData.onPrimary]; secondary elements use it at 72% alpha.
  final Color? foregroundColor;

  /// Merged over the account-name style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the balance style ([BankThemeData.numeralLarge]).
  final TextStyle? amountStyle;

  /// Merged over the masked-number style (the shared card-family PAN
  /// treatment: letter-spaced [BankTokens.numeralMedium]).
  final TextStyle? maskedNumberStyle;

  /// Merged over the fallback network-badge text style
  /// ([BankTokens.labelSmall]) shown when [networkLogoAsset] is null.
  final TextStyle? networkLabelStyle;

  /// Merged over the back-face detail-label style ([BankTokens.labelSmall]).
  final TextStyle? detailLabelStyle;

  /// Merged over the back-face detail-value style ([BankTokens.bodySmall]).
  final TextStyle? detailValueStyle;

  /// Merged over the copy-hint text style ([BankTokens.labelSmall]).
  final TextStyle? copyHintStyle;

  /// Overrides the account-type glyph. Defaults to the [BankIcons] glyph
  /// derived from [BankAccount.type].
  final IconData? typeIcon;

  /// Copy-action glyph on back-face rows. Defaults to [Icons.copy_outlined].
  final IconData? copyIcon;

  /// Glyph next to the copy hint. Defaults to [Icons.touch_app_outlined].
  final IconData? copyHintIcon;

  /// Label of the IBAN / account number row. Defaults to 'IBAN / Account'.
  final String? ibanLabel;

  /// Label of the sort code / BIC row. Defaults to 'Sort Code / BIC'.
  final String? sortCodeLabel;

  /// Label of the currency row. Defaults to 'Currency'.
  final String? currencyLabel;

  /// Copy hint shown on the back face. Defaults to 'Tap values to copy'.
  final String? copyHintLabel;

  /// Verb used in the copy-icon semantics, read as `<verb> <row label>`.
  /// Defaults to 'Copy'.
  final String? copyActionLabel;

  /// Overrides the card semantics label. Defaults to
  /// `Account card: <account name>, balance <balance>`.
  final String? semanticLabel;

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
    this.width,
    this.height,
    this.maxWidth,
    this.padding,
    this.radius,
    this.gradient,
    this.foregroundColor,
    this.titleStyle,
    this.amountStyle,
    this.maskedNumberStyle,
    this.networkLabelStyle,
    this.detailLabelStyle,
    this.detailValueStyle,
    this.copyHintStyle,
    this.typeIcon,
    this.copyIcon,
    this.copyHintIcon,
    this.ibanLabel,
    this.sortCodeLabel,
    this.currencyLabel,
    this.copyHintLabel,
    this.copyActionLabel,
    this.semanticLabel,
  });

  // ── Decoration helpers ────────────────────────────────────────────────────

  BoxDecoration _buildDecoration(BankThemeData bankTheme) {
    final baseRadius = radius ?? bankTheme.cardRadius;

    switch (background) {
      case BankHorizontalCardBackground.themeGradient:
        return BoxDecoration(
          gradient: gradient ??
              bankTheme.cardSurfaceGradient ??
              bankTheme.accentGradient ??
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

  // ── Face helpers ──────────────────────────────────────────────────────────

  /// Horizontal space a face reserves at the top-end corner so content never
  /// collides with [BankFlipCard]'s built-in flip-button overlay.
  double _cornerClearance(
    BuildContext context,
    EdgeInsetsGeometry resolvedPadding,
  ) {
    if (trigger != BankFlipTrigger.builtInButton) return 0;
    final dir = Directionality.of(context);
    final pad = resolvedPadding.resolve(dir);
    final endPad = dir == TextDirection.rtl ? pad.left : pad.right;
    final clearance = BankFlipCard.builtInButtonClearance - endPad;
    return clearance > 0 ? clearance : 0;
  }

  /// Layers the theme's generative card pattern beneath [content]; image
  /// backgrounds carry their own artwork and skip it.
  Widget _withPattern(Widget content, BankThemeData bankTheme) {
    final pattern = bankTheme.cardPattern;
    if (pattern == BankCardPattern.none ||
        background == BankHorizontalCardBackground.image) {
      return content;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: BankCardPatternPainter(
              pattern: pattern,
              color: bankTheme.cardPatternColor ??
                  bankTheme.onPrimary.withValues(alpha: 0.08),
            ),
          ),
        ),
        content,
      ],
    );
  }

  // ── Front face ────────────────────────────────────────────────────────────

  Widget _buildFront(BuildContext context, BankThemeData bankTheme) {
    final primary = foregroundColor ?? bankTheme.onPrimary;
    final secondary = primary.withValues(alpha: 0.72);
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space5);
    final dec = _buildDecoration(bankTheme);
    final cornerClearance = _cornerClearance(context, resolvedPadding);

    final typeIconWidget = Icon(
      typeIcon ?? _iconForType(account.type),
      color: secondary,
      size: 22,
    );
    var networkBadge = networkLogoAsset != null
        ? Image.asset(networkLogoAsset!, height: 26, fit: BoxFit.contain)
        : Text(
            account.type.name.toUpperCase(),
            style: BankTokens.labelSmall
                .copyWith(
                  color: secondary,
                  letterSpacing: 1,
                )
                .merge(networkLabelStyle),
          );
    if (cornerClearance > 0) {
      // All three layouts place the badge at the top-end corner; shift it
      // start-ward so the built-in flip button never occludes it.
      networkBadge = Padding(
        padding: EdgeInsetsDirectional.only(end: cornerClearance),
        child: networkBadge,
      );
    }
    final balanceWidget = BankBalanceText(
      money: account.balance,
      style: bankTheme.numeralLarge.copyWith(color: primary).merge(amountStyle),
    );
    // Shared card-family PAN treatment (see `bankMaskedPanSpan`).
    final maskedNumber = Text.rich(
      bankMaskedPanSpan(
        account.maskedNumber,
        BankTokens.numeralMedium
            .copyWith(
              color: secondary,
              letterSpacing: 2.4,
              height: 1,
            )
            .merge(maskedNumberStyle),
      ),
      textDirection: TextDirection.ltr,
    );
    final accountName = Text(
      cardholderName ?? account.name,
      style: BankTokens.labelLarge.copyWith(color: primary).merge(titleStyle),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    Widget content;
    switch (layout) {
      case BankHorizontalCardLayout.balanceLeft:
        content = Padding(
          padding: resolvedPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: balance hero + account name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    typeIconWidget,
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
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [typeIconWidget, networkBadge],
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
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      typeIconWidget,
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
      child: _withPattern(content, bankTheme),
    );
  }

  // ── Back face ─────────────────────────────────────────────────────────────

  Widget _buildBack(BuildContext context, BankThemeData bankTheme) {
    final primary = foregroundColor ?? bankTheme.onPrimary;
    final secondary = primary.withValues(alpha: 0.72);
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space5);
    final resolvedCopyIcon = copyIcon ?? Icons.copy_outlined;
    final resolvedCopyAction = copyActionLabel ?? 'Copy';
    final dec = _buildDecoration(bankTheme);
    final holder = cardholderName ?? account.name;
    final cornerClearance = _cornerClearance(context, resolvedPadding);

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
            style: BankTokens.labelSmall
                .copyWith(color: secondary)
                .merge(detailLabelStyle),
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
                ).merge(detailValueStyle),
                textDirection: TextDirection.ltr,
              ),
              if (copyable) ...[
                const SizedBox(width: BankTokens.space1),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                  },
                  child: Icon(
                    resolvedCopyIcon,
                    size: 14,
                    color: secondary,
                    semanticLabel: '$resolvedCopyAction $label',
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
      child: _withPattern(
        Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Keep a long cardholder name clear of the built-in flip
                // button at the top-end corner.
                padding: EdgeInsetsDirectional.only(end: cornerClearance),
                child: Text(
                  holder,
                  style: BankTokens.labelLarge
                      .copyWith(color: primary)
                      .merge(titleStyle),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              if (account.ibanOrAccountNumber != null) ...[
                detailRow(
                  label: ibanLabel ?? 'IBAN / Account',
                  value: account.ibanOrAccountNumber!,
                  copyable: true,
                ),
                const SizedBox(height: BankTokens.space3),
              ],
              if (account.sortCodeOrBic != null) ...[
                detailRow(
                  label: sortCodeLabel ?? 'Sort Code / BIC',
                  value: account.sortCodeOrBic!,
                  copyable: true,
                ),
                const SizedBox(height: BankTokens.space3),
              ],
              detailRow(
                label: currencyLabel ?? 'Currency',
                value: account.currencyCode,
              ),
              const Spacer(),
              // Tap-to-copy hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    copyHintIcon ?? Icons.touch_app_outlined,
                    size: 12,
                    color: secondary,
                  ),
                  const SizedBox(width: BankTokens.space1),
                  Text(
                    copyHintLabel ?? 'Tap values to copy',
                    style: BankTokens.labelSmall
                        .copyWith(
                          color: secondary,
                          fontSize: 10,
                        )
                        .merge(copyHintStyle),
                  ),
                ],
              ),
            ],
          ),
        ),
        bankTheme,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    // Never announce the raw balance while privacy mode is active.
    final semanticBalance = scope.privacyEnabled
        ? scope.strings.balanceHidden
        : '${account.balance.amount} ${account.balance.currencyCode}';
    final resolvedSemanticLabel = semanticLabel ??
        'Account card: ${account.name}, balance $semanticBalance';

    return Semantics(
      label: resolvedSemanticLabel,
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
        maxWidth: maxWidth,
        frontBuilder: (ctx, _) => _buildFront(ctx, bankTheme),
        backBuilder: (ctx, _) => _buildBack(ctx, bankTheme),
      ),
    );
  }
}
