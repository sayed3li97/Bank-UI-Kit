import 'dart:math' as math;

import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/social.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a themed [BankUiScope] so widgets that read
/// [BankThemeData.of] / [BankUiScope.of] can be pumped in isolation.
Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return BankUiScope(
    child: MaterialApp(
      theme: BankPreset.studio.apply(base),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// [_host] with [child] rendered under an explicit ambient [direction], so a
/// money atom can be pumped in LTR and RTL copy alike.
Widget _directionalHost(Widget child, TextDirection direction) => _host(
      Directionality(textDirection: direction, child: child),
    );

/// [_host] with the subtree's locale overridden to [locale], reusing the
/// app's own delegates so the widget sees a foreign locale without needing
/// localizations published for it.
Widget _localeHost(Widget child, Locale locale) => _host(
      Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: child,
        ),
      ),
    );

Transaction _txn({
  required double amount,
  TransactionStatus status = TransactionStatus.cleared,
}) =>
    Transaction(
      id: 't-$amount',
      amount: Money.fromDouble(amount, 'GBP'),
      settledAt: DateTime(2026, 7, 18, 14, 32),
      status: status,
      merchantName: 'Pret A Manger',
      category: TransactionCategory.dining,
    );

/// The color of the first [Text] whose data matches [matcher].
Color? _textColor(WidgetTester tester, Pattern matcher) {
  final text = tester.widgetList<Text>(find.byType(Text)).firstWhere(
        (t) => t.data != null && t.data!.contains(matcher),
      );
  return text.style?.color;
}

