import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A country indicator that can never render as a tofu box.
///
/// Emoji flags depend on platform font coverage and render as empty boxes on
/// web and many Linux/Windows hosts, so the kit's default is a crafted
/// ISO-code chip that is legible everywhere. Hosts that ship flag artwork can
/// override rendering globally via `BankUiScope`.
class BankCountryFlag extends StatelessWidget {
  const BankCountryFlag({
    required this.isoCode,
    super.key,
    this.size = const Size(24, 16),
    this.radius,
    this.semanticLabel,
  });

  /// Two-letter ISO 3166-1 alpha-2 code, e.g. `GB`.
  final String isoCode;

  /// The rendered footprint of the indicator.
  final Size size;

  /// Corner radius of the chip.
  final BorderRadius? radius;

  /// Semantic label; defaults to the ISO code.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bank = BankThemeData.of(context);
    return Semantics(
      label: semanticLabel ?? isoCode,
      child: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bank.surfaceVariant,
          borderRadius: radius ?? BorderRadius.circular(BankTokens.radiusSmall),
        ),
        child: Text(
          isoCode.toUpperCase(),
          style: BankTokens.labelSmall.copyWith(color: bank.onSurfaceVariant),
        ),
      ),
    );
  }
}
