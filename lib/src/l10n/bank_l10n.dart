import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'bank_l10n_ar.dart';
import 'bank_l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of BankL10n
/// returned by `BankL10n.of(context)`.
///
/// Applications need to include `BankL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/bank_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: BankL10n.localizationsDelegates,
///   supportedLocales: BankL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the BankL10n.supportedLocales
/// property.
abstract class BankL10n {
  BankL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static BankL10n? of(BuildContext context) {
    return Localizations.of<BankL10n>(context, BankL10n);
  }

  static const LocalizationsDelegate<BankL10n> delegate = _BankL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar')
  ];

  /// Relative day label for something dated today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Relative day label for something dated yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Relative timestamp for an event less than a minute old. Lower case: it sits inline after a merchant name, not at the head of a sentence.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// Relative timestamp in whole minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// Relative timestamp in whole hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// Relative timestamp in whole days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// Abbreviated relative timestamp in minutes, for dense rows.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgoShort(String count);

  /// Abbreviated relative timestamp in hours, for dense rows.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgoShort(String count);

  /// Abbreviated relative timestamp in days, for dense rows.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgoShort(String count);

  /// Transaction status: authorised but not yet settled.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Transaction status: settled.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get statusCleared;

  /// Transaction status: refused by the issuer.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// Transaction status: money returned to the customer.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// Transaction status: queued for a future date.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// Card or account status: temporarily blocked by the customer.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get statusFrozen;

  /// Card or account status: limited by the bank.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get statusRestricted;

  /// Card or account status: usable as normal.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Button that closes a finished flow.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Button that abandons the current action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Button that commits the current action.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Button that advances to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Button that returns to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Button that passes over an optional step.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// Button that agrees to a request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// Button that refuses a request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// Button that opens the platform share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Button that starts a transaction dispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get actionDispute;

  /// Button that reports a transaction as suspicious.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get actionReport;

  /// Button that repeats a failed operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Button or icon that dismisses an overlay.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Button that copies a value to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Confirmation shown after a value is copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// Button that opens a fuller view of the current item.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get actionViewDetails;

  /// Button that opens a support channel.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get actionContactSupport;

  /// Option that lets the customer enter their own value.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get actionCustom;

  /// Primary action: start an outbound payment.
  ///
  /// In en, this message translates to:
  /// **'Send money'**
  String get sendMoney;

  /// Primary action: ask someone to pay you.
  ///
  /// In en, this message translates to:
  /// **'Request money'**
  String get requestMoney;

  /// Primary action: top up an account or pot.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoney;

  /// Primary action: take money out.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// Placeholder glyphs shown in place of a balance in privacy mode. Usually left as dots in every locale.
  ///
  /// In en, this message translates to:
  /// **'••••'**
  String get balanceHidden;

  /// Screen-reader text replacing a balance in privacy mode.
  ///
  /// In en, this message translates to:
  /// **'Balance hidden'**
  String get balanceHiddenSpoken;

  /// Screen-reader text replacing a loyalty-points balance in privacy mode.
  ///
  /// In en, this message translates to:
  /// **'Points balance hidden'**
  String get pointsBalanceHiddenSpoken;

  /// Label for the spendable portion of a limit or balance.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get labelAvailable;

  /// Label for the consumed portion of a limit.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get labelUsed;

  /// Label for a savings target.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get labelGoal;

  /// Label for how far along a goal is.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get labelProgress;

  /// Label for a monetary value field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAmount;

  /// Label for an account's currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get labelCurrency;

  /// Label for an app version number.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// Label for the time data was last refreshed.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get labelLastUpdated;

  /// Conventional-finance rate label.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get interestRate;

  /// Islamic-finance equivalent of an interest rate.
  ///
  /// In en, this message translates to:
  /// **'Profit rate'**
  String get profitRate;

  /// Abbreviation for annual percentage rate.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get annualPercentageRate;

  /// Badge for a plan that charges no interest.
  ///
  /// In en, this message translates to:
  /// **'Interest free'**
  String get interestFree;

  /// Suffix appended to a monthly amount, e.g. 25.00/month.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// Short suffix appended to a monthly price in tight layouts.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonthShort;

  /// Length of an instalment plan in whole months.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 month} other{{count} months}}'**
  String installmentMonths(int count);

  /// Action that moves money into a savings pot.
  ///
  /// In en, this message translates to:
  /// **'Add to pot'**
  String get addToPot;

  /// Action that moves money out of a savings pot.
  ///
  /// In en, this message translates to:
  /// **'Withdraw from pot'**
  String get withdrawFromPot;

  /// Action that divides a bill into equal shares.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get splitEqually;

  /// Prompt asking the customer to authenticate with their PIN.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to confirm'**
  String get confirmPin;

  /// Title shown when a session has already ended.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionTimeout;

  /// Body shown when a session has already ended.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired for security. Please log in again.'**
  String get sessionTimeoutBody;

  /// Empty state for a transaction list.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// Loading state for a transaction list.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions…'**
  String get loadingTransactions;

  /// Confirmation that a transfer succeeded.
  ///
  /// In en, this message translates to:
  /// **'Transfer sent'**
  String get transferSuccess;

  /// Notice that a transfer did not go through.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed'**
  String get transferFailure;

  /// Title of the new-device security notice.
  ///
  /// In en, this message translates to:
  /// **'New device detected'**
  String get newDevice;

  /// Body of the new-device security notice.
  ///
  /// In en, this message translates to:
  /// **'We noticed a login from a new device. If this was you, no action is needed.'**
  String get newDeviceBody;

  /// Title of the compromised-device security notice.
  ///
  /// In en, this message translates to:
  /// **'Security warning'**
  String get compromisedDevice;

  /// Body of the compromised-device security notice.
  ///
  /// In en, this message translates to:
  /// **'This device may be compromised. For your safety, some features have been limited.'**
  String get compromisedDeviceBody;

  /// Title shown while identity documents are being checked.
  ///
  /// In en, this message translates to:
  /// **'Verification under review'**
  String get verificationUnderReview;

  /// Body shown while identity documents are being checked.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your documents. This usually takes 1–2 business days.'**
  String get verificationUnderReviewBody;

  /// Spending category: supermarkets and food shops.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// Spending category: restaurants, cafés, takeaway.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get categoryDining;

  /// Spending category: fuel, transit, taxis.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// Spending category: cinema, events, games.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// Spending category: electricity, water, internet.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// Spending category: pharmacy, clinics, insurance.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// Spending category: retail and online purchases.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// Spending category: flights, hotels, holidays.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// Spending category: tuition, courses, books.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// Spending category: recurring services.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get categorySubscription;

  /// Spending category: money moved between accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get categoryTransfer;

  /// Spending category: salary and other money in.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryIncome;

  /// Spending category: brokerage and fund activity.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get categoryInvestment;

  /// Spending category: credit-card activity, shown where space is tight.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get categoryCredit;

  /// Spending category: a payment made towards a credit card.
  ///
  /// In en, this message translates to:
  /// **'Credit Payment'**
  String get categoryCreditPayment;

  /// Spending category: anything uncategorised.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Action that adds another category to a split.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoryAdd;

  /// Recurring payment frequency: every day.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// Recurring payment frequency: every week.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// Recurring payment frequency: every two weeks.
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get frequencyBiweekly;

  /// Recurring payment frequency: every month.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// Alert-preferences group covering security and fraud messages.
  ///
  /// In en, this message translates to:
  /// **'Security & fraud'**
  String get notifGroupSecurity;

  /// Alert-preferences group covering payment messages.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notifGroupPayments;

  /// Alert-preferences group covering account activity.
  ///
  /// In en, this message translates to:
  /// **'Account activity'**
  String get notifGroupAccount;

  /// Alert-preferences group covering promotional messages.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get notifGroupMarketing;

  /// Delivery channel: a device push notification.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get notifChannelPush;

  /// Delivery channel: email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get notifChannelEmail;

  /// Alert type: sign-ins and security events.
  ///
  /// In en, this message translates to:
  /// **'Security alerts'**
  String get notifSecurityAlerts;

  /// Alert type: suspected fraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud warnings'**
  String get notifFraudWarnings;

  /// Alert type: identity checks.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get notifIdentityVerification;

  /// Alert type: payments leaving the account.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notifPayments;

  /// Alert type: transfers between accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get notifTransfers;

  /// Alert type: card use.
  ///
  /// In en, this message translates to:
  /// **'Card activity'**
  String get notifCardActivity;

  /// Alert type: progress towards savings goals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get notifSavingsGoals;

  /// Alert type: investment price movements.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get notifPriceAlerts;

  /// Alert type: planned maintenance and service news.
  ///
  /// In en, this message translates to:
  /// **'Service updates'**
  String get notifServiceUpdates;

  /// Alert type: promotions and product news.
  ///
  /// In en, this message translates to:
  /// **'Offers & news'**
  String get notifOffersAndNews;

  /// Screen-reader prefix for a success toast.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get toastSuccess;

  /// Screen-reader prefix for an error toast.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get toastError;

  /// Screen-reader prefix for an informational toast.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get toastInfo;

  /// Screen-reader prefix for a warning toast.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get toastWarning;

  /// Banner title shown when the device loses connectivity.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get connectivityOfflineTitle;

  /// Banner title shown when the bank is partially unavailable.
  ///
  /// In en, this message translates to:
  /// **'Some services are affected'**
  String get connectivityDegradedTitle;

  /// Banner shown briefly once connectivity returns.
  ///
  /// In en, this message translates to:
  /// **'Back online. Your accounts are up to date.'**
  String get connectivityRestored;

  /// Blocking-gate title: planned maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance in progress'**
  String get gateMaintenanceTitle;

  /// Blocking-gate body: planned maintenance.
  ///
  /// In en, this message translates to:
  /// **'We are making some important updates. We will be back as soon as we can.'**
  String get gateMaintenanceBody;

  /// Blocking-gate title: the device is offline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get gateOfflineTitle;

  /// Blocking-gate body: the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Your device seems to be offline. Check your Wi-Fi or mobile data, then try again.'**
  String get gateOfflineBody;

  /// Blocking-gate title: the app version is no longer supported.
  ///
  /// In en, this message translates to:
  /// **'Time to update'**
  String get gateForceUpdateTitle;

  /// Blocking-gate body: the app version is no longer supported.
  ///
  /// In en, this message translates to:
  /// **'Update needed to keep your money safe. This version of the app is no longer supported.'**
  String get gateForceUpdateBody;

  /// Blocking-gate title for security blocks. Deliberately vague so an attacker learns nothing.
  ///
  /// In en, this message translates to:
  /// **'We can\'t open the app'**
  String get gateDeviceBlockedTitle;

  /// Blocking-gate body for security blocks. Deliberately vague.
  ///
  /// In en, this message translates to:
  /// **'We can\'t open the app on this device right now.'**
  String get gateDeviceBlockedBody;

  /// Blocking-gate title when sign-in is refused. Deliberately vague.
  ///
  /// In en, this message translates to:
  /// **'We can\'t log you in'**
  String get gateSignInBlockedTitle;

  /// Blocking-gate body when sign-in is refused. Deliberately vague.
  ///
  /// In en, this message translates to:
  /// **'We can\'t log you in right now, please try again later.'**
  String get gateSignInBlockedBody;

  /// Blocking-gate title: the device clock is wrong.
  ///
  /// In en, this message translates to:
  /// **'Check your date and time'**
  String get gateClockSkewTitle;

  /// Blocking-gate body: the device clock is wrong.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s clock looks wrong, so we can\'t connect securely. Setting it back to automatic usually fixes this.'**
  String get gateClockSkewBody;

  /// Blocking-gate title: developer mode is enabled.
  ///
  /// In en, this message translates to:
  /// **'Developer mode is on'**
  String get gateDeveloperModeTitle;

  /// Blocking-gate body: developer mode is enabled.
  ///
  /// In en, this message translates to:
  /// **'For your security the app cannot run while developer mode is switched on. Turning it off fixes this.'**
  String get gateDeveloperModeBody;

  /// Blocking-gate title: the customer is waiting in a sign-in queue.
  ///
  /// In en, this message translates to:
  /// **'You are in the queue'**
  String get gateQueueTitle;

  /// Blocking-gate body: the customer is waiting in a sign-in queue.
  ///
  /// In en, this message translates to:
  /// **'A lot of people are signing in right now, so we are letting everyone in gradually.'**
  String get gateQueueBody;

  /// Clock-fix step 1.
  ///
  /// In en, this message translates to:
  /// **'Open your device Settings'**
  String get gateClockStep1;

  /// Clock-fix step 2.
  ///
  /// In en, this message translates to:
  /// **'Go to Date and Time'**
  String get gateClockStep2;

  /// Clock-fix step 3.
  ///
  /// In en, this message translates to:
  /// **'Turn on Set automatically'**
  String get gateClockStep3;

  /// Clock-fix step 4.
  ///
  /// In en, this message translates to:
  /// **'Come back to the app'**
  String get gateClockStep4;

  /// Developer-mode-fix step 1.
  ///
  /// In en, this message translates to:
  /// **'Open your device Settings'**
  String get gateDeveloperStep1;

  /// Developer-mode-fix step 2.
  ///
  /// In en, this message translates to:
  /// **'Go to Developer options'**
  String get gateDeveloperStep2;

  /// Developer-mode-fix step 3.
  ///
  /// In en, this message translates to:
  /// **'Switch developer mode off'**
  String get gateDeveloperStep3;

  /// Developer-mode-fix step 4.
  ///
  /// In en, this message translates to:
  /// **'Come back to the app'**
  String get gateDeveloperStep4;

  /// Status shown while the gate retries in the background.
  ///
  /// In en, this message translates to:
  /// **'Still working'**
  String get gateStillWorking;

  /// Hint under the support reference code on a blocking gate.
  ///
  /// In en, this message translates to:
  /// **'Quote this code if you contact us'**
  String get gateReferenceHint;

  /// Label before an estimated time that service returns.
  ///
  /// In en, this message translates to:
  /// **'Back by around'**
  String get gateBackByAround;

  /// Shown when the estimated return time has passed.
  ///
  /// In en, this message translates to:
  /// **'Taking a little longer than expected'**
  String get gateTakingLonger;

  /// Reassurance shown to a customer waiting in the sign-in queue.
  ///
  /// In en, this message translates to:
  /// **'We\'ll bring you in automatically. Your place is saved.'**
  String get gateQueueReassurance;

  /// Secondary action on the force-update gate.
  ///
  /// In en, this message translates to:
  /// **'Get help with updating'**
  String get gateUpdateHelp;

  /// Reassurance line shown on security-related blocking gates.
  ///
  /// In en, this message translates to:
  /// **'Your money is safe.'**
  String get gateMoneyIsSafe;

  /// Channel that still works while the app is blocked.
  ///
  /// In en, this message translates to:
  /// **'Card payments'**
  String get gateAlternativeCardPayments;

  /// Channel that still works while the app is blocked.
  ///
  /// In en, this message translates to:
  /// **'ATM withdrawals'**
  String get gateAlternativeAtm;

  /// Channel that still works while the app is blocked.
  ///
  /// In en, this message translates to:
  /// **'Phone banking'**
  String get gateAlternativePhone;

  /// Estimated wait shorter than one minute.
  ///
  /// In en, this message translates to:
  /// **'less than a minute'**
  String get gateEtaLessThanMinute;

  /// Estimated wait in whole minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute} other{{count} minutes}}'**
  String gateEtaMinutes(int count);

  /// Title of the optional-update sheet.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready'**
  String get updateTitle;

  /// Body of the optional-update sheet.
  ///
  /// In en, this message translates to:
  /// **'This update includes fixes and improvements to keep the app fast and secure.'**
  String get updateBody;

  /// Primary action on the update sheet.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Dismissal action on the update sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get updateNotNow;

  /// Warning naming the date the current version stops working.
  ///
  /// In en, this message translates to:
  /// **'This version stops working on {date}'**
  String updateSunset(String date);

  /// The version being offered.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String updateVersion(String version);

  /// Trailing clause naming the version installed today.
  ///
  /// In en, this message translates to:
  /// **'you have {version}'**
  String updateCurrentVersion(String version);

  /// Action that sends a fresh one-time passcode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// PIN-keypad action that switches to fingerprint or face unlock.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get authUseBiometrics;

  /// PIN-keypad key that removes the last digit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get authDeleteDigit;

  /// Privacy toggle: reveal balances.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get authShowBalances;

  /// Privacy toggle: hide balances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get authHideBalances;

  /// Dialog title warning that the session is about to end.
  ///
  /// In en, this message translates to:
  /// **'Session expiring'**
  String get authSessionExpiringTitle;

  /// Dialog body warning that the session is about to end.
  ///
  /// In en, this message translates to:
  /// **'Your session will expire soon. Stay logged in?'**
  String get authSessionExpiringBody;

  /// Action that extends the session.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in'**
  String get authStayLoggedIn;

  /// Action that ends the session immediately.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogOut;

  /// Explanation shown before revoking a device session.
  ///
  /// In en, this message translates to:
  /// **'The device will need to sign in again to access the account.'**
  String get authSignOutDeviceBody;

  /// Strong-authentication action approving a payment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get scaConfirmPayment;

  /// Strong-authentication action refusing a payment.
  ///
  /// In en, this message translates to:
  /// **'Reject payment'**
  String get scaRejectPayment;

  /// Strong-authentication fallback to a PIN.
  ///
  /// In en, this message translates to:
  /// **'Use PIN instead'**
  String get scaUsePinInstead;

  /// Strong-authentication fallback to biometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics instead'**
  String get scaUseBiometricsInstead;

  /// Instruction to approve in a separate authenticator app.
  ///
  /// In en, this message translates to:
  /// **'Approve this payment in your authenticator'**
  String get scaAuthenticatorPrompt;

  /// Label before a countdown until the approval lapses.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get scaExpiresIn;

  /// Anti-vishing warning shown when no verified call is in progress.
  ///
  /// In en, this message translates to:
  /// **'If the person on the phone right now says they are calling from {bank}, hang up: they are a scammer. Genuine staff will never pressure you to move money or share security codes.'**
  String callVerifyUnverifiedWarning(String bank);

  /// Reassurance shown when a caller has been verified.
  ///
  /// In en, this message translates to:
  /// **'This call has been verified. Our team member will never ask for your PIN, your password, or a one time passcode.'**
  String get callVerifyVerifiedReassurance;

  /// Shown when no call is active, above the recent-contact summary.
  ///
  /// In en, this message translates to:
  /// **'No call is in progress right now. Below is a summary of your most recent verified call with {bank}.'**
  String callVerifyIdleSummary(String bank);

  /// Confirmation body before lifting a panic freeze.
  ///
  /// In en, this message translates to:
  /// **'Your cards and outgoing payments will start working again.'**
  String get panicUnfreezeConfirmBody;

  /// Screen-reader hint on the press-and-hold freeze control.
  ///
  /// In en, this message translates to:
  /// **'Press and hold for {seconds} seconds to freeze all cards and outgoing payments'**
  String panicHoldHint(String seconds);

  /// Screen-reader name for the reverse face of a payment card.
  ///
  /// In en, this message translates to:
  /// **'Card back'**
  String get cardBack;

  /// Screen-reader name for the front face of a payment card.
  ///
  /// In en, this message translates to:
  /// **'Card front'**
  String get cardFront;

  /// Action revealing the full card number and CVV.
  ///
  /// In en, this message translates to:
  /// **'Show card details'**
  String get cardShowDetails;

  /// Action turning a card over.
  ///
  /// In en, this message translates to:
  /// **'Flip card'**
  String get cardFlip;

  /// Screen-reader fallback when the card network is unknown. Network names themselves (Visa, Mastercard) are trademarks and stay untranslated.
  ///
  /// In en, this message translates to:
  /// **'Payment card'**
  String get cardGenericNetwork;

  /// Label for the field holding either an IBAN or a local account number.
  ///
  /// In en, this message translates to:
  /// **'IBAN / Account'**
  String get cardIbanOrAccount;

  /// Label for the field holding either a sort code or a BIC.
  ///
  /// In en, this message translates to:
  /// **'Sort Code / BIC'**
  String get cardSortCodeOrBic;

  /// Hint explaining that account details can be copied by tapping.
  ///
  /// In en, this message translates to:
  /// **'Tap values to copy'**
  String get cardTapToCopyHint;

  /// Cool-off notice before a merchant block is lifted.
  ///
  /// In en, this message translates to:
  /// **'For your protection this change is delayed. {label} payments stay blocked for {hours} more hours after you confirm.'**
  String cardBlockDelayNotice(String label, String hours);

  /// Field error for a malformed IBAN.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IBAN.'**
  String get validationIban;

  /// Field error for a malformed card number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid card number.'**
  String get validationCardNumber;

  /// Field error for a malformed sort code.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid sort code.'**
  String get validationSortCode;

  /// Field error for a value that fails an unnamed mask.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get validationGeneric;

  /// Steps the period selector back by one month.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get periodPreviousMonth;

  /// Steps the period selector back by one quarter.
  ///
  /// In en, this message translates to:
  /// **'Previous quarter'**
  String get periodPreviousQuarter;

  /// Steps the period selector back by one year.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get periodPreviousYear;

  /// Steps the period selector forward by one month.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get periodNextMonth;

  /// Steps the period selector forward by one quarter.
  ///
  /// In en, this message translates to:
  /// **'Next quarter'**
  String get periodNextQuarter;

  /// Steps the period selector forward by one year.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get periodNextYear;

  /// Chart range covering the whole available history.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// Screen-reader name for the grab bar at the top of a bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Drag handle'**
  String get sheetDragHandle;

  /// Label for a card's total spending limit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// Credit-score band, lowest.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get creditScorePoor;

  /// Credit-score band, below average.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get creditScoreFair;

  /// Credit-score band, average.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get creditScoreGood;

  /// Credit-score band, above average.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get creditScoreVeryGood;

  /// Credit-score band, highest.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get creditScoreExcellent;

  /// Badge marking a transaction that can be split into instalments.
  ///
  /// In en, this message translates to:
  /// **'Flex eligible'**
  String get creditFlexEligible;

  /// How sure the bank is about a generated insight.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get insightConfidenceHigh;

  /// How sure the bank is about a generated insight.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get insightConfidenceMedium;

  /// How sure the bank is about a generated insight.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get insightConfidenceLow;

  /// Explains what blocking a recurring merchant does.
  ///
  /// In en, this message translates to:
  /// **'Future charges from this merchant will be declined.'**
  String get merchantBlockNotice;

  /// Document-capture guidance: align the document.
  ///
  /// In en, this message translates to:
  /// **'Position your document in the frame'**
  String get captureFrameDocument;

  /// Document-capture guidance: the document drifted out of view.
  ///
  /// In en, this message translates to:
  /// **'Keep the document in frame'**
  String get captureKeepInFrame;

  /// Document-capture guidance: stop moving while the shot is taken.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get captureHoldStill;

  /// Document-capture guidance: the document fills too much of the frame.
  ///
  /// In en, this message translates to:
  /// **'Move further away'**
  String get captureMoveFurther;

  /// Document-capture guidance: the document is too small in the frame.
  ///
  /// In en, this message translates to:
  /// **'Move closer'**
  String get captureMoveCloser;

  /// Document-capture guidance: the scene is too dark.
  ///
  /// In en, this message translates to:
  /// **'Improve lighting conditions'**
  String get captureImproveLighting;

  /// Document-capture guidance: the camera is shaking.
  ///
  /// In en, this message translates to:
  /// **'Hold the camera steady'**
  String get captureHoldSteady;

  /// Shutter action on the document-capture overlay.
  ///
  /// In en, this message translates to:
  /// **'Capture document'**
  String get captureTakePhoto;

  /// Liveness-check guidance: align the face.
  ///
  /// In en, this message translates to:
  /// **'Position your face in the oval'**
  String get livenessPositionFace;

  /// Liveness-check guidance: face the lens.
  ///
  /// In en, this message translates to:
  /// **'Look straight at the camera'**
  String get livenessLookStraight;

  /// Liveness check succeeded.
  ///
  /// In en, this message translates to:
  /// **'Liveness verified'**
  String get livenessVerified;

  /// Liveness check failed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify: please try again'**
  String get livenessFailed;

  /// Empty state for the open-banking consent list.
  ///
  /// In en, this message translates to:
  /// **'Apps you allow to access your account data appear here.'**
  String get consentEmptyBody;

  /// Explains skipping one instance of a standing order.
  ///
  /// In en, this message translates to:
  /// **'The next scheduled payment will be skipped. Later payments stay on schedule.'**
  String get standingOrderSkipBody;

  /// Explains cancelling a standing order outright.
  ///
  /// In en, this message translates to:
  /// **'This permanently stops all future payments to this payee.'**
  String get standingOrderCancelBody;

  /// Action prompting the customer to read a disclosure first.
  ///
  /// In en, this message translates to:
  /// **'Review and agree'**
  String get disclosureReviewAndAgree;

  /// Action accepting a disclosure once read.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get disclosureAgreeAndContinue;

  /// Urgency label for an offer expiring today.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get offerEndsToday;

  /// Urgency label counting down to an offer's expiry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day left} other{{count} days left}}'**
  String offerDaysLeft(int count);

  /// Label for an offer past its end date.
  ///
  /// In en, this message translates to:
  /// **'Offer expired'**
  String get offerExpired;

  /// Caps the amount that can usefully be added to a pot.
  ///
  /// In en, this message translates to:
  /// **'Maximum contribution is {amount} to reach your goal'**
  String potMaxContribution(String amount);

  /// Explains round-up saving. {unit} is one whole unit of the pot's currency, e.g. £1 or ﷼1.
  ///
  /// In en, this message translates to:
  /// **'We\'ll round up every purchase to the nearest {unit} and save the difference automatically.'**
  String roundUpExplainer(String unit);

  /// Explains round-up saving with a multiplier, e.g. 'the difference ×2'.
  ///
  /// In en, this message translates to:
  /// **'We\'ll round up every purchase to the nearest {unit} and save the difference {multiplier} automatically.'**
  String roundUpExplainerMultiplied(String unit, String multiplier);

  /// Account ownership: held by this customer alone.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get ownershipPrimary;

  /// Account ownership: shared with someone else.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get ownershipJoint;

  /// Account ownership: this customer is a named beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get ownershipBeneficiary;

  /// Paywall headline naming the locked feature.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to access {feature}'**
  String paywallUpgradeTo(String feature);

  /// Paywall dismissal action.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get paywallMaybeLater;

  /// Paywall primary action.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get paywallUpgrade;

  /// Marks the plan the customer already has.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get paywallCurrentPlan;

  /// Screen-reader name for the paywall close control.
  ///
  /// In en, this message translates to:
  /// **'Dismiss upgrade prompt'**
  String get paywallDismiss;

  /// Confirmation that a membership perk is now active.
  ///
  /// In en, this message translates to:
  /// **'Perk activated'**
  String get perkActivated;

  /// Screen-reader state for an active perk.
  ///
  /// In en, this message translates to:
  /// **'Activated.'**
  String get perkActivatedSpoken;

  /// Screen-reader state for an inactive perk.
  ///
  /// In en, this message translates to:
  /// **'Not activated.'**
  String get perkNotActivatedSpoken;

  /// Action that shares a referral code.
  ///
  /// In en, this message translates to:
  /// **'Share referral code'**
  String get referralShareCode;

  /// Dispute reason: the customer did not make the transaction.
  ///
  /// In en, this message translates to:
  /// **'I did not authorize this'**
  String get disputeUnauthorized;

  /// Dispute reason: duplicate charge.
  ///
  /// In en, this message translates to:
  /// **'I was charged twice'**
  String get disputeDuplicate;

  /// Dispute reason: incorrect amount.
  ///
  /// In en, this message translates to:
  /// **'The amount is wrong'**
  String get disputeWrongAmount;

  /// Dispute reason: paid but nothing arrived.
  ///
  /// In en, this message translates to:
  /// **'Goods or services not received'**
  String get disputeNotReceived;

  /// Dispute reason: charged after cancelling.
  ///
  /// In en, this message translates to:
  /// **'I cancelled this subscription'**
  String get disputeCancelledSubscription;

  /// Dispute reason: none of the listed options.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get disputeOther;

  /// Dispute progress: filed with the bank.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get disputeStageSubmitted;

  /// Dispute progress: being investigated.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get disputeStageUnderReview;

  /// Dispute progress: closed.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get disputeStageResolved;

  /// Screen-reader summary of an account row.
  ///
  /// In en, this message translates to:
  /// **'Account: {name}, {number}, {balance}'**
  String a11yAccountSummary(String name, String number, String balance);

  /// Marks the currently chosen item for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'{label}, selected'**
  String a11ySelectedSuffix(String label);

  /// Screen-reader phrasing of an account balance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String a11yBalanceIs(String amount);

  /// Screen-reader summary of a budget gauge.
  ///
  /// In en, this message translates to:
  /// **'{name} budget: {spent} of {limit}'**
  String a11yBudgetSummary(String name, String spent, String limit);

  /// Appended when a budget has been exceeded.
  ///
  /// In en, this message translates to:
  /// **'{summary}, over budget'**
  String a11yBudgetOverspent(String summary);

  /// Screen-reader summary of a cashflow chart's history.
  ///
  /// In en, this message translates to:
  /// **'Balance ranged from {low} to {high}'**
  String a11yBalanceRange(String low, String high);

  /// Appended when a cashflow chart also shows a forecast.
  ///
  /// In en, this message translates to:
  /// **'{summary}, projected {projection}'**
  String a11yBalanceRangeProjected(String summary, String projection);

  /// Screen-reader summary of a forecast bill row.
  ///
  /// In en, this message translates to:
  /// **'{biller}, {amount}'**
  String a11yBillForecast(String biller, String amount);

  /// Appended when a forecast bill amount is only an estimate.
  ///
  /// In en, this message translates to:
  /// **'{summary}, estimated'**
  String a11yBillForecastEstimated(String summary);

  /// The customer's place in the sign-in queue.
  ///
  /// In en, this message translates to:
  /// **'You are number {position} in line'**
  String gateQueuePosition(String position);

  /// Queue position followed by the estimated wait.
  ///
  /// In en, this message translates to:
  /// **'{position}, about {wait}'**
  String gateQueuePositionWithEta(String position, String wait);

  /// Button that repeats a failed operation. Distinct from Retry, which is the terser form used in dense rows.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Countdown until the app retries a failed connection.
  ///
  /// In en, this message translates to:
  /// **'Retrying in {seconds}s'**
  String connectivityRetryingIn(String seconds);

  /// Delivery channel: a text message.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get notifChannelSms;

  /// Screen-reader summary of a credit-limit gauge.
  ///
  /// In en, this message translates to:
  /// **'{label}: {used} used of {limit}, {available} available'**
  String a11yCreditLimit(
      String label, String used, String limit, String available);

  /// Caption under an available amount, in running text rather than as a heading, so lower case in English.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get labelAvailableLower;

  /// How many people have accepted a referral.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 friend invited} other{{count} friends invited}}'**
  String referralFriendsInvited(int count);

  /// Referral progress against the reward cap.
  ///
  /// In en, this message translates to:
  /// **'{invited} of {max}'**
  String referralProgress(String invited, String max);

  /// Headline confirming the caller is genuine.
  ///
  /// In en, this message translates to:
  /// **'You are speaking with {bank}'**
  String callVerifyActiveHeadline(String bank);

  /// Label for the ceiling of a limit gauge.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get labelLimit;

  /// Button that dismisses a confirmation without acting.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get actionGoBack;

  /// Screen-reader name for an overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get actionMoreActions;

  /// Confirmation title for skipping one instance of a standing order.
  ///
  /// In en, this message translates to:
  /// **'Skip next payment?'**
  String get standingOrderSkipTitle;

  /// Confirmation title for cancelling a standing order outright.
  ///
  /// In en, this message translates to:
  /// **'Cancel standing order?'**
  String get standingOrderCancelTitle;

  /// Menu item that skips the next instance.
  ///
  /// In en, this message translates to:
  /// **'Skip next payment'**
  String get standingOrderSkipAction;

  /// Menu item that stops all future payments.
  ///
  /// In en, this message translates to:
  /// **'Cancel standing order'**
  String get standingOrderCancelAction;

  /// Menu item that suspends a standing order.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get standingOrderPause;

  /// Menu item that restarts a paused standing order.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get standingOrderResume;

  /// Standing-order state: suspended.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get standingOrderPaused;

  /// Standing-order state: the last attempt did not go through.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get standingOrderFailed;

  /// Action that re-attempts a failed standing-order payment.
  ///
  /// In en, this message translates to:
  /// **'Retry payment'**
  String get standingOrderRetry;

  /// Prefix before the date of a recurring merchant’s next charge, as in “next 1 Jul”.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get merchantNextPrefix;

  /// Badge marking a subscription that costs more than it used to.
  ///
  /// In en, this message translates to:
  /// **'Price rise'**
  String get merchantPriceRise;

  /// Action that explains how to end a subscription.
  ///
  /// In en, this message translates to:
  /// **'How to cancel'**
  String get merchantHowToCancel;

  /// Action that refuses further charges from a merchant.
  ///
  /// In en, this message translates to:
  /// **'Block future payments'**
  String get merchantBlockAction;

  /// Confirmation title before blocking a merchant.
  ///
  /// In en, this message translates to:
  /// **'Block this merchant?'**
  String get merchantBlockTitle;

  /// Action that withdraws an app’s access to account data.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get consentRevoke;

  /// Confirmation title before revoking an app’s access.
  ///
  /// In en, this message translates to:
  /// **'Revoke access?'**
  String get consentRevokeTitle;

  /// Confirmation body before revoking an app’s access.
  ///
  /// In en, this message translates to:
  /// **'This app immediately loses access to your data.'**
  String get consentRevokeBody;

  /// Prefix before the date access was granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get consentGrantedPrefix;

  /// Prefix before the date access lapses, in running text.
  ///
  /// In en, this message translates to:
  /// **'expires'**
  String get consentExpiresPrefix;

  /// Consent state: withdrawn by the customer.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get consentRevoked;

  /// Consent state: lapsed.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get consentExpired;

  /// Consent state: close to lapsing.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get consentExpiringSoon;
}

class _BankL10nDelegate extends LocalizationsDelegate<BankL10n> {
  const _BankL10nDelegate();

  @override
  Future<BankL10n> load(Locale locale) {
    return SynchronousFuture<BankL10n>(lookupBankL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_BankL10nDelegate old) => false;
}

BankL10n lookupBankL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return BankL10nAr();
    case 'en':
      return BankL10nEn();
  }

  throw FlutterError(
      'BankL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
