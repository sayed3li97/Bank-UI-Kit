import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/saving.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] with the kit's localisation delegates installed and the
/// ambient locale set to [locale].
Future<void> _pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  BankUiStrings? strings,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    BankUiScope(
      initialData: BankUiScopeData(
        strings: strings ?? BankUiStrings.defaults,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: BankL10n.localizationsDelegates,
        supportedLocales: BankL10n.supportedLocales,
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps [child] with **no** localisation delegate at all, the way a host app
/// that has never heard of `BankL10n` renders the kit.
Future<void> _pumpBare(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    BankUiScope(
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SavingsPot _pot(String currencyCode) => SavingsPot(
      id: 'pot',
      name: 'Rainy day',
      target: Money(amount: Decimal.fromInt(100), currencyCode: currencyCode),
      current: Money(amount: Decimal.fromInt(10), currencyCode: currencyCode),
      hasOwnAccountNumber: false,
      memberIds: const [],
      isRoundUpDestination: true,
    );

Widget _roundUp(String currencyCode, {int multiplier = 1}) =>
    BankRoundUpSettingsSheet(
      isEnabled: true,
      multiplier: multiplier,
      availablePots: [_pot(currencyCode)],
      selectedPotId: 'pot',
      onEnabledChanged: (_) {},
      onMultiplierChanged: (_) {},
      onPotSelected: (_) {},
    );

/// Reads the resolved catalogue out of a live element tree.
class _Probe extends StatelessWidget {
  const _Probe(this.onStrings);

  final void Function(BankStrings strings) onStrings;

  @override
  Widget build(BuildContext context) {
    onStrings(BankStrings.of(context));
    return const SizedBox.shrink();
  }
}

Future<BankStrings> _stringsFor(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  BankUiStrings? strings,
}) async {
  late BankStrings captured;
  await _pumpLocalized(
    tester,
    _Probe((s) => captured = s),
    locale: locale,
    strings: strings,
  );
  return captured;
}

void _noop() {}

Money _gbp(int amount) =>
    Money(amount: Decimal.fromInt(amount), currencyCode: 'GBP');

Widget _gauge() => BankCreditLimitGauge(
      creditLimit: _gbp(1000),
      usedAmount: _gbp(400),
    );

/// The credit-gauge screen-reader sentence exactly as the concatenation
/// that preceded [BankStrings.a11yCreditLimit] built it.
String _gaugeSentenceEn() {
  String money(int amount) => BankMoneyFormatter.format(
        amount: Decimal.fromInt(amount),
        currencyCode: 'GBP',
      );
  return 'Credit limit: ${money(400)} used of ${money(1000)}, '
      '${money(600)} available';
}

/// Reads the one [Semantics] label that carries the gauge summary.
String _summaryLabel(WidgetTester tester, String needle) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((s) => s.properties.label)
    .whereType<String>()
    .firstWhere((label) => label.contains(needle));

Widget _referral(int count, {int? max}) => BankReferralInviteCard(
      referralCode: 'ABC123',
      referralCount: count,
      maxReferrals: max,
    );

Widget _standingOrder() => BankStandingOrderTile(
      order: BankStandingOrder(
        id: 'so-1',
        payeeName: 'Acme Lettings',
        amount: _gbp(1250),
        pattern: BankRecurringPattern.monthly,
        nextRunDate: DateTime(2026, 7, 15),
      ),
      onPause: _noop,
      onSkipNext: _noop,
      onCancel: _noop,
    );

Widget _merchantTile() => BankRecurringMerchantTile(
      merchant: BankRecurringMerchant(
        id: 'm-1',
        merchantName: 'Streamly',
        amount: _gbp(12),
        cadence: BankRecurringPattern.monthly,
        nextExpectedDate: DateTime(2026, 7, 15),
        firstSeen: DateTime(2026, 1, 20),
        category: TransactionCategory.subscription,
        previousAmount: _gbp(10),
        priceIncreased: true,
      ),
      onCancelHelp: _noop,
      onBlock: _noop,
    );

Widget _consentList() => BankConsentManagementList(
      consents: [
        BankConsent(
          id: 'c-1',
          granteeName: 'Budgeting App X',
          scopes: const ['Account balances'],
          grantedAt: DateTime(2026, 1, 5),
          state: BankConsentState.active,
          expiresAt: DateTime(2026, 7, 5),
        ),
      ],
      onRevoke: (_) async => true,
    );

void main() {
  group('resolution order', () {
    testWidgets('no delegate installed still renders English', (tester) async {
      late BankStrings strings;
      await _pumpBare(tester, _Probe((s) => strings = s));

      expect(strings.actionConfirm, 'Confirm');
      expect(strings.gateOfflineTitle, 'No internet connection');
      expect(strings.installmentMonths(3), '3 months');
    });

    testWidgets('the delegate supplies the ambient language', (tester) async {
      final ar = await _stringsFor(tester, locale: const Locale('ar'));

      expect(ar.actionConfirm, 'تأكيد');
      expect(ar.gateOfflineTitle, 'لا يوجد اتصال بالإنترنت');
    });

    testWidgets('a host override outranks the translation', (tester) async {
      final ar = await _stringsFor(
        tester,
        locale: const Locale('ar'),
        strings: const BankUiStrings(interestRate: 'Profit rate'),
      );

      // The bank insisted on this wording, so it survives into Arabic…
      expect(ar.interestRate, 'Profit rate');
      // …while everything it did not touch is still translated.
      expect(ar.actionConfirm, 'تأكيد');
    });

    testWidgets('a value equal to the default is not an override',
        (tester) async {
      final ar = await _stringsFor(
        tester,
        locale: const Locale('ar'),
        // 'Interest rate' is exactly the shipped default, so this is
        // indistinguishable from passing nothing. The lints below are the
        // analyzer noticing the same thing, which is the point of the case:
        // spelling the default out explicitly must not defeat translation.
        // ignore: use_named_constants, avoid_redundant_argument_values
        strings: const BankUiStrings(interestRate: 'Interest rate'),
      );

      expect(ar.interestRate, 'معدّل الفائدة');
    });

    test('override() separates a choice from a default', () {
      expect(BankStrings.override('Retry', 'Retry'), isNull);
      expect(BankStrings.override('Try again', 'Retry'), 'Try again');
    });
  });

  group('plurals', () {
    testWidgets('English has two forms', (tester) async {
      final en = await _stringsFor(tester);

      expect(en.installmentMonths(1), '1 month');
      expect(en.installmentMonths(3), '3 months');
      expect(en.offerDaysLeft(1), '1 day left');
      expect(en.offerDaysLeft(4), '4 days left');
    });

    testWidgets('Arabic exercises all six CLDR categories', (tester) async {
      final ar = await _stringsFor(tester, locale: const Locale('ar'));

      // zero, one, two, few (3–10), many (11–99), other (100+).
      expect(ar.installmentMonths(0), 'بدون أشهر');
      expect(ar.installmentMonths(1), 'شهر واحد');
      expect(ar.installmentMonths(2), 'شهران');
      expect(ar.installmentMonths(3), '3 أشهر');
      expect(ar.installmentMonths(11), '11 شهرًا');
      expect(ar.installmentMonths(100), '100 شهر');
    });

    testWidgets('a {n} template override still substitutes', (tester) async {
      final ar = await _stringsFor(
        tester,
        locale: const Locale('ar'),
        strings: const BankUiStrings(installmentMonths: 'over {n} months'),
      );

      // A `{n}` template cannot express six categories, which is why the
      // catalogue exists — but an override still has to work.
      expect(ar.installmentMonths(2), 'over 2 months');
    });
  });

  group('whole-sentence semantics', () {
    testWidgets('the selected suffix is one translatable message',
        (tester) async {
      final en = await _stringsFor(tester);
      final ar = await _stringsFor(tester, locale: const Locale('ar'));

      expect(
        en.a11ySelectedSuffix('Everyday, ••1234'),
        'Everyday, ••1234, selected',
      );
      // Arabic puts its own comma in, which a concatenated ', selected'
      // could never have done.
      expect(ar.a11ySelectedSuffix('س'), contains('،'));
    });

    testWidgets('an account summary keeps its three parts', (tester) async {
      final en = await _stringsFor(tester);

      expect(
        en.a11yAccountSummary('Everyday', '••1234', 'Balance: £12.00'),
        'Account: Everyday, ••1234, Balance: £12.00',
      );
    });
  });

  group('round-up copy is currency-relative', () {
    testWidgets('a sterling pot reproduces the shipped English exactly',
        (tester) async {
      await _pumpLocalized(tester, _roundUp('GBP'));

      expect(
        find.text("We'll round up every purchase to the nearest £1 and save "
            'the difference automatically.'),
        findsOneWidget,
      );
    });

    testWidgets('the multiplier keeps its original spacing', (tester) async {
      await _pumpLocalized(tester, _roundUp('GBP', multiplier: 2));

      expect(
        find.text("We'll round up every purchase to the nearest £1 and save "
            'the difference × 2 automatically.'),
        findsOneWidget,
      );
    });

    testWidgets('a riyal pot rounds to a riyal, not a pound', (tester) async {
      await _pumpLocalized(tester, _roundUp('SAR'));

      final text = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').contains('round up every'),
        ),
      );
      expect(text.data, isNot(contains('£')));
      expect(text.data, contains('ر.س'));
    });
  });

  group('dates', () {
    test('an uninitialised locale degrades instead of throwing', () {
      // `DateFormat('d MMMM y', 'de')` throws LocaleDataException unless the
      // host called initializeDateFormatting. A wrong-language month name is
      // a cosmetic defect; an exception while painting a balance is an
      // outage.
      expect(
        () => BankDateFormatter.formatDateOnly(
          DateTime(2026, 6, 30),
          locale: 'de',
        ),
        returnsNormally,
      );
      // Whether it lands on German or falls back to English depends on what
      // else in the process has loaded date symbols, and either is fine. Not
      // throwing is the contract.
      expect(
        BankDateFormatter.formatDateOnly(DateTime(2026, 6, 30), locale: 'de'),
        contains('2026'),
      );
    });

    testWidgets('relative time follows the catalogue', (tester) async {
      final now = DateTime(2026, 6, 30, 12);
      final en = await _stringsFor(tester);
      final ar = await _stringsFor(tester, locale: const Locale('ar'));

      expect(
        en.relativeTime(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
      expect(
        en.relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        ar.relativeTime(now.subtract(const Duration(seconds: 20)), now: now),
        'الآن',
      );
      expect(
        ar.relativeTime(now.subtract(const Duration(hours: 3)), now: now),
        contains('3'),
      );
    });
  });

  group('catalogue reaches real widgets', () {
    testWidgets('the blocking gate speaks Arabic', (tester) async {
      await _pumpLocalized(
        tester,
        const BankAppGateScreen.offline(),
        locale: const Locale('ar'),
      );

      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('the same gate is unchanged in English', (tester) async {
      await _pumpLocalized(tester, const BankAppGateScreen.offline());

      expect(find.text('No internet connection'), findsOneWidget);
      expect(
        find.text('Your device seems to be offline. Check your Wi-Fi or '
            'mobile data, then try again.'),
        findsOneWidget,
      );
    });
  });

  group('English defaults on public parameters', () {
    testWidgets('an untouched default renders the shipped English',
        (tester) async {
      await _pumpLocalized(
        tester,
        const BankErrorStateView(
          title: 'Something went wrong',
          message: 'We could not load your accounts.',
          onRetry: _noop,
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('the same default translates without changing its type',
        (tester) async {
      await _pumpLocalized(
        tester,
        const BankErrorStateView(
          title: 'Something went wrong',
          message: 'We could not load your accounts.',
          onRetry: _noop,
        ),
        locale: const Locale('ar'),
      );

      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a host that changed the default keeps its own wording',
        (tester) async {
      await _pumpLocalized(
        tester,
        const BankErrorStateView(
          title: 'Something went wrong',
          message: 'We could not load your accounts.',
          retryLabel: 'Try once more',
          onRetry: _noop,
        ),
        locale: const Locale('ar'),
      );

      // An explicit choice outranks the translation, exactly as a
      // `BankUiStrings` override does.
      expect(find.text('Try once more'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsNothing);
    });

    testWidgets('the credit gauge composes the sentence it used to join',
        (tester) async {
      await _pumpLocalized(tester, _gauge());

      expect(_summaryLabel(tester, 'used of'), _gaugeSentenceEn());
      expect(find.text('available'), findsOneWidget);
    });

    testWidgets('and puts the Arabic sentence together its own way',
        (tester) async {
      await _pumpLocalized(tester, _gauge(), locale: const Locale('ar'));

      final label = _summaryLabel(tester, 'الحد الائتماني');
      expect(label, contains('مستخدَم'));
      expect(label, isNot(contains('used of')));
      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('available'), findsNothing);
    });

    testWidgets('the gauge legend keeps all three English captions',
        (tester) async {
      await _pumpLocalized(tester, _gauge());

      expect(find.text('Used'), findsOneWidget);
      expect(find.text('Limit'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);
    });

    testWidgets('and translates the whole legend, not one third of it',
        (tester) async {
      // The defect this closes: `availableLabel` had a key and the two
      // legend captions beside it did not, so an Arabic device rendered
      // "متاح" under the arc with "Used" and "Limit" in English
      // underneath it. Assert all three together or the next migration
      // can silently re-open the gap.
      await _pumpLocalized(tester, _gauge(), locale: const Locale('ar'));

      expect(find.text('المستخدم'), findsOneWidget);
      expect(find.text('الحد'), findsOneWidget);
      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('Used'), findsNothing);
      expect(find.text('Limit'), findsNothing);
      expect(find.text('available'), findsNothing);
    });

    testWidgets('a host that renamed one caption keeps only that one',
        (tester) async {
      await _pumpLocalized(
        tester,
        BankCreditLimitGauge(
          creditLimit: _gbp(1000),
          usedAmount: _gbp(400),
          usedLabel: 'Spent',
        ),
        locale: const Locale('ar'),
      );

      // An explicit choice outranks the translation for that caption, and
      // leaves the two the host did not touch translated.
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('المستخدم'), findsNothing);
      expect(find.text('الحد'), findsOneWidget);
      expect(find.text('متاح'), findsOneWidget);
    });

    testWidgets('the referral count keeps its English singular and plural',
        (tester) async {
      await _pumpLocalized(tester, _referral(1));
      expect(find.text('1 friend invited'), findsOneWidget);

      await _pumpLocalized(tester, _referral(3));
      expect(find.text('3 friends invited'), findsOneWidget);

      await _pumpLocalized(tester, _referral(3, max: 5));
      expect(find.text('3 friends invited of 5'), findsOneWidget);
    });

    testWidgets('and becomes a real plural in Arabic', (tester) async {
      await _pumpLocalized(tester, _referral(3), locale: const Locale('ar'));

      // 'few' — a category a hand-built friend/friends pair cannot reach.
      expect(find.text('تمت دعوة 3 أصدقاء'), findsOneWidget);
    });
  });

  // A cluster is every string one surface paints. Migrating a cluster one
  // parameter at a time is what produced the half-translated gauge these
  // cases exist to keep closed: assert the whole surface, never one label.
  group('a copy cluster resolves as a whole', () {
    testWidgets('the standing-order sheet keeps its English intact',
        (tester) async {
      await _pumpLocalized(tester, _standingOrder());

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Skip next payment'), findsOneWidget);
      expect(find.text('Cancel standing order'), findsOneWidget);

      await tester.tap(find.text('Skip next payment'));
      await tester.pumpAndSettle();
      expect(find.text('Skip next payment?'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('and translates the sheet and the dialog behind it together',
        (tester) async {
      await _pumpLocalized(
        tester,
        _standingOrder(),
        locale: const Locale('ar'),
      );

      await tester.tap(find.byTooltip('إجراءات أخرى'));
      await tester.pumpAndSettle();
      expect(find.text('إيقاف مؤقت'), findsOneWidget);
      expect(find.text('تخطّي الدفعة التالية'), findsOneWidget);
      expect(find.text('إلغاء الأمر المستديم'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Skip next payment'), findsNothing);
      expect(find.text('Cancel standing order'), findsNothing);

      await tester.tap(find.text('تخطّي الدفعة التالية'));
      await tester.pumpAndSettle();
      // The dialog is the half that used to stay English: its title and
      // both buttons had no key when its body got one.
      expect(find.text('تخطّي الدفعة التالية؟'), findsOneWidget);
      expect(find.text('رجوع'), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('Go back'), findsNothing);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('the paused chip reads the same language as the row',
        (tester) async {
      await _pumpLocalized(
        tester,
        BankStandingOrderTile(
          order: BankStandingOrder(
            id: 'so-2',
            payeeName: 'Acme Lettings',
            amount: _gbp(1250),
            pattern: BankRecurringPattern.monthly,
            nextRunDate: DateTime(2026, 7, 15),
            state: BankStandingOrderState.paused,
          ),
        ),
        locale: const Locale('ar'),
      );

      expect(find.text('موقوف مؤقتًا'), findsOneWidget);
      expect(find.text('Paused'), findsNothing);
    });

    testWidgets('the recurring-merchant row translates chip, line and sheet',
        (tester) async {
      await _pumpLocalized(tester, _merchantTile(), locale: const Locale('ar'));

      expect(find.text('ارتفاع السعر'), findsOneWidget);
      expect(find.text('Price rise'), findsNothing);
      expect(find.textContaining('التالية'), findsOneWidget);
      expect(find.textContaining('next'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('كيفية الإلغاء'), findsOneWidget);
      expect(find.text('حظر المدفوعات المستقبلية'), findsOneWidget);
      expect(find.text('How to cancel'), findsNothing);

      await tester.tap(find.text('حظر المدفوعات المستقبلية'));
      await tester.pumpAndSettle();
      expect(find.text('حظر هذا التاجر؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('Block this merchant?'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('the merchant row keeps its English when nothing is set',
        (tester) async {
      await _pumpLocalized(tester, _merchantTile());

      expect(find.text('Price rise'), findsOneWidget);
      expect(find.textContaining('next'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('How to cancel'), findsOneWidget);
      expect(find.text('Block future payments'), findsOneWidget);

      await tester.tap(find.text('Block future payments'));
      await tester.pumpAndSettle();
      expect(find.text('Block this merchant?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('the consent card translates chip, dates and revoke together',
        (tester) async {
      await _pumpLocalized(tester, _consentList(), locale: const Locale('ar'));

      expect(find.text('نشطة'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
      expect(find.textContaining('مُنح في'), findsOneWidget);
      expect(find.textContaining('ينتهي في'), findsOneWidget);
      expect(find.textContaining('Granted'), findsNothing);
      expect(find.text('إلغاء الوصول'), findsOneWidget);

      await tester.tap(find.text('إلغاء الوصول'));
      await tester.pumpAndSettle();
      expect(find.text('إلغاء الوصول؟'), findsOneWidget);
      expect(
        find.text('يفقد هذا التطبيق الوصول إلى بياناتك فورًا.'),
        findsOneWidget,
      );
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('Revoke access?'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('and leaves every one of those English by default',
        (tester) async {
      await _pumpLocalized(tester, _consentList());

      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('Granted'), findsOneWidget);
      expect(find.textContaining('expires'), findsOneWidget);
      expect(find.text('Revoke access'), findsOneWidget);

      await tester.tap(find.text('Revoke access'));
      await tester.pumpAndSettle();
      expect(find.text('Revoke access?'), findsOneWidget);
      expect(
        find.text('This app immediately loses access to your data.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('a locale with no catalogue', () {
    testWidgets('falls back to English rather than failing to load',
        (tester) async {
      // A host with ten supported locales installs `BankL10n.delegate`
      // alongside its own. German has no catalogue here, and the contract is
      // that kit copy quietly reads English rather than throwing or showing
      // a key.
      // Flutter reports its own warning whenever any installed delegate
      // lacks the resolved locale. It is advisory, it is not ours, and in a
      // test it would otherwise fail the case it is describing.
      final warnings = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('is not supported by all of its localization')) {
          warnings.add(text);
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      late BankStrings strings;
      await tester.pumpWidget(
        BankUiScope(
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: const [
              BankL10n.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de'), Locale('en')],
            home: _Probe((s) => strings = s),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(strings.actionConfirm, 'Confirm');
      expect(strings.installmentMonths(2), '2 months');
      expect(warnings, hasLength(1));
    });
  });
}
