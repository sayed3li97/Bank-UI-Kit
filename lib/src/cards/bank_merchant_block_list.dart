import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankCategoryBlock model
// ---------------------------------------------------------------------------

/// A single merchant-category self-exclusion entry rendered by
/// [BankMerchantBlockList].
///
/// [unblockCoolOff] marks categories (typically gambling) whose unblock
/// takes effect only after a regulatory cool-off delay. While an unblock
/// is pending, [coolOffEndsAt] holds the moment the block actually lifts.
@immutable
class BankCategoryBlock {
  /// Creates an immutable category block entry.
  const BankCategoryBlock({
    required this.id,
    required this.label,
    required this.icon,
    required this.blocked,
    this.unblockCoolOff,
    this.coolOffEndsAt,
  });

  /// Stable identifier passed back through the change callback.
  final String id;

  /// Display name of the category, e.g. `'Gambling'`.
  final String label;

  /// Category glyph rendered on a tinted tile at the row start.
  final IconData icon;

  /// Whether spending in this category is currently blocked.
  final bool blocked;

  /// Delay before an unblock takes effect (e.g. 48 hours for gambling).
  /// `null` means unblocking is instant.
  final Duration? unblockCoolOff;

  /// When a confirmed unblock actually lifts. While this is in the
  /// future the row renders in a pending state.
  final DateTime? coolOffEndsAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankCategoryBlock &&
        other.id == id &&
        other.label == label &&
        other.icon == icon &&
        other.blocked == blocked &&
        other.unblockCoolOff == unblockCoolOff &&
        other.coolOffEndsAt == coolOffEndsAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, label, icon, blocked, unblockCoolOff, coolOffEndsAt);
}

// ---------------------------------------------------------------------------
// BankMerchantBlockList
// ---------------------------------------------------------------------------

/// Merchant-category self-exclusion controls (gambling blocks, category
/// blocks) in the style of the gambling blocks pioneered by digital
/// banks.
///
/// Each row shows the category icon on a tinted tile, its label, and a
/// [Switch]. Flipping a switch calls [onChanged] and shows an inline
/// spinner until the returned future completes; a `false` result or an
/// exception keeps the previous state and surfaces [errorLabel] in
/// [BankTokens.danger].
///
/// Blocking is always instant. Unblocking a row that declares
/// [BankCategoryBlock.unblockCoolOff] first asks for confirmation in a
/// dialog explaining the delay; once confirmed (and [onChanged] succeeds)
/// the row renders a pending state with [coolOffTemplate] until
/// [BankCategoryBlock.coolOffEndsAt] passes. Rows with a cool-off also
/// show [coolOffNoticeTemplate] permanently as helper text.
///
/// Every row announces its blocked state via [Semantics].
///
/// ```dart
/// BankMerchantBlockList(
///   blocks: const [
///     BankCategoryBlock(
///       id: 'gambling',
///       label: 'Gambling',
///       icon: Icons.casino_outlined,
///       blocked: true,
///       unblockCoolOff: Duration(hours: 48),
///     ),
///     BankCategoryBlock(
///       id: 'crypto',
///       label: 'Crypto exchanges',
///       icon: Icons.currency_bitcoin_outlined,
///       blocked: false,
///     ),
///   ],
///   onChanged: (id, blocked) => api.setCategoryBlock(id, blocked),
/// )
/// ```
class BankMerchantBlockList extends StatefulWidget {
  /// Creates a merchant-category block list.
  const BankMerchantBlockList({
    required this.blocks,
    required this.onChanged,
    super.key,
    this.title = 'Merchant blocks',
    this.coolOffTemplate = 'Takes effect {date}',
    this.coolOffNoticeTemplate = 'Unblocking has a {hours}h delay',
    this.unblockDialogTitleTemplate = 'Unblock {label}?',
    this.unblockDialogBodyTemplate =
        'For your protection this change is delayed. {label} payments '
            'stay blocked for {hours} more hours after you confirm.',
    this.unblockConfirmLabel = 'Unblock',
    this.unblockCancelLabel = 'Keep blocked',
    this.errorLabel = 'Could not update. Try again.',
    this.blockedSemanticLabel = 'blocked',
    this.allowedSemanticLabel = 'allowed',
    this.titlePadding,
    this.rowPadding,
    this.tileRadius,
    this.accentColor,
    this.pendingColor,
    this.titleStyle,
    this.labelStyle,
    this.helperStyle,
    this.dialogTitleStyle,
    this.dialogBodyStyle,
    this.pendingIcon,
    this.noticeIcon,
    this.errorIcon,
    this.rowMinHeight,
    this.semanticLabel,
  });

