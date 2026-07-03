import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_icon_spec.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The category of a recoverable-money discovery shown in a
/// [BankFoundMoneyList].
enum BankFoundMoneyKind {
  /// Money sitting in a dormant or forgotten account.
  dormantAccount,

  /// A refund the customer is owed but has not collected.
  refund,

  /// Loyalty or reward points convertible to cash value.
  points,

  /// An insurance payout or premium refund awaiting a claim.
  insurance,

  /// A returnable deposit (security, utility, or similar).
  deposit,
}

/// An immutable recoverable-money discovery rendered as one row of
/// [BankFoundMoneyList].
@immutable
class BankFoundMoneyItem {
  /// Unique identifier passed back through the claim callback.
  final String id;

  /// Short description, for example "Dormant account at First National".
  final String title;

  /// Optional supporting detail shown under [title].
  final String? subtitle;

  /// The recoverable amount.
  final Money amount;

  /// The discovery category, which drives the row's icon and tint.
  final BankFoundMoneyKind kind;

  /// Whether the item has already been claimed.
  final bool claimed;

  /// Creates a recoverable-money discovery.
  const BankFoundMoneyItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.kind,
    this.subtitle,
    this.claimed = false,
  });

  /// Returns a copy of this item with the given fields replaced.
  BankFoundMoneyItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    Money? amount,
    BankFoundMoneyKind? kind,
    bool? claimed,
  }) =>
      BankFoundMoneyItem(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        kind: kind ?? this.kind,
        subtitle: subtitle ?? this.subtitle,
        claimed: claimed ?? this.claimed,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankFoundMoneyItem &&
        other.id == id &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.amount == amount &&
        other.kind == kind &&
        other.claimed == claimed;
  }

  @override
  int get hashCode => Object.hash(id, title, subtitle, amount, kind, claimed);
}

/// A recoverable-money discovery list: a celebratory header summing every
/// unclaimed amount, followed by one row per [BankFoundMoneyItem] with an
/// asynchronous claim button.
///
/// Use it on an insights or "money finder" screen to surface dormant
/// accounts, refunds, convertible points, insurance payouts, and returnable
/// deposits the customer can recover. Amounts render through
/// [BankBalanceText], so privacy mode masks them automatically.
///
/// Tapping a row's claim pill invokes [onClaim] with the item's id and shows
/// an inline spinner. When the future resolves `true` the pill switches to a
/// positive [claimedLabel] state and the row fades to 60% opacity; when it
/// resolves `false` (or throws) the pill returns to a danger-tinted retry
/// state. All items are expected to share one currency.
///
/// ```dart
/// BankFoundMoneyList(
///   items: [
///     BankFoundMoneyItem(
///       id: 'dormant-1',
///       title: 'Dormant account at First National',
///       subtitle: 'No activity since 2021',
///       amount: Money.fromDouble(120.50, 'USD'),
///       kind: BankFoundMoneyKind.dormantAccount,
///     ),
///     BankFoundMoneyItem(
///       id: 'refund-7',
///       title: 'Overpaid utility refund',
///       amount: Money.fromDouble(36.20, 'USD'),
///       kind: BankFoundMoneyKind.refund,
///     ),
///   ],
///   onClaim: (id) => api.claimFoundMoney(id),
/// )
/// ```
class BankFoundMoneyList extends StatefulWidget {
  /// The discoveries to display, one row each.
  final List<BankFoundMoneyItem> items;

  /// Called with the item id when a claim pill is tapped. Return `true`
  /// when the claim succeeded; `false` keeps the row claimable.
  final Future<bool> Function(String id) onClaim;

  /// Header text; the `{total}` placeholder is replaced by the summed
  /// unclaimed amount rendered with [BankBalanceText].
  final String headerTemplate;

  /// Label on the claim pill of an unclaimed row.
  final String claimLabel;

  /// Label shown once a row has been claimed.
  final String claimedLabel;

  /// Creates a recoverable-money discovery list.
  const BankFoundMoneyList({
    required this.items,
    required this.onClaim,
    super.key,
    this.headerTemplate = 'We found {total} you can claim',
    this.claimLabel = 'Claim',
    this.claimedLabel = 'Claimed',
  });

  @override
  State<BankFoundMoneyList> createState() => _BankFoundMoneyListState();
}

class _BankFoundMoneyListState extends State<BankFoundMoneyList> {
  final Set<String> _claimedIds = <String>{};
  final Set<String> _pendingIds = <String>{};
  final Set<String> _failedIds = <String>{};

  bool _isClaimed(BankFoundMoneyItem item) =>
      item.claimed || _claimedIds.contains(item.id);

  Money get _unclaimedTotal {
    var total = Money.zero(widget.items.first.amount.currencyCode);
    for (final item in widget.items) {
      if (!_isClaimed(item)) {
        total = total + item.amount;
      }
    }
    return total;
  }

