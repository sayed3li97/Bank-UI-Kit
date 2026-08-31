import 'package:flutter/widgets.dart';

import '../common/money_formatter.dart';
import '../models/transaction.dart';
import '../payments/bank_standing_order_tile.dart';
import '../scope/bank_ui_scope.dart';
import '../scope/bank_ui_strings.dart';
import 'bank_l10n.dart';
import 'bank_l10n_en.dart';

/// Every string the kit renders, already resolved for one [BuildContext].
///
/// Three sources feed it. The first that has an answer wins:
///
/// 1. a [BankUiStrings] field the host changed from its shipped default and
///    passed to [BankUiScope]. An explicit override always outranks a
///    translation, because a bank that insists on "Profit rate" means it in
///    every language;
/// 2. the translation for the ambient [Locale], when the host installed
///    [BankL10n.delegate];
/// 3. the built-in English.
///
/// It never throws and never returns null. A host that installs no delegate
/// and overrides nothing renders exactly the English every release before
/// 0.4.0 rendered, so adopting the kit's localisation is opt-in.
///
/// Read it once per `build`:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final strings = BankStrings.of(context);
///   return Text(strings.actionConfirm);
/// }
/// ```
@immutable
class BankStrings {
  const BankStrings._(this._overrides, this._l10n);

  /// Resolves the kit's copy for [context].
  ///
  /// Registers dependencies on both [BankUiScope] and [Localizations], so a
  /// widget that calls this rebuilds when the host swaps either. Like any
  /// `Localizations` read it belongs in `build`, never in `initState`.
  factory BankStrings.of(BuildContext context) => BankStrings._(
        BankUiScope.maybeOf(context)?.strings ?? BankUiStrings.defaults,
        BankL10n.of(context),
      );

  /// English, always loaded, used whenever the host installed no delegate or
  /// the ambient locale has no catalogue of its own.
  static final BankL10n _en = BankL10nEn();

  final BankUiStrings _overrides;
  final BankL10n? _l10n;

  /// Returns [value] when the caller changed it from [shipped], else `null`.
  ///
  /// Widgets whose copy arrives through a non-nullable `String` parameter
  /// with an English default use this to tell "the host chose this wording"
  /// from "the host left the default alone", without the breaking change of
  /// turning that parameter nullable:
  ///
  /// ```dart
  /// final title = BankStrings.override(widget.title, _defaultTitle) ??
  ///     strings.updateTitle;
  /// ```
  ///
  /// The one false negative — a host that explicitly assigns exactly the
  /// shipped English — is indistinguishable from assigning nothing, and
  /// produces the same English on an English device.
  static String? override(String value, String shipped) =>
      value == shipped ? null : value;

  // ---------------------------------------------------------------------------
  // Hand-authored accessors
  // ---------------------------------------------------------------------------

  /// Placeholder glyphs shown in place of a balance in privacy mode.
  ///
  /// Deliberately not translated: these are dots, and every locale hides a
  /// balance behind the same dots. Hosts that want a different mask still
  /// override [BankUiStrings.balanceHidden].
  String get balanceHidden => _overrides.balanceHidden;

  /// Length of an instalment plan in whole months.
  ///
  /// Resolves an override first. [BankUiStrings.installmentMonths] is a
  /// `{n}` template rather than an ICU message, so a host override cannot
  /// express plural categories; the catalogue can, and does for Arabic's
  /// six.
  String installmentMonths(int count) {
    final template = override(
      _overrides.installmentMonths,
      BankUiStrings.defaults.installmentMonths,
    );
    if (template != null) return template.replaceAll('{n}', '$count');
    return _l10n?.installmentMonths(count) ?? _en.installmentMonths(count);
  }

  /// The rate label for the ambient finance mode.
  ///
  /// Returns [profitRate] when the nearest [BankUiScope] has
  /// `islamicFinanceMode` set, and [interestRate] otherwise, so callers do
  /// not repeat the conditional at every rate-bearing widget.
  String rateLabel({required bool islamicFinanceMode}) =>
      islamicFinanceMode ? profitRate : interestRate;

  /// The display name of a spending category.
  ///
  /// Pass `short: true` where the label rides inside a filter chip, which
  /// shortens only [TransactionCategory.creditPayment] — "Credit" instead of
  /// "Credit Payment". Every other category has one name at both widths.
  String categoryLabel(TransactionCategory category, {bool short = false}) =>
      switch (category) {
        TransactionCategory.groceries => categoryGroceries,
        TransactionCategory.dining => categoryDining,
        TransactionCategory.transport => categoryTransport,
        TransactionCategory.entertainment => categoryEntertainment,
        TransactionCategory.utilities => categoryUtilities,
        TransactionCategory.health => categoryHealth,
        TransactionCategory.shopping => categoryShopping,
        TransactionCategory.travel => categoryTravel,
        TransactionCategory.education => categoryEducation,
        TransactionCategory.subscription => categorySubscription,
        TransactionCategory.transfer => categoryTransfer,
        TransactionCategory.income => categoryIncome,
        TransactionCategory.investment => categoryInvestment,
        TransactionCategory.creditPayment =>
          short ? categoryCredit : categoryCreditPayment,
        TransactionCategory.other => categoryOther,
      };

  /// Compact relative time for an activity feed, in the ambient language.
  ///
  /// Wraps [BankDateFormatter.formatRelative] with this catalogue's labels
  /// and the ambient [locale], so a caller does not have to thread five
  /// arguments through every timestamp.
  String relativeTime(DateTime date, {DateTime? now, String? locale}) =>
      BankDateFormatter.formatRelative(
        date,
        now: now,
        locale: locale,
        justNowLabel: justNow,
        minutesAgoLabel: (int minutes) => minutesAgoShort('$minutes'),
        hoursAgoLabel: (int hours) => hoursAgoShort('$hours'),
        daysAgoLabel: (int days) => daysAgoShort('$days'),
      );

  /// The display name of a recurring-payment cadence.
  ///
  /// `BankRecurringPattern.label` stays English by contract — hosts read it
  /// for their own copy — so every render site inside the kit resolves the
  /// word here instead. Without one shared helper the standing-order row and
  /// the recurring-merchant row drift apart and print "يومي" on one screen
  /// and "Daily" on the next for the same value.
  String frequencyLabel(BankRecurringPattern pattern) => switch (pattern) {
        BankRecurringPattern.daily => frequencyDaily,
        BankRecurringPattern.weekly => frequencyWeekly,
        BankRecurringPattern.biweekly => frequencyBiweekly,
        BankRecurringPattern.monthly => frequencyMonthly,
      };

  /// The display name of a transaction status.
  String statusLabel(TransactionStatus status) => switch (status) {
        TransactionStatus.pending => statusPending,
        TransactionStatus.cleared => statusCleared,
        TransactionStatus.declined => statusDeclined,
        TransactionStatus.refunded => statusRefunded,
        TransactionStatus.scheduled => statusScheduled,
      };

  // ---------------------------------------------------------------------------
  // Generated accessors
  // ---------------------------------------------------------------------------

  // --- GENERATED ACCESSORS: do not edit by hand (source: lib/l10n/bank_ui_kit_en.arb) ---
  /// Relative day label for something dated today.
  ///
  /// Overridden by `BankUiStrings.today` when the host changed it.
  String get today =>
      override(_overrides.today, BankUiStrings.defaults.today) ??
      _l10n?.today ??
      _en.today;

  /// Relative day label for something dated yesterday.
  ///
  /// Overridden by `BankUiStrings.yesterday` when the host changed it.
  String get yesterday =>
      override(_overrides.yesterday, BankUiStrings.defaults.yesterday) ??
      _l10n?.yesterday ??
      _en.yesterday;

  /// Relative timestamp for an event less than a minute old. Lower case: it
  /// sits inline after a merchant name, not at the head of a sentence.
  String get justNow => _l10n?.justNow ?? _en.justNow;

  /// Relative timestamp in whole minutes.
  String minutesAgo(int count) =>
      _l10n?.minutesAgo(count) ?? _en.minutesAgo(count);

