import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_surface_depth.dart';

// ---------------------------------------------------------------------------
// BankSheetHandle
// ---------------------------------------------------------------------------

/// The grab handle drawn at the top of a branded modal sheet.
///
/// The bar is a purely decorative affordance, but it must still be announced:
/// a painted rounded rectangle contributes nothing to the semantics tree, so
/// without a labelled [Semantics] container a screen-reader user gets no cue
/// that the surface is draggable at all.
///
/// Sizing comes from the spacing scale ([BankTokens.space10] wide,
/// [BankTokens.space1] tall, [BankTokens.space3] of breathing room above and
/// below) so the handle stays on the 4 pt grid at every text scale.
class BankSheetHandle extends StatelessWidget {
  const BankSheetHandle({
    super.key,
    this.semanticLabel = BankSheet.defaultHandleSemanticLabel,
    this.color,
  });

  /// Announced by assistive technologies for the handle region.
  final String semanticLabel;

  /// Bar ink. Defaults to the ambient [BankThemeData.outline].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<BankThemeData>();
    final ink =
        color ?? theme?.outline ?? Theme.of(context).colorScheme.outline;

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Center(
        child: Container(
          width: BankTokens.space10,
          height: BankTokens.space1,
          margin: const EdgeInsets.symmetric(vertical: BankTokens.space3),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: const BorderRadius.all(
              Radius.circular(BankTokens.radiusFull),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BankSheetHeader
// ---------------------------------------------------------------------------

/// A sheet title row with optional leading and trailing actions.
///
/// Exists so the kit's modal surfaces stop hand-rolling a title + close-button
/// row each. Laid out with a [Row] and [EdgeInsetsDirectional] throughout, so
/// the leading slot resolves to the visual left in LTR and the visual right in
/// RTL without any per-locale branching.
class BankSheetHeader extends StatelessWidget {
  const BankSheetHeader({
    required this.title,
    super.key,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.padding,
  });

  /// The sheet title. Marked as a semantics header so screen readers can jump
  /// straight to it.
  final String title;

  /// Action rendered before the title — a back chevron, an emblem, an icon.
  final Widget? leading;

  /// Action rendered after the title — typically a close button.
  final Widget? trailing;

  /// Overrides the title style. Merged onto [BankTokens.headlineSmall] in the
  /// theme's ink and brand font.
  final TextStyle? titleStyle;

  /// Overrides the header padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<BankThemeData>();
    final ink = theme?.onSurface ?? Theme.of(context).colorScheme.onSurface;
    final resolvedStyle = BankTokens.headlineSmall
        .copyWith(color: ink, fontFamily: theme?.fontFamily)
        .merge(titleStyle);

    return Padding(
      padding: padding ??
          const EdgeInsetsDirectional.fromSTEB(
            BankTokens.space4,
            0,
            BankTokens.space4,
            BankTokens.space3,
          ),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: BankTokens.space2),
              child: leading,
            ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: resolvedStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding:
                  const EdgeInsetsDirectional.only(start: BankTokens.space2),
              child: trailing,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BankSheetSurface
// ---------------------------------------------------------------------------

/// The branded modal surface: theme radius, theme ground, floating depth, a
/// grab handle, an optional header, and keyboard-aware insets.
///
/// [BankSheet.show] wraps every sheet body in one of these; it is public so a
/// host can compose the same surface into a persistent sheet or a custom
/// route.
///
/// ### Keyboard handling
///
/// The surface lifts itself above the on-screen keyboard and then *removes*
/// the bottom view inset from the subtree's [MediaQuery]. Sheet bodies that
/// already pad by `MediaQuery.viewInsetsOf(context).bottom` therefore see `0`
/// and stay correct instead of double-padding.
///
/// ### Long content
///
/// The body sits in a [Flexible] so a tall child shrinks into the space the
/// handle and header leave rather than overflowing; anything taller than that
/// is expected to scroll internally.
class BankSheetSurface extends StatelessWidget {
  const BankSheetSurface({
    required this.child,
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.showHandle = true,
    this.handleSemanticLabel = BankSheet.defaultHandleSemanticLabel,
    this.backgroundColor,
    this.radius,
    this.shadow,
    this.padding,
    this.resizeToAvoidKeyboard = true,
  });

  /// The sheet body.
  final Widget child;

  /// Title for the built-in [BankSheetHeader]. The header is omitted entirely
  /// when [title], [leading] and [trailing] are all `null`.
  final String? title;

  /// Leading header action. See [BankSheetHeader.leading].
  final Widget? leading;

  /// Trailing header action. See [BankSheetHeader.trailing].
  final Widget? trailing;

  /// Overrides the header title style.
  final TextStyle? titleStyle;

  /// Whether to draw the [BankSheetHandle].
  final bool showHandle;

  /// Screen-reader label for the grab handle.
  final String handleSemanticLabel;

  /// Sheet ground. Defaults to [BankThemeData.surface]; pass
  /// [Colors.transparent] when the body paints its own surface, which also
  /// suppresses the depth treatment.
  final Color? backgroundColor;

  /// Corner radius. Defaults to [BankThemeData.sheetRadius].
  final BorderRadius? radius;

  /// Overrides the floating-tier shadow; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Padding around [child], inside the surface.
  final EdgeInsetsGeometry? padding;

  /// Whether to lift the surface above the on-screen keyboard.
  final bool resizeToAvoidKeyboard;

  bool get _hasHeader => title != null || leading != null || trailing != null;

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final theme = materialTheme.extension<BankThemeData>();
    final ground =
        backgroundColor ?? theme?.surface ?? materialTheme.colorScheme.surface;
    final corners = radius ?? theme?.sheetRadius ?? _fallbackRadius;

    // A fully transparent ground means the body brings its own painted
    // surface; painting depth behind it would stamp a second silhouette.
    final paintsSurface = ground.a > 0;
    final depth = paintsSurface && theme != null
        ? BankSurfaceDepth.resolve(
            theme,
            surfaceColor: ground,
            shadow: shadow,
            tier: BankSurfaceDepthTier.floating,
          )
        : null;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      // The modal route hands its child a *tight* width. Stretching preserves
      // that contract for the body: without it the column would relax the
      // width to loose and every sheet would shrink-wrap its content.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) BankSheetHandle(semanticLabel: handleSemanticLabel),
        if (_hasHeader)
          BankSheetHeader(
            title: title ?? '',
            leading: leading,
            trailing: trailing,
            titleStyle: titleStyle,
          ),
        Flexible(
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ],
    );

    if (paintsSurface) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: corners,
          boxShadow: depth?.shadow ?? shadow ?? const <BoxShadow>[],
          border: depth?.border,
        ),
        child: ClipRRect(
          borderRadius: corners,
          // Ink splashes paint on the nearest Material ancestor. Without a
          // transparent one *inside* the painted ground, every ListTile and
          // InkWell in the body would splash behind it — invisibly.
          child: Material(type: MaterialType.transparency, child: content),
        ),
      );
    }

    if (resizeToAvoidKeyboard) {
      content = Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: content,
        ),
      );
    }

    return content;
  }

  /// Mirrors `BankThemeData.custom`'s sheet default, for hosts that render a
  /// sheet outside a Bank-themed subtree.
  static const BorderRadius _fallbackRadius = BorderRadius.vertical(
    top: Radius.circular(BankTokens.radiusLarge),
  );
}