  /// The category rows to render, in order.
  final List<BankCategoryBlock> blocks;

  /// Persists a change. Return `true` on success, `false` to keep the
  /// previous state. Called with the row id and the requested blocked
  /// state; the row shows an inline spinner until it completes.
  final Future<bool> Function(String id, bool blocked) onChanged;

  /// Heading rendered above the rows.
  final String title;

  /// Pending-state helper text; `{date}` is replaced with the formatted
  /// [BankCategoryBlock.coolOffEndsAt].
  final String coolOffTemplate;

  /// Permanent helper text on rows with a cool-off; `{hours}` is
  /// replaced with the delay in whole hours.
  final String coolOffNoticeTemplate;

  /// Title of the unblock confirmation dialog; `{label}` is replaced
  /// with the row label.
  final String unblockDialogTitleTemplate;

  /// Body of the unblock confirmation dialog; `{label}` and `{hours}`
  /// placeholders are replaced.
  final String unblockDialogBodyTemplate;

  /// Confirm button label in the unblock dialog.
  final String unblockConfirmLabel;

  /// Cancel button label in the unblock dialog.
  final String unblockCancelLabel;

  /// Inline error helper shown when [onChanged] fails or throws.
  final String errorLabel;

  /// Semantics state announced for blocked rows.
  final String blockedSemanticLabel;

  /// Semantics state announced for unblocked rows.
  final String allowedSemanticLabel;

  /// Overrides the heading padding. Defaults to [BankTokens.space4] at
  /// the start, end, and top with [BankTokens.space2] below.
  final EdgeInsetsGeometry? titlePadding;

  /// Overrides each row's content padding. Defaults to
  /// [BankTokens.space4] horizontal by [BankTokens.space2] vertical.
  final EdgeInsetsGeometry? rowPadding;

  /// Overrides the tinted icon tile radius. Defaults to the theme
  /// chipRadius.
  final BorderRadius? tileRadius;

  /// Overrides the accent used by blocked tiles, switches, spinners,
  /// and the dialog confirm button. Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the cool-off pending color used by tiles, switches, and
  /// helper text. Defaults to the theme pending color.
  final Color? pendingColor;

  /// Merged over the heading style ([BankTokens.labelMedium] in the
  /// theme onSurfaceVariant color), so partial overrides work.
  final TextStyle? titleStyle;

  /// Merged over the row label style ([BankTokens.labelLarge] in the
  /// theme onSurface color).
  final TextStyle? labelStyle;

  /// Merged over the helper line style ([BankTokens.bodySmall] in the
  /// helper's state color).
  final TextStyle? helperStyle;

  /// Merged over the unblock dialog title style
  /// ([BankTokens.headlineSmall] in the theme onSurface color).
  final TextStyle? dialogTitleStyle;

  /// Merged over the unblock dialog body style ([BankTokens.bodyMedium]
  /// in the theme onSurfaceVariant color).
  final TextStyle? dialogBodyStyle;

  /// Overrides the cool-off pending helper glyph. Defaults to
  /// [BankIcons.schedule].
  final IconData? pendingIcon;

  /// Overrides the cool-off notice helper glyph. Defaults to
  /// [BankIcons.info].
  final IconData? noticeIcon;

  /// Overrides the error helper glyph. Defaults to [BankIcons.error].
  final IconData? errorIcon;

  /// Overrides each row's minimum height. Defaults to 56.
  final double? rowMinHeight;

  /// Semantics label wrapping the whole list. Defaults to none, keeping
  /// only the per-row semantics.
  final String? semanticLabel;

  @override
  State<BankMerchantBlockList> createState() => _BankMerchantBlockListState();
}

class _BankMerchantBlockListState extends State<BankMerchantBlockList> {
  /// Rows with an in-flight [BankMerchantBlockList.onChanged] call.
  final Set<String> _busyIds = <String>{};

  /// Rows whose last change attempt failed.
  final Set<String> _failedIds = <String>{};

  /// Locally confirmed states, kept until the host supplies new data.
  final Map<String, BankCategoryBlock> _overrides =
      <String, BankCategoryBlock>{};

