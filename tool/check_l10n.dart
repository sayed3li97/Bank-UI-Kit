// Verifies the localisation catalogue is complete, consistent, and in sync
// with the Dart generated from it.
//
//   dart run tool/check_l10n.dart
//
// Four gates, each of which has to hold before a release can claim a locale
// is supported:
//
//  1. Every message in the template has an `@`-description. Translators work
//     from a spreadsheet, not from the widget tree, and an undescribed
//     "Credit" is unanswerable.
//  2. Every locale carries every key. A missing key silently renders English
//     inside an otherwise Arabic screen, which reads as a bug in the bank.
//  3. Placeholders match across locales. A translation that drops `{amount}`
//     compiles and then renders a sentence with a hole in it.
//  4. `flutter gen-l10n` leaves `l10n_untranslated.json` empty.
//
// The generated Dart itself is gated separately by
// `tool/generate_l10n_facade.dart --check` and by re-running `gen-l10n` in
// CI, so this file only judges the catalogue.
import 'dart:convert';
import 'dart:io';

/// Matches an ICU placeholder name. Deliberately ASCII-only: a plural branch
/// body is also brace-delimited (`few{{count} أشهر}`) and its leading token
/// is a translated word, not an argument.
final RegExp _placeholder = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)[,}]');

void main() {
  final root = Directory.current.path;
  final arbDir = Directory('$root/lib/l10n');
  if (!arbDir.existsSync()) {
    stderr.writeln('Cannot find ${arbDir.path}');
    exit(2);
  }

  final template = File('${arbDir.path}/bank_ui_kit_en.arb');
  if (!template.existsSync()) {
    stderr.writeln('Cannot find ${template.path}');
    exit(2);
  }

  final failures = <String>[];
  final en = _read(template);
  final enKeys = en.keys.where((k) => !k.startsWith('@')).toList();

  for (final key in enKeys) {
    final meta = en['@$key'];
    if (meta is! Map<String, dynamic> ||
        (meta['description'] as String? ?? '').trim().isEmpty) {
      failures.add('bank_ui_kit_en.arb: "$key" has no @description');
    }
  }

  final translations = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .where((f) => !f.path.endsWith('bank_ui_kit_en.arb'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in translations) {
    final name = file.uri.pathSegments.last;
    final locale = _read(file);
    final keys = locale.keys.where((k) => !k.startsWith('@')).toSet();

    final missing = enKeys.where((k) => !keys.contains(k)).toList();
    if (missing.isNotEmpty) {
      failures.add('$name: ${missing.length} untranslated '
          '(${missing.take(5).join(', ')}${missing.length > 5 ? ', …' : ''})');
    }
    final unknown = keys.where((k) => !enKeys.contains(k)).toList();
    if (unknown.isNotEmpty) {
      failures.add('$name: ${unknown.length} keys not in the template '
          '(${unknown.take(5).join(', ')})');
    }

    for (final key in enKeys) {
      final translated = locale[key];
      if (translated is! String) continue;
      final expected = _namesIn(en[key] as String);
      final actual = _namesIn(translated);
      if (!_sameSet(expected, actual)) {
        failures.add('$name: "$key" placeholders differ — template has '
            '${_show(expected)}, translation has ${_show(actual)}');
      }
    }
  }

  final untranslated = File('$root/l10n_untranslated.json');
  if (untranslated.existsSync()) {
    final content = untranslated.readAsStringSync().trim();
    if (content.isNotEmpty && content != '{}') {
      failures.add('l10n_untranslated.json is not empty: $content');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Localisation catalogue check failed:\n');
    for (final failure in failures) {
      stderr.writeln('  • $failure');
    }
    exit(1);
  }

  stdout.writeln('Catalogue OK: ${enKeys.length} messages × '
      '${translations.length + 1} locales, all described, all present, '
      'placeholders consistent.');
}

Map<String, dynamic> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Set<String> _namesIn(String message) =>
    _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.every(b.contains);

String _show(Set<String> names) =>
    names.isEmpty ? 'none' : (names.toList()..sort()).join(', ');
