import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// How [BankCountryFlag] renders a country when the host has not supplied
/// artwork via [BankUiScopeData.flagBuilder].
enum BankCountryFlagStyle {
  /// A crafted ISO-code chip: the two-letter code in micro-caps on a
  /// [BankThemeData.surfaceVariant] fill with a hairline border.
  ///
  /// This is the safe default — it uses only the kit's bundled text fonts,
  /// so it renders identically everywhere: offline, on web without a CDN,
  /// on Windows (whose emoji font ships no flag glyphs), and in test
  /// harnesses.
  chip,

  /// A regional-indicator emoji flag (e.g. 🇦🇪), opt-in.
  ///
  /// Emoji flags depend entirely on platform font coverage: they render as
  /// tofu boxes on Windows, on Flutter web without an emoji fallback font,
  /// and on de-flagged OEM Android builds — and there is no reliable way to
  /// detect missing glyph coverage at runtime. Prefer [chip] unless the
  /// deployment targets are known to ship a flag-capable emoji font.
  emoji,
}

/// A country indicator that can never render as a tofu box.
///
/// Resolution order:
///
/// 1. A host override via [BankUiScopeData.flagBuilder] always wins, letting
///    apps plug in bundled flag artwork globally.
/// 2. Otherwise [style] decides: [BankCountryFlagStyle.chip] (default) draws
///    a crafted ISO-code chip that is legible everywhere;
///    [BankCountryFlagStyle.emoji] opts into regional-indicator emoji and
///    trusts platform font coverage (falling back to the chip when [isoCode]
///    is not a two-letter code).
///
/// Accessibility: announced as [semanticLabel] when set, else [countryName],
/// else the ISO code.
class BankCountryFlag extends StatelessWidget {
  const BankCountryFlag({
    required this.isoCode,
    super.key,
    this.size = const Size(24, 16),
    this.radius,
    this.style = BankCountryFlagStyle.chip,
    this.countryName,
    this.semanticLabel,
  });

  /// Two-letter ISO 3166-1 alpha-2 code, e.g. `GB`.
  final String isoCode;

  /// The rendered footprint of the indicator.
  ///
  /// Field-leading flags use the 24×16 default; denser list rows (country
  /// sheet) typically pass 28×20. The chip's type scales with the height.
  final Size size;

  /// Corner radius of the chip. Defaults to [BankTokens.radiusSmall].
  final BorderRadius? radius;

  /// Rendering style when no [BankUiScopeData.flagBuilder] override is set.
  final BankCountryFlagStyle style;

  /// Human-readable country name used for the semantic label (e.g. read by
  /// screen readers as "United Arab Emirates" instead of "AE").
  final String? countryName;

  /// Overrides [countryName] as the semantic label.
  final String? semanticLabel;

  /// The regional-indicator emoji pair for [isoCode], or `null` when the
  /// code is not exactly two ASCII letters.
  String? get _emojiFlag {
    final code = isoCode.toUpperCase();
    if (code.length != 2) return null;
    final a = code.codeUnitAt(0);
    final b = code.codeUnitAt(1);
    if (a < 0x41 || a > 0x5A || b < 0x41 || b > 0x5A) return null;
    return String.fromCharCodes(<int>[0x1F1E6 + a - 0x41, 0x1F1E6 + b - 0x41]);
  }

  Widget _buildChip(BuildContext context) {
    final bank = BankThemeData.of(context);
    // Hairline strength follows the brightness of the surface it sits on.
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(bank.surfaceVariant);
    // Scale the micro-caps with the chip height (11 px at the 16 px default).
    final fontSize = (BankTokens.caption.fontSize ?? 11) * (size.height / 16.0);

    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      // Keeps glyphs clear of the hairline; FittedBox absorbs the loss.
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: bank.surfaceVariant,
        borderRadius: radius ?? BorderRadius.circular(BankTokens.radiusSmall),
        border: Border.all(
          color: BankTokens.hairlineColor(bank.onSurface, surfaceBrightness),
          // Matches BorderSide's default today; keep the token as the
          // source of truth for hairline geometry.
          // ignore: avoid_redundant_argument_values
          width: BankTokens.hairlineWidth,
        ),
      ),
      // scaleDown guarantees long/exotic codes never overflow the chip.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          isoCode.toUpperCase(),
          maxLines: 1,
          // ISO codes are always LTR, mirroring the dial-code precedent.
          textDirection: TextDirection.ltr,
          style: BankTokens.caption.copyWith(
            color: bank.onSurfaceVariant,
            fontSize: fontSize,
            // Optical centring: collapse the line box to the em square and
            // distribute leading evenly so the caps sit visually centred.
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }

  Widget _buildEmoji(String emoji) => SizedBox(
        width: size.width,
        height: size.height,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              emoji,
              maxLines: 1,
              textDirection: TextDirection.ltr,
              // No kit font carries flag glyphs; this deliberately trusts
              // the platform emoji font (see BankCountryFlagStyle.emoji).
              style: TextStyle(fontSize: size.height, height: 1),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final override = BankUiScope.flagFor(context, isoCode, size);

    Widget flag;
    if (override != null) {
      flag = SizedBox(
        width: size.width,
        height: size.height,
        child: override,
      );
    } else if (style == BankCountryFlagStyle.emoji) {
      final emoji = _emojiFlag;
      flag = emoji != null ? _buildEmoji(emoji) : _buildChip(context);
    } else {
      flag = _buildChip(context);
    }

    return Semantics(
      label: semanticLabel ?? countryName ?? isoCode.toUpperCase(),
      // The ISO letters (or emoji) are presentational; the label above is
      // the single source of truth for assistive tech.
      child: ExcludeSemantics(child: flag),
    );
  }
}
