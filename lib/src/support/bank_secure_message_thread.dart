import 'package:flutter/material.dart';

import '../common/bank_emblem.dart';
import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Who authored a [BankMessage].
enum BankMessageAuthor { customer, bank, system }

/// Delivery lifecycle of an outgoing [BankMessage].
enum BankMessageDeliveryState { sending, sent, delivered, read, failed }

/// Upload state of a [BankMessageAttachment].
enum BankAttachmentState { uploading, ready, failed }

/// A file attached to a secure message.
class BankMessageAttachment {
  const BankMessageAttachment({
    required this.id,
    required this.fileName,
    this.sizeBytes,
    this.state = BankAttachmentState.ready,
    this.uploadProgress,
  });

  final String id;
  final String fileName;
  final int? sizeBytes;
  final BankAttachmentState state;

  /// 0..1 while [BankAttachmentState.uploading]; indeterminate if null.
  final double? uploadProgress;
}

/// One message in a secure-inbox conversation.
class BankMessage {
  const BankMessage({
    required this.id,
    required this.body,
    required this.sentAt,
    required this.author,
    this.authorName,
    this.attachments = const <BankMessageAttachment>[],
    this.deliveryState = BankMessageDeliveryState.sent,
  });

  final String id;
  final String body;
  final DateTime sentAt;
  final BankMessageAuthor author;
  final String? authorName;
  final List<BankMessageAttachment> attachments;
  final BankMessageDeliveryState deliveryState;
}

/// Secure-messaging conversation view: customer bubbles trailing in a
/// primary tint, bank bubbles leading with an emblem, centered system
/// microcopy, date separators, delivery ticks on the last own message,
/// failed-send retry, attachment chips with upload progress, and an
/// async composer that hides its attach affordance when [onAttach] is
/// null.
///
/// ```dart
/// BankSecureMessageThread(
///   messages: thread,
///   onSend: (text) => api.sendSecureMessage(threadId, text),
///   bannerText: 'Replies within 1 business day',
/// )
/// ```
class BankSecureMessageThread extends StatefulWidget {
  const BankSecureMessageThread({
    required this.messages,
    required this.onSend,
    super.key,
    this.onAttach,
    this.onAttachmentTap,
    this.onRetry,
    this.composerEnabled = true,
    this.typingIndicator,
    this.scrollController,
    this.bannerText,
    this.composerHint = 'Write a message',
    this.sendLabel = 'Send',
    this.retryLabel = 'Tap to retry',
    this.bankName = 'Support',
    this.todayLabel = 'Today',
    this.yesterdayLabel = 'Yesterday',
    this.youLabel = 'You',
    this.padding,
    this.accentColor,
    this.bannerBackgroundColor,
    this.customerBubbleColor,
    this.bankBubbleColor,
    this.inputBackgroundColor,
    this.bubbleRadius,
    this.messageStyle,
    this.timestampStyle,
    this.bannerIcon,
    this.attachIcon,
    this.sendIcon,
    this.attachmentIcon,
    this.sendingIcon,
    this.sentIcon,
    this.deliveredIcon,
    this.readIcon,
    this.failedIcon,
  });

  /// Newest message LAST (chronological order).
  final List<BankMessage> messages;

  /// Sends the composed text; return `true` on success. The message is
  /// shown optimistically in the sending state while awaiting.
  final Future<bool> Function(String text) onSend;

  /// Shows the attach affordance when set; host opens its own picker.
  final VoidCallback? onAttach;

  final void Function(String attachmentId)? onAttachmentTap;

  /// Fired when the failed-send retry link is tapped.
  final void Function(String messageId)? onRetry;

  final bool composerEnabled;

  /// Slot rendered under the newest message (e.g. a typing indicator).
  final Widget? typingIndicator;

  final ScrollController? scrollController;

  /// Pinned info banner, e.g. `'Replies within 1 business day'`.
  final String? bannerText;

  final String composerHint;
  final String sendLabel;
  final String retryLabel;

  /// Fallback display name for bank-authored messages.
  final String bankName;

  /// Date-separator label for today. Defaults to `'Today'`.
  final String todayLabel;

  /// Date-separator label for yesterday. Defaults to `'Yesterday'`.
  final String yesterdayLabel;

  /// Screen-reader name for customer-authored messages. Defaults to
  /// `'You'`.
  final String youLabel;

  /// Overrides the message-list padding. Defaults to
  /// `EdgeInsets.all(BankTokens.space4)`.
  final EdgeInsetsGeometry? padding;

  /// Overrides the accent used for the banner icon and send button.
  /// Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the info-banner fill. Defaults to the accent at 8%
  /// alpha.
  final Color? bannerBackgroundColor;

  /// Overrides the customer bubble fill. Defaults to the theme primary
  /// at 12% alpha.
  final Color? customerBubbleColor;

  /// Overrides the bank bubble fill. Defaults to the theme
  /// surfaceVariant.
  final Color? bankBubbleColor;

  /// Overrides the composer field fill. Defaults to the theme
  /// surfaceVariant.
  final Color? inputBackgroundColor;

