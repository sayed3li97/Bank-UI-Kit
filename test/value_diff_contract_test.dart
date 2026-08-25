// Published API contract for BankValueDiffRow / BankValueDiffList.
//
// 0.3.0 gave the row a single old-to-new grammar in both BankValueDiffStyle
// variants, which silently retired the `previousLabel` / `newLabel`
// microlabels. A localised call site that still passes them compiles and
// renders nothing, so the only warning an adopter can get is the analyzer's.
// These gates pin both halves of that promise: the parameters really are
// no-ops, and every declaration of them really is annotated.
import 'dart:io';

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _source = 'lib/src/business/bank_value_diff_row.dart';

/// Every declaration the deprecation has to cover: the field and the
/// constructor parameter, on `BankValueDiffRow` and on `BankValueDiffList`.
const List<String> _declarations = [
  'final String previousLabel;',
  'final String newLabel;',
  "this.previousLabel = 'Previous',",
  "this.newLabel = 'New',",
];

/// The removing version the annotation must name, per the deprecation policy
/// in doc/enterprise/versioning-and-releases.md: deprecated in 0.3.0, so not
/// removed before 0.5.0.
const String _removingVersion = 'Removed in 0.5.0.';

Widget _host(Widget child) => BankUiScope(
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: Center(child: child)),
      ),
    );

/// The annotation block immediately above [at], or an empty list when the
/// declaration carries none.
List<String> _annotationAbove(List<String> lines, int at) {
  for (var i = at - 1; i >= 0 && at - i <= 10; i--) {
    if (lines[i].contains('@Deprecated(')) return lines.sublist(i, at);
    // A blank line or another member ends the search: an annotation further up
    // belongs to something else.
    if (lines[i].trim().isEmpty) return const [];
  }
  return const [];
}

void main() {
  group('BankValueDiffRow retired microlabels', () {
    test('every previousLabel / newLabel declaration carries @Deprecated', () {
      final lines = File(_source).readAsLinesSync();
      var checked = 0;

      for (var i = 0; i < lines.length; i++) {
        if (!_declarations.contains(lines[i].trim())) continue;
        checked++;
        final annotation = _annotationAbove(lines, i).join(' ');
        expect(
          annotation,
          contains('@Deprecated('),
          reason: '$_source:${i + 1} declares a parameter that is no longer '
              'rendered. Without @Deprecated a localised call site loses its '
              'text with no analyzer warning at all.',
        );
        expect(
          annotation,
          contains(_removingVersion),
          reason: '$_source:${i + 1}: the deprecation message must name the '
              'removing version, per the deprecation policy.',
        );
      }

      expect(
        checked,
        8,
        reason: 'expected a field and a constructor parameter for each of '
            'previousLabel and newLabel on both BankValueDiffRow and '
            'BankValueDiffList',
      );
    });

    testWidgets(
        'the stacked style renders neither supplied nor default '
        'microlabels', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 260,
            child: BankValueDiffRow(
              label: 'Limite',
              oldValue: '5 000,00 EUR',
              newValue: '8 000,00 EUR',
              style: BankValueDiffStyle.stacked,
              previousLabel: 'Precedent',
              newLabel: 'Nouveau',
            ),
          ),
        ),
      );

      // The no-op the @Deprecated message describes, pinned: neither the
      // localised values nor the English defaults reach the screen.
      expect(find.text('Precedent'), findsNothing);
      expect(find.text('Nouveau'), findsNothing);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('New'), findsNothing);

      // …and the grammar that replaced them is what the reviewer actually sees.
      expect(find.text('5 000,00 EUR'), findsOneWidget);
      expect(find.text('8 000,00 EUR'), findsOneWidget);
      expect(find.byIcon(BankIcons.forward), findsOneWidget);
    });

    testWidgets('the list does not forward them to its rows', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            child: BankValueDiffList(
              style: BankValueDiffStyle.stacked,
              previousLabel: 'Precedent',
              newLabel: 'Nouveau',
              items: [
                BankValueDiffItem(
                  label: 'Limite',
                  oldValue: '5 000,00 EUR',
                  newValue: '8 000,00 EUR',
                ),
              ],
            ),
          ),
        ),
      );

      final row = tester.widget<BankValueDiffRow>(
        find.byType(BankValueDiffRow),
      );
      // Forwarding would suppress the analyzer warning the adopter needs, so
      // the row is built with the defaults regardless of what the list holds.
      expect(row.previousLabel, 'Previous');
      expect(row.newLabel, 'New');
      expect(find.text('Precedent'), findsNothing);
      expect(find.text('Nouveau'), findsNothing);
    });
  });
}