  /// Relative timestamp in whole hours.
  String hoursAgo(int count) => _l10n?.hoursAgo(count) ?? _en.hoursAgo(count);

  /// Relative timestamp in whole days.
  String daysAgo(int count) => _l10n?.daysAgo(count) ?? _en.daysAgo(count);

  /// Abbreviated relative timestamp in minutes, for dense rows.
  String minutesAgoShort(String count) =>
      _l10n?.minutesAgoShort(count) ?? _en.minutesAgoShort(count);

  /// Abbreviated relative timestamp in hours, for dense rows.
  String hoursAgoShort(String count) =>
      _l10n?.hoursAgoShort(count) ?? _en.hoursAgoShort(count);

  /// Abbreviated relative timestamp in days, for dense rows.
  String daysAgoShort(String count) =>
      _l10n?.daysAgoShort(count) ?? _en.daysAgoShort(count);

  /// Transaction status: authorised but not yet settled.
  ///
  /// Overridden by `BankUiStrings.pending` when the host changed it.
  String get statusPending =>
      override(_overrides.pending, BankUiStrings.defaults.pending) ??
      _l10n?.statusPending ??
      _en.statusPending;

  /// Transaction status: settled.
  ///
  /// Overridden by `BankUiStrings.cleared` when the host changed it.
  String get statusCleared =>
      override(_overrides.cleared, BankUiStrings.defaults.cleared) ??
      _l10n?.statusCleared ??
      _en.statusCleared;

  /// Transaction status: refused by the issuer.
  ///
  /// Overridden by `BankUiStrings.declined` when the host changed it.
  String get statusDeclined =>
      override(_overrides.declined, BankUiStrings.defaults.declined) ??
      _l10n?.statusDeclined ??
      _en.statusDeclined;

  /// Transaction status: money returned to the customer.
  ///
  /// Overridden by `BankUiStrings.refunded` when the host changed it.
  String get statusRefunded =>
      override(_overrides.refunded, BankUiStrings.defaults.refunded) ??
      _l10n?.statusRefunded ??
      _en.statusRefunded;

  /// Transaction status: queued for a future date.
  ///
  /// Overridden by `BankUiStrings.scheduled` when the host changed it.
  String get statusScheduled =>
      override(_overrides.scheduled, BankUiStrings.defaults.scheduled) ??
      _l10n?.statusScheduled ??
      _en.statusScheduled;

  /// Card or account status: temporarily blocked by the customer.
  ///
  /// Overridden by `BankUiStrings.frozen` when the host changed it.
  String get statusFrozen =>
      override(_overrides.frozen, BankUiStrings.defaults.frozen) ??
      _l10n?.statusFrozen ??
      _en.statusFrozen;

  /// Card or account status: limited by the bank.
  ///
  /// Overridden by `BankUiStrings.restricted` when the host changed it.
  String get statusRestricted =>
      override(_overrides.restricted, BankUiStrings.defaults.restricted) ??
      _l10n?.statusRestricted ??
      _en.statusRestricted;

  /// Card or account status: usable as normal.
  ///
  /// Overridden by `BankUiStrings.active` when the host changed it.
  String get statusActive =>
      override(_overrides.active, BankUiStrings.defaults.active) ??
      _l10n?.statusActive ??
      _en.statusActive;

  /// Button that closes a finished flow.
  ///
  /// Overridden by `BankUiStrings.done` when the host changed it.
  String get actionDone =>
      override(_overrides.done, BankUiStrings.defaults.done) ??
      _l10n?.actionDone ??
      _en.actionDone;

  /// Button that abandons the current action.
  ///
  /// Overridden by `BankUiStrings.cancel` when the host changed it.
  String get actionCancel =>
      override(_overrides.cancel, BankUiStrings.defaults.cancel) ??
      _l10n?.actionCancel ??
      _en.actionCancel;

  /// Button that commits the current action.
  ///
  /// Overridden by `BankUiStrings.confirm` when the host changed it.
  String get actionConfirm =>
      override(_overrides.confirm, BankUiStrings.defaults.confirm) ??
      _l10n?.actionConfirm ??
      _en.actionConfirm;

  /// Button that advances to the next step.
  ///
  /// Overridden by `BankUiStrings.next` when the host changed it.
  String get actionNext =>
      override(_overrides.next, BankUiStrings.defaults.next) ??
      _l10n?.actionNext ??
      _en.actionNext;

  /// Button that returns to the previous step.
  ///
  /// Overridden by `BankUiStrings.back` when the host changed it.
  String get actionBack =>
      override(_overrides.back, BankUiStrings.defaults.back) ??
      _l10n?.actionBack ??
      _en.actionBack;

  /// Button that passes over an optional step.
  ///
  /// Overridden by `BankUiStrings.skip` when the host changed it.
  String get actionSkip =>
      override(_overrides.skip, BankUiStrings.defaults.skip) ??
      _l10n?.actionSkip ??
      _en.actionSkip;

  /// Button that agrees to a request.
  ///
  /// Overridden by `BankUiStrings.accept` when the host changed it.
  String get actionAccept =>
      override(_overrides.accept, BankUiStrings.defaults.accept) ??
      _l10n?.actionAccept ??
      _en.actionAccept;

  /// Button that refuses a request.
  ///
  /// Overridden by `BankUiStrings.decline` when the host changed it.
  String get actionDecline =>
      override(_overrides.decline, BankUiStrings.defaults.decline) ??
      _l10n?.actionDecline ??
      _en.actionDecline;

  /// Button that opens the platform share sheet.
  ///
  /// Overridden by `BankUiStrings.share` when the host changed it.
  String get actionShare =>
      override(_overrides.share, BankUiStrings.defaults.share) ??
      _l10n?.actionShare ??
      _en.actionShare;

  /// Button that starts a transaction dispute.
  ///
  /// Overridden by `BankUiStrings.dispute` when the host changed it.
  String get actionDispute =>
      override(_overrides.dispute, BankUiStrings.defaults.dispute) ??
      _l10n?.actionDispute ??
      _en.actionDispute;

  /// Button that reports a transaction as suspicious.
  ///
  /// Overridden by `BankUiStrings.report` when the host changed it.
  String get actionReport =>
      override(_overrides.report, BankUiStrings.defaults.report) ??
      _l10n?.actionReport ??
      _en.actionReport;

  /// Button that repeats a failed operation.
  ///
  /// Overridden by `BankUiStrings.retry` when the host changed it.
  String get actionRetry =>
      override(_overrides.retry, BankUiStrings.defaults.retry) ??
      _l10n?.actionRetry ??
      _en.actionRetry;

  /// Button or icon that dismisses an overlay.
  String get actionClose => _l10n?.actionClose ?? _en.actionClose;

  /// Button that copies a value to the clipboard.
  String get actionCopy => _l10n?.actionCopy ?? _en.actionCopy;

  /// Confirmation shown after a value is copied.
  String get actionCopied => _l10n?.actionCopied ?? _en.actionCopied;

  /// Button that opens a fuller view of the current item.
  String get actionViewDetails =>
      _l10n?.actionViewDetails ?? _en.actionViewDetails;

  /// Button that opens a support channel.
  ///
  /// Overridden by `BankUiStrings.contactSupport` when the host changed it.
  String get actionContactSupport =>
      override(
        _overrides.contactSupport,
        BankUiStrings.defaults.contactSupport,
      ) ??
      _l10n?.actionContactSupport ??
      _en.actionContactSupport;

  /// Option that lets the customer enter their own value.
  ///
  /// Overridden by `BankUiStrings.custom` when the host changed it.
  String get actionCustom =>
      override(_overrides.custom, BankUiStrings.defaults.custom) ??
      _l10n?.actionCustom ??
      _en.actionCustom;

  /// Primary action: start an outbound payment.
  ///
  /// Overridden by `BankUiStrings.sendMoney` when the host changed it.
  String get sendMoney =>
      override(_overrides.sendMoney, BankUiStrings.defaults.sendMoney) ??
      _l10n?.sendMoney ??
      _en.sendMoney;

