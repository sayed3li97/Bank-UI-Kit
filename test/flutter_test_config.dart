import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test harness config. Loads the kit's bundled fonts so golden
/// (visual-regression) tests render real glyphs deterministically instead of
/// the fallback test font. Regenerate goldens with `flutter test
/// --update-goldens` on Linux + the pinned Flutter version (matches CI).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  return testMain();
}

Future<void> _loadBundledFonts() async {
  // Brand faces are registered twice, under the bare family name and under
  // the package-qualified name. The presets emit the qualified form (a preset
  // sets `fontFamily: 'packages/bank_ui_kit/SpaceGrotesk'`), so registering
  // only the bare name silently drops every preset-themed widget test back to
  // the one-em-per-glyph fallback test font, which is roughly double the real
  // advance width and quietly invalidates any width-sensitive assertion.
  const brandFaces = <String, List<String>>{
    'SpaceGrotesk': [
      'lib/src/assets/fonts/SpaceGrotesk-Regular.ttf',
      'lib/src/assets/fonts/SpaceGrotesk-Medium.ttf',
      'lib/src/assets/fonts/SpaceGrotesk-SemiBold.ttf',
      'lib/src/assets/fonts/SpaceGrotesk-Bold.ttf',
    ],
    'Nunito': [
      'lib/src/assets/fonts/Nunito-Regular.ttf',
      'lib/src/assets/fonts/Nunito-Medium.ttf',
      'lib/src/assets/fonts/Nunito-SemiBold.ttf',
      'lib/src/assets/fonts/Nunito-Bold.ttf',
    ],
    'Fredoka': [
      'lib/src/assets/fonts/Fredoka-Regular.ttf',
      'lib/src/assets/fonts/Fredoka-Medium.ttf',
      'lib/src/assets/fonts/Fredoka-SemiBold.ttf',
    ],
    'NotoSerifDisplay': [
      'lib/src/assets/fonts/NotoSerifDisplay-Regular.ttf',
      'lib/src/assets/fonts/NotoSerifDisplay-SemiBold.ttf',
    ],
  };

  final families = <String, List<String>>{
    for (final entry in brandFaces.entries) ...{
      entry.key: entry.value,
      'packages/bank_ui_kit/${entry.key}': entry.value,
    },
    // Glyph-coverage fallbacks (currency symbols, Arabic, Devanagari) so
    // goldens render real glyphs instead of tofu. Registered under the
    // package-qualified names used by kBankFontFallback.
    'packages/bank_ui_kit/NotoSansCurrency': [
      'lib/src/assets/fonts/NotoSansCurrency-Regular.ttf',
    ],
    'packages/bank_ui_kit/NotoSansArabic': [
      'lib/src/assets/fonts/NotoSansArabic-Regular.ttf',
    ],
    'packages/bank_ui_kit/NotoSansDevanagari': [
      'lib/src/assets/fonts/NotoSansDevanagari-Regular.ttf',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}
