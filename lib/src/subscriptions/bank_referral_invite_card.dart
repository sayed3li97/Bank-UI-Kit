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

  const BankReferralInviteCard({
    required this.referralCode,
    super.key,
    this.rewardDescription,
    this.referralCount = 0,
    this.maxReferrals,
    this.state = BankReferralState.pending,
    this.onShare,
    this.onCopyCode,
  });

  bool get _isExpired => state == BankReferralState.expired;
  bool get _isRewarded => state == BankReferralState.rewarded;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final cardBg = bankTheme.primary.withValues(alpha: 0.08);
    final contentColor =
        _isExpired ? bankTheme.onSurfaceVariant : bankTheme.onSurface;

    final semanticLabel = 'Referral invite card. Code: $referralCode. '
        '${rewardDescription ?? ''}. '
        '$referralCount friend${referralCount == 1 ? '' : 's'} invited. '
        'Status: ${state.name}.';

    return Semantics(
      label: semanticLabel,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: bankTheme.cardRadius,
              border: Border.all(
                color: _isExpired
                    ? bankTheme.outline.withValues(alpha: 0.3)
                    : bankTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(BankTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heading row
                Row(
                  children: [
                    Icon(
                      BankIcons.gift,
                      size: 22,
                      color: _isExpired
                          ? bankTheme.onSurfaceVariant
                          : bankTheme.primary,
                    ),
                    const SizedBox(width: BankTokens.space2),
                    Text(
                      'Invite Friends',
                      style: BankTokens.headlineSmall.copyWith(
                        color: contentColor,
                      ),
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
                ),

                const SizedBox(height: BankTokens.space3),

                // Referral count label
                Text(
                  _countLabel,
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
                          BankIcons.share,
                          size: 18,
                          color: bankTheme.onPrimary,
                        ),
                        label: Text(
                          'Share Invite',
                          style: BankTokens.labelLarge.copyWith(
                            color: bankTheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: bankTheme.primary,
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
                child: _RewardedOverlay(bankTheme: bankTheme),
              ),
            ),

          // Expired overlay
          if (_isExpired)
            Positioned.fill(
              child: IgnorePointer(
                child: _ExpiredOverlay(bankTheme: bankTheme),
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

  const _ReferralCodeBox({
    required this.code,
    required this.bankTheme,
    required this.isExpired,
    required this.onCopyCode,
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
              style: BankTokens.numeralMedium.copyWith(
                fontFamily: 'monospace',
                color: isExpired
                    ? bankTheme.onSurfaceVariant
                    : bankTheme.onSurface,
                letterSpacing: 2,
              ),
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
                    Icons.copy_outlined,
                    size: 20,
                    color: isExpired
                        ? bankTheme.onSurfaceVariant
                        : bankTheme.primary,
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

  const _RewardedOverlay({required this.bankTheme});

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
              const Icon(Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'Rewarded',
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

  const _ExpiredOverlay({required this.bankTheme});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Offer expired',
      child: Container(
        decoration: BoxDecoration(
          color: bankTheme.surface.withValues(alpha: 0.75),
          borderRadius: bankTheme.cardRadius,
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
            'Offer Expired',
            style: BankTokens.labelLarge.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
