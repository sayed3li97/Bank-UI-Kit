import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/extensions.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';

/// A single shortcut entry rendered by [BankQuickActionsGrid].
///
/// Actions are identified by [id], which is what the grid reports back
/// through its reorder callback so the host application can persist the
/// user's preferred order.
@immutable
class BankQuickAction {
  const BankQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.badgeText,
  });

  /// Stable identifier used for reorder persistence.
  final String id;

  /// Short label shown below the icon (one to two lines).
  final String label;

  /// Icon shown inside the circular tile. Prefer entries from [BankIcons].
  final IconData icon;

  /// Invoked when the tile is tapped while [enabled] is `true`.
  final VoidCallback onTap;

  /// Whether the tile is interactive. Disabled tiles render at 40% opacity.
  final bool enabled;

  /// Optional mini chip text drawn over the icon (e.g. `'New'`).
  final String? badgeText;

  /// Note: [onTap] is compared by identity, so two otherwise identical
  /// actions with distinct closures are not equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankQuickAction &&
        other.id == id &&
        other.label == label &&
        other.icon == icon &&
        other.onTap == onTap &&
        other.enabled == enabled &&
        other.badgeText == badgeText;
  }

  @override
  int get hashCode => Object.hash(id, label, icon, onTap, enabled, badgeText);
}

/// Dashboard grid of quick-action shortcut tiles with optional user
/// reordering.
///
/// Each [BankQuickAction] renders as a 64 px circular icon tile with a
/// label underneath. Under the Voltage preset the circle gains an
/// accent-gradient ring. Set [maxVisible] to cap the grid: the final cell
/// becomes a "More" tile that fires [onShowAll].
///
/// When [editable] is `true`, a long-press lifts a tile (scaled up with a
/// high-elevation shadow) into a drag-to-reorder interaction; the other
/// tiles wiggle while a drag is active (suppressed when the platform
/// requests reduced motion). Releasing the tile commits the new order via
/// [onReorder], which receives every action id — including any hidden
/// behind the "More" tile — so the host can persist it.
///
/// ```dart
/// BankQuickActionsGrid(
///   actions: [
///     BankQuickAction(
///       id: 'send',
///       label: 'Send',
///       icon: BankIcons.send,
///       onTap: _openSend,
///     ),
///     BankQuickAction(
///       id: 'scan',
///       label: 'Scan',
///       icon: BankIcons.scan,
///       onTap: _openScanner,
///       badgeText: 'New',
///     ),
///   ],
///   editable: true,
///   onReorder: (orderedIds) => prefs.saveActionOrder(orderedIds),
///   maxVisible: 8,
///   onShowAll: _openAllActions,
/// )
/// ```
class BankQuickActionsGrid extends StatefulWidget {
  const BankQuickActionsGrid({
    required this.actions,
    super.key,
    this.crossAxisCount = 4,
    this.editable = false,
    this.onReorder,
    this.maxVisible,
    this.onShowAll,
    this.moreLabel = 'More',
  })  : assert(crossAxisCount > 0, 'crossAxisCount must be positive'),
        assert(
          maxVisible == null || maxVisible > 0,
          'maxVisible must be positive when provided',
        );

  /// The shortcuts to display, in their initial order.
  final List<BankQuickAction> actions;

  /// Number of tiles per row. Defaults to 4.
  final int crossAxisCount;

  /// Enables long-press drag-to-reorder.
  final bool editable;

  /// Called after a reorder drag completes, with the full id order
  /// (visible tiles first, then any actions hidden by [maxVisible]).
  final void Function(List<String> orderedIds)? onReorder;

  /// Caps the total number of grid cells. When more actions exist than fit,
  /// the last cell is a "More" tile that fires [onShowAll].
  final int? maxVisible;

  /// Invoked when the "More" tile is tapped.
  final VoidCallback? onShowAll;

  /// Label of the trailing "More" tile shown when [maxVisible] truncates
  /// the grid. Defaults to `'More'`.
  final String moreLabel;

  @override
  State<BankQuickActionsGrid> createState() => _BankQuickActionsGridState();
}

