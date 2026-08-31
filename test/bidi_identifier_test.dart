import 'dart:ui' as ui;

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// LEFT-TO-RIGHT ISOLATE / POP DIRECTIONAL ISOLATE, spelled out here so the
/// expectations below stay readable in an editor that would otherwise
/// render them as nothing at all.
const String lri = '\u2066';
const String pdi = '\u2069';

const String panRaw = '4532123456789012';
const String panGrouped = '4532 1234 5678 9012';
const String ibanRaw = 'SA0380000000608010167519';

/// The left edge of the first box covering [needle] inside [text], laid out
/// as a paragraph running [direction].
///
/// This is the whole test: bidi reordering is a *visual* property, so the
/// only honest assertion is where the glyphs land. Comparing the first
/// group's x against the last group's tells us whether the reader sees the
/// identifier in the order it was written.
double _xOf(
  String text,
  String needle,
  ui.TextDirection direction, {
  bool last = false,
}) {
  final start = last ? text.lastIndexOf(needle) : text.indexOf(needle);
  expect(start, isNonNegative, reason: 'no "$needle" in "$text"');
  final paragraph = (ui.ParagraphBuilder(
    ui.ParagraphStyle(textDirection: direction, fontSize: 20),
  )..addText(text))
      .build()
    ..layout(const ui.ParagraphConstraints(width: 2000));
  final boxes = paragraph.getBoxesForRange(start, start + needle.length);
  expect(boxes, isNotEmpty, reason: 'no boxes for "$needle" in "$text"');
  return boxes.first.left;
}

/// Whether [first] is painted to the left of [last] when [text] is laid out
/// in [direction] — i.e. whether the groups keep their written order.
bool _inOrder(
  String text,
  ui.TextDirection direction, {
  required String first,
  required String last,
}) =>
    _xOf(text, first, direction) < _xOf(text, last, direction, last: true);