// ---------------------------------------------------------------------------
// BankSheet
// ---------------------------------------------------------------------------

/// Branded modal-sheet presentation.
///
/// Stock [showModalBottomSheet] arrives with Material defaults on every axis a
/// design system cares about: no grab handle, Material's radius instead of
/// [BankThemeData.sheetRadius], a fixed `black54` scrim, and Material's
/// 250/200 ms `easeOutQuad` transition. [BankSheet.show] replaces all four
/// with the kit's own tokens and returns the same generic `Future<T?>`, so
/// callers keep their result values.
///
/// ```dart
/// final picked = await BankSheet.show<BankAccount>(
///   context,
///   title: 'Switch account',
///   builder: (_) => AccountList(onTap: Navigator.of(context).pop),
/// );
/// ```
///
/// Sheets whose body already paints its own rounded ground pass
/// `backgroundColor: Colors.transparent` and `showHandle: false`; they still
/// pick up the branded scrim, motion, safe area, and keyboard handling.
class BankSheet {
  const BankSheet._();

  /// Default screen-reader label for [BankSheetHandle].
  static const String defaultHandleSemanticLabel = 'Drag handle';

  /// Scrim opacity over a light ground.
  static const double scrimOpacity = 0.46;

  /// Scrim opacity over a dark ground.
  ///
  /// Heavier than [scrimOpacity] because low-luminance contrast compresses:
  /// the same alpha over a near-black ground barely reads as a veil.
  static const double scrimOpacityDark = 0.66;

  /// The branded modal scrim for the ambient theme.
  ///
  /// Uses whichever of the theme's ground and ink is darker, so the veil
  /// always *removes* light — the brand ink on light themes, the near-black
  /// ground on dark ones. A fixed `black54` would ignore the brand tint, and
  /// a plain `onBackground` would paint a white haze in dark mode.
  static Color scrimColor(BuildContext context) {
    final materialTheme = Theme.of(context);
    final theme = materialTheme.extension<BankThemeData>();
    final ground = theme?.background ?? materialTheme.colorScheme.surface;
    final ink = theme?.onBackground ?? materialTheme.colorScheme.onSurface;
    final onDarkGround =
        ThemeData.estimateBrightnessForColor(ground) == Brightness.dark;
    return (onDarkGround ? ground : ink)
        .withValues(alpha: onDarkGround ? scrimOpacityDark : scrimOpacity);
  }

