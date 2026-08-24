/// Guard suite for the Accessibility Conformance Report in
/// `doc/enterprise/acr/`.
///
/// An ACR is only worth publishing while every sentence in it is still true.
/// This suite is the ratchet that keeps it true: it parses
/// `doc/enterprise/acr/openacr.yaml` offline and fails the build when a claim
/// there stops matching the code, the tokens, or the tests that back it.
///
/// Three properties are enforced.
///
/// 1. **No silent drift.** The report's product version tracks `pubspec.yaml`,
///    its criteria set is exactly WCAG 2.1 Level A + AA, and every file path
///    cited as evidence still exists. A renamed widget file breaks this suite
///    rather than quietly turning the report into fiction.
/// 2. **No unbacked "supports".** Every criterion claimed as `supports` must be
///    registered in [_supportsEvidence] against either a named automated gate
///    that runs here, or an explicit manual-review marker. Adding a new
///    `supports` row without doing one of those two things fails the build.
/// 3. **The gates still hold.** The registered gates re-verify contrast, the
///    tap-target token, the motion floor, the source-level "we ship none of
///    this" claims, and two behavioural claims (pointer cancellation and
///    keyboard activation) against the live package.
///
/// Deliberately offline and dependency-free: validating against the upstream
/// GSA OpenACR schema needs the network and a Node toolchain, so it stays a
/// release-time step (documented in `ACR.md`) rather than a CI gate.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const String _acrYamlPath = 'doc/enterprise/acr/openacr.yaml';
const String _acrMarkdownPath = 'doc/enterprise/acr/ACR.md';
const String _contrastGatePath = 'test/accessibility_contrast_test.dart';
const String _guidelineGatePath = 'test/accessibility_widget_test.dart';
const String _privacyGatePath = 'test/privacy_mask_test.dart';
const String _tokenGatePath = 'test/design_tokens_test.dart';
const String _statementPath = 'doc/enterprise/accessibility-conformance.md';

/// The OpenACR catalog this report is written against: the edition whose
/// criteria set is WCAG 2.1 plus EN 301 549 V3.2.1, which is the standard the
/// European Accessibility Act points at.
const String _expectedCatalog = '2.4-edition-wcag-2.1-508-eu-en';

/// The conformance vocabulary defined by the OpenACR catalog. `not-evaluated`
/// is excluded on purpose: the catalog permits it only for WCAG Level AAA,
/// which this report does not cover, so its presence would be a defect.
const Set<String> _allowedLevels = {
  'supports',
  'partially-supports',
  'does-not-support',
  'not-applicable',
};

/// WCAG 2.1 Level A, exactly as enumerated by the OpenACR catalog. Hard-coded
/// so that quietly dropping an inconvenient criterion fails the build.
const List<String> _wcag21LevelA = [
  '1.1.1', '1.2.1', '1.2.2', '1.2.3', '1.3.1', '1.3.2', '1.3.3', '1.4.1',
  '1.4.2', '2.1.1', '2.1.2', '2.1.4', '2.2.1', '2.2.2', '2.3.1', '2.4.1',
  '2.4.2', '2.4.3', '2.4.4', '2.5.1', '2.5.2', '2.5.3', '2.5.4', '3.1.1',
  '3.2.1', '3.2.2', '3.3.1', '3.3.2', '4.1.1', '4.1.2', //
];

/// WCAG 2.1 Level AA, exactly as enumerated by the OpenACR catalog.
const List<String> _wcag21LevelAA = [
  '1.2.4', '1.2.5', '1.3.4', '1.3.5', '1.4.3', '1.4.4', '1.4.5', '1.4.10',
  '1.4.11', '1.4.12', '1.4.13', '2.4.5', '2.4.6', '2.4.7', '3.1.2', '3.2.3',
  '3.2.4', '3.3.3', '3.3.4', '4.1.3', //
];

