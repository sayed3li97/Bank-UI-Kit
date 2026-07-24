import 'package:flutter/material.dart';

import '../../src/common/bank_surface_depth.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class BankPerk {
  final String id;
  final String partnerName;
  final String title;
  final String description;
  final String? logoUrl;
  final String? discountLabel;
  final DateTime? expiresAt;
  final bool isActivated;

  const BankPerk({
    required this.id,
    required this.partnerName,
    required this.title,
    required this.description,
    this.logoUrl,
    this.discountLabel,
    this.expiresAt,
    this.isActivated = false,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Marketplace card for a single partner perk.
///
/// Shows the partner logo (or initials fallback), title, discount badge,
/// expiry hint, and an "Activate" button or "Activated" chip based on state.
class BankPerksMarketplaceCard extends StatefulWidget {
  final BankPerk perk;
  final VoidCallback? onActivate;
  final VoidCallback? onTap;

  /// Overrides the card content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card background color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Overrides the accent used for the initials avatar, tap splash and
  /// activate button. Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Merged over the perk title style (BankTokens.labelLarge in
  /// onSurface).
  final TextStyle? titleStyle;

  /// Merged over the partner-name style (BankTokens.bodySmall in
  /// onSurfaceVariant).
  final TextStyle? partnerStyle;

  /// Merged over the description style (BankTokens.bodySmall in
  /// onSurfaceVariant).
  final TextStyle? descriptionStyle;

  /// Radius of the partner logo avatar. Defaults to 24.
  final double? logoRadius;

  /// Glyph beside the activated label. Defaults to [Icons.check_circle].
  final IconData? activatedIcon;

  /// Activate button label. Defaults to `'Activate'`.
  final String activateLabel;

  /// Activated chip label. Defaults to `'Activated'`.
  final String activatedLabel;

  /// Expiry text once past [BankPerk.expiresAt]. Defaults to
  /// `'Expired'`.
  final String expiredLabel;

  /// Expiry text on the final day. Defaults to `'Expires today'`.
  final String expiresTodayLabel;

  /// Expiry text one day before. Defaults to `'Expires tomorrow'`.
  final String expiresTomorrowLabel;

  /// Expiry text within 30 days; `{n}` is substituted. Defaults to
  /// `'Expires in {n} days'`.
  final String expiresInDaysTemplate;

  /// Expiry text at exactly one month. Defaults to
  /// `'Expires in 1 month'`.
  final String expiresInMonthLabel;

  /// Expiry text beyond one month; `{n}` is substituted. Defaults to
  /// `'Expires in {n} months'`.
  final String expiresInMonthsTemplate;

  /// Overrides the generated card semantics label. Supply for
  /// non-English locales.
  final String? semanticLabel;

  const BankPerksMarketplaceCard({
    required this.perk,
    super.key,
    this.onActivate,
    this.onTap,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.shadow,
    this.border,
    this.titleStyle,
    this.partnerStyle,
    this.descriptionStyle,
    this.logoRadius,
    this.activatedIcon,
    this.activateLabel = 'Activate',
    this.activatedLabel = 'Activated',
    this.expiredLabel = 'Expired',
    this.expiresTodayLabel = 'Expires today',
    this.expiresTomorrowLabel = 'Expires tomorrow',
    this.expiresInDaysTemplate = 'Expires in {n} days',
    this.expiresInMonthLabel = 'Expires in 1 month',
    this.expiresInMonthsTemplate = 'Expires in {n} months',
    this.semanticLabel,
  });

  @override
  State<BankPerksMarketplaceCard> createState() =>
      _BankPerksMarketplaceCardState();
}

class _BankPerksMarketplaceCardState extends State<BankPerksMarketplaceCard> {
  bool _logoFailed = false;

  @override
  void didUpdateWidget(BankPerksMarketplaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.perk.logoUrl != widget.perk.logoUrl) {
      _logoFailed = false;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _formatExpiry(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return widget.expiredLabel;
    if (diff.inDays == 0) return widget.expiresTodayLabel;
    if (diff.inDays == 1) return widget.expiresTomorrowLabel;
    if (diff.inDays <= 30) {
      return widget.expiresInDaysTemplate.replaceAll('{n}', '${diff.inDays}');
    }
    final months = (diff.inDays / 30).round();
    if (months == 1) return widget.expiresInMonthLabel;
    return widget.expiresInMonthsTemplate.replaceAll('{n}', '$months');
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final perk = widget.perk;
    final accent = widget.accentColor ?? bankTheme.primary;
    final cardRadius = widget.radius ?? bankTheme.cardRadius;
    final avatarRadius = widget.logoRadius ?? 24;

    final expiryText =
        perk.expiresAt != null ? _formatExpiry(perk.expiresAt!) : '';
    final isExpired =
        perk.expiresAt != null && perk.expiresAt!.isBefore(DateTime.now());

    Widget logoWidget;
    if (perk.logoUrl != null && !_logoFailed) {
      logoWidget = CircleAvatar(
        radius: avatarRadius,
        backgroundColor: bankTheme.surfaceVariant,
        backgroundImage: BankUiScope.imageProviderFor(context, perk.logoUrl!),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _logoFailed = true);
        },
      );
    } else {
      logoWidget = CircleAvatar(
        radius: avatarRadius,
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Text(
          _initials(perk.partnerName),
          style: BankTokens.labelMedium.copyWith(color: accent),
        ),
      );
    }

    final semanticLabel = widget.semanticLabel ??
        '${perk.partnerName}: ${perk.title}. '
            '${perk.discountLabel != null ? '${perk.discountLabel!}. ' : ''}'
            '${expiryText.isNotEmpty ? '$expiryText. ' : ''}'
            '${perk.isActivated ? 'Activated.' : 'Not activated.'}';

    final depth = BankSurfaceDepth.resolve(
      bankTheme,
      surfaceColor: widget.backgroundColor,
      shadow: widget.shadow,
      border: widget.border,
    );

    return Semantics(
      label: semanticLabel,
      button: widget.onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? bankTheme.surface,
          borderRadius: cardRadius,
          boxShadow: depth.shadow,
          border: depth.border,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: cardRadius,
            splashColor: accent.withValues(alpha: 0.06),
            child: Padding(
              padding:
                  widget.padding ?? const EdgeInsets.all(BankTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: logo + info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      logoWidget,
                      const SizedBox(width: BankTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Partner name
                            Text(
                              perk.partnerName,
                              style: BankTokens.bodySmall
                                  .copyWith(
                                    color: bankTheme.onSurfaceVariant,
                                  )
                                  .merge(widget.partnerStyle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Perk title
                            Text(
                              perk.title,
                              style: BankTokens.labelLarge
                                  .copyWith(color: bankTheme.onSurface)
                                  .merge(widget.titleStyle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Description
                            Text(
                              perk.description,
                              style: BankTokens.bodySmall
                                  .copyWith(
                                    color: bankTheme.onSurfaceVariant,
                                  )
                                  .merge(widget.descriptionStyle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: BankTokens.space2),
                            // Discount badge + expiry row
                            Wrap(
                              spacing: BankTokens.space2,
                              runSpacing: BankTokens.space1,
                              children: [
                                if (perk.discountLabel != null)
                                  _DiscountBadge(
                                    label: perk.discountLabel!,
                                    bankTheme: bankTheme,
                                  ),
                                if (expiryText.isNotEmpty)
                                  Text(
                                    expiryText,
                                    style: BankTokens.bodySmall.copyWith(
                                      color: isExpired
                                          ? bankTheme.negativeBalance
                                          : bankTheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Action row
                  if (widget.onActivate != null || perk.isActivated) ...[
                    const SizedBox(height: BankTokens.space3),
                    const Divider(height: 1),
                    const SizedBox(height: BankTokens.space3),
                    _ActionRow(
                      perk: perk,
                      bankTheme: bankTheme,
                      onActivate: widget.onActivate,
                      accent: accent,
                      activateLabel: widget.activateLabel,
                      activatedLabel: widget.activatedLabel,
                      activatedIcon: widget.activatedIcon,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DiscountBadge extends StatelessWidget {
  final String label;
  final BankThemeData bankTheme;

  const _DiscountBadge({required this.label, required this.bankTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: BankTokens.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        border: Border.all(
          color: BankTokens.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: BankTokens.labelSmall.copyWith(color: BankTokens.success),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final BankPerk perk;
  final BankThemeData bankTheme;
  final VoidCallback? onActivate;
  final Color accent;
  final String activateLabel;
  final String activatedLabel;
  final IconData? activatedIcon;

  const _ActionRow({
    required this.perk,
    required this.bankTheme,
    required this.onActivate,
    required this.accent,
    required this.activateLabel,
    required this.activatedLabel,
    required this.activatedIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (perk.isActivated) {
      return Semantics(
        label: 'Perk activated',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activatedIcon ?? Icons.check_circle,
              size: 16,
              color: BankTokens.success,
            ),
            const SizedBox(width: BankTokens.space1),
            Text(
              activatedLabel,
              style: BankTokens.labelMedium.copyWith(
                color: BankTokens.success,
              ),
            ),
          ],
        ),
      );
    }

    if (onActivate != null) {
      return Semantics(
        button: true,
        label: 'Activate ${perk.title}',
        child: SizedBox(
          height: BankTokens.minTapTarget,
          child: FilledButton(
            onPressed: onActivate,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: bankTheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: bankTheme.buttonRadius,
              ),
            ),
            child: Text(
              activateLabel,
              style: BankTokens.labelLarge.copyWith(
                color: bankTheme.onPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
