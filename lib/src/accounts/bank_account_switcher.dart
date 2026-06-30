import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Bottom-sheet or inline widget for selecting among multiple bank accounts.
///
/// Typically presented as a modal bottom sheet via [BankAccountSwitcher.show]:
///
/// ```dart
/// final selected = await BankAccountSwitcher.show(
///   context,
///   accounts: myAccounts,
///   selectedAccountId: currentAccount.id,
/// );
/// if (selected != null) { /* switch to selected */ }
/// ```
///
/// When embedded inline (e.g. inside an existing sheet), construct the widget
/// directly and provide an [onSelected] callback.
///
/// Each row is 72 px tall and follows the 44×44 minimum tap-target rule.
/// A drag handle is rendered at the top of the sheet for discoverability.
/// Privacy mode is respected: balances are masked when
/// [BankUiScopeData.privacyEnabled] is `true`.
class BankAccountSwitcher extends StatelessWidget {
  /// The list of accounts to display.
  final List<BankAccount> accounts;

  /// The ID of the currently active account. Its row receives a trailing
  /// checkmark.
  final String? selectedAccountId;

  /// Called when the user taps a row. In the bottom-sheet flow this callback
  /// is wired to `Navigator.of(context).pop(account)` by [show].
  final ValueChanged<BankAccount> onSelected;

  /// Optional full override for each row. When non-null, this builder is
  /// called instead of the default [_AccountRow] for every list item.
  final Widget Function(BuildContext, BankAccount, bool isSelected)?
      itemBuilder;

  const BankAccountSwitcher({
    required this.accounts,
    required this.onSelected,
    super.key,
    this.selectedAccountId,
    this.itemBuilder,
  });

  // ---------------------------------------------------------------------------
  // Static helper — modal presentation
  // ---------------------------------------------------------------------------

  /// Presents [BankAccountSwitcher] as a transparent-background modal bottom
  /// sheet and returns the account the user tapped, or `null` if dismissed.
  static Future<BankAccount?> show(
    BuildContext context, {
    required List<BankAccount> accounts,
    String? selectedAccountId,
  }) =>
      showModalBottomSheet<BankAccount>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BankAccountSwitcher(
          accounts: accounts,
          selectedAccountId: selectedAccountId,
          onSelected: (account) => Navigator.of(context).pop(account),
        ),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    // Calculate an intrinsic max height: sheet fills up to 70 % of the screen.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.70;

    // The drag-handle bar at the top of the sheet.
    final Widget handleBar = Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: BankTokens.space3),
        decoration: BoxDecoration(
          color: bankTheme.outline,
          borderRadius:
              const BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
        ),
      ),
    );

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: bankTheme.sheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          handleBar,

          // Account list
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.paddingOf(context).bottom + BankTokens.space4,
              ),
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (BuildContext ctx, int index) {
                final account = accounts[index];
                final isSelected = account.id == selectedAccountId;

                if (itemBuilder != null) {
                  return itemBuilder!(ctx, account, isSelected);
                }

                return _AccountRow(
                  account: account,
                  isSelected: isSelected,
                  onTap: () => onSelected(account),
                  bankTheme: bankTheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal row widget
// ---------------------------------------------------------------------------

/// A single account row inside [BankAccountSwitcher].
///
/// Height: at least 72 px (satisfies the 44×44 minimum tap-target rule with
/// comfortable padding). An [InkWell] provides the ripple feedback.
class _AccountRow extends StatelessWidget {
  final BankAccount account;
  final bool isSelected;
  final VoidCallback onTap;
  final BankThemeData bankTheme;

  const _AccountRow({
    required this.account,
    required this.isSelected,
    required this.onTap,
    required this.bankTheme,
  });

  IconData _iconForType(BankAccountType type) => switch (type) {
        BankAccountType.savings => BankIcons.accountSavings,
        BankAccountType.joint => BankIcons.accountJoint,
        BankAccountType.business => BankIcons.accountBusiness,
        BankAccountType.crypto => BankIcons.accountCrypto,
        BankAccountType.current || BankAccountType.isa => BankIcons.account,
      };

  @override
  Widget build(BuildContext context) {
    final scopeData = BankUiScope.of(context);
    final privacyEnabled = scopeData.privacyEnabled;

    final balanceText = privacyEnabled
        ? scopeData.strings.balanceHidden
        : BankMoneyFormatter.format(
            amount: account.balance.amount,
            currencyCode: account.balance.currencyCode,
            numeralStyle: scopeData.numeralStyle,
          );

    final semanticLabel = 'Account: ${account.name}, '
        '${account.maskedNumber}, '
        '${privacyEnabled ? "Balance hidden" : "Balance: $balanceText"}'
        '${isSelected ? ", selected" : ""}';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        splashColor: bankTheme.primary.withValues(alpha: 0.08),
        highlightColor: bankTheme.primary.withValues(alpha: 0.04),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 72,
            minWidth: double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            child: Row(
              children: [
                // Leading: account type icon in a tinted circle.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bankTheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForType(account.type),
                    color: bankTheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),

                const SizedBox(width: BankTokens.space3),

                // Centre: account name + masked number.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: BankTokens.labelLarge.copyWith(
                          color: bankTheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.maskedNumber,
                        style: BankTokens.bodySmall.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                        // Masked numbers are always LTR regardless of locale.
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: BankTokens.space3),

                // Trailing: balance + optional checkmark.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balanceText,
                      style: BankTokens.numeralSmall.copyWith(
                        color: bankTheme.onSurface,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.check_circle,
                        color: bankTheme.primary,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
