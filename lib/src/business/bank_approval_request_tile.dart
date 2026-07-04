import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_emblem.dart';
import '../common/bank_text_field.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Where a [BankApprovalRequest] sits in the maker-checker workflow.
enum BankApprovalState { pending, approvedByMe, approved, rejected, expired }

/// A pending item in a business-banking approval queue.
class BankApprovalRequest {
  const BankApprovalRequest({
    required this.id,
    required this.title,
    required this.requesterName,
    required this.requestedAt,
    required this.approvalsRequired,
    required this.approvalsGiven,
    required this.state,
    this.amount,
    this.requesterAvatarUrl,
    this.approverNames = const <String>[],
    this.rejectionReason,
  });

  final String id;

  /// e.g. `'Payment to Acme Ltd'`.
  final String title;

  final String requesterName;
  final DateTime requestedAt;

  /// Total approvals needed (e.g. 3 in a 3-eyes policy).
  final int approvalsRequired;

  /// Approvals collected so far.
  final int approvalsGiven;

  final BankApprovalState state;
  final Money? amount;
  final String? requesterAvatarUrl;
  final List<String> approverNames;
  final String? rejectionReason;
}

/// Maker-checker approval queue row for business banking.
///
/// Shows the requester emblem, title, relative request time, optional
/// amount, and a segmented approval-progress element ("2 of 3
/// approvals"). When the viewer can act, inline Approve / Reject
/// buttons appear: Reject collects a mandatory reason in a bottom
/// sheet. Async actions disable both buttons with an inline spinner.
///
/// ```dart
/// BankApprovalRequestTile(
///   request: request,
///   onApprove: () => api.approve(request.id),
///   onReject: (reason) => api.reject(request.id, reason),
/// )
/// ```
class BankApprovalRequestTile extends StatefulWidget {
  const BankApprovalRequestTile({
    required this.request,
    super.key,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.canAct = true,
    this.requestedByPrefix = 'Requested by',
    this.approveLabel = 'Approve',
    this.rejectLabel = 'Reject',
    this.approvalsTemplate = '{given} of {required} approvals',
    this.youApprovedLabel = 'You approved',
    this.rejectedLabel = 'Rejected',
    this.rejectReasonTitle = 'Reason for rejection',
    this.rejectReasonHint = 'Explain why this request is rejected',
    this.rejectSubmitLabel = 'Reject request',
    this.padding,
    this.accentColor,
    this.approvedIcon = Icons.check_rounded,
    this.titleStyle,
    this.subtitleStyle,
    this.progressStyle,
    this.semanticLabel,
  });

  final BankApprovalRequest request;

  final VoidCallback? onTap;

  /// Approves on the backend; return `true` on success.
  final Future<bool> Function()? onApprove;

  /// Rejects with the collected reason; return `true` on success.
  final Future<bool> Function(String reason)? onReject;

  /// Whether the viewer holds an approver role for this request.
  final bool canAct;

  final String requestedByPrefix;
  final String approveLabel;
  final String rejectLabel;

  /// `{given}` and `{required}` are substituted.
  final String approvalsTemplate;

  final String youApprovedLabel;
  final String rejectedLabel;
  final String rejectReasonTitle;
  final String rejectReasonHint;
  final String rejectSubmitLabel;

  /// Overrides the tile content padding. Defaults to
  /// `EdgeInsetsDirectional.symmetric(horizontal: space4, vertical: space3)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the color of filled approval-progress segments and the
  /// "you approved" check. Defaults to the theme positiveBalance.
  final Color? accentColor;

  /// Glyph shown in the "you approved" row. Defaults to
  /// [Icons.check_rounded].
  final IconData approvedIcon;

  /// Merged over the title style (BankTokens.bodyLarge in onSurface).
  final TextStyle? titleStyle;

  /// Merged over the requested-by line style
  /// (BankTokens.bodySmall in onSurfaceVariant).
  final TextStyle? subtitleStyle;

  /// Merged over the approval-progress label style
  /// (BankTokens.labelSmall in onSurfaceVariant).
  final TextStyle? progressStyle;

  /// Overrides the composed Semantics label. Defaults to the title,
  /// requested-by line, and approval-progress label.
  final String? semanticLabel;

  @override
  State<BankApprovalRequestTile> createState() =>
      _BankApprovalRequestTileState();
}

