import 'package:flutter/material.dart';

import '../../src/common/bank_format_context.dart';
import '../../src/common/money_formatter.dart';
import '../../src/models/money.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/scope/bank_ui_strings.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Sticky date-grouped section header for transaction lists.
///
/// Renders the date as tracked-caps micro-type ([BankTokens.caption])
/// directly on the list background — no full-bleed band — so the header
/// separates groups through typography rather than a grey stripe. An
/// optional [dayTotal] renders trailing in tabular numerals
/// (`numeralSmall`) so a day's net spend can be scanned in place.
///
/// Labels are sourced from [BankUiStrings] for 'Today' and 'Yesterday'.
/// [dayTotal] respects privacy mode, the ambient numeral style, and the
/// ambient locale, and drops zero minor units (`£120`, not `£120.00`).
class BankTransactionGroupHeader extends StatelessWidget {
  final DateTime date;

  /// Optional strings override; falls back to
  /// [BankUiScope.of(context).strings].
  final BankUiStrings? strings;

  /// Optional day aggregate (e.g. the day's net spend) rendered trailing
  /// in tabular numerals. Hidden when null.
  final Money? dayTotal;

  /// Whether [dayTotal] renders with an explicit `+` when positive.
  /// Defaults to `true`, matching the transaction rows beneath.
  final bool showDayTotalSign;

  /// Overrides the header height. Defaults to 36.
  final double? height;

  /// Overrides the label padding. Defaults to horizontal
  /// [BankTokens.space4].
  final EdgeInsetsGeometry? padding;

  /// Optional header fill. Defaults to `null` — the header sits directly
  /// on the list background so no band is painted. (Sticky-header hosts
  /// that scroll content beneath can pass the scaffold background.)
  final Color? backgroundColor;

  /// Merged over the label style ([BankTokens.caption], tracked caps, in
  /// `onSurfaceVariant`).
  final TextStyle? labelStyle;

  /// Merged over the day-total style (theme `numeralSmall` in
  /// `onSurfaceVariant`).
  final TextStyle? dayTotalStyle;

  /// Overrides the header semantics label. Defaults to the visible text.
  final String? semanticLabel;

  const BankTransactionGroupHeader({
    required this.date,
    super.key,
    this.strings,
    this.dayTotal,
    this.showDayTotalSign = true,
    this.height,
    this.padding,
    this.backgroundColor,
    this.labelStyle,
    this.dayTotalStyle,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final scope = BankUiScope.of(context);
    final s = strings ?? scope.strings;

    final label = BankDateFormatter.formatGroupHeader(
      date: date,
      todayLabel: s.today,
      yesterdayLabel: s.yesterday,
    );

    final total = dayTotal;
    String? totalText;
    if (total != null) {
      totalText = scope.privacyEnabled
          ? scope.strings.balanceHidden
          : BankMoneyFormatter.format(
              amount: total.amount,
              currencyCode: total.currencyCode,
              numeralStyle: scope.numeralStyle,
              locale: context.bankLocale,
              showSign: showDayTotalSign,
              trimZeroCents: true,
            );
    }

    return Semantics(
      header: true,
      label: semanticLabel,
      child: Container(
        height: height ?? 36,
        color: backgroundColor,
        padding: padding ??
            const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space4,
            ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BankTokens.caption
                    .copyWith(
                      color: bankTheme.onSurfaceVariant,
                      // Tracked caps: the label is uppercased above, so
                      // positive tracking is typographically safe here
                      // (caption itself tracks at 0 for sentence case).
                      letterSpacing: 0.8,
                    )
                    .merge(labelStyle),
              ),
            ),
            if (totalText != null) ...[
              const SizedBox(width: BankTokens.space2),
              Text(
                totalText,
                style: bankTheme.numeralSmall
                    .copyWith(color: bankTheme.onSurfaceVariant)
                    .merge(dayTotalStyle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