  /// Overrides the large bubble corner radius. Defaults to the theme
  /// sheetRadius corner.
  final Radius? bubbleRadius;

  /// Merged over the message body style (BankTokens.bodyMedium in
  /// onSurface).
  final TextStyle? messageStyle;

  /// Merged over the timestamp style (BankTokens.labelSmall in
  /// onSurfaceVariant).
  final TextStyle? timestampStyle;

  /// Glyph inside the pinned banner. Defaults to [BankIcons.info].
  final IconData? bannerIcon;

  /// Glyph of the attach affordance. Defaults to
  /// [Icons.attach_file_rounded].
  final IconData? attachIcon;

  /// Glyph of the send button. Defaults to
  /// [Icons.arrow_upward_rounded].
  final IconData? sendIcon;

  /// Glyph on attachment chips. Defaults to [BankIcons.document].
  final IconData? attachmentIcon;

  /// Delivery tick while sending. Defaults to [Icons.schedule_rounded].
  final IconData? sendingIcon;

  /// Delivery tick once sent. Defaults to [Icons.check_rounded].
  final IconData? sentIcon;

  /// Delivery tick once delivered. Defaults to
  /// [Icons.done_all_rounded].
  final IconData? deliveredIcon;

  /// Delivery tick once read. Defaults to [Icons.done_all_rounded].
  final IconData? readIcon;

  /// Delivery glyph for failed sends. Defaults to
  /// [Icons.error_outline_rounded].
  final IconData? failedIcon;

  @override
  State<BankSecureMessageThread> createState() =>
      _BankSecureMessageThreadState();
}

