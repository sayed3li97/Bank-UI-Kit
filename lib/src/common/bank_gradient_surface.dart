import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';

/// Internal (non-exported) resolver that turns a surface's
/// [BankGradientRole] into the gradient it actually paints and the ink that
/// belongs on top of it.
///
/// [BankThemeData.gradientReach] is a brand-level rationing policy: a
/// signature gradient painted on every component family stops reading as
/// *the* brand moment. The policy is only real if call sites consult it, so
/// every kit surface that used to read [BankThemeData.accentGradient] raw
/// goes through here instead.
///
/// The two halves must move together. A full-strength gradient is an opaque
/// brand fill and takes [BankThemeData.onPrimary]; a demoted one is a
/// low-alpha wash over the ambient surface and takes
/// [BankThemeData.onSurface]. Resolving them separately is how a demoted
/// gradient ends up with white-on-white labels, which is why [gradient] and
/// [foreground] are handed back as one value.
///
/// Precedence, highest first:
///
/// 1. an explicit caller `override` — the host asked for this exact fill, so
///    it is painted at full strength with [BankThemeData.onPrimary] ink;
/// 2. the brand gradient resolved through [BankThemeData.gradientFor], which
///    may come back demoted;
/// 3. `fallback` — the widget's own opaque gradient for brands that define no
///    accent gradient at all, inked with `fallbackForeground`.
@immutable
class BankGradientSurface {
  const BankGradientSurface._({
    required this.gradient,
    required this.foreground,
    required this.demoted,
  });

  /// Resolves what a surface at [role] paints under [theme].
  ///
  /// [override] is a caller-supplied gradient and always wins. [fallback] is
  /// painted when the brand has no accent gradient; it may be `null`, in
  /// which case [gradient] comes back `null` and the caller should paint its
  /// flat treatment instead. [fallbackForeground] is the ink for [fallback]
  /// and for [override], defaulting to [BankThemeData.onPrimary] because both
  /// are opaque brand fills.
  factory BankGradientSurface.resolve(
    BankThemeData theme,
    BankGradientRole role, {
    Gradient? override,
    Gradient? fallback,
    Color? fallbackForeground,
  }) {
    final onFill = fallbackForeground ?? theme.onPrimary;
    if (override != null) {
      return BankGradientSurface._(
        gradient: override,
        foreground: onFill,
        demoted: false,
      );
    }
    final brand = theme.gradientFor(role);
    if (brand != null) {
      return BankGradientSurface._(
        gradient: brand,
        foreground: theme.onGradientFor(role),
        demoted: !theme.paintsFullGradientAt(role),
      );
    }
    return BankGradientSurface._(
      gradient: fallback,
      foreground: onFill,
      demoted: false,
    );
  }

  /// The gradient to paint, or `null` when this brand has nothing to paint
  /// here and the caller supplied no [BankGradientSurface.resolve] fallback.
  final Gradient? gradient;

  /// The ink that stays legible on [gradient].
  final Color foreground;

  /// Whether [gradient] is the brand gradient rationed down to a translucent
  /// wash rather than an opaque fill.
  ///
  /// Surfaces where the gradient carries data rather than decoration — a
  /// progress arc, a meter fill — should check this and fall back to a solid
  /// accent instead of painting an unreadable 10% stroke.
  final bool demoted;

  /// The gradient to paint when the surface must stay legible as a data
  /// encoding: the brand gradient at full strength, or `null` (paint the flat
  /// accent) rather than a translucent wash.
  Gradient? get opaqueGradient => demoted ? null : gradient;
}
