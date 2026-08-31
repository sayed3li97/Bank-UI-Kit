// Layout gates for the constraints the component authors did not try: a
// narrow phone, and a raised OS text size.
//
// Both defects here were invisible at the sizes the widgets were built at and
// only appear once the available width (or the text scale) is squeezed, so
// these tests pin the exact geometries that failed:
//
//  * [BankInsightCard]'s action row used to share the row's free space between
//    the confidence meter and a `Spacer`, capping the meter at half the slack
//    and ellipsizing its label — the wording that is the level's only
//    non-colour encoding (WCAG 1.4.1).
//  * [BankHorizontalAccountCard]'s back face used to spend a hard
//    [BankTokens.minTapTarget] of vertical budget per copy row inside a fixed
//    ISO-7810 box, so an account carrying both an IBAN and a sort code
//    overflowed on a narrow device or at a raised text scale.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _insight = BankInsight(
  id: 'i1',
  title: 'Spending is up',
  body: 'You spent 12% more on dining this month.',
  confidence: InsightConfidence.high,
  generatedAt: DateTime(2026, 7),
  isDismissed: false,
);

/// An account carrying *both* optional back-face rows — the worst case for the
/// back face's vertical budget.
final _fullAccount = BankAccount(
  id: 'a1',
  name: 'Everyday Current',
  maskedNumber: '•••• 4321',
  balance: Money.fromDouble(1240.5, 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
  ibanOrAccountNumber: 'GB29 NWBK 6016 1331 9268 19',
  sortCodeOrBic: '60-16-13',
);

/// Pins the logical viewport to [size] for the duration of the test, so the
/// widths below are the widths the widget actually lays out at.
void _useViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _host(
  Widget child, {
  BankPreset preset = BankPreset.studio,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1.0,
}) =>
    BankUiScope(
      initialData: BankUiScopeData(preset: preset),
      child: MaterialApp(
        theme: preset.apply(
          brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
        ),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: textDirection,
              child: Scaffold(body: child),
            ),
          ),
        ),
      ),
    );

