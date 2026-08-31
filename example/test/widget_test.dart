import 'package:bank_ui_kit/core.dart';
import 'package:bank_ui_kit_example/demo/home_dashboard.dart';
import 'package:bank_ui_kit_example/showcase/showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeDashboard renders under the Studio preset', (tester) async {
    await tester.pumpWidget(
      BankUiScope(
        initialData: const BankUiScopeData(),
        child: MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: const HomeDashboard(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
  });

  testWidgets(
      'the showcase language control changes the language, not just '
      'the direction', (tester) async {
    // The sidebar used to offer LTR / RTL, which mirrored an English layout
    // and taught a viewer nothing. Picking العربية has to install the kit's
    // delegates for the previewed content, so this pins both halves.
    Future<void> pumpIn(Locale locale) => tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: BankL10n.localizationsDelegates,
            supportedLocales: BankL10n.supportedLocales,
            home: ThemedContent(
              settings: ShowcaseSettings(
                preset: BankPreset.studio,
                dark: false,
                locale: locale,
                privacy: false,
              ),
              child: Builder(
                builder: (context) => Column(
                  children: [
                    Text(BankStrings.of(context).actionConfirm),
                    Text(
                      Directionality.of(context) == TextDirection.rtl
                          ? 'rtl'
                          : 'ltr',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    await pumpIn(const Locale('en'));
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('ltr'), findsOneWidget);

    await pumpIn(const Locale('ar'));
    expect(find.text('تأكيد'), findsOneWidget);
    expect(find.text('rtl'), findsOneWidget);
  });
}
