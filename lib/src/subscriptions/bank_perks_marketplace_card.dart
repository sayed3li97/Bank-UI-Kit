import 'package:flutter/material.dart';

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

  const BankPerksMarketplaceCard({
    required this.perk,
    super.key,
    this.onActivate,
    this.onTap,
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
    if (diff.isNegative) return 'Expired';
    if (diff.inDays == 0) return 'Expires today';
    if (diff.inDays == 1) return 'Expires tomorrow';
    if (diff.inDays <= 30) return 'Expires in ${diff.inDays} days';
    final months = (diff.inDays / 30).round();
    return 'Expires in $months month${months == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final perk = widget.perk;

    final expiryText =
        perk.expiresAt != null ? _formatExpiry(perk.expiresAt!) : '';
    final isExpired =
        perk.expiresAt != null && perk.expiresAt!.isBefore(DateTime.now());

    Widget logoWidget;
    if (perk.logoUrl != null && !_logoFailed) {
      logoWidget = CircleAvatar(
        radius: 24,
        backgroundColor: bankTheme.surfaceVariant,
        backgroundImage: NetworkImage(perk.logoUrl!),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _logoFailed = true);
        },
      );
    } else {
      logoWidget = CircleAvatar(
        radius: 24,
        backgroundColor: bankTheme.primary.withValues(alpha: 0.12),
        child: Text(
          _initials(perk.partnerName),
          style: BankTokens.labelMedium.copyWith(color: bankTheme.primary),
        ),
      );
    }

    final semanticLabel = '${perk.partnerName}: ${perk.title}. '
        '${perk.discountLabel != null ? '${perk.discountLabel!}. ' : ''}'
        '${expiryText.isNotEmpty ? '$expiryText. ' : ''}'
        '${perk.isActivated ? 'Activated.' : 'Not activated.'}';

    return Semantics(
      label: semanticLabel,
      button: widget.onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bankTheme.surface,
          borderRadius: bankTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: bankTheme.cardRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: bankTheme.cardRadius,
            splashColor: bankTheme.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space4),
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
                              style: BankTokens.bodySmall.copyWith(
                                color: bankTheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Perk title
                            Text(
                              perk.title,
                              style: BankTokens.labelLarge.copyWith(
                                color: bankTheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Description
                            Text(
                              perk.description,
                              style: BankTokens.bodySmall.copyWith(
                                color: bankTheme.onSurfaceVariant,
                              ),
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

  const _ActionRow({
    required this.perk,
    required this.bankTheme,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    if (perk.isActivated) {
      return Semantics(
        label: 'Perk activated',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 16, color: BankTokens.success),
            const SizedBox(width: BankTokens.space1),
            Text(
              'Activated',
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
              backgroundColor: bankTheme.primary,
              foregroundColor: bankTheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: bankTheme.buttonRadius,
              ),
            ),
            child: Text(
              'Activate',
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
