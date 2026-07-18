import 'dart:math' as math;

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative-luminance of a single linearised channel (0..1 input).
double _linearize(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// WCAG 2.1 relative luminance of [color]. Uses the modern 0..1 component
/// accessors (`.r/.g/.b`) so no deprecated APIs are touched.
double _luminance(Color color) =>
    0.2126 * _linearize(color.r) +
    0.7152 * _linearize(color.g) +
    0.0722 * _linearize(color.b);

/// WCAG 2.1 contrast ratio between two opaque colors (1.0 .. 21.0).
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Every built-in theme, keyed by a human label for readable failure messages.
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

/// Asserts [fg] on [bg] clears [min]:1, with a readable failure message.
void _expectContrast(Color fg, Color bg, double min, String reason) {
  expect(
    contrastRatio(fg, bg),
    greaterThanOrEqualTo(min),
    reason: reason,
  );
}

void main() {
  // AA thresholds (WCAG 1.4.3 / 1.4.11).
  const aaText = 4.5; // normal body text
  const aaLargeOrNonText = 3.0; // large/bold text, icons, UI components

  group('WCAG contrast — text pairs meet AA (4.5:1) in every preset', () {
    _allThemes().forEach((name, t) {
      test('$name: onPrimary vs primary', () {
        _expectContrast(
          t.onPrimary,
          t.primary,
          aaText,
          '$name onPrimary on primary is below AA',
        );
      });
      test('$name: onSurface vs surface', () {
        _expectContrast(
          t.onSurface,
          t.surface,
          aaText,
          '$name onSurface on surface is below AA',
        );
      });
      test('$name: onSurfaceVariant vs surface', () {
        _expectContrast(
          t.onSurfaceVariant,
          t.surface,
          aaText,
          '$name secondary text on surface is below AA',
        );
      });
      test('$name: onBackground vs background', () {
        _expectContrast(
          t.onBackground,
          t.background,
          aaText,
          '$name onBackground on background is below AA',
        );
      });
    });
  });

  group('WCAG contrast — financial semantic colors are legible (>= 4.5:1)', () {
    // positive/negative/pending render as bold numerals and status icons; we
    // hold them to full AA text contrast against both canvases to be safe.
    _allThemes().forEach((name, t) {
      for (final canvas in [
        ('surface', t.surface),
        ('background', t.background),
      ]) {
        test('$name: positiveBalance vs ${canvas.$1}', () {
          _expectContrast(
            t.positiveBalance,
            canvas.$2,
            aaText,
            '$name positiveBalance on ${canvas.$1} is below AA',
          );
        });
        test('$name: negativeBalance vs ${canvas.$1}', () {
          _expectContrast(
            t.negativeBalance,
            canvas.$2,
            aaText,
            '$name negativeBalance on ${canvas.$1} is below AA',
          );
        });
        test('$name: pending vs ${canvas.$1}', () {
          _expectContrast(
            t.pending,
            canvas.$2,
            aaText,
            '$name pending on ${canvas.$1} is below AA',
          );
        });
      }
    });
  });

  group('WCAG contrast — muted "frozen" state meets non-text AA (>= 3:1)', () {
    _allThemes().forEach((name, t) {
      test('$name: frozen vs surface', () {
        _expectContrast(
          t.frozen,
          t.surface,
          aaLargeOrNonText,
          '$name frozen on surface is below the 3:1 UI-component floor',
        );
      });
    });
  });

  test('contrastRatio helper matches known WCAG anchors', () {
    // Black on white is the canonical 21:1; white on white is 1:1.
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21.0, 0.1),
    );
    expect(
      contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
      closeTo(1.0, 0.01),
    );
  });
}
