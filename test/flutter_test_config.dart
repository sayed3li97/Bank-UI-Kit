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
  const families = <String, List<String>>{
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
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}
