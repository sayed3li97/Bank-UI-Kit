import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

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

  /// Overrides the hidden/visible cross-fade duration. Defaults to
  /// [BankTokens.durationFast].
  final Duration? animationDuration;

  /// Overrides the hidden/visible cross-fade curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  /// Overrides the computed accessibility label (`'Balance: X'`, or
  /// `'Balance hidden'` while privacy mode is active).
  final String? semanticLabel;

  const BankBalanceText({
    required this.money,
    super.key,
    this.style,
    this.size = BankBalanceSize.large,
    this.showSign = false,
    this.compact = false,
    this.animationDuration,
    this.animationCurve,
    this.semanticLabel,
  });

  TextStyle _baseStyleForSize(BankThemeData bankTheme) {
    final sizeStyle = switch (size) {
      BankBalanceSize.hero => bankTheme.numeralHero,
      BankBalanceSize.large => bankTheme.numeralLarge,
      BankBalanceSize.medium => bankTheme.numeralMedium,
      BankBalanceSize.small => bankTheme.numeralSmall,
    };
    return sizeStyle.copyWith(color: bankTheme.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final data = BankUiScope.of(context);
    final bankTheme = BankThemeData.of(context);
    final resolvedStyle = style ?? _baseStyleForSize(bankTheme);

    final hidden = data.privacyEnabled;

    final formattedBalance = BankMoneyFormatter.format(
      amount: money.amount,
      currencyCode: money.currencyCode,
      numeralStyle: data.numeralStyle,
      locale: context.bankLocale,
      showSign: showSign,
      compact: compact,
    );

    final displayText = hidden ? data.strings.balanceHidden : formattedBalance;
    final resolvedSemanticLabel = semanticLabel ??
        (hidden ? 'Balance hidden' : 'Balance: $formattedBalance');

    return Semantics(
      label: resolvedSemanticLabel,
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: animationDuration ?? BankTokens.durationFast,
        switchInCurve: animationCurve ?? BankTokens.curveStandard,
        switchOutCurve: animationCurve ?? BankTokens.curveStandard,
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
