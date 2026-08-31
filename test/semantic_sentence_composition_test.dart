import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the exact English of the screen-reader sentences that used to be
/// glued together from fragments inside the widget and now come from whole
/// ICU messages in the catalogue.
///
/// The point of that migration was that the grammar became translatable,
/// not that the English changed: every expectation below is character-for-
/// character what the old concatenation produced.
Widget _host(Widget child) {
  final preset = BankPreset.values.first;
  return BankUiScope(
    initialData: BankUiScopeData(preset: preset),
    child: MaterialApp(
      theme: preset.apply(ThemeData.light(useMaterial3: true)),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Matches a node whose own label is exactly [sentence].
///
/// A [Semantics] node that does not exclude its descendants merges their
/// labels in after its own, separated by newlines, so an equality match
/// would depend on every child string as well. Anchoring to the start and
/// to a newline (or the end) pins the sentence under test and nothing else.
Finder _sentence(String sentence) => find.bySemanticsLabel(
      RegExp('^${RegExp.escape(sentence)}(\n|\$)'),
    );

String _money(double value, String code) => BankMoneyFormatter.format(
      amount: Money.fromDouble(value, code).amount,
      currencyCode: code,
    );

String _compact(double value, String code) => BankMoneyFormatter.format(
      amount: Money.fromDouble(value, code).amount,
      currencyCode: code,
      compact: true,
    );

void main() {
  group('budget gauge', () {
    BankBudget budget(double spent) => BankBudget(
          id: 'b1',
          name: 'Groceries',
          limit: Money.fromDouble(200, 'GBP'),
          spent: Money.fromDouble(spent, 'GBP'),
          periodStart: DateTime(2026, 7, 2),
          periodEnd: DateTime(2026, 7, 31),
        );

    testWidgets('under budget reads name, spend and limit', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(BankBudgetGaugeWidget(budget: budget(90))));
      await tester.pump();

      expect(
        _sentence(
          'Groceries budget: ${_money(90, 'GBP')} of ${_money(200, 'GBP')}',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('over budget appends the overspend clause', (tester) async {
      final handle = tester.ensureSemantics();
      await tester
          .pumpWidget(_host(BankBudgetGaugeWidget(budget: budget(210))));
      await tester.pump();

      expect(
        _sentence(
          'Groceries budget: ${_money(210, 'GBP')} '
          'of ${_money(200, 'GBP')}, over budget',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('cashflow chart', () {
    List<BankBalancePoint> points(List<double> values, {int startDay = 1}) => [
          for (var i = 0; i < values.length; i++)
            BankBalancePoint(
              date: DateTime(2026, 7, startDay + i),
              balance: Money.fromDouble(values[i], 'GBP'),
            ),
        ];

    Widget chart({List<BankBalancePoint>? forecast}) => SizedBox(
          height: 240,
          child: BankCashflowChart(
            history: points([1200, 900, 1500]),
            forecast: forecast,
            currencyCode: 'GBP',
          ),
        );

    testWidgets('history alone reads as a plain range', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(chart()));
      await tester.pump();

      expect(
        _sentence(
          'Balance ranged from ${_compact(900, 'GBP')} '
          'to ${_compact(1500, 'GBP')}',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a forecast appends the projection clause', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(chart(forecast: points([1100], startDay: 4))),
      );
      await tester.pump();

      expect(
        _sentence(
          'Balance ranged from ${_compact(900, 'GBP')} '
          'to ${_compact(1500, 'GBP')}, projected ${_compact(1100, 'GBP')}',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('bill forecast row', () {
    Widget list(double confidence) => BankBillForecastList(
          currencyCode: 'GBP',
          forecasts: [
            BankBillForecast(
              id: 'f1',
              billerName: 'Electric Co',
              predictedAmount: Money.fromDouble(64, 'GBP'),
              expectedDate: DateTime(2026, 7, 14),
              confidence: confidence,
            ),
          ],
        );

    testWidgets('a confident row reads biller and expected date',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(list(0.95)));
      await tester.pump();

      final date = BankDateFormatter.formatShort(DateTime(2026, 7, 14));
      expect(_sentence('Electric Co, Expected $date'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a low-confidence row is marked estimated', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(list(0.4)));
      await tester.pump();

      final date = BankDateFormatter.formatShort(DateTime(2026, 7, 14));
      expect(
        _sentence('Electric Co, Expected $date, estimated'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