  /// Primary action: ask someone to pay you.
  ///
  /// Overridden by `BankUiStrings.requestMoney` when the host changed it.
  String get requestMoney =>
      override(_overrides.requestMoney, BankUiStrings.defaults.requestMoney) ??
      _l10n?.requestMoney ??
      _en.requestMoney;

  /// Primary action: top up an account or pot.
  ///
  /// Overridden by `BankUiStrings.addMoney` when the host changed it.
  String get addMoney =>
      override(_overrides.addMoney, BankUiStrings.defaults.addMoney) ??
      _l10n?.addMoney ??
      _en.addMoney;

  /// Primary action: take money out.
  ///
  /// Overridden by `BankUiStrings.withdraw` when the host changed it.
  String get withdraw =>
      override(_overrides.withdraw, BankUiStrings.defaults.withdraw) ??
      _l10n?.withdraw ??
      _en.withdraw;

  /// Screen-reader text replacing a balance in privacy mode.
  String get balanceHiddenSpoken =>
      _l10n?.balanceHiddenSpoken ?? _en.balanceHiddenSpoken;

  /// Screen-reader text replacing a loyalty-points balance in privacy mode.
  String get pointsBalanceHiddenSpoken =>
      _l10n?.pointsBalanceHiddenSpoken ?? _en.pointsBalanceHiddenSpoken;

  /// Label for the spendable portion of a limit or balance.
  ///
  /// Overridden by `BankUiStrings.available` when the host changed it.
  String get labelAvailable =>
      override(_overrides.available, BankUiStrings.defaults.available) ??
      _l10n?.labelAvailable ??
      _en.labelAvailable;

  /// Label for the consumed portion of a limit.
  ///
  /// Overridden by `BankUiStrings.used` when the host changed it.
  String get labelUsed =>
      override(_overrides.used, BankUiStrings.defaults.used) ??
      _l10n?.labelUsed ??
      _en.labelUsed;

  /// Label for a savings target.
  ///
  /// Overridden by `BankUiStrings.goal` when the host changed it.
  String get labelGoal =>
      override(_overrides.goal, BankUiStrings.defaults.goal) ??
      _l10n?.labelGoal ??
      _en.labelGoal;

  /// Label for how far along a goal is.
  ///
  /// Overridden by `BankUiStrings.progress` when the host changed it.
  String get labelProgress =>
      override(_overrides.progress, BankUiStrings.defaults.progress) ??
      _l10n?.labelProgress ??
      _en.labelProgress;

  /// Label for a monetary value field.
  String get labelAmount => _l10n?.labelAmount ?? _en.labelAmount;

  /// Label for an account's currency.
  String get labelCurrency => _l10n?.labelCurrency ?? _en.labelCurrency;

  /// Label for an app version number.
  String get labelVersion => _l10n?.labelVersion ?? _en.labelVersion;

  /// Label for the time data was last refreshed.
  String get labelLastUpdated =>
      _l10n?.labelLastUpdated ?? _en.labelLastUpdated;

  /// Conventional-finance rate label.
  ///
  /// Overridden by `BankUiStrings.interestRate` when the host changed it.
  String get interestRate =>
      override(_overrides.interestRate, BankUiStrings.defaults.interestRate) ??
      _l10n?.interestRate ??
      _en.interestRate;

  /// Islamic-finance equivalent of an interest rate.
  ///
  /// Overridden by `BankUiStrings.profitRate` when the host changed it.
  String get profitRate =>
      override(_overrides.profitRate, BankUiStrings.defaults.profitRate) ??
      _l10n?.profitRate ??
      _en.profitRate;

  /// Abbreviation for annual percentage rate.
  ///
  /// Overridden by `BankUiStrings.annualPercentageRate` when the host changed
  /// it.
  String get annualPercentageRate =>
      override(
        _overrides.annualPercentageRate,
        BankUiStrings.defaults.annualPercentageRate,
      ) ??
      _l10n?.annualPercentageRate ??
      _en.annualPercentageRate;

  /// Badge for a plan that charges no interest.
  ///
  /// Overridden by `BankUiStrings.interestFree` when the host changed it.
  String get interestFree =>
      override(_overrides.interestFree, BankUiStrings.defaults.interestFree) ??
      _l10n?.interestFree ??
      _en.interestFree;

  /// Suffix appended to a monthly amount, e.g. 25.00/month.
  ///
  /// Overridden by `BankUiStrings.perMonth` when the host changed it.
  String get perMonth =>
      override(_overrides.perMonth, BankUiStrings.defaults.perMonth) ??
      _l10n?.perMonth ??
      _en.perMonth;

  /// Short suffix appended to a monthly price in tight layouts.
  String get perMonthShort => _l10n?.perMonthShort ?? _en.perMonthShort;

  /// Action that moves money into a savings pot.
  ///
  /// Overridden by `BankUiStrings.addToPot` when the host changed it.
  String get addToPot =>
      override(_overrides.addToPot, BankUiStrings.defaults.addToPot) ??
      _l10n?.addToPot ??
      _en.addToPot;

  /// Action that moves money out of a savings pot.
  ///
  /// Overridden by `BankUiStrings.withdrawFromPot` when the host changed it.
  String get withdrawFromPot =>
      override(
        _overrides.withdrawFromPot,
        BankUiStrings.defaults.withdrawFromPot,
      ) ??
      _l10n?.withdrawFromPot ??
      _en.withdrawFromPot;

  /// Action that divides a bill into equal shares.
  ///
  /// Overridden by `BankUiStrings.splitEqually` when the host changed it.
  String get splitEqually =>
      override(_overrides.splitEqually, BankUiStrings.defaults.splitEqually) ??
      _l10n?.splitEqually ??
      _en.splitEqually;

  /// Prompt asking the customer to authenticate with their PIN.
  ///
  /// Overridden by `BankUiStrings.confirmPin` when the host changed it.
  String get confirmPin =>
      override(_overrides.confirmPin, BankUiStrings.defaults.confirmPin) ??
      _l10n?.confirmPin ??
      _en.confirmPin;

  /// Title shown when a session has already ended.
  ///
  /// Overridden by `BankUiStrings.sessionTimeout` when the host changed it.
  String get sessionTimeout =>
      override(
        _overrides.sessionTimeout,
        BankUiStrings.defaults.sessionTimeout,
      ) ??
      _l10n?.sessionTimeout ??
      _en.sessionTimeout;

  /// Body shown when a session has already ended.
  ///
  /// Overridden by `BankUiStrings.sessionTimeoutBody` when the host changed it.
  String get sessionTimeoutBody =>
      override(
        _overrides.sessionTimeoutBody,
        BankUiStrings.defaults.sessionTimeoutBody,
      ) ??
      _l10n?.sessionTimeoutBody ??
      _en.sessionTimeoutBody;

  /// Empty state for a transaction list.
  ///
  /// Overridden by `BankUiStrings.noTransactions` when the host changed it.
  String get noTransactions =>
      override(
        _overrides.noTransactions,
        BankUiStrings.defaults.noTransactions,
      ) ??
      _l10n?.noTransactions ??
      _en.noTransactions;

  /// Loading state for a transaction list.
  ///
  /// Overridden by `BankUiStrings.loadingTransactions` when the host changed
  /// it.
  String get loadingTransactions =>
      override(
        _overrides.loadingTransactions,
        BankUiStrings.defaults.loadingTransactions,
      ) ??
      _l10n?.loadingTransactions ??
      _en.loadingTransactions;

  /// Confirmation that a transfer succeeded.
  ///
  /// Overridden by `BankUiStrings.transferSuccess` when the host changed it.
  String get transferSuccess =>
      override(
        _overrides.transferSuccess,
        BankUiStrings.defaults.transferSuccess,
      ) ??
      _l10n?.transferSuccess ??
      _en.transferSuccess;

  /// Notice that a transfer did not go through.
  ///
  /// Overridden by `BankUiStrings.transferFailure` when the host changed it.
  String get transferFailure =>
      override(
        _overrides.transferFailure,
        BankUiStrings.defaults.transferFailure,
      ) ??
      _l10n?.transferFailure ??
      _en.transferFailure;