  /// Token-driven sheet transition: [BankTokens.durationBase] in on
  /// [BankTokens.curveDecelerate] (an element arriving from off-canvas),
  /// [BankTokens.durationFast] out on [BankTokens.curveEmphasized].
  ///
  /// Collapses to [AnimationStyle.noAnimation] when the platform reports
  /// `disableAnimations`, so the sheet is simply *there* for users who have
  /// asked the OS to stop moving things.
  static AnimationStyle animationStyle(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: BankTokens.durationBase,
              reverseDuration: BankTokens.durationFast,
              curve: BankTokens.curveDecelerate,
              reverseCurve: BankTokens.curveEmphasized,
            );

  /// Presents [builder] as a branded modal bottom sheet and completes with the
  /// value the sheet pops, or `null` when it is dismissed.
  ///
  /// [isScrollControlled] defaults to `true` — the kit's sheets carry forms and
  /// long lists, and a scroll-controlled sheet is the only one that can grow
  /// past Material's 9/16 clamp and react to the keyboard. Pass `false` for
  /// short, fixed action menus to keep Material's clamp.
  ///
  /// [showHandle] defaults to [enableDrag]: a handle on a sheet that cannot be
  /// dragged is a lie, so non-dismissible flows (SCA approval, PIN entry) drop
  /// it automatically.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    Widget? leading,
    Widget? trailing,
    TextStyle? titleStyle,
    bool? showHandle,
    String handleSemanticLabel = defaultHandleSemanticLabel,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
    bool useRootNavigator = false,
    bool resizeToAvoidKeyboard = true,
    Color? backgroundColor,
    BorderRadius? radius,
    List<BoxShadow>? shadow,
    EdgeInsetsGeometry? padding,
    Color? barrierColor,
    String? barrierLabel,
    BoxConstraints? constraints,
    RouteSettings? routeSettings,
    AnimationStyle? sheetAnimationStyle,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        constraints: constraints,
        routeSettings: routeSettings,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor ?? scrimColor(context),
        // The branded surface is painted by BankSheetSurface so the ground,
        // radius, depth, handle and header share one clip. Material's own
        // ground and elevation would stamp a second, squarer silhouette
        // behind it.
        backgroundColor: Colors.transparent,
        elevation: 0,
        // A host BottomSheetThemeData must not be able to add a second,
        // unbranded handle above ours.
        showDragHandle: false,
        sheetAnimationStyle: sheetAnimationStyle ?? animationStyle(context),
        builder: (sheetContext) => BankSheetSurface(
          title: title,
          leading: leading,
          trailing: trailing,
          titleStyle: titleStyle,
          showHandle: showHandle ?? enableDrag,
          handleSemanticLabel: handleSemanticLabel,
          backgroundColor: backgroundColor,
          radius: radius,
          shadow: shadow,
          padding: padding,
          resizeToAvoidKeyboard: resizeToAvoidKeyboard,
          child: builder(sheetContext),
        ),
      );
}

// ---------------------------------------------------------------------------
// BankDialog
// ---------------------------------------------------------------------------

/// Branded centre-dialog presentation — the [BankSheet] counterpart for the
/// kit's confirmation dialogs.
///
/// Gives every `showDialog` call site the same scrim and the same token
/// motion as a sheet, so a confirm dialog and the sheet that raised it read as
/// one system. The dialog body itself is the caller's, so existing
/// [AlertDialog] content keeps its shape and copy.
class BankDialog {
  const BankDialog._();

  /// Token-driven dialog transition: [BankTokens.durationFast] both ways on
  /// [BankTokens.curveEmphasized] — a dialog appears in place, so it wants a
  /// snappier curve than a sheet travelling in from off-canvas.
  ///
  /// Collapses to [AnimationStyle.noAnimation] under `disableAnimations`.
  static AnimationStyle animationStyle(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: BankTokens.durationFast,
              reverseDuration: BankTokens.durationFast,
              curve: BankTokens.curveEmphasized,
              reverseCurve: BankTokens.curveEmphasized,
            );

  /// Presents [builder] as a branded modal dialog and completes with the value
  /// the dialog pops, or `null` when it is dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    AnimationStyle? dialogAnimationStyle,
  }) =>
      showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? BankSheet.scrimColor(context),
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        animationStyle: dialogAnimationStyle ?? animationStyle(context),
      );
}
