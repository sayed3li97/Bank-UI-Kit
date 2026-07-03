import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankRecurringPattern
// ---------------------------------------------------------------------------

/// How often a recurring payment repeats.
///
/// This is the canonical recurrence enum for the kit's scheduled-payment
/// surfaces (the transfer-timing toggle exposes the same options as plain
/// strings; use [BankRecurringPattern.label] to bridge between the two).
enum BankRecurringPattern {
  /// Repeats every day.
  daily('Daily'),

  /// Repeats every 7 days.
  weekly('Weekly'),

  /// Repeats every 14 days.
  biweekly('Biweekly'),

  /// Repeats once a month on the same day-of-month (clamped to the last
  /// day of shorter months).
  monthly('Monthly');

  const BankRecurringPattern(this.label);

  /// English display label, e.g. `'Monthly'`.
  final String label;

  /// Returns the occurrence that follows [date] for this pattern.
  DateTime nextOccurrenceAfter(DateTime date) => switch (this) {
        BankRecurringPattern.daily => date.add(const Duration(days: 1)),
        BankRecurringPattern.weekly => date.add(const Duration(days: 7)),
        BankRecurringPattern.biweekly => date.add(const Duration(days: 14)),
        BankRecurringPattern.monthly => _addOneMonth(date),
      };

  static DateTime _addOneMonth(DateTime date) {
    final year = date.month == 12 ? date.year + 1 : date.year;
    final month = date.month == 12 ? 1 : date.month + 1;
    final lastDayOfTarget = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfTarget ? lastDayOfTarget : date.day;
    return DateTime(year, month, day, date.hour, date.minute);
  }
}

// ---------------------------------------------------------------------------
// BankStandingOrderState
// ---------------------------------------------------------------------------

/// Lifecycle state of a [BankStandingOrder].
enum BankStandingOrderState {
  /// Runs on schedule.
  active,

  /// Temporarily paused by the customer; no payments are executed.
  paused,

  /// The last execution failed (e.g. insufficient funds).
  failed,
}

// ---------------------------------------------------------------------------
// BankStandingOrder
// ---------------------------------------------------------------------------

/// Immutable description of a recurring/scheduled payment instruction.
@immutable
class BankStandingOrder {
  /// Unique identifier of the standing order.
  final String id;

  /// Display name of the payee receiving the payments.
  final String payeeName;

  /// The amount transferred on every run.
  final Money amount;

  /// How often the order repeats.
  final BankRecurringPattern pattern;

  /// The date the next payment is scheduled to run.
  final DateTime nextRunDate;

  /// Current lifecycle state of the order.
  final BankStandingOrderState state;

  /// Optional avatar image URL for the payee.
  final String? avatarUrl;

  /// Optional date after which the order stops running.
  final DateTime? endDate;

  const BankStandingOrder({
    required this.id,
    required this.payeeName,
    required this.amount,
    required this.pattern,
    required this.nextRunDate,
    this.state = BankStandingOrderState.active,
    this.avatarUrl,
    this.endDate,
  });

  /// Returns a copy with the given fields replaced.
  BankStandingOrder copyWith({
    String? id,
    String? payeeName,
    Money? amount,
    BankRecurringPattern? pattern,
    DateTime? nextRunDate,
    BankStandingOrderState? state,
    String? avatarUrl,
    DateTime? endDate,
  }) =>
      BankStandingOrder(
        id: id ?? this.id,
        payeeName: payeeName ?? this.payeeName,
        amount: amount ?? this.amount,
        pattern: pattern ?? this.pattern,
        nextRunDate: nextRunDate ?? this.nextRunDate,
        state: state ?? this.state,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        endDate: endDate ?? this.endDate,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankStandingOrder &&
        other.id == id &&
        other.payeeName == payeeName &&
        other.amount == amount &&
        other.pattern == pattern &&
        other.nextRunDate == nextRunDate &&
        other.state == state &&
        other.avatarUrl == avatarUrl &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
        id,
        payeeName,
        amount,
        pattern,
        nextRunDate,
        state,
        avatarUrl,
        endDate,
      );
}