  /// Title of the new-device security notice.
  ///
  /// Overridden by `BankUiStrings.newDevice` when the host changed it.
  String get newDevice =>
      override(_overrides.newDevice, BankUiStrings.defaults.newDevice) ??
      _l10n?.newDevice ??
      _en.newDevice;

  /// Body of the new-device security notice.
  ///
  /// Overridden by `BankUiStrings.newDeviceBody` when the host changed it.
  String get newDeviceBody =>
      override(
        _overrides.newDeviceBody,
        BankUiStrings.defaults.newDeviceBody,
      ) ??
      _l10n?.newDeviceBody ??
      _en.newDeviceBody;

  /// Title of the compromised-device security notice.
  ///
  /// Overridden by `BankUiStrings.compromisedDevice` when the host changed it.
  String get compromisedDevice =>
      override(
        _overrides.compromisedDevice,
        BankUiStrings.defaults.compromisedDevice,
      ) ??
      _l10n?.compromisedDevice ??
      _en.compromisedDevice;

  /// Body of the compromised-device security notice.
  ///
  /// Overridden by `BankUiStrings.compromisedDeviceBody` when the host changed
  /// it.
  String get compromisedDeviceBody =>
      override(
        _overrides.compromisedDeviceBody,
        BankUiStrings.defaults.compromisedDeviceBody,
      ) ??
      _l10n?.compromisedDeviceBody ??
      _en.compromisedDeviceBody;

  /// Title shown while identity documents are being checked.
  ///
  /// Overridden by `BankUiStrings.verificationUnderReview` when the host
  /// changed it.
  String get verificationUnderReview =>
      override(
        _overrides.verificationUnderReview,
        BankUiStrings.defaults.verificationUnderReview,
      ) ??
      _l10n?.verificationUnderReview ??
      _en.verificationUnderReview;

  /// Body shown while identity documents are being checked.
  ///
  /// Overridden by `BankUiStrings.verificationUnderReviewBody` when the host
  /// changed it.
  String get verificationUnderReviewBody =>
      override(
        _overrides.verificationUnderReviewBody,
        BankUiStrings.defaults.verificationUnderReviewBody,
      ) ??
      _l10n?.verificationUnderReviewBody ??
      _en.verificationUnderReviewBody;

  /// Spending category: supermarkets and food shops.
  String get categoryGroceries =>
      _l10n?.categoryGroceries ?? _en.categoryGroceries;

  /// Spending category: restaurants, cafés, takeaway.
  String get categoryDining => _l10n?.categoryDining ?? _en.categoryDining;

  /// Spending category: fuel, transit, taxis.
  String get categoryTransport =>
      _l10n?.categoryTransport ?? _en.categoryTransport;

  /// Spending category: cinema, events, games.
  String get categoryEntertainment =>
      _l10n?.categoryEntertainment ?? _en.categoryEntertainment;

  /// Spending category: electricity, water, internet.
  String get categoryUtilities =>
      _l10n?.categoryUtilities ?? _en.categoryUtilities;

  /// Spending category: pharmacy, clinics, insurance.
  String get categoryHealth => _l10n?.categoryHealth ?? _en.categoryHealth;

  /// Spending category: retail and online purchases.
  String get categoryShopping =>
      _l10n?.categoryShopping ?? _en.categoryShopping;

  /// Spending category: flights, hotels, holidays.
  String get categoryTravel => _l10n?.categoryTravel ?? _en.categoryTravel;

  /// Spending category: tuition, courses, books.
  String get categoryEducation =>
      _l10n?.categoryEducation ?? _en.categoryEducation;

  /// Spending category: recurring services.
  String get categorySubscription =>
      _l10n?.categorySubscription ?? _en.categorySubscription;

  /// Spending category: money moved between accounts.
  String get categoryTransfer =>
      _l10n?.categoryTransfer ?? _en.categoryTransfer;

  /// Spending category: salary and other money in.
  String get categoryIncome => _l10n?.categoryIncome ?? _en.categoryIncome;

  /// Spending category: brokerage and fund activity.
  String get categoryInvestment =>
      _l10n?.categoryInvestment ?? _en.categoryInvestment;

  /// Spending category: credit-card activity, shown where space is tight.
  String get categoryCredit => _l10n?.categoryCredit ?? _en.categoryCredit;

  /// Spending category: a payment made towards a credit card.
  String get categoryCreditPayment =>
      _l10n?.categoryCreditPayment ?? _en.categoryCreditPayment;

  /// Spending category: anything uncategorised.
  String get categoryOther => _l10n?.categoryOther ?? _en.categoryOther;

  /// Action that adds another category to a split.
  String get categoryAdd => _l10n?.categoryAdd ?? _en.categoryAdd;

  /// Recurring payment frequency: every day.
  String get frequencyDaily => _l10n?.frequencyDaily ?? _en.frequencyDaily;

  /// Recurring payment frequency: every week.
  String get frequencyWeekly => _l10n?.frequencyWeekly ?? _en.frequencyWeekly;

  /// Recurring payment frequency: every two weeks.
  String get frequencyBiweekly =>
      _l10n?.frequencyBiweekly ?? _en.frequencyBiweekly;

  /// Recurring payment frequency: every month.
  String get frequencyMonthly =>
      _l10n?.frequencyMonthly ?? _en.frequencyMonthly;

  /// Alert-preferences group covering security and fraud messages.
  String get notifGroupSecurity =>
      _l10n?.notifGroupSecurity ?? _en.notifGroupSecurity;

  /// Alert-preferences group covering payment messages.
  String get notifGroupPayments =>
      _l10n?.notifGroupPayments ?? _en.notifGroupPayments;

  /// Alert-preferences group covering account activity.
  String get notifGroupAccount =>
      _l10n?.notifGroupAccount ?? _en.notifGroupAccount;

  /// Alert-preferences group covering promotional messages.
  String get notifGroupMarketing =>
      _l10n?.notifGroupMarketing ?? _en.notifGroupMarketing;

  /// Delivery channel: a device push notification.
  String get notifChannelPush =>
      _l10n?.notifChannelPush ?? _en.notifChannelPush;

  /// Delivery channel: email.
  String get notifChannelEmail =>
      _l10n?.notifChannelEmail ?? _en.notifChannelEmail;

  /// Alert type: sign-ins and security events.
  String get notifSecurityAlerts =>
      _l10n?.notifSecurityAlerts ?? _en.notifSecurityAlerts;

  /// Alert type: suspected fraud.
  String get notifFraudWarnings =>
      _l10n?.notifFraudWarnings ?? _en.notifFraudWarnings;

  /// Alert type: identity checks.
  String get notifIdentityVerification =>
      _l10n?.notifIdentityVerification ?? _en.notifIdentityVerification;

  /// Alert type: payments leaving the account.
  String get notifPayments => _l10n?.notifPayments ?? _en.notifPayments;

  /// Alert type: transfers between accounts.
  String get notifTransfers => _l10n?.notifTransfers ?? _en.notifTransfers;

  /// Alert type: card use.
  String get notifCardActivity =>
      _l10n?.notifCardActivity ?? _en.notifCardActivity;

  /// Alert type: progress towards savings goals.
  String get notifSavingsGoals =>
      _l10n?.notifSavingsGoals ?? _en.notifSavingsGoals;

  /// Alert type: investment price movements.
  String get notifPriceAlerts =>
      _l10n?.notifPriceAlerts ?? _en.notifPriceAlerts;

  /// Alert type: planned maintenance and service news.
  String get notifServiceUpdates =>
      _l10n?.notifServiceUpdates ?? _en.notifServiceUpdates;

  /// Alert type: promotions and product news.
  String get notifOffersAndNews =>
      _l10n?.notifOffersAndNews ?? _en.notifOffersAndNews;

  /// Screen-reader prefix for a success toast.
  String get toastSuccess => _l10n?.toastSuccess ?? _en.toastSuccess;

  /// Screen-reader prefix for an error toast.
  String get toastError => _l10n?.toastError ?? _en.toastError;