class _BankQuickActionsGridState extends State<BankQuickActionsGrid>
    with SingleTickerProviderStateMixin {
  static const double _iconDiameter = 64;
  static const double _ringWidth = 2;
  static const double _iconSize = 28;
  static const double _tileExtent = 108;
  static const double _liftScale = 1.1;
  static const double _wiggleAngle = 0.02;

  late List<BankQuickAction> _actions;
  late final AnimationController _wiggleController;
  String? _draggingId;
  bool _orderChanged = false;

  @override
  void initState() {
    super.initState();
    _actions = List.of(widget.actions);
    _wiggleController = AnimationController(
      vsync: this,
      duration: BankTokens.durationFast,
    );
  }

  @override
  void didUpdateWidget(BankQuickActionsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.actions, oldWidget.actions)) {
      _actions = List.of(widget.actions);
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  bool get _showMore =>
      widget.maxVisible != null && _actions.length > widget.maxVisible!;

  List<BankQuickAction> get _visibleActions =>
      _showMore ? _actions.sublist(0, widget.maxVisible! - 1) : _actions;

  void _handleDragStarted(String id) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    setState(() {
      _draggingId = id;
      _orderChanged = false;
    });
    if (!disableAnimations) {
      _wiggleController.repeat(reverse: true);
    }
  }

  void _handleDragEnded() {
    _wiggleController
      ..stop()
      ..reset();
    final changed = _orderChanged;
    setState(() {
      _draggingId = null;
      _orderChanged = false;
    });
    if (changed) {
      widget.onReorder?.call(
        List.unmodifiable(_actions.map((a) => a.id)),
      );
    }
  }

  void _moveTo(String id, int targetIndex) {
    final currentIndex = _actions.indexWhere((a) => a.id == id);
    if (currentIndex < 0 || currentIndex == targetIndex) return;
    setState(() {
      final moved = _actions.removeAt(currentIndex);
      _actions.insert(targetIndex, moved);
      _orderChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleActions;
    final cellCount = visible.length + (_showMore ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth -
                (widget.crossAxisCount - 1) * BankTokens.space2) /
            widget.crossAxisCount;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: BankTokens.space2,
            mainAxisSpacing: BankTokens.space3,
            mainAxisExtent: _tileExtent,
          ),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            if (_showMore && index == visible.length) {
              return KeyedSubtree(
                key: const ValueKey<String>('bank_quick_actions_more'),
                child: _buildMoreTile(context),
              );
            }
            return KeyedSubtree(
              key: ValueKey<String>(visible[index].id),
              child: _buildActionCell(
                context,
                visible[index],
                index,
                tileWidth,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionCell(
    BuildContext context,
    BankQuickAction action,
    int index,
    double tileWidth,
  ) {
    final tile = _buildTile(
      context,
      icon: action.icon,
      label: action.label,
      badgeText: action.badgeText,
      enabled: action.enabled,
      onTap: action.enabled ? action.onTap : null,
    );

    if (!widget.editable) return tile;

    final theme = BankThemeData.of(context);
    final draggable = LongPressDraggable<String>(
      data: action.id,
      maxSimultaneousDrags: 1,
      onDragStarted: () => _handleDragStarted(action.id),
      onDragEnd: (_) => _handleDragEnded(),
      feedback: _buildLiftedFeedback(theme, action, tileWidth),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: _maybeWiggle(tile, index, action.id),
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (details.data == action.id) return false;
        _moveTo(details.data, index);
        return true;
      },
      builder: (context, candidateData, rejectedData) => draggable,
    );
  }

  Widget _buildMoreTile(BuildContext context) => _buildTile(
        context,
        icon: BankIcons.other,
        label: widget.moreLabel,
        badgeText: null,
        enabled: widget.onShowAll != null,
        onTap: widget.onShowAll,
      );

  Widget _maybeWiggle(Widget child, int index, String id) {
    if (_draggingId == null || _draggingId == id) return child;
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, wiggleChild) {
        if (!_wiggleController.isAnimating) return wiggleChild!;
        final direction = index.isEven ? 1.0 : -1.0;
        final angle =
            direction * (_wiggleController.value * 2 - 1) * _wiggleAngle;
        return Transform.rotate(angle: angle, child: wiggleChild);
      },
      child: child,
    );
  }

  Widget _buildLiftedFeedback(
    BankThemeData theme,
    BankQuickAction action,
    double tileWidth,
  ) =>
      Transform.scale(
        scale: _liftScale,
        child: Material(
          elevation: theme.elevationHigh,
          borderRadius: theme.cardRadius,
          color: theme.surface,
          shadowColor:
              theme.useGlow && theme.glowColor != null ? theme.glowColor : null,
          child: SizedBox(
            width: tileWidth,
            height: _tileExtent,
            child: _buildTileBody(
              context,
              icon: action.icon,
              label: action.label,
              badgeText: action.badgeText,
            ),
          ),
        ),
      );

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? badgeText,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final theme = BankThemeData.of(context);

    final semanticLabel = badgeText == null ? label : '$label, $badgeText';

    Widget tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: theme.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: BankTokens.minTapTarget,
            minHeight: BankTokens.minTapTarget,
          ),
          child: _buildTileBody(
            context,
            icon: icon,
            label: label,
            badgeText: badgeText,
          ),
        ),
      ),
    );

    if (!enabled) {
      tile = Opacity(opacity: 0.4, child: tile);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: ExcludeSemantics(child: tile),
    );
  }

  Widget _buildTileBody(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? badgeText,
  }) {
    final theme = BankThemeData.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: BankTokens.space1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIconCircle(context, theme, icon),
              if (badgeText != null)
                PositionedDirectional(
                  top: -BankTokens.space1,
                  end: -BankTokens.space1,
                  child: _buildBadge(theme, badgeText),
                ),
            ],
          ),
          const SizedBox(height: BankTokens.space2),
          Text(
            label,
            style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(
    BuildContext context,
    BankThemeData theme,
    IconData icon,
  ) {
    final scope = BankUiScope.of(context);
    final gradient = theme.accentGradient;
    final showRing = scope.preset == BankPreset.voltage && gradient != null;

    final tint = Color.alphaBlend(
      theme.primary.withValues(alpha: 0.08),
      theme.surface,
    );

    final core = DecoratedBox(
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Center(child: Icon(icon, size: _iconSize, color: theme.primary)),
    );

    if (!showRing) {
      return SizedBox.square(dimension: _iconDiameter, child: core);
    }

    return SizedBox.square(
      dimension: _iconDiameter,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
        child: Padding(
          padding: const EdgeInsets.all(_ringWidth),
          child: core,
        ),
      ),
    );
  }

  Widget _buildBadge(BankThemeData theme, String text) => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: theme.chipRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space2,
            vertical: BankTokens.space1 / 2,
          ),
          child: Text(
            text,
            style: BankTokens.labelSmall.copyWith(color: theme.onPrimary),
          ),
        ),
      );
}
