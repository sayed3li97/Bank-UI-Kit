import 'package:flutter/material.dart';

import '../accounts/bank_balance_text.dart';
import '../common/bank_emblem.dart';
import '../common/money_formatter.dart';
import '../models/money.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// A single predicted upcoming bill produced by a bill-forecasting engine
/// (recurring-payment detection, biller history, or open-banking data).
///
/// [confidence] expresses how certain the prediction is on a 0..1 scale.
/// A [confirmed] forecast (user-verified or already scheduled) is always
/// treated as certain, regardless of [confidence].
@immutable
class BankBillForecast {
  const BankBillForecast({
    required this.id,
    required this.billerName,
    required this.predictedAmount,
    required this.expectedDate,
    required this.confidence,
    this.logoUrl,
    this.confirmed = false,
  }) : assert(
          confidence >= 0 && confidence <= 1,
          'confidence must be within 0..1',
        );

  /// Stable identifier of the forecast entry.
  final String id;

  /// Display name of the biller (e.g. `Electric Co`).
  final String billerName;

  /// Optional biller logo shown in the row emblem.
  final String? logoUrl;

  /// The predicted charge amount.
  final Money predictedAmount;

  /// The date the charge is expected to land.
  final DateTime expectedDate;

  /// Prediction certainty on a 0..1 scale.
  final double confidence;

  /// Whether the user (or a scheduled payment) has confirmed this bill.
  final bool confirmed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankBillForecast &&
          other.id == id &&
          other.billerName == billerName &&
          other.logoUrl == logoUrl &&
          other.predictedAmount == predictedAmount &&
          other.expectedDate == expectedDate &&
          other.confidence == confidence &&
          other.confirmed == confirmed;

  @override
  int get hashCode => Object.hash(
        id,
        billerName,
        logoUrl,
        predictedAmount,
        expectedDate,
        confidence,
        confirmed,
      );
}

/// A predicted-upcoming-bills list: the bill-prediction pattern found
/// in leading banking apps.
///
/// Shows a header with a [title], the summed predicted total for the
/// period (rendered through [BankBalanceText] so privacy mode masks it),
/// and an optional See all action. Forecast rows are grouped by week with
/// subtle section labels (This week, Next week, Later) and show the biller
/// emblem, the expected date, and the predicted amount on the trailing
/// edge. Low-confidence predictions (confidence below 0.8) render with a
/// `~` prefix and a secondary numeral style; confirmed rows drop the `~`
/// and read as certain.
///
/// Use it on a payments hub or cashflow screen to warn customers about
/// money that is expected to leave their account soon.
///
/// ```dart
/// BankBillForecastList(
///   forecasts: forecasts,
///   currencyCode: 'USD',
///   onTap: openForecast,
///   onSeeAll: openAllForecasts,
/// )
/// ```
class BankBillForecastList extends StatelessWidget {
  const BankBillForecastList({
    required this.forecasts,
    required this.currencyCode,
    super.key,
    this.onTap,
    this.onSeeAll,
    this.title = 'Upcoming bills',
    this.totalTemplate = '{total} expected this month',
    this.expectedPrefix = 'Expected',
    this.seeAllLabel = 'See all',
    this.thisWeekLabel = 'This week',
    this.nextWeekLabel = 'Next week',
    this.laterLabel = 'Later',
    this.emptyLabel = 'No upcoming bills predicted',
    this.now,
  });

  /// The predicted bills to display, in any order; rows are sorted by
  /// [BankBillForecast.expectedDate] and grouped by week internally.
  final List<BankBillForecast> forecasts;

  /// ISO 4217 code used for the summed total. Every forecast's
  /// [BankBillForecast.predictedAmount] must use this currency.
  final String currencyCode;

  /// Called with the tapped forecast row.
  final void Function(BankBillForecast forecast)? onTap;

  /// Shows a See all action in the header when non-null.
  final VoidCallback? onSeeAll;

  /// Header title.
  final String title;

  /// Template for the summary line under the title. The `{total}`
  /// placeholder is replaced by the summed amount, rendered through
  /// [BankBalanceText] so privacy mode masks it.
  final String totalTemplate;

  /// Word placed before the formatted expected date on each row.
  final String expectedPrefix;

  /// Label of the See all header action.
  final String seeAllLabel;

  /// Section label for bills expected in the current week.
  final String thisWeekLabel;

  /// Section label for bills expected next week.
  final String nextWeekLabel;

  /// Section label for bills expected after next week.
  final String laterLabel;

  /// Placeholder text shown when [forecasts] is empty.
  final String emptyLabel;

  /// Reference date used for week grouping. Defaults to `DateTime.now()`;
  /// override for deterministic rendering in tests and previews.
  final DateTime? now;

  /// Predictions below this confidence render the `~` prefix and the
  /// secondary numeral style (unless confirmed).
  static const double _confidenceThreshold = 0.8;

