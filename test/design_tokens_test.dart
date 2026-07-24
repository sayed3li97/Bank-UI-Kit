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

    test('premium brand fields survive the round-trip', () {
      final voltage = BankVoltageTheme.dark();
      final restoredVoltage = BankThemeData.fromJson(voltage.toJson());
      expect(restoredVoltage.cardPattern, BankCardPattern.mesh);
      expect(restoredVoltage.cardPatternColor, voltage.cardPatternColor);
      expect(restoredVoltage.cardSurfaceGradient, voltage.cardSurfaceGradient);

      final heritage = BankHeritageTheme.light();
      final restoredHeritage = BankThemeData.fromJson(heritage.toJson());
      expect(
        restoredHeritage.displayFontFamily,
        'packages/bank_ui_kit/NotoSerifDisplay',
      );
      expect(restoredHeritage.cardPattern, BankCardPattern.lattice);
    });

    test('old payloads without the new keys parse to defaults', () {
      final t = BankThemeData.fromJson(const {
        'colors': {'primary': '#123456'},
      });
      expect(t.displayFontFamily, isNull);
      expect(t.cardSurfaceGradient, isNull);
      expect(t.cardPattern, BankCardPattern.none);
      expect(t.cardPatternColor, isNull);
      expect(t.stateLayerHoverOpacity, BankTokens.stateLayerHoverOpacity);
      expect(t.stateLayerPressedOpacity, BankTokens.stateLayerPressedOpacity);
      expect(t.stateLayerFocusOpacity, BankTokens.stateLayerFocusOpacity);
      expect(t.disabledOpacity, BankTokens.disabledOpacity);
      expect(t.pressScale, BankTokens.pressScale);
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
      expect(BankTokens.success, hex('success'));
      expect(BankTokens.successDark, hex('successDark'));
      expect(BankTokens.warning, hex('warning'));
      expect(BankTokens.warningDark, hex('warningDark'));
      expect(BankTokens.danger, hex('danger'));
      expect(BankTokens.dangerDark, hex('dangerDark'));
      expect(BankTokens.networkMastercardRed, hex('networkMastercardRed'));
      expect(BankTokens.networkMastercardBlend, hex('networkMastercardBlend'));
      expect(BankTokens.networkAmexBlue, hex('networkAmexBlue'));
    });

    test('system feedback colours are unified: one family per hue', () {
      // Success / gain / available headroom share the positiveBalance green.
      expect(BankTokens.success, BankTokens.positiveBalance);
      expect(BankTokens.investmentGain, BankTokens.positiveBalance);
      expect(BankTokens.creditAvailable, BankTokens.positiveBalance);
      expect(BankTokens.successDark, BankTokens.positiveBalanceDark);
      expect(BankTokens.investmentGainDark, BankTokens.positiveBalanceDark);
      // Danger / loss share the negativeBalance red.
      expect(BankTokens.danger, BankTokens.negativeBalance);
      expect(BankTokens.investmentLoss, BankTokens.negativeBalance);
      expect(BankTokens.dangerDark, BankTokens.negativeBalanceDark);
      expect(BankTokens.investmentLossDark, BankTokens.negativeBalanceDark);
      // Warning / utilised credit share the pending amber.
      expect(BankTokens.warning, BankTokens.pending);
      expect(BankTokens.creditUsed, BankTokens.pending);
      expect(BankTokens.warningDark, BankTokens.pendingDark);
    });

    test('spacing + radius scalars match the DTCG source', () {
      expect(BankTokens.space4, 16);
      expect(BankTokens.radiusFull, 999);
      expect(BankTokens.minTapTarget, 44);
      expect(BankTokens.tileCompactBreakpoint, 168);
    });

    test('interaction + effect scalars match the DTCG source', () {
      double n(String group, String key) =>
          (((src[group] as Map)[key] as Map)[r'$value'] as num).toDouble();
      expect(
        BankTokens.stateLayerHoverOpacity,
        n('interaction', 'stateLayerHoverOpacity'),
      );
      expect(
        BankTokens.stateLayerPressedOpacity,
        n('interaction', 'stateLayerPressedOpacity'),
      );
      expect(
        BankTokens.stateLayerFocusOpacity,
        n('interaction', 'stateLayerFocusOpacity'),
      );
      expect(BankTokens.disabledOpacity, n('interaction', 'disabledOpacity'));
      expect(BankTokens.focusRingWidth, n('interaction', 'focusRingWidth'));
      expect(BankTokens.focusRingOpacity, n('interaction', 'focusRingOpacity'));
      expect(BankTokens.pressScale, n('interaction', 'pressScale'));
      expect(
        BankTokens.frozenCardSaturation,
        n('effect', 'frozenCardSaturation'),
      );
    });
  });
}
