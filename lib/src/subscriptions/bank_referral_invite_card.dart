import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------------

enum BankReferralState { pending, rewarded, expired }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Referral invite card with shareable code, reward description, and
/// pending / rewarded / expired state handling.
class BankReferralInviteCard extends StatelessWidget {
  final String referralCode;
  final String? rewardDescription;
  final int referralCount;
  final int? maxReferrals;
  final BankReferralState state;
  final VoidCallback? onShare;
  final VoidCallback? onCopyCode;

  /// Overrides the card content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to the accent at 8% alpha.
  final Color? backgroundColor;

  /// Overrides the accent used for the gift icon, card border, copy icon
  /// and share button. Defaults to the theme primary.
  final Color? accentColor;

  /// Merged over the heading style (BankTokens.headlineSmall).
  final TextStyle? titleStyle;

  /// Merged over the referral-code style (BankTokens.numeralMedium in
  /// monospace).
  final TextStyle? codeStyle;

  /// Card heading. Defaults to `'Invite Friends'`.
  final String title;

  /// Share button label. Defaults to `'Share Invite'`.
  final String shareLabel;

  /// Rewarded overlay badge text. Defaults to `'Rewarded'`.
  final String rewardedLabel;

  /// Expired overlay text. Defaults to `'Offer Expired'`.
  final String expiredLabel;

  /// Replaces the generated invite-count line
  /// (`'<n> friends invited [of <max>]'`). Supply for localisation.
  final String? countLabel;

  /// Glyph next to the heading. Defaults to [BankIcons.gift].
  final IconData? giftIcon;

  /// Glyph on the share button. Defaults to [BankIcons.share].
  final IconData? shareIcon;

  /// Glyph of the copy-code affordance. Defaults to
  /// [Icons.copy_outlined].
  final IconData? copyIcon;

  /// Glyph inside the rewarded badge. Defaults to [Icons.check_circle].
  final IconData? rewardedIcon;

  /// Overrides the generated card semantics label. Supply for
  /// non-English locales.
  final String? semanticLabel;

  const BankReferralInviteCard({
    required this.referralCode,
    super.key,
    this.rewardDescription,
    this.referralCount = 0,
    this.maxReferrals,
    this.state = BankReferralState.pending,
    this.onShare,
    this.onCopyCode,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.accentColor,
    this.titleStyle,
    this.codeStyle,
    this.title = 'Invite Friends',
    this.shareLabel = 'Share Invite',
    this.rewardedLabel = 'Rewarded',
    this.expiredLabel = 'Offer Expired',
    this.countLabel,
    this.giftIcon,
    this.shareIcon,
    this.copyIcon,
    this.rewardedIcon,
    this.semanticLabel,
  });

  bool get _isExpired => state == BankReferralState.expired;
  bool get _isRewarded => state == BankReferralState.rewarded;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final accent = accentColor ?? bankTheme.primary;
    final cardBg = backgroundColor ?? accent.withValues(alpha: 0.08);
    final cardRadius = radius ?? bankTheme.cardRadius;
    final contentColor =
        _isExpired ? bankTheme.onSurfaceVariant : bankTheme.onSurface;

    final resolvedSemanticLabel = semanticLabel ??
        'Referral invite card. Code: $referralCode. '
            '${rewardDescription ?? ''}. '
            '$referralCount friend${referralCount == 1 ? '' : 's'} invited. '
            'Status: ${state.name}.';