  Money get _total => forecasts.fold(
        Money.zero(currencyCode),
        (Money sum, BankBillForecast forecast) =>
            sum + forecast.predictedAmount,
      );

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);

    final sections = _groupByWeek(forecasts, now ?? DateTime.now());
    final sectionLabels = <_ForecastWeek, String>{
      _ForecastWeek.thisWeek: thisWeekLabel,
      _ForecastWeek.nextWeek: nextWeekLabel,
      _ForecastWeek.later: laterLabel,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.cardRadius,
        boxShadow: BankTokens.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: theme.cardRadius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              if (forecasts.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    BankTokens.space4,
                    0,
                    BankTokens.space4,
                    BankTokens.space4,
                  ),
                  child: Text(
                    emptyLabel,
                    style: BankTokens.bodyMedium
                        .copyWith(color: theme.onSurfaceVariant),
                  ),
                )
              else ...[
                for (final week in _ForecastWeek.values)
                  if (sections[week]!.isNotEmpty) ...[
                    _SectionLabel(
                      label: sectionLabels[week]!,
                      theme: theme,
                    ),
                    for (final forecast in sections[week]!)
                      _ForecastRow(
                        forecast: forecast,
                        expectedPrefix: expectedPrefix,
                        lowConfidence: !forecast.confirmed &&
                            forecast.confidence < _confidenceThreshold,
                        theme: theme,
                        onTap: onTap == null ? null : () => onTap!(forecast),
                      ),
                  ],
                const SizedBox(height: BankTokens.space2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BankThemeData theme) {
    final hasPlaceholder = totalTemplate.contains('{total}');
    final parts = totalTemplate.split('{total}');
    final prefix = hasPlaceholder ? parts.first : '';
    final suffix =
        hasPlaceholder ? parts.sublist(1).join('{total}') : ' $totalTemplate';
    final secondary =
        BankTokens.bodySmall.copyWith(color: theme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BankTokens.space4,
        BankTokens.space4,
        BankTokens.space2,
        BankTokens.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      BankTokens.headlineSmall.copyWith(color: theme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: BankTokens.space1),
                Row(
                  children: [
                    if (prefix.isNotEmpty)
                      Flexible(
                        child: Text(
                          prefix,
                          style: secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    BankBalanceText(
                      money: _total,
                      size: BankBalanceSize.medium,
                    ),
                    if (suffix.isNotEmpty)
                      Flexible(
                        child: Text(
                          suffix,
                          style: secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
                minimumSize: const Size(
                  BankTokens.minTapTarget,
                  BankTokens.minTapTarget,
                ),
              ),
              child: Text(seeAllLabel, style: BankTokens.labelLarge),
            ),
        ],
      ),
    );
  }

  /// Buckets [items] into week sections relative to [reference], sorted by
  /// expected date inside each bucket. Anything before the end of the
  /// current calendar week (Monday-based) lands in This week, the seven
  /// days after that in Next week, and the rest in Later.
  static Map<_ForecastWeek, List<BankBillForecast>> _groupByWeek(
    List<BankBillForecast> items,
    DateTime reference,
  ) {
    final today = DateTime(reference.year, reference.month, reference.day);
    final thisWeekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final nextWeekStart = thisWeekStart.add(const Duration(days: 7));
    final laterStart = thisWeekStart.add(const Duration(days: 14));

    final sorted = List<BankBillForecast>.of(items)
      ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

    final sections = <_ForecastWeek, List<BankBillForecast>>{
      for (final week in _ForecastWeek.values) week: <BankBillForecast>[],
    };
    for (final forecast in sorted) {
      final day = DateTime(
        forecast.expectedDate.year,
        forecast.expectedDate.month,
        forecast.expectedDate.day,
      );
      final week = day.isBefore(nextWeekStart)
          ? _ForecastWeek.thisWeek
          : day.isBefore(laterStart)
              ? _ForecastWeek.nextWeek
              : _ForecastWeek.later;
      sections[week]!.add(forecast);
    }
    return sections;
  }
}

/// Week buckets used by [BankBillForecastList] section grouping.
enum _ForecastWeek { thisWeek, nextWeek, later }

/// Subtle week section label.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.theme,
  });

  final String label;
  final BankThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BankTokens.space4,
        BankTokens.space3,
        BankTokens.space4,
        BankTokens.space1,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: BankTokens.labelMedium.copyWith(
            color: theme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A single forecast row: biller emblem, name, expected date, and the
/// predicted amount with an optional approximation marker.
class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.forecast,
    required this.expectedPrefix,
    required this.lowConfidence,
    required this.theme,
    this.onTap,
  });

  final BankBillForecast forecast;
  final String expectedPrefix;
  final bool lowConfidence;
  final BankThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shortDate = BankDateFormatter.formatShort(forecast.expectedDate);
    final expectedText = '$expectedPrefix $shortDate';
    final amountColor =
        lowConfidence ? theme.onSurfaceVariant : theme.onSurface;

    return Semantics(
      button: onTap != null,
      label: '${forecast.billerName}, $expectedText'
          '${lowConfidence ? ', estimated' : ''}',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BankTokens.space12 + BankTokens.space4,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space2,
            ),
            child: Row(
              children: [
                BankEmblem(
                  imageUrl: forecast.logoUrl,
                  initialsFrom: forecast.billerName,
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.billerName,
                        style: BankTokens.bodyLarge
                            .copyWith(color: theme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expectedText,
                        style: BankTokens.bodySmall
                            .copyWith(color: theme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space2),
                if (lowConfidence)
                  Text(
                    '~',
                    style: theme.numeralSmall.copyWith(color: amountColor),
                    semanticsLabel: 'approximately',
                  ),
                BankBalanceText(
                  money: forecast.predictedAmount,
                  size: BankBalanceSize.small,
                  style: theme.numeralSmall.copyWith(color: amountColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
