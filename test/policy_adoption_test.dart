// Adoption gates for the two brand policies that live on BankThemeData but
// only exist if the *widgets* consult them.
//
// Both were shipped as theme API, wired through toJson/lerp/==, announced in
// the CHANGELOG — and then read by nothing, so a preset that set them
// rendered pixel-identically to one that did not. These tests assert on the
// painted decorations of a rendered tree rather than on the theme methods
// (test/design_tokens_test.dart already covers those), so a widget that goes
// back to reading `theme.accentGradient` or `BankTokens.shadow*` raw fails
// CI instead of silently reopening the seam.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child,
  BankPreset preset, {
  required Brightness brightness,
}) {
  return BankUiScope(
    initialData: BankUiScopeData(preset: preset),
    child: MaterialApp(
      theme: preset.apply(
        brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true),
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

final _account = BankAccount(
  id: 'a1',
  name: 'Everyday',
  maskedNumber: '•••• 4291',
  balance: Money.fromDouble(1234.56, 'GBP'),
  status: BankAccountStatus.active,
  type: BankAccountType.current,
  currencyCode: 'GBP',
);

List<BankQuickAction> get _actions => [
      BankQuickAction(
        id: 'send',
        icon: Icons.send_rounded,
        label: 'Send',
        onTap: () {},
      ),
    ];

/// Every [BoxDecoration] painted anywhere under [root].
Iterable<BoxDecoration> _decorationsUnder(WidgetTester tester, Finder root) =>
    tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: root,
            matching: find.byType(DecoratedBox),
            matchRoot: true,
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();

/// Every gradient painted anywhere under [root].
Iterable<Gradient> _gradientsUnder(WidgetTester tester, Finder root) =>
    _decorationsUnder(tester, root)
        .map((d) => d.gradient)
        .whereType<Gradient>();

/// A colour's 8-bit RGB triple, ignoring alpha.
({int r, int g, int b}) rgb(Color c) => (
      r: (c.r * 255).round(),
      g: (c.g * 255).round(),
      b: (c.b * 255).round(),
    );

/// Every non-empty box shadow painted anywhere under [root].
Iterable<BoxShadow> _shadowsUnder(WidgetTester tester, Finder root) =>
    _decorationsUnder(tester, root)
        .expand((d) => d.boxShadow ?? const <BoxShadow>[]);

void main() {
  group('gradientReach is honoured by the widgets, not just the theme', () {
    // Voltage is the preset that rations: gradientReach: hero.
    final voltage = BankVoltageTheme.dark();
    final stops = (voltage.accentGradient! as LinearGradient).colors;

    testWidgets('a hero card face paints the sweep at full strength',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const BankPaymentCard(label: 'Everyday'),
          BankPreset.voltage,
          brightness: Brightness.dark,
        ),
      );
      await tester.pump();

      final gradients = _gradientsUnder(tester, find.byType(BankPaymentCard))
          .whereType<LinearGradient>()
          .where((g) => g.colors.length == stops.length)
          .toList();
      expect(
        gradients,
        isNotEmpty,
        reason: 'the card face must paint a brand gradient',
      );

      final face = gradients.first;
      for (var i = 0; i < stops.length; i++) {
        expect(
          face.colors[i],
          stops[i],
          reason: 'a hero surface keeps the brand stops opaque: '
              'gradientReach can never ration BankGradientRole.hero down',
        );
      }
    });

    testWidgets('an incidental icon ring paints the rationed wash',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankQuickActionsGrid(actions: _actions),
          BankPreset.voltage,
          brightness: Brightness.dark,
        ),
      );
      await tester.pump();

      final rings =
          _gradientsUnder(tester, find.byType(BankQuickActionsGrid)).toList();
      expect(
        rings,
        isNotEmpty,
        reason: 'the Voltage icon ring must still be painted',
      );

      final ring = rings.first;
      expect(ring.colors.length, stops.length);
      for (var i = 0; i < stops.length; i++) {
        // Same hue travel, rationed alpha — this is the whole point of
        // gradientReach, and the assertion that fails the moment a call site
        // goes back to reading theme.accentGradient raw.
        expect(
          rgb(ring.colors[i]),
          rgb(stops[i]),
          reason: 'a rationed gradient keeps the brand hues',
        );
        expect(
          ring.colors[i].a,
          closeTo(stops[i].a * BankTokens.alphaSoft, 0.01),
          reason: 'BankGradientRole.incidental is rationed to '
              'BankTokens.alphaSoft under Voltage',
        );
      }
    });

    testWidgets('a brand with no reach limit still paints incidentals full',
        (tester) async {
      // Heritage leaves gradientReach at its incidental default, so nothing
      // is rationed — the policy must not fade gradients unconditionally.
      final heritage = BankHeritageTheme.light();
      final heritageStops = heritage.accentGradient!.colors;
      await tester.pumpWidget(
        _host(
          BankQuickActionsGrid(
            actions: _actions,
            // Heritage does not draw the ring by default; an explicit
            // ringGradient is a caller override, so use the theme's own
            // gradient as the fill under test instead.
            ringGradient: heritage.accentGradient,
          ),
          BankPreset.heritage,
          brightness: Brightness.light,
        ),
      );
      await tester.pump();

      final rings =
          _gradientsUnder(tester, find.byType(BankQuickActionsGrid)).toList();
      expect(rings, isNotEmpty);
      expect(rings.first.colors, heritageStops);
    });
  });

  group('shadowTint reaches every kit surface, not just the resolver ones', () {
    // Bloom light is the preset that tints: a warm plum ink instead of the
    // kit's default blue-grey. Before this gate, widgets that read
    // BankTokens.shadow* directly kept the blue-grey and two adjacent resting
    // cards on one screen dropped different-coloured shadows.
    final bloom = BankBloomTheme.light();

    Future<void> expectTinted(
      WidgetTester tester,
      Widget child,
      Type type,
    ) async {
      await tester.pumpWidget(
        _host(child, BankPreset.bloom, brightness: Brightness.light),
      );
      await tester.pump();

      final shadows = _shadowsUnder(tester, find.byType(type)).toList();
      expect(
        shadows,
        isNotEmpty,
        reason: '$type must resolve at least one shadow to tint',
      );
      for (final shadow in shadows) {
        expect(
          rgb(shadow.color),
          rgb(bloom.shadowTint!),
          reason: '$type casts an untinted shadow — it is reading '
              'BankTokens.shadow* directly instead of routing through '
              'BankThemeData.shadowFor / BankSurfaceDepth.resolve',
        );
      }
    }

    testWidgets('Bloom light tints every kit shadow on one screen',
        (tester) async {
      expect(
        bloom.shadowTint,
        isNotNull,
        reason: 'Bloom light is the tinted preset this gate depends on',
      );

      // A mix of both routes: widgets that were already on
      // BankSurfaceDepth.resolve and widgets that used to read the tokens
      // directly. On one cream background they must agree on shadow hue.
      await expectTinted(
        tester,
        BankAccountCard(account: _account),
        BankAccountCard,
      );
      await expectTinted(
        tester,
        const BankPaymentCard(label: 'Everyday'),
        BankPaymentCard,
      );
      await expectTinted(
        tester,
        BankProductCategoryTile(
          icon: Icons.directions_car_outlined,
          title: 'Loans',
          subtitle: 'Auto, personal, home',
          count: 6,
          onTap: () {},
        ),
        BankProductCategoryTile,
      );
      await expectTinted(
        tester,
        const BankServiceStatusList(
          services: [
            BankServiceStatusEntry(
              name: 'Cards',
              health: BankServiceHealth.operational,
            ),
          ],
        ),
        BankServiceStatusList,
      );
      await expectTinted(
        tester,
        BankQuickActionsGrid(actions: _actions),
        BankQuickActionsGrid,
      );
      await expectTinted(
        tester,
        BankEarlyPaydayCard(
          normalPayday: DateTime(2026, 8, 28),
          earlyPayday: DateTime(2026, 8, 26),
          enabled: false,
          onChanged: (_) {},
        ),
        BankEarlyPaydayCard,
      );
    });

    testWidgets('an untinted preset keeps the token shadow ink',
        (tester) async {
      // The tint must be applied, not invented: Studio defines no shadowTint,
      // so its surfaces keep BankTokens.shadowCard verbatim.
      final studio = BankStudioTheme.light();
      expect(studio.shadowTint, isNull);

      await tester.pumpWidget(
        _host(
          BankAccountCard(account: _account),
          BankPreset.studio,
          brightness: Brightness.light,
        ),
      );
      await tester.pump();

      final shadows =
          _shadowsUnder(tester, find.byType(BankAccountCard)).toList();
      expect(shadows, isNotEmpty);
      expect(
        shadows.map((s) => rgb(s.color)).toSet(),
        {rgb(BankTokens.shadowCard.first.color)},
      );
    });
  });
}
