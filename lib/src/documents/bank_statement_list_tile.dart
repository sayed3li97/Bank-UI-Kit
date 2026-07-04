import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// The kind of document a [BankDocument] represents.
enum BankDocumentType {
  /// A periodic account statement.
  statement,

  /// A tax certificate or annual tax summary.
  taxDocument,

  /// A signed agreement or terms document.
  contract,

  /// A letter or notice from the bank.
  letter,

  /// A payment or deposit receipt.
  receipt,
}

/// Download lifecycle of a document row's trailing action.
enum BankDocumentDownloadState {
  /// No download started: shows the download affordance.
  idle,

  /// Download in flight: shows a circular progress indicator.
  downloading,

  /// Download finished: shows a success check.
  done,

  /// Download failed: shows a danger-coloured retry affordance.
  failed,
}

/// A downloadable document in the statements / documents center.
class BankDocument {
  const BankDocument({
    required this.id,
    required this.title,
    required this.periodOrDate,
    required this.type,
    this.fileSizeBytes,
    this.isNew = false,
  });

  /// Stable identifier used by hosts to key downloads.
  final String id;

  /// Display title, e.g. `'March 2026 statement'`.
  final String title;

  /// The statement period end or document issue date.
  final DateTime periodOrDate;

  final BankDocumentType type;

  /// File size in bytes, rendered human-readable when provided.
  final int? fileSizeBytes;

  /// Marks a document the customer has not opened yet.
  final bool isNew;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankDocument &&
          other.id == id &&
          other.title == title &&
          other.periodOrDate == periodOrDate &&
          other.type == type &&
          other.fileSizeBytes == fileSizeBytes &&
          other.isNew == isNew;

  @override
  int get hashCode =>
      Object.hash(id, title, periodOrDate, type, fileSizeBytes, isNew);
}

/// A row for the statements / documents center.
///
/// Renders a document-type icon, the document title with its formatted
/// period line, a `New` chip for unread documents, and a trailing download
/// affordance that reflects [BankDocumentDownloadState]. Group rows by year
/// with `BankTransactionGroupHeader`-style headers and pair the empty
/// center with `BankEmptyStateView`.
///
/// ```dart
/// BankStatementListTile(
///   document: const BankDocument(
///     id: 'st-2026-03',
///     title: 'March 2026 statement',
///     periodOrDate: DateTime(2026, 3, 31),
///     type: BankDocumentType.statement,
///     fileSizeBytes: 245000,
///     isNew: true,
///   ),
///   onView: _openViewer,
///   onDownload: _startDownload,
///   downloadState: BankDocumentDownloadState.idle,
/// )
/// ```
class BankStatementListTile extends StatelessWidget {
  const BankStatementListTile({
    required this.document,
    required this.onView,
    super.key,
    this.onDownload,
    this.onShare,
    this.downloadState = BankDocumentDownloadState.idle,
    this.downloadProgress,
    this.newLabel = 'New',
    this.downloadLabel = 'Download',
    this.retryLabel = 'Retry download',
    this.shareLabel = 'Share',
    this.padding,
    this.accentColor,
    this.iconBackgroundColor,
    this.icon,
    this.downloadIcon,
    this.shareIcon,
    this.doneIcon,
    this.retryIcon,
    this.chevronIcon,
    this.titleStyle,
    this.subtitleStyle,
    this.minHeight,
    this.semanticLabel,
  });

  final BankDocument document;

  /// Fired when the row body is tapped: opens the document viewer.
  final VoidCallback onView;

  /// Starts (or retries) a download. The trailing affordance is hidden
  /// when null.
  final VoidCallback? onDownload;

  /// Shows a share affordance next to the download one when set.
  final VoidCallback? onShare;

  final BankDocumentDownloadState downloadState;

  /// Determinate progress (0..1) while
  /// [BankDocumentDownloadState.downloading]; indeterminate when null.
  final double? downloadProgress;

  /// Label of the unread chip.
  final String newLabel;

  /// Semantics label for the idle download affordance.
  final String downloadLabel;

  /// Semantics label for the failed-state retry affordance.
  final String retryLabel;

  /// Semantics label for the share affordance.
  final String shareLabel;

  /// Overrides the row's inner padding. Defaults to a symmetric
  /// [BankTokens.space4] by [BankTokens.space2] inset.
  final EdgeInsetsGeometry? padding;

  /// Overrides [BankThemeData.primary] as the document icon tint and the
  /// "New" chip colour.
  final Color? accentColor;

  /// Overrides the document icon box fill. Defaults to the accent colour
  /// at 8 % opacity.
  final Color? iconBackgroundColor;

  /// Overrides the type-derived document glyph (see [BankIcons]).
  final IconData? icon;

  /// Overrides the idle download glyph. Defaults to [BankIcons.download].
  final IconData? downloadIcon;

  /// Overrides the share glyph. Defaults to [BankIcons.share].
  final IconData? shareIcon;

  /// Overrides the download-complete glyph. Defaults to
  /// [Icons.check_circle_rounded].
  final IconData? doneIcon;

