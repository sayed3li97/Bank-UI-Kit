import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The kit-wide interaction-state wrapper: hover, press, keyboard focus,
/// and disabled treatment for any tappable surface.
///
/// Wrap any card, tile, or custom surface to give it the full premium
/// interaction grammar without a [Material] ancestor:
///
/// - a state layer ([BankThemeData.onSurface] by default, or [overlayColor])
///   at the theme's hover / pressed opacities, clipped to [borderRadius];
/// - a gentle scale-down to [BankThemeData.pressScale] while pressed
///   ([BankTokens.durationFast] / [BankTokens.curveEmphasized]);
/// - keyboard activation (Enter / Space) with a focus ring drawn *outside*
///   the child bounds in [BankThemeData.primary] at
///   [BankTokens.focusRingOpacity];
/// - [Semantics] as an (enabled/disabled) button, and
///   [BankTokens.disabledOpacity] dimming when disabled.
///
/// With no [onTap] / [onLongPress] handlers the child is returned untouched
/// (plus [Semantics] when [semanticLabel] is given), so the wrapper is safe
/// on conditionally interactive tiles.
///
/// All geometry is symmetric, so the widget is RTL-safe by construction.
///
/// ```dart
/// BankPressable(
///   onTap: () => openAccount(account),
///   borderRadius: theme.cardRadius,
///   semanticLabel: 'Checking account, balance \$1,240',
///   child: const _AccountCardFace(),
/// )
/// ```
class BankPressable extends StatefulWidget {
  const BankPressable({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.overlayColor,
    this.enabled = true,
    this.pressScale,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// Called on tap or keyboard activation (Enter / Space).
  final VoidCallback? onTap;

  /// Called on long-press.
  final VoidCallback? onLongPress;

  /// Corner radius for the state layer and the focus ring. Defaults to
  /// [BorderRadius.zero].
  final BorderRadius? borderRadius;

  /// State-layer ink. Defaults to the ambient [BankThemeData.onSurface].
  final Color? overlayColor;

  /// When `false`, interaction is suppressed and the child is dimmed to the
  /// theme's disabled opacity (only when handlers are present).
  final bool enabled;

  /// Pressed-state scale. Defaults to the ambient [BankThemeData.pressScale].
  final double? pressScale;

  /// Announced by assistive technologies for the whole surface.
  final String? semanticLabel;

  /// When `true`, descendant semantics are replaced by [semanticLabel] —
  /// use for surfaces whose visual content would read as noise.
  final bool excludeSemantics;

  /// The surface to decorate.
  final Widget child;

  @override
  State<BankPressable> createState() => _BankPressableState();
}

class _BankPressableState extends State<BankPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _hasHandlers => widget.onTap != null || widget.onLongPress != null;

  bool get _interactive => widget.enabled && _hasHandlers;

  void _handleActivate() {
    if (!_interactive) return;
    // Flash the pressed state so keyboard activation gives the same
    // visual feedback as a tap.
    setState(() => _pressed = true);
    widget.onTap?.call();
    Future<void>.delayed(BankTokens.durationFast, () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fall back to raw tokens when no BankThemeData is registered, so the
    // widget works outside a preset-themed app too.
    final theme = Theme.of(context).extension<BankThemeData>();
    final hoverOpacity =
        theme?.stateLayerHoverOpacity ?? BankTokens.stateLayerHoverOpacity;
    final pressedOpacity =
        theme?.stateLayerPressedOpacity ?? BankTokens.stateLayerPressedOpacity;
    final disabledOpacity =
        theme?.disabledOpacity ?? BankTokens.disabledOpacity;
    final pressScale =
        widget.pressScale ?? theme?.pressScale ?? BankTokens.pressScale;
    final overlayInk = widget.overlayColor ??
        theme?.onSurface ??
        Theme.of(context).colorScheme.onSurface;
    final focusRingColor = (theme?.primary ?? Theme.of(context).primaryColor)
        .withValues(alpha: BankTokens.focusRingOpacity);
    final borderRadius = widget.borderRadius ?? BorderRadius.zero;

    if (!_interactive) {
      var result = widget.child;
      if (!widget.enabled && _hasHandlers) {
        result = Opacity(opacity: disabledOpacity, child: result);
      }
      if (widget.semanticLabel != null) {
        result = Semantics(
          button: _hasHandlers,
          enabled: widget.enabled && _hasHandlers,
          label: widget.semanticLabel,
          excludeSemantics: widget.excludeSemantics,
          child: result,
        );
      }
      return result;
    }

    final overlayOpacity = _pressed
        ? pressedOpacity
        : _hovered
            ? hoverOpacity
            : 0.0;

    // The ring sits fully outside the child so it never occludes content;
    // its radius grows by the same inset so the curves stay concentric.
    const ringGap = 1.0;
    const ringInset = BankTokens.focusRingWidth + ringGap;

    Widget surface = Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: BankTokens.durationFast,
              curve: BankTokens.curveEmphasized,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: overlayInk.withValues(alpha: overlayOpacity),
              ),
            ),
          ),
        ),
        if (_focused)
          Positioned(
            left: -ringInset,
            top: -ringInset,
            right: -ringInset,
            bottom: -ringInset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius +
                      const BorderRadius.all(Radius.circular(ringInset)),
                  border: Border.all(
                    color: focusRingColor,
                    width: BankTokens.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    surface = AnimatedScale(
      scale: _pressed ? pressScale : 1.0,
      duration: BankTokens.durationFast,
      curve: BankTokens.curveEmphasized,
      child: surface,
    );

    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          // Space maps to ActivateIntent, Enter to ButtonActivateIntent in
          // the default WidgetsApp shortcut map; honour both.
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleActivate();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              _handleActivate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: surface,
        ),
      ),
    );
  }
}
