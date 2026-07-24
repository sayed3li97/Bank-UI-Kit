import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/button_text_style.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A rate figure shown as the hero of a [BankProductCard].
///
/// The labels are fully caller-supplied so the card stays Shariah-safe: a
/// conventional product can pass `'APR'`, while an Islamic product can pass
/// `'Profit rate'`. Never assume a specific label.
///
/// The rate line renders **in reading order**: [prefixLabel], then [value],
/// then [label]. A qualifier such as *from* belongs in [prefixLabel] so the
/// line reads `'From 5.9% APR'` — putting `'from APR'` in [label] would
/// compose backwards as `'5.9% from APR'`.
///
/// The optional [caption] carries compliance microcopy such as
/// `'Representative'` or `'as of 4 Jul 2026'`. State the representative
/// qualifier **once** — in [caption] *or* in a label — never in both.
@immutable
class BankProductRate {
  /// The formatted rate value, e.g. `'5.9%'`. Passed pre-formatted so the
  /// card does not impose a locale or numeral system on it.
  final String value;

  /// The rate label rendered *after* [value], e.g. `'APR'` or
  /// `'Profit rate'`.
  final String label;

  /// Optional qualifier rendered *before* [value], e.g. `'From'`, so
  /// compliance copy reads naturally in order: `'From 5.9% APR'`.
  final String? prefixLabel;

  /// Optional microcopy under the value, e.g. `'Representative'` or
  /// `'as of 4 Jul 2026'`.
  final String? caption;