  @override
  void didUpdateWidget(BankMerchantBlockList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.blocks, oldWidget.blocks)) {
      // The host is the source of truth: new data wins over local
      // optimistic overrides.
      _overrides.clear();
    }
  }

  BankCategoryBlock _effective(BankCategoryBlock block) =>
      _overrides[block.id] ?? block;

  Future<void> _handleToggle(BankCategoryBlock block, bool blocked) async {
    if (_busyIds.contains(block.id)) return;

    if (!blocked && block.unblockCoolOff != null) {
      final confirmed = await _confirmUnblock(block);
      if (!mounted || confirmed != true) return;
    }

    setState(() {
      _busyIds.add(block.id);
      _failedIds.remove(block.id);
    });

    var success = false;
    try {
      success = await widget.onChanged(block.id, blocked);
    } catch (_) {
      success = false;
    }
    if (!mounted) return;

    setState(() {
      _busyIds.remove(block.id);
      if (!success) {
        _failedIds.add(block.id);
        return;
      }
      final coolOff = block.unblockCoolOff;
      if (!blocked && coolOff != null) {
        // Unblock confirmed but delayed: stay blocked and show the
        // pending state until the cool-off elapses.
        _overrides[block.id] = BankCategoryBlock(
          id: block.id,
          label: block.label,
          icon: block.icon,
          blocked: true,
          unblockCoolOff: coolOff,
          coolOffEndsAt: DateTime.now().add(coolOff),
        );
      } else {
        _overrides[block.id] = BankCategoryBlock(
          id: block.id,
          label: block.label,
          icon: block.icon,
          blocked: blocked,
          unblockCoolOff: block.unblockCoolOff,
        );
      }
    });
  }

  Future<bool?> _confirmUnblock(BankCategoryBlock block) {
    final theme = BankThemeData.of(context);
    final hours = '${block.unblockCoolOff!.inHours}';
    final resolvedAccentColor = widget.accentColor ?? theme.primary;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
        title: Text(
          widget.unblockDialogTitleTemplate.replaceAll('{label}', block.label),
          style: BankTokens.headlineSmall
              .copyWith(color: theme.onSurface)
              .merge(widget.dialogTitleStyle),
        ),
        content: Text(
          widget.unblockDialogBodyTemplate
              .replaceAll('{label}', block.label)
              .replaceAll('{hours}', hours),
          style: BankTokens.bodyMedium
              .copyWith(color: theme.onSurfaceVariant)
              .merge(widget.dialogBodyStyle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: theme.onSurfaceVariant,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(widget.unblockCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: resolvedAccentColor,
              foregroundColor: theme.onPrimary,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
              shape: RoundedRectangleBorder(borderRadius: theme.buttonRadius),
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(widget.unblockConfirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final now = DateTime.now();

    final resolvedTitlePadding = widget.titlePadding ??
        const EdgeInsetsDirectional.only(
          start: BankTokens.space4,
          end: BankTokens.space4,
          top: BankTokens.space4,
          bottom: BankTokens.space2,
        );
    final resolvedRowPadding = widget.rowPadding ??
        const EdgeInsets.symmetric(
          horizontal: BankTokens.space4,
          vertical: BankTokens.space2,
        );
    final resolvedTitleStyle = BankTokens.labelMedium
        .copyWith(color: theme.onSurfaceVariant)
        .merge(widget.titleStyle);
    final resolvedTileRadius = widget.tileRadius ?? theme.chipRadius;
    final resolvedAccentColor = widget.accentColor ?? theme.primary;
    final resolvedPendingColor = widget.pendingColor ?? theme.pending;
    final resolvedRowMinHeight = widget.rowMinHeight ?? 56;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: resolvedTitlePadding,
          child: Text(
            widget.title,
            style: resolvedTitleStyle,
          ),
        ),
        for (final block in widget.blocks)
          _BlockRow(
            block: _effective(block),
            busy: _busyIds.contains(block.id),
            failed: _failedIds.contains(block.id),
            now: now,
            theme: theme,
            coolOffTemplate: widget.coolOffTemplate,
            coolOffNoticeTemplate: widget.coolOffNoticeTemplate,
            errorLabel: widget.errorLabel,
            blockedSemanticLabel: widget.blockedSemanticLabel,
            allowedSemanticLabel: widget.allowedSemanticLabel,
            onToggle: _handleToggle,
            rowPadding: resolvedRowPadding,
            tileRadius: resolvedTileRadius,
            accentColor: resolvedAccentColor,
            pendingColor: resolvedPendingColor,
            labelStyle: widget.labelStyle,
            helperStyle: widget.helperStyle,
            pendingIcon: widget.pendingIcon ?? BankIcons.schedule,
            noticeIcon: widget.noticeIcon ?? BankIcons.info,
            errorIcon: widget.errorIcon ?? BankIcons.error,
            minHeight: resolvedRowMinHeight,
          ),
      ],
    );

    if (widget.semanticLabel == null) return list;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: list,
    );
  }
}

