import 'package:bank_ui_kit/bank_ui_kit.dart';
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the balance-typography stream:
/// - BankBalanceText merges caller styles over the numeral base (tabular
///   figures survive partial overrides).
/// - Amounts scale down instead of truncating to an ellipsis (LTR and RTL).
/// - Amount changes count up/down and settle on the exact formatted value.
/// - BankBalanceTile renders its caption verbatim in the caption token.
/// - Keypads keep working through the BankPressable key language.
Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
    home: BankUiScope(
      child: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('BankBalanceText style merge', () {
    testWidgets('partial style override keeps tabular figures', (tester) async {
      await tester.pumpWidget(
        _host(
          BankBalanceText(
            money: Money.fromDouble(1234.56, 'GBP'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, Colors.red);
      expect(
        text.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      // Tier size survives a colour-only override.
      expect(text.style?.fontSize, BankTokens.numeralLarge.fontSize);
    });

    testWidgets('inherit: false replaces the base entirely', (tester) async {
      await tester.pumpWidget(
        _host(
          BankBalanceText(
            money: Money.fromDouble(1234.56, 'GBP'),
            style: const TextStyle(inherit: false, fontSize: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, 10);
      expect(text.style?.fontFeatures, isNull);
    });
  });

  group('BankBalanceText fit-to-width', () {
    testWidgets('hero amount in a 200px box never ellipsizes', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            child: BankBalanceText(
              money: Money.fromDouble(1234567.89, 'GBP'),
              size: BankBalanceSize.hero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('1,234,567').first,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('RTL: hero amount in a 200px box never ellipsizes',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            child: BankBalanceText(
              money: Money.fromDouble(1234567.89, 'AED'),
              size: BankBalanceSize.hero,
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('1,234,567').first,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitToWidth: false renders a plain single-line Text',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankBalanceText(
            money: Money.fromDouble(12.34, 'GBP'),
            fitToWidth: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FittedBox), findsNothing);
      expect(find.textContaining('12.34'), findsOneWidget);
    });
  });

  group('BankBalanceText count-up', () {
    testWidgets('first build renders the final value immediately',
        (tester) async {
      await tester.pumpWidget(
        _host(BankBalanceText(money: Money.fromDouble(500, 'GBP'))),
      );
      // No settle: the very first frame must already show the target.
      expect(find.textContaining('500.00'), findsOneWidget);
    });

    testWidgets('amount change animates and settles on the exact value',
        (tester) async {
      await tester.pumpWidget(
        _host(BankBalanceText(money: Money.fromDouble(100, 'GBP'))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('100.00'), findsOneWidget);

      await tester.pumpWidget(
        _host(BankBalanceText(money: Money.fromDouble(200, 'GBP'))),
      );
      // Mid-flight: neither endpoint should be showing.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('100.00'), findsNothing);
      expect(find.textContaining('200.00'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.textContaining('200.00'), findsOneWidget);
    });

    testWidgets('animateChanges: false snaps to the new value', (tester) async {
      await tester.pumpWidget(
        _host(
          BankBalanceText(
            money: Money.fromDouble(100, 'GBP'),
            animateChanges: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _host(
          BankBalanceText(
            money: Money.fromDouble(200, 'GBP'),
            animateChanges: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('200.00'), findsOneWidget);
    });
  });

  group('BankBalanceTile caption', () {
    testWidgets('caption renders verbatim in sentence case', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 168,
            child: BankBalanceTile(
              label: 'Available Balance',
              amount: Money.fromDouble(3565, 'GBP'),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('AVAILABLE BALANCE'), findsNothing);

      final caption = tester.widget<Text>(find.text('Available Balance'));
      expect(caption.style?.letterSpacing, 0);
      expect(caption.style?.fontSize, BankTokens.caption.fontSize);
      expect(caption.maxLines, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tile amount keeps tabular figures under amountStyle',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 168,
            child: BankBalanceTile(
              label: 'Savings',
              amount: Money.fromDouble(650, 'GBP'),
              amountStyle: const TextStyle(color: Colors.green),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final amountText = tester.widget<Text>(find.textContaining('650.00'));
      expect(
        amountText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(amountText.style?.color, Colors.green);
      // w800 is gone: the numeral tier weight is what renders.
      expect(amountText.style?.fontWeight, isNot(FontWeight.w800));
    });
  });

  group('Keypads', () {
    testWidgets('BankAmountKeypad: long amount at 320px does not overflow',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: BankAmountKeypad(
              amountText: '123456789012345',
              currencyCode: 'GBP',
              onDigit: (_) {},
              onDelete: () {},
              onDecimalPoint: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('123456789012345'), findsOneWidget);
    });

    testWidgets('BankAmountKeypad: digit and delete taps reach callbacks',
        (tester) async {
      String? digit;
      var deleted = false;
      await tester.pumpWidget(
        _host(
          BankAmountKeypad(
            amountText: '12',
            currencyCode: 'GBP',
            onDigit: (d) => digit = d,
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('7'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(digit, '7');
      expect(deleted, isTrue);
    });

    testWidgets(
        'BankAmountKeypad: decimal cell is absent when decimals disabled',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankAmountKeypad(
            amountText: '12',
            currencyCode: 'JPY',
            onDigit: (_) {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('.'), findsNothing);
    });

    testWidgets('BankPinKeypad: digit taps reach onDigit', (tester) async {
      String? digit;
      await tester.pumpWidget(
        _host(
          BankPinKeypad(
            onDigit: (d) => digit = d,
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(digit, '3');
    });
  });

  group('BankPinDots', () {
    testWidgets('renders, fills, and survives the error shake', (tester) async {
      await tester.pumpWidget(
        _host(const BankPinDots(filled: 2, length: 4)),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('2 of 4 digits entered'), findsOneWidget);

      await tester.pumpWidget(
        _host(const BankPinDots(filled: 4, length: 4, error: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