/// Every `supports` claim in the report, mapped to the evidence that justifies
/// it. Keys are `<chapter>:<criterion>`.
///
/// A value naming a gate in [_gates] means the claim is machine-verified on
/// every run. `_manual` means the claim rests on documented human review and
/// is allowed to stand — the report says so in the same words. There is no
/// third option: an unregistered `supports` row fails
/// `every "supports" claim is registered against evidence`.
const Map<String, String> _supportsEvidence = {
  'success_criteria_level_a:1.3.3': _manual,
  'success_criteria_level_a:2.3.1': 'motion-floor',
  'success_criteria_level_a:2.5.2': 'behaviour:pointer-cancellation',
  'success_criteria_level_a:3.2.1': _manual,
  'success_criteria_level_aa:1.4.5': 'no-raster-assets',
  'success_criteria_level_aa:3.2.4': 'token-gate-present',
  'en_301_549_functional_performance:4.2.9': 'motion-floor',
  'en_301_549_functional_performance:4.2.11': 'privacy-semantics-gate',
  'en_301_549_generic_requirements:5.2': _manual,
  'en_301_549_generic_requirements:5.9': 'no-multipoint-gestures',
  'en_301_549_software:11.6.1': 'no-platform-overrides',
  'en_301_549_documentation_and_support_services:12.1.1': 'docs-published',
  'en_301_549_documentation_and_support_services:12.2.2': 'docs-published',
};

const String _manual = 'manual-review';

// ---------------------------------------------------------------------------
// Gates
// ---------------------------------------------------------------------------

/// Named automated gates referenced by [_supportsEvidence]. Each throws (via
/// `expect`) when the claim it backs stops being true.
final Map<String, void Function()> _gates = {
  // WCAG 2.3.1 / EN 4.2.9: no animation can reach three cycles per second.
  // Every animation in the kit is driven by one of these four tokens, so a
  // floor on the tokens is a floor on the flash rate.
  'motion-floor': () {
    for (final d in <Duration>[
      BankTokens.durationFast,
      BankTokens.durationBase,
      BankTokens.durationSlow,
      BankTokens.durationXSlow,
    ]) {
      expect(
        d.inMilliseconds,
        greaterThanOrEqualTo(150),
        reason: 'The ACR claims no kit animation can flash three times per '
            'second. A motion token below 150 ms breaks that claim.',
      );
    }
  },

  // WCAG 1.4.5: the package bundles fonts and nothing else, so no string can
  // reach the user as a picture of text.
  'no-raster-assets': () {
    final assets = Directory('lib/src/assets');
    expect(assets.existsSync(), isTrue, reason: 'lib/src/assets is missing.');
    final strays = assets
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where((p) => !p.endsWith('.ttf') && !p.endsWith('.otf'))
        .toList();
    expect(
      strays,
      isEmpty,
      reason: 'The ACR claims 1.4.5 Images of Text is fully supported because '
          'the package ships only font assets. Non-font assets found: $strays',
    );
  },

  // WCAG 3.2.4: consistent identification rests on one pinned token set.
  'token-gate-present': () {
    _expectFileContains(_tokenGatePath, const [
      'BankTokens.minTapTarget',
    ]);
    expect(BankTokens.minTapTarget, greaterThanOrEqualTo(44));
  },

  // EN 4.2.11 Privacy: the mask must change what is *announced*, not only what
  // is drawn. Both halves of that assertion must still exist.
  'privacy-semantics-gate': () {
    _expectFileContains(_privacyGatePath, const [
      "bySemanticsLabel('Balance hidden')",
      "bySemanticsLabel(RegExp('Balance: '))",
    ]);
  },

  // EN 5.9 / WCAG 2.5.1: no interaction requires two pointers.
  'no-multipoint-gestures': () {
    _expectLibraryFree(
      const [
        'onScaleStart',
        'onScaleUpdate',
        'onScaleEnd',
        'InteractiveViewer',
      ],
      claim: 'EN 301 549 clause 5.9 is claimed as supported because no '
          'interaction requires simultaneous user actions.',
    );
  },

  // EN 11.6.1: the kit never overrides a platform accessibility setting.
  'no-platform-overrides': () {
    _expectLibraryFree(
      const ['SystemChrome'],
      claim: 'EN 301 549 clause 11.6.1 is claimed as supported because the '
          'kit installs no platform-level overrides.',
    );
  },

  // EN 12.1.1 / 12.2.2: the accessibility documentation the report points at
  // must actually be published alongside the code.
  'docs-published': () {
    for (final path in const [
      _acrMarkdownPath,
      _statementPath,
      'doc/enterprise/design-tokens.md',
    ]) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'The ACR claims accessibility documentation is published, but '
            '$path is missing.',
      );
    }
  },
};