class _BankSecureMessageThreadState extends State<BankSecureMessageThread> {
  final TextEditingController _composer = TextEditingController();
  bool _sending = false;
  String _pendingText = '';

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _pendingText = text;
      _composer.clear();
    });
    var succeeded = false;
    try {
      succeeded = await widget.onSend(text);
    } on Object {
      succeeded = false;
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (!succeeded) _composer.text = _pendingText;
      _pendingText = '';
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = widget.accentColor ?? theme.primary;

    String? lastOwnId;
    for (final message in widget.messages.reversed) {
      if (message.author == BankMessageAuthor.customer) {
        lastOwnId = message.id;
        break;
      }
    }

    return Column(
      children: [
        if (widget.bannerText != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: widget.bannerBackgroundColor ??
                  accent.withValues(alpha: 0.08),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
                vertical: BankTokens.space2,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.bannerIcon ?? BankIcons.info,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Expanded(
                    child: Text(
                      widget.bannerText!,
                      style:
                          BankTokens.bodySmall.copyWith(color: theme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            reverse: true,
            padding: widget.padding ?? const EdgeInsets.all(BankTokens.space4),
            itemCount: widget.messages.length +
                (widget.typingIndicator == null ? 0 : 1),
            itemBuilder: (context, reversedIndex) {
              if (widget.typingIndicator != null && reversedIndex == 0) {
                return widget.typingIndicator!;
              }
              final offset = widget.typingIndicator == null ? 0 : 1;
              final index =
                  widget.messages.length - 1 - (reversedIndex - offset);
              final message = widget.messages[index];
              final showDate = index == 0 ||
                  !_sameDay(
                    message.sentAt,
                    widget.messages[index - 1].sentAt,
                  );

              return Column(
                children: [
                  if (showDate)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: BankTokens.space3,
                      ),
                      child: Text(
                        BankDateFormatter.formatGroupHeader(
                          date: message.sentAt,
                          todayLabel: widget.todayLabel,
                          yesterdayLabel: widget.yesterdayLabel,
                        ),
                        style: BankTokens.labelSmall
                            .copyWith(color: theme.onSurfaceVariant),
                      ),
                    ),
                  _MessageBubble(
                    message: message,
                    isLastOwn: message.id == lastOwnId,
                    theme: theme,
                    host: widget,
                    onRetry: widget.onRetry,
                    onAttachmentTap: widget.onAttachmentTap,
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space3,
              BankTokens.space2,
              BankTokens.space3,
              BankTokens.space3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.onAttach != null)
                  IconButton(
                    onPressed: widget.composerEnabled ? widget.onAttach : null,
                    icon: Icon(
                      widget.attachIcon ?? Icons.attach_file_rounded,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    enabled: widget.composerEnabled && !_sending,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    style:
                        BankTokens.bodyLarge.copyWith(color: theme.onSurface),
                    decoration: InputDecoration(
                      hintText: widget.composerHint,
                      hintStyle: BankTokens.bodyLarge
                          .copyWith(color: theme.onSurfaceVariant),
                      filled: true,
                      fillColor:
                          widget.inputBackgroundColor ?? theme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: BankTokens.space4,
                        vertical: BankTokens.space2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: theme.buttonRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                Semantics(
                  button: true,
                  label: widget.sendLabel,
                  child: IconButton.filled(
                    onPressed: _composer.text.trim().isEmpty || _sending
                        ? null
                        : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: theme.surfaceVariant,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.sendIcon ?? Icons.arrow_upward_rounded,
                            color: theme.onPrimary,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isLastOwn,
    required this.theme,
    required this.host,
    required this.onRetry,
    required this.onAttachmentTap,
  });

  final BankMessage message;
  final bool isLastOwn;
  final BankThemeData theme;
  final BankSecureMessageThread host;
  final void Function(String messageId)? onRetry;
  final void Function(String attachmentId)? onAttachmentTap;

  static String _formatBytes(int bytes) {
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000000) return '${(bytes / 1000).toStringAsFixed(0)} KB';
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }

  IconData get _deliveryIcon => switch (message.deliveryState) {
        BankMessageDeliveryState.sending =>
          host.sendingIcon ?? Icons.schedule_rounded,
        BankMessageDeliveryState.sent => host.sentIcon ?? Icons.check_rounded,
        BankMessageDeliveryState.delivered =>
          host.deliveredIcon ?? Icons.done_all_rounded,
        BankMessageDeliveryState.read =>
          host.readIcon ?? Icons.done_all_rounded,
        BankMessageDeliveryState.failed =>
          host.failedIcon ?? Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (message.author == BankMessageAuthor.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
        child: Text(
          message.body,
          textAlign: TextAlign.center,
          style: BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant),
        ),
      );
    }

    final isCustomer = message.author == BankMessageAuthor.customer;
    final failed = message.deliveryState == BankMessageDeliveryState.failed;
    final cornerRadius = host.bubbleRadius ?? theme.sheetRadius.topLeft;

    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: isCustomer
            ? host.customerBubbleColor ?? theme.primary.withValues(alpha: 0.12)
            : host.bankBubbleColor ?? theme.surfaceVariant,
        borderRadius: BorderRadiusDirectional.only(
          topStart: cornerRadius,
          topEnd: cornerRadius,
          bottomStart: isCustomer ? cornerRadius : const Radius.circular(4),
          bottomEnd: isCustomer ? const Radius.circular(4) : cornerRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space3,
          vertical: BankTokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: BankTokens.bodyMedium
                  .copyWith(color: theme.onSurface)
                  .merge(host.messageStyle),
            ),
            for (final attachment in message.attachments)
              Padding(
                padding: const EdgeInsets.only(top: BankTokens.space2),
                child: _AttachmentChip(
                  attachment: attachment,
                  theme: theme,
                  icon: host.attachmentIcon,
                  sizeText: attachment.sizeBytes == null
                      ? null
                      : _formatBytes(attachment.sizeBytes!),
                  onTap: onAttachmentTap,
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      liveRegion: !isCustomer,
      label:
          '${isCustomer ? host.youLabel : message.authorName ?? host.bankName}'
          ': ${message.body}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BankTokens.space1),
        child: Row(
          mainAxisAlignment:
              isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCustomer) ...[
              BankEmblem(
                initialsFrom: message.authorName ?? host.bankName,
                size: 28,
              ),
              const SizedBox(width: BankTokens.space2),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isCustomer
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  bubble,
                  if (isCustomer && (isLastOwn || failed))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: failed && onRetry != null
                          ? InkWell(
                              onTap: () => onRetry!(message.id),
                              child: Text(
                                host.retryLabel,
                                style: BankTokens.labelSmall
                                    .copyWith(color: BankTokens.danger),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  BankDateFormatter.formatTime(
                                    message.sentAt,
                                  ),
                                  style: BankTokens.labelSmall
                                      .copyWith(
                                        color: theme.onSurfaceVariant,
                                      )
                                      .merge(host.timestampStyle),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _deliveryIcon,
                                  size: 12,
                                  color: failed
                                      ? BankTokens.danger
                                      : message.deliveryState ==
                                              BankMessageDeliveryState.read
                                          ? theme.primary
                                          : theme.onSurfaceVariant,
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.attachment,
    required this.theme,
    required this.icon,
    required this.sizeText,
    required this.onTap,
  });

  final BankMessageAttachment attachment;
  final BankThemeData theme;
  final IconData? icon;
  final String? sizeText;
  final void Function(String attachmentId)? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(attachment.id),
      borderRadius: theme.chipRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: theme.chipRadius,
          border: Border.all(color: theme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BankTokens.space2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attachment.state == BankAttachmentState.failed
                        ? Icons.error_outline_rounded
                        : icon ?? BankIcons.document,
                    size: 16,
                    color: attachment.state == BankAttachmentState.failed
                        ? BankTokens.danger
                        : theme.primary,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Flexible(
                    child: Text(
                      attachment.fileName,
                      style: BankTokens.labelMedium
                          .copyWith(color: theme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sizeText != null) ...[
                    const SizedBox(width: BankTokens.space2),
                    Text(
                      sizeText!,
                      style: BankTokens.labelSmall
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              if (attachment.state == BankAttachmentState.uploading)
                Padding(
                  padding: const EdgeInsets.only(top: BankTokens.space1),
                  child: SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: theme.chipRadius,
                      child: LinearProgressIndicator(
                        value: attachment.uploadProgress,
                        minHeight: 3,
                        backgroundColor: theme.surfaceVariant,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
