import 'package:flutter/material.dart';

import 'tokens.dart';

/// Kit-internal resolver for button label styles.
///
/// ## The blank-CTA bug this prevents
///
/// Setting `ButtonStyle.textStyle` to a raw token style **replaces** the
/// Material 3 default label style outright — it is not merged into it. The
/// M3 default is where the ambient brand `fontFamily` lives (presets inject
/// it via `textTheme`), so a raw token style silently drops the brand font;
/// on web builds where the fallback resolution differs this has produced
/// CTAs that render blank until the system font loads.
///
/// This helper starts from the ambient `textTheme.labelLarge` (brand font,
/// fallbacks and all) and *merges* the token [metrics] on top, so buttons
/// keep the brand voice while conforming to kit metrics:
///
/// ```dart
/// FilledButton(
///   style: FilledButton.styleFrom(
///     textStyle: bankButtonTextStyle(context),
///   ),
///   ...
/// )
/// ```
TextStyle bankButtonTextStyle(
  BuildContext context, [
  TextStyle metrics = BankTokens.labelLarge,
]) =>
    Theme.of(context).textTheme.labelLarge?.merge(metrics) ?? metrics;
