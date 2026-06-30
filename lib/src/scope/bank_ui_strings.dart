import '../../bank_ui_kit.dart';
import '../../core.dart';
import 'bank_ui_scope.dart';
import 'scope.dart';

/// All user-visible strings rendered by the Bank UI Kit.
///
/// Every field carries an English default. Host apps that need a different
/// language or tone can construct a custom [BankUiStrings] instance and pass
/// it to [BankUiScope].
class BankUiStrings {
  final String today;
  final String yesterday;
  final String pending;
  final String cleared;
  final String declined;
  final String refunded;
  final String scheduled;
  final String frozen;
  final String restricted;
  final String active;
  final String balanceHidden;
  final String sendMoney;
  final String requestMoney;
  final String addMoney;
  final String withdraw;
  final String confirmPin;
  final String sessionTimeout;
  final String sessionTimeoutBody;
  final String retry;
  final String contactSupport;
  final String noTransactions;
  final String loadingTransactions;
  final String transferSuccess;
  final String transferFailure;
  final String interestRate;
  final String profitRate;
  final String annualPercentageRate;
  final String profitRateAbbr;
  final String available;
  final String used;
  final String goal;
  final String progress;
  final String addToPot;
  final String withdrawFromPot;
  final String splitEqually;
  final String custom;
  final String done;
  final String cancel;
  final String confirm;
  final String next;
  final String back;
  final String skip;
  final String accept;
  final String decline;
  final String share;
  final String dispute;
  final String report;
  final String newDevice;
  final String newDeviceBody;
  final String compromisedDevice;
  final String compromisedDeviceBody;
  final String verificationUnderReview;
  final String verificationUnderReviewBody;

  /// Template string for installment plan term length.
  ///
  /// Contains the literal token `{n}` which the host app should replace with
  /// the actual month count before displaying. The package itself never
  /// interpolates this string.
  final String installmentMonths;

  final String interestFree;
  final String perMonth;

  const BankUiStrings({
    this.today = 'Today',
    this.yesterday = 'Yesterday',
    this.pending = 'Pending',
    this.cleared = 'Cleared',
    this.declined = 'Declined',
    this.refunded = 'Refunded',
    this.scheduled = 'Scheduled',
    this.frozen = 'Frozen',
    this.restricted = 'Restricted',
    this.active = 'Active',
    this.balanceHidden = '••••',
    this.sendMoney = 'Send Money',
    this.requestMoney = 'Request Money',
    this.addMoney = 'Add Money',
    this.withdraw = 'Withdraw',
    this.confirmPin = 'Enter PIN to confirm',
    this.sessionTimeout = 'Session Expired',
    this.sessionTimeoutBody =
        'Your session has expired for security. Please log in again.',
    this.retry = 'Retry',
    this.contactSupport = 'Contact Support',
    this.noTransactions = 'No transactions yet',
    this.loadingTransactions = 'Loading transactions…',
    this.transferSuccess = 'Transfer Sent',
    this.transferFailure = 'Transfer Failed',
    this.interestRate = 'Interest Rate',
    this.profitRate = 'Profit Rate',
    this.annualPercentageRate = 'APR',
    this.profitRateAbbr = 'Profit Rate',
    this.available = 'Available',
    this.used = 'Used',
    this.goal = 'Goal',
    this.progress = 'Progress',
    this.addToPot = 'Add to Pot',
    this.withdrawFromPot = 'Withdraw from Pot',
    this.splitEqually = 'Split Equally',
    this.custom = 'Custom',
    this.done = 'Done',
    this.cancel = 'Cancel',
    this.confirm = 'Confirm',
    this.next = 'Next',
    this.back = 'Back',
    this.skip = 'Skip',
    this.accept = 'Accept',
    this.decline = 'Decline',
    this.share = 'Share',
    this.dispute = 'Dispute',
    this.report = 'Report',
    this.newDevice = 'New Device Detected',
    this.newDeviceBody = 'We noticed a login from a new device. '
        'If this was you, no action is needed.',
    this.compromisedDevice = 'Security Warning',
    this.compromisedDeviceBody = 'This device may be compromised. '
        'For your safety, some features have been limited.',
    this.verificationUnderReview = 'Verification Under Review',
    this.verificationUnderReviewBody = 'We\'re reviewing your documents. '
        'This usually takes 1–2 business days.',
    this.installmentMonths = '{n} months',
    this.interestFree = 'Interest Free',
    this.perMonth = '/month',
  });

