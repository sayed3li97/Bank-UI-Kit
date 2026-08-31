// Generates the resolution facade in `lib/src/l10n/bank_strings.dart` from
// the English catalogue `lib/l10n/bank_ui_kit_en.arb`.
//
//   dart run tool/generate_l10n_facade.dart          # regenerate
//   dart run tool/generate_l10n_facade.dart --check  # CI: fail if out of sync
//
// Only the region between the GENERATED ACCESSORS markers is owned by this
// tool. Everything else in bank_strings.dart is hand-authored, including the
// handful of accessors listed in `_handWritten` below, which need resolution
// logic no template can express.
import 'dart:convert';
import 'dart:io';

const _begin = '  // --- GENERATED ACCESSORS: do not edit by hand '
    '(source: lib/l10n/bank_ui_kit_en.arb) ---';
const _end = '  // --- END GENERATED ACCESSORS ---';

/// ARB keys whose accessor lives below the markers instead.
const _handWritten = <String>{
  // Legacy `{n}` template plus an ICU plural: two override grammars in one.
  'installmentMonths',
  // Dots, not words. Localising them would be a bug, not a feature.
  'balanceHidden',
};

/// Maps a `BankUiStrings` field to the ARB key that carries its translation.
///
/// A host that changed one of these from its shipped default is expressing
/// an explicit choice, so the override outranks the translation. Fields
/// absent from this map have no legacy equivalent and resolve from the
/// catalogue alone.
const _legacyFields = <String, String>{
  'today': 'today',
  'yesterday': 'yesterday',
  'pending': 'statusPending',
  'cleared': 'statusCleared',
  'declined': 'statusDeclined',
  'refunded': 'statusRefunded',
  'scheduled': 'statusScheduled',
  'frozen': 'statusFrozen',
  'restricted': 'statusRestricted',
  'active': 'statusActive',
  'sendMoney': 'sendMoney',
  'requestMoney': 'requestMoney',
  'addMoney': 'addMoney',
  'withdraw': 'withdraw',
  'confirmPin': 'confirmPin',
  'sessionTimeout': 'sessionTimeout',
  'sessionTimeoutBody': 'sessionTimeoutBody',
  'retry': 'actionRetry',
  'contactSupport': 'actionContactSupport',
  'noTransactions': 'noTransactions',
  'loadingTransactions': 'loadingTransactions',
  'transferSuccess': 'transferSuccess',
  'transferFailure': 'transferFailure',
  'interestRate': 'interestRate',
  'profitRate': 'profitRate',
  'annualPercentageRate': 'annualPercentageRate',
  'available': 'labelAvailable',
  'used': 'labelUsed',
  'goal': 'labelGoal',
  'progress': 'labelProgress',
  'addToPot': 'addToPot',
  'withdrawFromPot': 'withdrawFromPot',
  'splitEqually': 'splitEqually',
  'custom': 'actionCustom',
  'done': 'actionDone',
  'cancel': 'actionCancel',
  'confirm': 'actionConfirm',
  'next': 'actionNext',
  'back': 'actionBack',
  'skip': 'actionSkip',
  'accept': 'actionAccept',
  'decline': 'actionDecline',
  'share': 'actionShare',
  'dispute': 'actionDispute',
  'report': 'actionReport',
  'newDevice': 'newDevice',
  'newDeviceBody': 'newDeviceBody',
  'compromisedDevice': 'compromisedDevice',
  'compromisedDeviceBody': 'compromisedDeviceBody',
  'verificationUnderReview': 'verificationUnderReview',
  'verificationUnderReviewBody': 'verificationUnderReviewBody',
  'interestFree': 'interestFree',
  'perMonth': 'perMonth',
};

void main(List<String> args) {
  final check = args.contains('--check');
  final arb = File('${Directory.current.path}/lib/l10n/bank_ui_kit_en.arb');
  final target =
      File('${Directory.current.path}/lib/src/l10n/bank_strings.dart');

  for (final file in [arb, target]) {
    if (!file.existsSync()) {
      stderr.writeln('Cannot find ${file.path}');
      exit(2);
    }
  }

  final catalogue = jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
  final generated = _renderRegion(catalogue);

  final source = target.readAsStringSync();
  if (!source.contains(_begin) || !source.contains(_end)) {
    stderr.writeln('Could not find GENERATED ACCESSORS markers in '
        '${target.path}');
    exit(2);
  }

  final before = source.substring(0, source.indexOf(_begin));
  final after = source.substring(source.indexOf(_end) + _end.length);
  final rebuilt = '$before$generated$after';

  // The emitted region is compared and written already formatted, so the
  // drift gate and `dart format --set-exit-if-changed` can never disagree
  // about the same file.
  final formatted = _format(rebuilt);

  if (check) {
    if (formatted != source) {
      stderr.writeln(
        'bank_strings.dart is out of sync with bank_ui_kit_en.arb.\n'
        'Run: dart run tool/generate_l10n_facade.dart',
      );
      exit(1);
    }
    stdout.writeln('bank_strings.dart is in sync with the catalogue.');
    return;
  }

  target.writeAsStringSync(formatted);
  stdout.writeln('Wrote ${target.path}');
}