  Future<void> _handleClaim(String id) async {
    setState(() {
      _pendingIds.add(id);
      _failedIds.remove(id);
    });
    var success = false;
    try {
      success = await widget.onClaim(id);
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      _pendingIds.remove(id);
      if (success) {
        _claimedIds.add(id);
      } else {
        _failedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final theme = BankThemeData.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BankFoundMoneyHeader(
          total: _unclaimedTotal,
          template: widget.headerTemplate,
        ),
        const SizedBox(height: BankTokens.space3),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: theme.cardRadius,
            boxShadow: BankTokens.shadowCard,
          ),
          child: Column(
            children: [
              for (var i = 0; i < widget.items.length; i++) ...[
                _BankFoundMoneyRow(
                  item: widget.items[i],
                  claimed: _isClaimed(widget.items[i]),
                  pending: _pendingIds.contains(widget.items[i].id),
                  failed: _failedIds.contains(widget.items[i].id),
                  claimLabel: widget.claimLabel,
                  claimedLabel: widget.claimedLabel,
                  onClaim: () => _handleClaim(widget.items[i].id),
                ),
                if (i < widget.items.length - 1)
                  Divider(height: 1, thickness: 1, color: theme.outline),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _BankFoundMoneyHeader extends StatelessWidget {
  final Money total;
  final String template;

  const _BankFoundMoneyHeader({required this.total, required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final gradient = theme.accentGradient ??
        LinearGradient(colors: [theme.primary, theme.primaryVariant]);

    const placeholder = '{total}';
    final index = template.indexOf(placeholder);
    final before =
        (index >= 0 ? template.substring(0, index) : template).trim();
    final after =
        index >= 0 ? template.substring(index + placeholder.length).trim() : '';

    final textStyle = BankTokens.headlineSmall.copyWith(color: theme.onPrimary);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space5),
        child: Row(
          children: [
            Container(
              width: BankTokens.minTapTarget,
              height: BankTokens.minTapTarget,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.onPrimary.withValues(alpha: 0.16),
              ),
              child: Icon(
                Icons.celebration_outlined,
                size: 22,
                color: theme.onPrimary,
              ),
            ),
            const SizedBox(width: BankTokens.space4),
            Expanded(
              child: Wrap(
                spacing: BankTokens.space1,
                runSpacing: BankTokens.space1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (before.isNotEmpty) Text(before, style: textStyle),
                  if (index >= 0)
                    BankBalanceText(
                      money: total,
                      style:
                          theme.numeralLarge.copyWith(color: theme.onPrimary),
                    ),
                  if (after.isNotEmpty) Text(after, style: textStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Row
// -----------------------------------------------------------------------------

class _BankFoundMoneyRow extends StatelessWidget {
  final BankFoundMoneyItem item;
  final bool claimed;
  final bool pending;
  final bool failed;
  final String claimLabel;
  final String claimedLabel;
  final VoidCallback onClaim;

  const _BankFoundMoneyRow({
    required this.item,
    required this.claimed,
    required this.pending,
    required this.failed,
    required this.claimLabel,
    required this.claimedLabel,
    required this.onClaim,
  });

  static IconData _kindIcon(BankFoundMoneyKind kind) => switch (kind) {
        BankFoundMoneyKind.dormantAccount => BankIcons.account,
        BankFoundMoneyKind.refund => BankIcons.receipt,
        BankFoundMoneyKind.points => Icons.loyalty_outlined,
        BankFoundMoneyKind.insurance => BankIcons.shield,
        BankFoundMoneyKind.deposit => BankIcons.accountSavings,
      };

  static Color _kindColor(BankFoundMoneyKind kind, BankThemeData theme) =>
      switch (kind) {
        BankFoundMoneyKind.dormantAccount => theme.primary,
        BankFoundMoneyKind.refund => theme.positiveBalance,
        BankFoundMoneyKind.points => BankTokens.warning,
        BankFoundMoneyKind.insurance => theme.frozen,
        BankFoundMoneyKind.deposit => BankTokens.success,
      };

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final color = _kindColor(item.kind, theme);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return AnimatedOpacity(
      opacity: claimed ? 0.6 : 1,
      duration: disableAnimations ? Duration.zero : BankTokens.durationBase,
      curve: BankTokens.curveStandard,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(_kindIcon(item.kind), size: 20, color: color),
            ),
            const SizedBox(width: BankTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style:
                        BankTokens.labelLarge.copyWith(color: theme.onSurface),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: BankTokens.bodySmall
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BankBalanceText(
                  money: item.amount,
                  size: BankBalanceSize.medium,
                ),
                const SizedBox(height: BankTokens.space2),
                if (claimed)
                  _ClaimedPill(label: claimedLabel)
                else
                  _ClaimButton(
                    label: claimLabel,
                    itemTitle: item.title,
                    pending: pending,
                    failed: failed,
                    onPressed: onClaim,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Claim pill states
// -----------------------------------------------------------------------------

class _ClaimButton extends StatelessWidget {
  final String label;
  final String itemTitle;
  final bool pending;
  final bool failed;
  final VoidCallback onPressed;

  const _ClaimButton({
    required this.label,
    required this.itemTitle,
    required this.pending,
    required this.failed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Semantics(
      button: true,
      enabled: !pending,
      label: '$label: $itemTitle',
      child: ExcludeSemantics(
        child: SizedBox(
          height: BankTokens.minTapTarget,
          child: FilledButton(
            onPressed: pending ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: failed ? BankTokens.danger : theme.primary,
              foregroundColor: theme.onPrimary,
              minimumSize: const Size(72, BankTokens.minTapTarget),
              padding:
                  const EdgeInsets.symmetric(horizontal: BankTokens.space4),
              textStyle: BankTokens.labelMedium,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(BankTokens.radiusFull)),
              ),
            ),
            child: pending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.onSurfaceVariant,
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}

class _ClaimedPill extends StatelessWidget {
  final String label;

  const _ClaimedPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: BankTokens.minTapTarget,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.positiveBalance.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(
                Radius.circular(BankTokens.radiusFull),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: BankTokens.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    BankIcons.success,
                    size: 16,
                    color: theme.positiveBalance,
                  ),
                  const SizedBox(width: BankTokens.space1),
                  Text(
                    label,
                    style: BankTokens.labelMedium
                        .copyWith(color: theme.positiveBalance),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
