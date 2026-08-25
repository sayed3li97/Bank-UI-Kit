import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts [child] under a preset-themed [MaterialApp], with the knobs the
/// chrome has to survive: brightness, direction, and text scale.
Widget _host(
  Widget child, {
  BankPreset preset = BankPreset.studio,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) =>
    BankUiScope(
      child: MaterialApp(
        theme: preset.apply(
          brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
        ),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Directionality(textDirection: direction, child: child),
          ),
        ),
      ),
    );

BankThemeData _themeOf(WidgetTester tester, Type widgetType) =>
    BankThemeData.of(tester.element(find.byType(widgetType)));

/// The [Text] carrying [data] at exactly [fontSize] — the two titles of a
/// collapsing bar are otherwise indistinguishable.
Finder _textSized(String data, double fontSize) => find.byWidgetPredicate(
      (w) => w is Text && w.data == data && w.style?.fontSize == fontSize,
    );

/// Number of semantics *nodes* whose label mentions [needle].
///
/// Counted over the node tree rather than with `find.bySemanticsLabel`, which
/// reports one hit per widget that maps onto a node and so double-counts a
/// merged one.
int _nodesLabelled(WidgetTester tester, String needle) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.label.contains(needle)) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  // Start from the node at (or above) the app root rather than the binding's
  // deprecated pipeline owner.
  visit(tester.getSemantics(find.byType(MaterialApp)));
  return count;
}

/// Labels of every node carrying the heading trait, empty labels included —
/// an anonymous heading is exactly the thing heading navigation trips over.
List<String> _headingLabels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.flagsCollection.isHeader || data.flagsCollection.namesRoute) {
      labels.add(data.label);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return labels;
}