// ---------------------------------------------------------------------------
// _BlockRow: tinted icon tile + label + helpers + switch / spinner
// ---------------------------------------------------------------------------

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.block,
    required this.busy,
    required this.failed,
    required this.now,
    required this.theme,
    required this.coolOffTemplate,
    required this.coolOffNoticeTemplate,
    required this.errorLabel,
    required this.blockedSemanticLabel,
    required this.allowedSemanticLabel,
    required this.onToggle,
    required this.rowPadding,
    required this.tileRadius,
    required this.accentColor,
    required this.pendingColor,
    required this.pendingIcon,
    required this.noticeIcon,
    required this.errorIcon,
    required this.minHeight,
    this.labelStyle,
    this.helperStyle,
  });

  final BankCategoryBlock block;
  final bool busy;
  final bool failed;
  final DateTime now;
  final BankThemeData theme;
  final String coolOffTemplate;
  final String coolOffNoticeTemplate;
  final String errorLabel;
  final String blockedSemanticLabel;
  final String allowedSemanticLabel;
  final Future<void> Function(BankCategoryBlock block, bool blocked) onToggle;
  final EdgeInsetsGeometry rowPadding;
  final BorderRadius tileRadius;
  final Color accentColor;
  final Color pendingColor;
  final IconData pendingIcon;
  final IconData noticeIcon;
  final IconData errorIcon;
  final double minHeight;
  final TextStyle? labelStyle;
  final TextStyle? helperStyle;

  bool get _coolingOff =>
      block.coolOffEndsAt != null && block.coolOffEndsAt!.isAfter(now);

  @override
  Widget build(BuildContext context) {
    final coolingOff = _coolingOff;
    final hasCoolOff = block.unblockCoolOff != null;
    final interactive = !busy && !coolingOff;

    final Color tileColor;
    final Color iconColor;
    if (coolingOff) {
      tileColor = pendingColor.withValues(alpha: 0.12);
      iconColor = pendingColor;
    } else if (block.blocked) {
      tileColor = accentColor.withValues(alpha: 0.12);
      iconColor = accentColor;
    } else {
      tileColor = theme.surfaceVariant;
      iconColor = theme.onSurfaceVariant;
    }

    final pendingText = coolingOff
        ? coolOffTemplate.replaceAll(
            '{date}',
            BankDateFormatter.formatLong(block.coolOffEndsAt!),
          )
        : null;
    final noticeText = hasCoolOff
        ? coolOffNoticeTemplate.replaceAll(
            '{hours}',
            '${block.unblockCoolOff!.inHours}',
          )
        : null;

    var semanticsLabel = '${block.label}, '
        '${block.blocked ? blockedSemanticLabel : allowedSemanticLabel}';
    if (pendingText != null) {
      semanticsLabel = '$semanticsLabel, $pendingText';
    }

    return Semantics(
      label: semanticsLabel,
      toggled: block.blocked,
      enabled: interactive,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: interactive ? () => onToggle(block, !block.blocked) : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: rowPadding,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: tileRadius,
                      ),
                      child: Center(
                        child: Icon(block.icon, size: 22, color: iconColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          block.label,
                          style: BankTokens.labelLarge
                              .copyWith(color: theme.onSurface)
                              .merge(labelStyle),
                        ),
                        if (pendingText != null)
                          _HelperLine(
                            icon: pendingIcon,
                            text: pendingText,
                            color: pendingColor,
                            textStyle: helperStyle,
                          ),
                        if (noticeText != null)
                          _HelperLine(
                            icon: noticeIcon,
                            text: noticeText,
                            color: theme.onSurfaceVariant,
                            textStyle: helperStyle,
                          ),
                        if (failed)
                          _HelperLine(
                            icon: errorIcon,
                            text: errorLabel,
                            color: BankTokens.danger,
                            textStyle: helperStyle,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BankTokens.space2),
                  SizedBox(
                    width: 64,
                    height: BankTokens.minTapTarget,
                    child: Center(
                      child: busy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            )
                          : Switch(
                              value: block.blocked,
                              activeColor: theme.onPrimary,
                              activeTrackColor:
                                  coolingOff ? pendingColor : accentColor,
                              onChanged: interactive
                                  ? (value) => onToggle(block, value)
                                  : null,
                            ),
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
// _HelperLine: small icon + caption under a row label
// ---------------------------------------------------------------------------

class _HelperLine extends StatelessWidget {
  const _HelperLine({
    required this.icon,
    required this.text,
    required this.color,
    this.textStyle,
  });

  final IconData icon;
  final String text;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: BankTokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: BankTokens.space1),
          Flexible(
            child: Text(
              text,
              style:
                  BankTokens.bodySmall.copyWith(color: color).merge(textStyle),
            ),
          ),
        ],
      ),
    );
  }
}
