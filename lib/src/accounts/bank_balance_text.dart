import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

/// The visual size tier for [BankBalanceText].
///
/// Each tier maps to a different [TextStyle] from [BankTokens]:
/// - [hero] → `BankTokens.numeralHero` (44 sp, semi-bold)
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
/// When the amount itself changes (same currency), the digits count up or
/// down to the new value; see [animateChanges]. Long amounts scale down to
/// fit the available width instead of truncating; see [fitToWidth].
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

  /// Merged over the size-derived numeral style.
  ///
  /// Fields left `null` inherit from the numeral tier ([size]) — including
  /// its tabular/lining font features, so partial overrides (e.g. a colour
  /// change) keep digits column-aligned. To replace the base style entirely,
  /// pass a [TextStyle] with `inherit: false`.
  final TextStyle? style;

  /// Controls which numeral-typography scale is used.
  final BankBalanceSize size;

  /// When `true` a leading `+` is prepended to positive amounts.
  final bool showSign;

  /// When `true`, uses compact notation (e.g. `£1.2K` instead of `£1,200.00`).
  final bool compact;

  /// When `true` (the default), the rendered amount scales down — never up —
  /// to fit the available width instead of truncating digits to an ellipsis.
  ///
  /// Set to `false` to opt out and render a plain single-line [Text] that
  /// ellipsizes on overflow (the pre-fit behaviour).
  final bool fitToWidth;

  /// When `true` (the default), a change to [money]'s amount within the same
  /// currency animates old → new with a count-up/count-down over
  /// [BankTokens.durationBase] using [BankTokens.curveEmphasized], formatting
  /// every frame through the regular formatter path.
  ///
  /// The animation is skipped on first build, while privacy mode is masking
  /// the value, when the currency changes, and when the platform requests
  /// reduced motion ([MediaQueryData.disableAnimations]).
  final bool animateChanges;

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
    this.fitToWidth = true,
    this.animateChanges = true,
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
    // Merge (not replace) so partial caller styles keep the numeral base —
    // tabular figures, tier size/weight — unless explicitly overridden.
    final resolvedStyle = _baseStyleForSize(bankTheme).merge(style);

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

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animate = animateChanges && !hidden && !reduceMotion;

    final Widget amount = animate
        ? _AnimatedAmount(
            money: money,
            formattedTarget: formattedBalance,
            style: resolvedStyle,
            numeralStyle: data.numeralStyle,
            locale: context.bankLocale,
            showSign: showSign,
            compact: compact,
          )
        : Text(
            displayText,
            style: resolvedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    // AnimatedSwitcher keys its direct child, so the privacy key lives on the
    // FittedBox (or a KeyedSubtree when fitting is disabled).
    final switcherChild = fitToWidth
        ? FittedBox(
            key: ValueKey<bool>(hidden),
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: amount,
          )
        : KeyedSubtree(
            key: ValueKey<bool>(hidden),
            child: amount,
          );

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
        // Keep the '••••' ↔ amount cross-fade start-aligned in both LTR and
        // RTL (the default layout builder centres, which drifts the shorter
        // mask). AlignmentDirectional resolves via the ambient Directionality.
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: AlignmentDirectional.centerStart,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: switcherChild,
      ),
    );
  }
}

/// Renders the visible amount, counting up/down whenever the target value
/// changes within the same currency.
///
/// Uses [TweenAnimationBuilder] retargeting: on first build `begin == end`,
/// so nothing animates; a later change to [money] animates from the current
/// frame value to the new amount. Keyed by currency so cross-currency
/// changes snap instead of tweening through meaningless values.
class _AnimatedAmount extends StatelessWidget {
  const _AnimatedAmount({
    required this.money,
    required this.formattedTarget,
    required this.style,
    required this.numeralStyle,
    required this.locale,
    required this.showSign,
    required this.compact,
  });

  final Money money;
  final String formattedTarget;
  final TextStyle style;
  final NumeralStyle numeralStyle;
  final String? locale;
  final bool showSign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final target = money.amount.toDouble();
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(money.currencyCode),
      tween: Tween<double>(end: target),
      duration: BankTokens.durationBase,
      curve: BankTokens.curveEmphasized,
      builder: (BuildContext context, double value, Widget? _) {
        return Text(
          _formatFrame(value, target),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  String _formatFrame(double value, double target) {
    // At rest, render the precise Decimal-formatted amount so no double
    // round-trip error can leak into the settled display. Also bail out for
    // values outside the safely fixed-formattable double range.
    if (value == target || !value.isFinite || value.abs() >= 1e15) {
      return formattedTarget;
    }
    return BankMoneyFormatter.format(
      amount: Decimal.parse(value.toStringAsFixed(6)),
      currencyCode: money.currencyCode,
      numeralStyle: numeralStyle,
      locale: locale,
      showSign: showSign,
      compact: compact,
    );
  }
}
