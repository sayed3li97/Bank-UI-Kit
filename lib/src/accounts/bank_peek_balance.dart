import 'dart:async';

import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_balance_text.dart';

/// A single entry shown by [BankPeekBalance]: a display label (never an
/// account number) and its current balance.
typedef BankPeekAccount = ({String label, Money balance});

/// Width of the floating reveal card.
const double _kCardWidth = 280;

/// Downward drag distance (logical pixels) that reveals the card in the
/// [BankPeekBalance.pullTab] variant.
const double _kPullRevealDistance = BankTokens.space6;

/// How long the reveal card stays visible when triggered through the
/// semantic long-press action (screen readers cannot hold a pointer down).
const Duration _kAccessibilityPeekDuration = Duration(seconds: 3);

/// Pre-login balance peek without authentication: the press-and-hold
/// quick balance pattern.
///
/// Renders a pill affordance. While the user presses and holds the pill
/// (for at least [revealHold]), a floating card appears listing each
/// account label with its balance rendered by [BankBalanceText] at
/// [BankBalanceSize.small]. Releasing hides the card with a short fade
/// ([BankTokens.durationFast]). The widget never shows account numbers,
/// only labels and balances.
///
/// Use the [BankPeekBalance.pullTab] variant when embedding at the top of
/// the screen: it renders a pull tab with rounded bottom corners and also
/// reveals the card on a downward swipe.
///
/// When [enabled] is `false` the widget renders a "Turn on quick balance"
/// prompt instead; tapping it invokes [onEnable].
///
/// The floating card is hosted in the nearest [Overlay] (provided by
/// [MaterialApp]), so the widget must sit below one.
///
/// Accessibility: the reveal card is a live region, so balances are
/// announced when revealed. Screen-reader users can trigger a timed peek
/// through the semantic long-press action.
///
/// ```dart
/// BankPeekBalance(
///   accounts: [
///     (label: 'Everyday', balance: Money.fromDouble(1240.50, 'GBP')),
///     (label: 'Savings', balance: Money.fromDouble(8050.00, 'GBP')),
///   ],
///   enabled: true,
///   onEnable: () => settings.enableQuickBalance(),
/// )
/// ```
class BankPeekBalance extends StatefulWidget {
  /// The accounts to list while the peek card is revealed. Only the label
  /// and balance are ever displayed.
  final List<BankPeekAccount> accounts;

  /// Whether quick balance peeking is switched on. When `false` the widget
  /// renders an enable prompt instead of the peek affordance.
  final bool enabled;

  /// Short instruction rendered inside the pill / pull tab.
  final String hint;

  /// How long the pointer must stay down before the card is revealed.
  final Duration revealHold;

  /// Called when the user taps the enable prompt shown while [enabled] is
  /// `false`.
  final VoidCallback? onEnable;

  /// Label for the prompt shown while [enabled] is `false`.
  final String enablePromptLabel;

  /// Whether this instance renders as a top-of-screen pull tab that also
  /// reveals on a downward swipe. Set by [BankPeekBalance.pullTab].
  final bool usePullTab;

  /// Creates the standard pill variant, revealed by press-and-hold.
  const BankPeekBalance({
    required this.accounts,
    required this.enabled,
    super.key,
    this.hint = 'Hold to peek',
    this.revealHold = BankTokens.durationBase,
    this.onEnable,
    this.enablePromptLabel = 'Turn on quick balance',
  }) : usePullTab = false;

  /// Creates the pull-tab variant for embedding at the top of the screen.
  ///
  /// In addition to press-and-hold, a downward swipe on the tab reveals
  /// the card until the finger lifts.
  const BankPeekBalance.pullTab({
    required this.accounts,
    required this.enabled,
    super.key,
    this.hint = 'Pull to peek',
    this.revealHold = BankTokens.durationBase,
    this.onEnable,
    this.enablePromptLabel = 'Turn on quick balance',
  }) : usePullTab = true;

  @override
  State<BankPeekBalance> createState() => _BankPeekBalanceState();
}

