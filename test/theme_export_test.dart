import 'dart:convert';
import 'dart:io';

import 'package:bank_ui_kit/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generates and verifies the per-brand theme token exports in `tokens/themes/`.
///
/// These files are the Figma-Variables / Style-Dictionary-consumable brand
/// token sets — the theme half of the "one source, many consumers" story
/// (`tokens/design-tokens.json` is the global half).
///
/// They are generated, never hand-edited. To (re)generate after a preset
/// changes, run:
///
///   UPDATE_THEME_TOKENS=1 flutter test test/theme_export_test.dart
///
/// Plain `flutter test` (and CI) then asserts the committed files match the
/// presets, so a preset change that isn't re-exported fails the build.
void main() {
  final update = Platform.environment['UPDATE_THEME_TOKENS'] == '1';
  const encoder = JsonEncoder.withIndent('  ');

  final themes = <String, BankThemeData>{
    'studio.light': BankStudioTheme.light(),
    'studio.dark': BankStudioTheme.dark(),
    'voltage.light': BankVoltageTheme.light(),
    'voltage.dark': BankVoltageTheme.dark(),
    'bloom.light': BankBloomTheme.light(),
    'bloom.dark': BankBloomTheme.dark(),
    'heritage.light': BankHeritageTheme.light(),
    'heritage.dark': BankHeritageTheme.dark(),
  };

  final dir = Directory('tokens/themes');

  setUpAll(() {
    if (update) dir.createSync(recursive: true);
  });

  themes.forEach((name, theme) {
    test('tokens/themes/$name.json matches ${name.split('.').first} preset',
        () {
      final file = File('${dir.path}/$name.json');
      final expected = '${encoder.convert(theme.toJson())}\n';

      if (update) {
        file.writeAsStringSync(expected);
        return;
      }

      expect(
        file.existsSync(),
        isTrue,
        reason: 'Missing $name.json — run '
            'UPDATE_THEME_TOKENS=1 flutter test test/theme_export_test.dart',
      );
      expect(
        file.readAsStringSync(),
        expected,
        reason: '$name.json is stale — regenerate with '
            'UPDATE_THEME_TOKENS=1 flutter test test/theme_export_test.dart',
      );
    });
  });
}
