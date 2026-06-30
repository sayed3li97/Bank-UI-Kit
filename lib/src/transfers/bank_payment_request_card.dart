import 'package:flutter/material.dart';

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

  const BankPaymentRequestCard({
    super.key,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    required this.amount,
    this.note,
    required this.requestedAt,
    required this.onAccept,
    required this.onDecline,
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

    final timeAgo = _timeAgo(requestedAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      color: theme.surface,
      elevation: theme.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(BankTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.surfaceVariant,
                  backgroundImage: requesterAvatarUrl != null
                      ? NetworkImage(requesterAvatarUrl!)
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
                              .copyWith(color: theme.onSurface),
                        ),
                        TextSpan(
                          text: 'requests ',
                          style: BankTokens.bodyMedium
                              .copyWith(color: theme.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: formatted,
                          style: BankTokens.labelLarge.copyWith(
                            color: BankTokens.warning,
                          ),
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
                    .copyWith(color: theme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: BankTokens.space1),
            Text(
              timeAgo,
              style:
                  BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
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
                        backgroundColor: BankTokens.success,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
