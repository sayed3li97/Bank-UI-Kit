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
      expect(t.shadowTint, isNull);
      expect(t.gradientReach, BankGradientRole.incidental);
    });

    test('shadow tint and gradient reach survive the round-trip', () {
      final bloom = BankBloomTheme.light();
      expect(bloom.shadowTint, isNotNull);
      expect(
        BankThemeData.fromJson(bloom.toJson()).shadowTint,
        bloom.shadowTint,
      );

      final voltage = BankVoltageTheme.dark();
      expect(voltage.gradientReach, BankGradientRole.hero);
      expect(
        BankThemeData.fromJson(voltage.toJson()).gradientReach,
        BankGradientRole.hero,
      );
    });

    test('a non-default reach is exported even without a gradient', () {
      // gradientReach is meaningless on its own, but dropping it when
      // accentGradient is null would silently lose a brand's policy the
      // moment it went through a server round-trip.
      final t = BankThemeData.custom(
        primary: const Color(0xFF123456),
        brightness: Brightness.light,
        gradientReach: BankGradientRole.hero,
      );
      expect(t.accentGradient, isNull);
      expect(
        BankThemeData.fromJson(t.toJson()).gradientReach,
        BankGradientRole.hero,
      );
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

    test('neutral ramp + surface/ink/border roles match the DTCG source', () {
      Color role(String group, String key) {
        final v = (((src[group] as Map)[key] as Map)[r'$value'] as String)
            .replaceFirst('#', '');
        // DTCG orders alpha last; Flutter wants it first.
        return v.length == 8
            ? Color(int.parse(v.substring(6) + v.substring(0, 6), radix: 16))
            : Color(int.parse('FF$v', radix: 16));
      }

      expect(BankTokens.neutral0, role('neutral', '0'));
      expect(BankTokens.neutral950, role('neutral', '950'));
      expect(BankTokens.surfaceBase, role('surface', 'base'));
      expect(BankTokens.surfaceRaisedDark, role('surface', 'raisedDark'));
      expect(BankTokens.inkMuted, role('ink', 'muted'));
      expect(BankTokens.borderOutline, role('border', 'outline'));
      expect(BankTokens.borderDividerDark, role('border', 'dividerDark'));
    });

    test('the neutral ramp is monotonic from white to near-black', () {
      // A ramp that is not ordered by luminance cannot be reasoned about:
      // "one rung darker" has to mean one rung darker.
      const ramp = [
        BankTokens.neutral0,
        BankTokens.neutral50,
        BankTokens.neutral100,
        BankTokens.neutral200,
        BankTokens.neutral300,
        BankTokens.neutral400,
        BankTokens.neutral500,
        BankTokens.neutral600,
        BankTokens.neutral700,
        BankTokens.neutral800,
        BankTokens.neutral900,
        BankTokens.neutral950,
      ];
      for (var i = 1; i < ramp.length; i++) {
        expect(
          ramp[i].computeLuminance(),
          lessThan(ramp[i - 1].computeLuminance()),
          reason: 'neutral ramp rung $i is not darker than rung ${i - 1}',
        );
      }
    });

    test('surface / ink / border roles are cut from the neutral ramp', () {
      // The roles are aliases, not a second palette: a role that drifts off
      // the ramp is how a fourth grey gets into the system.
      final ramp = <Color>{
        BankTokens.neutral0,
        BankTokens.neutral50,
        BankTokens.neutral100,
        BankTokens.neutral200,
        BankTokens.neutral300,
        BankTokens.neutral400,
        BankTokens.neutral500,
        BankTokens.neutral600,
        BankTokens.neutral700,
        BankTokens.neutral800,
        BankTokens.neutral900,
        BankTokens.neutral950,
      };
      for (final role in const {
        'surfaceSunken': BankTokens.surfaceSunken,
        'surfaceSunkenDark': BankTokens.surfaceSunkenDark,
        'surfaceBase': BankTokens.surfaceBase,
        'surfaceBaseDark': BankTokens.surfaceBaseDark,
        'surfaceRaised': BankTokens.surfaceRaised,
        'surfaceRaisedDark': BankTokens.surfaceRaisedDark,
        'inkStrong': BankTokens.inkStrong,
        'inkStrongDark': BankTokens.inkStrongDark,
        'inkMuted': BankTokens.inkMuted,
        'inkMutedDark': BankTokens.inkMutedDark,
        'inkFaint': BankTokens.inkFaint,
        'inkFaintDark': BankTokens.inkFaintDark,
        'borderOutline': BankTokens.borderOutline,
        'borderOutlineDark': BankTokens.borderOutlineDark,
      }.entries) {
        expect(ramp, contains(role.value), reason: '${role.key} is off-ramp');
      }
    });

    test('icon ladder and alpha ladder are ordered', () {
      const icons = [
        BankTokens.iconXSmall,
        BankTokens.iconSmall,
        BankTokens.iconMedium,
        BankTokens.iconLarge,
        BankTokens.iconXLarge,
        BankTokens.iconHero,
      ];
      for (var i = 1; i < icons.length; i++) {
        expect(icons[i], greaterThan(icons[i - 1]));
      }
      const alphas = [
        BankTokens.alphaFaint,
        BankTokens.alphaSubtle,
        BankTokens.alphaSoft,
        BankTokens.alphaMuted,
        BankTokens.alphaStrong,
        BankTokens.alphaScrim,
        BankTokens.alphaSecondaryInk,
      ];
      for (var i = 1; i < alphas.length; i++) {
        expect(alphas[i], greaterThan(alphas[i - 1]));
      }
    });

    test('elevation tier ranks match the enum order', () {
      for (final tier in BankElevationTier.values) {
        expect(tier.rank, tier.index);
      }
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

  group('Typography completeness', () {
    // Audit #63: an unset height falls back to the loaded font's own metrics,
    // so the same style occupies a different box under each preset's face.
    test('every text style pins a line height', () {
      const styles = {
        'displayLarge': BankTokens.displayLarge,
        'displayMedium': BankTokens.displayMedium,
        'headlineLarge': BankTokens.headlineLarge,
        'headlineMedium': BankTokens.headlineMedium,
        'headlineSmall': BankTokens.headlineSmall,
        'bodyLarge': BankTokens.bodyLarge,
        'bodyMedium': BankTokens.bodyMedium,
        'bodySmall': BankTokens.bodySmall,
        'labelLarge': BankTokens.labelLarge,
        'labelMedium': BankTokens.labelMedium,
        'labelSmall': BankTokens.labelSmall,
        'numeralHero': BankTokens.numeralHero,
        'numeralLarge': BankTokens.numeralLarge,
        'numeralMedium': BankTokens.numeralMedium,
        'numeralSmall': BankTokens.numeralSmall,
        'caption': BankTokens.caption,
        'captionCaps': BankTokens.captionCaps,
        'captionCapsWide': BankTokens.captionCapsWide,
      };
      final ladder = <double>{
        BankTokens.lineHeightTight,
        BankTokens.lineHeightSnug,
        BankTokens.lineHeightNormal,
        BankTokens.lineHeightRelaxed,
        BankTokens.lineHeightLoose,
        BankTokens.lineHeightAiry,
      };
      styles.forEach((name, style) {
        expect(style.height, isNotNull, reason: '$name has no line height');
        expect(
          ladder,
          contains(style.height),
          reason: '$name uses an off-ladder line height',
        );
      });
    });

    test('caps styles track, and sentence-case caption does not', () {
      // Positive tracking on sentence case reads loose, and it severs the
      // cursive joins in Arabic script — so it is caps-only by construction.
      expect(BankTokens.caption.letterSpacing, 0);
      expect(BankTokens.captionCaps.letterSpacing, BankTokens.trackingCaps);
      expect(
        BankTokens.captionCapsWide.letterSpacing,
        BankTokens.trackingCapsWide,
      );
      expect(BankTokens.captionCaps.fontSize, BankTokens.caption.fontSize);
      expect(BankTokens.captionCapsWide.fontSize, BankTokens.caption.fontSize);
    });
  });

  group('Depth & gradient policy', () {
    test('shadowFor tints a brand shadow without moving it', () {
      final bloom = BankBloomTheme.light();
      final tinted = bloom.shadowFor(BankElevationTier.card);
      final plain = BankTokens.shadowCardFor(Brightness.light);

      expect(tinted, hasLength(plain.length));
      for (var i = 0; i < tinted.length; i++) {
        expect(tinted[i].blurRadius, plain[i].blurRadius);
        expect(tinted[i].offset, plain[i].offset);
        expect(tinted[i].color.a, closeTo(plain[i].color.a, 0.001));
        expect(tinted[i].color.r, isNot(closeTo(plain[i].color.r, 0.001)));
      }
    });

    test('an untinted brand gets the token shadows unchanged', () {
      final studio = BankStudioTheme.light();
      expect(studio.shadowTint, isNull);
      expect(
        studio.shadowFor(BankElevationTier.card),
        BankTokens.shadowCardFor(Brightness.light),
      );
      expect(studio.shadowFor(BankElevationTier.flat), isEmpty);
    });

    test('shadow variant follows the background, not the surface', () {
      // A light-ink shadow is invisible on a near-black canvas.
      final voltage = BankVoltageTheme.dark();
      expect(
        voltage.shadowFor(BankElevationTier.hero),
        BankTokens.shadowHeroFor(Brightness.dark),
      );
    });

    test('Voltage demotes its gradient below the hero role', () {
      final voltage = BankVoltageTheme.dark();
      final full = voltage.accentGradient! as LinearGradient;

      expect(voltage.gradientFor(BankGradientRole.hero), same(full));
      expect(voltage.paintsFullGradientAt(BankGradientRole.hero), isTrue);

      for (final demoted in const [
        (BankGradientRole.accent, BankTokens.alphaStrong),
        (BankGradientRole.incidental, BankTokens.alphaSoft),
      ]) {
        final g = voltage.gradientFor(demoted.$1)! as LinearGradient;
        expect(voltage.paintsFullGradientAt(demoted.$1), isFalse);
        // Same hues and geometry, lower alpha: the brand still reads, it
        // just stops competing with the hero.
        expect(g.begin, full.begin);
        expect(g.end, full.end);
        for (var i = 0; i < g.colors.length; i++) {
          expect(g.colors[i].r, closeTo(full.colors[i].r, 0.001));
          expect(g.colors[i].a, closeTo(demoted.$2, 0.01));
        }
        // A translucent wash composites over the surface, so its content
        // must take surface ink, not onPrimary.
        expect(voltage.onGradientFor(demoted.$1), voltage.onSurface);
      }
      expect(voltage.onGradientFor(BankGradientRole.hero), voltage.onPrimary);
    });

    test('brands without a reach opt-in keep painting at full strength', () {
      // Heritage also ships a gradient; the policy is opt-in so no existing
      // brand changes appearance until it asks to.
      final heritage = BankHeritageTheme.light();
      expect(heritage.gradientReach, BankGradientRole.incidental);
      for (final role in BankGradientRole.values) {
        expect(heritage.gradientFor(role), same(heritage.accentGradient));
      }
    });

    test('a brand with no gradient resolves to null at every role', () {
      final studio = BankStudioTheme.light();
      expect(studio.accentGradient, isNull);
      for (final role in BankGradientRole.values) {
        expect(studio.gradientFor(role), isNull);
        expect(studio.paintsFullGradientAt(role), isFalse);
      }
    });
  });
}
