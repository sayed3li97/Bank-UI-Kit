import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';

/// Visual treatments for [BankMoneyProtectionBanner].
enum BankMoneyProtectionStyle {
  /// A quiet surface tile with a shield icon: suitable for footers of
  /// account screens and onboarding flows.
  subtle,

  /// A card with a 4 px positive-coloured start border on a tinted
  /// background: suitable for placement near deposit actions where the
  /// guarantee should be unmissable.
  prominent,
}

/// Regulatory deposit-guarantee notice (FDIC / FSCS / local deposit scheme).
///
/// Renders the statutorily required "your eligible deposits are protected"
/// message with a shield icon and an optional learn-more affordance. Place
/// it beneath account balances, on savings product pages, or at the end of
/// a deposit flow.
///
/// Deliberately **non-dismissible**: compliance notices must remain visible,
/// so no close affordance is offered. The banner is static informational
/// content: it is not announced as a live region.
///
/// Visual treatment (see [BankMoneyProtectionStyle]):
/// - [BankMoneyProtectionStyle.subtle]: a [BankThemeData.surfaceVariant]
///   tile with the [BankIcons.shield] icon tinted
///   [BankThemeData.positiveBalance].
/// - [BankMoneyProtectionStyle.prominent]: a 4 px
///   [BankThemeData.positiveBalance] start border on a
///   `positiveBalance.withValues(alpha: 0.08)` background.
///
/// The default copy is `'Your eligible deposits are protected by
/// $schemeName'`; pass [message] to fully localise or reword it. A custom
/// [schemeLogo] (e.g. the FDIC or FSCS mark) replaces the shield icon.
///
/// ```dart
/// BankMoneyProtectionBanner(
///   schemeName: 'the Financial Services Compensation Scheme',
///   detailText: 'Up to £85,000 per person, per institution.',
///   onLearnMore: () => navigator.push(FscsDetailsRoute()),
///   style: BankMoneyProtectionStyle.prominent,
/// )
/// ```
class BankMoneyProtectionBanner extends StatelessWidget {
  /// Name of the deposit-guarantee scheme, interpolated into the default
  /// copy (e.g. `'FDIC'`, `'the Financial Services Compensation Scheme'`).
  final String schemeName;

  /// Optional secondary line, e.g. coverage limits or eligibility notes.
  final String? detailText;

  /// Called when the user taps the learn-more affordance. When `null`,
  /// no learn-more control is shown.
  final VoidCallback? onLearnMore;

  /// Optional scheme mark rendered in place of the shield icon.
  /// Constrained to a 24 × 24 logical-pixel box.
  final Widget? schemeLogo;

  /// Visual treatment of the banner.
  final BankMoneyProtectionStyle style;

  /// Full replacement for the default protection message. When `null`,
  /// `'Your eligible deposits are protected by $schemeName'` is used.
  final String? message;

  /// Label of the learn-more control. Defaults to `'Learn more'`.
  final String learnMoreLabel;

  /// Overrides the banner's content padding (default:
  /// [BankTokens.space4] on all sides).
  final EdgeInsetsGeometry? padding;

  /// Overrides [BankThemeData.cardRadius] as the banner radius.
  final BorderRadius? radius;

  /// Overrides the computed background (default: an 8 % accent tint for
  /// the prominent style, [BankThemeData.surfaceVariant] otherwise).
  final Color? backgroundColor;

  /// Overrides [BankThemeData.positiveBalance] as the accent used for
  /// the shield icon, the prominent start border, and the learn-more
  /// control.
  final Color? accentColor;

  /// Merged over the computed message style (default:
  /// [BankTokens.bodyMedium] at w500 in [BankThemeData.onSurface]).
  final TextStyle? messageStyle;

  /// Merged over the computed [detailText] style (default:
  /// [BankTokens.bodySmall] in [BankThemeData.onSurfaceVariant]).
  final TextStyle? detailStyle;

  /// Overrides the computed semantics label (default: the message
  /// followed by [detailText]).
  final String? semanticLabel;

  const BankMoneyProtectionBanner({
    required this.schemeName,
    this.detailText,
    this.onLearnMore,
    this.schemeLogo,
    this.style = BankMoneyProtectionStyle.subtle,
    this.message,
    this.learnMoreLabel = 'Learn more',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.messageStyle,
    this.detailStyle,
    this.semanticLabel,
    super.key,
  });

  String get _effectiveMessage =>
      message ?? 'Your eligible deposits are protected by $schemeName';

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final prominent = style == BankMoneyProtectionStyle.prominent;
    final accent = accentColor ?? theme.positiveBalance;
    final borderRadius = radius ?? theme.cardRadius;

    final decoration = prominent
        ? BoxDecoration(
            color: backgroundColor ?? accent.withValues(alpha: 0.08),
            borderRadius: borderRadius,
            border: BorderDirectional(
              start: BorderSide(
                color: accent,
                width: 4,
              ),
            ),
          )
        : BoxDecoration(
            color: backgroundColor ?? theme.surfaceVariant,
            borderRadius: borderRadius,
          );

    final detail = detailText;
    final semanticsLabel = semanticLabel ??
        (detail == null ? _effectiveMessage : '$_effectiveMessage. $detail');

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding:
              padding ?? const EdgeInsetsDirectional.all(BankTokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 24,
                child: schemeLogo ??
                    Icon(
                      BankIcons.shield,
                      color: accent,
                      size: 24,
                    ),
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _effectiveMessage,
                        style: BankTokens.bodyMedium
                            .copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w500,
                            )
                            .merge(messageStyle),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: BankTokens.space1),
                        Text(
                          detail,
                          style: BankTokens.bodySmall
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(detailStyle),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (onLearnMore != null) ...[
                const SizedBox(width: BankTokens.space2),
                _LearnMoreButton(
                  label: learnMoreLabel,
                  onPressed: onLearnMore!,
                  color: accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing learn-more affordance: a [TextButton] with a direction-aware
/// chevron.
class _LearnMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _LearnMoreButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final chevron = Transform.flip(
      flipX: isRtl,
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: color,
      ),
    );

    return Semantics(
      button: true,
      label: label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(
            BankTokens.minTapTarget,
            BankTokens.minTapTarget,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space2,
          ),
          shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
          textStyle: BankTokens.labelMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: BankTokens.space1),
            chevron,
          ],
        ),
      ),
    );
  }
}
