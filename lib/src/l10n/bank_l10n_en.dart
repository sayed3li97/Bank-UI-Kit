// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'bank_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class BankL10nEn extends BankL10n {
  BankL10nEn([String locale = 'en']) : super(locale);

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String minutesAgoShort(String count) {
    return '${count}m ago';
  }

  @override
  String hoursAgoShort(String count) {
    return '${count}h ago';
  }

  @override
  String daysAgoShort(String count) {
    return '${count}d ago';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCleared => 'Cleared';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusFrozen => 'Frozen';

  @override
  String get statusRestricted => 'Restricted';

  @override
  String get statusActive => 'Active';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionDecline => 'Decline';

  @override
  String get actionShare => 'Share';

  @override
  String get actionDispute => 'Dispute';

  @override
  String get actionReport => 'Report';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied';

  @override
  String get actionViewDetails => 'View details';

  @override
  String get actionContactSupport => 'Contact support';

  @override
  String get actionCustom => 'Custom';

  @override
  String get sendMoney => 'Send money';

  @override
  String get requestMoney => 'Request money';

  @override
  String get addMoney => 'Add money';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get balanceHidden => '••••';

  @override
  String get balanceHiddenSpoken => 'Balance hidden';

  @override
  String get pointsBalanceHiddenSpoken => 'Points balance hidden';

  @override
  String get labelAvailable => 'Available';

  @override
  String get labelUsed => 'Used';

  @override
  String get labelGoal => 'Goal';

  @override
  String get labelProgress => 'Progress';

  @override
  String get labelAmount => 'Amount';

  @override
  String get labelCurrency => 'Currency';

  @override
  String get labelVersion => 'Version';

  @override
  String get labelLastUpdated => 'Last updated';

  @override
  String get interestRate => 'Interest rate';

  @override
  String get profitRate => 'Profit rate';

  @override
  String get annualPercentageRate => 'APR';

  @override
  String get interestFree => 'Interest free';

  @override
  String get perMonth => '/month';

  @override
  String get perMonthShort => '/mo';

  @override
  String installmentMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get addToPot => 'Add to pot';

  @override
  String get withdrawFromPot => 'Withdraw from pot';

  @override
  String get splitEqually => 'Split equally';

  @override
  String get confirmPin => 'Enter PIN to confirm';

  @override
  String get sessionTimeout => 'Session expired';

  @override
  String get sessionTimeoutBody =>
      'Your session has expired for security. Please log in again.';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get loadingTransactions => 'Loading transactions…';

  @override
  String get transferSuccess => 'Transfer sent';

  @override
  String get transferFailure => 'Transfer failed';

  @override
  String get newDevice => 'New device detected';

  @override
  String get newDeviceBody =>
      'We noticed a login from a new device. If this was you, no action is needed.';

  @override
  String get compromisedDevice => 'Security warning';

  @override
  String get compromisedDeviceBody =>
      'This device may be compromised. For your safety, some features have been limited.';

  @override
  String get verificationUnderReview => 'Verification under review';

  @override
  String get verificationUnderReviewBody =>
      'We\'re reviewing your documents. This usually takes 1–2 business days.';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryDining => 'Dining';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categorySubscription => 'Subscription';

  @override
  String get categoryTransfer => 'Transfer';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categoryInvestment => 'Investment';

  @override
  String get categoryCredit => 'Credit';

  @override
  String get categoryCreditPayment => 'Credit Payment';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyBiweekly => 'Biweekly';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get notifGroupSecurity => 'Security & fraud';

  @override
  String get notifGroupPayments => 'Payments';

  @override
  String get notifGroupAccount => 'Account activity';

  @override
  String get notifGroupMarketing => 'Marketing';

  @override
  String get notifChannelPush => 'Push';

  @override
  String get notifChannelEmail => 'Email';

  @override
  String get notifSecurityAlerts => 'Security alerts';

  @override
  String get notifFraudWarnings => 'Fraud warnings';

  @override
  String get notifIdentityVerification => 'Identity verification';

  @override
  String get notifPayments => 'Payments';

  @override
  String get notifTransfers => 'Transfers';

  @override
  String get notifCardActivity => 'Card activity';

  @override
  String get notifSavingsGoals => 'Savings goals';

  @override
  String get notifPriceAlerts => 'Price alerts';

  @override
  String get notifServiceUpdates => 'Service updates';

  @override
  String get notifOffersAndNews => 'Offers & news';

  @override
  String get toastSuccess => 'Success';

  @override
  String get toastError => 'Error';

  @override
  String get toastInfo => 'Info';

  @override
  String get toastWarning => 'Warning';

  @override
  String get connectivityOfflineTitle => 'You\'re offline';

  @override
  String get connectivityDegradedTitle => 'Some services are affected';

  @override
  String get connectivityRestored =>
      'Back online. Your accounts are up to date.';

  @override
  String get gateMaintenanceTitle => 'Maintenance in progress';

  @override
  String get gateMaintenanceBody =>
      'We are making some important updates. We will be back as soon as we can.';

  @override
  String get gateOfflineTitle => 'No internet connection';

  @override
  String get gateOfflineBody =>
      'Your device seems to be offline. Check your Wi-Fi or mobile data, then try again.';

  @override
  String get gateForceUpdateTitle => 'Time to update';

  @override
  String get gateForceUpdateBody =>
      'Update needed to keep your money safe. This version of the app is no longer supported.';

  @override
  String get gateDeviceBlockedTitle => 'We can\'t open the app';

  @override
  String get gateDeviceBlockedBody =>
      'We can\'t open the app on this device right now.';

  @override
  String get gateSignInBlockedTitle => 'We can\'t log you in';

  @override
  String get gateSignInBlockedBody =>
      'We can\'t log you in right now, please try again later.';

  @override
  String get gateClockSkewTitle => 'Check your date and time';

  @override
  String get gateClockSkewBody =>
      'Your device\'s clock looks wrong, so we can\'t connect securely. Setting it back to automatic usually fixes this.';

  @override
  String get gateDeveloperModeTitle => 'Developer mode is on';

  @override
  String get gateDeveloperModeBody =>
      'For your security the app cannot run while developer mode is switched on. Turning it off fixes this.';

  @override
  String get gateQueueTitle => 'You are in the queue';

  @override
  String get gateQueueBody =>
      'A lot of people are signing in right now, so we are letting everyone in gradually.';

  @override
  String get gateClockStep1 => 'Open your device Settings';

  @override
  String get gateClockStep2 => 'Go to Date and Time';

  @override
  String get gateClockStep3 => 'Turn on Set automatically';

  @override
  String get gateClockStep4 => 'Come back to the app';

  @override
  String get gateDeveloperStep1 => 'Open your device Settings';

  @override
  String get gateDeveloperStep2 => 'Go to Developer options';

  @override
  String get gateDeveloperStep3 => 'Switch developer mode off';

  @override
  String get gateDeveloperStep4 => 'Come back to the app';

  @override
  String get gateStillWorking => 'Still working';

  @override
  String get gateReferenceHint => 'Quote this code if you contact us';

  @override
  String get gateBackByAround => 'Back by around';

  @override
  String get gateTakingLonger => 'Taking a little longer than expected';

  @override
  String get gateQueueReassurance =>
      'We\'ll bring you in automatically. Your place is saved.';

  @override
  String get gateUpdateHelp => 'Get help with updating';

  @override
  String get gateMoneyIsSafe => 'Your money is safe.';

  @override
  String get gateAlternativeCardPayments => 'Card payments';

  @override
  String get gateAlternativeAtm => 'ATM withdrawals';

  @override
  String get gateAlternativePhone => 'Phone banking';

  @override
  String get gateEtaLessThanMinute => 'less than a minute';

  @override
  String gateEtaMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get updateTitle => 'A new version is ready';

  @override
  String get updateBody =>
      'This update includes fixes and improvements to keep the app fast and secure.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateNotNow => 'Not now';

  @override
  String updateSunset(String date) {
    return 'This version stops working on $date';
  }

  @override
  String updateVersion(String version) {
    return 'Version $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'you have $version';
  }

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authUseBiometrics => 'Use biometrics';

  @override
  String get authDeleteDigit => 'Delete';

  @override
  String get authShowBalances => 'Show balances';

  @override
  String get authHideBalances => 'Hide balances';

  @override
  String get authSessionExpiringTitle => 'Session expiring';

  @override
  String get authSessionExpiringBody =>
      'Your session will expire soon. Stay logged in?';

  @override
  String get authStayLoggedIn => 'Stay logged in';

  @override
  String get authLogOut => 'Log out';

  @override
  String get authSignOutDeviceBody =>
      'The device will need to sign in again to access the account.';

  @override
  String get scaConfirmPayment => 'Confirm payment';

  @override
  String get scaRejectPayment => 'Reject payment';

  @override
  String get scaUsePinInstead => 'Use PIN instead';

  @override
  String get scaUseBiometricsInstead => 'Use biometrics instead';

  @override
  String get scaAuthenticatorPrompt =>
      'Approve this payment in your authenticator';

  @override
  String get scaExpiresIn => 'Expires in';

  @override
  String callVerifyUnverifiedWarning(String bank) {
    return 'If the person on the phone right now says they are calling from $bank, hang up: they are a scammer. Genuine staff will never pressure you to move money or share security codes.';
  }

  @override
  String get callVerifyVerifiedReassurance =>
      'This call has been verified. Our team member will never ask for your PIN, your password, or a one time passcode.';

  @override
  String callVerifyIdleSummary(String bank) {
    return 'No call is in progress right now. Below is a summary of your most recent verified call with $bank.';
  }

  @override
  String get panicUnfreezeConfirmBody =>
      'Your cards and outgoing payments will start working again.';

  @override
  String panicHoldHint(String seconds) {
    return 'Press and hold for $seconds seconds to freeze all cards and outgoing payments';
  }

  @override
  String get cardBack => 'Card back';

  @override
  String get cardFront => 'Card front';

  @override
  String get cardShowDetails => 'Show card details';

  @override
  String get cardFlip => 'Flip card';

  @override
  String get cardGenericNetwork => 'Payment card';

  @override
  String get cardIbanOrAccount => 'IBAN / Account';

  @override
  String get cardSortCodeOrBic => 'Sort Code / BIC';

  @override
  String get cardTapToCopyHint => 'Tap values to copy';

  @override
  String cardBlockDelayNotice(String label, String hours) {
    return 'For your protection this change is delayed. $label payments stay blocked for $hours more hours after you confirm.';
  }

  @override
  String get validationIban => 'Enter a valid IBAN.';

  @override
  String get validationCardNumber => 'Enter a valid card number.';

  @override
  String get validationSortCode => 'Enter a valid sort code.';

  @override
  String get validationGeneric => 'Enter a valid value.';

  @override
  String get periodPreviousMonth => 'Previous month';

  @override
  String get periodPreviousQuarter => 'Previous quarter';

  @override
  String get periodPreviousYear => 'Previous year';

  @override
  String get periodNextMonth => 'Next month';

  @override
  String get periodNextQuarter => 'Next quarter';

  @override
  String get periodNextYear => 'Next year';

  @override
  String get periodAll => 'All';

  @override
  String get sheetDragHandle => 'Drag handle';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get creditScorePoor => 'Poor';

  @override
  String get creditScoreFair => 'Fair';

  @override
  String get creditScoreGood => 'Good';

  @override
  String get creditScoreVeryGood => 'Very good';

  @override
  String get creditScoreExcellent => 'Excellent';

  @override
  String get creditFlexEligible => 'Flex eligible';

  @override
  String get insightConfidenceHigh => 'High confidence';

  @override
  String get insightConfidenceMedium => 'Medium confidence';

  @override
  String get insightConfidenceLow => 'Low confidence';

  @override
  String get merchantBlockNotice =>
      'Future charges from this merchant will be declined.';

  @override
  String get captureFrameDocument => 'Position your document in the frame';

  @override
  String get captureKeepInFrame => 'Keep the document in frame';

  @override
  String get captureHoldStill => 'Hold still…';

  @override
  String get captureMoveFurther => 'Move further away';

  @override
  String get captureMoveCloser => 'Move closer';

  @override
  String get captureImproveLighting => 'Improve lighting conditions';

  @override
  String get captureHoldSteady => 'Hold the camera steady';

  @override
  String get captureTakePhoto => 'Capture document';

  @override
  String get livenessPositionFace => 'Position your face in the oval';

  @override
  String get livenessLookStraight => 'Look straight at the camera';

  @override
  String get livenessVerified => 'Liveness verified';

  @override
  String get livenessFailed => 'Could not verify: please try again';

  @override
  String get consentEmptyBody =>
      'Apps you allow to access your account data appear here.';

  @override
  String get standingOrderSkipBody =>
      'The next scheduled payment will be skipped. Later payments stay on schedule.';

  @override
  String get standingOrderCancelBody =>
      'This permanently stops all future payments to this payee.';

  @override
  String get disclosureReviewAndAgree => 'Review and agree';

  @override
  String get disclosureAgreeAndContinue => 'Agree and continue';

  @override
  String get offerEndsToday => 'Ends today';

  @override
  String offerDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get offerExpired => 'Offer expired';

  @override
  String potMaxContribution(String amount) {
    return 'Maximum contribution is $amount to reach your goal';
  }

  @override
  String roundUpExplainer(String unit) {
    return 'We\'ll round up every purchase to the nearest $unit and save the difference automatically.';
  }

  @override
  String roundUpExplainerMultiplied(String unit, String multiplier) {
    return 'We\'ll round up every purchase to the nearest $unit and save the difference $multiplier automatically.';
  }

  @override
  String get ownershipPrimary => 'Primary';

  @override
  String get ownershipJoint => 'Joint';

  @override
  String get ownershipBeneficiary => 'Beneficiary';

  @override
  String paywallUpgradeTo(String feature) {
    return 'Upgrade to access $feature';
  }

  @override
  String get paywallMaybeLater => 'Maybe later';

  @override
  String get paywallUpgrade => 'Upgrade';

  @override
  String get paywallCurrentPlan => 'Current plan';

  @override
  String get paywallDismiss => 'Dismiss upgrade prompt';

  @override
  String get perkActivated => 'Perk activated';

  @override
  String get perkActivatedSpoken => 'Activated.';

  @override
  String get perkNotActivatedSpoken => 'Not activated.';

  @override
  String get referralShareCode => 'Share referral code';

  @override
  String get disputeUnauthorized => 'I did not authorize this';

  @override
  String get disputeDuplicate => 'I was charged twice';

  @override
  String get disputeWrongAmount => 'The amount is wrong';

  @override
  String get disputeNotReceived => 'Goods or services not received';

  @override
  String get disputeCancelledSubscription => 'I cancelled this subscription';

  @override
  String get disputeOther => 'Something else';

  @override
  String get disputeStageSubmitted => 'Submitted';

  @override
  String get disputeStageUnderReview => 'Under review';

  @override
  String get disputeStageResolved => 'Resolved';

  @override
  String a11yAccountSummary(String name, String number, String balance) {
    return 'Account: $name, $number, $balance';
  }

  @override
  String a11ySelectedSuffix(String label) {
    return '$label, selected';
  }

  @override
  String a11yBalanceIs(String amount) {
    return 'Balance: $amount';
  }

  @override
  String a11yBudgetSummary(String name, String spent, String limit) {
    return '$name budget: $spent of $limit';
  }

  @override
  String a11yBudgetOverspent(String summary) {
    return '$summary, over budget';
  }

  @override
  String a11yBalanceRange(String low, String high) {
    return 'Balance ranged from $low to $high';
  }

  @override
  String a11yBalanceRangeProjected(String summary, String projection) {
    return '$summary, projected $projection';
  }

  @override
  String a11yBillForecast(String biller, String amount) {
    return '$biller, $amount';
  }

  @override
  String a11yBillForecastEstimated(String summary) {
    return '$summary, estimated';
  }

  @override
  String gateQueuePosition(String position) {
    return 'You are number $position in line';
  }

  @override
  String gateQueuePositionWithEta(String position, String wait) {
    return '$position, about $wait';
  }

  @override
  String get actionTryAgain => 'Try again';

  @override
  String connectivityRetryingIn(String seconds) {
    return 'Retrying in ${seconds}s';
  }

  @override
  String get notifChannelSms => 'SMS';

  @override
  String a11yCreditLimit(
      String label, String used, String limit, String available) {
    return '$label: $used used of $limit, $available available';
  }

  @override
  String get labelAvailableLower => 'available';

  @override
  String referralFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends invited',
      one: '1 friend invited',
    );
    return '$_temp0';
  }

  @override
  String referralProgress(String invited, String max) {
    return '$invited of $max';
  }

  @override
  String callVerifyActiveHeadline(String bank) {
    return 'You are speaking with $bank';
  }

  @override
  String get labelLimit => 'Limit';

  @override
  String get actionGoBack => 'Go back';

  @override
  String get actionMoreActions => 'More actions';

  @override
  String get standingOrderSkipTitle => 'Skip next payment?';

  @override
  String get standingOrderCancelTitle => 'Cancel standing order?';

  @override
  String get standingOrderSkipAction => 'Skip next payment';

  @override
  String get standingOrderCancelAction => 'Cancel standing order';

  @override
  String get standingOrderPause => 'Pause';

  @override
  String get standingOrderResume => 'Resume';

  @override
  String get standingOrderPaused => 'Paused';

  @override
  String get standingOrderFailed => 'Failed';

  @override
  String get standingOrderRetry => 'Retry payment';

  @override
  String get merchantNextPrefix => 'next';

  @override
  String get merchantPriceRise => 'Price rise';

  @override
  String get merchantHowToCancel => 'How to cancel';

  @override
  String get merchantBlockAction => 'Block future payments';

  @override
  String get merchantBlockTitle => 'Block this merchant?';

  @override
  String get consentRevoke => 'Revoke access';

  @override
  String get consentRevokeTitle => 'Revoke access?';

  @override
  String get consentRevokeBody =>
      'This app immediately loses access to your data.';

  @override
  String get consentGrantedPrefix => 'Granted';

  @override
  String get consentExpiresPrefix => 'expires';

  @override
  String get consentRevoked => 'Revoked';

  @override
  String get consentExpired => 'Expired';

  @override
  String get consentExpiringSoon => 'Expiring soon';
}