class _BankPeekBalanceState extends State<BankPeekBalance>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  late final AnimationController _fade;
  late final Animation<double> _fadeCurve;

  Timer? _holdTimer;
  Timer? _autoHideTimer;
  double _dragDistance = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: BankTokens.durationFast,
    )..addStatusListener(_handleFadeStatus);
    _fadeCurve = CurvedAnimation(
      parent: _fade,
      curve: BankTokens.curveStandard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _fade.duration =
        disableAnimations ? Duration.zero : BankTokens.durationFast;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _autoHideTimer?.cancel();
    _fade
      ..removeStatusListener(_handleFadeStatus)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Reveal / hide logic
  // ---------------------------------------------------------------------------

  void _handleFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _portal.isShowing) {
      _portal.hide();
    }
  }

  void _startHold() {
    if (widget.accounts.isEmpty) return;
    _holdTimer?.cancel();
    _holdTimer = Timer(widget.revealHold, _reveal);
  }

  void _reveal() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!mounted || widget.accounts.isEmpty) return;
    if (!_portal.isShowing) _portal.show();
    _fade.forward();
    if (!_revealed) setState(() => _revealed = true);
  }

  void _release() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    if (!mounted) return;
    if (_portal.isShowing) _fade.reverse();
    if (_revealed) setState(() => _revealed = false);
  }

  /// Timed reveal for assistive technologies that cannot hold a pointer.
  void _peekForAccessibility() {
    if (widget.accounts.isEmpty) return;
    _reveal();
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_kAccessibilityPeekDuration, _release);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dy;
    if (_dragDistance >= _kPullRevealDistance && !_portal.isShowing) {
      _reveal();
    }
  }

  // ---------------------------------------------------------------------------
  // Reveal card (overlay)
  // ---------------------------------------------------------------------------

  String _announcementFor(BankUiScopeData scope) => widget.accounts.map(
        (BankPeekAccount account) {
          final value = scope.privacyEnabled
              ? scope.strings.balanceHidden
              : BankMoneyFormatter.format(
                  amount: account.balance.amount,
                  currencyCode: account.balance.currencyCode,
                  numeralStyle: scope.numeralStyle,
                );
          return '${account.label}: $value';
        },
      ).join(', ');

  Widget _buildRevealCard(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);

    final rows = <Widget>[];
    for (var i = 0; i < widget.accounts.length; i++) {
      final account = widget.accounts[i];
      if (i > 0) rows.add(const SizedBox(height: BankTokens.space3));
      rows.add(
        Row(
          children: [
            Expanded(
              child: Text(
                account.label,
                style: BankTokens.bodyMedium.copyWith(
                  color: theme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: BankTokens.space3),
            BankBalanceText(
              money: account.balance,
              size: BankBalanceSize.small,
            ),
          ],
        ),
      );
    }

    return Positioned(
      width: _kCardWidth,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: const Offset(0, BankTokens.space2),
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _fadeCurve,
            child: Semantics(
              container: true,
              liveRegion: true,
              label: _announcementFor(scope),
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: theme.cardRadius,
                  boxShadow: BankTokens.shadowFloating,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Affordances
  // ---------------------------------------------------------------------------

  Widget _buildPill(BankThemeData theme) {
    final contentColor = _revealed ? theme.primary : theme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(BankTokens.radiusFull),
        boxShadow: BankTokens.shadowCard,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BankTokens.space4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _revealed ? BankIcons.visibilityOff : BankIcons.visibility,
                size: 18,
                color: contentColor,
              ),
              const SizedBox(width: BankTokens.space2),
              Text(
                widget.hint,
                style: BankTokens.labelMedium.copyWith(color: contentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BankThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(BankTokens.radiusLarge),
        ),
        boxShadow: BankTokens.shadowCard,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BankTokens.minTapTarget,
          minWidth: BankTokens.minTapTarget * 2,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: BankTokens.space8,
                height: BankTokens.space1,
                decoration: BoxDecoration(
                  color: theme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(BankTokens.radiusFull),
                ),
              ),
              const SizedBox(height: BankTokens.space1),
              Text(
                widget.hint,
                style: BankTokens.labelSmall.copyWith(
                  color: theme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnablePrompt(BankThemeData theme) {
    return Semantics(
      button: true,
      label: widget.enablePromptLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onEnable,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(BankTokens.radiusFull),
            boxShadow: BankTokens.shadowCard,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BankTokens.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BankTokens.space4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    BankIcons.visibility,
                    size: 18,
                    color: theme.primary,
                  ),
                  const SizedBox(width: BankTokens.space2),
                  Text(
                    widget.enablePromptLabel,
                    style: BankTokens.labelMedium.copyWith(
                      color: theme.primary,
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    if (!widget.enabled) return _buildEnablePrompt(theme);

    Widget interactive = Listener(
      onPointerDown: (PointerDownEvent event) => _startHold(),
      onPointerUp: (PointerUpEvent event) => _release(),
      onPointerCancel: (PointerCancelEvent event) => _release(),
      child: widget.usePullTab ? _buildTab(theme) : _buildPill(theme),
    );

    if (widget.usePullTab) {
      interactive = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: (DragEndDetails details) => _release(),
        onVerticalDragCancel: _release,
        child: interactive,
      );
    }

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildRevealCard,
        child: Semantics(
          button: true,
          label: widget.hint,
          onLongPress: _peekForAccessibility,
          excludeSemantics: true,
          child: interactive,
        ),
      ),
    );
  }
}
