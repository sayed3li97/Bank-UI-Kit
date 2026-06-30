import 'package:flutter/widgets.dart';

import '../theme/extensions.dart';
import '../theme/numeral_style.dart';
import 'bank_ui_strings.dart';

/// Immutable snapshot of the runtime configuration for the Bank UI Kit.
///
/// An instance lives inside [BankUiScope] and is propagated through the
/// widget tree via [_BankUiScopeInherited]. Widgets read it with
/// [BankUiScope.of].
@immutable
class BankUiScopeData {
  final bool privacyEnabled;
  final BankPreset preset;
  final BankUiStrings strings;
  final NumeralStyle numeralStyle;

  /// When `true`, labels such as APR are replaced with Islamic-finance
  /// equivalents (e.g. "Profit Rate") sourced from [strings].
  final bool islamicFinanceMode;

  const BankUiScopeData({
    this.privacyEnabled = false,
    this.preset = BankPreset.studio,
    this.strings = BankUiStrings.defaults,
    this.numeralStyle = NumeralStyle.western,
    this.islamicFinanceMode = false,
  });

  BankUiScopeData copyWith({
    bool? privacyEnabled,
    BankPreset? preset,
    BankUiStrings? strings,
    NumeralStyle? numeralStyle,
    bool? islamicFinanceMode,
  }) =>
      BankUiScopeData(
        privacyEnabled: privacyEnabled ?? this.privacyEnabled,
        preset: preset ?? this.preset,
        strings: strings ?? this.strings,
        numeralStyle: numeralStyle ?? this.numeralStyle,
        islamicFinanceMode: islamicFinanceMode ?? this.islamicFinanceMode,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankUiScopeData &&
        other.privacyEnabled == privacyEnabled &&
        other.preset == preset &&
        other.strings == strings &&
        other.numeralStyle == numeralStyle &&
        other.islamicFinanceMode == islamicFinanceMode;
  }

  @override
  int get hashCode => Object.hash(
        privacyEnabled,
        preset,
        strings,
        numeralStyle,
        islamicFinanceMode,
      );
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Provides Bank UI Kit configuration to the subtree.
///
/// Wrap the application (or the portion that uses Bank UI Kit widgets) with
/// this widget so every descendant can read [BankUiScopeData] and call
/// mutation methods via [BankUiScope.controllerOf].
///
/// ```dart
/// BankUiScope(
///   initialData: BankUiScopeData(
///     preset: BankPreset.voltage,
///     islamicFinanceMode: true,
///   ),
///   child: MyApp(),
/// )
/// ```
class BankUiScope extends StatefulWidget {
  final BankUiScopeData initialData;
  final Widget child;

  const BankUiScope({
    super.key,
    this.initialData = const BankUiScopeData(),
    required this.child,
  });

  // ---------------------------------------------------------------------------
  // Static accessors
  // ---------------------------------------------------------------------------

  /// Returns the nearest [BankUiScopeData] from the widget tree.
  ///
  /// Descendants are rebuilt whenever the data changes.
  ///
  /// Throws a [FlutterError] if no [BankUiScope] ancestor is found.
  static BankUiScopeData of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_BankUiScopeInherited>();
    assert(
      inherited != null,
      'BankUiScope.of() called with a context that does not contain a '
      'BankUiScope widget. Make sure BankUiScope is an ancestor of the '
      'widget that calls BankUiScope.of().',
    );
    return inherited!.data;
  }

  /// Returns the [_BankUiScopeController] that allows callers to mutate the
  /// scope data without a full rebuild of the [BankUiScope] itself.
  ///
  /// Throws a [FlutterError] if no [BankUiScope] ancestor is found.
  static _BankUiScopeController controllerOf(BuildContext context) {
    final inherited =
        context.getInheritedWidgetOfExactType<_BankUiScopeInherited>();
    assert(
      inherited != null,
      'BankUiScope.controllerOf() called with a context that does not contain '
      'a BankUiScope widget. Make sure BankUiScope is an ancestor of the '
      'widget that calls BankUiScope.controllerOf().',
    );
    return inherited!.controller;
  }

  @override
  State<BankUiScope> createState() => _BankUiScopeState();
}

// ---------------------------------------------------------------------------
// Controller (exposed to descendants via _BankUiScopeInherited)
// ---------------------------------------------------------------------------

/// Provides mutation methods for [BankUiScopeData].
///
/// Obtain an instance with [BankUiScope.controllerOf]. The controller holds a
/// direct reference to [_BankUiScopeState] and triggers rebuilds via
/// [setState] so only [_BankUiScopeInherited] and its dependents rebuild.
class _BankUiScopeController {
  _BankUiScopeController(this._state);

  final _BankUiScopeState _state;

  /// Flips [BankUiScopeData.privacyEnabled].
  void togglePrivacy() => _state._updateData(
        _state._data.copyWith(
          privacyEnabled: !_state._data.privacyEnabled,
        ),
      );

  /// Sets [BankUiScopeData.privacyEnabled] to [enabled].
  void setPrivacy(bool enabled) =>
      _state._updateData(_state._data.copyWith(privacyEnabled: enabled));

  /// Switches the active [BankPreset].
  void setPreset(BankPreset preset) =>
      _state._updateData(_state._data.copyWith(preset: preset));

  /// Switches the active [NumeralStyle].
  void setNumeralStyle(NumeralStyle style) =>
      _state._updateData(_state._data.copyWith(numeralStyle: style));

  /// Enables or disables Islamic finance mode (swaps APR labels for
  /// profit-rate labels throughout the kit).
  void setIslamicFinanceMode(bool enabled) =>
      _state._updateData(_state._data.copyWith(islamicFinanceMode: enabled));
}

// ---------------------------------------------------------------------------
// InheritedWidget
// ---------------------------------------------------------------------------

class _BankUiScopeInherited extends InheritedWidget {
  final BankUiScopeData data;
  final _BankUiScopeController controller;

  const _BankUiScopeInherited({
    required this.data,
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_BankUiScopeInherited old) => data != old.data;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _BankUiScopeState extends State<BankUiScope> {
  late BankUiScopeData _data;
  late _BankUiScopeController _controller;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _controller = _BankUiScopeController(this);
  }

  @override
  void didUpdateWidget(BankUiScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _data = widget.initialData;
    }
  }

  void _updateData(BankUiScopeData next) {
    if (next == _data) return;
    setState(() => _data = next);
  }

  @override
  Widget build(BuildContext context) => _BankUiScopeInherited(
        data: _data,
        controller: _controller,
        child: widget.child,
      );
}
