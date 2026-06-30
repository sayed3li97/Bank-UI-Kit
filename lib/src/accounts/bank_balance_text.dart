import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// The visual size tier for [BankBalanceText].
///
/// Each tier maps to a different [TextStyle] from [BankTokens]:
/// - [hero] → `BankTokens.numeralHero` (48 sp, bold)
/// - [large] → `BankTokens.numeralLarge` (24 sp, semi-bold)
/// - [medium] → `BankTokens.numeralMedium` (18 sp, medium)
/// - [small] → `BankTokens.numeralSmall` (14 sp, medium)
enum BankBalanceSize { hero, large, medium, small }

/// Currency-formatted text that automatically masks when privacy mode is
/// active.
///
/// Privacy state is read from the nearest [BankUiScope]. When
/// [BankUiScopeData.privacyEnabled] is `true`, the balance is replaced by
/// [BankUiStrings.balanceHidden] (default: `'••••'`). The transition between
/// hidden and visible states is animated with a 150 ms cross-fade.
///
/// ```dart
/// BankBalanceText(
///   money: account.balance,
///   size: BankBalanceSize.hero,
///   showSign: true,
/// )
/// ```
class BankBalanceText extends StatelessWidget {
  /// The monetary value to display.
  final Money money;

  /// Override for the text style. When `null`, a style is derived from [size]
  /// and [BankThemeData.onSurface] colour.
  final TextStyle? style;

  /// Controls which numeral-typography scale is used.
  final BankBalanceSize size;

  /// When `true` a leading `+` is prepended to positive amounts.
  final bool showSign;

  /// When `true`, uses compact notation (e.g. `£1.2K` instead of `£1,200.00`).
  final bool compact;

  const BankBalanceText({
    super.key,
    required this.money,
    this.style,
    this.size = BankBalanceSize.large,
    this.showSign = false,
    this.compact = false,
  });

  TextStyle _baseStyleForSize(BankThemeData bankTheme) {
    final TextStyle sizeStyle = switch (size) {
      BankBalanceSize.hero => bankTheme.numeralHero,
      BankBalanceSize.large => bankTheme.numeralLarge,
      BankBalanceSize.medium => bankTheme.numeralMedium,
      BankBalanceSize.small => bankTheme.numeralSmall,
    };
    return sizeStyle.copyWith(color: bankTheme.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final BankUiScopeData data = BankUiScope.of(context);
    final BankThemeData bankTheme = BankThemeData.of(context);
    final TextStyle resolvedStyle = style ?? _baseStyleForSize(bankTheme);

    final bool hidden = data.privacyEnabled;

    final String formattedBalance = BankMoneyFormatter.format(
      amount: money.amount,
      currencyCode: money.currencyCode,
      numeralStyle: data.numeralStyle,
      showSign: showSign,
      compact: compact,
    );

    final String displayText = hidden ? data.strings.balanceHidden : formattedBalance;
    final String semanticLabel = hidden
        ? 'Balance hidden'
        : 'Balance: $formattedBalance';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: BankTokens.durationFast,
        switchInCurve: BankTokens.curveStandard,
        switchOutCurve: BankTokens.curveStandard,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Text(
          displayText,
          key: ValueKey<bool>(hidden),
          style: resolvedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