  /// Creates an immutable rate descriptor.
  const BankProductRate({
    required this.value,
    required this.label,
    this.prefixLabel,
    this.caption,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankProductRate &&
          other.value == value &&
          other.label == label &&
          other.prefixLabel == prefixLabel &&
          other.caption == caption;

  @override
  int get hashCode => Object.hash(value, label, prefixLabel, caption);
}

/// The visual tone of a [BankProductBadge] chip.
enum BankProductBadgeTone {
  /// Muted, informational (e.g. `'No fee'`).
  neutral,

  /// Positive / reassuring (e.g. `'Pre-qualified'`).
  positive,

  /// Promotional / featured accent (e.g. `'Featured'`).
  promo,

  /// Shariah-compliant marker (e.g. `'Shariah'`).
  shariah,
}

/// A small badge chip shown in the badge row of a [BankProductCard].
@immutable
class BankProductBadge {
  /// The badge text, e.g. `'Featured'`, `'No fee'`, `'Shariah'`.
  final String label;

  /// The badge tone. Defaults to [BankProductBadgeTone.neutral].
  final BankProductBadgeTone tone;

  /// Creates an immutable badge descriptor.
  const BankProductBadge({
    required this.label,
    this.tone = BankProductBadgeTone.neutral,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankProductBadge && other.label == label && other.tone == tone;

  @override
  int get hashCode => Object.hash(label, tone);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A marketing product card for a banking product catalog.
///
/// Presents a single product line (loan, mortgage, card, deposit,
/// investment, insurance; conventional or Islamic) with an optional leading
/// emblem, a product name and tagline, a rate hero (value, label, caption),
/// a short list of feature bullets, a row of badge chips, and one or two
/// call-to-action buttons.
///
/// Set [highlighted] to give a featured product an accent border, a gradient
/// identity header, and a floating shadow.
///
/// Every user-facing string is a constructor parameter with an English
/// default, and every visual decision (padding, radius, colors, gradient,
/// shadow, text styles, icons, header/footer slots) is optionally
/// overridable, so a bank can fully rebrand the card without a fork.
///
/// ```dart
/// BankProductCard(
///   title: 'Personal Loan',
///   subtitle: 'Borrow from 1,000 to 50,000',
///   leadingIcon: Icons.request_quote_outlined,
///   rate: const BankProductRate(
///     prefixLabel: 'From',
///     value: '5.9%',
///     label: 'APR',
///     caption: 'Representative',
///   ),
///   features: const [
///     'No early repayment fee',
///     'Funds in minutes once approved',
///     'Fixed monthly payments',
///   ],
///   badges: const [
///     BankProductBadge(label: 'Featured', tone: BankProductBadgeTone.promo),
///     BankProductBadge(label: 'No fee', tone: BankProductBadgeTone.neutral),
///   ],
///   ctaLabel: 'View details',
///   onTap: () {},
///   secondaryLabel: 'Check eligibility',
///   onSecondary: () {},
///   highlighted: true,
/// )
/// ```
class BankProductCard extends StatelessWidget {
  /// The product name, shown as the card title.
  final String title;

  /// A short tagline shown under the [title].
  final String? subtitle;

  /// The rate hero (value, label, caption). Hidden when null.
  final BankProductRate? rate;

  /// Two to four short feature bullet strings. Defaults to an empty list.
  final List<String> features;

  /// The badge chips shown in a wrapping row. Defaults to an empty list.
  final List<BankProductBadge> badges;

  /// Primary call-to-action label. Defaults to `'View details'`.
  final String ctaLabel;

  /// Called when the primary CTA is tapped. When null the primary CTA is
  /// disabled.
  final VoidCallback? onTap;

  /// Optional secondary call-to-action label, e.g. `'Check eligibility'`.
  /// The secondary CTA is only shown when both this and [onSecondary] are
  /// set.
  final String? secondaryLabel;

  /// Called when the secondary CTA is tapped.
  final VoidCallback? onSecondary;

  /// Whether to apply the featured treatment: accent border, gradient
  /// identity header, and a floating shadow. Defaults to `false`.
  final bool highlighted;

  /// Optional leading emblem widget. Takes precedence over [leadingIcon].
  final Widget? leading;

  /// Glyph for the default leading emblem when [leading] is null. When both
  /// are null no emblem is shown.
  final IconData? leadingIcon;

  /// Replaces the whole identity header (emblem, title, subtitle).
  final Widget? header;

  /// Optional footer slot rendered full width below the CTAs.
  final Widget? footer;

  /// Overrides the content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme `cardRadius`.
  final BorderRadius? radius;

  /// Overrides the card background color. Defaults to the theme `surface`.
  final Color? backgroundColor;

  /// Overrides the accent used for the emblem, rate value, promo badges,
  /// border and buttons. Defaults to the theme `primary`.
  final Color? accentColor;

  /// Overrides the gradient painted behind the identity header when
  /// [highlighted]. Defaults to the theme `accentGradient`, or a gradient
  /// derived from the accent color.
  final Gradient? gradient;

  /// Overrides the card shadow. Defaults to the floating shadow when
  /// [highlighted], otherwise the resting card shadow, each resolved for
  /// the theme background brightness ([BankTokens.shadowFloatingFor] /
  /// [BankTokens.shadowCardFor]). Pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Non-highlighted cards default on dark
  /// surfaces to a [BankTokens.hairlineWidth] hairline in
  /// [BankTokens.hairlineColor] (a shadow alone cannot separate the card
  /// there) and on light surfaces to an invisible border of the same
  /// width, so geometry is identical across brightness. Highlighted
  /// cards keep their accent border. Pass `const Border()` to remove.
  final BoxBorder? border;

  /// Merged over the title style (`BankTokens.headlineSmall`).
  final TextStyle? titleStyle;

  /// Merged over the subtitle style (`BankTokens.bodySmall`).
  final TextStyle? subtitleStyle;

  /// Merged over the rate value style (`BankTokens.headlineLarge`).
  final TextStyle? rateValueStyle;

  /// Merged over the rate label style (`BankTokens.labelMedium`).
  /// Applies to both [BankProductRate.prefixLabel] and
  /// [BankProductRate.label].
  final TextStyle? rateLabelStyle;

  /// Merged over the rate caption style (`BankTokens.bodySmall`).
  final TextStyle? rateCaptionStyle;

  /// Merged over the feature bullet style (`BankTokens.bodyMedium`).
  final TextStyle? featureStyle;

  /// Glyph shown beside each feature bullet. Defaults to
  /// [Icons.check_circle].
  final IconData? featureIcon;

  /// Overrides the generated card semantics label. Supply for non-English
  /// locales.
  final String? semanticLabel;

  /// Creates a marketing product card.
  const BankProductCard({
    required this.title,
    super.key,
    this.subtitle,
    this.rate,
    this.features = const [],
    this.badges = const [],
    this.ctaLabel = 'View details',
    this.onTap,
    this.secondaryLabel,
    this.onSecondary,
    this.highlighted = false,
    this.leading,
    this.leadingIcon,
    this.header,
    this.footer,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.gradient,
    this.shadow,
    this.border,
    this.titleStyle,
    this.subtitleStyle,
    this.rateValueStyle,
    this.rateLabelStyle,
    this.rateCaptionStyle,
    this.featureStyle,
    this.featureIcon,
    this.semanticLabel,
  });

  Color _toneColor(
    BankProductBadgeTone tone,
    BankThemeData theme,
    Color accent,
  ) {
    switch (tone) {
      case BankProductBadgeTone.neutral:
        return theme.onSurfaceVariant;
      case BankProductBadgeTone.positive:
        return theme.positiveBalance;
      case BankProductBadgeTone.promo:
        return accent;
      case BankProductBadgeTone.shariah:
        return BankTokens.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = accentColor ?? theme.primary;
    final cardRadius = radius ?? theme.cardRadius;
    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);
    // Brightness of the painted surface drives the hairline; brightness
    // of the theme background drives the resting shadow (matching the
    // kit-wide BankAccountCard treatment).
    final resolvedBackground = backgroundColor ?? theme.surface;
    final surfaceBrightness =
        ThemeData.estimateBrightnessForColor(resolvedBackground);
    final backgroundBrightness =
        ThemeData.estimateBrightnessForColor(theme.background);
    final resolvedShadow = shadow ??
        (highlighted
            ? BankTokens.shadowFloatingFor(backgroundBrightness)
            : BankTokens.shadowCardFor(backgroundBrightness));

    // Highlighted cards keep the accent border; plain cards get a dark
    // hairline (or an invisible border of the same width on light
    // surfaces, so geometry stays identical across brightness).
    final resolvedBorder = border ??
        (highlighted
            ? Border.all(
                color: accent.withValues(alpha: 0.5),
                width: 1.5,
              )
            : Border.all(
                color: surfaceBrightness == Brightness.dark
                    ? BankTokens.hairlineColor(
                        theme.onSurface,
                        surfaceBrightness,
                      )
                    : theme.onSurface.withValues(alpha: 0),
                // Matches Border.all's default today; keep the token as
                // the source of truth for hairline geometry.
                // ignore: avoid_redundant_argument_values
                width: BankTokens.hairlineWidth,
              ));

    final semantics = semanticLabel ?? _defaultSemanticLabel();

    final Widget identity;
    if (header != null) {
      identity = header!;
    } else {
      identity = _Identity(
        title: title,
        subtitle: subtitle,
        leading: leading,
        leadingIcon: leadingIcon,
        accent: accent,
        theme: theme,
        onGradient: highlighted,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
      );
    }

    final headerGradient = highlighted
        ? (gradient ??
            theme.accentGradient ??
            LinearGradient(
              colors: [accent, theme.primaryVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ))
        : null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rate != null) ...[
          _RateHero(
            rate: rate!,
            accent: accent,
            theme: theme,
            valueStyle: rateValueStyle,
            labelStyle: rateLabelStyle,
            captionStyle: rateCaptionStyle,
          ),
          const SizedBox(height: BankTokens.space3),
        ],
        if (features.isNotEmpty) ...[
          _FeatureList(
            features: features,
            accent: accent,
            theme: theme,
            icon: featureIcon ?? Icons.check_circle,
            style: featureStyle,
          ),
          const SizedBox(height: BankTokens.space3),
        ],
        if (badges.isNotEmpty) ...[
          Wrap(
            spacing: BankTokens.space2,
            runSpacing: BankTokens.space2,
            children: [
              for (final badge in badges)
                _BadgeChip(
                  badge: badge,
                  color: _toneColor(badge.tone, theme, accent),
                  theme: theme,
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space4),
        ],
        _Actions(
          ctaLabel: ctaLabel,
          onTap: onTap,
          secondaryLabel: secondaryLabel,
          onSecondary: onSecondary,
          accent: accent,
          theme: theme,
        ),
        if (footer != null) ...[
          const SizedBox(height: BankTokens.space3),
          footer!,
        ],
      ],
    );

    return Semantics(
      container: true,
      label: semantics,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolvedBackground,
          borderRadius: cardRadius,
          boxShadow: resolvedShadow,
          border: resolvedBorder,
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: headerGradient != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: headerGradient),
                      child: Padding(
                        padding: resolvedPadding,
                        child: identity,
                      ),
                    ),
                    Padding(padding: resolvedPadding, child: body),
                  ],
                )
              : Padding(
                  padding: resolvedPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      identity,
                      const SizedBox(height: BankTokens.space3),
                      body,
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _defaultSemanticLabel() {
    final buffer = StringBuffer(title);
    if (subtitle != null && subtitle!.isNotEmpty) {
      buffer.write('. $subtitle');
    }
    if (rate != null) {
      final prefix = rate!.prefixLabel;
      final rateText = [
        if (prefix != null && prefix.isNotEmpty) prefix,
        rate!.value,
        rate!.label,
      ].join(' ');
      buffer.write('. $rateText');
      if (rate!.caption != null && rate!.caption!.isNotEmpty) {
        buffer.write(', ${rate!.caption}');
      }
    }
    buffer.write('.');
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// Identity header
// ---------------------------------------------------------------------------

class _Identity extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final Color accent;
  final BankThemeData theme;
  final bool onGradient;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const _Identity({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.leadingIcon,
    required this.accent,
    required this.theme,
    required this.onGradient,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = onGradient ? theme.onPrimary : theme.onSurface;
    final subtitleColor = onGradient
        ? theme.onPrimary.withValues(alpha: 0.85)
        : theme.onSurfaceVariant;

    Widget? emblem;
    if (leading != null) {
      emblem = leading;
    } else if (leadingIcon != null) {
      final discColor = onGradient
          ? theme.onPrimary.withValues(alpha: 0.2)
          : accent.withValues(alpha: 0.12);
      final iconColor = onGradient ? theme.onPrimary : accent;
      emblem = Container(
        width: BankTokens.space10,
        height: BankTokens.space10,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: discColor,
          borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
        ),
        child: Icon(leadingIcon, size: BankTokens.space5, color: iconColor),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emblem != null) ...[
          emblem,
          const SizedBox(width: BankTokens.space3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: BankTokens.headlineSmall
                    .copyWith(color: titleColor)
                    .merge(titleStyle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space1),
                Text(
                  subtitle!,
                  style: BankTokens.bodySmall
                      .copyWith(color: subtitleColor)
                      .merge(subtitleStyle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Rate hero
// ---------------------------------------------------------------------------

class _RateHero extends StatelessWidget {
  final BankProductRate rate;
  final Color accent;
  final BankThemeData theme;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final TextStyle? captionStyle;

  const _RateHero({
    required this.rate,
    required this.accent,
    required this.theme,
    required this.valueStyle,
    required this.labelStyle,
    required this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reading order: prefix qualifier, value, label — so a rate
            // composed as (prefixLabel: 'From', value: '5.9%',
            // label: 'APR') renders 'From 5.9% APR', never backwards.
            if (rate.prefixLabel != null && rate.prefixLabel!.isNotEmpty) ...[
              Flexible(
                child: Text(
                  rate.prefixLabel!,
                  style: BankTokens.labelMedium
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(labelStyle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BankTokens.space2),
            ],
            Flexible(
              child: Text(
                rate.value,
                style: BankTokens.headlineLarge
                    .copyWith(color: accent)
                    .merge(valueStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: BankTokens.space2),
            Flexible(
              child: Text(
                rate.label,
                style: BankTokens.labelMedium
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(labelStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (rate.caption != null && rate.caption!.isNotEmpty) ...[
          const SizedBox(height: BankTokens.space1),
          Text(
            rate.caption!,
            style: BankTokens.bodySmall
                .copyWith(color: theme.onSurfaceVariant)
                .merge(captionStyle),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature list
// ---------------------------------------------------------------------------

class _FeatureList extends StatelessWidget {
  final List<String> features;
  final Color accent;
  final BankThemeData theme;
  final IconData icon;
  final TextStyle? style;

  const _FeatureList({
    required this.features,
    required this.accent,
    required this.theme,
    required this.icon,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < features.length; i++) ...[
          if (i > 0) const SizedBox(height: BankTokens.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Icon(
                  icon,
                  size: BankTokens.space4,
                  color: accent,
                ),
              ),
              const SizedBox(width: BankTokens.space2),
              Expanded(
                child: Text(
                  features[i],
                  style: BankTokens.bodyMedium
                      .copyWith(color: theme.onSurface)
                      .merge(style),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Badge chip
// ---------------------------------------------------------------------------

class _BadgeChip extends StatelessWidget {
  final BankProductBadge badge;
  final Color color;
  final BankThemeData theme;

  const _BadgeChip({
    required this.badge,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        badge.label,
        style: BankTokens.labelSmall.copyWith(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

class _Actions extends StatelessWidget {
  final String ctaLabel;
  final VoidCallback? onTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Color accent;
  final BankThemeData theme;

  const _Actions({
    required this.ctaLabel,
    required this.onTap,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.accent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: BankTokens.minTapTarget,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: theme.onPrimary,
              textStyle: bankButtonTextStyle(context),
              shape: RoundedRectangleBorder(
                borderRadius: theme.buttonRadius,
              ),
            ),
            child: Text(ctaLabel),
          ),
        ),
        if (hasSecondary) ...[
          const SizedBox(height: BankTokens.space2),
          SizedBox(
            width: double.infinity,
            height: BankTokens.minTapTarget,
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                textStyle: bankButtonTextStyle(context),
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: theme.buttonRadius,
                ),
              ),
              child: Text(secondaryLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
