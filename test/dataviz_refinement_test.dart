import 'dart:io';
import 'dart:math' as math;

import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a themed [BankUiScope] so widgets that read
/// [BankThemeData.of] / [BankUiScope.of] can be pumped in isolation.
Widget _host(
  Widget child, {
  bool disableAnimations = false,
  BankPreset? preset,
}) {
  final resolvedPreset = preset ?? BankPreset.values.first;
  return BankUiScope(
    initialData: BankUiScopeData(preset: resolvedPreset),
    child: MaterialApp(
      theme: resolvedPreset.apply(ThemeData.light(useMaterial3: true)),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// The eight Tailwind/stock hues the donut used to hard-code.
const _legacyTailwindHexes = <int>[
  0xFF4A7C80,
  0xFFFF6B6B,
  0xFF7C3AED,
  0xFFF59E0B,
  0xFF10B981,
  0xFF3B82F6,
  0xFFEC4899,
  0xFF8B5CF6,
];

void main() {
  group('Spending donut palette derivation', () {
    test('is deterministic for the same seed and brightness', () {
      const seed = Color(0xFF1B4D3E);
      final a = BankSpendingBreakdownChart.derivePalette(
        seed: seed,
        brightness: Brightness.light,
      );
      final b = BankSpendingBreakdownChart.derivePalette(
        seed: seed,
        brightness: Brightness.light,
      );
      expect(a, equals(b));
      expect(a, hasLength(8));
    });

    test('honours the requested length and yields distinct colours', () {
      final palette = BankSpendingBreakdownChart.derivePalette(
        seed: const Color(0xFF3366FF),
        brightness: Brightness.light,
        length: 6,
      );
      expect(palette, hasLength(6));
      expect(palette.toSet(), hasLength(6), reason: 'colours must be unique');
    });

    test('differs across brightnesses (lightness anchored per surface)', () {
      const seed = Color(0xFF3366FF);
      final light = BankSpendingBreakdownChart.derivePalette(
        seed: seed,
        brightness: Brightness.light,
      );
      final dark = BankSpendingBreakdownChart.derivePalette(
        seed: seed,
        brightness: Brightness.dark,
      );
      expect(light, isNot(equals(dark)));
      for (final c in light) {
        expect(
          HSLColor.fromColor(c).lightness,
          lessThan(0.5),
          reason: 'light-surface ramp stays dark enough to read on white',
        );
      }
      for (final c in dark) {
        expect(
          HSLColor.fromColor(c).lightness,
          greaterThan(0.5),
          reason: 'dark-surface ramp stays light enough to read on black',
        );
      }
    });

    test('derived defaults contain none of the legacy Tailwind constants', () {
      for (final brightness in Brightness.values) {
        final palette = BankSpendingBreakdownChart.derivePalette(
          seed: const Color(0xFF4A7C80),
          brightness: brightness,
        );
        for (final c in palette) {
          expect(_legacyTailwindHexes, isNot(contains(c.toARGB32())));
        }
      }
    });

    test('the legacy Tailwind hex constants are gone from the source', () {
      final source = File('lib/src/insights/bank_spending_breakdown_chart.dart')
          .readAsStringSync()
          .toUpperCase();
      for (final hex in _legacyTailwindHexes) {
        final literal =
            '0X${hex.toRadixString(16).toUpperCase().padLeft(8, '0')}';
        expect(
          source.contains(literal),
          isFalse,
          reason: '$literal must not be hard-coded in the donut',
        );
      }
    });
  });

  group('Spending donut centre + legend', () {
    final categories = [
      BankSpendingCategory(
        category: TransactionCategory.groceries,
        amount: Money.fromDouble(120, 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.dining,
        amount: Money.fromDouble(80, 'GBP'),
      ),
      BankSpendingCategory(
        category: TransactionCategory.entertainment,
        amount: Money.fromDouble(50, 'GBP'),
      ),
    ];

    testWidgets('renders the formatted total and caption in the centre',
        (tester) async {
      await tester.pumpWidget(
        _host(BankSpendingBreakdownChart(categories: categories)),
      );
      await tester.pump();
      expect(find.textContaining('250'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('centerLabel overrides the computed total', (tester) async {
      await tester.pumpWidget(
        _host(
          BankSpendingBreakdownChart(
            categories: categories,
            centerLabel: 'June',
            centerCaption: 'This month',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('June'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
    });

    testWidgets('legend renders one aligned row per category', (tester) async {
      await tester.pumpWidget(
        _host(BankSpendingBreakdownChart(categories: categories)),
      );
      await tester.pump();
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });
  });

  group('Credit limit gauge sweep and bounds', () {
    test('sweeps exactly the documented 270 degrees', () {
      expect(BankCreditLimitGauge.gaugeSweepAngle, math.pi * 1.5);
      expect(BankCreditLimitGauge.gaugeStartAngle, math.pi * 0.75);
      // Start 135° + sweep 270° ends at 45°: symmetric about vertical.
      const end = BankCreditLimitGauge.gaugeStartAngle +
          BankCreditLimitGauge.gaugeSweepAngle;
      expect(end % (2 * math.pi), closeTo(math.pi / 4, 1e-9));
    });

    test('geometry keeps the full stroke inside the canvas', () {
      for (final size in const [
        Size(200, 120),
        Size(120, 120),
        Size(300, 90),
        Size(80, 200),
      ]) {
        const stroke = 14.0;
        final g = BankCreditLimitGauge.gaugeGeometry(size, stroke);
        final r = g.radius;
        final c = g.center;
        expect(r, greaterThan(0));
        // Top of the stroke.
        expect(c.dy - r - stroke / 2, greaterThanOrEqualTo(-1e-9));
        // Sides of the stroke.
        expect(c.dx - r - stroke / 2, greaterThanOrEqualTo(-1e-9));
        expect(c.dx + r + stroke / 2, lessThanOrEqualTo(size.width + 1e-9));
        // The 270° endpoints sit sin(45°) below centre; with the round
        // cap they must stay inside the canvas (the old painter put
        // them at y ≈ 144 on a 120px canvas).
        final endpointY = c.dy + r * math.sin(math.pi / 4);
        expect(endpointY + stroke / 2, lessThanOrEqualTo(size.height + 1e-9));
      }
    });

    testWidgets('renders without painting errors and shows both legends',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankCreditLimitGauge(
            creditLimit: Money.fromDouble(4000, 'GBP'),
            usedAmount: Money.fromDouble(2800, 'GBP'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('Limit'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);
    });
  });

  group('Asset price ticker', () {
    AssetQuote quote(double price, {double change = 1.2}) => AssetQuote(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          price: Money.fromDouble(price, 'USD'),
          changePercent: change,
        );

    testWidgets('reduced motion swaps the price instantly with no animation',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankAssetPriceTicker(quote: quote(190)),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(find.textContaining('190'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          BankAssetPriceTicker(quote: quote(195.50)),
          disableAnimations: true,
        ),
      );
      // A single zero-duration pump: the new price must already be the
      // only one on screen, with nothing left animating.
      await tester.pump();
      expect(find.textContaining('195.50'), findsOneWidget);
      expect(find.textContaining('190.00'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('animated path settles on the new price', (tester) async {
      await tester.pumpWidget(_host(BankAssetPriceTicker(quote: quote(190))));
      await tester.pump();

      await tester.pumpWidget(
        _host(BankAssetPriceTicker(quote: quote(184, change: -0.8))),
      );
      // Mid-flight both prices exist (crossfade), then the old one goes.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('184'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('184'), findsOneWidget);
      expect(find.textContaining('190'), findsNothing);
    });
  });

  group('Budget gauge truthful percentage', () {
    BankBudget budget(double spent) => BankBudget(
          id: 'b1',
          name: 'Groceries',
          limit: Money.fromDouble(200, 'GBP'),
          spent: Money.fromDouble(spent, 'GBP'),
          periodStart: DateTime(2026, 7, 2),
          periodEnd: DateTime(2026, 7, 31),
        );

    testWidgets('over budget prints the true percentage beside the chip',
        (tester) async {
      await tester
          .pumpWidget(_host(BankBudgetGaugeWidget(budget: budget(210))));
      await tester.pump();
      expect(find.text('105%'), findsOneWidget);
      expect(find.text('Over budget'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('under budget still prints the plain percentage',
        (tester) async {
      await tester.pumpWidget(_host(BankBudgetGaugeWidget(budget: budget(90))));
      await tester.pump();
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('Over budget'), findsNothing);
    });
  });
}