void main() {
  // -------------------------------------------------------------------------
  // BankAppBar (rank 68)
  // -------------------------------------------------------------------------
  group('BankAppBar', () {
    testWidgets('title and subtitle come from the type tokens', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(
            appBar: BankAppBar(title: 'Accounts', subtitle: 'Sara Ahmed'),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Accounts'));
      expect(title.style?.fontSize, BankTokens.headlineMedium.fontSize);
      expect(title.style?.fontWeight, FontWeight.w700);
      // The defect: the heading used to run at headlineSmall.
      expect(
        title.style!.fontSize,
        greaterThan(BankTokens.headlineSmall.fontSize!),
      );

      final theme = _themeOf(tester, BankAppBar);
      final subtitle = tester.widget<Text>(find.text('Sara Ahmed'));
      expect(subtitle.style?.fontSize, BankTokens.labelLarge.fontSize);
      expect(subtitle.style?.color, theme.onSurfaceVariant);
      // Supporting line, not a second title.
      expect(subtitle.style!.fontSize, lessThan(title.style!.fontSize!));
    });

    testWidgets('standard mode keeps the stock bar height', (tester) async {
      const bar = BankAppBar(title: 'Accounts', subtitle: 'Sara Ahmed');
      expect(bar.preferredSize.height, kToolbarHeight);

      await tester.pumpWidget(_host(const Scaffold(appBar: bar)));
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });

    testWidgets('large mode adds a full-width tier at headlineLarge',
        (tester) async {
      const bar = BankAppBar(
        title: 'Accounts',
        subtitle: 'Sara Ahmed',
        titleMode: BankAppBarTitleMode.large,
        leading: Icon(Icons.arrow_back),
      );
      expect(bar.preferredSize.height, greaterThan(kToolbarHeight));

      await tester.pumpWidget(_host(const Scaffold(appBar: bar)));
      expect(tester.takeException(), isNull);

      final title = tester.widget<Text>(find.text('Accounts'));
      expect(title.style?.fontSize, BankTokens.headlineLarge.fontSize);
      // The tier starts at the screen margin, not behind the leading action.
      expect(tester.getTopLeft(find.text('Accounts')).dx, BankTokens.space4);
      expect(
        tester.getTopLeft(find.text('Accounts')).dy,
        greaterThan(kToolbarHeight),
      );
    });

    testWidgets('large mode stacks a caller bottom under the tier',
        (tester) async {
      const bar = BankAppBar(
        title: 'Accounts',
        titleMode: BankAppBarTitleMode.large,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: SizedBox(height: 48, child: Text('tabs')),
        ),
      );
      const noBottom = BankAppBar(
        title: 'Accounts',
        titleMode: BankAppBarTitleMode.large,
      );
      expect(bar.preferredSize.height, noBottom.preferredSize.height + 48);

      await tester.pumpWidget(_host(const Scaffold(appBar: bar)));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('tabs')).dy,
        greaterThan(tester.getTopLeft(find.text('Accounts')).dy),
      );
    });

    testWidgets('renders in every preset, both brightnesses, and RTL',
        (tester) async {
      for (final preset in BankPreset.values) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _host(
              const Scaffold(
                appBar: BankAppBar(
                  title: 'الحسابات',
                  subtitle: 'سارة أحمد',
                  titleMode: BankAppBarTitleMode.large,
                ),
              ),
              preset: preset,
              brightness: brightness,
              direction: TextDirection.rtl,
            ),
          );
          expect(tester.takeException(), isNull, reason: preset.name);
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // BankSliverAppBar (rank 68)
  // -------------------------------------------------------------------------
  group('BankSliverAppBar', () {
    Widget scrollHost() => _host(
          Scaffold(
            body: CustomScrollView(
              slivers: [
                const BankSliverAppBar(title: 'Accounts', subtitle: 'Sara'),
                SliverList.list(
                  children: [
                    for (var i = 0; i < 30; i++)
                      SizedBox(height: 48, child: Text('row $i')),
                  ],
                ),
              ],
            ),
          ),
        );

    double opacityOf(WidgetTester tester, Finder finder) => tester
        .widget<Opacity>(
          find.ancestor(of: finder, matching: find.byType(Opacity)).first,
        )
        .opacity;

    testWidgets('opens with the large title and no compact title',
        (tester) async {
      await tester.pumpWidget(scrollHost());
      expect(tester.takeException(), isNull);

      final large = _textSized('Accounts', BankTokens.headlineLarge.fontSize!);
      final compact =
          _textSized('Accounts', BankTokens.headlineSmall.fontSize!);
      expect(large, findsOneWidget);
      expect(compact, findsOneWidget);
      expect(opacityOf(tester, large), 1.0);
      expect(opacityOf(tester, compact), 0.0);
    });

    testWidgets('hands the title over to the compact bar on scroll',
        (tester) async {
      await tester.pumpWidget(scrollHost());
      await tester.drag(find.text('row 2'), const Offset(0, -400));
      await tester.pumpAndSettle();

      final large = _textSized('Accounts', BankTokens.headlineLarge.fontSize!);
      final compact =
          _textSized('Accounts', BankTokens.headlineSmall.fontSize!);
      expect(opacityOf(tester, large), 0.0);
      expect(opacityOf(tester, compact), 1.0);
    });

    testWidgets('announces the heading exactly once at both ends',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scrollHost());
      // Both titles are in the tree; only the visible one may be announced.
      expect(find.text('Accounts'), findsNWidgets(2));
      expect(_nodesLabelled(tester, 'Accounts'), 1);

      await tester.drag(find.text('row 2'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(_nodesLabelled(tester, 'Accounts'), 1);
      handle.dispose();
    });

    testWidgets('leaves no anonymous heading behind the large title',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scrollHost());

      // Expanded: the tier's own labelled heading, and nothing else. The
      // framework's wrapper around the (still excluded) compact title used to
      // add a second, unlabelled header and an empty route name here.
      expect(_headingLabels(tester), hasLength(1));
      expect(_headingLabels(tester).single, contains('Accounts'));

      await tester.drag(find.text('row 2'), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Collapsed: the compact title takes the heading over, still named.
      expect(_headingLabels(tester), hasLength(1));
      expect(_headingLabels(tester).single, contains('Accounts'));
      handle.dispose();
    });

    testWidgets('standard mode is a plain pinned bar', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(
            body: CustomScrollView(
              slivers: [
                BankSliverAppBar(
                  title: 'Accounts',
                  subtitle: 'Sara',
                  titleMode: BankAppBarTitleMode.standard,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // BankConnectivityBanner (rank 61)
  // -------------------------------------------------------------------------
  group('BankConnectivityBanner', () {
    DateTime clock() => DateTime(2026, 7, 4, 1, 12);

    Widget banner({TextDirection direction = TextDirection.ltr}) => _host(
          Scaffold(
            body: SizedBox(
              width: 360,
              child: BankConnectivityBanner(
                status: BankConnectivityStatus.serviceDegraded,
                title: 'Some services are affected',
                message: 'Bank transfers are delayed right now.',
                lastSyncedAt: DateTime(2026, 7, 4, 0, 58),
                nextRetryAt: DateTime(2026, 7, 4, 1, 12, 15),
                clock: clock,
              ),
            ),
          ),
          direction: direction,
        );

    testWidgets('every line of the text stack shares one start edge',
        (tester) async {
      await tester.pumpWidget(banner());
      await tester.pump();

      final edges = <double>[
        tester.getTopLeft(find.text('Some services are affected')).dx,
        tester
            .getTopLeft(find.text('Bank transfers are delayed right now.'))
            .dx,
        tester.getTopLeft(find.textContaining('Showing info from')).dx,
        tester.getTopLeft(find.textContaining('Retrying in')).dx,
      ];
      for (final edge in edges) {
        expect(edge, edges.first, reason: 'text stack must have one edge');
      }
    });

    testWidgets('keeps one edge in RTL too', (tester) async {
      await tester.pumpWidget(banner(direction: TextDirection.rtl));
      await tester.pump();

      final edges = <double>[
        tester.getTopRight(find.text('Some services are affected')).dx,
        tester
            .getTopRight(find.text('Bank transfers are delayed right now.'))
            .dx,
        tester.getTopRight(find.textContaining('Showing info from')).dx,
        tester.getTopRight(find.textContaining('Retrying in')).dx,
      ];
      for (final edge in edges) {
        expect(edge, edges.first);
      }
    });

    testWidgets('is a tinted surface card, not a saturated slab',
        (tester) async {
      await tester.pumpWidget(banner());
      final theme = _themeOf(tester, BankConnectivityBanner);

      final decoration = tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(BankConnectivityBanner),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration as BoxDecoration;

      expect(
        decoration.color,
        Color.alphaBlend(
          BankTokens.warning.withValues(alpha: BankTokens.alphaSoft),
          theme.surface,
        ),
      );
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, BankTokens.hairlineWidth);
      // The old treatment hung a 3 px accent rule off the start edge.
      expect(decoration.border!.isUniform, isTrue);
    });

    testWidgets('leading glyph stays centred on the first title line',
        (tester) async {
      await tester.pumpWidget(banner());
      await tester.pump();

      final title = find.text('Some services are affected');
      final lineExtent =
          BankTokens.labelLarge.fontSize! * BankTokens.labelLarge.height!;
      expect(
        tester.getCenter(find.byIcon(BankIcons.warning).first).dy,
        closeTo(tester.getTopLeft(title).dy + lineExtent / 2, 2),
      );
    });

    testWidgets('glyph follows the first line at a 2x text scale',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: SizedBox(
              width: 360,
              child: BankConnectivityBanner(
                status: BankConnectivityStatus.deviceOffline,
                title: 'Offline',
                clock: clock,
              ),
            ),
          ),
          textScale: 2,
        ),
      );

      final lineExtent =
          BankTokens.labelLarge.fontSize! * 2 * BankTokens.labelLarge.height!;
      expect(
        tester.getCenter(find.byIcon(Icons.cloud_off_outlined)).dy,
        closeTo(tester.getTopLeft(find.text('Offline')).dy + lineExtent / 2, 1),
      );
    });

    testWidgets('renders in every preset and both brightnesses',
        (tester) async {
      for (final preset in BankPreset.values) {
        for (final brightness in Brightness.values) {
          for (final status in BankConnectivityStatus.values) {
            await tester.pumpWidget(
              _host(
                Scaffold(
                  body: BankConnectivityBanner(status: status, clock: clock),
                ),
                preset: preset,
                brightness: brightness,
              ),
            );
            expect(tester.takeException(), isNull, reason: preset.name);
          }
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // BankStepProgressIndicator step help (rank 76)
  // -------------------------------------------------------------------------
  group('BankStepProgressIndicator step help', () {
    const labels = ['Identity', 'Income', 'Review'];
    const help = [
      'We check your ID against the national register.',
      'Your income decides which products we may offer you.',
      '',
    ];

    Widget stepper({
      double width = 600,
      List<String>? stepHelp = help,
      BankStepHelpVisibility visibility = BankStepHelpVisibility.currentStep,
      void Function(int step, String helpText)? onStepHelp,
    }) =>
        _host(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: BankStepProgressIndicator(
                  totalSteps: 3,
                  currentStep: 2,
                  showLabels: true,
                  labels: labels,
                  stepHelp: stepHelp,
                  helpVisibility: visibility,
                  onStepHelp: onStepHelp,
                ),
              ),
            ),
          ),
        );

    testWidgets('is absent until stepHelp is supplied', (tester) async {
      await tester.pumpWidget(stepper(stepHelp: null));
      expect(find.byType(BankPressable), findsNothing);
      expect(find.byIcon(BankIcons.info), findsNothing);
    });

    testWidgets('shows one affordance on the live step, 44 px tall',
        (tester) async {
      await tester.pumpWidget(stepper());
      expect(find.byType(BankPressable), findsOneWidget);
      expect(
        tester.getSize(find.byType(BankPressable)),
        const Size(BankTokens.minTapTarget, BankTokens.minTapTarget),
      );
    });

    testWidgets('is a labelled button for assistive technology',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(stepper());

      final node = tester.getSemantics(find.byType(BankPressable));
      expect(node.label, 'Why do we ask this?');
      expect(node.flagsCollection.isButton, isTrue);
      // Reachable as its own node: the stepper's 'Step X of Y' annotation
      // must not have swallowed it.
      expect(node.rect.height, BankTokens.minTapTarget);
      handle.dispose();
    });

    testWidgets('presents the copy in a branded sheet by default',
        (tester) async {
      await tester.pumpWidget(stepper());
      await tester.tap(find.byType(BankPressable));
      await tester.pumpAndSettle();

      expect(find.byType(BankSheetSurface), findsOneWidget);
      expect(find.text(help[1]), findsOneWidget);
      // Titled with the step it explains.
      expect(find.text('Income'), findsWidgets);
    });

    testWidgets('onStepHelp takes over the presentation', (tester) async {
      int? seenStep;
      String? seenCopy;
      await tester.pumpWidget(
        stepper(
          onStepHelp: (step, copy) {
            seenStep = step;
            seenCopy = copy;
          },
        ),
      );
      await tester.tap(find.byType(BankPressable));
      await tester.pumpAndSettle();

      expect(seenStep, 2);
      expect(seenCopy, help[1]);
      expect(find.byType(BankSheetSurface), findsNothing);
    });

    testWidgets('allSteps shows one per step that has copy', (tester) async {
      await tester.pumpWidget(
        stepper(visibility: BankStepHelpVisibility.allSteps),
      );
      // Step 3's entry is empty, so it gets no affordance.
      expect(find.byType(BankPressable), findsNWidgets(2));
    });

    testWidgets('labels still fit on one line with help attached',
        (tester) async {
      await tester.pumpWidget(
        stepper(width: 320, visibility: BankStepHelpVisibility.allSteps),
      );
      expect(tester.takeException(), isNull);
      for (final label in labels) {
        // bodySmall is 12 px at 1.4 line height; two lines would exceed 25.
        expect(
          tester.getSize(find.text(label)).height,
          lessThan(25),
          reason: '"$label" must not wrap mid-word',
        );
      }
    });

    testWidgets('never overflows a dense stepper', (tester) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: BankStepProgressIndicator(
                  totalSteps: 8,
                  currentStep: 5,
                  showLabels: true,
                  labels: const [
                    'One',
                    'Two',
                    'Three',
                    'Four',
                    'Five',
                    'Six',
                    'Seven',
                    'Eight',
                  ],
                  stepHelp: List<String>.filled(8, 'Because the rules say so.'),
                  helpVisibility: BankStepHelpVisibility.allSteps,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // 320 / 8 = 40 px cells: the target clamps to the cell instead of
      // overflowing the row.
      expect(tester.getSize(find.byType(BankPressable).first).width, 40);
    });

    testWidgets('renders RTL and in dark mode', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(
            const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: BankStepProgressIndicator(
                    totalSteps: 3,
                    currentStep: 2,
                    showLabels: true,
                    labels: ['الهوية', 'الدخل', 'المراجعة'],
                    stepHelp: ['لماذا نسأل؟', '', ''],
                    helpVisibility: BankStepHelpVisibility.allSteps,
                  ),
                ),
              ),
            ),
            direction: TextDirection.rtl,
            brightness: brightness,
            preset: BankPreset.heritage,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
