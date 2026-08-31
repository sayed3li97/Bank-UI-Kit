// Regression gates for the component-polish cluster (audit items 37, 48, 54,
// 55, 58). Each group pins the *defect*, not the pixels: a receipt whose ink
// disappears into its own paper, a table that clips with no way to know it,
// amounts that drift out of column, colour used as a verdict on a value, and
// a control flung to the screen edges.
import 'dart:math' as math;

import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Widget _host(
  Widget child, {
  BankPreset preset = BankPreset.studio,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
}) =>
    BankUiScope(
      initialData: BankUiScopeData(preset: preset),
      child: MaterialApp(
        theme: preset.apply(
          brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
        ),
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

BankThemeData _themeOf(WidgetTester tester, Finder of) =>
    BankThemeData.of(tester.element(of));

/// WCAG 2.1 relative-luminance of a single linearised channel (0..1 input).
double _linearize(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linearize(color.r) +
    0.7152 * _linearize(color.g) +
    0.0722 * _linearize(color.b);

/// WCAG 2.1 contrast ratio between two opaque colours (1.0 .. 21.0).
double _contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Iterable<BoxDecoration> _decorationsUnder(WidgetTester tester, Finder root) =>
    tester
        .widgetList<DecoratedBox>(
          find.descendant(of: root, matching: find.byType(DecoratedBox)),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Transaction _tx({required double amount}) => Transaction(
      id: 't1',
      amount: Money.fromDouble(amount, 'GBP'),
      settledAt: DateTime(2026, 6, 28),
      status: TransactionStatus.cleared,
      merchantName: 'Café Nero',
      category: TransactionCategory.dining,
    );

BankBill _bill({
  required String id,
  required String name,
  required double amount,
  required BankBillStatus status,
}) =>
    BankBill(
      id: id,
      billerName: name,
      amountDue: Money.fromDouble(amount, 'GBP'),
      dueDate: DateTime(2026, 7, 14),
      status: status,
    );

List<BankPlanTier> _tiers(int count) => [
      for (var i = 0; i < count; i++)
        BankPlanTier(
          id: 't$i',
          name: 'Tier $i',
          monthlyPrice: Money.fromDouble(i * 5.0, 'GBP'),
          tagline: i == 1 ? 'Most popular' : null,
          features: [
            BankPlanFeature(
              label: 'Feature A',
              tierSupport: {'t$i': i.isEven},
            ),
            BankPlanFeature(
              label: 'Feature B',
              tierSupport: {'t$i': true},
            ),
          ],
        ),
    ];

void main() {
  // -------------------------------------------------------------------------
  // Item 37 — BankReceiptView: ink is chosen by the paper, not the theme
  // -------------------------------------------------------------------------

  group('BankReceiptView', () {
    /// The paper is the receipt's own outermost decorated surface.
    Color paperOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BankReceiptView),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    /// The hero amount is the only text set at the numeralHero size.
    Color amountInkOf(WidgetTester tester) => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(BankReceiptView),
            matching: find.byType(Text),
          ),
        )
        .firstWhere((t) => t.style?.fontSize == BankTokens.numeralHero.fontSize)
        .style!
        .color!;

    for (final preset in BankPreset.values) {
      for (final brightness in Brightness.values) {
        final label = '${preset.name}/${brightness.name}';

        testWidgets('$label: paper stays light and the debit amount reads',
            (tester) async {
          await tester.pumpWidget(
            _host(
              BankReceiptView(transaction: _tx(amount: -38.5)),
              preset: preset,
              brightness: brightness,
            ),
          );

          final paper = paperOf(tester);
          expect(
            ThemeData.estimateBrightnessForColor(paper),
            Brightness.light,
            reason: '$label: a receipt must still read as paper',
          );
          expect(
            _contrastRatio(amountInkOf(tester), paper),
            greaterThanOrEqualTo(4.5),
            reason: '$label: the debit amount is illegible on its own paper',
          );
        });

        testWidgets('$label: the credit amount reads on the paper',
            (tester) async {
          await tester.pumpWidget(
            _host(
              BankReceiptView(transaction: _tx(amount: 250)),
              preset: preset,
              brightness: brightness,
            ),
          );

          expect(
            _contrastRatio(amountInkOf(tester), paperOf(tester)),
            greaterThanOrEqualTo(4.5),
            reason: '$label: the positive-balance ink fails on receipt stock',
          );
        });
      }
    }

    testWidgets('a dark paper override re-inks the receipt', (tester) async {
      await tester.pumpWidget(
        _host(
          BankReceiptView(
            transaction: _tx(amount: -38.5),
            backgroundColor: const Color(0xFF101014),
          ),
          brightness: Brightness.dark,
        ),
      );

      expect(
        _contrastRatio(amountInkOf(tester), paperOf(tester)),
        greaterThanOrEqualTo(4.5),
        reason: 'ink must follow the resolved paper, not the theme',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Item 48 — BankPlanComparisonTable: scroll affordance + closed emphasis
  // -------------------------------------------------------------------------

  group('BankPlanComparisonTable', () {
    /// The two edge fades, ordered leading-edge first.
    ({double start, double end}) fades(WidgetTester tester) {
      final finder = find.descendant(
        of: find.byType(BankPlanComparisonTable),
        matching: find.byType(AnimatedOpacity),
      );
      final found = <({double dx, double opacity})>[
        for (var i = 0; i < tester.widgetList(finder).length; i++)
          (
            dx: tester.getTopLeft(finder.at(i)).dx,
            opacity: tester.widget<AnimatedOpacity>(finder.at(i)).opacity,
          ),
      ]..sort((a, b) => a.dx.compareTo(b.dx));
      return (start: found.first.opacity, end: found.last.opacity);
    }

    testWidgets('overflowing columns scroll and fade at the live edge',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: BankPlanComparisonTable(tiers: _tiers(5)),
          ),
        ),
      );

      final scrollable = tester.widget<Scrollable>(
        find.descendant(
          of: find.byType(BankPlanComparisonTable),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.axisDirection, AxisDirection.right);

      // Parked at offset 0: nothing hidden behind the leading edge, more
      // columns behind the trailing one.
      expect(fades(tester), (start: 0.0, end: 1.0));

      await tester.drag(
        find.byType(BankPlanComparisonTable),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(fades(tester), (start: 1.0, end: 0.0));
    });

    testWidgets('a table that fits neither scrolls nor fades', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: BankPlanComparisonTable(tiers: _tiers(2)),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(BankPlanComparisonTable),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    testWidgets('the emphasis frame closes on all four sides', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 700,
            child: BankPlanComparisonTable(
              tiers: _tiers(3),
              highlightedTierId: 't1',
            ),
          ),
        ),
      );

      final theme = _themeOf(tester, find.byType(BankPlanComparisonTable));
      final frames = _decorationsUnder(
        tester,
        find.byType(BankPlanComparisonTable),
      ).where((d) => d.border is Border && (d.border! as Border).isUniform);

      expect(
        frames.length,
        1,
        reason: 'exactly one tier carries a closed emphasis frame',
      );
      final frame = frames.first;
      final border = frame.border! as Border;
      expect(border.bottom.color, theme.primary);
      expect(border.bottom.width, border.top.width);
      expect(
        (frame.borderRadius! as BorderRadius).bottomLeft.y,
        greaterThan(0),
        reason: 'the frame must round out at the bottom, not run off it',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Item 54 — BankBillPayTile: one trailing column, one enabled action
  // -------------------------------------------------------------------------

  group('BankBillPayTile', () {
    Widget twoTiles() => SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankBillPayTile(
                bill: _bill(
                  id: 'b1',
                  name: 'City Power',
                  amount: 184.2,
                  status: BankBillStatus.dueSoon,
                ),
                onPay: () {},
              ),
              BankBillPayTile(
                bill: _bill(
                  id: 'b2',
                  name: 'Metro Internet',
                  amount: 49.99,
                  status: BankBillStatus.autopay,
                ),
              ),
            ],
          ),
        );

    testWidgets('amounts share one trailing edge across rows', (tester) async {
      await tester.pumpWidget(_host(twoTiles()));

      final amounts = find.byType(BankBalanceText);
      expect(amounts, findsNWidgets(2));
      expect(
        tester.getTopRight(amounts.at(0)).dx,
        moreOrLessEquals(tester.getTopRight(amounts.at(1)).dx, epsilon: 0.5),
        reason: 'a payable row must not push its amount out of column',
      );
    });

    testWidgets('amounts stay in column in RTL', (tester) async {
      await tester.pumpWidget(
        _host(twoTiles(), textDirection: TextDirection.rtl),
      );

      final amounts = find.byType(BankBalanceText);
      expect(
        tester.getTopLeft(amounts.at(0)).dx,
        moreOrLessEquals(tester.getTopLeft(amounts.at(1)).dx, epsilon: 0.5),
      );
    });

    testWidgets('the Pay pill reads and behaves as enabled', (tester) async {
      var paid = false;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 380,
            child: BankBillPayTile(
              bill: _bill(
                id: 'b1',
                name: 'City Power',
                amount: 184.2,
                status: BankBillStatus.dueSoon,
              ),
              onPay: () => paid = true,
            ),
          ),
        ),
      );

      final theme = _themeOf(tester, find.byType(BankBillPayTile));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      final fill = button.style!.backgroundColor!.resolve(<WidgetState>{})!;
      expect(fill, theme.primary);
      expect(fill.a, 1.0, reason: 'a 12 % tint reads as a disabled chip');
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(BankTokens.minTapTarget),
      );

      await tester.tap(find.byType(FilledButton));
      expect(paid, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Item 55 — BankValueDiffRow: one grammar, colour by meaning
  // -------------------------------------------------------------------------

  group('BankValueDiffRow', () {
    Color arrowInk(WidgetTester tester) =>
        tester.widget<Icon>(find.byIcon(BankIcons.forward)).color!;

    Color newValueInk(WidgetTester tester) => tester
        .widgetList<BankBalanceText>(find.byType(BankBalanceText))
        .last
        .style!
        .color!;

    Widget limitRow({
      bool highlightIncrease = false,
      BankValueDiffMeaning meaning = BankValueDiffMeaning.neutral,
    }) =>
        SizedBox(
          width: 360,
          child: BankValueDiffRow(
            label: 'Daily limit',
            oldMoney: Money.fromDouble(5000, 'GBP'),
            newMoney: Money.fromDouble(25000, 'GBP'),
            highlightIncrease: highlightIncrease,
            meaning: meaning,
          ),
        );

    testWidgets('an increased new value is not painted as a warning',
        (tester) async {
      await tester.pumpWidget(_host(limitRow(highlightIncrease: true)));

      final theme = _themeOf(tester, find.byType(BankValueDiffRow));
      expect(
        newValueInk(tester),
        theme.onSurface,
        reason: 'the new value is content, not a verdict',
      );
      expect(
        arrowInk(tester),
        theme.pending,
        reason: 'the change itself carries the caution',
      );
    });

    testWidgets('a neutral change leaves the arrow neutral', (tester) async {
      await tester.pumpWidget(_host(limitRow()));

      final theme = _themeOf(tester, find.byType(BankValueDiffRow));
      expect(arrowInk(tester), theme.onSurfaceVariant);
      expect(newValueInk(tester), theme.onSurface);
    });

    testWidgets('a favourable change reads positive', (tester) async {
      await tester.pumpWidget(
        _host(limitRow(meaning: BankValueDiffMeaning.favourable)),
      );

      final theme = _themeOf(tester, find.byType(BankValueDiffRow));
      expect(arrowInk(tester), theme.positiveBalance);
      expect(newValueInk(tester), theme.onSurface);
    });

    testWidgets('both styles speak the same grammar', (tester) async {
      for (final style in BankValueDiffStyle.values) {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 360,
              child: BankValueDiffRow(
                label: 'Account name',
                oldValue: 'Acme Trading',
                newValue: 'Acme Trading LLC',
                style: style,
              ),
            ),
          ),
        );

        expect(
          find.byIcon(BankIcons.forward),
          findsOneWidget,
          reason: '${style.name} must point old → new like the other variant',
        );
        expect(find.text('Previous'), findsNothing);
        expect(find.text('New'), findsNothing);
      }
    });

    testWidgets('the arrow is bundled with the value it points at',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 240,
            child: BankValueDiffRow(
              label: 'Registered address',
              oldValue: 'Sunset Boulevard 120',
              newValue: 'Ocean Drive Apt 4412',
              style: BankValueDiffStyle.stacked,
            ),
          ),
        ),
      );

      // The cluster wraps; the innermost Row around the arrow is what keeps
      // it from being carried to a line of its own.
      final bundle = find
          .ancestor(
            of: find.byIcon(BankIcons.forward),
            matching: find.byType(Row),
          )
          .first;

      final newValue = find.text('Ocean Drive Apt 4412');
      expect(
        find.descendant(of: bundle, matching: newValue),
        findsOneWidget,
        reason: 'an arrow that can wrap away from its value points at nothing',
      );
      expect(
        find.descendant(
          of: bundle,
          matching: find.text('Sunset Boulevard 120'),
        ),
        findsNothing,
        reason: 'the old value must stay free to wrap onto its own line',
      );
      expect(
        tester.getRect(find.byIcon(BankIcons.forward)).center.dy,
        moreOrLessEquals(
          tester.getRect(newValue).center.dy,
          epsilon: 2,
        ),
      );
    });

    testWidgets('a removed field uses the brightness-aware negative colour',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: BankValueDiffRow(
              label: 'Second approver',
              oldValue: 'Lina Haddad',
            ),
          ),
          brightness: Brightness.dark,
        ),
      );

      final theme = _themeOf(tester, find.byType(BankValueDiffRow));
      final chip = _decorationsUnder(tester, find.byType(BankValueDiffRow))
          .firstWhere((d) => d.color != null);
      expect(chip.color!.r, theme.negativeBalance.r);
      expect(chip.color!.g, theme.negativeBalance.g);
      expect(chip.color!.b, theme.negativeBalance.b);
    });
  });

  // -------------------------------------------------------------------------
  // Item 58 — BankPeriodSelector: content-sized, with real targets
  // -------------------------------------------------------------------------

  group('BankPeriodSelector', () {
    Finder chevron(String label) => find.byWidgetPredicate(
          (w) => w is BankPressable && w.semanticLabel == label,
        );

    Widget selector({
      DateTime? max,
      ValueChanged<DateTime>? onChanged,
    }) =>
        SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankPeriodSelector(
                period: DateTime(2026, 3),
                unit: BankPeriodUnit.month,
                maxPeriod: max,
                onChanged: onChanged ?? (_) {},
              ),
            ],
          ),
        );

    testWidgets('sizes to its content instead of the available width',
        (tester) async {
      await tester.pumpWidget(_host(selector()));

      final width = tester.getSize(find.byType(BankPeriodSelector)).width;
      expect(
        width,
        lessThan(400),
        reason: 'a stretched row flings the chevrons to the screen edges',
      );

      // The chevrons must sit against the label, not across a gutter.
      final gap = tester.getRect(find.byType(Text).first).left -
          tester.getRect(chevron('Previous month')).right;
      expect(gap, lessThan(BankTokens.space4));
    });

    testWidgets('each chevron is a full 44 px target', (tester) async {
      await tester.pumpWidget(_host(selector()));

      for (final label in ['Previous month', 'Next month']) {
        expect(
          tester.getSize(chevron(label)),
          const Size(BankTokens.minTapTarget, BankTokens.minTapTarget),
          reason: '$label must be tappable, not a bare hairline glyph',
        );
      }
    });

    testWidgets('chevrons page the period and stop at a bound', (tester) async {
      DateTime? received;
      await tester.pumpWidget(
        _host(
          selector(
            max: DateTime(2026, 3),
            onChanged: (value) => received = value,
          ),
        ),
      );

      await tester.tap(chevron('Previous month'));
      expect(received, DateTime(2026, 2));

      received = null;
      await tester.tap(chevron('Next month'), warnIfMissed: false);
      expect(
        received,
        isNull,
        reason: 'the forward chevron is disabled at maxPeriod',
      );
      // Disabled or not, the target keeps its size.
      expect(
        tester.getSize(chevron('Next month')),
        const Size(BankTokens.minTapTarget, BankTokens.minTapTarget),
      );
    });
  });
}
