import 'package:flutter/material.dart';

import '../../bank_ui_kit.dart';
import '../../core.dart';

// ---------------------------------------------------------------------------
// BankPrivacyToggle
// ---------------------------------------------------------------------------

/// A tappable icon button that toggles the ambient [BankUiScope] privacy state.
///
/// When privacy is on, [BankBalanceText] widgets throughout the tree mask their
/// values with the placeholder string from [BankUiStrings.balanceHidden].
///
/// **Uncontrolled mode** (default): reads [BankUiScopeData.privacyEnabled] from
/// the nearest [BankUiScope] and calls
/// `BankUiScope.controllerOf(context).togglePrivacy()` on tap. The host app
/// does not need to manage state.
///
/// **Controlled mode**: when [overrideValue] is non-null, the widget uses that
/// value for its display and calls [onChanged] on tap. The [BankUiScope] is
/// still read for the icon colour but its internal state is not mutated.
///
/// ```dart
/// // Uncontrolled: inside a BankUiScope subtree
/// const BankPrivacyToggle()
///
/// // Controlled
/// BankPrivacyToggle(
///   overrideValue: _hideBalances,
///   onChanged: (v) => setState(() => _hideBalances = v),
/// )
/// ```
class BankPrivacyToggle extends StatelessWidget {
  /// When non-null, the widget operates in controlled mode and this value
  /// determines which icon is displayed.
  final bool? overrideValue;

  /// Called in controlled mode when the button is tapped. Receives the new
  /// desired privacy state (`true` = private / hide balances).
  final ValueChanged<bool>? onChanged;

  /// Color of the eye icon. Defaults to the theme `onSurface` when null.
  final Color? foregroundColor;

  /// Size, in logical pixels, of the eye icon. Defaults to 24 when null.
  final double? iconSize;

  /// Glyph shown when privacy is enabled (balances hidden). Defaults to
  /// [BankIcons.visibilityOff] when null.
  final IconData? hiddenIcon;

  /// Glyph shown when privacy is disabled (balances visible). Defaults to
  /// [BankIcons.visibility] when null.
  final IconData? visibleIcon;

  /// Accessibility / tooltip label used when the action reveals balances
  /// (privacy currently enabled). Defaults to `'Show balances'` when null.
  final String? showBalancesLabel;

  /// Accessibility / tooltip label used when the action hides balances
  /// (privacy currently disabled). Defaults to `'Hide balances'` when null.
  final String? hideBalancesLabel;

  /// Duration of the icon cross-fade. Defaults to [BankTokens.durationFast]
  /// when null.
  final Duration? animationDuration;

  /// Curve of the icon cross-fade. Defaults to [BankTokens.curveStandard]
  /// when null.
  final Curve? animationCurve;

  const BankPrivacyToggle({
    super.key,
    this.overrideValue,
    this.onChanged,
    this.foregroundColor,
    this.iconSize,
    this.hiddenIcon,
    this.visibleIcon,
    this.showBalancesLabel,
    this.hideBalancesLabel,
    this.animationDuration,
    this.animationCurve,
  });

  @override
  Widget build(BuildContext context) {
    final scopeData = BankUiScope.of(context);
    final bankTheme = BankThemeData.of(context);

    final privacyEnabled = overrideValue ?? scopeData.privacyEnabled;

    final semanticLabel = privacyEnabled
        ? (showBalancesLabel ?? 'Show balances')
        : (hideBalancesLabel ?? 'Hide balances');

    final resolvedIcon = privacyEnabled
        ? (hiddenIcon ?? BankIcons.visibilityOff)
        : (visibleIcon ?? BankIcons.visibility);

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: BankTokens.minTapTarget,
        height: BankTokens.minTapTarget,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: BankTokens.minTapTarget,
            minHeight: BankTokens.minTapTarget,
          ),
          tooltip: semanticLabel,
          onPressed: () => _handleTap(context, privacyEnabled),
          icon: AnimatedSwitcher(
            duration: animationDuration ?? BankTokens.durationFast,
            switchInCurve: animationCurve ?? BankTokens.curveStandard,
            switchOutCurve: animationCurve ?? BankTokens.curveStandard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Icon(
              resolvedIcon,
              key: ValueKey<bool>(privacyEnabled),
              color: foregroundColor ?? bankTheme.onSurface,
              size: iconSize ?? 24,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, bool currentPrivacy) {
    if (overrideValue != null) {
      onChanged?.call(!currentPrivacy);
    } else {
      BankUiScope.controllerOf(context).togglePrivacy();
    }
  }
}
