import 'package:flutter/material.dart';

import '../../src/common/money_formatter.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/scope/bank_ui_strings.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

/// Sticky date-grouped section header for transaction lists.
/// Labels sourced from [BankUiStrings] for 'Today' and 'Yesterday'.
class BankTransactionGroupHeader extends StatelessWidget {
  final DateTime date;

  /// Optional strings override; falls back to
  /// [BankUiScope.of(context).strings].
  final BankUiStrings? strings;

  const BankTransactionGroupHeader({
    required this.date,
    super.key,
    this.strings,
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

    return Semantics(
      header: true,
      child: SizedBox(
        height: 36,
        child: Container(
          color: bankTheme.background,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BankTokens.space4,
          ),
          child: Text(
            label.toUpperCase(),
            style: BankTokens.labelSmall.copyWith(
              color: bankTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