  /// Screen-reader prefix for an informational toast.
  String get toastInfo => _l10n?.toastInfo ?? _en.toastInfo;

  /// Screen-reader prefix for a warning toast.
  String get toastWarning => _l10n?.toastWarning ?? _en.toastWarning;

  /// Banner title shown when the device loses connectivity.
  String get connectivityOfflineTitle =>
      _l10n?.connectivityOfflineTitle ?? _en.connectivityOfflineTitle;

  /// Banner title shown when the bank is partially unavailable.
  String get connectivityDegradedTitle =>
      _l10n?.connectivityDegradedTitle ?? _en.connectivityDegradedTitle;

  /// Banner shown briefly once connectivity returns.
  String get connectivityRestored =>
      _l10n?.connectivityRestored ?? _en.connectivityRestored;

  /// Blocking-gate title: planned maintenance.
  String get gateMaintenanceTitle =>
      _l10n?.gateMaintenanceTitle ?? _en.gateMaintenanceTitle;

  /// Blocking-gate body: planned maintenance.
  String get gateMaintenanceBody =>
      _l10n?.gateMaintenanceBody ?? _en.gateMaintenanceBody;

  /// Blocking-gate title: the device is offline.
  String get gateOfflineTitle =>
      _l10n?.gateOfflineTitle ?? _en.gateOfflineTitle;

  /// Blocking-gate body: the device is offline.
  String get gateOfflineBody => _l10n?.gateOfflineBody ?? _en.gateOfflineBody;

  /// Blocking-gate title: the app version is no longer supported.
  String get gateForceUpdateTitle =>
      _l10n?.gateForceUpdateTitle ?? _en.gateForceUpdateTitle;

  /// Blocking-gate body: the app version is no longer supported.
  String get gateForceUpdateBody =>
      _l10n?.gateForceUpdateBody ?? _en.gateForceUpdateBody;

  /// Blocking-gate title for security blocks. Deliberately vague so an attacker
  /// learns nothing.
  String get gateDeviceBlockedTitle =>
      _l10n?.gateDeviceBlockedTitle ?? _en.gateDeviceBlockedTitle;

  /// Blocking-gate body for security blocks. Deliberately vague.
  String get gateDeviceBlockedBody =>
      _l10n?.gateDeviceBlockedBody ?? _en.gateDeviceBlockedBody;

  /// Blocking-gate title when sign-in is refused. Deliberately vague.
  String get gateSignInBlockedTitle =>
      _l10n?.gateSignInBlockedTitle ?? _en.gateSignInBlockedTitle;

  /// Blocking-gate body when sign-in is refused. Deliberately vague.
  String get gateSignInBlockedBody =>
      _l10n?.gateSignInBlockedBody ?? _en.gateSignInBlockedBody;

  /// Blocking-gate title: the device clock is wrong.
  String get gateClockSkewTitle =>
      _l10n?.gateClockSkewTitle ?? _en.gateClockSkewTitle;

  /// Blocking-gate body: the device clock is wrong.
  String get gateClockSkewBody =>
      _l10n?.gateClockSkewBody ?? _en.gateClockSkewBody;

  /// Blocking-gate title: developer mode is enabled.
  String get gateDeveloperModeTitle =>
      _l10n?.gateDeveloperModeTitle ?? _en.gateDeveloperModeTitle;

  /// Blocking-gate body: developer mode is enabled.
  String get gateDeveloperModeBody =>
      _l10n?.gateDeveloperModeBody ?? _en.gateDeveloperModeBody;

  /// Blocking-gate title: the customer is waiting in a sign-in queue.
  String get gateQueueTitle => _l10n?.gateQueueTitle ?? _en.gateQueueTitle;

  /// Blocking-gate body: the customer is waiting in a sign-in queue.
  String get gateQueueBody => _l10n?.gateQueueBody ?? _en.gateQueueBody;

  /// Clock-fix step 1.
  String get gateClockStep1 => _l10n?.gateClockStep1 ?? _en.gateClockStep1;

  /// Clock-fix step 2.
  String get gateClockStep2 => _l10n?.gateClockStep2 ?? _en.gateClockStep2;

  /// Clock-fix step 3.
  String get gateClockStep3 => _l10n?.gateClockStep3 ?? _en.gateClockStep3;

  /// Clock-fix step 4.
  String get gateClockStep4 => _l10n?.gateClockStep4 ?? _en.gateClockStep4;

  /// Developer-mode-fix step 1.
  String get gateDeveloperStep1 =>
      _l10n?.gateDeveloperStep1 ?? _en.gateDeveloperStep1;

  /// Developer-mode-fix step 2.
  String get gateDeveloperStep2 =>
      _l10n?.gateDeveloperStep2 ?? _en.gateDeveloperStep2;

  /// Developer-mode-fix step 3.
  String get gateDeveloperStep3 =>
      _l10n?.gateDeveloperStep3 ?? _en.gateDeveloperStep3;

  /// Developer-mode-fix step 4.
  String get gateDeveloperStep4 =>
      _l10n?.gateDeveloperStep4 ?? _en.gateDeveloperStep4;

  /// Status shown while the gate retries in the background.
  String get gateStillWorking =>
      _l10n?.gateStillWorking ?? _en.gateStillWorking;

  /// Hint under the support reference code on a blocking gate.
  String get gateReferenceHint =>
      _l10n?.gateReferenceHint ?? _en.gateReferenceHint;

  /// Label before an estimated time that service returns.
  String get gateBackByAround =>
      _l10n?.gateBackByAround ?? _en.gateBackByAround;

  /// Shown when the estimated return time has passed.
  String get gateTakingLonger =>
      _l10n?.gateTakingLonger ?? _en.gateTakingLonger;

  /// Reassurance shown to a customer waiting in the sign-in queue.
  String get gateQueueReassurance =>
      _l10n?.gateQueueReassurance ?? _en.gateQueueReassurance;

  /// Secondary action on the force-update gate.
  String get gateUpdateHelp => _l10n?.gateUpdateHelp ?? _en.gateUpdateHelp;

  /// Reassurance line shown on security-related blocking gates.
  String get gateMoneyIsSafe => _l10n?.gateMoneyIsSafe ?? _en.gateMoneyIsSafe;

  /// Channel that still works while the app is blocked.
  String get gateAlternativeCardPayments =>
      _l10n?.gateAlternativeCardPayments ?? _en.gateAlternativeCardPayments;

  /// Channel that still works while the app is blocked.
  String get gateAlternativeAtm =>
      _l10n?.gateAlternativeAtm ?? _en.gateAlternativeAtm;

  /// Channel that still works while the app is blocked.
  String get gateAlternativePhone =>
      _l10n?.gateAlternativePhone ?? _en.gateAlternativePhone;

  /// Estimated wait shorter than one minute.
  String get gateEtaLessThanMinute =>
      _l10n?.gateEtaLessThanMinute ?? _en.gateEtaLessThanMinute;

  /// Estimated wait in whole minutes.
  String gateEtaMinutes(int count) =>
      _l10n?.gateEtaMinutes(count) ?? _en.gateEtaMinutes(count);

  /// Title of the optional-update sheet.
  String get updateTitle => _l10n?.updateTitle ?? _en.updateTitle;

  /// Body of the optional-update sheet.
  String get updateBody => _l10n?.updateBody ?? _en.updateBody;

  /// Primary action on the update sheet.
  String get updateNow => _l10n?.updateNow ?? _en.updateNow;

  /// Dismissal action on the update sheet.
  String get updateNotNow => _l10n?.updateNotNow ?? _en.updateNotNow;

  /// Warning naming the date the current version stops working.
  String updateSunset(String date) =>
      _l10n?.updateSunset(date) ?? _en.updateSunset(date);

  /// The version being offered.
  String updateVersion(String version) =>
      _l10n?.updateVersion(version) ?? _en.updateVersion(version);

  /// Trailing clause naming the version installed today.
  String updateCurrentVersion(String version) =>
      _l10n?.updateCurrentVersion(version) ?? _en.updateCurrentVersion(version);

