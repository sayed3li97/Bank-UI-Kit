import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Native golden (visual-regression) tests pinning the rendered pixels of key
/// widgets across every preset x brightness — the point of a themeable design
/// system is that these stay visually consistent. Regenerate with
/// `flutter test --update-goldens`.

final _presets = <String, ({BankThemeData light, BankThemeData dark})>{
  'studio': (light: BankStudioTheme.light(), dark: BankStudioTheme.dark()),
  'voltage': (light: BankVoltageTheme.light(), dark: BankVoltageTheme.dark()),
  'bloom': (light: BankBloomTheme.light(), dark: BankBloomTheme.dark()),
  'heritage': (
    light: BankHeritageTheme.light(),
    dark: BankHeritageTheme.dark()
  ),
};

Widget _cell(
  String label,
  BankThemeData bank,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) {
  return BankUiScope(
    child: Theme(
      data: ThemeData(
        brightness: bank.background.computeLuminance() < 0.5
            ? Brightness.dark
            : Brightness.light,
        extensions: [bank],
      ),
      child: Directionality(
        textDirection: direction,
        child: ColoredBox(
          color: bank.background,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    ),
  );
}

/// Pumps [grid] at a fixed surface size and matches it to [file].
Future<void> _matchGrid(
  WidgetTester tester,
  Widget grid,
  String file,
) async {
  await tester.binding.setSurfaceSize(const Size(680, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(child: grid),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(RepaintBoundary).first,
    matchesGoldenFile('goldens/$file.png'),
  );
}

Widget _wrap(List<Widget> cells) => ColoredBox(
      color: const Color(0xFF808080),
      child: Wrap(spacing: 4, runSpacing: 4, children: cells),
    );

void main() {
  testWidgets('balance tile across presets', (tester) async {
    final cells = <Widget>[];
    _presets.forEach((name, pair) {
      for (final variant in [('light', pair.light), ('dark', pair.dark)]) {
        cells.add(
          _cell(
            '$name ${variant.$1}',
            variant.$2,
            BankBalanceTile(
              label: 'Available Balance',
              amount: Money.fromDouble(3565, 'GBP'),
              icon: Icons.account_balance_wallet_outlined,
              trend: '+2.4%',
            ),
          ),
        );
      }
    });
    await _matchGrid(tester, _wrap(cells), 'balance_tile_presets');
  });

  testWidgets('hero balance across presets', (tester) async {
    final cells = <Widget>[];
    _presets.forEach((name, pair) {
      for (final variant in [('light', pair.light), ('dark', pair.dark)]) {
        cells.add(
          _cell(
            '$name ${variant.$1}',
            variant.$2,
            BankBalanceText(
              money: Money.fromDouble(12345.67, 'USD'),
              size: BankBalanceSize.hero,
            ),
          ),
        );
      }
    });
    await _matchGrid(tester, _wrap(cells), 'hero_balance_presets');
  });

  testWidgets('balance tile respects RTL', (tester) async {
    final cells = [
      _cell(
        'LTR',
        BankStudioTheme.light(),
        BankBalanceTile(
          label: 'Available Balance',
          amount: Money.fromDouble(3565, 'SAR'),
          icon: Icons.account_balance_wallet_outlined,
        ),
      ),
      _cell(
        'RTL',
        BankStudioTheme.light(),
        direction: TextDirection.rtl,
        BankBalanceTile(
          label: 'الرصيد المتاح',
          amount: Money.fromDouble(3565, 'SAR'),
          icon: Icons.account_balance_wallet_outlined,
        ),
      ),
    ];
    await _matchGrid(tester, _wrap(cells), 'balance_tile_rtl');
  });
}
