import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../scope/bank_ui_scope.dart';
import '../theme/bank_theme_data.dart';
import '../theme/numeral_style.dart';
import '../theme/tokens.dart';

/// Granularity of the time period navigated by a [BankPeriodSelector].
enum BankPeriodUnit {
  /// Calendar month: labelled like `March 2026`.
  month,

  /// Calendar quarter: labelled like `Q1 2026`.
  quarter,

  /// Calendar year: labelled like `2026`.
  year,
}

/// Prev/next time-period navigator for statements, insights and budgets.
///
/// Renders a row with a back chevron, a centred period label, and a
/// forward chevron. Hosts keep the current [period] in their own state and
/// receive the previous/next period through [onChanged]: the widget itself
/// is stateless with respect to the selected period (controlled component).
///
/// Typical placement is as the header above a spending breakdown chart or
/// a budget gauge, so users can page through months, quarters or years.
///
/// Behaviour:
/// - The label is formatted per [unit] (`March 2026` / `Q1 2026` / `2026`)
///   and digits follow the ambient [NumeralStyle] from [BankUiScope]
///   (Eastern Arabic-Indic digits in Arabic-script locales).
/// - Chevrons dim to 40% opacity and stop responding at [minPeriod] /
///   [maxPeriod] bounds (compared at [unit] granularity).
/// - Chevrons flip for right-to-left locales, and their semantic labels
///   stay direction-agnostic ("Previous month" / "Next month").
/// - The label crossfades over 150 ms with a short horizontal slide that
///   matches the direction of travel (reversed in RTL); the animation is
///   skipped when the platform requests reduced motion.
/// - [onTapLabel] lets hosts open a month-grid or year picker when the
///   user taps the label itself.
///
/// ```dart
/// BankPeriodSelector(
///   period: DateTime(2026, 3),
///   unit: BankPeriodUnit.month,
///   onChanged: (next) => setState(() => _period = next),
///   minPeriod: DateTime(2024, 1),
///   maxPeriod: DateTime.now(),
///   onTapLabel: _openMonthGridPicker,
/// )
/// ```
class BankPeriodSelector extends StatefulWidget {
  /// The currently selected period. Any [DateTime] inside the period is
  /// accepted; it is normalised to the start of the [unit] internally.
  final DateTime period;

  /// Granularity of navigation: month, quarter or year.
  final BankPeriodUnit unit;

  /// Called with the start of the previous/next period when a chevron is
  /// tapped. The host owns the state and rebuilds with the new [period].
  final ValueChanged<DateTime> onChanged;

  /// Earliest reachable period (inclusive), compared at [unit] granularity.
  /// The back chevron disables once [period] reaches this bound.
  final DateTime? minPeriod;

  /// Latest reachable period (inclusive), compared at [unit] granularity.
  /// The forward chevron disables once [period] reaches this bound.
  final DateTime? maxPeriod;

  /// Called when the user taps the period label: hosts typically open a
  /// month-grid or year picker here. When `null` the label is not tappable.
  final VoidCallback? onTapLabel;

  /// Semantic label for the back chevron. Defaults to an English label
  /// matching [unit], e.g. `Previous month`.
  final String? previousSemanticLabel;

  /// Semantic label for the forward chevron. Defaults to an English label
  /// matching [unit], e.g. `Next month`.
  final String? nextSemanticLabel;

  const BankPeriodSelector({
    required this.period,
    required this.unit,
    required this.onChanged,
    super.key,
    this.minPeriod,
    this.maxPeriod,
    this.onTapLabel,
    this.previousSemanticLabel,
    this.nextSemanticLabel,
  });

  @override
  State<BankPeriodSelector> createState() => _BankPeriodSelectorState();
}

class _BankPeriodSelectorState extends State<BankPeriodSelector> {
  /// Whether the most recent period change moved forward in time.
  /// Drives the slide direction of the label transition.
  bool _movedForward = true;