  /// Canonical defaults instance. Widgets use this when the host app does not
  /// supply a custom [BankUiStrings] via [BankUiScope].
  static const BankUiStrings defaults = BankUiStrings();

  BankUiStrings copyWith({
    String? today,
    String? yesterday,
    String? pending,
    String? cleared,
    String? declined,
    String? refunded,
    String? scheduled,
    String? frozen,
    String? restricted,
    String? active,
    String? balanceHidden,
    String? sendMoney,
    String? requestMoney,
    String? addMoney,
    String? withdraw,
    String? confirmPin,
    String? sessionTimeout,
    String? sessionTimeoutBody,
    String? retry,
    String? contactSupport,
    String? noTransactions,
    String? loadingTransactions,
    String? transferSuccess,
    String? transferFailure,
    String? interestRate,
    String? profitRate,
    String? annualPercentageRate,
    String? profitRateAbbr,
    String? available,
    String? used,
    String? goal,
    String? progress,
    String? addToPot,
    String? withdrawFromPot,
    String? splitEqually,
    String? custom,
    String? done,
    String? cancel,
    String? confirm,
    String? next,
    String? back,
    String? skip,
    String? accept,
    String? decline,
    String? share,
    String? dispute,
    String? report,
    String? newDevice,
    String? newDeviceBody,
    String? compromisedDevice,
    String? compromisedDeviceBody,
    String? verificationUnderReview,
    String? verificationUnderReviewBody,
    String? installmentMonths,
    String? interestFree,
    String? perMonth,
  }) =>
      BankUiStrings(
        today: today ?? this.today,
        yesterday: yesterday ?? this.yesterday,
        pending: pending ?? this.pending,
        cleared: cleared ?? this.cleared,
        declined: declined ?? this.declined,
        refunded: refunded ?? this.refunded,
        scheduled: scheduled ?? this.scheduled,
        frozen: frozen ?? this.frozen,
        restricted: restricted ?? this.restricted,
        active: active ?? this.active,
        balanceHidden: balanceHidden ?? this.balanceHidden,
        sendMoney: sendMoney ?? this.sendMoney,
        requestMoney: requestMoney ?? this.requestMoney,
        addMoney: addMoney ?? this.addMoney,
        withdraw: withdraw ?? this.withdraw,
        confirmPin: confirmPin ?? this.confirmPin,
        sessionTimeout: sessionTimeout ?? this.sessionTimeout,
        sessionTimeoutBody: sessionTimeoutBody ?? this.sessionTimeoutBody,
        retry: retry ?? this.retry,
        contactSupport: contactSupport ?? this.contactSupport,
        noTransactions: noTransactions ?? this.noTransactions,
        loadingTransactions: loadingTransactions ?? this.loadingTransactions,
        transferSuccess: transferSuccess ?? this.transferSuccess,
        transferFailure: transferFailure ?? this.transferFailure,
        interestRate: interestRate ?? this.interestRate,
        profitRate: profitRate ?? this.profitRate,
        annualPercentageRate: annualPercentageRate ?? this.annualPercentageRate,
        profitRateAbbr: profitRateAbbr ?? this.profitRateAbbr,
        available: available ?? this.available,
        used: used ?? this.used,
        goal: goal ?? this.goal,
        progress: progress ?? this.progress,
        addToPot: addToPot ?? this.addToPot,
        withdrawFromPot: withdrawFromPot ?? this.withdrawFromPot,
        splitEqually: splitEqually ?? this.splitEqually,
        custom: custom ?? this.custom,
        done: done ?? this.done,
        cancel: cancel ?? this.cancel,
        confirm: confirm ?? this.confirm,
        next: next ?? this.next,
        back: back ?? this.back,
        skip: skip ?? this.skip,
        accept: accept ?? this.accept,
        decline: decline ?? this.decline,
        share: share ?? this.share,
        dispute: dispute ?? this.dispute,
        report: report ?? this.report,
        newDevice: newDevice ?? this.newDevice,
        newDeviceBody: newDeviceBody ?? this.newDeviceBody,
        compromisedDevice: compromisedDevice ?? this.compromisedDevice,
        compromisedDeviceBody:
            compromisedDeviceBody ?? this.compromisedDeviceBody,
        verificationUnderReview:
            verificationUnderReview ?? this.verificationUnderReview,
        verificationUnderReviewBody:
            verificationUnderReviewBody ?? this.verificationUnderReviewBody,
        installmentMonths: installmentMonths ?? this.installmentMonths,
        interestFree: interestFree ?? this.interestFree,
        perMonth: perMonth ?? this.perMonth,
      );
}
