// Generates the scalar design tokens in `lib/src/theme/tokens.dart` from the
// platform-neutral W3C DTCG source `tokens/design-tokens.json`.
//
//   dart run tool/generate_tokens.dart          # regenerate (writes the file)
//   dart run tool/generate_tokens.dart --check   # CI: fail if out of sync
//
// Only the region between the GENERATED-TOKENS markers is owned by this tool.
// Composite tokens (text styles, curves, shadows) are hand-authored below the
// markers and reference these generated values.
import 'dart:convert';
import 'dart:io';

const _begin = '  // --- GENERATED TOKENS: do not edit by hand '
    '(source: tokens/design-tokens.json) ---';
const _end = '  // --- END GENERATED TOKENS ---';

void main(List<String> args) {
  final check = args.contains('--check');
  final root = Directory.current.path;
  final tokensJson = File('$root/tokens/design-tokens.json');
  final tokensDart = File('$root/lib/src/theme/tokens.dart');

  if (!tokensJson.existsSync()) {
    stderr.writeln('Cannot find ${tokensJson.path}');
    exit(2);
  }

  final data =
      jsonDecode(tokensJson.readAsStringSync()) as Map<String, dynamic>;
  final generated = _renderRegion(data);

  final source = tokensDart.readAsStringSync();
  if (!source.contains(_begin) || !source.contains(_end)) {
    stderr.writeln('Could not find GENERATED TOKENS markers in tokens.dart');
    exit(2);
  }

  final before = source.substring(0, source.indexOf(_begin));
  final after = source.substring(source.indexOf(_end) + _end.length);
  final rebuilt = '$before$generated$after';

  if (check) {
    // Compare formatted-to-formatted so dart_style whitespace quirks never
    // cause a false "out of sync". The committed file is already formatted
    // (CI enforces it), so any real diff is a genuine token change.
    final tmp = File('${tokensDart.path}.gen.tmp')..writeAsStringSync(rebuilt);
    _format(tmp.path);
    final formatted = tmp.readAsStringSync();
    tmp.deleteSync();
    if (formatted == source) {
      stdout.writeln('Design tokens are in sync.');
      return;
    }
    stderr.writeln(
      'Design tokens are OUT OF SYNC with tokens/design-tokens.json.\n'
      'Run: dart run tool/generate_tokens.dart',
    );
    exit(1);
  }

  tokensDart.writeAsStringSync(rebuilt);
  _format(tokensDart.path);
  stdout.writeln('Wrote generated tokens to ${tokensDart.path}');
}

/// Runs `dart format` on [path] so generated output matches CI's formatter.
void _format(String path) {
  final r = Process.runSync('dart', ['format', path]);
  if (r.exitCode != 0) {
    stderr.writeln('dart format failed on $path:\n${r.stderr}');
    exit(2);
  }
}

String _renderRegion(Map<String, dynamic> data) {
  final b = StringBuffer()
    ..writeln(_begin)
    ..writeln();

  void group(
    String jsonKey,
    String heading,
    String Function(String, Map<String, dynamic>) one,
  ) {
    final map = data[jsonKey] as Map<String, dynamic>?;
    if (map == null) return;
    b.writeln('  // $heading');
    map.forEach((key, value) {
      final token = value as Map<String, dynamic>;
      final desc = token[r'$description'] as String?;
      if (desc != null) {
        for (final line in _wrapDoc(desc)) {
          b.writeln(line);
        }
      }
      b.writeln(one(key, token));
    });
    b.writeln();
  }

  group('color', 'Colour roles', (key, t) {
    final hex = _colorLiteral(t[r'$value'] as String);
    return '  static const Color $key = $hex;';
  });
  group('space', 'Spacing (4 pt grid)', (key, t) {
    final v = _dimension(t[r'$value'] as String);
    return '  static const double space$key = $v;';
  });
  group('radius', 'Border-radius tiers', (key, t) {
    final v = _dimension(t[r'$value'] as String);
    return '  static const double radius${_cap(key)} = $v;';
  });
  group('duration', 'Motion: durations', (key, t) {
    final ms = _durationMs(t[r'$value'] as String);
    return '  static const Duration duration${_cap(key)} = '
        'Duration(milliseconds: $ms);';
  });
  group('size', 'Accessibility & sizing', (key, t) {
    final v = _dimension(t[r'$value'] as String);
    return '  static const double $key = $v;';
  });
  group('interaction', 'Interaction states', (key, t) {
    final v = _number(t[r'$value'] as num);
    return '  static const double $key = $v;';
  });
  group('effect', 'Visual effects', (key, t) {
    final v = _number(t[r'$value'] as num);
    return '  static const double $key = $v;';
  });

  b.write(_end);
  return b.toString();
}

/// Wraps [text] into `  /// ...` doc-comment lines that respect the
/// 80-column limit enforced by the `lines_longer_than_80_chars` lint.
List<String> _wrapDoc(String text) {
  const prefix = '  /// ';
  const width = 80 - prefix.length;
  final lines = <String>[];
  var current = StringBuffer();
  for (final word in text.split(RegExp(r'\s+'))) {
    if (current.isEmpty) {
      current.write(word);
    } else if (current.length + 1 + word.length <= width) {
      current.write(' $word');
    } else {
      lines.add('$prefix$current');
      current = StringBuffer(word);
    }
  }
  if (current.isNotEmpty) lines.add('$prefix$current');
  return lines;
}

/// `#RRGGBB` or `#RRGGBBAA` -> `Color(0xAARRGGBB)`.
String _colorLiteral(String hex) {
  var h = hex.replaceFirst('#', '').toUpperCase();
  if (h.length == 6) {
    h = 'FF$h';
  } else if (h.length == 8) {
    // DTCG orders alpha last (RRGGBBAA); Flutter wants AARRGGBB.
    final rgb = h.substring(0, 6);
    final a = h.substring(6, 8);
    h = '$a$rgb';
  }
  return 'Color(0x$h)';
}

/// `"16px"` -> `16` (trim a trailing `.0`).
String _dimension(String value) {
  final n = double.parse(value.replaceAll('px', '').trim());
  return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}

/// DTCG `number` (`0.12`, `2`) -> Dart double literal (`0.12`, `2`).
String _number(num value) {
  final n = value.toDouble();
  return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}

/// `"150ms"` -> `150`.
int _durationMs(String value) => int.parse(value.replaceAll('ms', '').trim());

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
