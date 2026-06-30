import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// Data for a single currency wallet tab.
class BankCurrencyWallet {
  /// ISO 4217 currency code, e.g. `'GBP'`.
  final String currencyCode;

  /// Human-readable currency name, e.g. `'British Pound'`.
  final String currencyName;

  /// Current balance held in this currency.
  final Money balance;

  /// Optional flag emoji, e.g. `'🇬🇧'`. Displayed before the currency code.
  final String? flagEmoji;

  const BankCurrencyWallet({
    required this.currencyCode,
    required this.currencyName,
    required this.balance,
    this.flagEmoji,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Horizontal scrollable tab row showing one tab per currency wallet.
///
/// Each tab displays the flag emoji (if provided), the ISO currency code, and
/// the balance formatted for the current [BankUiScope] numeral style. The
/// selected tab receives a 3 px primary-colour bottom border and a subtle
/// surface-variant background to indicate active state.
///
/// Selecting a tab automatically scrolls it into view.
class BankCurrencyWalletTabBar extends StatefulWidget {
  /// The list of currency wallets to display, one tab per wallet.
  final List<BankCurrencyWallet> wallets;

  /// Index of the currently selected tab.
  final int selectedIndex;

  /// Called when the user taps a tab, with the tapped tab's index.
  final ValueChanged<int> onSelected;

  const BankCurrencyWalletTabBar({
    super.key,
    required this.wallets,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<BankCurrencyWalletTabBar> createState() =>
      _BankCurrencyWalletTabBarState();
}

class _BankCurrencyWalletTabBarState extends State<BankCurrencyWalletTabBar> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
  }

  @override
  void didUpdateWidget(BankCurrencyWalletTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallets.length != widget.wallets.length) {
      _rebuildKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _rebuildKeys() {
    _tabKeys
      ..clear()
      ..addAll(List.generate(widget.wallets.length, (_) => GlobalKey()));
  }

  void _scrollToSelected() {
    final index = widget.selectedIndex;
    if (index < 0 || index >= _tabKeys.length) return;
    final key = _tabKeys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: BankTokens.durationBase,
        curve: BankTokens.curveStandard,
        alignment: 0.5,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        itemCount: widget.wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: BankTokens.space2),
        itemBuilder: (context, index) {
          final wallet = widget.wallets[index];
          final isSelected = index == widget.selectedIndex;

          final formattedBalance = BankMoneyFormatter.format(
            amount: wallet.balance.amount,
            currencyCode: wallet.balance.currencyCode,
            numeralStyle: scope.numeralStyle,
            compact: true,
          );

          final label = [
            if (wallet.flagEmoji != null) wallet.flagEmoji!,
            wallet.currencyCode,
          ].join(' ');

          return Semantics(
            label: '${wallet.currencyName}, balance $formattedBalance',
            selected: isSelected,
            button: true,
            excludeSemantics: true,
            child: _WalletTab(
              tabKey: _tabKeys[index],
              wallet: wallet,
              isSelected: isSelected,
              formattedBalance: formattedBalance,
              label: label,
              bankTheme: bankTheme,
              onTap: () {
                widget.onSelected(index);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToSelected(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private tab cell
// ---------------------------------------------------------------------------

class _WalletTab extends StatelessWidget {
  const _WalletTab({
    required this.tabKey,
    required this.wallet,
    required this.isSelected,
    required this.formattedBalance,
    required this.label,
    required this.bankTheme,
    required this.onTap,
  });

  final GlobalKey tabKey;
  final BankCurrencyWallet wallet;
  final bool isSelected;
  final String formattedBalance;
  final String label;
  final BankThemeData bankTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tabKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
        child: AnimatedContainer(
          duration: BankTokens.durationFast,
          curve: BankTokens.curveStandard,
          constraints: const BoxConstraints(minWidth: BankTokens.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space3,
            vertical: BankTokens.space2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? bankTheme.surfaceVariant
                : Colors.transparent,
            borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? bankTheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: BankTokens.labelMedium.copyWith(
                  color: isSelected
                      ? bankTheme.primary
                      : bankTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formattedBalance,
                style: bankTheme.numeralSmall.copyWith(
                  color: isSelected
                      ? bankTheme.onSurface
                      : bankTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