  /// Action that sends a fresh one-time passcode.
  String get authResendCode => _l10n?.authResendCode ?? _en.authResendCode;

  /// PIN-keypad action that switches to fingerprint or face unlock.
  String get authUseBiometrics =>
      _l10n?.authUseBiometrics ?? _en.authUseBiometrics;

  /// PIN-keypad key that removes the last digit.
  String get authDeleteDigit => _l10n?.authDeleteDigit ?? _en.authDeleteDigit;

  /// Privacy toggle: reveal balances.
  String get authShowBalances =>
      _l10n?.authShowBalances ?? _en.authShowBalances;

  /// Privacy toggle: hide balances.
  String get authHideBalances =>
      _l10n?.authHideBalances ?? _en.authHideBalances;

  /// Dialog title warning that the session is about to end.
  String get authSessionExpiringTitle =>
      _l10n?.authSessionExpiringTitle ?? _en.authSessionExpiringTitle;

  /// Dialog body warning that the session is about to end.
  String get authSessionExpiringBody =>
      _l10n?.authSessionExpiringBody ?? _en.authSessionExpiringBody;

  /// Action that extends the session.
  String get authStayLoggedIn =>
      _l10n?.authStayLoggedIn ?? _en.authStayLoggedIn;

  /// Action that ends the session immediately.
  String get authLogOut => _l10n?.authLogOut ?? _en.authLogOut;

  /// Explanation shown before revoking a device session.
  String get authSignOutDeviceBody =>
      _l10n?.authSignOutDeviceBody ?? _en.authSignOutDeviceBody;

  /// Strong-authentication action approving a payment.
  String get scaConfirmPayment =>
      _l10n?.scaConfirmPayment ?? _en.scaConfirmPayment;

  /// Strong-authentication action refusing a payment.
  String get scaRejectPayment =>
      _l10n?.scaRejectPayment ?? _en.scaRejectPayment;

  /// Strong-authentication fallback to a PIN.
  String get scaUsePinInstead =>
      _l10n?.scaUsePinInstead ?? _en.scaUsePinInstead;

  /// Strong-authentication fallback to biometrics.
  String get scaUseBiometricsInstead =>
      _l10n?.scaUseBiometricsInstead ?? _en.scaUseBiometricsInstead;

  /// Instruction to approve in a separate authenticator app.
  String get scaAuthenticatorPrompt =>
      _l10n?.scaAuthenticatorPrompt ?? _en.scaAuthenticatorPrompt;

  /// Label before a countdown until the approval lapses.
  String get scaExpiresIn => _l10n?.scaExpiresIn ?? _en.scaExpiresIn;

  /// Anti-vishing warning shown when no verified call is in progress.
  String callVerifyUnverifiedWarning(String bank) =>
      _l10n?.callVerifyUnverifiedWarning(bank) ??
      _en.callVerifyUnverifiedWarning(bank);

  /// Reassurance shown when a caller has been verified.
  String get callVerifyVerifiedReassurance =>
      _l10n?.callVerifyVerifiedReassurance ?? _en.callVerifyVerifiedReassurance;

  /// Shown when no call is active, above the recent-contact summary.
  String callVerifyIdleSummary(String bank) =>
      _l10n?.callVerifyIdleSummary(bank) ?? _en.callVerifyIdleSummary(bank);

  /// Confirmation body before lifting a panic freeze.
  String get panicUnfreezeConfirmBody =>
      _l10n?.panicUnfreezeConfirmBody ?? _en.panicUnfreezeConfirmBody;

  /// Screen-reader hint on the press-and-hold freeze control.
  String panicHoldHint(String seconds) =>
      _l10n?.panicHoldHint(seconds) ?? _en.panicHoldHint(seconds);

  /// Screen-reader name for the reverse face of a payment card.
  String get cardBack => _l10n?.cardBack ?? _en.cardBack;

  /// Screen-reader name for the front face of a payment card.
  String get cardFront => _l10n?.cardFront ?? _en.cardFront;

  /// Action revealing the full card number and CVV.
  String get cardShowDetails => _l10n?.cardShowDetails ?? _en.cardShowDetails;

  /// Action turning a card over.
  String get cardFlip => _l10n?.cardFlip ?? _en.cardFlip;

  /// Screen-reader fallback when the card network is unknown. Network names
  /// themselves (Visa, Mastercard) are trademarks and stay untranslated.
  String get cardGenericNetwork =>
      _l10n?.cardGenericNetwork ?? _en.cardGenericNetwork;

  /// Label for the field holding either an IBAN or a local account number.
  String get cardIbanOrAccount =>
      _l10n?.cardIbanOrAccount ?? _en.cardIbanOrAccount;

  /// Label for the field holding either a sort code or a BIC.
  String get cardSortCodeOrBic =>
      _l10n?.cardSortCodeOrBic ?? _en.cardSortCodeOrBic;

  /// Hint explaining that account details can be copied by tapping.
  String get cardTapToCopyHint =>
      _l10n?.cardTapToCopyHint ?? _en.cardTapToCopyHint;

  /// Cool-off notice before a merchant block is lifted.
  String cardBlockDelayNotice(String label, String hours) =>
      _l10n?.cardBlockDelayNotice(label, hours) ??
      _en.cardBlockDelayNotice(label, hours);

  /// Field error for a malformed IBAN.
  String get validationIban => _l10n?.validationIban ?? _en.validationIban;

  /// Field error for a malformed card number.
  String get validationCardNumber =>
      _l10n?.validationCardNumber ?? _en.validationCardNumber;

  /// Field error for a malformed sort code.
  String get validationSortCode =>
      _l10n?.validationSortCode ?? _en.validationSortCode;

  /// Field error for a value that fails an unnamed mask.
  String get validationGeneric =>
      _l10n?.validationGeneric ?? _en.validationGeneric;

  /// Steps the period selector back by one month.
  String get periodPreviousMonth =>
      _l10n?.periodPreviousMonth ?? _en.periodPreviousMonth;

  /// Steps the period selector back by one quarter.
  String get periodPreviousQuarter =>
      _l10n?.periodPreviousQuarter ?? _en.periodPreviousQuarter;

  /// Steps the period selector back by one year.
  String get periodPreviousYear =>
      _l10n?.periodPreviousYear ?? _en.periodPreviousYear;

  /// Steps the period selector forward by one month.
  String get periodNextMonth => _l10n?.periodNextMonth ?? _en.periodNextMonth;

  /// Steps the period selector forward by one quarter.
  String get periodNextQuarter =>
      _l10n?.periodNextQuarter ?? _en.periodNextQuarter;

  /// Steps the period selector forward by one year.
  String get periodNextYear => _l10n?.periodNextYear ?? _en.periodNextYear;

  /// Chart range covering the whole available history.
  String get periodAll => _l10n?.periodAll ?? _en.periodAll;

  /// Screen-reader name for the grab bar at the top of a bottom sheet.
  String get sheetDragHandle => _l10n?.sheetDragHandle ?? _en.sheetDragHandle;

  /// Label for a card's total spending limit.
  String get creditLimit => _l10n?.creditLimit ?? _en.creditLimit;

  /// Credit-score band, lowest.
  String get creditScorePoor => _l10n?.creditScorePoor ?? _en.creditScorePoor;

  /// Credit-score band, below average.
  String get creditScoreFair => _l10n?.creditScoreFair ?? _en.creditScoreFair;

  /// Credit-score band, average.
  String get creditScoreGood => _l10n?.creditScoreGood ?? _en.creditScoreGood;

  /// Credit-score band, above average.
  String get creditScoreVeryGood =>
      _l10n?.creditScoreVeryGood ?? _en.creditScoreVeryGood;

  /// Credit-score band, highest.
  String get creditScoreExcellent =>
      _l10n?.creditScoreExcellent ?? _en.creditScoreExcellent;

  /// Badge marking a transaction that can be split into instalments.
  String get creditFlexEligible =>
      _l10n?.creditFlexEligible ?? _en.creditFlexEligible;