class _BankApprovalRequestTileState extends State<BankApprovalRequestTile> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await widget.onApprove!();
    } on Object {
      // Host surfaces failures; the row simply re-enables.
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reject() async {
    final theme = BankThemeData.of(context);
    final controller = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: theme.sheetRadius),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: BankTokens.space4,
          right: BankTokens.space4,
          top: BankTokens.space4,
          bottom:
              MediaQuery.viewInsetsOf(sheetContext).bottom + BankTokens.space4,
        ),
        child: _RejectReasonForm(
          controller: controller,
          title: widget.rejectReasonTitle,
          hint: widget.rejectReasonHint,
          submitLabel: widget.rejectSubmitLabel,
          theme: theme,
        ),
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onReject!(reason.trim());
    } on Object {
      // Host surfaces failures; the row simply re-enables.
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final request = widget.request;

    final progressLabel = widget.approvalsTemplate
        .replaceAll('{given}', '${request.approvalsGiven}')
        .replaceAll('{required}', '${request.approvalsRequired}');
    final requestedLine = '${widget.requestedByPrefix} '
        '${request.requesterName} · '
        '${BankDateFormatter.formatRelative(request.requestedAt)}';

    final expired = request.state == BankApprovalState.expired;
    final showButtons = widget.canAct &&
        request.state == BankApprovalState.pending &&
        (widget.onApprove != null || widget.onReject != null);

    return Opacity(
      opacity: expired ? 0.4 : 1,
      child: Semantics(
        button: widget.onTap != null,
        label: widget.semanticLabel ??
            '${request.title}, $requestedLine, $progressLabel',
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: widget.padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BankEmblem(
                      imageUrl: request.requesterAvatarUrl,
                      initialsFrom: request.requesterName,
                    ),
                    const SizedBox(width: BankTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: BankTokens.bodyLarge
                                .copyWith(color: theme.onSurface)
                                .merge(widget.titleStyle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            requestedLine,
                            style: BankTokens.bodySmall
                                .copyWith(color: theme.onSurfaceVariant)
                                .merge(widget.subtitleStyle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (request.amount != null) ...[
                      const SizedBox(width: BankTokens.space2),
                      BankBalanceText(
                        money: request.amount!,
                        size: BankBalanceSize.small,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BankTokens.space3),
                Row(
                  children: [
                    for (var i = 0; i < request.approvalsRequired; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i < request.approvalsGiven
                                ? (widget.accentColor ?? theme.positiveBalance)
                                : theme.surfaceVariant,
                            borderRadius: theme.chipRadius,
                          ),
                          child: const SizedBox(width: 20, height: 5),
                        ),
                      ),
                    const SizedBox(width: BankTokens.space2),
                    Text(
                      progressLabel,
                      style: BankTokens.labelSmall
                          .copyWith(color: theme.onSurfaceVariant)
                          .merge(widget.progressStyle),
                    ),
                  ],
                ),
                if (request.state == BankApprovalState.rejected &&
                    request.rejectionReason != null) ...[
                  const SizedBox(height: BankTokens.space2),
                  Text(
                    '${widget.rejectedLabel}: ${request.rejectionReason}',
                    style:
                        BankTokens.bodySmall.copyWith(color: BankTokens.danger),
                  ),
                ],
                if (request.state == BankApprovalState.approvedByMe) ...[
                  const SizedBox(height: BankTokens.space2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.approvedIcon,
                        size: 14,
                        color: widget.accentColor ?? theme.positiveBalance,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.youApprovedLabel,
                        style: BankTokens.labelMedium.copyWith(
                          color: widget.accentColor ?? theme.positiveBalance,
                        ),
                      ),
                    ],
                  ),
                ],
                if (showButtons) ...[
                  const SizedBox(height: BankTokens.space3),
                  Row(
                    children: [
                      if (widget.onApprove != null)
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _busy ? null : _approve,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  theme.positiveBalance.withValues(alpha: 0.12),
                              foregroundColor: theme.positiveBalance,
                              shape: RoundedRectangleBorder(
                                borderRadius: theme.buttonRadius,
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.approveLabel,
                                    style: BankTokens.labelLarge,
                                  ),
                          ),
                        ),
                      if (widget.onApprove != null && widget.onReject != null)
                        const SizedBox(width: BankTokens.space3),
                      if (widget.onReject != null)
                        TextButton(
                          onPressed: _busy ? null : _reject,
                          child: Text(
                            widget.rejectLabel,
                            style: BankTokens.labelLarge
                                .copyWith(color: BankTokens.danger),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RejectReasonForm extends StatefulWidget {
  const _RejectReasonForm({
    required this.controller,
    required this.title,
    required this.hint,
    required this.submitLabel,
    required this.theme,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final String submitLabel;
  final BankThemeData theme;

  @override
  State<_RejectReasonForm> createState() => _RejectReasonFormState();
}

class _RejectReasonFormState extends State<_RejectReasonForm> {
  bool _valid = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style:
              BankTokens.headlineSmall.copyWith(color: widget.theme.onSurface),
        ),
        const SizedBox(height: BankTokens.space3),
        BankTextField(
          controller: widget.controller,
          hint: widget.hint,
          maxLines: 3,
          autofocus: true,
          onChanged: (text) => setState(() => _valid = text.trim().isNotEmpty),
        ),
        const SizedBox(height: BankTokens.space4),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(widget.controller.text)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: BankTokens.danger,
            foregroundColor: const Color(0xFFFFFFFF),
            minimumSize: const Size.fromHeight(BankTokens.space12),
            shape: RoundedRectangleBorder(
              borderRadius: widget.theme.buttonRadius,
            ),
          ),
          child: Text(widget.submitLabel, style: BankTokens.labelLarge),
        ),
      ],
    );
  }
}
