import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankPreset.apply', () {
    for (final preset in BankPreset.values) {
      test('${preset.name} registers a BankThemeData extension', () {
        final theme = preset.apply(ThemeData.light(useMaterial3: true));
        final bank = theme.extension<BankThemeData>();
        expect(bank, isNotNull);
        // Brand font is wired into the Material text theme.
        expect(theme.textTheme.bodyMedium?.fontFamily, isNotNull);
      });
    }
  });

  group('BankThemeData.custom', () {
    test('derives sensible defaults from primary + brightness', () {
      final theme = BankThemeData.custom(
        primary: const Color(0xFF0052CC),
        brightness: Brightness.light,
      );
      expect(theme.primary, const Color(0xFF0052CC));
      expect(theme.cardRadius, const BorderRadius.all(Radius.circular(12)));
      expect(theme.useGlow, isFalse);
    });

    test('respects explicit overrides', () {
      final theme = BankThemeData.custom(
        primary: const Color(0xFF0052CC),
        brightness: Brightness.dark,
        cardRadius: const BorderRadius.all(Radius.circular(20)),
        useGlow: true,
      );
      expect(theme.cardRadius, const BorderRadius.all(Radius.circular(20)));
      expect(theme.useGlow, isTrue);
    });

    test('dark brightness yields a dark surface', () {
      final dark = BankThemeData.custom(
        primary: const Color(0xFF0052CC),
        brightness: Brightness.dark,
      );
      final light = BankThemeData.custom(
        primary: const Color(0xFF0052CC),
        brightness: Brightness.light,
      );
      expect(dark.surface, isNot(light.surface));
    });
  });

  group('ThemeData.withBankTheme', () {
    test('registers the extension and syncs the color scheme', () {
      final bank = BankThemeData.custom(
        primary: const Color(0xFFE91E63),
        brightness: Brightness.light,
      );
      final theme = ThemeData.light(useMaterial3: true).withBankTheme(bank);
      expect(theme.extension<BankThemeData>(), bank);
      expect(theme.colorScheme.primary, const Color(0xFFE91E63));
    });
  });

  group('BankThemeData value semantics', () {
    test('copyWith overrides a single field and preserves the rest', () {
      final base = BankStudioTheme.light();
      final next = base.copyWith(primary: const Color(0xFF123456));
      expect(next.primary, const Color(0xFF123456));
      expect(next.surface, base.surface);
    });

    test('lerp(0) == this and lerp(1) == other', () {
      final a = BankStudioTheme.light();
      final b = BankBloomTheme.light();
      expect(a.lerp(b, 0).primary, a.primary);
      expect(a.lerp(b, 1).primary, b.primary);
    });

    test('equality and hashCode are consistent', () {
      expect(BankStudioTheme.light(), BankStudioTheme.light());
      expect(
        BankStudioTheme.light().hashCode,
        BankStudioTheme.light().hashCode,
      );
    });
  });
}