  /// How sure the bank is about a generated insight.
  String get insightConfidenceHigh =>
      _l10n?.insightConfidenceHigh ?? _en.insightConfidenceHigh;

  /// How sure the bank is about a generated insight.
  String get insightConfidenceMedium =>
      _l10n?.insightConfidenceMedium ?? _en.insightConfidenceMedium;

  /// How sure the bank is about a generated insight.
  String get insightConfidenceLow =>
      _l10n?.insightConfidenceLow ?? _en.insightConfidenceLow;

  /// Explains what blocking a recurring merchant does.
  String get merchantBlockNotice =>
      _l10n?.merchantBlockNotice ?? _en.merchantBlockNotice;

  /// Document-capture guidance: align the document.
  String get captureFrameDocument =>
      _l10n?.captureFrameDocument ?? _en.captureFrameDocument;

  /// Document-capture guidance: the document drifted out of view.
  String get captureKeepInFrame =>
      _l10n?.captureKeepInFrame ?? _en.captureKeepInFrame;

  /// Document-capture guidance: stop moving while the shot is taken.
  String get captureHoldStill =>
      _l10n?.captureHoldStill ?? _en.captureHoldStill;

  /// Document-capture guidance: the document fills too much of the frame.
  String get captureMoveFurther =>
      _l10n?.captureMoveFurther ?? _en.captureMoveFurther;

  /// Document-capture guidance: the document is too small in the frame.
  String get captureMoveCloser =>
      _l10n?.captureMoveCloser ?? _en.captureMoveCloser;

  /// Document-capture guidance: the scene is too dark.
  String get captureImproveLighting =>
      _l10n?.captureImproveLighting ?? _en.captureImproveLighting;

  /// Document-capture guidance: the camera is shaking.
  String get captureHoldSteady =>
      _l10n?.captureHoldSteady ?? _en.captureHoldSteady;

  /// Shutter action on the document-capture overlay.
  String get captureTakePhoto =>
      _l10n?.captureTakePhoto ?? _en.captureTakePhoto;

  /// Liveness-check guidance: align the face.
  String get livenessPositionFace =>
      _l10n?.livenessPositionFace ?? _en.livenessPositionFace;

  /// Liveness-check guidance: face the lens.
  String get livenessLookStraight =>
      _l10n?.livenessLookStraight ?? _en.livenessLookStraight;

  /// Liveness check succeeded.
  String get livenessVerified =>
      _l10n?.livenessVerified ?? _en.livenessVerified;

  /// Liveness check failed.
  String get livenessFailed => _l10n?.livenessFailed ?? _en.livenessFailed;

  /// Empty state for the open-banking consent list.
  String get consentEmptyBody =>
      _l10n?.consentEmptyBody ?? _en.consentEmptyBody;

  /// Explains skipping one instance of a standing order.
  String get standingOrderSkipBody =>
      _l10n?.standingOrderSkipBody ?? _en.standingOrderSkipBody;

  /// Explains cancelling a standing order outright.
  String get standingOrderCancelBody =>
      _l10n?.standingOrderCancelBody ?? _en.standingOrderCancelBody;

  /// Action prompting the customer to read a disclosure first.
  String get disclosureReviewAndAgree =>
      _l10n?.disclosureReviewAndAgree ?? _en.disclosureReviewAndAgree;

  /// Action accepting a disclosure once read.
  String get disclosureAgreeAndContinue =>
      _l10n?.disclosureAgreeAndContinue ?? _en.disclosureAgreeAndContinue;

  /// Urgency label for an offer expiring today.
  String get offerEndsToday => _l10n?.offerEndsToday ?? _en.offerEndsToday;

  /// Urgency label counting down to an offer's expiry.
  String offerDaysLeft(int count) =>
      _l10n?.offerDaysLeft(count) ?? _en.offerDaysLeft(count);

  /// Label for an offer past its end date.
  String get offerExpired => _l10n?.offerExpired ?? _en.offerExpired;

  /// Caps the amount that can usefully be added to a pot.
  String potMaxContribution(String amount) =>
      _l10n?.potMaxContribution(amount) ?? _en.potMaxContribution(amount);

  /// Explains round-up saving. {unit} is one whole unit of the pot's currency,
  /// e.g. £1 or ﷼1.
  String roundUpExplainer(String unit) =>
      _l10n?.roundUpExplainer(unit) ?? _en.roundUpExplainer(unit);

  /// Explains round-up saving with a multiplier, e.g. 'the difference ×2'.
  String roundUpExplainerMultiplied(String unit, String multiplier) =>
      _l10n?.roundUpExplainerMultiplied(unit, multiplier) ??
      _en.roundUpExplainerMultiplied(unit, multiplier);

  /// Account ownership: held by this customer alone.
  String get ownershipPrimary =>
      _l10n?.ownershipPrimary ?? _en.ownershipPrimary;

  /// Account ownership: shared with someone else.
  String get ownershipJoint => _l10n?.ownershipJoint ?? _en.ownershipJoint;

  /// Account ownership: this customer is a named beneficiary.
  String get ownershipBeneficiary =>
      _l10n?.ownershipBeneficiary ?? _en.ownershipBeneficiary;

  /// Paywall headline naming the locked feature.
  String paywallUpgradeTo(String feature) =>
      _l10n?.paywallUpgradeTo(feature) ?? _en.paywallUpgradeTo(feature);

  /// Paywall dismissal action.
  String get paywallMaybeLater =>
      _l10n?.paywallMaybeLater ?? _en.paywallMaybeLater;

  /// Paywall primary action.
  String get paywallUpgrade => _l10n?.paywallUpgrade ?? _en.paywallUpgrade;

  /// Marks the plan the customer already has.
  String get paywallCurrentPlan =>
      _l10n?.paywallCurrentPlan ?? _en.paywallCurrentPlan;

  /// Screen-reader name for the paywall close control.
  String get paywallDismiss => _l10n?.paywallDismiss ?? _en.paywallDismiss;

  /// Confirmation that a membership perk is now active.
  String get perkActivated => _l10n?.perkActivated ?? _en.perkActivated;

  /// Screen-reader state for an active perk.
  String get perkActivatedSpoken =>
      _l10n?.perkActivatedSpoken ?? _en.perkActivatedSpoken;

  /// Screen-reader state for an inactive perk.
  String get perkNotActivatedSpoken =>
      _l10n?.perkNotActivatedSpoken ?? _en.perkNotActivatedSpoken;

  /// Action that shares a referral code.
  String get referralShareCode =>
      _l10n?.referralShareCode ?? _en.referralShareCode;

  /// Dispute reason: the customer did not make the transaction.
  String get disputeUnauthorized =>
      _l10n?.disputeUnauthorized ?? _en.disputeUnauthorized;

  /// Dispute reason: duplicate charge.
  String get disputeDuplicate =>
      _l10n?.disputeDuplicate ?? _en.disputeDuplicate;

  /// Dispute reason: incorrect amount.
  String get disputeWrongAmount =>
      _l10n?.disputeWrongAmount ?? _en.disputeWrongAmount;

  /// Dispute reason: paid but nothing arrived.
  String get disputeNotReceived =>
      _l10n?.disputeNotReceived ?? _en.disputeNotReceived;

  /// Dispute reason: charged after cancelling.
  String get disputeCancelledSubscription =>
      _l10n?.disputeCancelledSubscription ?? _en.disputeCancelledSubscription;

  /// Dispute reason: none of the listed options.
  String get disputeOther => _l10n?.disputeOther ?? _en.disputeOther;

  /// Dispute progress: filed with the bank.
  String get disputeStageSubmitted =>
      _l10n?.disputeStageSubmitted ?? _en.disputeStageSubmitted;

  /// Dispute progress: being investigated.
  String get disputeStageUnderReview =>
      _l10n?.disputeStageUnderReview ?? _en.disputeStageUnderReview;

  /// Dispute progress: closed.
  String get disputeStageResolved =>
      _l10n?.disputeStageResolved ?? _en.disputeStageResolved;