void main() {
  group('BankPreapprovedLoanCard rate unit (rank 17)', () {
    test('assert fires on percent-style input like 8.9', () {
      expect(
        () => BankPreapprovedLoanCard(
          maxAmount: Money.fromDouble(10000, 'GBP'),
          annualRate: 8.9,
          maxMonths: 12,
          onContinue: (_) {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('formattedApr renders the fraction as display percent', () {
      final card = BankPreapprovedLoanCard(
        maxAmount: Money.fromDouble(10000, 'GBP'),
        annualRate: 0.089,
        maxMonths: 12,
        onContinue: (_) {},
      );
      expect(card.formattedApr, '8.9%');
      expect(BankPreapprovedLoanCard.formatAnnualRate(0.0499), '4.99%');
      expect(BankPreapprovedLoanCard.formatAnnualRate(0.05), '5%');
      expect(BankPreapprovedLoanCard.formatAnnualRate(0), '0%');
      expect(
        BankPreapprovedLoanCard.formatAnnualRate(
          0.089,
          numeralStyle: NumeralStyle.easternArabicIndic,
        ),
        isNot(contains('8')),
      );
    });

    testWidgets('card renders the fraction rate and sane amortization',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankPreapprovedLoanCard(
            maxAmount: Money.fromDouble(10000, 'GBP'),
            annualRate: 0.089,
            maxMonths: 12,
            onContinue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The microline shows the fraction as 8.9% — never 890.00%.
      expect(find.textContaining('8.9%'), findsOneWidget);
      expect(find.textContaining('890'), findsNothing);

      // Monthly estimate matches standard amortization for the fraction:
      // P * r / (1 - (1+r)^-n) with r = 0.089 / 12.
      const r = 0.089 / 12;
      final expectedMonthly = 10000 * r / (1 - math.pow(1 + r, -12));
      final expectedText = BankMoneyFormatter.format(
        amount: Money.fromDouble(expectedMonthly, 'GBP').amount,
        currencyCode: 'GBP',
      );
      expect(find.textContaining(expectedText), findsOneWidget);
    });
  });

  group('BankProductCard rate composition (rank 40)', () {
    testWidgets('prefixLabel renders before the value, label after',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          BankProductCard(
            title: 'Personal Loan',
            rate: const BankProductRate(
              prefixLabel: 'From',
              value: '5.9%',
              label: 'APR',
              caption: 'Representative',
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('From'), findsOneWidget);
      expect(find.text('5.9%'), findsOneWidget);
      expect(find.text('APR'), findsOneWidget);
      // The card announces the rate in reading order — 'From 5.9% APR' —
      // never the backwards '5.9% from APR'.
      expect(
        find.bySemanticsLabel(RegExp(r'From 5\.9% APR, Representative')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('rate without prefixLabel keeps the legacy layout',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankProductCard(
            title: 'Easy Saver',
            rate: const BankProductRate(value: '4.2%', label: 'AER'),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('4.2%'), findsOneWidget);
      expect(find.text('AER'), findsOneWidget);
    });
  });

  group('Transaction row money semantics (rank 29)', () {
    testWidgets('credit renders with explicit + in positiveBalance',
        (tester) async {
      await tester.pumpWidget(
        _host(BankTransactionListTile(transaction: _txn(amount: 250))),
      );
      final theme = BankThemeData.of(
        tester.element(find.byType(BankTransactionListTile)),
      );
      expect(find.textContaining('+£250.00'), findsOneWidget);
      expect(_textColor(tester, '+£250.00'), theme.positiveBalance);
    });

    testWidgets('debit stays neutral onSurface — no red-everything',
        (tester) async {
      await tester.pumpWidget(
        _host(BankTransactionListTile(transaction: _txn(amount: -4.85))),
      );
      final theme = BankThemeData.of(
        tester.element(find.byType(BankTransactionListTile)),
      );
      expect(find.textContaining('-£4.85'), findsOneWidget);
      final color = _textColor(tester, '-£4.85');
      expect(color, theme.onSurface);
      expect(color, isNot(theme.negativeBalance));
    });

    testWidgets('secondary line shows category and time', (tester) async {
      await tester.pumpWidget(
        _host(BankTransactionListTile(transaction: _txn(amount: -4.85))),
      );
      expect(find.textContaining('Dining'), findsOneWidget);
      expect(find.textContaining('14:32'), findsOneWidget);
    });

    testWidgets('showCategoryAndTime: false restores the status-only line',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankTransactionListTile(
            transaction: _txn(amount: -4.85),
            showCategoryAndTime: false,
          ),
        ),
      );
      expect(find.textContaining('Dining'), findsNothing);
    });

    testWidgets('joint tile matches the same credit/debit semantics',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              BankJointTransactionListTile(
                transaction: _txn(amount: 120),
                initiatorName: 'Dana',
              ),
              BankJointTransactionListTile(
                transaction: _txn(amount: -60),
                initiatorName: 'Sam',
              ),
            ],
          ),
        ),
      );
      final theme = BankThemeData.of(
        tester.element(find.byType(BankJointTransactionListTile).first),
      );
      expect(find.textContaining('+£120.00'), findsOneWidget);
      expect(_textColor(tester, '+£120.00'), theme.positiveBalance);
      expect(_textColor(tester, '-£60.00'), theme.onSurface);
    });

    testWidgets('tappable row fires onTap through BankPressable',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          BankTransactionListTile(
            transaction: _txn(amount: -4.85),
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(BankTransactionListTile));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('BankTransactionGroupHeader (rank 59 rider)', () {
    testWidgets('renders tracked caps with no band and a trimmed day total',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankTransactionGroupHeader(
            date: DateTime(2026, 3, 14),
            dayTotal: Money.fromDouble(-120, 'GBP'),
          ),
        ),
      );
      expect(find.text('14 MARCH 2026'), findsOneWidget);
      // Whole day totals drop the zero minor units.
      expect(find.text('-£120'), findsOneWidget);
      expect(find.textContaining('.00'), findsNothing);
    });

    testWidgets('day total is optional (legacy call sites unchanged)',
        (tester) async {
      await tester.pumpWidget(
        _host(BankTransactionGroupHeader(date: DateTime(2026, 3, 14))),
      );
      expect(find.text('14 MARCH 2026'), findsOneWidget);
    });
  });

  group('a Gulf money atom renders the same in either direction', () {
    // Marker, no-break space, digits. The defect this pins packed the
    // gap inside the marker's isolate, where it resolves right-to-left with
    // the marker and reorders to its far side: a leading space, and the
    // Arabic marker painted flush against the first brand-font digit.
    const bhd = '\u2068د.ب\u2069\u00A01,234.567';
    const gapInsideIsolate = '\u2068د.ب\u00A0\u20691,234.567';

    String format() => BankMoneyFormatter.format(
          amount: Decimal.parse('1234.567'),
          currencyCode: 'BHD',
          locale: 'en',
        );

    for (final direction in TextDirection.values) {
      testWidgets('composition is unchanged by ${direction.name} copy',
          (tester) async {
        await tester.pumpWidget(
          _directionalHost(
            Builder(builder: (context) => Text(format())),
            direction,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(bhd), findsOneWidget);
        expect(find.text(gapInsideIsolate), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BankPrizeDrawCard prize amount follows the app locale', () {
    BankPrizeDrawCard buildCard() => BankPrizeDrawCard(
          balance: Money.fromDouble(1250, 'USD'),
          entriesCount: 25,
          clock: () => DateTime(2026, 5, 2),
          useIsoCurrencyCodes: true,
          draws: [
            BankPrizeDraw(
              id: 'may',
              prizeLabel: 'Cash prize',
              prizeAmount: Money.fromDouble(500000, 'USD'),
              drawDate: DateTime(2026, 5, 13),
              lastDepositDate: DateTime(2026, 5, 8),
            ),
          ],
        );

    testWidgets('a German app gets German grouping', (tester) async {
      await tester.pumpWidget(_localeHost(buildCard(), const Locale('de')));
      await tester.pumpAndSettle();

      // `USD 500,000` read by a German customer is five hundred dollars.
      expect(find.text('USD\u00A0500.000'), findsOneWidget);
      expect(find.text('USD\u00A0500,000'), findsNothing);
    });

    testWidgets('an English app still gets US grouping', (tester) async {
      await tester.pumpWidget(_localeHost(buildCard(), const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('USD\u00A0500,000'), findsOneWidget);
      expect(find.text('USD\u00A0500.000'), findsNothing);
    });
  });

  group('Formatter smoke (rank 28)', () {
    test('trimZeroCents and unknown-code fallback', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('25000'),
          currencyCode: 'GBP',
          trimZeroCents: true,
        ),
        '£25,000',
      );
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('2480.55'),
          currencyCode: 'ZZZ',
        ),
        'ZZZ 2,480.55',
      );
    });

    test('splitMajorMinor reassembles to format output', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('2480.55'),
        currencyCode: 'GBP',
      );
      expect(parts.major, '£2,480');
      expect(parts.minor, '.55');
      expect(
        parts.major + parts.minor + parts.suffix,
        BankMoneyFormatter.format(
          amount: Decimal.parse('2480.55'),
          currencyCode: 'GBP',
        ),
      );
    });
  });
}
