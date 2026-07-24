import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/bank_pressable.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import 'bank_balance_text.dart';

/// Swipeable card that visually represents a single bank account.
///
/// Renders the account balance, type icon, masked account number, account name,
/// and — when the account is not active — a status chip derived from the
/// theme's semantic roles. Frozen accounts are additionally desaturated
/// (see [BankTokens.frozenCardSaturation]) so the state is unmistakable at a
/// glance without obscuring the numerals.
///
/// By default the card sizes itself to its content. In tight-height contexts
/// (an explicit [height], or a [PageView] viewport) the balance block pins to
/// the bottom edge while the icon row stays at the top.
///
/// **Theme surface treatments:**
/// - *Voltage*: `BankThemeData.accentGradient` is non-null → violet/cyan
///   gradient background, white text, and a coloured glow
///   ([BankThemeData.glowColor]) when [BankThemeData.useGlow] is `true`.
///   Wrapped in [RepaintBoundary] to isolate gradient repaints.
/// - *Studio / Bloom / Heritage*: flat `BankThemeData.surface` background
///   with `BankThemeData.onSurface` text, a resting [BankTokens.shadowCard]
///   ([BankTokens.shadowCardDark] on dark backgrounds), and a hairline
///   outline on dark surfaces where a shadow alone cannot separate the card
///   from the background.
///
/// Wrap multiple [BankAccountCard]s in a [PageView] to enable swiping between
/// accounts:
///
/// ```dart
/// PageView(
///   children: accounts
///       .map((a) => Padding(
///             padding: const EdgeInsets.symmetric(horizontal: 16),
///             child: BankAccountCard(account: a, onTap: () {}),
///           ))
///       .toList(),
/// )
/// ```
class BankAccountCard extends StatelessWidget {
  /// The account data to display.
  final BankAccount account;

  /// Called when the card is tapped. If `null`, no tap interaction is wired.
  final VoidCallback? onTap;

  /// Called on a long-press, e.g. to show a context menu.
  final VoidCallback? onLongPress;

  /// When non-null, completely overrides the default card content. The
  /// builder receives [BuildContext] and the [BankAccount] and must return
  /// a widget tree that fills the card.
  final Widget Function(BuildContext, BankAccount)? itemBuilder;

  /// `true` uses [BankBalanceSize.hero] for the balance; `false` uses
  /// [BankBalanceSize.large] (compact mode e.g. in the account switcher).
  final bool showFullBalance;

  /// Optional widget rendered at the bottom of the card, e.g. a row of
  /// action buttons. It is placed below the account-name / status row.
  final Widget? actions;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme `cardRadius`.
  final BorderRadius? radius;

  /// Overrides the flat background colour. Defaults to the theme
  /// `surface`. Ignored while a gradient is painted.
  final Color? backgroundColor;

  /// Overrides the background gradient. Defaults to the theme
  /// `accentGradient` when the preset provides one.
  final Gradient? gradient;

  /// Overrides the primary text colour. Defaults to white on gradient
  /// surfaces, otherwise the theme `onSurface`.
  final Color? foregroundColor;

  /// Overrides the secondary text and icon colour. Defaults to 80% white
  /// on gradient surfaces, otherwise the theme `onSurfaceVariant`.
  final Color? secondaryColor;

  /// Overrides the card shadow. Defaults to the theme glow when
  /// `useGlow` is on, otherwise the resting card shadow
  /// ([BankTokens.shadowCardFor] of the theme background brightness);
  /// pass `const []` to remove it.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark flat surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light flat surfaces keep an invisible border of the same width so
  /// geometry is identical across brightness. Gradient surfaces default to
  /// no border. Pass `const Border()` to remove the hairline entirely.
  final BoxBorder? border;

  /// Merged over the account-name style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the balance style (theme `numeralHero`/`numeralLarge`).
  final TextStyle? amountStyle;

  /// Merged over the masked-number style ([BankTokens.bodySmall]).
  final TextStyle? numberStyle;

  /// Overrides the account-type icon derived from [BankAccount.type].
  final IconData? typeIcon;

  /// Overrides the icon shown inside the frozen status chip. Defaults to
  /// [BankIcons.cardFreeze].
  final IconData? frozenIcon;

  /// Status chip label for closed accounts. Defaults to `'Closed'`.
  final String closedLabel;

  /// Accessibility label of the frozen-chip icon. Defaults to
  /// `'Account frozen'`.
  final String frozenSemanticLabel;

  /// Overrides the computed accessibility label of the whole card.
  final String? semanticLabel;

  /// Overrides the card height. When `null` (the default) the card sizes
  /// itself to its content; set an explicit height for fixed-height
  /// contexts such as carousels, where the balance block pins to the
  /// bottom edge.
  final double? height;

