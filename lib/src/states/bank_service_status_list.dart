import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// Health level of a single banking service rail.
///
/// Used by [BankServiceStatusEntry] and rendered as an icon plus text
/// pill by [BankServiceStatusList], so state is never conveyed by
/// colour alone.
enum BankServiceHealth {
  /// The service is fully available.
  operational,

  /// The service is available but slower or partially impaired.
  degraded,

  /// The service is unavailable.
  down,

  /// The service is offline for planned maintenance.
  maintenance,
}

/// Immutable description of one banking service rail and its health.
///
/// Rendered as a single row inside [BankServiceStatusList].
@immutable
class BankServiceStatusEntry {
  /// Display name of the service rail, e.g. 'Card payments'.
  final String name;

  /// Current health level of the service.
  final BankServiceHealth health;

  /// Optional short incident note, e.g. 'Outbound transfers may be
  /// delayed, next update by 15:30'.
  final String? note;

  /// When this entry last changed; rendered as a relative time.
  final DateTime? updatedAt;

  /// Optional leading service glyph, e.g. [BankIcons.card] or
  /// [BankIcons.transfer].
  final IconData? icon;

  /// Creates the description of one service rail.
  const BankServiceStatusEntry({
    required this.name,
    required this.health,
    this.note,
    this.updatedAt,
    this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankServiceStatusEntry &&
        other.name == name &&
        other.health == health &&
        other.note == note &&
        other.updatedAt == updatedAt &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(name, health, note, updatedAt, icon);
}

/// Per-rail system health card (the Starling/Monzo status pattern):
/// one row per banking rail such as 'Card payments', 'Transfers out',
/// or 'Login', each with a trailing status pill combining an icon, a
/// label, and a colour so state is never colour alone.
///
/// Purely presentational: [services] and [lastUpdatedAt] are injected
/// by the host app; no networking or polling happens inside. This makes
/// the card equally usable on a dashboard, as a still-working area
/// replacement in a gate screen, or behind a connectivity banner's
/// view-status action. Sorting is the caller's responsibility (worst
/// first is recommended); the widget preserves input order exactly.
///
/// An empty [services] list renders a single quiet
/// [allOperationalLabel] row, never a bare empty box. Rows become
/// tappable [InkWell]s when [onEntryTap] is provided, and a footer
/// [TextButton] link appears when [onViewStatusPage] is provided.
///
/// ```dart
/// BankServiceStatusList(
///   services: [
///     const BankServiceStatusEntry(
///       name: 'Card payments',
///       health: BankServiceHealth.operational,
///       icon: BankIcons.card,
///     ),
///     BankServiceStatusEntry(
///       name: 'Transfers out',
///       health: BankServiceHealth.degraded,
///       note: 'Outbound transfers may be delayed, '
///           'next update by 15:30',
///       updatedAt: DateTime(2026, 7, 3, 15, 0),
///       icon: BankIcons.transfer,
///     ),
///   ],
///   lastUpdatedAt: DateTime(2026, 7, 3, 15, 5),
///   onViewStatusPage: () => openStatusPage(),
///   onEntryTap: (entry) => openIncidentDetail(entry),
/// )
/// ```
class BankServiceStatusList extends StatelessWidget {
  /// The service rails to display, rendered in the given order.
  final List<BankServiceStatusEntry> services;

  /// Header title rendered in [BankTokens.labelLarge].
  final String title;

  /// When the status feed itself was refreshed; shown in the header
  /// trailing slot as a relative time. Hidden when `null`.
  final DateTime? lastUpdatedAt;

  /// Clock used to compute relative times, so screenshots can be
  /// deterministic. Defaults to [DateTime.now].
  final DateTime Function()? clock;

  /// Prefix before every relative "updated" time.
  final String updatedPrefix;

  /// Opens the full public status page. The footer link is hidden when
  /// `null`.
  final VoidCallback? onViewStatusPage;

  /// Label of the footer status-page link.
  final String statusPageLabel;

  /// Called with the tapped entry for drill-in. Rows are static when
  /// `null`.
  final void Function(BankServiceStatusEntry entry)? onEntryTap;

  /// Pill label for [BankServiceHealth.operational].
  final String operationalLabel;

  /// Pill label for [BankServiceHealth.degraded].
  final String degradedLabel;

  /// Pill label for [BankServiceHealth.down].
  final String downLabel;

  /// Pill label for [BankServiceHealth.maintenance].
  final String maintenanceLabel;

  /// Quiet row shown when [services] is empty.
  final String allOperationalLabel;

  /// Overrides the card content padding. Defaults to
  /// [EdgeInsetsDirectional.all] of [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Overrides the card corner radius. Defaults to
  /// [BankThemeData.cardRadius].
  final BorderRadius? radius;

  /// Overrides the card background. Defaults to [BankThemeData.surface].
  final Color? backgroundColor;

  /// Overrides the card shadow. Defaults to [BankTokens.shadowCard];
  /// passing `const []` flattens the card.
  final List<BoxShadow>? shadow;

  /// Merged over the computed header title style.
  final TextStyle? titleStyle;

  /// Merged over the computed service-name style.
  final TextStyle? nameStyle;

  /// Merged over the computed incident-note style.
  final TextStyle? noteStyle;

  /// Replaces the default header row (title plus updated time).
  final Widget? header;

  /// Replaces the default footer (the status-page link).
  final Widget? footer;

  /// Swaps an entire row while keeping the card chrome and dividers.
  final Widget Function(BuildContext context, BankServiceStatusEntry entry)?
      itemBuilder;

  /// Creates a per-rail service status card.
  const BankServiceStatusList({
    required this.services,
    super.key,
    this.title = 'Service status',
    this.lastUpdatedAt,
    this.clock,
    this.updatedPrefix = 'Updated ',
    this.onViewStatusPage,
    this.statusPageLabel = 'Full status page',
    this.onEntryTap,
    this.operationalLabel = 'Operational',
    this.degradedLabel = 'Degraded',
    this.downLabel = 'Down',
    this.maintenanceLabel = 'Maintenance',
    this.allOperationalLabel = 'All services operational',
    this.padding,
    this.radius,
    this.backgroundColor,
    this.shadow,
    this.titleStyle,
    this.nameStyle,
    this.noteStyle,
    this.header,
    this.footer,
    this.itemBuilder,
  });

  String _labelFor(BankServiceHealth health) => switch (health) {
        BankServiceHealth.operational => operationalLabel,
        BankServiceHealth.degraded => degradedLabel,
        BankServiceHealth.down => downLabel,
        BankServiceHealth.maintenance => maintenanceLabel,
      };

  static Color _colorFor(BankThemeData theme, BankServiceHealth health) =>
      switch (health) {
        BankServiceHealth.operational => theme.positiveBalance,
        BankServiceHealth.degraded => BankTokens.warning,
        BankServiceHealth.down => BankTokens.danger,
        BankServiceHealth.maintenance => theme.pending,
      };

  static IconData _iconFor(BankServiceHealth health) => switch (health) {
        BankServiceHealth.operational => BankIcons.success,
        BankServiceHealth.degraded => BankIcons.warning,
        BankServiceHealth.down => BankIcons.error,
        BankServiceHealth.maintenance => BankIcons.schedule,
      };

  String _relative(DateTime date) =>
      BankDateFormatter.formatRelative(date, now: (clock ?? DateTime.now)());

  String _rowSemanticsLabel(BankServiceStatusEntry entry) {
    final buffer = StringBuffer('${entry.name}: ${_labelFor(entry.health)}.');
    final note = entry.note;
    if (note != null) {
      buffer.write(' $note.');
    }
    final updated = entry.updatedAt;
    if (updated != null) {
      buffer.write(' $updatedPrefix${_relative(updated)}');
    }
    return buffer.toString();
  }

  Widget _buildHeader(BankThemeData theme) {
    final computedTitle = BankTokens.labelLarge.copyWith(
      color: theme.onSurface,
    );
    return Row(
      children: [
        Expanded(
          child: Text(title, style: computedTitle.merge(titleStyle)),
        ),
        if (lastUpdatedAt != null)
          Text(
            '$updatedPrefix${_relative(lastUpdatedAt!)}',
            style: BankTokens.bodySmall.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildRow(BankThemeData theme, BankServiceStatusEntry entry) {
    final secondary = BankTokens.bodySmall.copyWith(
      color: theme.onSurfaceVariant,
    );

    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
        child: Row(
          children: [
            if (entry.icon != null) ...[
              Icon(entry.icon, size: 20, color: theme.onSurfaceVariant),
              const SizedBox(width: BankTokens.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: BankTokens.bodyMedium
                        .copyWith(color: theme.onSurface)
                        .merge(nameStyle),
                  ),
                  if (entry.note != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    Text(entry.note!, style: secondary.merge(noteStyle)),
                  ],
                  if (entry.updatedAt != null) ...[
                    const SizedBox(height: BankTokens.space1),
                    Text(
                      '$updatedPrefix${_relative(entry.updatedAt!)}',
                      style: secondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            _BankServiceStatusPill(
              color: _colorFor(theme, entry.health),
              icon: _iconFor(entry.health),
              label: _labelFor(entry.health),
            ),
          ],
        ),
      ),
    );

    content = Semantics(
      button: onEntryTap != null,
      label: _rowSemanticsLabel(entry),
      excludeSemantics: true,
      child: content,
    );

    if (onEntryTap != null) {
      content = InkWell(
        onTap: () => onEntryTap!(entry),
        child: content,
      );
    }

    return MergeSemantics(child: content);
  }

  Widget _buildAllOperationalRow(BankThemeData theme) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BankTokens.space2),
          child: Row(
            children: [
              Icon(BankIcons.success, size: 20, color: theme.positiveBalance),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Text(
                  allOperationalLabel,
                  style: BankTokens.bodyMedium
                      .copyWith(color: theme.onSurfaceVariant)
                      .merge(nameStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BankThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: BankTokens.space1),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          label: statusPageLabel,
          child: TextButton(
            onPressed: onViewStatusPage,
            style: TextButton.styleFrom(
              foregroundColor: theme.primary,
              minimumSize: const Size(
                BankTokens.minTapTarget,
                BankTokens.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space2,
              ),
              textStyle: BankTokens.labelLarge,
            ),
            child: Text(statusPageLabel),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final resolvedPadding =
        padding ?? const EdgeInsetsDirectional.all(BankTokens.space4);
    final resolvedRadius = radius ?? theme.cardRadius;
    final resolvedBackground = backgroundColor ?? theme.surface;
    final resolvedShadow = shadow ?? BankTokens.shadowCard;
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: theme.outline.withValues(alpha: 0.4),
    );

    final rows = <Widget>[];
    if (services.isEmpty) {
      rows.add(_buildAllOperationalRow(theme));
    } else {
      for (var i = 0; i < services.length; i++) {
        if (i > 0) {
          rows.add(divider);
        }
        final entry = services[i];
        rows.add(
          itemBuilder?.call(context, entry) ?? _buildRow(theme, entry),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: resolvedShadow,
      ),
      child: Material(
        color: resolvedBackground,
        borderRadius: resolvedRadius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              header ?? _buildHeader(theme),
              const SizedBox(height: BankTokens.space2),
              ...rows,
              if (footer != null)
                footer!
              else if (onViewStatusPage != null)
                _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing status pill: a [BankThemeData.chipRadius]-rounded box with
/// the level colour at 12% alpha behind a 14 px icon and a label, so
/// health is always communicated by icon plus text plus colour.
class _BankServiceStatusPill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _BankServiceStatusPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: theme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space2,
          vertical: BankTokens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: BankTokens.space1),
            Text(label, style: BankTokens.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