/// Runs `dart format` over [source] and returns the result.
String _format(String source) {
  // Scratch inside the package: `dart format` resolves the language version
  // from the enclosing package config, and formats differently without it.
  final scratch = Directory('${Directory.current.path}/.dart_tool')
      .createTempSync('bank_l10n_facade');
  try {
    final file = File('${scratch.path}/bank_strings.dart')
      ..writeAsStringSync(source);
    final result = Process.runSync('dart', ['format', file.path]);
    if (result.exitCode != 0) {
      stderr.writeln('dart format failed: ${result.stderr}');
      exit(2);
    }
    return file.readAsStringSync();
  } finally {
    scratch.deleteSync(recursive: true);
  }
}

String _renderRegion(Map<String, dynamic> catalogue) {
  final byArbKey = <String, String>{
    for (final entry in _legacyFields.entries) entry.value: entry.key,
  };
  final buffer = StringBuffer()..writeln(_begin);

  final keys = catalogue.keys
      .where((k) => !k.startsWith('@'))
      .where((k) => !_handWritten.contains(k))
      .toList();

  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final meta = catalogue['@$key'] as Map<String, dynamic>?;
    final description = meta?['description'] as String?;
    final placeholders =
        (meta?['placeholders'] as Map<String, dynamic>?) ?? const {};
    final legacy = byArbKey[key];

    if (i > 0) buffer.writeln();
    if (description != null) {
      for (final line in _wrapDoc(description)) {
        buffer.writeln(line);
      }
    }
    if (legacy != null) {
      buffer.writeln('  ///');
      for (final line in _wrapDoc(
        'Overridden by `BankUiStrings.$legacy` when the host changed it.',
      )) {
        buffer.writeln(line);
      }
    }

    if (placeholders.isEmpty) {
      buffer.write(_getter(key, legacy));
    } else {
      buffer.write(_method(key, placeholders));
    }
  }

  buffer.write(_end);
  return buffer.toString();
}

String _getter(String key, String? legacy) {
  if (legacy == null) {
    final oneLine = '  String get $key => _l10n?.$key ?? _en.$key;';
    if (oneLine.length <= 80) return '$oneLine\n';
    return '  String get $key =>\n      _l10n?.$key ?? _en.$key;\n';
  }
  final compact =
      '      override(_overrides.$legacy, BankUiStrings.defaults.$legacy) ??';
  final pick = compact.length <= 80
      ? '$compact\n'
      : '      override(\n'
          '            _overrides.$legacy,\n'
          '            BankUiStrings.defaults.$legacy,\n'
          '          ) ??\n';
  return '  String get $key =>\n$pick'
      '      _l10n?.$key ??\n'
      '      _en.$key;\n';
}

String _method(String key, Map<String, dynamic> placeholders) {
  final params = placeholders.entries
      .map((e) => '${_dartType(e.value)} ${e.key}')
      .join(', ');
  final args = placeholders.keys.join(', ');
  final compact = '  String $key($params) =>';
  final body = ' _l10n?.$key($args) ?? _en.$key($args);';
  if ((compact + body).length <= 80) return '$compact$body\n';
  // A wrapped parameter list needs its own trailing comma, or
  // `require_trailing_commas` fires on the formatted output.
  final signature = compact.length <= 80
      ? compact
      : [
          '  String $key(',
          for (final entry in placeholders.entries)
            '    ${_dartType(entry.value)} ${entry.key},',
          '  ) =>',
        ].join('\n');
  return '$signature\n'
      '      _l10n?.$key($args) ??\n'
      '      _en.$key($args);\n';
}

String _dartType(Object? spec) {
  final type = (spec as Map<String, dynamic>?)?['type'] as String?;
  return switch (type) {
    'int' => 'int',
    'double' => 'double',
    'num' => 'num',
    'DateTime' => 'DateTime',
    _ => 'String',
  };
}

/// Wraps a description into `///` lines that fit the 80-column lint.
List<String> _wrapDoc(String text) {
  final words = text.split(' ');
  final lines = <String>[];
  var current = '  ///';
  for (final word in words) {
    if ('$current $word'.length > 80) {
      lines.add(current);
      current = '  /// $word';
    } else {
      current = '$current $word';
    }
  }
  lines.add(current);
  return lines;
}
