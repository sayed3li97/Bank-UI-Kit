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

  const BankAccountCard({
    required this.account,
    super.key,
    this.onTap,
    this.onLongPress,
    this.itemBuilder,
    this.showFullBalance = true,
    this.actions,
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
          'Closed',
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
    final isGradient = bankTheme.accentGradient != null;
    final isFrozen = account.status == BankAccountStatus.frozen;

    // Determine text colours based on surface treatment.
    final primaryTextColor =
        isGradient ? const Color(0xFFFFFFFF) : bankTheme.onSurface;
    final secondaryTextColor = isGradient
        ? const Color(0xCCFFFFFF) // 80% white
        : bankTheme.onSurfaceVariant;

    // Compose background decoration.
    final backgroundDecoration = isGradient
        ? BoxDecoration(
            gradient: bankTheme.accentGradient,
            borderRadius: bankTheme.cardRadius,
          )
        : BoxDecoration(
            color: bankTheme.surface,
            borderRadius: bankTheme.cardRadius,
          );

    // Build the card content.
    Widget cardContent = Padding(
      padding: const EdgeInsets.all(BankTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: account type icon + masked number ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _iconForType(account.type),
                color: secondaryTextColor,
                size: 20,
              ),
              Text(
                account.maskedNumber,
                style: BankTokens.bodySmall.copyWith(color: secondaryTextColor),
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
                .copyWith(color: primaryTextColor),
          ),

          const SizedBox(height: BankTokens.space2),

          // ── Bottom row: account name + status chip ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style:
                      BankTokens.labelLarge.copyWith(color: primaryTextColor),
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
                borderRadius: bankTheme.cardRadius,
              ),
              child: const Center(
                child: Icon(
                  Icons.ac_unit_outlined,
                  color: Colors.white,
                  size: 40,
                  semanticLabel: 'Account frozen',
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Compose the decorated container.
    Widget card = Container(
      height: 200,
      width: double.infinity,
      decoration: backgroundDecoration,
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );

    // Glow shadow (Voltage preset).
    if (bankTheme.useGlow && bankTheme.glowColor != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: bankTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: bankTheme.glowColor!,
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
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
    final semanticLabel = 'Account: ${account.name}, '
        'Balance: $semanticBalance, '
        'Status: ${account.status.name}';

    Widget interactive = Semantics(
      label: semanticLabel,
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
