import 'package:bank_ui_kit/core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the currency-rendering pass (ranks 42 and 62) and the review /
/// approval / document hierarchy pass (ranks 69, 71, 73).

// ---------------------------------------------------------------------------
// Unicode bidi controls under test
// ---------------------------------------------------------------------------

const String lri = '\u2066'; // LEFT-TO-RIGHT ISOLATE
const String rli = '\u2067'; // RIGHT-TO-LEFT ISOLATE
const String fsi = '\u2068'; // FIRST STRONG ISOLATE
const String pdi = '\u2069'; // POP DIRECTIONAL ISOLATE
const String nbsp = '\u00A0';

/// Whether every isolate initiator in [s] is matched by a [pdi].
bool isolatesBalanced(String s) {
  var depth = 0;
  for (final rune in s.runes) {
    final c = String.fromCharCode(rune);
    if (c == lri || c == rli || c == fsi) depth++;
    if (c == pdi) depth--;
    if (depth < 0) return false;
  }
  return depth == 0;
}

// ---------------------------------------------------------------------------
// Widget harness
// ---------------------------------------------------------------------------

Widget host(
  Widget child, {
  BankPreset preset = BankPreset.studio,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return BankUiScope(
    initialData: BankUiScopeData(preset: preset),
    child: MaterialApp(
      theme: preset.apply(base),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// Every invisible directional control the kit wraps a machine identifier
/// in for display (U+2066 LRI … U+2069 PDI, see `BankBidi`). A lookup by
/// what the customer actually reads should not have to spell them.
final RegExp _bidiControls = RegExp('[\u2066-\u2069]');

/// The first [Text] whose visible data equals [data], directional controls
/// discounted.
Text textWidget(WidgetTester tester, String data) =>
    tester.widgetList<Text>(find.byType(Text)).firstWhere(
          (t) => t.data?.replaceAll(_bidiControls, '') == data,
          orElse: () => fail('no Text with data "$data"'),
        );

const BankBeneficiary beneficiary = BankBeneficiary(
  id: 'ben1',
  name: 'Omar Farouk',
  maskedAccount: '•••• 8842',
  type: BeneficiaryType.bankTransfer,
  bankName: 'Gulf International Bank',
  isVerified: true,
);

void main() {
  // -------------------------------------------------------------------------
  // Rank 42 — currency spacing
  // -------------------------------------------------------------------------

  group('rank 42: fallback-font currency symbols keep their gap', () {
    test('VND separates the dong sign from its digits', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1000000'),
        currencyCode: 'VND',
      );
      expect(s, '1,000,000$nbsp₫');
      // The glue is the defect: never '1,000,000₫'.
      expect(s.contains('0₫'), isFalse);
    });

    test('the gap is a no-break space, so an amount cannot wrap in two', () {
      for (final code in ['VND', 'SEK', 'CHF', 'BHD', 'ZZZ']) {
        final s = BankMoneyFormatter.format(
          amount: Decimal.parse('1234'),
          currencyCode: code,
        );
        expect(s.contains(' '), isFalse, reason: '$code used a plain space');
        expect(s.contains(nbsp), isTrue, reason: '$code lost its gap');
      }
    });

    test('unspaced currencies are left unspaced', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('1234'),
          currencyCode: 'THB',
        ),
        '฿1,234.00',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Rank 42 — bidi isolation
  // -------------------------------------------------------------------------

  group('rank 42: Gulf markers isolate the symbol, gap stays outside', () {
    test('the gap belongs to the marker, not to the paragraph', () {
      final s = BankMoneyFormatter.format(
        amount: Decimal.parse('1234.567'),
        currencyCode: 'BHD',
      );
      // The isolate wraps the marker alone and the gap sits outside it, on
      // the amount's side. U+00A0 is bidi class CS: inside the isolate it
      // resolves to R next to the AL-derived marker and reorders to the far
      // side of it, which is what produced a leading space and marker glued
      // to digits. Outside, it is a lone neutral between an opaque isolate
      // and a number, so it takes the embedding direction and stays put.
      expect(s, '$fsiد.ب$pdi$nbsp' '1,234.567');
      expect(isolatesBalanced(s), isTrue);
    });

    test('a bare neutral gap is never left between marker and digits', () {
      for (final code in ['SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD']) {
        final s = BankMoneyFormatter.format(
          amount: Decimal.parse('1234.5'),
          currencyCode: code,
        );
        expect(
          s.contains('$pdi$nbsp'),
          isTrue,
          reason: '$code lost its gap',
        );
        expect(
          s.contains('$nbsp$pdi'),
          isFalse,
          reason: '$code packed the gap inside its isolate',
        );
        expect(isolatesBalanced(s), isTrue);
      }
    });

    test('a Gulf amount ends in digits, never in a format character', () {
      // A string ending in a directional-format character lays out with a
      // spurious overflow flag in an RTL paragraph under the negative
      // letter-spacing the kit's numeral styles use, so the default
      // composition never produces one.
      for (final code in ['SAR', 'AED', 'KWD', 'BHD', 'OMR']) {
        for (final raw in ['1234.5', '-1234.5']) {
          final s = BankMoneyFormatter.format(
            amount: Decimal.parse(raw),
            currencyCode: code,
          );
          expect(
            s.endsWith(pdi),
            isFalse,
            reason: '$code $raw ends in a format character',
          );
        }
      }
    });

    test('Latin-symbol currencies stay bare', () {
      for (final code in ['GBP', 'USD', 'JPY', 'SEK', 'VND', 'ZZZ']) {
        final s = BankMoneyFormatter.format(
          amount: Decimal.parse('1234.5'),
          currencyCode: code,
        );
        expect(s.contains(fsi), isFalse, reason: '$code gained an isolate');
        expect(s.contains(lri), isFalse, reason: '$code gained an isolate');
      }
    });

    test('bidiIsolate pins the whole atom, sign included', () {
      // The RTL defect this exists for: a bare leading '-' is a neutral and
      // resolves with the paragraph, not with the digits it belongs to.
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-1234.5'),
          currencyCode: 'USD',
          bidiIsolate: true,
        ),
        '$lri-\$1,234.50$pdi',
      );
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('-1234.5'),
          currencyCode: 'BHD',
          bidiIsolate: true,
        ),
        '$lri-$fsiد.ب$pdi$nbsp' '1,234.500$pdi',
      );
    });

    test('splitMajorMinor reassembles exactly and never leaks an isolate', () {
      for (final code in ['BHD', 'KWD', 'AED', 'SAR', 'VND', 'GBP', 'SEK']) {
        for (final raw in ['1234.5', '-1234.5', '25000', '0']) {
          for (final iso in [true, false]) {
            final amount = Decimal.parse(raw);
            final parts = BankMoneyFormatter.splitMajorMinor(
              amount: amount,
              currencyCode: code,
              showSign: true,
              bidiIsolate: iso,
            );
            final joined = parts.major + parts.minor + parts.suffix;
            expect(
              joined,
              BankMoneyFormatter.format(
                amount: amount,
                currencyCode: code,
                showSign: true,
                bidiIsolate: iso,
              ),
              reason: '$code $raw (isolate: $iso) must reassemble exactly',
            );
            expect(
              isolatesBalanced(joined),
              isTrue,
              reason: '$code $raw (isolate: $iso) left an isolate open',
            );
            for (final span in [parts.major, parts.minor, parts.suffix]) {
              expect(
                span.split(pdi).length - 1 <= span.length,
                isTrue,
                reason: 'span sanity',
              );
            }
          }
        }
      }
    });

    test('trimZeroCents closes an opted-in isolate on the major span', () {
      final parts = BankMoneyFormatter.splitMajorMinor(
        amount: Decimal.parse('25000'),
        currencyCode: 'BHD',
        trimZeroCents: true,
        bidiIsolate: true,
      );
      expect(parts.minor, '');
      expect(isolatesBalanced(parts.major), isTrue);
    });

    testWidgets('a Gulf amount lays out cleanly in both directions',
        (tester) async {
      final formatted = BankMoneyFormatter.format(
        amount: Decimal.parse('1234567.891'),
        currencyCode: 'BHD',
      );
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            Text(
              formatted,
              style: BankTokens.numeralHero,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            direction: direction,
          ),
        );
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(formatted));
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '$direction reported a phantom overflow',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Rank 62 — currency disambiguation
  // -------------------------------------------------------------------------

  group('rank 62: mixed-currency prize rows are disambiguated', () {
    final draws = [
      BankPrizeDraw(
        id: 'grand',
        prizeLabel: 'Grand cash prize',
        prizeAmount: Money.fromDouble(500000, 'USD'),
        drawDate: DateTime(2026, 5, 13),
        lastDepositDate: DateTime(2026, 5, 4),
        isGrand: true,
      ),
      BankPrizeDraw(
        id: 'monthly',
        prizeLabel: 'Monthly cash prize',
        prizeAmount: Money.fromDouble(10000, 'BHD'),
        drawDate: DateTime(2026, 6, 13),
        lastDepositDate: DateTime(2026, 6, 4),
      ),
    ];

    test('useIsoCode renders the code, never the symbol', () {
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('500000'),
          currencyCode: 'USD',
          useIsoCode: true,
          trimZeroCents: true,
        ),
        'USD${nbsp}500,000',
      );
      // Minor units survive the swap: BHD is still a 3-decimal currency.
      expect(
        BankMoneyFormatter.format(
          amount: Decimal.parse('10000.5'),
          currencyCode: 'BHD',
          useIsoCode: true,
        ),
        'BHD${nbsp}10,000.500',
      );
    });

    testWidgets('a USD prize inside a BHD programme switches the list to codes',
        (tester) async {
      await tester.pumpWidget(
        host(
          BankPrizeDrawCard(
            balance: Money.fromDouble(1250, 'BHD'),
            entriesCount: 25,
            draws: draws,
            clock: () => DateTime(2026, 5, 4),
          ),
        ),
      );
      expect(find.text('USD${nbsp}500,000'), findsOneWidget);
      expect(find.text('BHD${nbsp}10,000'), findsOneWidget);
      // No bare symbol is left to confuse the two rows.
      expect(find.textContaining(r'$500,000'), findsNothing);
    });

    testWidgets('a single-currency list keeps the currency symbol',
        (tester) async {
      await tester.pumpWidget(
        host(
          BankPrizeDrawCard(
            balance: Money.fromDouble(1250, 'BHD'),
            entriesCount: 25,
            draws: [draws[1]],
            clock: () => DateTime(2026, 5, 4),
          ),
        ),
      );
      final expected = BankMoneyFormatter.format(
        amount: Decimal.parse('10000'),
        currencyCode: 'BHD',
        trimZeroCents: true,
      );
      expect(find.text(expected), findsOneWidget);
      expect(find.text('BHD${nbsp}10,000'), findsNothing);
    });

    testWidgets('useIsoCurrencyCodes overrides the automatic choice',
        (tester) async {
      await tester.pumpWidget(
        host(
          BankPrizeDrawCard(
            balance: Money.fromDouble(1250, 'BHD'),
            entriesCount: 25,
            draws: [draws[1]],
            useIsoCurrencyCodes: true,
            clock: () => DateTime(2026, 5, 4),
          ),
        ),
      );
      expect(find.text('BHD${nbsp}10,000'), findsOneWidget);
    });

    testWidgets('a grand badge no longer shunts its own row sideways',
        (tester) async {
      await tester.pumpWidget(
        host(
          BankPrizeDrawCard(
            balance: Money.fromDouble(1250, 'BHD'),
            entriesCount: 25,
            draws: draws,
            clock: () => DateTime(2026, 5, 4),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('USD${nbsp}500,000')).dx,
        tester.getTopLeft(find.text('BHD${nbsp}10,000')).dx,
      );
    });

    testWidgets('a non-monetary prize still renders its label', (tester) async {
      await tester.pumpWidget(
        host(
          BankPrizeDrawCard(
            balance: Money.fromDouble(1250, 'BHD'),
            entriesCount: 25,
            draws: [
              BankPrizeDraw(
                id: 'car',
                prizeLabel: 'Porsche 911 Carrera S',
                drawDate: DateTime(2026, 5, 13),
                lastDepositDate: DateTime(2026, 5, 4),
              ),
            ],
            clock: () => DateTime(2026, 5, 4),
          ),
        ),
      );
      expect(find.text('Porsche 911 Carrera S'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Rank 69 — transfer review hierarchy
  // -------------------------------------------------------------------------

  group('rank 69: BankTransferReviewCard establishes a hierarchy', () {
    Future<BankThemeData> pumpCard(WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          BankTransferReviewCard(
            amount: Money.fromDouble(500, 'GBP'),
            beneficiary: beneficiary,
            fee: Money.fromDouble(0, 'GBP'),
            estimatedArrival: 'Within 2 hours',
          ),
        ),
      );
      return BankThemeData.of(
        tester.element(find.byType(BankTransferReviewCard)),
      );
    }

    testWidgets('the amount outranks every supporting row', (tester) async {
      final theme = await pumpCard(tester);

      final amount = textWidget(tester, '£500.00').style!;
      final arrival = textWidget(tester, 'Within 2 hours').style!;
      final arrivalLabel = textWidget(tester, 'Arrives').style!;

      expect(amount.fontSize, theme.numeralLarge.fontSize);
      expect(amount.fontSize! > arrival.fontSize!, isTrue);
      expect(arrival.fontSize! > arrivalLabel.fontSize!, isTrue);
      expect(arrivalLabel.color, theme.onSurfaceVariant);
    });

    testWidgets('the amount carries a caps micro-label', (tester) async {
      final theme = await pumpCard(tester);
      final label = textWidget(tester, 'AMOUNT').style!;
      expect(label.letterSpacing, BankTokens.trackingCaps);
      expect(label.color, theme.onSurfaceVariant);
    });

    testWidgets('the account mask is legible on its own line', (tester) async {
      final theme = await pumpCard(tester);
      final mask = textWidget(tester, '•••• 8842').style!;

      // Full ink at numeral size, not caption grey glued to the bank name.
      expect(mask.color, theme.onSurface);
      expect(mask.fontSize, theme.numeralSmall.fontSize);
      expect(mask.fontFeatures, theme.numeralSmall.fontFeatures);

      final bank = textWidget(tester, 'Gulf International Bank').style!;
      expect(bank.color, theme.onSurfaceVariant);
      expect(bank.fontSize! < mask.fontSize!, isTrue);
    });

    testWidgets('maskStyle overrides only the mask', (tester) async {
      await tester.pumpWidget(
        host(
          BankTransferReviewCard(
            amount: Money.fromDouble(500, 'GBP'),
            beneficiary: beneficiary,
            maskStyle: const TextStyle(color: Color(0xFF00FF00)),
          ),
        ),
      );
      expect(
        textWidget(tester, '•••• 8842').style!.color,
        const Color(0xFF00FF00),
      );
    });

    testWidgets('the hero still announces as a label/value pair',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);
      expect(find.bySemanticsLabel('Amount: £500.00'), findsOneWidget);
      handle.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Rank 71 — SCA approval sheet colour discipline
  // -------------------------------------------------------------------------

  group('rank 71: BankScaApprovalSheet spends one accent plus status', () {
    Widget sheet({DateTime? expiresAt, Duration? threshold}) =>
        BankScaApprovalSheet(
          amount: Money.fromDouble(1250, 'GBP'),
          payeeName: 'Acme Trading LLC',
          payeeAccountMasked: 'SA44 •••• 9021',
          methods: const {BankScaMethod.pin},
          expiresAt: expiresAt,
          expiryWarningThreshold: threshold ?? const Duration(minutes: 1),
          onApprove: (_, __) async => true,
          onReject: () {},
        );

    testWidgets('the header mark is the accent, not an alarm colour',
        (tester) async {
      await tester.pumpWidget(host(sheet()));
      final theme =
          BankThemeData.of(tester.element(find.byType(BankScaApprovalSheet)));

      final header = tester.widget<Icon>(find.byIcon(BankIcons.shield));
      expect(header.color, theme.primary);

      // Nothing on a resting approval sheet paints the raw warning token.
      final inks = <Color?>[
        for (final icon in tester.widgetList<Icon>(find.byType(Icon)))
          icon.color,
        for (final text in tester.widgetList<Text>(find.byType(Text)))
          text.style?.color,
      ];
      expect(inks, isNot(contains(BankTokens.warning)));
    });

    testWidgets('a comfortable countdown stays neutral', (tester) async {
      await tester.pumpWidget(
        host(sheet(expiresAt: DateTime.now().add(const Duration(minutes: 5)))),
      );
      final theme =
          BankThemeData.of(tester.element(find.byType(BankScaApprovalSheet)));
      final chip = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.data ?? '').startsWith('Expires in'));
      expect(chip.style!.color, theme.onSurfaceVariant);
    });

    testWidgets('a short countdown escalates to the pending colour',
        (tester) async {
      await tester.pumpWidget(
        host(
          sheet(
            expiresAt: DateTime.now().add(const Duration(seconds: 20)),
            threshold: const Duration(seconds: 30),
          ),
        ),
      );
      // The chip resolves on the first tick of the countdown.
      await tester.pump(const Duration(seconds: 1));
      final theme =
          BankThemeData.of(tester.element(find.byType(BankScaApprovalSheet)));
      final chip = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.data ?? '').startsWith('Expires in'));
      expect(chip.style!.color, theme.pending);
    });

    testWidgets('reject follows the theme, so it survives dark mode',
        (tester) async {
      await tester.pumpWidget(
        host(sheet(), brightness: Brightness.dark),
      );
      final theme =
          BankThemeData.of(tester.element(find.byType(BankScaApprovalSheet)));
      final reject = textWidget(tester, 'Reject payment').style!;
      expect(reject.color, theme.negativeBalance);
      // The hardcoded token this used to paint is a light-surface red.
      expect(reject.color, isNot(BankTokens.danger));
    });

    testWidgets('the destination mask is legible, not caption grey',
        (tester) async {
      await tester.pumpWidget(host(sheet()));
      final theme =
          BankThemeData.of(tester.element(find.byType(BankScaApprovalSheet)));
      final mask = textWidget(tester, 'SA44 •••• 9021').style!;
      expect(mask.color, theme.onSurface);
      expect(mask.fontSize, theme.numeralSmall.fontSize);
    });

    Widget opener({bool? showHandle}) => host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => BankScaApprovalSheet.show(
                context,
                amount: Money.fromDouble(1250, 'GBP'),
                payeeName: 'Acme Trading LLC',
                methods: const {BankScaMethod.pin},
                showHandle: showHandle,
                onApprove: (_, __) async => true,
                onReject: () {},
              ),
              child: const Text('open'),
            ),
          ),
        );

    testWidgets('presentation comes from BankSheet, not a hand-rolled surface',
        (tester) async {
      await tester.pumpWidget(opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BankSheetSurface), findsOneWidget);
      // Non-dismissible by design, so BankSheet's `showHandle ?? enableDrag`
      // rule drops the handle rather than promising a drag that does nothing.
      expect(find.byType(BankSheetHandle), findsNothing);
    });

    testWidgets('a host whose SCA flow is dismissible can ask for the handle',
        (tester) async {
      await tester.pumpWidget(opener(showHandle: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BankSheetHandle), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Rank 73 — statement rows
  // -------------------------------------------------------------------------

  group('rank 73: BankStatementListTile subtitle', () {
    BankDocument doc(DateTime date, {int? bytes}) => BankDocument(
          id: 'st1',
          title: 'June 2026 statement',
          periodOrDate: date,
          type: BankDocumentType.statement,
          fileSizeBytes: bytes,
        );

    testWidgets('a date-only period never prints a midnight time',
        (tester) async {
      await tester.pumpWidget(
        host(
          BankStatementListTile(
            document: doc(DateTime(2026, 6, 30), bytes: 245000),
            onView: () {},
          ),
        ),
      );
      expect(find.text('30 June 2026 · 245${nbsp}KB'), findsOneWidget);
      expect(find.textContaining('00:00'), findsNothing);
    });

    testWidgets('a real timestamp keeps its time', (tester) async {
      await tester.pumpWidget(
        host(
          BankStatementListTile(
            document: doc(DateTime(2026, 6, 30, 14, 32)),
            onView: () {},
          ),
        ),
      );
      expect(find.text('30 June 2026, 14:32'), findsOneWidget);
    });

    test('formatLongOrDate picks per value', () {
      expect(
        BankDateFormatter.formatLongOrDate(DateTime(2026, 6, 30)),
        '30 June 2026',
      );
      expect(
        BankDateFormatter.formatLongOrDate(DateTime(2026, 6, 30, 0, 0, 1)),
        '30 June 2026, 00:00',
      );
      expect(
        BankDateFormatter.carriesTimeOfDay(DateTime(2026, 6, 30)),
        isFalse,
      );
      expect(
        BankDateFormatter.carriesTimeOfDay(
          DateTime(2026, 6, 30, 0, 0, 0, 1),
        ),
        isTrue,
      );
    });

    test('formatFileSize rolls over instead of printing 1000 KB', () {
      expect(BankStatementListTile.formatFileSize(0), '0${nbsp}B');
      expect(BankStatementListTile.formatFileSize(999), '999${nbsp}B');
      expect(BankStatementListTile.formatFileSize(1000), '1.0${nbsp}KB');
      expect(BankStatementListTile.formatFileSize(1500), '1.5${nbsp}KB');
      expect(BankStatementListTile.formatFileSize(245000), '245${nbsp}KB');
      // The old implementation printed '1000 KB' here.
      expect(BankStatementListTile.formatFileSize(999999), '1.0${nbsp}MB');
      expect(BankStatementListTile.formatFileSize(3400000000), '3.4${nbsp}GB');
    });
  });
}