  /// Overrides the failed-state retry glyph. Defaults to
  /// [Icons.refresh_rounded].
  final IconData? retryIcon;

  /// Overrides the chevron shown when [onDownload] is null. Defaults to
  /// [Icons.chevron_right].
  final IconData? chevronIcon;

  /// Merged over the computed title style ([BankTokens.bodyLarge] in
  /// [BankThemeData.onSurface]).
  final TextStyle? titleStyle;

  /// Merged over the computed subtitle style ([BankTokens.bodySmall] in
  /// [BankThemeData.onSurfaceVariant]).
  final TextStyle? subtitleStyle;

  /// Overrides the row's 64 px minimum height.
  final double? minHeight;

  /// Overrides the row's computed semantics label (title, subtitle, and
  /// the "New" marker).
  final String? semanticLabel;

  IconData get _typeIcon => switch (document.type) {
        BankDocumentType.statement => BankIcons.document,
        BankDocumentType.taxDocument => BankIcons.tax,
        BankDocumentType.contract => BankIcons.contract,
        BankDocumentType.letter => BankIcons.letter,
        BankDocumentType.receipt => BankIcons.receipt,
      };

  static String _formatBytes(int bytes) {
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000000) {
      return '${(bytes / 1000).toStringAsFixed(0)} KB';
    }
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final accent = accentColor ?? theme.primary;

    final sizeSuffix = document.fileSizeBytes == null
        ? ''
        : ' · ${_formatBytes(document.fileSizeBytes!)}';
    final subtitle =
        '${BankDateFormatter.formatLong(document.periodOrDate)}$sizeSuffix';

    return Semantics(
      button: true,
      label: semanticLabel ??
          '${document.title}, $subtitle'
              '${document.isNew ? ', $newLabel' : ''}',
      child: InkWell(
        onTap: onView,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight ?? 64),
          child: Padding(
            padding: padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space2,
                ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        iconBackgroundColor ?? accent.withValues(alpha: 0.08),
                    borderRadius: theme.chipRadius,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(icon ?? _typeIcon, size: 22, color: accent),
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
                            child: Text(
                              document.title,
                              style: BankTokens.bodyLarge
                                  .copyWith(color: theme.onSurface)
                                  .merge(titleStyle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (document.isNew) ...[
                            const SizedBox(width: BankTokens.space2),
                            _NewChip(
                              label: newLabel,
                              theme: theme,
                              accent: accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant)
                            .merge(subtitleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onShare != null &&
                    downloadState != BankDocumentDownloadState.downloading)
                  IconButton(
                    onPressed: onShare,
                    tooltip: shareLabel,
                    icon: Icon(
                      shareIcon ?? BankIcons.share,
                      size: 20,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                _TrailingAction(
                  state: downloadState,
                  progress: downloadProgress,
                  onDownload: onDownload,
                  downloadLabel: downloadLabel,
                  retryLabel: retryLabel,
                  theme: theme,
                  downloadIcon: downloadIcon,
                  doneIcon: doneIcon,
                  retryIcon: retryIcon,
                  chevronIcon: chevronIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip({
    required this.label,
    required this.theme,
    required this.accent,
  });

  final String label;
  final BankThemeData theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: 2,
        ),
        child: Text(
          label,
          style: BankTokens.labelSmall.copyWith(color: accent),
        ),
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.state,
    required this.progress,
    required this.onDownload,
    required this.downloadLabel,
    required this.retryLabel,
    required this.theme,
    this.downloadIcon,
    this.doneIcon,
    this.retryIcon,
    this.chevronIcon,
  });

  final BankDocumentDownloadState state;
  final double? progress;
  final VoidCallback? onDownload;
  final String downloadLabel;
  final String retryLabel;
  final BankThemeData theme;
  final IconData? downloadIcon;
  final IconData? doneIcon;
  final IconData? retryIcon;
  final IconData? chevronIcon;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BankDocumentDownloadState.idle => onDownload == null
          ? Icon(
              chevronIcon ?? Icons.chevron_right,
              color: theme.onSurfaceVariant,
            )
          : IconButton(
              onPressed: onDownload,
              tooltip: downloadLabel,
              icon: Icon(
                downloadIcon ?? BankIcons.download,
                size: 20,
                color: theme.onSurfaceVariant,
              ),
            ),
      BankDocumentDownloadState.downloading => Padding(
          padding: const EdgeInsets.all(BankTokens.space3),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
              color: theme.primary,
            ),
          ),
        ),
      BankDocumentDownloadState.done => Padding(
          padding: const EdgeInsets.all(BankTokens.space3),
          child: Icon(
            doneIcon ?? Icons.check_circle_rounded,
            size: 20,
            color: theme.positiveBalance,
          ),
        ),
      BankDocumentDownloadState.failed => IconButton(
          onPressed: onDownload,
          tooltip: retryLabel,
          icon: Icon(
            retryIcon ?? Icons.refresh_rounded,
            size: 20,
            color: BankTokens.danger,
          ),
        ),
    };
  }
}
