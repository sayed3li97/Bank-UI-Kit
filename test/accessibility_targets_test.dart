// Accessibility gates for the defects the conformance report would otherwise
// have to disclose: tap targets below the kit's own 44 px floor, input value
// states that encode one thing twice (or nothing at all), and the insight
// card's unlabelled confidence meter.
//
// These are structural assertions, not screenshots: they fail when a control
// shrinks, when a state signal doubles up, or when the meter loses its
// accessible name.
import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

/// The slider nodes assistive technology actually receives.
///
/// A node that merges its descendants is where the merge stops: its data
/// already carries the framework slider's role, value, and actions, so
/// descending past it would count the same control twice.
List<SemanticsData> _sliderNodes(WidgetTester tester) {
  final nodes = <SemanticsData>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.flagsCollection.isSlider) {
      nodes.add(data);
      return;
    }
    if (node.mergeAllDescendantsIntoThisNode) return;
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return nodes;
}

/// The data of the first semantics node whose label contains [needle].
SemanticsData _nodeLabelled(WidgetTester tester, String needle) {
  SemanticsData? found;
  void visit(SemanticsNode node) {
    if (found != null) return;
    final data = node.getSemanticsData();
    if (data.label.contains(needle)) {
      found = data;
      return;
    }
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return found ?? (throw StateError('no semantics node mentions "$needle"'));
}

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

  testWidgets('consent tick boxes are targets in their own right',
      (tester) async {
    final handle = tester.ensureSemantics();

    final surfaces = <String, Widget>{
      'BankConsentModal': BankConsentModal(
        title: 'Terms of service',
        termsContent: 'You agree to the terms.',
        onAccept: () {},
        onDecline: () {},
      ),
      'BankDisclosureConsentSheet': BankDisclosureConsentSheet(
        disclosures: const [
          BankDisclosure(
            title: 'Representative example',
            body: 'Borrow 10,000 over 48 months at 5.9% APR.',
            required: true,
          ),
        ],
        consents: const [
          BankConsentItem(
            id: 'terms',
            label: 'I agree to the loan terms',
            required: true,
          ),
        ],
        onChanged: (_) {},
        onAgree: () {},
      ),
    };

    for (final entry in surfaces.entries) {
      await tester.pumpWidget(_host(Center(child: entry.value)));
      await tester.pumpAndSettle();

      // The box carries `onChanged` itself, so it is an independently
      // tappable node and owes the floor on its own — the enclosing row
      // meeting it is not enough.
      final box = tester.getSize(find.byType(Checkbox));
      expect(
        box.width,
        greaterThanOrEqualTo(BankTokens.minTapTarget),
        reason: '${entry.key} tick box is narrower than the floor',
      );
      expect(
        box.height,
        greaterThanOrEqualTo(BankTokens.minTapTarget),
        reason: '${entry.key} tick box is shorter than the floor',
      );

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    }

    handle.dispose();
  });

  testWidgets('a consent gate that cannot be ticked yet reads as disabled',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: BankConsentModal(
            title: 'Terms of service',
            termsContent: 'You agree to the terms.',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final side = CheckboxTheme.of(tester.element(find.byType(Checkbox))).side;
    // A plain BorderSide is handed back verbatim for every unselected state,
    // which is what erased the disabled outline: the box the user cannot tick
    // painted at exactly the strength of one they can.
    expect(side, isA<WidgetStateBorderSide>());
    final resolvable = side! as WidgetStateBorderSide;
    final enabled = resolvable.resolve(<WidgetState>{});
    final disabled = resolvable.resolve(<WidgetState>{WidgetState.disabled});
    expect(disabled!.color, isNot(enabled!.color));
    expect(
      disabled.color.a,
      lessThan(enabled.color.a),
      reason: 'the disabled outline must be the faded one',
    );
    expect(disabled.width, enabled.width);
  });

  // -------------------------------------------------------------------------
  // Item 74 — sliders stay adjustable
  // -------------------------------------------------------------------------

  testWidgets('kit sliders keep the role, the value, and both adjustments',
      (tester) async {
    final handle = tester.ensureSemantics();

    final sliders = <String, Widget>{
      'BankCardControlsPanel': BankCardControlsPanel(
        isFrozen: false,
        isOnlinePaymentsEnabled: true,
        isContactlessEnabled: true,
        isInternationalEnabled: false,
        onFreezeChanged: (_) {},
        onOnlinePaymentsChanged: (_) {},
        onContactlessChanged: (_) {},
        onInternationalChanged: (_) {},
        spendLimit: 2000,
        maxSpendLimit: 5000,
        onSpendLimitChanged: (_) {},
      ),
      'BankCreditLimitAdjuster': BankCreditLimitAdjuster(
        currentLimit: Money.fromDouble(4500, 'GBP'),
        maxApproved: Money.fromDouble(8000, 'GBP'),
        used: Money.fromDouble(1250, 'GBP'),
        onCommit: (_) async => true,
      ),
      'BankTransferLimitManager': BankTransferLimitManager(
        channels: [
          BankLimitChannel(
            id: 'atm',
            label: 'ATM withdrawals',
            icon: Icons.atm_outlined,
            current: Money.fromDouble(500, 'GBP'),
            max: Money.fromDouble(2000, 'GBP'),
            used: Money.fromDouble(120, 'GBP'),
          ),
        ],
        onChanged: (_, __) {},
      ),
    };

    for (final entry in sliders.entries) {
      await tester.pumpWidget(
        _host(SingleChildScrollView(child: entry.value)),
      );
      await tester.pumpAndSettle();

      final nodes = _sliderNodes(tester);
      expect(
        nodes,
        hasLength(1),
        reason: '${entry.key} lost the framework slider node',
      );
      final node = nodes.single;
      expect(
        node.label,
        isNotEmpty,
        reason: '${entry.key} slider has no accessible name',
      );
      expect(
        node.value,
        isNotEmpty,
        reason: '${entry.key} slider announces no value',
      );
      expect(
        node.hasAction(SemanticsAction.increase),
        isTrue,
        reason: '${entry.key} cannot be raised by assistive technology',
      );
      expect(
        node.hasAction(SemanticsAction.decrease),
        isTrue,
        reason: '${entry.key} cannot be lowered by assistive technology',
      );
      // The adjustment previews are the values the control would land on,
      // never the framework's fallback percentage of the track.
      expect(node.increasedValue, isNotEmpty);
      expect(node.decreasedValue, isNotEmpty);
      expect(node.increasedValue, isNot(node.decreasedValue));
    }

    handle.dispose();
  });

  testWidgets('card control toggles can be operated, not only read',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: BankCardControlsPanel(
            isFrozen: false,
            isOnlinePaymentsEnabled: true,
            isContactlessEnabled: true,
            isInternationalEnabled: false,
            onFreezeChanged: (_) {},
            onOnlinePaymentsChanged: (_) {},
            onContactlessChanged: (_) {},
            onInternationalChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Excluding the row's whole subtree took the tap action with it, so the
    // freeze toggle announced its state and offered no way to change it.
    final freeze = _nodeLabelled(tester, 'Freeze card');
    expect(freeze.value, 'disabled');
    expect(
      freeze.hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'the freeze toggle cannot be flipped by assistive technology',
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
