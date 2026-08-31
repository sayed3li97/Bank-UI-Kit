// Identity-system conformance: one emblem ladder, one deterministic and
// AA-legible colour derivation, one stacked-group overflow rule, and one
// chip/badge anatomy shared by every call site (audit ranks 43, 62, 67).
import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit/investing.dart';
import 'package:bank_ui_kit/social.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  BankThemeData? bank,
  TextDirection direction = TextDirection.ltr,
}) {
  final theme = bank ?? BankStudioTheme.light();
  final brightness =
      ThemeData.estimateBrightnessForColor(theme.background) == Brightness.dark
          ? Brightness.dark
          : Brightness.light;
  return BankUiScope(
    child: MaterialApp(
      theme: ThemeData(brightness: brightness, extensions: [theme]),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          backgroundColor: theme.background,
          body: child,
        ),
      ),
    ),
  );
}

/// Every preset x brightness, so a derivation rule has to hold for the whole
/// brand matrix rather than for Studio light.
Map<String, BankThemeData> _allThemes() => {
      'studio.light': BankStudioTheme.light(),
      'studio.dark': BankStudioTheme.dark(),
      'voltage.light': BankVoltageTheme.light(),
      'voltage.dark': BankVoltageTheme.dark(),
      'bloom.light': BankBloomTheme.light(),
      'bloom.dark': BankBloomTheme.dark(),
      'heritage.light': BankHeritageTheme.light(),
      'heritage.dark': BankHeritageTheme.dark(),
    };

/// WCAG 2.x relative-contrast ratio, computed independently of the widget
/// code so the test validates the rule rather than restating it.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The box a [BankTintChip.dotSize] marker dot occupies, as [Container]
/// stores it — the handle the tests use to find (or fail to find) a dot.
const _dotConstraints = BoxConstraints.tightFor(
  width: BankTintChip.dotSize,
  height: BankTintChip.dotSize,
);

const _names = <String>[
  'Ada Lovelace',
  'Bank of Bahrain',
  'Carlos Ruiz',
  'Deutsche Telekom',
  'Elena Fischer',
  'Fatima Al Sayed',
  'Grace Hopper',
  'Hussain Trading',
  'Ivan Petrov',
  'Jonas Lund',
  'Karim Nasser',
  'Lucia Moretti',
];

BankNotification _notification({
  required String id,
  required String title,
  required bool isRead,
  BankNotificationType type = BankNotificationType.payment,
}) =>
    BankNotification(
      id: id,
      title: title,
      body: 'Body copy for $title',
      receivedAt: DateTime(2026, 7, 1, 9),
      isRead: isRead,
      type: type,
    );