// ---------------------------------------------------------------------------
// BankStandingOrderTile
// ---------------------------------------------------------------------------

/// Manager row for a recurring/scheduled payment ([BankStandingOrder]).
///
/// Shows an initials avatar, the payee name with a
/// `'Monthly · next 1 Jul'` summary line, and the amount on the trailing
/// edge (rendered with [BankBalanceText], so privacy mode masks it).
///
/// State treatment:
/// - **Paused** orders render at 40% opacity with a pending-coloured
///   `'Paused'` chip.
/// - **Failed** orders show a danger chip plus an inline retry button that
///   fires [onResume].
///
/// A long-press — or the trailing overflow button — opens a bottom action
/// sheet with pause/resume, skip-next (confirmation dialog) and cancel
/// (destructive, confirmation dialog). Confirming skip-next fires
/// [onSkipNext] and optimistically advances the displayed date to the
/// following occurrence.
///
/// Actions whose callbacks are `null` are omitted from the sheet; when no
/// actions are available the overflow button is hidden.
///
/// ```dart
/// BankStandingOrderTile(
///   order: BankStandingOrder(
///     id: 'so-1',
///     payeeName: 'Acme Lettings',
///     amount: Money.fromDouble(1250, 'GBP'),
///     pattern: BankRecurringPattern.monthly,
///     nextRunDate: DateTime(2026, 7, 1),
///   ),
///   onTap: _openDetail,
///   onPause: _pause,
///   onResume: _resume,
///   onSkipNext: _skipNext,
///   onCancel: _cancel,
/// )
/// ```
class BankStandingOrderTile extends StatefulWidget {
  /// The standing order to display.
  final BankStandingOrder order;

  /// Called when the row body is tapped.
  final VoidCallback? onTap;

  /// Called when the user chooses "Pause" from the action sheet.
  final VoidCallback? onPause;

  /// Called when the user chooses "Resume", or taps the inline retry
  /// button of a failed order.
  final VoidCallback? onResume;

  /// Called after the user confirms skipping the next payment.
  final VoidCallback? onSkipNext;

  /// Called after the user confirms cancelling the standing order.
  final VoidCallback? onCancel;

  /// Chip label shown on paused orders.
  final String pausedLabel;

  /// Chip label shown on failed orders.
  final String failedLabel;

  /// Tooltip/semantics label for the inline retry button.
  final String retryLabel;

  /// Action-sheet label for pausing the order.
  final String pauseActionLabel;

  /// Action-sheet label for resuming the order.
  final String resumeActionLabel;

  /// Action-sheet label for skipping the next payment.
  final String skipNextActionLabel;

  /// Action-sheet label for cancelling the order.
  final String cancelActionLabel;

  /// Title of the skip-next confirmation dialog.
  final String skipConfirmTitle;

  /// Body text of the skip-next confirmation dialog.
  final String skipConfirmMessage;

  /// Title of the cancel confirmation dialog.
  final String cancelConfirmTitle;

  /// Body text of the cancel confirmation dialog.
  final String cancelConfirmMessage;

  /// Label of the confirming button in both dialogs.
  final String confirmActionLabel;

  /// Label of the dismissing button in both dialogs.
  final String dismissActionLabel;

  const BankStandingOrderTile({
    required this.order,
    super.key,
    this.onTap,
    this.onPause,
    this.onResume,
    this.onSkipNext,
    this.onCancel,
    this.pausedLabel = 'Paused',
    this.failedLabel = 'Failed',
    this.retryLabel = 'Retry payment',
    this.pauseActionLabel = 'Pause',
    this.resumeActionLabel = 'Resume',
    this.skipNextActionLabel = 'Skip next payment',
    this.cancelActionLabel = 'Cancel standing order',
    this.skipConfirmTitle = 'Skip next payment?',
    this.skipConfirmMessage =
        'The next scheduled payment will be skipped. Later payments stay '
            'on schedule.',
    this.cancelConfirmTitle = 'Cancel standing order?',
    this.cancelConfirmMessage =
        'This permanently stops all future payments to this payee.',
    this.confirmActionLabel = 'Confirm',
    this.dismissActionLabel = 'Go back',
  });

