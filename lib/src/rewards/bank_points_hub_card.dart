import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// A single quick action rendered as a pill inside [BankPointsHubCard].
///
/// Typical actions are Redeem, Gift cards, Donate, and Invest. The [id] is
/// passed back through `BankPointsHubCard.onAction` when the pill is tapped.
@immutable
class BankPointsAction {
  /// Stable identifier reported to `BankPointsHubCard.onAction`.
  final String id;

  /// User-facing label of the action pill.
  final String label;

  /// Icon shown before the label. Prefer entries from [BankIcons]
  /// (e.g. [BankIcons.gift]) where a fitting one exists.
  final IconData icon;

  /// Creates an immutable action descriptor for [BankPointsHubCard].
  const BankPointsAction({
    required this.id,
    required this.label,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankPointsAction &&
        other.id == id &&
        other.label == label &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(id, label, icon);

  @override
  String toString() => 'BankPointsAction(id: $id, label: $label)';
}

/// Loyalty points hero card: the entry point of a rewards programme hub.
///
/// Shows the member's points balance in hero numerals with
/// [NumeralStyle]-aware digit grouping, an optional cash-equivalent line,
/// an optional earn-rate microtext, a warning chip when a batch of points
/// is about to expire, and a row of action pills (Redeem, Gift cards,
/// Donate, Invest, or whatever [actions] you provide).
///
/// The loyalty points hub pattern found in leading banking apps.
///
/// The points balance and the cash-value line are masked when privacy mode
/// is active on the ambient [BankUiScope], mirroring how account balances
/// behave across the kit. All colours, radii, spacing, and text styles come
/// from [BankThemeData] and [BankTokens].
///
/// ```dart
/// BankPointsHubCard(
///   pointsBalance: 12450,
///   cashValueLabel: '= SAR 42.50',
///   earnRateLabel: '1 point per SAR 4',
///   expiringPoints: 500,
///   expiringOn: DateTime(2026, 8, 1),
///   actions: const [
///     BankPointsAction(
///       id: 'redeem',
///       label: 'Redeem',
///       icon: Icons.redeem_outlined,
///     ),
///     BankPointsAction(
///       id: 'gift_cards',
///       label: 'Gift cards',
///       icon: BankIcons.gift,
///     ),
///     BankPointsAction(
///       id: 'donate',
///       label: 'Donate',
///       icon: Icons.volunteer_activism_outlined,
///     ),
///     BankPointsAction(
///       id: 'invest',
///       label: 'Invest',
///       icon: BankIcons.investment,
///     ),
///   ],
///   onAction: (String actionId) => debugPrint('tapped $actionId'),
/// )
/// ```
class BankPointsHubCard extends StatelessWidget {
  /// Current points balance, rendered in hero numerals with locale-style
  /// digit grouping converted to the active [NumeralStyle].
  final int pointsBalance;

  /// Quick actions rendered as icon + label pills below the balance.
  /// Pass an empty list to hide the action row entirely.
  final List<BankPointsAction> actions;

  /// Unit label shown next to the balance, e.g. `'points'` or `'miles'`.
  final String pointsLabel;

  /// Optional preformatted cash equivalent, e.g. `'= SAR 42.50'`.
  /// Masked together with the balance when privacy mode is active.
  final String? cashValueLabel;

  /// Optional earn-rate microtext, e.g. `'1 point per SAR 4'`.
  final String? earnRateLabel;

  /// Number of points in the batch that expires next. The expiry chip is
  /// shown only when both this and [expiringOn] are provided and this
  /// value is greater than zero.
  final int? expiringPoints;

  /// Date on which [expiringPoints] expire.
  final DateTime? expiringOn;

  /// Called with the tapped action's [BankPointsAction.id]. When `null`,
  /// the action pills render in a disabled state.
  final void Function(String actionId)? onAction;

  /// Verb inserted in the expiry chip between the points count and the
  /// date, e.g. `'500 points expire 1 Aug'`. Override to localise.
  final String expireVerbLabel;

  /// Creates a loyalty points hero card.
  const BankPointsHubCard({
    required this.pointsBalance,
    required this.actions,
    super.key,
    this.pointsLabel = 'points',
    this.cashValueLabel,
    this.earnRateLabel,
    this.expiringPoints,
    this.expiringOn,
    this.onAction,
    this.expireVerbLabel = 'expire',
  });

  String _formatPoints(int value, NumeralStyle numeralStyle) =>
      numeralStyle.convert(NumberFormat.decimalPattern().format(value));

  bool get _hasExpiryChip =>
      expiringPoints != null && expiringPoints! > 0 && expiringOn != null;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final hidden = scope.privacyEnabled;

    final formattedBalance = _formatPoints(pointsBalance, scope.numeralStyle);
    final displayBalance =
        hidden ? scope.strings.balanceHidden : formattedBalance;

    return Semantics(
      container: true,
      label: hidden
          ? 'Points balance hidden'
          : 'Points balance: $formattedBalance $pointsLabel',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: theme.cardRadius,
          boxShadow: BankTokens.shadowCard,
        ),
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  displayBalance,
                  style: theme.numeralHero.copyWith(color: theme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: BankTokens.space1),
              ExcludeSemantics(child: _buildUnitLine(theme, hidden)),
              if (earnRateLabel != null) ...[
                const SizedBox(height: BankTokens.space2),
                Text(
                  earnRateLabel!,
                  style: BankTokens.bodySmall
                      .copyWith(color: theme.onSurfaceVariant),
                ),
              ],
              if (_hasExpiryChip) ...[
                const SizedBox(height: BankTokens.space3),
                _buildExpiryChip(theme, scope.numeralStyle),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: BankTokens.space4),
                Wrap(
                  spacing: BankTokens.space2,
                  runSpacing: BankTokens.space2,
                  children: [
                    for (final action in actions)
                      _ActionPill(action: action, onAction: onAction),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitLine(BankThemeData theme, bool hidden) {
    final cashValue = cashValueLabel;
    return Wrap(
      spacing: BankTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          pointsLabel,
          style: BankTokens.bodyMedium.copyWith(color: theme.onSurfaceVariant),
        ),
        if (cashValue != null && !hidden)
          Text(
            cashValue,
            style: BankTokens.labelMedium.copyWith(color: theme.primary),
          ),
      ],
    );
  }

  Widget _buildExpiryChip(BankThemeData theme, NumeralStyle numeralStyle) {
    final count = _formatPoints(expiringPoints!, numeralStyle);
    final date = numeralStyle.convert(
      BankDateFormatter.formatShort(expiringOn!),
    );
    final message = '$count $pointsLabel $expireVerbLabel $date';

    return Semantics(
      label: message,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BankTokens.warning.withValues(alpha: 0.12),
            borderRadius: theme.chipRadius,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space3,
              vertical: BankTokens.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  BankIcons.warning,
                  size: 16,
                  color: BankTokens.warning,
                ),
                const SizedBox(width: BankTokens.space2),
                Flexible(
                  child: Text(
                    message,
                    style: BankTokens.labelMedium
                        .copyWith(color: BankTokens.warning),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + label pill that fires `onAction` with its action id.
class _ActionPill extends StatelessWidget {
  final BankPointsAction action;
  final void Function(String actionId)? onAction;

  const _ActionPill({
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final enabled = onAction != null;
    const pillRadius = BorderRadius.all(
      Radius.circular(BankTokens.radiusFull),
    );

    final foreground = enabled
        ? theme.onSurface
        : theme.onSurfaceVariant.withValues(alpha: 0.6);
    final iconColor =
        enabled ? theme.primary : theme.onSurfaceVariant.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      child: Material(
        color: theme.surfaceVariant,
        borderRadius: pillRadius,
        child: InkWell(
          onTap: enabled ? () => onAction!(action.id) : null,
          borderRadius: pillRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BankTokens.minTapTarget,
              minWidth: BankTokens.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 18, color: iconColor),
                  const SizedBox(width: BankTokens.space2),
                  ExcludeSemantics(
                    child: Text(
                      action.label,
                      style: BankTokens.labelMedium.copyWith(color: foreground),
                    ),
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
