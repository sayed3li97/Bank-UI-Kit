// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'bank_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class BankL10nAr extends BankL10n {
  BankL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة واحدة',
      zero: 'منذ أقل من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة واحدة',
      zero: 'منذ أقل من ساعة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String minutesAgoShort(String count) {
    return 'منذ $count د';
  }

  @override
  String hoursAgoShort(String count) {
    return 'منذ $count س';
  }

  @override
  String daysAgoShort(String count) {
    return 'منذ $count ي';
  }

  @override
  String get statusPending => 'قيد المعالجة';

  @override
  String get statusCleared => 'تمت التسوية';

  @override
  String get statusDeclined => 'مرفوضة';

  @override
  String get statusRefunded => 'مُستردّة';

  @override
  String get statusScheduled => 'مجدولة';

  @override
  String get statusFrozen => 'مجمّدة';

  @override
  String get statusRestricted => 'مقيّدة';

  @override
  String get statusActive => 'نشطة';

  @override
  String get actionDone => 'تم';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionNext => 'التالي';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionSkip => 'تخطٍّ';

  @override
  String get actionAccept => 'قبول';

  @override
  String get actionDecline => 'رفض';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get actionDispute => 'اعتراض';

  @override
  String get actionReport => 'إبلاغ';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionCopy => 'نسخ';

  @override
  String get actionCopied => 'تم النسخ';

  @override
  String get actionViewDetails => 'عرض التفاصيل';

  @override
  String get actionContactSupport => 'التواصل مع الدعم';

  @override
  String get actionCustom => 'مبلغ مخصّص';

  @override
  String get sendMoney => 'إرسال الأموال';

  @override
  String get requestMoney => 'طلب الأموال';

  @override
  String get addMoney => 'إضافة أموال';

  @override
  String get withdraw => 'سحب';

  @override
  String get balanceHidden => '••••';

  @override
  String get balanceHiddenSpoken => 'الرصيد مخفي';

  @override
  String get pointsBalanceHiddenSpoken => 'رصيد النقاط مخفي';

  @override
  String get labelAvailable => 'المتاح';

  @override
  String get labelUsed => 'المستخدم';

  @override
  String get labelGoal => 'الهدف';

  @override
  String get labelProgress => 'التقدّم';

  @override
  String get labelAmount => 'المبلغ';

  @override
  String get labelCurrency => 'العملة';

  @override
  String get labelVersion => 'الإصدار';

  @override
  String get labelLastUpdated => 'آخر تحديث';

  @override
  String get interestRate => 'معدّل الفائدة';

  @override
  String get profitRate => 'معدّل الربح';

  @override
  String get annualPercentageRate => 'النسبة السنوية';

  @override
  String get interestFree => 'بدون فوائد';

  @override
  String get perMonth => '/شهريًا';

  @override
  String get perMonthShort => '/شهر';

  @override
  String installmentMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهر',
      many: '$count شهرًا',
      few: '$count أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: 'بدون أشهر',
    );
    return '$_temp0';
  }

  @override
  String get addToPot => 'إضافة إلى الحصّالة';

  @override
  String get withdrawFromPot => 'سحب من الحصّالة';

  @override
  String get splitEqually => 'التقسيم بالتساوي';

  @override
  String get confirmPin => 'أدخل الرقم السري للتأكيد';

  @override
  String get sessionTimeout => 'انتهت الجلسة';

  @override
  String get sessionTimeoutBody =>
      'انتهت جلستك لدواعٍ أمنية. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get noTransactions => 'لا توجد معاملات بعد';

  @override
  String get loadingTransactions => 'جارٍ تحميل المعاملات…';

  @override
  String get transferSuccess => 'تم إرسال التحويل';

  @override
  String get transferFailure => 'تعذّر إتمام التحويل';

  @override
  String get newDevice => 'تم رصد جهاز جديد';

  @override
  String get newDeviceBody =>
      'لاحظنا تسجيل دخول من جهاز جديد. إذا كنت أنت، فلا حاجة لأي إجراء.';

  @override
  String get compromisedDevice => 'تحذير أمني';

  @override
  String get compromisedDeviceBody =>
      'قد يكون هذا الجهاز مخترقًا. لسلامتك، جرى تقييد بعض الميزات.';

  @override
  String get verificationUnderReview => 'التحقق قيد المراجعة';

  @override
  String get verificationUnderReviewBody =>
      'نراجع مستنداتك حاليًا. تستغرق هذه العملية عادةً من يوم إلى يومَي عمل.';

  @override
  String get categoryGroceries => 'البقالة';

  @override
  String get categoryDining => 'المطاعم';

  @override
  String get categoryTransport => 'المواصلات';

  @override
  String get categoryEntertainment => 'الترفيه';

  @override
  String get categoryUtilities => 'الفواتير والخدمات';

  @override
  String get categoryHealth => 'الصحة';

  @override
  String get categoryShopping => 'التسوّق';

  @override
  String get categoryTravel => 'السفر';

  @override
  String get categoryEducation => 'التعليم';

  @override
  String get categorySubscription => 'الاشتراكات';

  @override
  String get categoryTransfer => 'التحويلات';

  @override
  String get categoryIncome => 'الدخل';

  @override
  String get categoryInvestment => 'الاستثمار';

  @override
  String get categoryCredit => 'الائتمان';

  @override
  String get categoryCreditPayment => 'سداد بطاقة ائتمانية';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get categoryAdd => 'إضافة فئة';

  @override
  String get frequencyDaily => 'يوميًا';

  @override
  String get frequencyWeekly => 'أسبوعيًا';

  @override
  String get frequencyBiweekly => 'كل أسبوعين';

  @override
  String get frequencyMonthly => 'شهريًا';

  @override
  String get notifGroupSecurity => 'الأمان والاحتيال';

  @override
  String get notifGroupPayments => 'المدفوعات';

  @override
  String get notifGroupAccount => 'نشاط الحساب';

  @override
  String get notifGroupMarketing => 'التسويق';

  @override
  String get notifChannelPush => 'إشعارات الجهاز';

  @override
  String get notifChannelEmail => 'البريد الإلكتروني';

  @override
  String get notifSecurityAlerts => 'تنبيهات الأمان';

  @override
  String get notifFraudWarnings => 'تحذيرات الاحتيال';

  @override
  String get notifIdentityVerification => 'التحقق من الهوية';

  @override
  String get notifPayments => 'المدفوعات';

  @override
  String get notifTransfers => 'التحويلات';

  @override
  String get notifCardActivity => 'نشاط البطاقة';

  @override
  String get notifSavingsGoals => 'أهداف الادخار';

  @override
  String get notifPriceAlerts => 'تنبيهات الأسعار';

  @override
  String get notifServiceUpdates => 'تحديثات الخدمة';

  @override
  String get notifOffersAndNews => 'العروض والأخبار';

  @override
  String get toastSuccess => 'نجاح';

  @override
  String get toastError => 'خطأ';

  @override
  String get toastInfo => 'معلومة';

  @override
  String get toastWarning => 'تحذير';

  @override
  String get connectivityOfflineTitle => 'أنت غير متصل بالإنترنت';

  @override
  String get connectivityDegradedTitle => 'بعض الخدمات متأثرة';

  @override
  String get connectivityRestored => 'عاد الاتصال. حساباتك محدَّثة.';

  @override
  String get gateMaintenanceTitle => 'جارٍ العمل على الصيانة';

  @override
  String get gateMaintenanceBody =>
      'نُجري بعض التحديثات المهمة. سنعود في أقرب وقت ممكن.';

  @override
  String get gateOfflineTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get gateOfflineBody =>
      'يبدو أن جهازك غير متصل. تحقّق من شبكة Wi-Fi أو بيانات الجوال، ثم أعد المحاولة.';

  @override
  String get gateForceUpdateTitle => 'حان وقت التحديث';

  @override
  String get gateForceUpdateBody =>
      'التحديث ضروري للحفاظ على أمان أموالك. لم يعد هذا الإصدار من التطبيق مدعومًا.';

  @override
  String get gateDeviceBlockedTitle => 'تعذّر فتح التطبيق';

  @override
  String get gateDeviceBlockedBody =>
      'لا يمكننا فتح التطبيق على هذا الجهاز في الوقت الحالي.';

  @override
  String get gateSignInBlockedTitle => 'تعذّر تسجيل دخولك';

  @override
  String get gateSignInBlockedBody =>
      'لا يمكننا تسجيل دخولك الآن، يُرجى المحاولة لاحقًا.';

  @override
  String get gateClockSkewTitle => 'تحقّق من التاريخ والوقت';

  @override
  String get gateClockSkewBody =>
      'يبدو أن ساعة جهازك غير صحيحة، لذا تعذّر الاتصال بشكل آمن. عادةً ما تُحلّ المشكلة بإعادتها إلى الضبط التلقائي.';

  @override
  String get gateDeveloperModeTitle => 'وضع المطوّر مُفعَّل';

  @override
  String get gateDeveloperModeBody =>
      'لدواعي أمانك لا يمكن تشغيل التطبيق أثناء تفعيل وضع المطوّر. إيقافه يحلّ المشكلة.';

  @override
  String get gateQueueTitle => 'أنت في قائمة الانتظار';

  @override
  String get gateQueueBody =>
      'يسجّل عدد كبير من العملاء الدخول الآن، لذا ندخلهم تدريجيًا.';

  @override
  String get gateClockStep1 => 'افتح إعدادات جهازك';

  @override
  String get gateClockStep2 => 'انتقل إلى التاريخ والوقت';

  @override
  String get gateClockStep3 => 'فعّل الضبط التلقائي';

  @override
  String get gateClockStep4 => 'عُد إلى التطبيق';

  @override
  String get gateDeveloperStep1 => 'افتح إعدادات جهازك';

  @override
  String get gateDeveloperStep2 => 'انتقل إلى خيارات المطوّر';

  @override
  String get gateDeveloperStep3 => 'أوقف وضع المطوّر';

  @override
  String get gateDeveloperStep4 => 'عُد إلى التطبيق';

  @override
  String get gateStillWorking => 'العمل جارٍ';

  @override
  String get gateReferenceHint => 'اذكر هذا الرمز عند التواصل معنا';

  @override
  String get gateBackByAround => 'العودة تقريبًا في';

  @override
  String get gateTakingLonger => 'يستغرق الأمر وقتًا أطول قليلًا من المتوقع';

  @override
  String get gateQueueReassurance => 'سندخلك تلقائيًا. مكانك محفوظ.';

  @override
  String get gateUpdateHelp => 'احصل على مساعدة في التحديث';

  @override
  String get gateMoneyIsSafe => 'أموالك في أمان.';

  @override
  String get gateAlternativeCardPayments => 'مدفوعات البطاقة';

  @override
  String get gateAlternativeAtm => 'السحب من الصراف الآلي';

  @override
  String get gateAlternativePhone => 'الخدمات المصرفية الهاتفية';

  @override
  String get gateEtaLessThanMinute => 'أقل من دقيقة';

  @override
  String gateEtaMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: 'أقل من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get updateTitle => 'إصدار جديد جاهز';

  @override
  String get updateBody =>
      'يتضمّن هذا التحديث إصلاحات وتحسينات تُبقي التطبيق سريعًا وآمنًا.';

  @override
  String get updateNow => 'التحديث الآن';

  @override
  String get updateNotNow => 'ليس الآن';

  @override
  String updateSunset(String date) {
    return 'يتوقّف هذا الإصدار عن العمل في $date';
  }

  @override
  String updateVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'لديك $version';
  }

  @override
  String get authResendCode => 'إعادة إرسال الرمز';

  @override
  String get authUseBiometrics => 'استخدام السمات الحيوية';

  @override
  String get authDeleteDigit => 'حذف';

  @override
  String get authShowBalances => 'إظهار الأرصدة';

  @override
  String get authHideBalances => 'إخفاء الأرصدة';

  @override
  String get authSessionExpiringTitle => 'الجلسة على وشك الانتهاء';

  @override
  String get authSessionExpiringBody =>
      'ستنتهي جلستك قريبًا. هل تريد البقاء مسجّلًا للدخول؟';

  @override
  String get authStayLoggedIn => 'البقاء مسجّلًا';

  @override
  String get authLogOut => 'تسجيل الخروج';

  @override
  String get authSignOutDeviceBody =>
      'سيحتاج الجهاز إلى تسجيل الدخول مرة أخرى للوصول إلى الحساب.';

  @override
  String get scaConfirmPayment => 'تأكيد الدفع';

  @override
  String get scaRejectPayment => 'رفض الدفع';

  @override
  String get scaUsePinInstead => 'استخدام الرقم السري بدلًا من ذلك';

  @override
  String get scaUseBiometricsInstead => 'استخدام السمات الحيوية بدلًا من ذلك';

  @override
  String get scaAuthenticatorPrompt => 'وافق على هذه العملية في تطبيق المصادقة';

  @override
  String get scaExpiresIn => 'تنتهي خلال';

  @override
  String callVerifyUnverifiedWarning(String bank) {
    return 'إذا ادّعى المتصل بك الآن أنه من $bank، فأنهِ المكالمة فورًا: إنه محتال. لن يضغط عليك موظفونا أبدًا لتحويل الأموال أو مشاركة رموز الأمان.';
  }

  @override
  String get callVerifyVerifiedReassurance =>
      'تم التحقق من هذه المكالمة. لن يطلب منك موظفنا أبدًا رقمك السري أو كلمة المرور أو رمز التحقق لمرة واحدة.';

  @override
  String callVerifyIdleSummary(String bank) {
    return 'لا توجد مكالمة جارية الآن. في الأسفل ملخّص لآخر مكالمة موثَّقة مع $bank.';
  }

  @override
  String get panicUnfreezeConfirmBody =>
      'ستعود بطاقاتك ومدفوعاتك الصادرة إلى العمل.';

  @override
  String panicHoldHint(String seconds) {
    return 'اضغط مع الاستمرار لمدة $seconds ثانية لتجميد جميع البطاقات والمدفوعات الصادرة';
  }

  @override
  String get cardBack => 'ظهر البطاقة';

  @override
  String get cardFront => 'وجه البطاقة';

  @override
  String get cardShowDetails => 'إظهار تفاصيل البطاقة';

  @override
  String get cardFlip => 'قلب البطاقة';

  @override
  String get cardGenericNetwork => 'بطاقة دفع';

  @override
  String get cardIbanOrAccount => 'الآيبان / رقم الحساب';

  @override
  String get cardSortCodeOrBic => 'رمز الفرز / رمز السويفت';

  @override
  String get cardTapToCopyHint => 'انقر على القيم لنسخها';

  @override
  String cardBlockDelayNotice(String label, String hours) {
    return 'لحمايتك، هذا التغيير مؤجَّل. تبقى مدفوعات $label محظورة لمدة $hours ساعة إضافية بعد التأكيد.';
  }

  @override
  String get validationIban => 'أدخل رقم آيبان صحيحًا.';

  @override
  String get validationCardNumber => 'أدخل رقم بطاقة صحيحًا.';

  @override
  String get validationSortCode => 'أدخل رمز فرز صحيحًا.';

  @override
  String get validationGeneric => 'أدخل قيمة صحيحة.';

  @override
  String get periodPreviousMonth => 'الشهر السابق';

  @override
  String get periodPreviousQuarter => 'الربع السابق';

  @override
  String get periodPreviousYear => 'السنة السابقة';

  @override
  String get periodNextMonth => 'الشهر التالي';

  @override
  String get periodNextQuarter => 'الربع التالي';

  @override
  String get periodNextYear => 'السنة التالية';

  @override
  String get periodAll => 'الكل';

  @override
  String get sheetDragHandle => 'مقبض السحب';

  @override
  String get creditLimit => 'الحد الائتماني';

  @override
  String get creditScorePoor => 'ضعيف';

  @override
  String get creditScoreFair => 'مقبول';

  @override
  String get creditScoreGood => 'جيد';

  @override
  String get creditScoreVeryGood => 'جيد جدًا';

  @override
  String get creditScoreExcellent => 'ممتاز';

  @override
  String get creditFlexEligible => 'مؤهّلة للتقسيط';

  @override
  String get insightConfidenceHigh => 'ثقة عالية';

  @override
  String get insightConfidenceMedium => 'ثقة متوسطة';

  @override
  String get insightConfidenceLow => 'ثقة منخفضة';

  @override
  String get merchantBlockNotice => 'سيتم رفض أي رسوم مستقبلية من هذا التاجر.';

  @override
  String get captureFrameDocument => 'ضع المستند داخل الإطار';

  @override
  String get captureKeepInFrame => 'أبقِ المستند داخل الإطار';

  @override
  String get captureHoldStill => 'ثبّت الجهاز…';

  @override
  String get captureMoveFurther => 'ابتعد قليلًا';

  @override
  String get captureMoveCloser => 'اقترب قليلًا';

  @override
  String get captureImproveLighting => 'حسّن الإضاءة';

  @override
  String get captureHoldSteady => 'ثبّت الكاميرا';

  @override
  String get captureTakePhoto => 'تصوير المستند';

  @override
  String get livenessPositionFace => 'ضع وجهك داخل الإطار البيضاوي';

  @override
  String get livenessLookStraight => 'انظر مباشرة إلى الكاميرا';

  @override
  String get livenessVerified => 'تم التحقق من هويتك';

  @override
  String get livenessFailed => 'تعذّر التحقق: يُرجى المحاولة مرة أخرى';

  @override
  String get consentEmptyBody =>
      'تظهر هنا التطبيقات التي تسمح لها بالوصول إلى بيانات حسابك.';

  @override
  String get standingOrderSkipBody =>
      'سيتم تخطّي الدفعة المجدولة التالية. تبقى الدفعات اللاحقة على موعدها.';

  @override
  String get standingOrderCancelBody =>
      'يوقف هذا نهائيًا جميع الدفعات المستقبلية لهذا المستفيد.';

  @override
  String get disclosureReviewAndAgree => 'الاطّلاع والموافقة';

  @override
  String get disclosureAgreeAndContinue => 'أوافق وأتابع';

  @override
  String get offerEndsToday => 'ينتهي اليوم';

  @override
  String offerDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يتبقّى $count يوم',
      many: 'يتبقّى $count يومًا',
      few: 'يتبقّى $count أيام',
      two: 'يتبقّى يومان',
      one: 'يتبقّى يوم واحد',
      zero: 'ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get offerExpired => 'انتهى العرض';

  @override
  String potMaxContribution(String amount) {
    return 'أقصى مبلغ يمكن إضافته هو $amount للوصول إلى هدفك';
  }

  @override
  String roundUpExplainer(String unit) {
    return 'سنقرّب كل عملية شراء إلى أقرب $unit ونوفّر الفرق تلقائيًا.';
  }

  @override
  String roundUpExplainerMultiplied(String unit, String multiplier) {
    return 'سنقرّب كل عملية شراء إلى أقرب $unit ونوفّر الفرق $multiplier تلقائيًا.';
  }

  @override
  String get ownershipPrimary => 'أساسي';

  @override
  String get ownershipJoint => 'مشترك';

  @override
  String get ownershipBeneficiary => 'مستفيد';

  @override
  String paywallUpgradeTo(String feature) {
    return 'قم بالترقية للوصول إلى $feature';
  }

  @override
  String get paywallMaybeLater => 'ربما لاحقًا';

  @override
  String get paywallUpgrade => 'ترقية';

  @override
  String get paywallCurrentPlan => 'الباقة الحالية';

  @override
  String get paywallDismiss => 'إغلاق عرض الترقية';

  @override
  String get perkActivated => 'تم تفعيل الميزة';

  @override
  String get perkActivatedSpoken => 'مُفعَّلة.';

  @override
  String get perkNotActivatedSpoken => 'غير مُفعَّلة.';

  @override
  String get referralShareCode => 'مشاركة رمز الدعوة';

  @override
  String get disputeUnauthorized => 'لم أُصرّح بهذه العملية';

  @override
  String get disputeDuplicate => 'تم خصم المبلغ مرتين';

  @override
  String get disputeWrongAmount => 'المبلغ غير صحيح';

  @override
  String get disputeNotReceived => 'لم أستلم السلعة أو الخدمة';

  @override
  String get disputeCancelledSubscription => 'ألغيت هذا الاشتراك';

  @override
  String get disputeOther => 'سبب آخر';

  @override
  String get disputeStageSubmitted => 'تم التقديم';

  @override
  String get disputeStageUnderReview => 'قيد المراجعة';

  @override
  String get disputeStageResolved => 'تمت التسوية';

  @override
  String a11yAccountSummary(String name, String number, String balance) {
    return 'الحساب: $name، $number، $balance';
  }

  @override
  String a11ySelectedSuffix(String label) {
    return '$label، محدَّد';
  }

  @override
  String a11yBalanceIs(String amount) {
    return 'الرصيد: $amount';
  }

  @override
  String a11yBudgetSummary(String name, String spent, String limit) {
    return 'ميزانية $name: $spent من $limit';
  }

  @override
  String a11yBudgetOverspent(String summary) {
    return '$summary، تجاوزت الميزانية';
  }

  @override
  String a11yBalanceRange(String low, String high) {
    return 'تراوح الرصيد بين $low و$high';
  }

  @override
  String a11yBalanceRangeProjected(String summary, String projection) {
    return '$summary، والمتوقَّع $projection';
  }

  @override
  String a11yBillForecast(String biller, String amount) {
    return '$biller، $amount';
  }

  @override
  String a11yBillForecastEstimated(String summary) {
    return '$summary، تقديري';
  }

  @override
  String gateQueuePosition(String position) {
    return 'رقمك في الطابور $position';
  }

  @override
  String gateQueuePositionWithEta(String position, String wait) {
    return '$position، خلال $wait تقريبًا';
  }

  @override
  String get actionTryAgain => 'إعادة المحاولة';

  @override
  String connectivityRetryingIn(String seconds) {
    return 'إعادة المحاولة خلال $seconds ثانية';
  }

  @override
  String get notifChannelSms => 'رسالة نصية';

  @override
  String a11yCreditLimit(
      String label, String used, String limit, String available) {
    return '$label: $used مستخدَم من $limit، و$available متاح';
  }

  @override
  String get labelAvailableLower => 'متاح';

  @override
  String referralFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت دعوة $count صديق',
      many: 'تمت دعوة $count صديقًا',
      few: 'تمت دعوة $count أصدقاء',
      two: 'تمت دعوة صديقين',
      one: 'تمت دعوة صديق واحد',
      zero: 'لم يدعُ أحد بعد',
    );
    return '$_temp0';
  }

  @override
  String referralProgress(String invited, String max) {
    return '$invited من $max';
  }

  @override
  String callVerifyActiveHeadline(String bank) {
    return 'أنت تتحدث مع $bank';
  }

  @override
  String get labelLimit => 'الحد';

  @override
  String get actionGoBack => 'رجوع';

  @override
  String get actionMoreActions => 'إجراءات أخرى';

  @override
  String get standingOrderSkipTitle => 'تخطّي الدفعة التالية؟';

  @override
  String get standingOrderCancelTitle => 'إلغاء الأمر المستديم؟';

  @override
  String get standingOrderSkipAction => 'تخطّي الدفعة التالية';

  @override
  String get standingOrderCancelAction => 'إلغاء الأمر المستديم';

  @override
  String get standingOrderPause => 'إيقاف مؤقت';

  @override
  String get standingOrderResume => 'استئناف';

  @override
  String get standingOrderPaused => 'موقوف مؤقتًا';

  @override
  String get standingOrderFailed => 'فشلت';

  @override
  String get standingOrderRetry => 'إعادة محاولة الدفع';

  @override
  String get merchantNextPrefix => 'التالية';

  @override
  String get merchantPriceRise => 'ارتفاع السعر';

  @override
  String get merchantHowToCancel => 'كيفية الإلغاء';

  @override
  String get merchantBlockAction => 'حظر المدفوعات المستقبلية';

  @override
  String get merchantBlockTitle => 'حظر هذا التاجر؟';

  @override
  String get consentRevoke => 'إلغاء الوصول';

  @override
  String get consentRevokeTitle => 'إلغاء الوصول؟';

  @override
  String get consentRevokeBody => 'يفقد هذا التطبيق الوصول إلى بياناتك فورًا.';

  @override
  String get consentGrantedPrefix => 'مُنح في';

  @override
  String get consentExpiresPrefix => 'ينتهي في';

  @override
  String get consentRevoked => 'مُلغى';

  @override
  String get consentExpired => 'منتهٍ';

  @override
  String get consentExpiringSoon => 'ينتهي قريبًا';
}
