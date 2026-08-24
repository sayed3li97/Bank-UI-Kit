// Accessibility gates for the defects the conformance report would otherwise
// have to disclose: tap targets below the kit's own 44 px floor, input value
// states that encode one thing twice (or nothing at all), and the insight
// card's unlabelled confidence meter.
//
// These are structural assertions, not screenshots: they fail when a control
// shrinks, when a state signal doubles up, or when the meter loses its
// accessible name.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _account = BankAccount(
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

final _insight = BankInsight(
  id: 'i1',
  title: 'Spending is up',
  body: 'You spent 12% more on dining this month.',
  confidence: InsightConfidence.high,
  generatedAt: DateTime(2026, 7),
  isDismissed: false,
);

final _bahrain =
    BankCountry.all.firstWhere((BankCountry c) => c.isoCode == 'BH');

Widget _host(Widget child, {BankPreset preset = BankPreset.studio}) =>
    BankUiScope(
      initialData: BankUiScopeData(preset: preset),
      child: MaterialApp(
        theme: preset.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: child),
      ),
    );

/// Every [AnimatedContainer] box decoration inside an OTP input.
List<BoxDecoration> _otpBoxes(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(BankOtpInput),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .map((AnimatedContainer c) => c.decoration)
    .whereType<BoxDecoration>()
    .toList();

void main() {
  // -------------------------------------------------------------------------
  // Item 72 — tap targets
  // -------------------------------------------------------------------------

  testWidgets('audited controls meet the tap-target + label guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        ListView(
          padding: const EdgeInsets.all(BankTokens.space4),
          children: [
            BankInsightCard(
              insight: _insight,
              onTap: () {},
              onDismiss: () {},
              onAction: () {},
            ),
            const SizedBox(height: BankTokens.space4),
            BankHorizontalAccountCard(
              account: _account,
              width: 340,
              isFlipped: true,
              onFlip: () {},
            ),
            const SizedBox(height: BankTokens.space4),
            BankCountryPicker(
              onSelected: (_) {},
              selected: _bahrain,
              label: 'Country of residence',
            ),
            const SizedBox(height: BankTokens.space4),
            BankAddressPreview(
              address: BankAddress(
                line1: '1 Bank Street',
                city: 'Manama',
                postalCode: '317',
                country: _bahrain,
              ),
              onEdit: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('targets hold up in RTL, in dark, and on a flat preset',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      BankUiScope(
        initialData: const BankUiScopeData(preset: BankPreset.voltage),
        child: MaterialApp(
          theme: BankPreset.voltage.apply(ThemeData.dark(useMaterial3: true)),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(BankTokens.space4),
                children: [
                  BankInsightCard(
                    insight: _insight,
                    onDismiss: () {},
                    onAction: () {},
                  ),
                  const SizedBox(height: BankTokens.space4),
                  BankHorizontalAccountCard(
                    account: _account,
                    width: 340,
                    isFlipped: true,
                    onFlip: () {},
                  ),
                  const SizedBox(height: BankTokens.space4),
                  BankOtpInput(
                    onCompleted: (_) {},
                    onResend: () {},
                    resendCooldown: Duration.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('insight dismiss grows the hit area, not the glyph',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: BankInsightCard(insight: _insight, onDismiss: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final target = find.ancestor(
      of: find.byIcon(Icons.close),
      matching: find.byType(SizedBox),
    );
    final size = tester.getSize(target.first);
    expect(size.width, greaterThanOrEqualTo(BankTokens.minTapTarget));
    expect(size.height, greaterThanOrEqualTo(BankTokens.minTapTarget));

    // The glyph itself must not have been inflated to get there.
    expect(
      tester.widget<Icon>(find.byIcon(Icons.close)).size,
      BankTokens.iconSmall,
    );
  });

  testWidgets('IBAN copy is a full-size target that confirms the copy',
      (tester) async {
    final handle = tester.ensureSemantics();

    // Capture both the clipboard write and the assistive-tech announcement.
    final announcements = <Object?>[];
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
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (Object? message) async {
        announcements.add(message);
        return null;
      },
    );

    await tester.pumpWidget(
      _host(
        Center(
          child: BankHorizontalAccountCard(
            account: _account,
            width: 340,
            isFlipped: true,
            onFlip: () {},
            trigger: BankFlipTrigger.external,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iban = RegExp.escape(_account.ibanOrAccountNumber!);
    final copyTarget = find.bySemanticsLabel(
      RegExp('^Copy IBAN / Account, $iban'),
    );
    expect(copyTarget, findsOneWidget);
    final size = tester.getSize(copyTarget);
    expect(size.width, greaterThanOrEqualTo(BankTokens.minTapTarget));
    expect(size.height, greaterThanOrEqualTo(BankTokens.minTapTarget));

    await tester.tap(copyTarget);
    await tester.pump();

    expect(clipboardText, _account.ibanOrAccountNumber);
    // Perceivable: the hint slot turns into a confirmation …
    expect(find.text('IBAN / Account copied'), findsOneWidget);
    // … and the same sentence reaches assistive technology.
    expect(announcements, isNotEmpty);
    expect(
      announcements.map((Object? m) => m.toString()).join(),
      contains('IBAN / Account copied'),
    );

    // The confirmation is temporary, not a new resting state.
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('IBAN / Account copied'), findsNothing);
    expect(find.text('Tap values to copy'), findsOneWidget);

    tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, null)
      ..setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        null,
      );
    handle.dispose();
  });

  // -------------------------------------------------------------------------
  // Item 70 — value states
  // -------------------------------------------------------------------------

  testWidgets('OTP encodes focus once and keeps the fill stable',
      (tester) async {
    await tester.pumpWidget(
      _host(Center(child: BankOtpInput(onCompleted: (_) {}))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();

    final boxes = _otpBoxes(tester);
    expect(boxes, hasLength(6));

    // Fill: identical for empty, filled, and active boxes.
    expect(boxes.map((BoxDecoration d) => d.color).toSet(), hasLength(1));

    // Border: identical too — focus must not also swap the outline.
    final borders =
        boxes.map((BoxDecoration d) => d.border! as Border).toList();
    expect(borders.map((Border b) => b.top.color).toSet(), hasLength(1));
    expect(borders.map((Border b) => b.top.width).toSet(), {
      BankTokens.hairlineWidth,
    });

    // Exactly one signal, on exactly one box: the focus ring.
    final rings = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(BankOtpInput),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .toList();
    expect(rings, hasLength(6));
    expect(rings.where((AnimatedOpacity o) => o.opacity == 1), hasLength(1));

    // Filled boxes are told apart by their digit, never by colour.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('OTP error state is distinguishable without colour',
      (tester) async {
    await tester.pumpWidget(
      _host(Center(child: BankOtpInput(onCompleted: (_) {}))),
    );
    await tester.pumpAndSettle();
    final restingWidth = (_otpBoxes(tester).first.border! as Border).top.width;

    await tester.pumpWidget(
      _host(Center(child: BankOtpInput(onCompleted: (_) {}, error: true))),
    );
    await tester.pumpAndSettle();

    final errored = _otpBoxes(tester)
        .map((BoxDecoration d) => d.border! as Border)
        .toList();
    expect(errored, hasLength(6));
    for (final border in errored) {
      expect(border.top.color, BankTokens.danger);
      expect(border.top.width, BankTokens.focusRingWidth);
      expect(border.top.width, greaterThan(restingWidth));
    }
  });

  testWidgets('picker values are typographically distinct from placeholders',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            BankCountryPicker(onSelected: (_) {}, selected: _bahrain),
            BankCountryPicker(onSelected: (_) {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final value = tester.widget<Text>(find.text(_bahrain.name)).style!;
    final placeholder = tester.widget<Text>(find.text('Select country')).style!;

    expect(value.fontWeight, FontWeight.w600);
    expect(placeholder.fontWeight, FontWeight.w400);
    expect(value.color, isNot(placeholder.color));
  });

  testWidgets('region dropdown shows a placeholder until a value is picked',
      (tester) async {
    final us = BankCountry.all.firstWhere((BankCountry c) => c.isoCode == 'US');
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: BankAddressForm(onChanged: (_) {}, defaultCountry: us),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Item 60 — confidence indicator
  // -------------------------------------------------------------------------

  testWidgets('confidence meter is labelled, valued, and spelled out',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(Center(child: BankInsightCard(insight: _insight))),
    );
    await tester.pumpAndSettle();

    // A visible text equivalent, so three marks are never the only encoding.
    expect(find.text('High confidence'), findsOneWidget);

    final node = tester.getSemantics(
      find.bySemanticsLabel('Insight confidence'),
    );
    expect(node.label, 'Insight confidence');
    expect(node.value, 'High confidence');

    handle.dispose();
  });

  testWidgets('confidence wording tracks the level', (tester) async {
    for (final (InsightConfidence confidence, String expected) in const [
      (InsightConfidence.high, 'High confidence'),
      (InsightConfidence.medium, 'Medium confidence'),
      (InsightConfidence.low, 'Low confidence'),
    ]) {
      await tester.pumpWidget(
        _host(
          Center(
            child: BankInsightCard(
              insight: BankInsight(
                id: 'i',
                title: 'Title',
                body: 'Body',
                confidence: confidence,
                generatedAt: DateTime(2026, 7),
                isDismissed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    }
  });
}