  const BankAccountCard({
    required this.account,
    super.key,
    this.onTap,
    this.onLongPress,
    this.itemBuilder,
    this.showFullBalance = true,
    this.actions,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.secondaryColor,
    this.shadow,
    this.border,
    this.titleStyle,
    this.amountStyle,
    this.numberStyle,
    this.typeIcon,
    this.frozenIcon,
    this.closedLabel = 'Closed',
    this.frozenSemanticLabel = 'Account frozen',
    this.semanticLabel,
    this.height,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the icon appropriate for the account type.
  IconData _iconForType(BankAccountType type) => switch (type) {
        BankAccountType.savings => BankIcons.accountSavings,
        BankAccountType.joint => BankIcons.accountJoint,
        BankAccountType.business => BankIcons.accountBusiness,
        BankAccountType.crypto => BankIcons.accountCrypto,
        BankAccountType.current || BankAccountType.isa => BankIcons.account,
      };

  /// Rec. 709 luma saturation matrix: `1.0` is identity, `0.0` is greyscale.
  /// Desaturation preserves relative luminance, so text contrast survives on
  /// light, dark, and gradient surfaces alike.
  static ColorFilter _saturationFilter(double saturation) {
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;
    final inv = 1 - saturation;
    final r = inv * lumR;
    final g = inv * lumG;
    final b = inv * lumB;
    return ColorFilter.matrix(<double>[
      r + saturation, g, b, 0, 0, //
      r, g + saturation, b, 0, 0, //
      r, g, b + saturation, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }

  /// Builds the small status chip shown when the account is not active.
  ///
  /// The chip is derived from the theme's semantic roles — a low-alpha fill
  /// of the role colour under full-strength role ink. On gradient surfaces
  /// the chip uses [textColor] (white-alpha fill, white ink) so it stays
  /// legible over any gradient stop.
  Widget _buildStatusChip(
    BuildContext context,
    BankAccountStatus status,
    BankThemeData bankTheme,
    Color textColor, {
    required bool isGradient,
    required Brightness surfaceBrightness,
  }) {
    if (status == BankAccountStatus.active) return const SizedBox.shrink();

    final data = BankUiScope.of(context);
    final isDarkSurface = surfaceBrightness == Brightness.dark;

    final (Color role, String label) = switch (status) {
      BankAccountStatus.frozen => (
          isGradient ? textColor : bankTheme.frozen,
          data.strings.frozen,
        ),
      BankAccountStatus.restricted => (
          isGradient
              ? textColor
              : (isDarkSurface ? BankTokens.warningDark : BankTokens.warning),
          data.strings.restricted,
        ),
      BankAccountStatus.pending => (
          isGradient ? textColor : bankTheme.pending,
          data.strings.pending,
        ),
      BankAccountStatus.closed => (
          isGradient ? textColor : bankTheme.onSurfaceVariant,
          closedLabel,
        ),
      BankAccountStatus.active => (textColor, ''),
    };

    final labelText = Text(
      label,
      style: BankTokens.labelSmall.copyWith(color: role),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: BankTokens.space1,
      ),
      decoration: BoxDecoration(
        // Low-alpha role fill under full-strength role ink, matching the
        // kit-wide semantic chip treatment.
        color: role.withValues(alpha: 0.16),
        borderRadius: bankTheme.chipRadius,
      ),
      child: status == BankAccountStatus.frozen
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  frozenIcon ?? BankIcons.cardFreeze,
                  size: BankTokens.space4,
                  color: role,
                  semanticLabel: frozenSemanticLabel,
                ),
                const SizedBox(width: BankTokens.space1),
                labelText,
              ],
            )
          : labelText,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Delegate to custom builder if provided.
    if (itemBuilder != null) {
      return itemBuilder!(context, account);
    }

    final bankTheme = BankThemeData.of(context);
    // An explicit backgroundColor suppresses the theme gradient; an
    // explicit gradient always wins.
    final resolvedGradient =
        gradient ?? (backgroundColor == null ? bankTheme.accentGradient : null);
    final isGradient = resolvedGradient != null;
    final isFrozen = account.status == BankAccountStatus.frozen;
    final resolvedRadius = radius ?? bankTheme.cardRadius;

    // Brightness of the actual painted flat surface (honours a
    // caller-supplied backgroundColor) drives the hairline; brightness of
    // the theme background drives the resting shadow.
    final resolvedSurface = backgroundColor ?? bankTheme.surface;
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(resolvedSurface);
    final backgroundBrightness =
        ThemeData.estimateBrightnessForColor(bankTheme.background);

    // Determine text colours based on surface treatment.
    final primaryTextColor = foregroundColor ??
        (isGradient ? const Color(0xFFFFFFFF) : bankTheme.onSurface);
    final secondaryTextColor = secondaryColor ??
        (isGradient
            ? const Color(0xCCFFFFFF) // 80% white
            : bankTheme.onSurfaceVariant);

    // Compose background decoration. On dark flat surfaces a hairline
    // separates the card from the background where the shadow alone cannot;
    // light flat surfaces carry an invisible border of the same width so
    // geometry stays identical across brightness.
    final resolvedBorder = border ??
        (isGradient
            ? null
            : Border.all(
                color: surfaceBrightness == Brightness.dark
                    ? BankTokens.hairlineColor(
                        bankTheme.onSurface,
                        surfaceBrightness,
                      )
                    : bankTheme.onSurface.withValues(alpha: 0),
                // Matches Border.all's default today; keep the token as the
                // source of truth for hairline geometry.
                // ignore: avoid_redundant_argument_values
                width: BankTokens.hairlineWidth,
              ));
    final backgroundDecoration = isGradient
        ? BoxDecoration(
            gradient: resolvedGradient,
            borderRadius: resolvedRadius,
            border: resolvedBorder,
          )
        : BoxDecoration(
            color: resolvedSurface,
            borderRadius: resolvedRadius,
            border: resolvedBorder,
          );

    // Build the card content: two groups — icon row on top, balance block
    // beneath. Content-sized by default; in tight-height contexts
    // spaceBetween pins the balance block to the bottom while the SizedBox
    // inside the block guarantees a minimum gap.
    final Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(BankTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: account type icon + masked number ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                typeIcon ?? _iconForType(account.type),
                color: secondaryTextColor,
                size: 20,
              ),
              Text(
                account.maskedNumber,
                style: BankTokens.bodySmall
                    .copyWith(color: secondaryTextColor)
                    .merge(numberStyle),
                textDirection: TextDirection.ltr, // masked number always LTR
              ),
            ],
          ),

