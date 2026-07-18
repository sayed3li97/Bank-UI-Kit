import 'package:flutter/widgets.dart';

/// Locale helpers for money/date formatting.
extension BankFormatContext on BuildContext {
  /// The active locale tag (e.g. `'de'`, `'fr'`, `'en_IN'`) resolved from the
  /// ambient [Localizations], or `null` when none is available.
  ///
  /// Pass this to `BankMoneyFormatter.format`'s `locale` so digit grouping and
  /// the decimal separator follow the user's locale (German `1.234,56`, French
  /// `1 234,56`, Indian lakh grouping `1,23,456`). Kit widgets that render
  /// money resolve it automatically; use it directly when you call the
  /// formatter yourself.
  String? get bankLocale => Localizations.maybeLocaleOf(this)?.toString();
}
