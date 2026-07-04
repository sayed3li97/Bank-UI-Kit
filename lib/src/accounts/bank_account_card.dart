import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';
import 'bank_balance_text.dart';

/// Swipeable card that visually represents a single bank account.
///
/// Renders the account balance, type icon, masked account number, account name,
/// and: when the account is not active: a status chip. Frozen accounts
/// additionally show a semi-transparent overlay with a snowflake icon to make
/// the state unmistakably clear.
///
/// **Theme surface treatments:**
/// - *Voltage*: `BankThemeData.accentGradient` is non-null → violet/cyan
///   gradient background, white text. Wrapped in [RepaintBoundary] to
///   isolate gradient repaints.
/// - *Studio / Bloom*: flat `BankThemeData.surface` background with
///   `BankThemeData.onSurface` text.
///
/// When [BankThemeData.useGlow] is `true`, a coloured box-shadow glow is
/// rendered beneath the card using [BankThemeData.glowColor].
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

  /// Overrides the glow shadow. Defaults to the theme glow when
  /// `useGlow` is on; pass `const []` to remove it.
  final List<BoxShadow>? shadow;

  /// Merged over the account-name style ([BankTokens.labelLarge]).
  final TextStyle? titleStyle;

  /// Merged over the balance style (theme `numeralHero`/`numeralLarge`).
  final TextStyle? amountStyle;

  /// Merged over the masked-number style ([BankTokens.bodySmall]).
  final TextStyle? numberStyle;

  /// Overrides the account-type icon derived from [BankAccount.type].
  final IconData? typeIcon;

  /// Overrides the frozen-overlay icon. Defaults to
  /// [Icons.ac_unit_outlined].
  final IconData? frozenIcon;

  /// Status chip label for closed accounts. Defaults to `'Closed'`.
  final String closedLabel;

  /// Accessibility label of the frozen-overlay icon. Defaults to
  /// `'Account frozen'`.
  final String frozenSemanticLabel;

  /// Overrides the computed accessibility label of the whole card.
  final String? semanticLabel;

  /// Overrides the fixed card height. Defaults to 200.
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

  /// Builds the small status chip shown when the account is not active.
  Widget _buildStatusChip(
    BuildContext context,
    BankAccountStatus status,
    BankThemeData bankTheme,
    Color textColor,
  ) {
    final data = BankUiScope.of(context);

    final (Color chipBackground, String label) = switch (status) {
      BankAccountStatus.frozen => (
          const Color(0xFFB3E5FC), // ice-blue
          data.strings.frozen,
        ),
      BankAccountStatus.restricted => (
          const Color(0xFFFFE082), // amber
          data.strings.restricted,
        ),
      BankAccountStatus.pending => (
          const Color(0xFFFFF9C4), // pale yellow
          data.strings.pending,
        ),
      BankAccountStatus.closed => (
          const Color(0xFFEEEEEE), // neutral grey
          closedLabel,
        ),
      BankAccountStatus.active => (Colors.transparent, ''),
    };

    if (status == BankAccountStatus.active) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: BankTokens.space1,
      ),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: bankTheme.chipRadius,
      ),
      child: Text(
        label,
        style: BankTokens.labelSmall.copyWith(color: const Color(0xFF333333)),
      ),
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

    // Determine text colours based on surface treatment.
    final primaryTextColor = foregroundColor ??
        (isGradient ? const Color(0xFFFFFFFF) : bankTheme.onSurface);
    final secondaryTextColor = secondaryColor ??
        (isGradient
            ? const Color(0xCCFFFFFF) // 80% white
            : bankTheme.onSurfaceVariant);

    // Compose background decoration.
    final backgroundDecoration = isGradient
        ? BoxDecoration(
            gradient: resolvedGradient,
            borderRadius: resolvedRadius,
          )
        : BoxDecoration(
            color: backgroundColor ?? bankTheme.surface,
            borderRadius: resolvedRadius,
          );

    // Build the card content.
    Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(BankTokens.space4),
      child: Column(
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

          const Spacer(),

          // ── Middle: balance ───────────────────────────────────────────────
          BankBalanceText(
            money: account.balance,
            size:
                showFullBalance ? BankBalanceSize.hero : BankBalanceSize.large,
            style: (showFullBalance
                    ? bankTheme.numeralHero
                    : bankTheme.numeralLarge)
                .copyWith(color: primaryTextColor)
                .merge(amountStyle),
          ),

          const SizedBox(height: BankTokens.space2),

          // ── Bottom row: account name + status chip ────────────────────────
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
                ),
              ],
            ],
          ),

          // ── Optional action row ───────────────────────────────────────────
          if (actions != null) ...[
            const SizedBox(height: BankTokens.space3),
            actions!,
          ],
        ],
      ),
    );

    // Frozen overlay: semi-transparent blue-grey wash + snowflake icon.
    if (isFrozen) {
      cardContent = Stack(
        children: [
          cardContent,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.30),
                borderRadius: resolvedRadius,
              ),
              child: Center(
                child: Icon(
                  frozenIcon ?? Icons.ac_unit_outlined,
                  color: Colors.white,
                  size: 40,
                  semanticLabel: frozenSemanticLabel,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Compose the decorated container.
    Widget card = Container(
      height: height ?? 200,
      width: double.infinity,
      decoration: backgroundDecoration,
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );

    // Glow shadow (Voltage preset), or the caller's override.
    final resolvedShadow = shadow ??
        (bankTheme.useGlow && bankTheme.glowColor != null
            ? <BoxShadow>[
                BoxShadow(
                  color: bankTheme.glowColor!,
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ]
            : null);
    if (resolvedShadow != null && resolvedShadow.isNotEmpty) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: resolvedShadow,
        ),
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

    Widget interactive = Semantics(
      label: resolvedSemanticLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );

    // Isolate gradient repaint in Voltage.
    if (isGradient) {
      interactive = RepaintBoundary(child: interactive);
    }

    return interactive;
  }
}
