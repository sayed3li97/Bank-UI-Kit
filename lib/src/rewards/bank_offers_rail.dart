import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// An immutable card-linked merchant offer shown in a [BankOffersRail].
///
/// Mirrors the offer objects behind card-linked rewards programmes: a
/// merchant identity, a headline reward (for example
/// "5% back"), an optional expiry, and whether the customer has already
/// activated (added) the offer to their card.
@immutable
class BankMerchantOffer {
  /// Creates an immutable card-linked merchant offer.
  const BankMerchantOffer({
    required this.id,
    required this.merchantName,
    required this.rewardLabel,
    this.logoUrl,
    this.expiresAt,
    this.activated = false,
    this.terms,
  });

  /// Stable unique identifier, passed to activation callbacks.
  final String id;

  /// Merchant display name (for example "Blue Bottle Coffee").
  final String merchantName;

  /// Merchant logo URL; when null, initials derived from
  /// [merchantName] are shown instead.
  final String? logoUrl;

  /// Headline reward text, already localised (for example "5% back").
  final String rewardLabel;

  /// When the offer stops being redeemable, or null for no expiry.
  final DateTime? expiresAt;

  /// Whether the customer has already added this offer to their card.
  final bool activated;

  /// Optional fine print for a detail view; not rendered by the rail.
  final String? terms;

  /// Returns a copy of this offer with the given fields replaced.
  BankMerchantOffer copyWith({
    String? id,
    String? merchantName,
    String? logoUrl,
    String? rewardLabel,
    DateTime? expiresAt,
    bool? activated,
    String? terms,
  }) {
    return BankMerchantOffer(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      logoUrl: logoUrl ?? this.logoUrl,
      rewardLabel: rewardLabel ?? this.rewardLabel,
      expiresAt: expiresAt ?? this.expiresAt,
      activated: activated ?? this.activated,
      terms: terms ?? this.terms,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankMerchantOffer &&
        other.id == id &&
        other.merchantName == merchantName &&
        other.logoUrl == logoUrl &&
        other.rewardLabel == rewardLabel &&
        other.expiresAt == expiresAt &&
        other.activated == activated &&
        other.terms == terms;
  }

  @override
  int get hashCode => Object.hash(
        id,
        merchantName,
        logoUrl,
        rewardLabel,
        expiresAt,
        activated,
        terms,
      );

  @override
  String toString() => 'BankMerchantOffer('
      'id: $id, '
      'merchantName: $merchantName, '
      'activated: $activated'
      ')';
}

/// A horizontally scrolling rail of card-linked merchant offers that the
/// customer can activate in place.
///
/// The card-linked offers pattern of leading banking apps: place it
/// on a home or rewards screen to surface cashback
/// offers the customer can add to their card with a single tap.
///
/// Each 140 pt wide card shows a [BankEmblem] for the merchant, the
/// merchant name (two lines, ellipsised), [BankMerchantOffer.rewardLabel]
/// in the theme primary colour, an expiry microtext in
/// [BankTokens.warning] when fewer than seven days remain, and an
/// activation pill:
///
/// * Tapping the pill invokes [onActivate] and shows an inline spinner
///   while the returned future is pending.
/// * On success (`true`) the pill flips to a positive check plus
///   [activatedLabel] and stops being tappable.
/// * On failure (`false`, or a thrown error) the pill is restored and the
///   card shakes briefly to signal the problem (skipped when the ambient
///   [MediaQuery] reports that animations are disabled).
///
/// Tapping anywhere else on a card invokes [onTap] with the offer, for
/// example to open a detail sheet with [BankMerchantOffer.terms].
///
/// The rail renders nothing when [offers] is empty.
///
/// ```dart
/// BankOffersRail(
///   offers: offers,
///   onActivate: (offerId) => rewardsApi.activateOffer(offerId),
///   onTap: (offer) => showOfferDetails(context, offer),
/// )
/// ```
class BankOffersRail extends StatelessWidget {
  /// Creates a horizontally scrolling rail of activatable offers.
  const BankOffersRail({
    required this.offers,
    required this.onActivate,
    super.key,
    this.onTap,
    this.activateLabel = 'Activate',
    this.activatedLabel = 'Added',
    this.expiryLabelBuilder,
    this.height = 168,
  });

  /// The offers to render, in display order.
  final List<BankMerchantOffer> offers;

  /// Called when the customer taps an offer's activation pill.
  ///
  /// Return `true` when the offer was activated; `false` (or a thrown
  /// error) restores the pill and shakes the card.
  final Future<bool> Function(String offerId) onActivate;

  /// Called when the customer taps a card outside the activation pill.
  final void Function(BankMerchantOffer offer)? onTap;

  /// Label on the activation pill while the offer is not yet activated.
  final String activateLabel;

  /// Label on the pill once the offer has been activated.
  final String activatedLabel;

  /// Builds the expiry microtext from the whole days remaining
  /// (0 meaning the offer ends within the current day).
  ///
  /// Defaults to English: "Ends today", "1 day left", "N days left".
  final String Function(int daysLeft)? expiryLabelBuilder;

  /// Height of the rail in logical pixels.
  final double height;

