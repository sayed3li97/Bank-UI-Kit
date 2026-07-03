import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => BankUiScope(
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: child),
      ),
    );

void main() {
  DateTime clock() => DateTime(2026, 7, 4, 1, 12);

  group('BankAppGateScreen', () {
    for (final reason in BankAppGateReason.values) {
      testWidgets('renders ${reason.name} without exceptions', (tester) async {
        await tester.pumpWidget(
          _host(
            BankAppGateScreen(
              reason: reason,
              clock: clock,
              resumesAt: reason == BankAppGateReason.maintenance
                  ? DateTime(2026, 7, 4, 2, 30)
                  : null,
              queuePosition:
                  reason == BankAppGateReason.queueFull ? 1200 : null,
              queueInitialPosition:
                  reason == BankAppGateReason.queueFull ? 5000 : null,
              onPrimaryAction: () {},
              referenceCode: 'RC-TEST-01',
              appVersion: '4.13.0',
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.byType(BankAppGateScreen), findsOneWidget);
      });
    }
  });

  testWidgets('BankConnectivityBanner shows staleness and retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(
        BankConnectivityBanner(
          status: BankConnectivityStatus.deviceOffline,
          lastSyncedAt: DateTime(2026, 7, 4, 0, 58),
          clock: clock,
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Try now'));
    expect(retried, isTrue);
  });

  testWidgets('BankServiceStatusList renders all health states',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankServiceStatusList(
          services: const [
            BankServiceStatusEntry(
              name: 'Cards',
              health: BankServiceHealth.operational,
            ),
            BankServiceStatusEntry(
              name: 'Transfers',
              health: BankServiceHealth.degraded,
              note: 'Delays up to 30 minutes.',
            ),
            BankServiceStatusEntry(
              name: 'FX',
              health: BankServiceHealth.down,
            ),
            BankServiceStatusEntry(
              name: 'International',
              health: BankServiceHealth.maintenance,
            ),
          ],
          clock: clock,
        ),
      ),
    );
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Delays up to 30 minutes.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankUpdatePromptSheet renders highlights and versions',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankUpdatePromptSheet(
          onUpdate: () {},
          onNotNow: () {},
          availableVersion: '4.14.0',
          installedVersion: '4.13.0',
          highlights: const ['Passkeys', 'Insights redesign'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Passkeys'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
