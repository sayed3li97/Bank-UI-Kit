import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Internal (non-exported) resolvers that put Material's stock toggle controls
/// — [Switch], [Slider], [Checkbox] — onto the kit's palette.
///
/// Those three read their defaults from [ThemeData.colorScheme], never from
/// [BankThemeData], so on a branded screen they render in whatever Material
/// was seeded with rather than in the active preset. Call sites used to patch
/// that one property at a time (`activeThumbColor` here, `inactiveColor`
/// there), which is why the off state stayed stock grey everywhere: the
/// unselected half of the control was never anyone's job. Each widget now
/// wraps its control in the matching `SwitchTheme` / `SliderTheme` /
/// `CheckboxTheme` with the data resolved here, so both halves move together.
///
/// The role mapping deliberately departs from Material's in two places:
///
/// - the "off" track is ambient ink at [BankTokens.alphaMuted] rather than a
///   surface tier, because several presets paint `surfaceVariant` within a
///   couple of steps of `surface` (Studio light: `#F4F4F2` on `#FFFFFF`) and
///   the groove would vanish;
/// - the "off" thumb and the checkbox outline take
///   [BankThemeData.onSurfaceVariant], not [BankThemeData.outline]. `outline`
///   is calibrated as a *hairline* colour; at thumb size it reads as an
///   unpainted hole.
class BankControlTheme {
  const BankControlTheme._();

  /// Material's own checkbox outline weight.
  ///
  /// Not tokenised: this is the control's internal geometry rather than the
  /// kit's, and the check glyph Material paints inside the box is drawn
  /// against it — widening the outline alone would desynchronise the two.
  static const double _checkboxOutlineWidth = 2;

  /// Switch colours for [theme], selected-state fill [accent] (defaults to
  /// [BankThemeData.primary]) and thumb ink [onAccent] (defaults to
  /// [BankThemeData.onPrimary]).
  ///
  /// Pass [onAccent] whenever [accent] is not the brand primary — a status
  /// hue's legible ink is not guaranteed to be `onPrimary`.
  static SwitchThemeData switchTheme(
    BankThemeData theme, {
    Color? accent,
    Color? onAccent,
  }) {
    final on = accent ?? theme.primary;
    final onInk = onAccent ?? theme.onPrimary;
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.onSurface.withValues(alpha: theme.disabledOpacity);
        }
        return states.contains(WidgetState.selected)
            ? onInk
            : theme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.onSurface.withValues(alpha: BankTokens.alphaSubtle);
        }
        return states.contains(WidgetState.selected)
            ? on
            : theme.onSurface.withValues(alpha: BankTokens.alphaMuted);
      }),
      // The filled groove already carries the off state; Material's outline on
      // top of it double-encodes the same information.
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
      overlayColor: _overlayColor(theme, on),
    );
  }

  /// Slider colours for [theme], with [accent] driving the filled track and
  /// thumb.
  ///
  /// [inactiveTrackColor] exists for the sliders that sit on an already-tinted
  /// container and need the groove to match it; leave it null everywhere else
  /// so the kit keeps one groove.
  static SliderThemeData sliderTheme(
    BankThemeData theme, {
    Color? accent,
    Color? onAccent,
    Color? inactiveTrackColor,
  }) {
    final on = accent ?? theme.primary;
    final onInk = onAccent ?? theme.onPrimary;
    final disabledInk =
        theme.onSurface.withValues(alpha: theme.disabledOpacity);
    return SliderThemeData(
      activeTrackColor: on,
      inactiveTrackColor: inactiveTrackColor ??
          theme.onSurface.withValues(alpha: BankTokens.alphaMuted),
      thumbColor: on,
      // Tick marks sit *on* the track, so each takes the ink of the half it
      // falls in.
      activeTickMarkColor:
          onInk.withValues(alpha: BankTokens.alphaSecondaryInk),
      inactiveTickMarkColor:
          theme.onSurfaceVariant.withValues(alpha: BankTokens.alphaScrim),
      disabledActiveTrackColor: disabledInk,
      disabledInactiveTrackColor:
          theme.onSurface.withValues(alpha: BankTokens.alphaSubtle),
      disabledThumbColor: disabledInk,
      disabledActiveTickMarkColor:
          theme.surface.withValues(alpha: BankTokens.alphaScrim),
      disabledInactiveTickMarkColor:
          theme.onSurface.withValues(alpha: BankTokens.alphaMuted),
      overlayColor: on.withValues(alpha: theme.stateLayerPressedOpacity),
      valueIndicatorColor: on,
      valueIndicatorTextStyle: BankTokens.labelSmall.copyWith(color: onInk),
    );
  }

  /// Checkbox colours for [theme], with [accent] filling the ticked box.
  static CheckboxThemeData checkboxTheme(
    BankThemeData theme, {
    Color? accent,
    Color? onAccent,
  }) {
    final on = accent ?? theme.primary;
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return states.contains(WidgetState.selected)
              ? theme.onSurface.withValues(alpha: theme.disabledOpacity)
              : Colors.transparent;
        }
        return states.contains(WidgetState.selected) ? on : Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll<Color>(onAccent ?? theme.onPrimary),
      // A plain BorderSide is applied by Material only while the box is
      // unticked — the ticked box is a solid fill — which is exactly the state
      // that needs a visible outline.
      side: BorderSide(
        color: theme.onSurfaceVariant,
        width: _checkboxOutlineWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
      ),
      overlayColor: _overlayColor(theme, on),
    );
  }

  /// The brand-tinted state layer shared by the toggle controls, so a hover or
  /// press on a switch reads the same as on any other pressable surface.
  static WidgetStateProperty<Color?> _overlayColor(
    BankThemeData theme,
    Color accent,
  ) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return accent.withValues(alpha: theme.stateLayerPressedOpacity);
        }
        if (states.contains(WidgetState.hovered)) {
          return accent.withValues(alpha: theme.stateLayerHoverOpacity);
        }
        if (states.contains(WidgetState.focused)) {
          return accent.withValues(alpha: theme.stateLayerFocusOpacity);
        }
        return null;
      });
}
