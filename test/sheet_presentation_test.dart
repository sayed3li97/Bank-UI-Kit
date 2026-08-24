// Branded sheet-presentation checks: the grab handle, the theme radius and
// token scrim, generic result round-tripping, reduced-motion collapse, and RTL
// header placement.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _appTheme(Brightness brightness) => BankPreset.studio.apply(
      brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
    );

BankThemeData _bankTheme(Brightness brightness) =>
    _appTheme(brightness).extension<BankThemeData>()!;

/// Pumps a host screen with a single "open" button wired to [onPressed].
///
/// The overrides are injected through `MaterialApp.builder`, which sits above
/// the navigator, so pushed modal routes inherit them too.
Future<void> _pumpHost(
  WidgetTester tester, {
  required void Function(BuildContext) onPressed,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) =>
    tester.pumpWidget(
      BankUiScope(
        child: MaterialApp(
          // A fresh key per pump discards any navigator state (and therefore
          // any still-open route) from a previous case in the same test.
          key: UniqueKey(),
          theme: _appTheme(brightness),
          builder: (context, child) => Directionality(
            textDirection: textDirection,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: disableAnimations),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => onPressed(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Iterable<BoxDecoration> _surfaceDecorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(BankSheetSurface),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>();

void main() {
  testWidgets('grab handle renders and carries semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await _pumpHost(
      tester,
      onPressed: (context) => BankSheet.show<void>(
        context,
        builder: (_) => const SizedBox(height: 120),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BankSheetHandle), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(BankSheetHandle)).label,
      BankSheet.defaultHandleSemanticLabel,
    );

    semantics.dispose();
  });

  testWidgets('handle is omitted on non-draggable flows', (tester) async {
    await _pumpHost(
      tester,
      onPressed: (context) => BankSheet.show<void>(
        context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => const SizedBox(height: 120),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BankSheetHandle), findsNothing);
  });

  testWidgets('applies the theme sheet radius and surface', (tester) async {
    final theme = _bankTheme(Brightness.light);

    await _pumpHost(
      tester,
      onPressed: (context) => BankSheet.show<void>(
        context,
        builder: (_) => const SizedBox(height: 120),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      _surfaceDecorations(tester).any(
        (d) => d.borderRadius == theme.sheetRadius && d.color == theme.surface,
      ),
      isTrue,
      reason: 'the branded surface must paint sheetRadius over surface',
    );
  });

  testWidgets('applies the token scrim, not Material black54', (tester) async {
    for (final brightness in Brightness.values) {
      Color? barrier;

      await _pumpHost(
        tester,
        brightness: brightness,
        onPressed: (context) => BankSheet.show<void>(
          context,
          builder: (sheetContext) {
            barrier = ModalRoute.of(sheetContext)!.barrierColor;
            return const SizedBox(height: 120);
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final theme = _bankTheme(brightness);
      final expectedAlpha = brightness == Brightness.dark
          ? BankSheet.scrimOpacityDark
          : BankSheet.scrimOpacity;
      // The veil is whichever of the theme's ground and ink is darker.
      final expectedInk =
          brightness == Brightness.dark ? theme.background : theme.onBackground;

      expect(barrier, isNotNull);
      expect(barrier, isNot(Colors.black54), reason: 'Material default');
      expect(barrier, expectedInk.withValues(alpha: expectedAlpha));
    }
  });

  testWidgets('the body is laid out at the full sheet width', (tester) async {
    await _pumpHost(
      tester,
      onPressed: (context) => BankSheet.show<void>(
        context,
        // A childless SizedBox with no width fills only a *tight* width
        // constraint, which is what the modal route hands its child.
        builder: (_) => const SizedBox(key: ValueKey('body'), height: 40),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('body'))).width,
      tester.getSize(find.byType(BankSheetSurface)).width,
    );
  });

  testWidgets('tall content shares the surface with handle and header',
      (tester) async {
    await _pumpHost(
      tester,
      onPressed: (context) => BankSheet.show<void>(
        context,
        title: 'Long list',
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.92,
          child: ListView.builder(
            itemCount: 60,
            itemBuilder: (_, index) => SizedBox(
              height: BankTokens.minTapTarget,
              child: Text('row $index'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'must not overflow');
    expect(find.byType(BankSheetHandle), findsOneWidget);
    expect(find.text('Long list'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
  });

  testWidgets('a result value round-trips through the sheet', (tester) async {
    String? result;
    var completed = false;

    await _pumpHost(
      tester,
      onPressed: (context) async {
        result = await BankSheet.show<String>(
          context,
          builder: (sheetContext) => TextButton(
            onPressed: () => Navigator.of(sheetContext).pop('picked'),
            child: const Text('pick'),
          ),
        );
        completed = true;
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, 'picked');
  });

  testWidgets('a dismissed sheet completes with null', (tester) async {
    Object? result = 'sentinel';

    await _pumpHost(
      tester,
      onPressed: (context) async {
        result = await BankSheet.show<String>(
          context,
          builder: (_) => const SizedBox(height: 120, child: Text('body')),
        );
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Tap the scrim above the sheet.
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('reduced motion collapses the sheet transition', (tester) async {
    Future<Offset> firstFrameTravel({required bool disableAnimations}) async {
      await _pumpHost(
        tester,
        disableAnimations: disableAnimations,
        onPressed: (context) => BankSheet.show<void>(
          context,
          builder: (_) => const SizedBox(height: 200, child: Text('body')),
        ),
      );
      await tester.tap(find.text('open'));
      // One frame only: the transition has been started but not advanced.
      await tester.pump();
      final atStart = tester.getTopLeft(find.text('body'));
      await tester.pumpAndSettle();
      return atStart - tester.getTopLeft(find.text('body'));
    }

    expect(
      await firstFrameTravel(disableAnimations: true),
      Offset.zero,
      reason: 'a reduced-motion sheet must be at its resting offset on frame 1',
    );
    expect(
      (await firstFrameTravel(disableAnimations: false)).dy,
      greaterThan(0),
      reason: 'the control case must actually travel, or the test proves '
          'nothing',
    );
  });

  testWidgets('RTL mirrors the header action to the leading edge',
      (tester) async {
    Future<double> actionOffsetFromTitle(TextDirection direction) async {
      await _pumpHost(
        tester,
        textDirection: direction,
        onPressed: (context) => BankSheet.show<void>(
          context,
          title: 'Filters',
          trailing: IconButton(
            key: const ValueKey('close'),
            icon: const Icon(Icons.close_rounded),
            onPressed: () {},
          ),
          builder: (_) => const SizedBox(height: 120),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BankSheetHeader), findsOneWidget);
      return tester.getCenter(find.byKey(const ValueKey('close'))).dx -
          tester.getCenter(find.text('Filters')).dx;
    }

    expect(await actionOffsetFromTitle(TextDirection.ltr), greaterThan(0));
    expect(await actionOffsetFromTitle(TextDirection.rtl), lessThan(0));
  });

  testWidgets('BankDialog applies the same branded scrim', (tester) async {
    Color? barrier;

    await _pumpHost(
      tester,
      onPressed: (context) => BankDialog.show<void>(
        context,
        builder: (dialogContext) {
          barrier = ModalRoute.of(dialogContext)!.barrierColor;
          return const AlertDialog(content: Text('confirm'));
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final theme = _bankTheme(Brightness.light);
    expect(
      barrier,
      theme.onBackground.withValues(alpha: BankSheet.scrimOpacity),
    );
  });
}