/// True when [finder]'s paragraph had to drop glyphs to fit.
bool _isTruncated(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

/// How far the account card's back face can be scrolled — `0` when the face
/// fits, which is the resting case the card is designed around.
double _scrollExtent(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(BankHorizontalAccountCard),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .maxScrollExtent;

/// A card wrapped in the page margins a phone home screen would give it.
Widget _insightPage({
  bool showConfidence = true,
  VoidCallback? onDismiss,
}) =>
    ListView(
      padding: const EdgeInsets.all(BankTokens.space4),
      children: <Widget>[
        BankInsightCard(
          insight: _insight,
          onAction: () {},
          onDismiss: onDismiss,
          showConfidence: showConfidence,
        ),
      ],
    );

void main() {
  group('BankInsightCard action row', () {
    // NOTE ON WIDTHS: the harness registers the brand faces under an
    // unprefixed family name, so kit text lays out in the fallback test font,
    // whose glyphs are one em wide — roughly double the real advance widths
    // the component was sized against. The geometric assertions below are
    // therefore written as *relations* between the meter, the button and the
    // row (which hold in any font) rather than as pixel budgets; the
    // truncation assertions use a viewport wide enough for the test font.

    testWidgets('the meter takes the row\'s whole slack at 360 pt',
        (tester) async {
      _useViewport(tester, const Size(360, 800));

      await tester.pumpWidget(_host(_insightPage(onDismiss: () {})));
      await tester.pumpAndSettle();

      // No RenderFlex overflow was reported while laying the row out.
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(BankInsightCard));
      final button = tester.getRect(find.byType(TextButton));
      final meter = tester.getRect(find.bySemanticsLabel('Insight confidence'));

      // The defect: a `Spacer` beside the meter's `Flexible` split the free
      // space in two, so the meter was capped at half of it and an empty gap
      // sat between the (ellipsized) wording and the button. The meter must
      // instead run from the content edge all the way to the button.
      expect(
        meter.left,
        closeTo(card.left + BankTokens.space4, 0.5),
        reason: 'the meter should start at the content edge',
      );
      expect(
        meter.right,
        closeTo(button.left, 0.5),
        reason: 'an empty Spacer was left between the meter and the button',
      );
      expect(
        meter.width + button.width,
        closeTo(card.width - 2 * BankTokens.space4, 0.5),
        reason: 'the meter did not receive the row\'s full free space',
      );
    });

    testWidgets('confidence wording is never ellipsized when the row has room',
        (tester) async {
      // Wide enough that the meter's natural width fits beside the button
      // even in the harness's double-width test font.
      _useViewport(tester, const Size(560, 800));

      await tester.pumpWidget(_host(_insightPage(onDismiss: () {})));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final label = find.text('High confidence');
      expect(label, findsOneWidget);
      expect(
        _isTruncated(tester, label),
        isFalse,
        reason: 'the confidence wording was ellipsized inside the action row',
      );

      final withAction = tester.getSize(label).width;

      // Adding the button must not squeeze the wording at all: at this width
      // there is room for both, so the label is the same box it is when the
      // meter owns the whole row.
      await tester.pumpWidget(
        _host(
          ListView(
            padding: const EdgeInsets.all(BankTokens.space4),
            children: <Widget>[
              BankInsightCard(insight: _insight, onDismiss: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.text('High confidence')).width,
        closeTo(withAction, 0.5),
        reason: 'the meter was capped at half the free space by a Spacer',
      );
    });

    testWidgets('the meter keeps the slack in RTL on a flat dark preset',
        (tester) async {
      _useViewport(tester, const Size(560, 800));

      await tester.pumpWidget(
        _host(
          _insightPage(),
          preset: BankPreset.voltage,
          brightness: Brightness.dark,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_isTruncated(tester, find.text('High confidence')), isFalse);

      // Mirrored: the meter now runs from the trailing content edge back to
      // the button, which sits on the left.
      final card = tester.getRect(find.byType(BankInsightCard));
      final button = tester.getRect(find.byType(TextButton));
      final meter = tester.getRect(find.bySemanticsLabel('Insight confidence'));
      expect(meter.right, closeTo(card.right - BankTokens.space4, 0.5));
      expect(meter.left, closeTo(button.right, 0.5));
    });

    testWidgets('the action button still lands on the trailing edge',
        (tester) async {
      _useViewport(tester, const Size(360, 800));

      await tester.pumpWidget(_host(_insightPage()));
      await tester.pumpAndSettle();

      final card = tester.getRect(find.byType(BankInsightCard));
      final button = tester.getRect(find.byType(TextButton));
      expect(
        button.right,
        closeTo(card.right - BankTokens.space4, 0.5),
        reason: 'the button must stay flush with the content edge',
      );
    });

    testWidgets('hiding the meter keeps the button trailing', (tester) async {
      _useViewport(tester, const Size(360, 800));

      await tester.pumpWidget(_host(_insightPage(showConfidence: false)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('High confidence'), findsNothing);

      final card = tester.getRect(find.byType(BankInsightCard));
      final button = tester.getRect(find.byType(TextButton));
      expect(button.right, closeTo(card.right - BankTokens.space4, 0.5));
    });
  });

  group('BankHorizontalAccountCard back face', () {
    Widget narrowCard({double textScale = 1.0}) => _host(
          Padding(
            padding: const EdgeInsets.all(BankTokens.space4),
            child: BankHorizontalAccountCard(
              account: _fullAccount,
              isFlipped: true,
              onFlip: () {},
              trigger: BankFlipTrigger.external,
            ),
          ),
          textScale: textScale,
        );

    testWidgets('IBAN + sort code fit a 320 pt device', (tester) async {
      _useViewport(tester, const Size(320, 700));

      await tester.pumpWidget(narrowCard());
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'the back face overflowed its fixed-ratio box',
      );
      expect(find.text(_fullAccount.ibanOrAccountNumber!), findsOneWidget);
      expect(find.text(_fullAccount.sortCodeOrBic!), findsOneWidget);
      expect(find.text('Tap values to copy'), findsOneWidget);
      // At the default text size the face still fits exactly — the fix must
      // not turn the resting card into a scroller.
      expect(_scrollExtent(tester), 0.0);
    });

    testWidgets('IBAN + sort code fit at text scale 1.3', (tester) async {
      _useViewport(tester, const Size(320, 700));

      await tester.pumpWidget(narrowCard(textScale: 1.3));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'the back face overflowed once the OS text size was raised',
      );
      expect(find.text(_fullAccount.ibanOrAccountNumber!), findsOneWidget);
      expect(find.text(_fullAccount.sortCodeOrBic!), findsOneWidget);
    });

    testWidgets('back face degrades by scrolling, not by overflowing',
        (tester) async {
      _useViewport(tester, const Size(320, 700));

      // Well past the point where the fixed content outgrows the ISO-7810
      // face. (Far past it the row *labels* eventually outgrow the card width
      // too — a horizontal limit of a fixed-ratio face, not the vertical
      // budget this fix is about.)
      await tester.pumpWidget(narrowCard(textScale: 1.4));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'the back face must degrade, not overflow, at large text',
      );

      // The over-budget face is reachable rather than clipped.
      expect(_scrollExtent(tester), greaterThan(0.0));
      expect(find.text('Tap values to copy'), findsOneWidget);
      expect(find.text(_fullAccount.ibanOrAccountNumber!), findsOneWidget);
    });

    testWidgets('a scrolled-back face is still tappable', (tester) async {
      _useViewport(tester, const Size(320, 700));
      final handle = tester.ensureSemantics();
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(narrowCard(textScale: 1.4));
      await tester.pumpAndSettle();

      // The degradation path must stay interactive: the viewport wrapping the
      // face must not swallow the copy row's tap.
      await tester.tap(
        find.bySemanticsLabel(RegExp('^Copy IBAN / Account, ')),
      );
      await tester.pump();
      expect(clipboardText, _fullAccount.ibanOrAccountNumber);
      expect(find.text('IBAN / Account copied'), findsOneWidget);

      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      handle.dispose();
    });

    testWidgets('copy rows keep the 44 px target on a narrow card',
        (tester) async {
      _useViewport(tester, const Size(320, 700));
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(narrowCard());
      await tester.pumpAndSettle();

      for (final label in <String>['IBAN / Account', 'Sort Code / BIC']) {
        final target = find.bySemanticsLabel(
          RegExp('^Copy ${RegExp.escape(label)}, '),
        );
        expect(target, findsOneWidget, reason: 'missing copy target: $label');
        final size = tester.getSize(target);
        expect(size.height, greaterThanOrEqualTo(BankTokens.minTapTarget));
        expect(size.width, greaterThanOrEqualTo(BankTokens.minTapTarget));
      }

      handle.dispose();
    });

    testWidgets('a 340 pt card back is unchanged in RTL on a dark preset',
        (tester) async {
      _useViewport(tester, const Size(400, 800));

      await tester.pumpWidget(
        _host(
          Center(
            child: BankHorizontalAccountCard(
              account: _fullAccount,
              width: 340,
              isFlipped: true,
              onFlip: () {},
              trigger: BankFlipTrigger.external,
            ),
          ),
          preset: BankPreset.voltage,
          brightness: Brightness.dark,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The roomy case still fills the face exactly: nothing to scroll, and
      // the hint stays pinned to the foot of the card.
      expect(_scrollExtent(tester), 0.0);
      final card = tester.getRect(find.byType(BankFlipCard));
      final hint = tester.getRect(find.text('Tap values to copy'));
      expect(hint.bottom, lessThanOrEqualTo(card.bottom));
      expect(
        hint.bottom,
        greaterThan(card.bottom - BankTokens.space5 - BankTokens.space6),
      );
    });
  });
}