  @override
  State<BankStandingOrderTile> createState() => _BankStandingOrderTileState();
}

class _BankStandingOrderTileState extends State<BankStandingOrderTile> {
  /// Set after a confirmed skip-next so the row optimistically shows the
  /// occurrence after the skipped one, until the host rebuilds with fresh
  /// data.
  DateTime? _optimisticNextRun;

  BankStandingOrder get _order => widget.order;

  DateTime get _effectiveNextRun => _optimisticNextRun ?? _order.nextRunDate;

  bool get _hasSheetActions =>
      _pauseAvailable ||
      _resumeAvailable ||
      _skipAvailable ||
      widget.onCancel != null;

  bool get _pauseAvailable =>
      widget.onPause != null && _order.state == BankStandingOrderState.active;

  bool get _resumeAvailable =>
      widget.onResume != null && _order.state != BankStandingOrderState.active;

  bool get _skipAvailable =>
      widget.onSkipNext != null &&
      _order.state == BankStandingOrderState.active;

  @override
  void didUpdateWidget(BankStandingOrderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.nextRunDate != oldWidget.order.nextRunDate) {
      _optimisticNextRun = null;
    }
  }

  String get _initials {
    final parts = _order.payeeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  Future<void> _openActionSheet() async {
    final bankTheme = BankThemeData.of(context);

    final action = await showModalBottomSheet<_TileAction>(
      context: context,
      backgroundColor: bankTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: bankTheme.sheetRadius),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandleBar(),
            const SizedBox(height: BankTokens.space2),
            if (_pauseAvailable)
              _SheetActionRow(
                icon: Icons.pause_circle_outline,
                label: widget.pauseActionLabel,
                onTap: () => Navigator.of(sheetContext).pop(_TileAction.pause),
              ),
            if (_resumeAvailable)
              _SheetActionRow(
                icon: Icons.play_circle_outline,
                label: widget.resumeActionLabel,
                onTap: () => Navigator.of(sheetContext).pop(_TileAction.resume),
              ),
            if (_skipAvailable)
              _SheetActionRow(
                icon: Icons.skip_next_outlined,
                label: widget.skipNextActionLabel,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_TileAction.skipNext),
              ),
            if (widget.onCancel != null)
              _SheetActionRow(
                icon: Icons.delete_outline,
                label: widget.cancelActionLabel,
                destructive: true,
                onTap: () => Navigator.of(sheetContext).pop(_TileAction.cancel),
              ),
            const SizedBox(height: BankTokens.space2),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case _TileAction.pause:
        widget.onPause?.call();
      case _TileAction.resume:
        widget.onResume?.call();
      case _TileAction.skipNext:
        await _confirmSkipNext();
      case _TileAction.cancel:
        await _confirmCancel();
    }
  }

  Future<void> _confirmSkipNext() async {
    final confirmed = await _showConfirmDialog(
      title: widget.skipConfirmTitle,
      message: widget.skipConfirmMessage,
      destructive: false,
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _optimisticNextRun =
          _order.pattern.nextOccurrenceAfter(_order.nextRunDate);
    });
    widget.onSkipNext?.call();
  }

  Future<void> _confirmCancel() async {
    final confirmed = await _showConfirmDialog(
      title: widget.cancelConfirmTitle,
      message: widget.cancelConfirmMessage,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    widget.onCancel?.call();
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required bool destructive,
  }) {
    final bankTheme = BankThemeData.of(context);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bankTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: bankTheme.cardRadius),
        title: Text(
          title,
          style: BankTokens.headlineSmall.copyWith(color: bankTheme.onSurface),
        ),
        content: Text(
          message,
          style:
              BankTokens.bodyMedium.copyWith(color: bankTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(widget.dismissActionLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  destructive ? BankTokens.danger : bankTheme.primary,
              foregroundColor: bankTheme.onPrimary,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
            ),
            child: Text(widget.confirmActionLabel),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  Widget _fadeIfPaused(Widget child) =>
      _order.state == BankStandingOrderState.paused
          ? Opacity(opacity: 0.4, child: child)
          : child;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    final isFailed = _order.state == BankStandingOrderState.failed;
    final isPaused = _order.state == BankStandingOrderState.paused;

    final nextDateText = BankDateFormatter.formatShort(_effectiveNextRun);
    final scheduleText = '${_order.pattern.label} · next $nextDateText';

    final stateSuffix = isPaused
        ? ', ${widget.pausedLabel}'
        : isFailed
            ? ', ${widget.failedLabel}'
            : '';

    return Semantics(
      button: widget.onTap != null,
      label: 'Standing order to ${_order.payeeName}, '
          '$scheduleText$stateSuffix',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: _hasSheetActions ? _openActionSheet : null,
          borderRadius: bankTheme.cardRadius,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BankTokens.minTapTarget,
              ),
              child: Row(
                children: [
                  _fadeIfPaused(
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: bankTheme.surfaceVariant,
                      backgroundImage: _order.avatarUrl != null
                          ? NetworkImage(_order.avatarUrl!)
                          : null,
                      child: _order.avatarUrl == null
                          ? Text(
                              _initials,
                              style: BankTokens.labelLarge
                                  .copyWith(color: bankTheme.primary),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: _fadeIfPaused(
                                Text(
                                  _order.payeeName,
                                  style: BankTokens.labelLarge
                                      .copyWith(color: bankTheme.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (isPaused) ...[
                              const SizedBox(width: BankTokens.space2),
                              _StatusChip(
                                label: widget.pausedLabel,
                                color: bankTheme.pending,
                                chipRadius: bankTheme.chipRadius,
                              ),
                            ],
                            if (isFailed) ...[
                              const SizedBox(width: BankTokens.space2),
                              _StatusChip(
                                label: widget.failedLabel,
                                color: BankTokens.danger,
                                chipRadius: bankTheme.chipRadius,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: BankTokens.space1),
                        _fadeIfPaused(
                          Text(
                            scheduleText,
                            style: BankTokens.bodySmall.copyWith(
                              color: bankTheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  _fadeIfPaused(
                    BankBalanceText(
                      money: _order.amount,
                      size: BankBalanceSize.medium,
                    ),
                  ),
                  if (isFailed && widget.onResume != null)
                    IconButton(
                      onPressed: widget.onResume,
                      tooltip: widget.retryLabel,
                      icon: const Icon(Icons.refresh),
                      color: BankTokens.danger,
                      constraints: const BoxConstraints(
                        minWidth: BankTokens.minTapTarget,
                        minHeight: BankTokens.minTapTarget,
                      ),
                    ),
                  if (_hasSheetActions)
                    IconButton(
                      onPressed: _openActionSheet,
                      tooltip: 'More actions',
                      icon: const Icon(Icons.more_vert),
                      color: bankTheme.onSurfaceVariant,
                      constraints: const BoxConstraints(
                        minWidth: BankTokens.minTapTarget,
                        minHeight: BankTokens.minTapTarget,
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

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

enum _TileAction { pause, resume, skipNext, cancel }

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.chipRadius,
  });

  final String label;
  final Color color;
  final BorderRadius chipRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1,
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: color),
        ),
      ),
    );
  }
}

class _SheetHandleBar extends StatelessWidget {
  const _SheetHandleBar();

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BankTokens.space2),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: bankTheme.outline,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
          ),
        ),
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final color = destructive ? BankTokens.danger : bankTheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: BankTokens.minTapTarget,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Text(
                  label,
                  style: BankTokens.bodyLarge.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