void main() {
  group('paragraph order', () {
    test('an unisolated PAN reverses its groups in an RTL paragraph', () {
      // The defect this file exists for, asserted directly: UAX #9 N1 gives
      // the gap between two numbers an R resolution, and L2 then reverses
      // the run. The customer reads 9012 5678 1234 4532 — a wrong card
      // number, rendered without a single broken-looking glyph.
      final grouped = BankAccountNumberFormatter.format(
        panRaw,
        BankAccountNumberKind.pan,
      );
      expect(grouped, panGrouped);
      expect(
        _inOrder(
          grouped,
          ui.TextDirection.rtl,
          first: '4532',
          last: '9012',
        ),
        isFalse,
      );
    });

    test('an isolated PAN keeps its groups in written order', () {
      final display = BankAccountNumberFormatter.format(
        panRaw,
        BankAccountNumberKind.pan,
        bidiIsolate: true,
      );
      expect(display, '$lri$panGrouped$pdi');
      for (final direction in ui.TextDirection.values) {
        expect(
          _inOrder(display, direction, first: '4532', last: '9012'),
          isTrue,
          reason: 'PAN groups swapped in a ${direction.name} paragraph',
        );
      }
    });

    test('an isolated masked PAN keeps its bullets ahead of the last four', () {
      final display = BankAccountNumberFormatter.mask(
        panRaw,
        BankAccountNumberKind.pan,
        bidiIsolate: true,
      );
      expect(display, '$lri•••• •••• •••• 9012$pdi');
      expect(
        _inOrder(display, ui.TextDirection.rtl, first: '••••', last: '9012'),
        isTrue,
      );
    });

    test(
        'a sort code reverses inside Arabic copy, and holds inside an '
        'isolate', () {
      final sortCode = BankAccountNumberFormatter.format(
        '204545',
        BankAccountNumberKind.sortCode,
      );
      expect(sortCode, '20-45-45');

      // Alone, a sort code is safe: the hyphen is a European Separator and
      // W4 folds `EN ES EN` into one number. Next to an Arabic letter it is
      // not: W2 retypes the digits as Arabic numbers, the hyphen is left a
      // plain neutral between them, and N1 flips it to R.
      expect(
        _inOrder(
          'الرمز $sortCode هنا',
          ui.TextDirection.rtl,
          first: '20',
          last: '45',
        ),
        isFalse,
      );

      final isolated = BankAccountNumberFormatter.format(
        '204545',
        BankAccountNumberKind.sortCode,
        bidiIsolate: true,
      );
      expect(
        _inOrder(
          'الرمز $isolated هنا',
          ui.TextDirection.rtl,
          first: '20',
          last: '45',
        ),
        isTrue,
      );
    });

    test('a grouped phone number needs its paragraph pinned', () {
      // BankPhoneInputField cannot isolate its buffer — the controls would
      // be selected and copied — so it pins the paragraph instead. Both
      // halves of that claim, measured.
      const grouped = '555 123 4567';
      expect(
        _inOrder(
          grouped,
          ui.TextDirection.rtl,
          first: '555',
          last: '4567',
        ),
        isFalse,
      );
      expect(
        _inOrder(
          grouped,
          ui.TextDirection.ltr,
          first: '555',
          last: '4567',
        ),
        isTrue,
      );
    });

    test('an IBAN was already anchored by its country code', () {
      // The control: `SA` is a strong L, so W7 retypes every digit after it
      // and the run never reverses. The isolate changes nothing here, which
      // is exactly why the kit applies it unconditionally instead of
      // sniffing values for letters.
      final plain = BankAccountNumberFormatter.format(
        ibanRaw,
        BankAccountNumberKind.iban,
      );
      final isolated = BankAccountNumberFormatter.format(
        ibanRaw,
        BankAccountNumberKind.iban,
        bidiIsolate: true,
      );
      for (final text in [plain, isolated]) {
        expect(
          _inOrder(
            text,
            ui.TextDirection.rtl,
            first: 'SA03',
            last: '7519',
          ),
          isTrue,
        );
      }
    });

    test('Arabic-Indic digits reverse whatever the markup says', () {
      // Why identifiers are exempt from NumeralStyle rather than isolated
      // and converted: U+0660-U+0669 are bidi class AN, W7 only retypes EN,
      // so the groups swap inside an isolate and inside an LTR paragraph
      // too. There is no directional markup that repairs this.
      final converted = NumeralStyle.easternArabicIndic.convert(panGrouped);
      for (final text in [converted, '$lri$converted$pdi']) {
        for (final direction in ui.TextDirection.values) {
          expect(
            _inOrder(
              text,
              direction,
              first: '٤٥٣٢',
              last: '٩٠١٢',
            ),
            isFalse,
            reason: 'AN digits cannot be rescued by an isolate',
          );
        }
      }
    });
  });

  group('BankAccountNumberFormatter', () {
    test('the default output is byte-clean', () {
      for (final kind in BankAccountNumberKind.values) {
        final formatted = BankAccountNumberFormatter.format(panRaw, kind);
        final masked = BankAccountNumberFormatter.mask(panRaw, kind);
        expect(formatted, isNot(contains(lri)));
        expect(formatted, isNot(contains(pdi)));
        expect(masked, isNot(contains(lri)));
        expect(masked, isNot(contains(pdi)));
      }
    });

    test('normalize strips isolates that arrive with the value', () {
      // A host that reads a displayed value back into the widget must not
      // smuggle the controls onto the clipboard on the round trip.
      final display = BankAccountNumberFormatter.format(
        panRaw,
        BankAccountNumberKind.pan,
        bidiIsolate: true,
      );
      expect(BankAccountNumberFormatter.normalize(display), panRaw);
    });
  });

  group('BankAccountNumberText', () {
    Widget host(
      Widget child, {
      NumeralStyle numeralStyle = NumeralStyle.western,
    }) {
      return BankUiScope(
        initialData: BankUiScopeData(numeralStyle: numeralStyle),
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      );
    }

    testWidgets('displays an isolated identifier and copies a clean one',
        (tester) async {
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
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        host(
          const BankAccountNumberText(
            value: panRaw,
            kind: BankAccountNumberKind.pan,
          ),
        ),
      );

      final displayed = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data)
          .whereType<String>()
          .firstWhere((String data) => data.contains('9012'));
      expect(displayed, '$lri$panGrouped$pdi');

      await tester.tap(find.byType(InkResponse));
      await tester.pump();

      expect(clipboardText, panRaw);
      expect(clipboardText, isNot(contains(lri)));
      expect(clipboardText, isNot(contains(pdi)));
    });

    testWidgets(
        'keeps identifier digits Western under an Arabic numeral '
        'style', (tester) async {
      await tester.pumpWidget(
        host(
          const BankAccountNumberText(
            value: panRaw,
            kind: BankAccountNumberKind.pan,
            copyEnabled: false,
          ),
          numeralStyle: NumeralStyle.easternArabicIndic,
        ),
      );

      final displayed = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data)
          .whereType<String>()
          .firstWhere((String data) => data.contains('9012'));
      expect(displayed, '$lri$panGrouped$pdi');
      expect(displayed, isNot(contains('٩')));
    });
  });

  group('BankPhoneInputField', () {
    Widget host({NumeralStyle numeralStyle = NumeralStyle.western}) {
      return BankUiScope(
        initialData: BankUiScopeData(numeralStyle: numeralStyle),
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: BankPhoneInputField(onChanged: (_, __) {}),
            ),
          ),
        ),
      );
    }

    testWidgets('pins its editable paragraph and keeps the buffer clean',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.enterText(find.byType(TextField), '5551234567');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);

      final text = field.controller!.text;
      expect(text, '555 123 4567');
      expect(text, isNot(contains(lri)));
      expect(text, isNot(contains(pdi)));
    });

    testWidgets('folds Arabic-Indic input to Western digits', (tester) async {
      await tester.pumpWidget(
        host(numeralStyle: NumeralStyle.easternArabicIndic),
      );
      await tester.enterText(find.byType(TextField), '٥٥٥١٢٣٤٥٦٧');
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '555 123 4567',
      );
    });

    testWidgets('isolates the dial code', (tester) async {
      await tester.pumpWidget(host());
      final dialCode = BankCountry.all.first.dialCode;
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => t.data)
            .whereType<String>()
            .where((String data) => data.contains(dialCode)),
        contains('$lri$dialCode$pdi'),
      );
    });
  });

  testWidgets('the gate screen support number keeps its group order in RTL',
      (tester) async {
    // Caught by looking at an Arabic screenshot: `+973 1758 3300` rendered
    // as `3300 1758 973+`, which dials nothing. The row is a plain Text in a
    // paragraph the ambient direction owns, so it needs the isolate rather
    // than a pinned direction.
    const number = '+973 1758 3300';
    await tester.pumpWidget(
      BankUiScope(
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: BankAppGateScreen.maintenance(supportPhoneLabel: number),
          ),
        ),
      ),
    );
    await tester.pump();

    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((d) => d.contains('973'));
    expect(rendered, '\u2066$number\u2069');

    // The spoken label is the clean number: a screen reader must never meet
    // the control characters, which it would if the row simply let the
    // isolated Text speak for itself.
    final labels = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text(rendered),
            matching: find.byType(Semantics),
          ),
        )
        .map((s) => s.properties.label)
        .whereType<String>()
        .where((l) => l.isNotEmpty);
    expect(labels, contains(number));
    expect(labels.any((l) => l.contains('\u2066')), isFalse);
  });
}