  @override
  void didUpdateWidget(BankPeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _normalize(oldWidget.period, oldWidget.unit);
    final current = _normalize(widget.period, widget.unit);
    if (current != previous) {
      _movedForward = current.isAfter(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // Period arithmetic
  // ---------------------------------------------------------------------------

  /// Snaps [period] to the canonical start of its [unit]
  /// (first day of the month / quarter / year).
  static DateTime _normalize(DateTime period, BankPeriodUnit unit) =>
      switch (unit) {
        BankPeriodUnit.month => DateTime(period.year, period.month),
        BankPeriodUnit.quarter =>
          DateTime(period.year, ((period.month - 1) ~/ 3) * 3 + 1),
        BankPeriodUnit.year => DateTime(period.year),
      };

  /// Returns the normalised period [steps] units away from [normalized].
  static DateTime _shift(
    DateTime normalized,
    BankPeriodUnit unit,
    int steps,
  ) =>
      switch (unit) {
        BankPeriodUnit.month =>
          DateTime(normalized.year, normalized.month + steps),
        BankPeriodUnit.quarter =>
          DateTime(normalized.year, normalized.month + steps * 3),
        BankPeriodUnit.year => DateTime(normalized.year + steps),
      };

  /// Formats [normalized] per [unit], converting digits to [numeralStyle].
  static String _formatLabel(
    DateTime normalized,
    BankPeriodUnit unit,
    NumeralStyle numeralStyle,
  ) {
    final raw = switch (unit) {
      BankPeriodUnit.month => DateFormat('MMMM y').format(normalized),
      BankPeriodUnit.quarter =>
        'Q${(normalized.month - 1) ~/ 3 + 1} ${normalized.year}',
      BankPeriodUnit.year => '${normalized.year}',
    };
    return numeralStyle.convert(raw);
  }

  String get _defaultPreviousLabel => switch (widget.unit) {
        BankPeriodUnit.month => 'Previous month',
        BankPeriodUnit.quarter => 'Previous quarter',
        BankPeriodUnit.year => 'Previous year',
      };

  String get _defaultNextLabel => switch (widget.unit) {
        BankPeriodUnit.month => 'Next month',
        BankPeriodUnit.quarter => 'Next quarter',
        BankPeriodUnit.year => 'Next year',
      };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final normalized = _normalize(widget.period, widget.unit);
    final canGoBack = widget.minPeriod == null ||
        normalized.isAfter(_normalize(widget.minPeriod!, widget.unit));
    final canGoForward = widget.maxPeriod == null ||
        normalized.isBefore(_normalize(widget.maxPeriod!, widget.unit));

    final labelText = _formatLabel(normalized, widget.unit, scope.numeralStyle);

    // Slide direction of the label: towards the past or the future,
    // mirrored for RTL so travel always matches reading direction.
    final travel = (_movedForward ? 1.0 : -1.0) * (isRtl ? -1.0 : 1.0);

    final label = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : BankTokens.durationFast,
      switchInCurve: BankTokens.curveStandard,
      switchOutCurve: BankTokens.curveStandard,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final incoming = child.key == ValueKey<DateTime>(normalized);
        final beginDx = (incoming ? 0.25 : -0.25) * travel;
        final position = Tween<Offset>(
          begin: Offset(beginDx, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: position, child: child),
        );
      },
      child: Text(
        labelText,
        key: ValueKey<DateTime>(normalized),
        style: BankTokens.headlineSmall.copyWith(color: theme.onSurface),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    Widget labelArea = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BankTokens.minTapTarget),
      child: Center(child: label),
    );

    if (widget.onTapLabel != null) {
      labelArea = Semantics(
        button: true,
        label: labelText,
        child: InkWell(
          onTap: widget.onTapLabel,
          borderRadius: theme.chipRadius,
          child: labelArea,
        ),
      );
    }

    return Row(
      children: [
        _PeriodChevron(
          icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
          semanticLabel: widget.previousSemanticLabel ?? _defaultPreviousLabel,
          enabled: canGoBack,
          onPressed: () =>
              widget.onChanged(_shift(normalized, widget.unit, -1)),
        ),
        Expanded(child: labelArea),
        _PeriodChevron(
          icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
          semanticLabel: widget.nextSemanticLabel ?? _defaultNextLabel,
          enabled: canGoForward,
          onPressed: () => widget.onChanged(_shift(normalized, widget.unit, 1)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private chevron button
// ---------------------------------------------------------------------------

/// Directional navigation chevron with a 44 px tap target that dims to
/// 40% opacity when disabled at a period bound.
class _PeriodChevron extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;

  const _PeriodChevron({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        color: theme.onSurface,
        disabledColor: theme.onSurface.withValues(alpha: 0.4),
        constraints: const BoxConstraints(
          minWidth: BankTokens.minTapTarget,
          minHeight: BankTokens.minTapTarget,
        ),
      ),
    );
  }
}
