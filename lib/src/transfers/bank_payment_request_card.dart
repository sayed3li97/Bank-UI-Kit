import 'package:flutter/material.dart';

import '../../src/common/bank_surface_depth.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Incoming money-request card with accept or decline actions.
class BankPaymentRequestCard extends StatelessWidget {
  final String requesterId;
  final String requesterName;
  final String? requesterAvatarUrl;
  final Money amount;
  final String? note;
  final DateTime requestedAt;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Overrides the card content padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to the theme cardRadius.
  final BorderRadius? radius;

  /// Overrides the card background color. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Legacy depth opt-out. The card renders the kit shadow language
  /// ([BankTokens.shadowCardFor] of the theme background brightness) instead
  /// of Material elevation; pass `0` — or use a theme whose `elevationLow`
  /// is `0`, such as Voltage — to flatten the card to hairline-only depth.
  final double? elevation;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCardFor] of
  /// the theme background brightness; pass `const []` to flatten.
  final List<BoxShadow>? shadow;

  /// Overrides the card outline. Defaults on dark surfaces to a
  /// [BankTokens.hairlineWidth] hairline in [BankTokens.hairlineColor];
  /// light surfaces keep an invisible border of the same width. Pass
  /// `const Border()` to remove it.
  final BoxBorder? border;

  /// Replaces the requester avatar. Defaults to a [CircleAvatar] built from
  /// [requesterAvatarUrl] or the requester's initial.
  final Widget? leading;

  /// Merged over the requester name style
  /// (BankTokens.labelLarge in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the connector text style
  /// (BankTokens.bodyMedium in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the amount style (BankTokens.labelLarge in warning).
  final TextStyle? amountStyle;

  /// Merged over the note style (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? noteStyle;

  /// Merged over the timestamp style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? timestampStyle;

  /// Connector word between the requester name and the amount.
  /// Defaults to `'requests'`.
  final String requestsLabel;

  /// Label of the accept button. Defaults to `'Accept'`.
  final String acceptLabel;

  /// Label of the decline button. Defaults to `'Decline'`.
  final String declineLabel;

  /// Overrides the accept button background. Defaults to BankTokens.success.
  final Color? acceptColor;

  /// Replaces the built-in relative "time ago" formatting of [requestedAt].
  /// Defaults to the built-in English formatter.
  final String Function(DateTime requestedAt)? timestampFormatter;

  /// When non-null, wraps the card in a [Semantics] label. Defaults to no
  /// extra semantics node.
  final String? semanticLabel;

  const BankPaymentRequestCard({
    required this.requesterId,
    required this.requesterName,
    required this.amount,
    required this.requestedAt,
    required this.onAccept,
    required this.onDecline,
    super.key,
    this.requesterAvatarUrl,
    this.note,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.elevation,
    this.shadow,
    this.border,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.amountStyle,
    this.noteStyle,
    this.timestampStyle,
    this.requestsLabel = 'requests',
    this.acceptLabel = 'Accept',
    this.declineLabel = 'Decline',
    this.acceptColor,
    this.timestampFormatter,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final formatted = BankMoneyFormatter.format(
      amount: amount.amount,
      currencyCode: amount.currencyCode,
      numeralStyle: scope.numeralStyle,
    );

    // Privacy mode substitutes the scope's masked label for the amount.
    final displayAmount =
        scope.privacyEnabled ? scope.strings.balanceHidden : formatted;

    final timeAgo =
        timestampFormatter?.call(requestedAt) ?? _timeAgo(requestedAt);

    final resolvedPadding = padding ?? const EdgeInsets.all(BankTokens.space4);

    // One depth language for every card: token shadows resolved against the
    // theme background brightness, with the dark-surface hairline. Themes
    // that declare flat depth (elevationLow == 0, e.g. Voltage) — or an
    // explicit `elevation: 0` — keep hairline-only separation. The margin
    // preserves the footprint of the Material [Card] this replaces.
    final depth = BankSurfaceDepth.resolve(
      theme,
      surfaceColor: backgroundColor,
      shadow: shadow,
      border: border,
      tier: (elevation ?? theme.elevationLow) <= 0
          ? BankSurfaceDepthTier.flat
          : BankSurfaceDepthTier.card,
    );

    final card = Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: radius ?? theme.cardRadius,
        color: backgroundColor ?? theme.surface,
        boxShadow: depth.shadow,
        border: depth.border,
      ),
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leading ??
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.surfaceVariant,
                      backgroundImage: requesterAvatarUrl != null
                          ? BankUiScope.imageProviderFor(
                              context,
                              requesterAvatarUrl!,
                            )
                          : null,
                      child: requesterAvatarUrl == null
                          ? Text(
                              requesterName.isNotEmpty
                                  ? requesterName[0].toUpperCase()
                                  : '?',
                              style: BankTokens.labelLarge
                                  .copyWith(color: theme.primary),
                            )
                          : null,
                    ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$requesterName ',
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onSurface)
                              .merge(titleStyle),
                        ),
                        TextSpan(
                          text: '$requestsLabel ',
                          style: BankTokens.bodyMedium
                              .copyWith(color: theme.onSurfaceVariant)
                              .merge(subtitleStyle),
                        ),
                        TextSpan(
                          text: displayAmount,
                          style: BankTokens.labelLarge
                              .copyWith(color: BankTokens.warning)
                              .merge(amountStyle),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: BankTokens.space2),
              Text(
                note!,
                style: BankTokens.bodySmall
                    .copyWith(color: theme.onSurfaceVariant)
                    .merge(noteStyle),
              ),
            ],
            const SizedBox(height: BankTokens.space1),
            Text(
              timeAgo,
              style: BankTokens.bodySmall
                  .copyWith(color: theme.onSurfaceVariant)
                  .merge(timestampStyle),
            ),
            const SizedBox(height: BankTokens.space4),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: acceptColor ?? BankTokens.success,
                      ),
                      child: Text(acceptLabel),
                    ),
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onDecline,
                      child: Text(declineLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, child: card);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
