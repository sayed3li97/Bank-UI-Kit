import 'dart:convert';
import 'dart:io';

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('BankThemeData JSON round-trip', () {
    _allThemes().forEach((name, theme) {
      test('$name survives toJson -> fromJson unchanged', () {
        final restored = BankThemeData.fromJson(theme.toJson());
        expect(restored, equals(theme), reason: '$name did not round-trip');
      });
    });

    test('toJson survives a JSON string encode/decode cycle', () {
      final theme = BankStudioTheme.light();
      final decoded =
          jsonDecode(jsonEncode(theme.toJson())) as Map<String, dynamic>;
      expect(BankThemeData.fromJson(decoded), equals(theme));
    });

    test('colors serialise as #RRGGBBAA hex', () {
      final json = BankHeritageTheme.light().toJson();
      final colors = json['colors'] as Map<String, dynamic>;
      expect(colors['primary'], matches(RegExp(r'^#[0-9A-F]{8}$')));
      // Heritage light primary is the deep forest green, fully opaque.
      expect(colors['primary'], '#006341FF');
    });

    test('partial payloads fall back to neutral defaults', () {
      final t = BankThemeData.fromJson(const {
        'colors': {'primary': '#123456'},
      });
      expect(t.primary, const Color(0xFF123456));
      expect(t.positiveBalance, BankTokens.positiveBalance); // default
    });
  });

  group('Generated tokens stay in sync with tokens/design-tokens.json', () {
    late Map<String, dynamic> src;

    setUpAll(() {
      final file = File('tokens/design-tokens.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'DTCG source of truth must exist',
      );
      src = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    Color hex(String key) {
      final v = ((src['color'] as Map)[key] as Map)[r'$value'] as String;
      final h = v.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    }

    test('semantic colours match the DTCG source', () {
      expect(BankTokens.positiveBalance, hex('positiveBalance'));
      expect(BankTokens.negativeBalance, hex('negativeBalance'));
      expect(BankTokens.pending, hex('pending'));
      expect(BankTokens.positiveBalanceDark, hex('positiveBalanceDark'));
      expect(BankTokens.frozen, hex('frozen'));
    });

    test('spacing + radius scalars match the DTCG source', () {
      expect(BankTokens.space4, 16);
      expect(BankTokens.radiusFull, 999);
      expect(BankTokens.minTapTarget, 44);
    });
  });
}