/// Behavioural claims proved by `testWidgets` cases further down rather than by
/// a synchronous gate. Registered here so [_supportsEvidence] can name them.
const Set<String> _behaviouralGates = {
  'behaviour:pointer-cancellation',
  'behaviour:keyboard-activation',
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late final Map<String, Object?> acr;

  setUpAll(() {
    final file = File(_acrYamlPath);
    expect(
      file.existsSync(),
      isTrue,
      reason: '$_acrYamlPath is the machine-readable ACR and must exist.',
    );
    acr = _parseYaml(file.readAsStringSync());
  });

  group('OpenACR document integrity', () {
    test('product version matches pubspec', () {
      final declared = _string(_dig(acr, ['product', 'version']));
      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final versionLine = pubspec.firstWhere(
        (l) => l.startsWith('version:'),
        orElse: () => '',
      );
      final actual = versionLine.split(':').last.trim();
      expect(
        declared,
        actual,
        reason: 'The ACR reports on version $declared but the package is at '
            '$actual. Re-issue the ACR with the release, or the report '
            'describes code nobody is shipping.',
      );
    });

    test('declares the WCAG 2.1 + EN 301 549 catalog', () {
      expect(_string(acr['catalog']), _expectedCatalog);
    });

    test('names the evaluation as a self-assessment, not an audit', () {
      final methods = _string(acr['evaluation_methods_used']).toLowerCase();
      expect(
        methods,
        contains('self-assessment'),
        reason: 'Overclaiming the evaluation method is the fastest way to have '
            'the whole report discarded.',
      );
      expect(
        methods,
        contains('not a third-party audit'),
        reason: 'The report must say plainly that no third party audited it.',
      );
      // The report must keep listing what was never done. TalkBack/VoiceOver
      // behaviour is the claim a bank reviewer checks first.
      expect(methods, contains('talkback'));
      expect(methods, contains('voiceover'));
    });

    test('covers WCAG 2.1 Level A and AA in full', () {
      expect(
        _criteriaNumbers(acr, 'success_criteria_level_a'),
        _wcag21LevelA.toSet(),
        reason: 'Level A coverage drifted from the WCAG 2.1 criteria set.',
      );
      expect(
        _criteriaNumbers(acr, 'success_criteria_level_aa'),
        _wcag21LevelAA.toSet(),
        reason: 'Level AA coverage drifted from the WCAG 2.1 criteria set.',
      );
    });

    test('reports the EN 301 549 chapters that apply to a component library',
        () {
      final chapters = (acr['chapters']! as Map<String, Object?>).keys.toSet();
      for (final required in const [
        'en_301_549_functional_performance',
        'en_301_549_generic_requirements',
        'en_301_549_software',
        'en_301_549_documentation_and_support_services',
      ]) {
        expect(
          chapters,
          contains(required),
          reason: 'EN 301 549 chapter $required is missing from the ACR.',
        );
      }
      // Chapter 11 is the one a UI component library lives or dies by.
      final ch11 = _criteriaNumbers(acr, 'en_301_549_software');
      expect(ch11, contains('11.5.2.5')); // object information
      expect(ch11, contains('11.5.2.8')); // label relationships
      expect(ch11, contains('11.7')); // user preferences
    });

    test('every adherence uses a catalog level and carries a remark', () {
      for (final claim in _claims(acr)) {
        expect(
          _allowedLevels,
          contains(claim.level),
          reason: '${claim.key} uses "${claim.level}", which is not an OpenACR '
              'conformance level for a WCAG 2.1 A/AA report.',
        );
        expect(
          claim.notes.trim().length,
          greaterThan(40),
          reason: '${claim.key} has no substantive remark. Every row must name '
              'the mechanism that satisfies it or the gap that does not.',
        );
      }
    });

    test('every file cited as evidence exists', () {
      final pattern = RegExp(
        '(?:lib|test|doc|tokens|tool|example)/[A-Za-z0-9_./-]*'
        r'\.(?:dart|md|yaml|json)',
      );
      final cited = <String>{};
      for (final claim in _claims(acr)) {
        cited.addAll(pattern.allMatches(claim.notes).map((m) => m.group(0)!));
      }
      for (final key in const [
        'notes',
        'evaluation_methods_used',
      ]) {
        cited.addAll(
          pattern.allMatches(_string(acr[key])).map((m) => m.group(0)!),
        );
      }
      expect(cited, isNotEmpty, reason: 'The ACR cites no evidence at all.');
      final missing = cited.where((p) => !File(p).existsSync()).toList()
        ..sort();
      expect(
        missing,
        isEmpty,
        reason: 'The ACR cites files that no longer exist: $missing. Either '
            'restore them or re-word the remarks that depend on them.',
      );
    });
  });

  group('no "supports" claim without evidence', () {
    test('every "supports" claim is registered against evidence', () {
      final claimed = _claims(acr)
          .where((c) => c.level == 'supports')
          .map((c) => c.key)
          .toSet();
      final unregistered =
          claimed.difference(_supportsEvidence.keys.toSet()).toList()..sort();
      expect(
        unregistered,
        isEmpty,
        reason: 'These rows claim full support with no registered evidence: '
            '$unregistered. Wire an automated gate and register it in '
            '_supportsEvidence, or downgrade the row to partially-supports.',
      );

      final stale = _supportsEvidence.keys.toSet().difference(claimed).toList()
        ..sort();
      expect(
        stale,
        isEmpty,
        reason: 'These registry entries no longer correspond to a "supports" '
            'row and should be removed: $stale',
      );
    });

    test('every registered gate is implemented and passes', () {
      for (final entry in _supportsEvidence.entries) {
        final gate = entry.value;
        if (gate == _manual) {
          continue;
        }
        if (_behaviouralGates.contains(gate)) {
          continue; // proved by the testWidgets cases below.
        }
        final run = _gates[gate];
        expect(
          run,
          isNotNull,
          reason: '${entry.key} cites gate "$gate", which is not implemented.',
        );
        run!();
      }
    });

    test('the automated gates the report names are still in the suite', () {
      // The report describes these two suites as the CI gates behind its
      // contrast, tap-target, and label claims. If they lose their assertions
      // the report is describing coverage the repository no longer has.
      _expectFileContains(_contrastGatePath, const [
        'aaText = 4.5',
        'aaLargeOrNonText = 3.0',
        'onSurfaceVariant',
      ]);
      _expectFileContains(_guidelineGatePath, const [
        'meetsGuideline(iOSTapTargetGuideline)',
        'meetsGuideline(labeledTapTargetGuideline)',
      ]);
    });

    test('ACR.md states the same position as openacr.yaml', () {
      // The two files are one report in two renderings. A reviewer who reads
      // the prose and a procurement system that diffs the YAML must be told
      // the same thing, so every WCAG row in the Markdown tables is checked
      // against the machine-readable level it is supposed to render.
      final levels = <String, String>{
        for (final chapter in const [
          'success_criteria_level_a',
          'success_criteria_level_aa',
        ])
          for (final claim in _claims(acr).where(
            (c) => c.key.startsWith('$chapter:'),
          ))
            claim.key.split(':').last: claim.level,
      };

      const wording = <String, String>{
        'Supports': 'supports',
        'Partially Supports': 'partially-supports',
        'Does Not Support': 'does-not-support',
        'Not Applicable': 'not-applicable',
      };
      final row =
          RegExp(r'^\|\s*(\d+\.\d+\.\d+)[^|]*\|\s*(A|AA)\s*\|([^|]*)\|');

      var checked = 0;
      for (final line in File(_acrMarkdownPath).readAsLinesSync()) {
        final match = row.firstMatch(line.trim());
        if (match == null) continue;
        final criterion = match.group(1)!;
        final rendered = match.group(3)!.replaceAll('*', '').trim();
        expect(
          wording.keys,
          contains(rendered),
          reason: 'ACR.md row $criterion reads "$rendered", which is not one '
              'of the OpenACR conformance terms.',
        );
        expect(
          wording[rendered],
          levels[criterion],
          reason: 'ACR.md reports $criterion as "$rendered" but openacr.yaml '
              'records "${levels[criterion]}". The prose and the '
              'machine-readable report must agree.',
        );
        checked++;
      }
      expect(
        checked,
        _wcag21LevelA.length + _wcag21LevelAA.length,
        reason: 'ACR.md should render one table row per WCAG 2.1 A/AA '
            'criterion; $checked were found.',
      );
    });
  });

  group('gates behind partially-supported claims', () {
    // These back the *mechanism* half of "partially supports" rows. They are
    // gates in their own right: if the kit acquires a media player or a
    // keyboard shortcut, the corresponding "not applicable" row becomes a lie.
    test('1.2.x: the kit ships no audio or video', () {
      _expectLibraryFree(
        const ['VideoPlayer', 'AudioPlayer', 'video_player', 'just_audio'],
        claim: 'WCAG 1.2.1-1.2.5 are reported as not applicable because the '
            'kit ships no synchronised media.',
      );
    });

    test('2.1.4: the kit registers no keyboard shortcuts', () {
      _expectLibraryFree(
        const [
          'SingleActivator',
          'CharacterActivator',
          'CallbackShortcuts',
          'Shortcuts(',
        ],
        claim: 'WCAG 2.1.4 Character Key Shortcuts is reported as not '
            'applicable because the kit registers no shortcuts.',
      );
    });

    test('1.3.4: no widget locks device orientation', () {
      _expectLibraryFree(
        const ['SystemChrome'],
        claim: 'WCAG 1.3.4 Orientation rests on the kit never requesting an '
            'orientation.',
      );
    });

    test('1.4.4: no widget overrides the platform text scale', () {
      _expectLibraryFree(
        const ['textScaleFactor', 'TextScaler'],
        claim: 'WCAG 1.4.4 Resize Text rests on text inheriting the platform '
            'scale rather than a hard-coded one.',
      );
    });

    test('11.5.2.6: the kit ships no data grid', () {
      _expectLibraryFree(
        const ['DataTable'],
        claim: 'EN 301 549 clause 11.5.2.6 is reported as not applicable '
            'because the kit exposes no rows, columns, or table headers.',
      );
    });

    test('1.4.3: every preset still clears AA on its text roles', () {
      // Deliberately recomputed here instead of importing the helper from
      // accessibility_contrast_test.dart: a guard that shares an
      // implementation with the thing it guards agrees with it even when both
      // are wrong. Two independent implementations of the WCAG formula have to
      // agree for the claim to stand.
      for (final entry in _presets.entries) {
        final t = entry.value;
        for (final pair in <(String, Color, Color)>[
          ('onSurface/surface', t.onSurface, t.surface),
          ('onSurfaceVariant/surface', t.onSurfaceVariant, t.surface),
          ('onPrimary/primary', t.onPrimary, t.primary),
          ('onBackground/background', t.onBackground, t.background),
        ]) {
          expect(
            _contrastRatio(pair.$2, pair.$3),
            greaterThanOrEqualTo(4.5),
            reason: 'The ACR reports 1.4.3 as gated at 4.5:1 in all eight '
                'preset/brightness combinations. ${entry.key} '
                '${pair.$1} no longer clears it.',
          );
        }
        expect(
          _contrastRatio(t.frozen, t.surface),
          greaterThanOrEqualTo(3.0),
          reason: 'The ACR reports the frozen state as gated at 3:1 for '
              '1.4.11. ${entry.key} no longer clears it.',
        );
      }
    });
  });

  group('behavioural gates', () {
    testWidgets(
        '2.5.2 Pointer Cancellation: activation happens on the up-event',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Scaffold(
            body: Center(
              child: BankPressable(
                onTap: () => taps++,
                semanticLabel: 'Confirm transfer',
                child: const SizedBox(width: 160, height: 56),
              ),
            ),
          ),
        ),
      );

      // Positive control: the harness can register a tap at all. Without this,
      // the negative assertion below would pass on a broken test.
      await tester.tap(find.byType(BankPressable));
      await tester.pump(BankTokens.durationFast * 2);
      expect(taps, 1, reason: 'BankPressable did not fire on a plain tap.');

      // Press, drag away, release: the standard "I changed my mind" gesture.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(BankPressable)));
      await tester.pump();
      await gesture.moveTo(const Offset(20, 20));
      await tester.pump();
      await gesture.up();
      await tester.pump(BankTokens.durationFast * 2);

      expect(
        taps,
        1,
        reason: 'The ACR claims 2.5.2 as fully supported because no kit '
            'control acts on the down-event. Dragging off a pressed '
            'BankPressable still triggered its action.',
      );
    });

    testWidgets('2.1.1 Keyboard: Enter activates a focused BankPressable',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
          home: Scaffold(
            body: Center(
              child: BankPressable(
                onTap: () => taps++,
                semanticLabel: 'Confirm transfer',
                child: const SizedBox(width: 160, height: 56),
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      // Past the pressed-state flash BankPressable schedules on activation.
      await tester.pump(BankTokens.durationFast * 2);

      expect(
        taps,
        1,
        reason: 'The ACR describes keyboard activation via '
            'FocusableActionDetector as the mechanism behind 2.1.1. Enter no '
            'longer activates a focused BankPressable.',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Contrast (independent reimplementation — see the note at its call site)
// ---------------------------------------------------------------------------

Map<String, BankThemeData> get _presets => {
      'studio.light': BankStudioTheme.light(),
      'studio.dark': BankStudioTheme.dark(),
      'voltage.light': BankVoltageTheme.light(),
      'voltage.dark': BankVoltageTheme.dark(),
      'bloom.light': BankBloomTheme.light(),
      'bloom.dark': BankBloomTheme.dark(),
      'heritage.light': BankHeritageTheme.light(),
      'heritage.dark': BankHeritageTheme.dark(),
    };

double _channel(double v) =>
    v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _contrastRatio(Color a, Color b) {
  double lum(Color c) =>
      0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);
  final (hi, lo) = lum(a) >= lum(b) ? (lum(a), lum(b)) : (lum(b), lum(a));
  return (hi + 0.05) / (lo + 0.05);
}

// ---------------------------------------------------------------------------
// Source scanning
// ---------------------------------------------------------------------------

/// Asserts none of [needles] appears anywhere under `lib/`.
///
/// Several rows in the ACR are "not applicable" or "supports" precisely
/// *because* the package contains none of a given API. Those rows stop being
/// true the moment someone adds one, so the absence is asserted rather than
/// assumed.
void _expectLibraryFree(List<String> needles, {required String claim}) {
  final offenders = <String>[];
  for (final file in Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final source = file.readAsStringSync();
    for (final needle in needles) {
      if (source.contains(needle)) {
        offenders.add('${file.path}: $needle');
      }
    }
  }
  expect(
    offenders,
    isEmpty,
    reason: '$claim That claim is now false: $offenders. Update the ACR row '
        'before landing the change.',
  );
}

void _expectFileContains(String path, List<String> needles) {
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason: 'The ACR names $path as an enforcing gate, but it is missing.',
  );
  final source = file.readAsStringSync();
  for (final needle in needles) {
    expect(
      source.contains(needle),
      isTrue,
      reason: 'The ACR relies on $path asserting `$needle`, which is gone.',
    );
  }
}

// ---------------------------------------------------------------------------
// Claim extraction
// ---------------------------------------------------------------------------

/// One `<chapter>:<criterion>` position taken by the report.
class _Claim {
  const _Claim(this.key, this.level, this.notes);

  final String key;
  final String level;
  final String notes;
}

List<_Claim> _claims(Map<String, Object?> acr) {
  final out = <_Claim>[];
  final chapters = acr['chapters']! as Map<String, Object?>;
  chapters.forEach((chapter, body) {
    if (body is! Map<String, Object?>) return;
    final criteria = body['criteria'];
    if (criteria is! List) return;
    for (final criterion in criteria.cast<Map<String, Object?>>()) {
      final num = _string(criterion['num']);
      final components = criterion['components'];
      if (components is! List) continue;
      for (final component in components.cast<Map<String, Object?>>()) {
        final adherence = component['adherence'];
        if (adherence is! Map<String, Object?>) continue;
        out.add(
          _Claim(
            '$chapter:$num',
            _string(adherence['level']),
            _string(adherence['notes']),
          ),
        );
      }
    }
  });
  return out;
}

Set<String> _criteriaNumbers(Map<String, Object?> acr, String chapter) {
  final body = _dig(acr, ['chapters', chapter]);
  if (body is! Map<String, Object?>) return const {};
  final criteria = body['criteria'];
  if (criteria is! List) return const {};
  return criteria
      .cast<Map<String, Object?>>()
      .map((c) => _string(c['num']))
      .toSet();
}

Object? _dig(Object? node, List<String> path) {
  var current = node;
  for (final key in path) {
    if (current is! Map<String, Object?>) return null;
    current = current[key];
  }
  return current;
}

String _string(Object? value) => value == null ? '' : value.toString();

// ---------------------------------------------------------------------------
// Minimal YAML reader
// ---------------------------------------------------------------------------

/// Parses the exact YAML subset `openacr.yaml` is written in: two-space
/// indentation, `key: value` mappings, `- ` sequences of mappings, and folded
/// (`>-`) block scalars. It is not a general YAML parser and is not meant to
/// be one — the package has no YAML dependency, and adding one to read a single
/// documentation file would be a poor trade.
Map<String, Object?> _parseYaml(String source) {
  final lines = <_YamlLine>[];
  for (final raw in source.split('\n')) {
    final trimmed = raw.trimLeft();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    lines.add(_YamlLine(raw.length - trimmed.length, trimmed));
  }
  final parsed = _parseBlock(lines, 0, lines.isEmpty ? 0 : lines.first.indent);
  return parsed is Map<String, Object?> ? parsed : <String, Object?>{};
}

class _YamlLine {
  const _YamlLine(this.indent, this.text);

  final int indent;
  final String text;
}

/// Parses the lines at [indent] from [start], returning a map or a list.
Object _parseBlock(List<_YamlLine> lines, int start, int indent) {
  if (start >= lines.length) return <String, Object?>{};
  return lines[start].text.startsWith('- ')
      ? _parseSequence(lines, start, indent)
      : _parseMap(lines, start, indent);
}

List<Object?> _parseSequence(List<_YamlLine> lines, int start, int indent) {
  final items = <Object?>[];
  var i = start;
  while (i < lines.length &&
      lines[i].indent == indent &&
      lines[i].text.startsWith('- ')) {
    // Re-indent the inline part of `- key: value` so the item's body is one
    // uniform block, then parse that block as a mapping.
    final body = <_YamlLine>[_YamlLine(indent + 2, lines[i].text.substring(2))];
    i++;
    while (i < lines.length && lines[i].indent > indent) {
      body.add(lines[i]);
      i++;
    }
    items.add(_parseBlock(body, 0, indent + 2));
  }
  return items;
}

Map<String, Object?> _parseMap(List<_YamlLine> lines, int start, int indent) {
  final map = <String, Object?>{};
  var i = start;
  while (i < lines.length && lines[i].indent >= indent) {
    if (lines[i].indent > indent) {
      i++; // Defensive: stray deeper line with no owning key.
      continue;
    }
    final line = lines[i].text;
    final split = line.indexOf(':');
    if (split == -1) {
      i++;
      continue;
    }
    final key = line.substring(0, split).trim();
    final inline = line.substring(split + 1).trim();
    i++;

    final child = <_YamlLine>[];
    while (i < lines.length && lines[i].indent > indent) {
      child.add(lines[i]);
      i++;
    }

    if (inline == '>-' || inline == '>' || inline == '|' || inline == '|-') {
      final fold = inline.startsWith('|') ? '\n' : ' ';
      map[key] = child.map((l) => l.text).join(fold);
    } else if (inline.isEmpty) {
      map[key] =
          child.isEmpty ? null : _parseBlock(child, 0, child.first.indent);
    } else {
      map[key] = _scalar(inline);
    }
  }
  return map;
}

String _scalar(String raw) {
  if (raw.length >= 2) {
    final first = raw[0];
    if ((first == '"' || first == "'") && raw.endsWith(first)) {
      return raw.substring(1, raw.length - 1);
    }
  }
  return raw;
}
