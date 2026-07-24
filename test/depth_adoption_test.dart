// Depth-system adoption checks: representative card surfaces must resolve
// a non-empty boxShadow in light mode, and in dark mode must separate from
// the background with a shadow and/or a visible hairline border.
import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {required Brightness brightness}) => BankUiScope(
      child: MaterialApp(
        theme: BankPreset.studio.apply(
          brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Iterable<BoxDecoration> _decorationsUnder(WidgetTester tester, Finder root) =>
    tester
        .widgetList<DecoratedBox>(
          find.descendant(of: root, matching: find.byType(DecoratedBox)),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();

bool _hasShadow(Iterable<BoxDecoration> decorations) =>
    decorations.any((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty);

bool _hasVisibleBorder(Iterable<BoxDecoration> decorations) =>
    decorations.any((d) {
      final border = d.border;
      return border is Border && border.top.width > 0 && border.top.color.a > 0;
    });

Future<void> _expectDepth(
  WidgetTester tester,
  Widget Function() build,
  Type type,
) async {
  // Light: the resting card must carry a resolved, non-empty boxShadow.
  await tester.pumpWidget(_host(build(), brightness: Brightness.light));
  await tester.pump();
  final lightDecorations = _decorationsUnder(tester, find.byType(type));
  expect(
    _hasShadow(lightDecorations),
    isTrue,
    reason: '$type must render a non-empty boxShadow in light mode',
  );

  // Dark: shadow and/or visible hairline border must separate the surface.
  await tester.pumpWidget(_host(build(), brightness: Brightness.dark));
  await tester.pump();
  final darkDecorations = _decorationsUnder(tester, find.byType(type));
  expect(
    _hasShadow(darkDecorations) || _hasVisibleBorder(darkDecorations),
    isTrue,
    reason: '$type must render a boxShadow or visible border in dark mode',
  );
}

void main() {
  testWidgets('BankInsightCard resolves depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => BankInsightCard(
        insight: BankInsight(
          id: 'i1',
          title: 'Spending is up',
          body: 'You spent 12% more on dining this month.',
          confidence: InsightConfidence.high,
          generatedAt: DateTime(2026, 7),
          isDismissed: false,
        ),
        onTap: () {},
      ),
      BankInsightCard,
    );
  });

  testWidgets('BankOfferSummaryCard resolves depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => BankOfferSummaryCard(
        payment: Money.fromDouble(325.5, 'GBP'),
        amount: Money.fromDouble(10000, 'GBP'),
        onAccept: () {},
      ),
      BankOfferSummaryCard,
    );
  });

  testWidgets('BankPointsHubCard resolves depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => const BankPointsHubCard(
        pointsBalance: 12450,
        actions: [],
        cashValueLabel: '= £2,480.50',
      ),
      BankPointsHubCard,
    );
  });

  testWidgets('BankWatchlistCard resolves depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => BankWatchlistCard(
        quote: AssetQuote(
          symbol: 'ACME',
          name: 'Acme Corp',
          price: Money.fromDouble(182.4, 'USD'),
          changePercent: 1.2,
        ),
        onTap: () {},
      ),
      BankWatchlistCard,
    );
  });

  testWidgets('BankLoanCalculatorCard resolves depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => BankLoanCalculatorCard(
        minAmount: Money.fromDouble(1000, 'GBP'),
        maxAmount: Money.fromDouble(20000, 'GBP'),
        minMonths: 6,
        maxMonths: 60,
        annualRate: 0.049,
        onChanged: (_, __) {},
      ),
      BankLoanCalculatorCard,
    );
  });

  testWidgets('BankQuickActionsGrid icon discs resolve depth in light and dark',
      (tester) async {
    await _expectDepth(
      tester,
      () => BankQuickActionsGrid(
        actions: [
          BankQuickAction(
            id: 'send',
            icon: Icons.send_rounded,
            label: 'Send',
            onTap: () {},
            badgeText: 'New',
          ),
        ],
      ),
      BankQuickActionsGrid,
    );
  });

  testWidgets(
      'BankQuickActionsGrid glyph ink is onSurface-based and badge sits '
      'clear of the disc', (tester) async {
    await tester.pumpWidget(
      _host(
        BankQuickActionsGrid(
          actions: [
            BankQuickAction(
              id: 'send',
              icon: Icons.send_rounded,
              label: 'Send',
              onTap: () {},
              badgeText: 'New',
            ),
          ],
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pump();

    final theme = BankPreset.studio
        .apply(ThemeData.light(useMaterial3: true))
        .extension<BankThemeData>()!;

    final icon = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
    expect(
      icon.color,
      theme.onSurface,
      reason: 'quick-action glyphs use onSurface ink for >=3:1 contrast',
    );

    // The badge must not overlap the icon glyph.
    final badgeRect = tester.getRect(find.text('New'));
    final glyphRect = tester.getRect(find.byIcon(Icons.send_rounded));
    expect(
      badgeRect.overlaps(glyphRect),
      isFalse,
      reason: 'the badge chip must sit clear of the icon glyph',
    );
  });
}