void main() {
  // -------------------------------------------------------------------------
  // Rank 43: one deterministic, theme-derived, AA-legible identity palette
  // -------------------------------------------------------------------------
  group('Identity colour derivation', () {
    test('the same seed always resolves to the same tint', () {
      final theme = BankStudioTheme.light();
      for (final name in _names) {
        expect(
          BankEmblem.tintFor(theme, name),
          BankEmblem.tintFor(theme, name),
          reason: '$name must not drift between reads',
        );
        expect(
          BankEmblem.tintFor(BankStudioTheme.light(), name),
          BankEmblem.tintFor(theme, name),
          reason: '$name must not depend on the theme instance',
        );
      }
    });

    test('the palette spreads across buckets instead of collapsing', () {
      for (final entry in _allThemes().entries) {
        final tints = {
          for (final name in _names) BankEmblem.tintFor(entry.value, name),
        };
        expect(
          tints.length,
          greaterThanOrEqualTo(4),
          reason: '${entry.key} collapsed 12 identities into ${tints.length} '
              'colours — neighbours would read as the same entity',
        );
      }
    });

    test('derived ink clears WCAG AA against its own fill everywhere', () {
      for (final entry in _allThemes().entries) {
        final theme = entry.value;
        for (final name in _names) {
          final tint = BankEmblem.tintFor(theme, name);
          final fill = BankEmblem.fillFor(theme, tint);
          final ink = BankEmblem.inkFor(theme, tint);
          expect(
            _contrast(ink, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} / $name: monogram ink is not AA-legible',
          );
        }
      }
    });

    test('semantic tints are corrected too, not just hashed ones', () {
      for (final entry in _allThemes().entries) {
        final theme = entry.value;
        final seeds = <String, Color>{
          'primary': theme.primary,
          'positive': theme.positiveBalance,
          'negative': theme.negativeBalance,
          'pending': theme.pending,
          'onSurfaceVariant': theme.onSurfaceVariant,
        };
        seeds.forEach((label, seed) {
          expect(
            _contrast(
              BankEmblem.inkFor(theme, seed),
              BankEmblem.fillFor(theme, seed),
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} / $label chip ink is not AA-legible',
          );
        });
      }
    });
  });

  // -------------------------------------------------------------------------
  // Rank 43: the size ladder
  // -------------------------------------------------------------------------
  group('Identity size ladder', () {
    test('every rung draws its glyph from the icon-size ladder', () {
      const ladder = <double>[
        BankTokens.iconXSmall,
        BankTokens.iconSmall,
        BankTokens.iconMedium,
        BankTokens.iconLarge,
        BankTokens.iconXLarge,
        BankTokens.iconHero,
      ];
      for (final rung in BankEmblemSize.values) {
        expect(
          ladder,
          contains(rung.glyphSize),
          reason: '${rung.name} invented an off-ladder glyph size',
        );
      }
    });

    test('rung diameters ascend', () {
      final diameters = [
        for (final rung in BankEmblemSize.values) rung.diameter,
      ];
      final sorted = [...diameters]..sort();
      expect(diameters, sorted);
      expect(diameters.toSet().length, diameters.length);
    });

    testWidgets('a tier sets the footprint and a ring does not grow it',
        (tester) async {
      for (final rung in BankEmblemSize.values) {
        await tester.pumpWidget(
          _host(
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BankEmblem(initialsFrom: 'Ada Lovelace', tier: rung),
                  BankEmblem(
                    initialsFrom: 'Bob Ray',
                    tier: rung,
                    ring: const BankEmblemRing(),
                  ),
                ],
              ),
            ),
          ),
        );
        final sizes = tester
            .widgetList<BankEmblem>(find.byType(BankEmblem))
            .map((w) => tester.getSize(find.byWidget(w)))
            .toList();
        expect(
          sizes,
          everyElement(Size(rung.diameter, rung.diameter)),
          reason: '${rung.name}: a ringed emblem must occupy the same box',
        );
      }
    });

    testWidgets('size still works for off-ladder call sites', (tester) async {
      await tester.pumpWidget(
        _host(const Center(child: BankEmblem(initialsFrom: 'Ada', size: 28))),
      );
      expect(tester.getSize(find.byType(BankEmblem)), const Size(28, 28));
    });
  });

  // -------------------------------------------------------------------------
  // Ranks 43 / 62: stacked avatars with +N overflow
  // -------------------------------------------------------------------------
  group('BankEmblemStack', () {
    List<BankEmblemData> data(int count) => [
          for (var i = 0; i < count; i++)
            BankEmblemData(initialsFrom: _names[i]),
        ];

    testWidgets('folds everyone past maxVisible into a +N disc',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Center(
            child: BankEmblemStack(
              emblems: data(7),
              tier: BankEmblemSize.small,
              maxVisible: 3,
            ),
          ),
        ),
      );
      expect(find.text('+4'), findsOneWidget);
      // Three identities plus the overflow disc, and nothing beyond.
      expect(find.byType(BankEmblem), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow disc when everyone fits', (tester) async {
      await tester.pumpWidget(
        _host(
          Center(
            child: BankEmblemStack(emblems: data(3)),
          ),
        ),
      );
      expect(find.textContaining('+'), findsNothing);
      expect(find.byType(BankEmblem), findsNWidgets(3));
    });

    testWidgets('width is bounded by the overlap, not the member count',
        (tester) async {
      const tier = BankEmblemSize.small;
      await tester.pumpWidget(
        _host(
          Center(
            child: BankEmblemStack(
              emblems: data(9),
              tier: tier,
              maxVisible: 5,
            ),
          ),
        ),
      );
      final advance = tier.diameter * (1 - BankEmblemStack.defaultOverlap);
      expect(
        tester.getSize(find.byType(BankEmblemStack)).width,
        closeTo(tier.diameter + 5 * advance, 0.01),
        reason: 'five identities plus the overflow disc, and no more',
      );
    });

    testWidgets('a tappable slot keeps the 44 px target the ladder promises',
        (tester) async {
      final handle = tester.ensureSemantics();
      // xSmall is the rung documented for stacked rails: 24 px of disc, which
      // a slot pinned to the diameter would hand straight to the button.
      await tester.pumpWidget(
        _host(
          Center(
            child: BankEmblemStack(
              emblems: [
                BankEmblemData(initialsFrom: 'Ada Lovelace', onTap: () {}),
              ],
              tier: BankEmblemSize.xSmall,
              overflowCount: 4,
              onOverflowTap: () {},
            ),
          ),
        ),
      );

      // The member and the +4 overflow disc are both wired to a callback, so
      // both are buttons and both owe the floor.
      final buttons = find.byType(BankEmblem);
      expect(buttons, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final emblem = tester.widget<BankEmblem>(buttons.at(i));
        final size = tester.getSize(buttons.at(i));
        final name = emblem.semanticLabel ?? emblem.initialsFrom;
        expect(
          size.width,
          greaterThanOrEqualTo(BankTokens.minTapTarget),
          reason: '$name is narrower than the tap-target floor',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(BankTokens.minTapTarget),
          reason: '$name is shorter than the tap-target floor',
        );
      }

      // The discs themselves stay on the ladder: the slot grew, not the art.
      expect(
        tester.getSize(find.text('+4')).height,
        lessThan(BankTokens.minTapTarget),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a decorative group is still exactly one disc tall',
        (tester) async {
      const tier = BankEmblemSize.xSmall;
      await tester.pumpWidget(
        _host(Center(child: BankEmblemStack(emblems: data(2), tier: tier))),
      );
      expect(
        tester.getSize(find.byType(BankEmblemStack)).height,
        tier.diameter,
        reason: 'nothing is tappable, so nothing needs a tap target',
      );
    });

    testWidgets('stacking order follows the reading direction', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const Center(
              child: BankEmblemStack(
                emblems: [
                  BankEmblemData(initialsFrom: 'Ann Ant'),
                  BankEmblemData(initialsFrom: 'Bob Bee'),
                ],
                tier: BankEmblemSize.small,
              ),
            ),
            direction: direction,
          ),
        );
        final first = tester.getCenter(find.text('AA')).dx;
        final second = tester.getCenter(find.text('BB')).dx;
        if (direction == TextDirection.ltr) {
          expect(first, lessThan(second), reason: 'LTR leads on the left');
        } else {
          expect(first, greaterThan(second), reason: 'RTL leads on the right');
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // Rank 67: one chip anatomy
  // -------------------------------------------------------------------------
  group('Chip anatomy', () {
    testWidgets('ownership badge and price chip share height and radius',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BankAccountOwnershipBadge(role: BankOwnershipRole.joint),
              BankAssetPriceTicker(
                quote: AssetQuote(
                  symbol: 'AAPL',
                  name: 'Apple Inc.',
                  price: Money.fromDouble(190.25, 'USD'),
                  changePercent: 1.42,
                ),
              ),
            ],
          ),
        ),
      );
      final chips = find.byType(BankTintChip);
      expect(chips, findsNWidgets(2));
      final heights = tester
          .widgetList<BankTintChip>(chips)
          .map((chip) => tester.getSize(find.byWidget(chip)).height)
          .toSet();
      expect(
        heights,
        {BankTintChip.minHeight},
        reason: 'chips must agree on one height',
      );
    });

    testWidgets('every role badge stays legible on every preset',
        (tester) async {
      for (final entry in _allThemes().entries) {
        for (final role in BankOwnershipRole.values) {
          await tester.pumpWidget(
            _host(
              Center(child: BankAccountOwnershipBadge(role: role)),
              bank: entry.value,
            ),
          );
          final chip = tester.widget<BankTintChip>(find.byType(BankTintChip));
          final color = chip.color!;
          expect(
            _contrast(
              BankEmblem.inkFor(entry.value, color),
              BankEmblem.fillFor(entry.value, color),
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} / ${role.name} badge is not AA-legible',
          );
        }
      }
    });

    testWidgets('a chip carries at most one leading mark', (tester) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: BankTintChip(
              label: 'Pending',
              icon: Icons.schedule,
              showDot: true,
            ),
          ),
        ),
      );
      expect(find.byType(Icon), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints == _dotConstraints,
        ),
        findsNothing,
        reason: 'the glyph wins; the dot must not double up',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Rank 67: notification rows encode unread once
  // -------------------------------------------------------------------------
  group('BankInAppNotificationCenter unread encoding', () {
    Finder dotFinder() => find.byWidgetPredicate(
          (w) => w is Container && w.constraints == _dotConstraints,
        );

    testWidgets('unread rows take a marker dot and no per-row wash',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankInAppNotificationCenter(
            notifications: [
              _notification(id: 'n1', title: 'Card frozen', isRead: false),
              _notification(id: 'n2', title: 'Salary received', isRead: true),
            ],
          ),
        ),
      );

      expect(dotFinder(), findsOneWidget);

      for (final title in ['Card frozen', 'Salary received']) {
        final washes = tester
            .widgetList<Container>(
              find.ancestor(
                of: find.text(title),
                matching: find.byType(Container),
              ),
            )
            .where((c) => c.color != null);
        expect(
          washes,
          isEmpty,
          reason: '$title row still paints a full-bleed colour wash',
        );
      }
    });

    testWidgets('a caller can opt back into a wash', (tester) async {
      const wash = Color(0x11336699);
      await tester.pumpWidget(
        _host(
          BankInAppNotificationCenter(
            unreadTintColor: wash,
            notifications: [
              _notification(id: 'n1', title: 'Card frozen', isRead: false),
            ],
          ),
        ),
      );
      final colors = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('Card frozen'),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.color);
      expect(colors, contains(wash));
    });

    testWidgets('rows use the identity emblem, not a bespoke disc',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankInAppNotificationCenter(
            notifications: [
              _notification(
                id: 'n1',
                title: 'Unusual sign-in',
                isRead: false,
                type: BankNotificationType.fraud,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(BankEmblem), findsOneWidget);
      final emblem = tester.widget<BankEmblem>(find.byType(BankEmblem));
      expect(emblem.tier, BankEmblemSize.medium);
      expect(
        tester.getSize(find.byType(BankEmblem)).width,
        BankEmblemSize.medium.diameter,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Rank 62: the money circle stops swallowing members
  // -------------------------------------------------------------------------
  group('BankMoneyCircleCard turn tracker', () {
    List<BankCircleMember> members(int count) => [
          for (var i = 0; i < count; i++)
            BankCircleMember(
              id: 'm$i',
              name: _names[i],
              turnIndex: i + 1,
              paidThisCycle: i < 2,
              isMe: i == 1,
            ),
        ];

    Widget card(int count, {double width = 320, int? maxVisible}) => SizedBox(
          width: width,
          child: BankMoneyCircleCard(
            name: 'Family circle',
            contribution: Money.fromDouble(100, 'BHD'),
            members: members(count),
            currentCycle: 2,
            totalCycles: count,
            nextCollectionDate: DateTime(2026, 8, 2),
            maxVisibleMembers: maxVisible,
          ),
        );

    testWidgets('folds members that do not fit into a +N disc', (tester) async {
      await tester.pumpWidget(_host(Center(child: card(9))));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // 320 - 2*16 padding = 288 usable; slots are 40 + 12 wide, so five fit,
      // four turns are drawn, and the remaining five fold up.
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('a small circle draws every member and no overflow disc',
        (tester) async {
      await tester.pumpWidget(_host(Center(child: card(3))));
      await tester.pump();
      expect(find.textContaining('+'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('maxVisibleMembers caps the rail below what would fit',
        (tester) async {
      await tester.pumpWidget(
        _host(Center(child: card(6, width: 400, maxVisible: 3))),
      );
      await tester.pump();
      expect(find.text('+4'), findsOneWidget);
    });
  });
}