  /// Screen-reader summary of an account row.
  String a11yAccountSummary(String name, String number, String balance) =>
      _l10n?.a11yAccountSummary(name, number, balance) ??
      _en.a11yAccountSummary(name, number, balance);

  /// Marks the currently chosen item for a screen reader.
  String a11ySelectedSuffix(String label) =>
      _l10n?.a11ySelectedSuffix(label) ?? _en.a11ySelectedSuffix(label);

  /// Screen-reader phrasing of an account balance.
  String a11yBalanceIs(String amount) =>
      _l10n?.a11yBalanceIs(amount) ?? _en.a11yBalanceIs(amount);

  /// Screen-reader summary of a budget gauge.
  String a11yBudgetSummary(String name, String spent, String limit) =>
      _l10n?.a11yBudgetSummary(name, spent, limit) ??
      _en.a11yBudgetSummary(name, spent, limit);

  /// Appended when a budget has been exceeded.
  String a11yBudgetOverspent(String summary) =>
      _l10n?.a11yBudgetOverspent(summary) ?? _en.a11yBudgetOverspent(summary);

  /// Screen-reader summary of a cashflow chart's history.
  String a11yBalanceRange(String low, String high) =>
      _l10n?.a11yBalanceRange(low, high) ?? _en.a11yBalanceRange(low, high);

  /// Appended when a cashflow chart also shows a forecast.
  String a11yBalanceRangeProjected(String summary, String projection) =>
      _l10n?.a11yBalanceRangeProjected(summary, projection) ??
      _en.a11yBalanceRangeProjected(summary, projection);

  /// Screen-reader summary of a forecast bill row.
  String a11yBillForecast(String biller, String amount) =>
      _l10n?.a11yBillForecast(biller, amount) ??
      _en.a11yBillForecast(biller, amount);

  /// Appended when a forecast bill amount is only an estimate.
  String a11yBillForecastEstimated(String summary) =>
      _l10n?.a11yBillForecastEstimated(summary) ??
      _en.a11yBillForecastEstimated(summary);

  /// The customer's place in the sign-in queue.
  String gateQueuePosition(String position) =>
      _l10n?.gateQueuePosition(position) ?? _en.gateQueuePosition(position);

  /// Queue position followed by the estimated wait.
  String gateQueuePositionWithEta(String position, String wait) =>
      _l10n?.gateQueuePositionWithEta(position, wait) ??
      _en.gateQueuePositionWithEta(position, wait);

  /// Button that repeats a failed operation. Distinct from Retry, which is the
  /// terser form used in dense rows.
  String get actionTryAgain => _l10n?.actionTryAgain ?? _en.actionTryAgain;

  /// Countdown until the app retries a failed connection.
  String connectivityRetryingIn(String seconds) =>
      _l10n?.connectivityRetryingIn(seconds) ??
      _en.connectivityRetryingIn(seconds);

  /// Delivery channel: a text message.
  String get notifChannelSms => _l10n?.notifChannelSms ?? _en.notifChannelSms;

  /// Screen-reader summary of a credit-limit gauge.
  String a11yCreditLimit(
    String label,
    String used,
    String limit,
    String available,
  ) =>
      _l10n?.a11yCreditLimit(label, used, limit, available) ??
      _en.a11yCreditLimit(label, used, limit, available);

  /// Caption under an available amount, in running text rather than as a
  /// heading, so lower case in English.
  String get labelAvailableLower =>
      _l10n?.labelAvailableLower ?? _en.labelAvailableLower;

  /// How many people have accepted a referral.
  String referralFriendsInvited(int count) =>
      _l10n?.referralFriendsInvited(count) ?? _en.referralFriendsInvited(count);

  /// Referral progress against the reward cap.
  String referralProgress(String invited, String max) =>
      _l10n?.referralProgress(invited, max) ??
      _en.referralProgress(invited, max);

  /// Headline confirming the caller is genuine.
  String callVerifyActiveHeadline(String bank) =>
      _l10n?.callVerifyActiveHeadline(bank) ??
      _en.callVerifyActiveHeadline(bank);

  /// Label for the ceiling of a limit gauge.
  String get labelLimit => _l10n?.labelLimit ?? _en.labelLimit;

  /// Button that dismisses a confirmation without acting.
  String get actionGoBack => _l10n?.actionGoBack ?? _en.actionGoBack;

  /// Screen-reader name for an overflow menu.
  String get actionMoreActions =>
      _l10n?.actionMoreActions ?? _en.actionMoreActions;

  /// Confirmation title for skipping one instance of a standing order.
  String get standingOrderSkipTitle =>
      _l10n?.standingOrderSkipTitle ?? _en.standingOrderSkipTitle;

  /// Confirmation title for cancelling a standing order outright.
  String get standingOrderCancelTitle =>
      _l10n?.standingOrderCancelTitle ?? _en.standingOrderCancelTitle;

  /// Menu item that skips the next instance.
  String get standingOrderSkipAction =>
      _l10n?.standingOrderSkipAction ?? _en.standingOrderSkipAction;

  /// Menu item that stops all future payments.
  String get standingOrderCancelAction =>
      _l10n?.standingOrderCancelAction ?? _en.standingOrderCancelAction;

  /// Menu item that suspends a standing order.
  String get standingOrderPause =>
      _l10n?.standingOrderPause ?? _en.standingOrderPause;

  /// Menu item that restarts a paused standing order.
  String get standingOrderResume =>
      _l10n?.standingOrderResume ?? _en.standingOrderResume;

  /// Standing-order state: suspended.
  String get standingOrderPaused =>
      _l10n?.standingOrderPaused ?? _en.standingOrderPaused;

  /// Standing-order state: the last attempt did not go through.
  String get standingOrderFailed =>
      _l10n?.standingOrderFailed ?? _en.standingOrderFailed;

  /// Action that re-attempts a failed standing-order payment.
  String get standingOrderRetry =>
      _l10n?.standingOrderRetry ?? _en.standingOrderRetry;

  /// Prefix before the date of a recurring merchant’s next charge, as in “next
  /// 1 Jul”.
  String get merchantNextPrefix =>
      _l10n?.merchantNextPrefix ?? _en.merchantNextPrefix;

  /// Badge marking a subscription that costs more than it used to.
  String get merchantPriceRise =>
      _l10n?.merchantPriceRise ?? _en.merchantPriceRise;

  /// Action that explains how to end a subscription.
  String get merchantHowToCancel =>
      _l10n?.merchantHowToCancel ?? _en.merchantHowToCancel;

  /// Action that refuses further charges from a merchant.
  String get merchantBlockAction =>
      _l10n?.merchantBlockAction ?? _en.merchantBlockAction;

  /// Confirmation title before blocking a merchant.
  String get merchantBlockTitle =>
      _l10n?.merchantBlockTitle ?? _en.merchantBlockTitle;

  /// Action that withdraws an app’s access to account data.
  String get consentRevoke => _l10n?.consentRevoke ?? _en.consentRevoke;

  /// Confirmation title before revoking an app’s access.
  String get consentRevokeTitle =>
      _l10n?.consentRevokeTitle ?? _en.consentRevokeTitle;

  /// Confirmation body before revoking an app’s access.
  String get consentRevokeBody =>
      _l10n?.consentRevokeBody ?? _en.consentRevokeBody;

  /// Prefix before the date access was granted.
  String get consentGrantedPrefix =>
      _l10n?.consentGrantedPrefix ?? _en.consentGrantedPrefix;

  /// Prefix before the date access lapses, in running text.
  String get consentExpiresPrefix =>
      _l10n?.consentExpiresPrefix ?? _en.consentExpiresPrefix;

  /// Consent state: withdrawn by the customer.
  String get consentRevoked => _l10n?.consentRevoked ?? _en.consentRevoked;

  /// Consent state: lapsed.
  String get consentExpired => _l10n?.consentExpired ?? _en.consentExpired;

  /// Consent state: close to lapsing.
  String get consentExpiringSoon =>
      _l10n?.consentExpiringSoon ?? _en.consentExpiringSoon;
  // --- END GENERATED ACCESSORS ---
}