    return Semantics(
      label: resolvedSemanticLabel,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: cardRadius,
              border: Border.all(
                color: _isExpired
                    ? bankTheme.outline.withValues(alpha: 0.3)
                    : accent.withValues(alpha: 0.2),
              ),
            ),
            padding: padding ?? const EdgeInsets.all(BankTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heading row
                Row(
                  children: [
                    Icon(
                      giftIcon ?? BankIcons.gift,
                      size: 22,
                      color: _isExpired ? bankTheme.onSurfaceVariant : accent,
                    ),
                    const SizedBox(width: BankTokens.space2),
                    Text(
                      title,
                      style: BankTokens.headlineSmall
                          .copyWith(color: contentColor)
                          .merge(titleStyle),
                    ),
                  ],
                ),

                // Reward description
                if (rewardDescription != null) ...[
                  const SizedBox(height: BankTokens.space2),
                  Text(
                    rewardDescription!,
                    style: BankTokens.bodyMedium.copyWith(
                      color: _isExpired
                          ? bankTheme.onSurfaceVariant
                          : bankTheme.onSurface,
                    ),
                  ),
                ],

                const SizedBox(height: BankTokens.space4),

                // Referral code box
                _ReferralCodeBox(
                  code: referralCode,
                  bankTheme: bankTheme,
                  isExpired: _isExpired,
                  onCopyCode: onCopyCode,
                  accent: accent,
                  copyIcon: copyIcon,
                  codeStyle: codeStyle,
                ),

                const SizedBox(height: BankTokens.space3),

                // Referral count label
                Text(
                  countLabel ?? _countLabel,
                  style: BankTokens.bodySmall.copyWith(
                    color: bankTheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: BankTokens.space4),

                // Share button
                if (!_isExpired && onShare != null)
                  Semantics(
                    button: true,
                    label: 'Share referral code',
                    child: SizedBox(
                      height: BankTokens.minTapTarget,
                      child: FilledButton.icon(
                        onPressed: onShare,
                        icon: Icon(
                          shareIcon ?? BankIcons.share,
                          size: 18,
                          color: bankTheme.onPrimary,
                        ),
                        label: Text(
                          shareLabel,
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: bankTheme.onPrimary,
                          minimumSize: const Size(
                            double.infinity,
                            BankTokens.minTapTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: bankTheme.buttonRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Rewarded overlay badge
          if (_isRewarded)
            Positioned.fill(
              child: IgnorePointer(
                child: _RewardedOverlay(
                  bankTheme: bankTheme,
                  label: rewardedLabel,
                  icon: rewardedIcon,
                ),
              ),
            ),

          // Expired overlay
          if (_isExpired)
            Positioned.fill(
              child: IgnorePointer(
                child: _ExpiredOverlay(
                  bankTheme: bankTheme,
                  label: expiredLabel,
                  radius: cardRadius,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _countLabel {
    final friendWord = referralCount == 1 ? 'friend' : 'friends';
    final base = '$referralCount $friendWord invited';
    if (maxReferrals != null) {
      return '$base of $maxReferrals';
    }
    return base;
  }
}

// ---------------------------------------------------------------------------
// Referral code display
// ---------------------------------------------------------------------------

class _ReferralCodeBox extends StatelessWidget {
  final String code;
  final BankThemeData bankTheme;
  final bool isExpired;
  final VoidCallback? onCopyCode;
  final Color accent;
  final IconData? copyIcon;
  final TextStyle? codeStyle;

  const _ReferralCodeBox({
    required this.code,
    required this.bankTheme,
    required this.isExpired,
    required this.onCopyCode,
    required this.accent,
    required this.copyIcon,
    required this.codeStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space4,
        vertical: BankTokens.space3,
      ),
      decoration: BoxDecoration(
        color: bankTheme.surface,
        borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
        border: Border.all(
          color: bankTheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: BankTokens.numeralMedium
                  .copyWith(
                    fontFamily: 'monospace',
                    color: isExpired
                        ? bankTheme.onSurfaceVariant
                        : bankTheme.onSurface,
                    letterSpacing: 2,
                  )
                  .merge(codeStyle),
            ),
          ),
          Semantics(
            button: true,
            label: 'Copy referral code $code',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
              child: InkWell(
                onTap: isExpired
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: code));
                        onCopyCode?.call();
                      },
                borderRadius: BorderRadius.circular(BankTokens.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space2),
                  child: Icon(
                    copyIcon ?? Icons.copy_outlined,
                    size: 20,
                    color: isExpired ? bankTheme.onSurfaceVariant : accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State overlays
// ---------------------------------------------------------------------------

class _RewardedOverlay extends StatelessWidget {
  final BankThemeData bankTheme;
  final String label;
  final IconData? icon;

  const _RewardedOverlay({
    required this.bankTheme,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space3,
            vertical: BankTokens.space1,
          ),
          decoration: BoxDecoration(
            color: BankTokens.success,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: BankTokens.labelSmall.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiredOverlay extends StatelessWidget {
  final BankThemeData bankTheme;
  final String label;
  final BorderRadius radius;

  const _ExpiredOverlay({
    required this.bankTheme,
    required this.label,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Offer expired',
      child: Container(
        decoration: BoxDecoration(
          color: bankTheme.surface.withValues(alpha: 0.75),
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          decoration: BoxDecoration(
            color: bankTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            border: Border.all(
              color: bankTheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: BankTokens.labelLarge.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
