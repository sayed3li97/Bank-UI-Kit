import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1.0,
}) =>
    BankUiScope(
      child: MaterialApp(
        theme: theme ??
            BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );

void main() {
  // -------------------------------------------------------------------------
  // BankStepProgressIndicator (rank 9)
  // -------------------------------------------------------------------------
  group('BankStepProgressIndicator', () {
    testWidgets('labels render on a single line inside their step cell',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: BankStepProgressIndicator(
              totalSteps: 4,
              currentStep: 2,
              showLabels: true,
              labels: ['Identity', 'Selfie', 'Review', 'Done'],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final label in ['Identity', 'Selfie', 'Review', 'Done']) {
        // bodySmall is 12px at 1.4 line height; two lines would be > 30.
        expect(
          tester.getSize(find.text(label)).height,
          lessThan(25),
          reason: '"$label" must not wrap mid-word',
        );
      }
    });

    testWidgets('8 steps at 320px do not overflow', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            child: BankStepProgressIndicator(
              totalSteps: 8,
              currentStep: 5,
              showLabels: true,
              labels: [
                'One',
                'Two',
                'Three',
                'Four',
                'Five',
                'Six',
                'Seven',
                'Eight',
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlabelled indicator still renders (legacy call sites)',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            child: BankStepProgressIndicator(totalSteps: 4, currentStep: 2),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BankStepProgressIndicator), findsOneWidget);
    });

    testWidgets('RTL connector states match LTR (order-independent)',
        (tester) async {
      // The widget keeps its legacy display-index reversal, which composes
      // with the Row's own RTL mirroring; what must hold is that connector
      // completion is identical in both directions (RTL used to complete
      // connectors one step late).
      const active = Color(0xFFFF0000);
      const line = Color(0xFF00FF00);

      Future<void> pump(TextDirection direction) => tester.pumpWidget(
            _host(
              const SizedBox(
                width: 320,
                child: BankStepProgressIndicator(
                  totalSteps: 3,
                  currentStep: 2,
                  activeColor: active,
                  lineColor: line,
                ),
              ),
              direction: direction,
            ),
          );

      int countLines(Color color) => tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .where((w) {
            final decoration = w.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.rectangle &&
                decoration.color == color;
          }).length;

      await pump(TextDirection.ltr);
      await tester.pumpAndSettle();
      // Both halves of the completed 1-2 connector, both halves of the
      // pending 2-3 connector.
      expect(countLines(active), 2);
      expect(countLines(line), 2);

      await pump(TextDirection.rtl);
      await tester.pumpAndSettle();
      expect(countLines(active), 2);
      expect(countLines(line), 2);
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // BankProductCategoryTile (rank 11)
  // -------------------------------------------------------------------------
  group('BankProductCategoryTile adaptive layout', () {
    Widget tile({BankProductCategoryTileLayout? layout}) =>
        BankProductCategoryTile(
          icon: Icons.home_outlined,
          title: 'Mortgages',
          subtitle: 'Buy, remortgage, or release equity',
          count: 3,
          onTap: () {},
          layout: layout ?? BankProductCategoryTileLayout.auto,
        );

    testWidgets('compact width stacks vertically and keeps the full title',
        (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 160, child: tile())),
      );
      expect(tester.takeException(), isNull);
      // Vertical anatomy: the disc sits above the title.
      final disc = tester.getRect(find.byIcon(Icons.home_outlined));
      final title = tester.getRect(find.text('Mortgages'));
      expect(disc.bottom, lessThanOrEqualTo(title.top));
      // Title fits on a single line (labelLarge 14px; two lines > 28).
      expect(title.height, lessThan(22));
    });

    testWidgets('wide width keeps the classic horizontal anatomy',
        (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 400, child: tile())),
      );
      expect(tester.takeException(), isNull);
      final disc = tester.getRect(find.byIcon(Icons.home_outlined));
      final title = tester.getRect(find.text('Mortgages'));
      expect(disc.right, lessThanOrEqualTo(title.left));
      // Title vertically overlaps the disc (same row).
      expect(title.center.dy, greaterThan(disc.top));
      expect(title.center.dy, lessThan(disc.bottom));
    });

    testWidgets('compact anatomy mirrors under RTL (disc trailing badge)',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 160, child: tile()),
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
      final disc = tester.getCenter(find.byIcon(Icons.home_outlined));
      final badge = tester.getCenter(find.text('3'));
      expect(disc.dx, greaterThan(badge.dx));
    });

    testWidgets('explicit horizontal layout composes inside IntrinsicHeight',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 180,
            child: IntrinsicHeight(
              child: tile(layout: BankProductCategoryTileLayout.horizontal),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mortgages'), findsOneWidget);
    });

    testWidgets('compact anatomy renders under a dark preset', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 160, child: tile()),
          theme: BankPreset.voltage.apply(ThemeData.dark(useMaterial3: true)),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mortgages'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // BankSegmentedControl (rank 12)
  // -------------------------------------------------------------------------
  group('BankSegmentedControl', () {
    const longSegments = [
      BankSegmentItem(value: 'flat', label: 'Flat'),
      BankSegmentItem(value: 'gradient', label: 'Gradient'),
      BankSegmentItem(value: 'metal', label: 'Metal'),
      BankSegmentItem(value: 'mesh', label: 'Mesh'),
    ];

    testWidgets('labels never wrap and control meets the 44px minimum',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: BankSegmentedControl<String>(
              segments: longSegments,
              selected: 'gradient',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final label in ['Flat', 'Gradient', 'Metal', 'Mesh']) {
        for (final element in find.text(label).evaluate()) {
          final paragraph =
              element.renderObject as RenderParagraph?; // ignore ghosts
          if (paragraph == null) continue;
          expect(
            paragraph.size.height,
            lessThan(24),
            reason: '"$label" must stay on one line',
          );
        }
      }
      expect(
        tester.getSize(find.byType(BankSegmentedControl<String>)).height,
        greaterThanOrEqualTo(BankTokens.minTapTarget),
      );
      // No Material 3 checkmark affordance.
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('fires onChanged and fills selection with theme primary',
        (tester) async {
      String? changed;
      const segments = [
        BankSegmentItem(value: 'a', label: 'AA'),
        BankSegmentItem(value: 'b', label: 'BB'),
        BankSegmentItem(value: 'c', label: 'CC'),
      ];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: BankSegmentedControl<String>(
              segments: segments,
              selected: 'a',
              onChanged: (v) => changed = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('BB').last, warnIfMissed: false);
      expect(changed, 'b');

      // The selected segment carries the theme primary fill.
      final context = tester.element(find.text('AA').last);
      final primary = BankThemeData.of(context).primary;
      final selectedFills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) => (c.decoration as BoxDecoration?)?.color == primary);
      expect(selectedFills, isNotEmpty);
    });

    testWidgets('overflows into horizontal scrolling, last segment reachable',
        (tester) async {
      String? changed;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 240,
            child: BankSegmentedControl<String>(
              segments: longSegments,
              selected: 'flat',
              onChanged: (v) => changed = v,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(BankSegmentedControl<String>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Mesh').last,
        50,
        scrollable: find
            .descendant(
              of: find.byType(BankSegmentedControl<String>),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Mesh').last, warnIfMissed: false);
      expect(changed, 'mesh');
    });

    testWidgets('holds one line at 1.3x text scale', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: BankSegmentedControl<String>(
              segments: longSegments,
              selected: 'metal',
              onChanged: (_) {},
            ),
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      for (final element in find.text('Gradient').evaluate()) {
        final paragraph = element.renderObject as RenderParagraph?;
        if (paragraph == null) continue;
        expect(paragraph.size.height, lessThan(32));
      }
    });

    testWidgets('mirrors under RTL', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: BankSegmentedControl<String>(
              segments: longSegments,
              selected: 'flat',
              onChanged: (_) {},
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
      final flat = tester.getCenter(find.text('Flat').last);
      final mesh = tester.getCenter(find.text('Mesh').last);
      expect(flat.dx, greaterThan(mesh.dx));
    });
  });

  // -------------------------------------------------------------------------
  // Standing-order / recurring-merchant tiles (rank 21)
  // -------------------------------------------------------------------------
  group('tile anatomy under tall constraints', () {
    testWidgets('BankStandingOrderTile stays on one aligned grid',
        (tester) async {
      final order = BankStandingOrder(
        id: 'so-1',
        payeeName: 'Acme Lettings',
        amount: Money.fromDouble(1250, 'GBP'),
        pattern: BankRecurringPattern.monthly,
        nextRunDate: DateTime(2026, 7, 15),
      );
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            height: 300,
            child: BankStandingOrderTile(order: order, onTap: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final avatar = tester.getCenter(find.byType(CircleAvatar));
      final title = tester.getCenter(find.text('Acme Lettings'));
      expect(
        (title.dy - avatar.dy).abs(),
        lessThan(40),
        reason: 'title must not tear away from the avatar',
      );
    });

    testWidgets('BankRecurringMerchantTile stays on one aligned grid',
        (tester) async {
      final merchant = BankRecurringMerchant(
        id: 'rm-1',
        merchantName: 'Streamly',
        amount: Money.fromDouble(9.99, 'GBP'),
        cadence: BankRecurringPattern.monthly,
        nextExpectedDate: DateTime(2026, 8, 15),
        firstSeen: DateTime(2025, 8, 15),
        category: TransactionCategory.entertainment,
      );
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            height: 300,
            child: BankRecurringMerchantTile(
              merchant: merchant,
              onCancelHelp: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final emblem = tester.getCenter(find.byType(BankEmblem));
      final title = tester.getCenter(find.text('Streamly'));
      expect(
        (title.dy - emblem.dy).abs(),
        lessThan(40),
        reason: 'title must not tear away from the emblem',
      );
    });
  });

  // -------------------------------------------------------------------------
  // BankStatusTracker (rank 56)
  // -------------------------------------------------------------------------
  group('BankStatusTracker', () {
    testWidgets('renders normal and failed states without exceptions',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankStatusTracker(
            stages: [
              BankTrackerStage(
                title: 'Payment initiated',
                subtitle: 'To Acme Ltd',
                timestamp: DateTime(2026, 7, 1, 9, 30),
              ),
              BankTrackerStage(
                title: 'Compliance review',
                timestamp: DateTime(2026, 7, 1, 9, 32),
              ),
              const BankTrackerStage(title: 'Funds released'),
            ],
            currentIndex: 1,
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _host(
          BankStatusTracker(
            stages: const [
              BankTrackerStage(title: 'Submitted'),
              BankTrackerStage(title: 'Review'),
              BankTrackerStage(title: 'Resolved'),
            ],
            currentIndex: 1,
            failed: true,
            failureReason: 'Additional documents required',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Additional documents required'), findsOneWidget);
    });

    testWidgets('timestamps align to a single trailing column', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: BankStatusTracker(
              stages: [
                BankTrackerStage(
                  title: 'Initiated',
                  timestamp: DateTime(2026, 7, 1, 9, 30),
                ),
                BankTrackerStage(
                  title: 'In review',
                  timestamp: DateTime(2026, 7, 2, 10, 15),
                ),
              ],
              currentIndex: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // formatShort renders 'd MMM'.
      final first = tester.getTopRight(find.text('1 Jul'));
      final second = tester.getTopRight(find.text('2 Jul'));
      expect((first.dx - second.dx).abs(), lessThan(1));
    });
  });
}