  static String _defaultExpiryLabel(int daysLeft) {
    if (daysLeft <= 0) return 'Ends today';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: BankTokens.space3),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return _BankOfferCard(
            key: ValueKey<String>(offer.id),
            offer: offer,
            onActivate: onActivate,
            onTap: onTap,
            activateLabel: activateLabel,
            activatedLabel: activatedLabel,
            expiryLabelBuilder: expiryLabelBuilder ?? _defaultExpiryLabel,
          );
        },
      ),
    );
  }
}

/// A single offer card: emblem, merchant name, reward, expiry microtext,
/// and the async activation pill with spinner / success / shake states.
class _BankOfferCard extends StatefulWidget {
  const _BankOfferCard({
    required this.offer,
    required this.onActivate,
    required this.activateLabel,
    required this.activatedLabel,
    required this.expiryLabelBuilder,
    super.key,
    this.onTap,
  });

  final BankMerchantOffer offer;
  final Future<bool> Function(String offerId) onActivate;
  final void Function(BankMerchantOffer offer)? onTap;
  final String activateLabel;
  final String activatedLabel;
  final String Function(int daysLeft) expiryLabelBuilder;

  static const double _width = 140;

  @override
  State<_BankOfferCard> createState() => _BankOfferCardState();
}

class _BankOfferCardState extends State<_BankOfferCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: BankTokens.durationSlow,
  );

  late bool _activated = widget.offer.activated;
  bool _busy = false;

  @override
  void didUpdateWidget(_BankOfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.activated != widget.offer.activated) {
      _activated = widget.offer.activated;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool get _animationsDisabled =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Future<void> _handleActivate() async {
    if (_busy || _activated) return;
    setState(() => _busy = true);
    var succeeded = false;
    try {
      succeeded = await widget.onActivate(widget.offer.id);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _activated = succeeded;
    });
    if (!succeeded && !_animationsDisabled) {
      unawaited(_shakeController.forward(from: 0));
    }
  }

  /// Whole days until expiry, or null when there is no expiry, seven or
  /// more days remain, or the offer has already expired.
  int? get _daysLeft {
    final expiresAt = widget.offer.expiresAt;
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return null;
    final days = expiresAt.difference(now).inDays;
    return days < 7 ? days : null;
  }

  Widget _buildPill(BankThemeData theme) {
    final Widget content;
    if (_activated) {
      content = Row(
        key: const ValueKey<String>('activated'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: BankTokens.space4,
            color: theme.positiveBalance,
          ),
          const SizedBox(width: BankTokens.space1),
          Flexible(
            child: Text(
              widget.activatedLabel,
              style: BankTokens.labelMedium.copyWith(
                color: theme.positiveBalance,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (_busy) {
      content = SizedBox(
        key: const ValueKey<String>('busy'),
        width: BankTokens.space4,
        height: BankTokens.space4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
        ),
      );
    } else {
      content = Text(
        widget.activateLabel,
        key: const ValueKey<String>('idle'),
        style: BankTokens.labelMedium.copyWith(color: theme.onPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final pillColor = _activated
        ? theme.positiveBalance.withValues(alpha: 0.12)
        : theme.primary;

    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(BankTokens.radiusFull),
        ),
      ),
      child: SizedBox(
        height: BankTokens.minTapTarget,
        width: double.infinity,
        child: Center(
          child: AnimatedSwitcher(
            duration:
                _animationsDisabled ? Duration.zero : BankTokens.durationFast,
            switchInCurve: BankTokens.curveStandard,
            switchOutCurve: BankTokens.curveStandard,
            child: content,
          ),
        ),
      ),
    );

    final semanticsLabel = _activated
        ? '${widget.activatedLabel}: ${widget.offer.merchantName}'
        : '${widget.activateLabel}: ${widget.offer.merchantName}';

    return Semantics(
      button: !_activated,
      enabled: !_activated && !_busy,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: _activated || _busy ? null : _handleActivate,
          behavior: HitTestBehavior.opaque,
          child: pill,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final offer = widget.offer;
    final daysLeft = _daysLeft;

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BankEmblem(
              imageUrl: offer.logoUrl,
              initialsFrom: offer.merchantName,
              size: 32,
            ),
            const SizedBox(height: BankTokens.space2),
            Expanded(
              child: Text(
                offer.merchantName,
                style: BankTokens.labelMedium.copyWith(
                  color: theme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              offer.rewardLabel,
              style: BankTokens.labelLarge.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (daysLeft != null) ...[
              const SizedBox(height: BankTokens.space1),
              Text(
                widget.expiryLabelBuilder(daysLeft),
                style: BankTokens.labelSmall.copyWith(
                  color: BankTokens.warning,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: BankTokens.space2),
            _buildPill(theme),
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      card = Semantics(
        button: true,
        label: '${offer.merchantName}, ${offer.rewardLabel}',
        child: GestureDetector(
          onTap: () => widget.onTap!(offer),
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }

    return SizedBox(
      width: _BankOfferCard._width,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final t = _shakeController.value;
          final dx = math.sin(t * math.pi * 4) * (1 - t) * BankTokens.space2;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: child,
          );
        },
        child: card,
      ),
    );
  }
}
