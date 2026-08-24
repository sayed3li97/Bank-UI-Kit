// Audit items 74 (stock Material controls sit unthemed inside branded
// screens) and 75 (CTA microcopy casing).
//
// Item 74: Switch, Slider, and Checkbox take their defaults from
// ThemeData.colorScheme, never from BankThemeData, so an unpatched control
// renders in Material's own palette on every preset. These tests assert the
// resolved control theme at the control's own BuildContext — both halves of
// the control, because the *off* state is where the stock grey used to
// survive — and that no stock SegmentedButton is left in the kit.
//
// Item 75: default CTA labels are sentence case kit-wide.
import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  BankPreset preset = BankPreset.studio,
  Brightness brightness = Brightness.light,
}) =>
    BankUiScope(
      child: MaterialApp(
        theme: preset.apply(
          brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

BankThemeData _bankThemeOf(WidgetTester tester, Finder finder) =>
    BankThemeData.of(tester.element(finder));

Widget _controlsPanel() => BankCardControlsPanel(
      isFrozen: false,
      isOnlinePaymentsEnabled: true,
      isContactlessEnabled: true,
      isInternationalEnabled: false,
      onFreezeChanged: (_) {},
      onOnlinePaymentsChanged: (_) {},
      onContactlessChanged: (_) {},
      onInternationalChanged: (_) {},
      spendLimit: 500,
      onSpendLimitChanged: (_) {},
    );

void main() {
  group('item 74 — Material controls are on the brand palette', () {
    testWidgets('switch resolves both halves from BankThemeData', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_controlsPanel()));

      final switchFinder = find.byType(Switch).first;
      final bank = _bankThemeOf(tester, switchFinder);
      final data = SwitchTheme.of(tester.element(switchFinder));

      expect(
        data.trackColor?.resolve({WidgetState.selected}),
        bank.primary,
        reason: 'the on track must be the brand primary, not Material\'s',
      );
      expect(
        data.thumbColor?.resolve({WidgetState.selected}),
        bank.onPrimary,
      );

      // The off state is the half that used to stay stock grey.
      final offTrack = data.trackColor?.resolve(const {});
      expect(offTrack, isNotNull);
      expect(offTrack!.a, closeTo(BankTokens.alphaMuted, 0.001));
      expect(
        [offTrack.r, offTrack.g, offTrack.b],
        [bank.onSurface.r, bank.onSurface.g, bank.onSurface.b],
        reason: 'the off groove must be ambient ink, not a fixed grey',
      );
      expect(data.thumbColor?.resolve(const {}), bank.onSurfaceVariant);
    });

    testWidgets('switch tracks the preset in light and dark', (tester) async {
      for (final preset in BankPreset.values) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _host(_controlsPanel(), preset: preset, brightness: brightness),
          );
          final switchFinder = find.byType(Switch).first;
          final bank = _bankThemeOf(tester, switchFinder);
          expect(
            SwitchTheme.of(
              tester.element(switchFinder),
            ).trackColor?.resolve({WidgetState.selected}),
            bank.primary,
            reason: '${preset.name}/${brightness.name} switch is off-brand',
          );
        }
      }
    });

    testWidgets('slider resolves track, thumb, and tick marks', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_controlsPanel()));

      final sliderFinder = find.byType(Slider).first;
      final bank = _bankThemeOf(tester, sliderFinder);
      final data = SliderTheme.of(tester.element(sliderFinder));

      expect(data.activeTrackColor, bank.primary);
      expect(data.thumbColor, bank.primary);
      expect(data.valueIndicatorColor, bank.primary);
      // Divisions draw tick marks; unthemed they land in Material's ink.
      expect(data.activeTickMarkColor, isNotNull);
      expect(data.inactiveTickMarkColor, isNotNull);

      final inactive = data.inactiveTrackColor;
      expect(inactive, isNotNull);
      expect(inactive!.a, closeTo(BankTokens.alphaMuted, 0.001));
    });

    testWidgets('slider honours a caller-supplied groove', (tester) async {
      await tester.pumpWidget(
        _host(
          BankTransferLimitManager(
            channels: [
              BankLimitChannel(
                id: 'atm',
                label: 'ATM withdrawals',
                icon: Icons.atm_outlined,
                current: Money.fromDouble(500, 'BHD'),
                max: Money.fromDouble(2000, 'BHD'),
                used: Money.fromDouble(120, 'BHD'),
              ),
            ],
            onChanged: (_, __) {},
          ),
        ),
      );

      final sliderFinder = find.byType(Slider).first;
      final bank = _bankThemeOf(tester, sliderFinder);
      final data = SliderTheme.of(tester.element(sliderFinder));

      expect(data.activeTrackColor, bank.primary);
      expect(
        data.inactiveTrackColor,
        bank.surfaceVariant,
        reason: 'this groove sits under a progress bar and must match it',
      );
    });

    testWidgets('checkbox fills with the brand and outlines when unticked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          BankConsentModal(
            title: 'Terms',
            termsContent: 'Terms body',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      );

      final boxFinder = find.byType(Checkbox).first;
      final bank = _bankThemeOf(tester, boxFinder);
      final data = CheckboxTheme.of(tester.element(boxFinder));

      expect(data.fillColor?.resolve({WidgetState.selected}), bank.primary);
      expect(data.fillColor?.resolve(const {}), Colors.transparent);
      expect(data.checkColor?.resolve({WidgetState.selected}), bank.onPrimary);
      expect(
        data.side?.color,
        bank.onSurfaceVariant,
        reason: 'an unticked box outlined in the hairline colour is invisible',
      );
    });

    testWidgets('segmented selectors use BankSegmentedControl, not the M3 one',
        (tester) async {
      Future<void> expectBranded(Widget widget) async {
        await tester.pumpWidget(_host(widget));
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString().startsWith('SegmentedButton<'),
          ),
          findsNothing,
          reason: 'the M3 segmented control ships an unthemed check glyph',
        );
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString().startsWith('BankSegmentedControl<'),
          ),
          findsWidgets,
        );
      }

      await expectBranded(
        BankScheduledTransferToggle(
          selected: BankTransferTiming.instant,
          onChanged: (_) {},
        ),
      );
      await expectBranded(
        BankBuySellSheet(
          quote: AssetQuote(
            symbol: 'AAPL',
            name: 'Apple',
            price: Money.fromDouble(190, 'USD'),
            changePercent: 1.2,
          ),
          allowLimitOrder: true,
        ),
      );
    });

    testWidgets('segmented selectors survive an unbounded-height parent', (
      tester,
    ) async {
      // A Column inside a SingleChildScrollView is the commonest host for a
      // form, and it hands its children an infinite height budget.
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              BankScheduledTransferToggle(
                selected: BankTransferTiming.later,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('segment glyphs survive the migration', (tester) async {
      await tester.pumpWidget(
        _host(
          BankScheduledTransferToggle(
            selected: BankTransferTiming.instant,
            onChanged: (_) {},
          ),
        ),
      );

      // The public *Icon params must still reach the screen.
      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });
  });

  group('item 75 — default CTA copy is sentence case', () {
    // Words that legitimately keep an interior capital: acronyms, brands, and
    // proper nouns. Everything else must be lower case after the first word.
    final allowed = RegExp('^(PIN|APR|IBAN|NFC|BIC|ID|Apple|Google|Shariah|'
        'Sadaqah|Zakat)');

    void expectSentenceCase(String label) {
      final words = label.split(RegExp(r'[\s/]+'));
      for (final word in words.skip(1)) {
        if (word.isEmpty || allowed.hasMatch(word)) continue;
        expect(
          word[0] == word[0].toLowerCase(),
          isTrue,
          reason: '"$label" is Title Case; the kit is sentence case',
        );
      }
    }

    test('BankUiStrings defaults', () {
      const s = BankUiStrings.defaults;
      for (final label in [
        s.sendMoney,
        s.requestMoney,
        s.addMoney,
        s.sessionTimeout,
        s.contactSupport,
        s.transferSuccess,
        s.transferFailure,
        s.interestRate,
        s.profitRate,
        s.profitRateAbbr,
        s.addToPot,
        s.withdrawFromPot,
        s.splitEqually,
        s.newDevice,
        s.compromisedDevice,
        s.verificationUnderReview,
        s.interestFree,
        s.noTransactions,
      ]) {
        expectSentenceCase(label);
      }
      // Spot-check the exact strings so a silent re-capitalisation fails here.
      expect(s.sendMoney, 'Send money');
      expect(s.addToPot, 'Add to pot');
      expect(s.verificationUnderReview, 'Verification under review');
    });

    test('widget constructor defaults', () {
      const panel = BankCardControlsPanel(
        isFrozen: false,
        isOnlinePaymentsEnabled: true,
        isContactlessEnabled: true,
        isInternationalEnabled: true,
        onFreezeChanged: _noop,
        onOnlinePaymentsChanged: _noop,
        onContactlessChanged: _noop,
        onInternationalChanged: _noop,
      );
      for (final label in [
        panel.freezeLabel,
        panel.onlinePaymentsLabel,
        panel.contactlessLabel,
        panel.internationalLabel,
        panel.spendLimitLabel,
        panel.changePinLabel,
        panel.reportLostOrStolenLabel,
      ]) {
        expectSentenceCase(label);
      }
      expect(panel.reportLostOrStolenLabel, 'Report lost or stolen');
      // The acronym allow-list must not be a licence to Title Case.
      expect(panel.changePinLabel, 'Change PIN');
    });
  });
}

void _noop(bool _) {}
