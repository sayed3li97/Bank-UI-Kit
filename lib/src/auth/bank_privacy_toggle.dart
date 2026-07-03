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

  const BankPrivacyToggle({
    super.key,
    this.overrideValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scopeData = BankUiScope.of(context);
    final bankTheme = BankThemeData.of(context);

    final privacyEnabled = overrideValue ?? scopeData.privacyEnabled;

    final semanticLabel = privacyEnabled ? 'Show balances' : 'Hide balances';

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
            duration: BankTokens.durationFast,
            switchInCurve: BankTokens.curveStandard,
            switchOutCurve: BankTokens.curveStandard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Icon(
              privacyEnabled ? BankIcons.visibilityOff : BankIcons.visibility,
              key: ValueKey<bool>(privacyEnabled),
              color: bankTheme.onSurface,
              size: 24,
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