          // ── Bottom block: balance + name/status + optional actions ────────
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: BankTokens.space5),
              BankBalanceText(
                money: account.balance,
                size: showFullBalance
                    ? BankBalanceSize.hero
                    : BankBalanceSize.large,
                style: (showFullBalance
                        ? bankTheme.numeralHero
                        : bankTheme.numeralLarge)
                    .copyWith(color: primaryTextColor)
                    .merge(amountStyle),
              ),
              const SizedBox(height: BankTokens.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      account.name,
                      style: BankTokens.labelLarge
                          .copyWith(color: primaryTextColor)
                          .merge(titleStyle),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (account.status != BankAccountStatus.active) ...[
                    const SizedBox(width: BankTokens.space2),
                    _buildStatusChip(
                      context,
                      account.status,
                      bankTheme,
                      primaryTextColor,
                      isGradient: isGradient,
                      surfaceBrightness: surfaceBrightness,
                    ),
                  ],
                ],
              ),
              if (actions != null) ...[
                const SizedBox(height: BankTokens.space3),
                actions!,
              ],
            ],
          ),
        ],
      ),
    );

    // Compose the decorated container.
    Widget card = Container(
      height: height,
      width: double.infinity,
      decoration: backgroundDecoration,
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );

    // Glow shadow (Voltage preset), the resting card shadow elsewhere, or
    // the caller's override; `const []` removes the shadow entirely.
    final resolvedShadow = shadow ??
        (bankTheme.useGlow && bankTheme.glowColor != null
            ? <BoxShadow>[
                BoxShadow(
                  color: bankTheme.glowColor!,
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ]
            : BankTokens.shadowCardFor(backgroundBrightness));
    if (resolvedShadow.isNotEmpty) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: resolvedShadow,
        ),
        child: card,
      );
    }

    // Frozen treatment: desaturate the composed card (including its glow)
    // so the state reads at a glance without obscuring any content. The
    // status chip carries the explicit label and icon.
    if (isFrozen) {
      card = ColorFiltered(
        colorFilter: _saturationFilter(BankTokens.frozenCardSaturation),
        child: card,
      );
    }

    // Semantics wrapper. Never announce the raw balance while privacy mode
    // is active; substitute the scope's masked label instead.
    final scope = BankUiScope.of(context);
    final semanticBalance = scope.privacyEnabled
        ? scope.strings.balanceHidden
        : '${account.balance.amount} ${account.balance.currencyCode}';
    final resolvedSemanticLabel = semanticLabel ??
        'Account: ${account.name}, '
            'Balance: $semanticBalance, '
            'Status: ${account.status.name}';

    // Interactive cards get the kit-wide pressed-scale / hover / focus
    // treatment; non-interactive cards keep a plain semantics wrapper.
    var interactive = onTap != null || onLongPress != null
        ? BankPressable(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: resolvedRadius,
            overlayColor: primaryTextColor,
            semanticLabel: resolvedSemanticLabel,
            child: card,
          )
        : Semantics(
            label: resolvedSemanticLabel,
            button: false,
            child: card,
          );

    // Isolate gradient repaint in Voltage.
    if (isGradient) {
      interactive = RepaintBoundary(child: interactive);
    }

    return interactive;
  }
}
