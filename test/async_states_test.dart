// Loading / error / empty state coverage: the shimmer reads as a lighter band
// travelling through the placeholder shapes (never a dark slab, never in the
// gaps), stacked tiles are phase-offset, reduced motion stops the ticker
// outright, and BankAsyncContent picks the right surface and speaks the change.
import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _captureKey = Key('capture');

/// A background nothing in the kit paints, so any pixel still carrying it is
/// provably untouched by the shimmer.
const Color _canvas = Color(0xFF00FF00);

/// One shimmer sweep, pinned so tests can pump to an exact phase.
const Duration _sweep = Duration(milliseconds: 1000);

ThemeData _appTheme(
  Brightness brightness, [
  BankPreset preset = BankPreset.studio,
]) =>
    preset.apply(
      brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
    );

BankThemeData _bankTheme(Brightness brightness) =>
    _appTheme(brightness).extension<BankThemeData>()!;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  bool supportsAnnounce = false,
  double width = 300,
  bool keepState = false,
  BankPreset preset = BankPreset.studio,
}) =>
    tester.pumpWidget(
      MaterialApp(
        // A fresh key per pump discards the previous tree, so a shimmer
        // controller never carries its phase into the next case. Cases that
        // exercise an in-place state *change* opt out with [keepState].
        key: keepState ? const ValueKey<String>('app') : UniqueKey(),
        theme: _appTheme(brightness, preset),
        builder: (context, inner) => Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
              supportsAnnounce: supportsAnnounce,
            ),
            child: inner!,
          ),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              // The canvas sits *inside* the capture boundary, so a rasterised
              // pixel that still carries it was provably never painted over.
              child: RepaintBoundary(
                key: _captureKey,
                child: ColoredBox(color: _canvas, child: child),
              ),
            ),
          ),
        ),
      ),
    );

/// Rasterises the captured subtree at 1:1 and returns its pixels.
Future<_Pixels> _rasterise(WidgetTester tester) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  late ByteData bytes;
  late int width;
  late int height;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    width = image.width;
    height = image.height;
    bytes = (await image.toByteData())!;
    image.dispose();
  });
  return _Pixels(bytes.buffer.asUint8List(), width, height);
}

class _Pixels {
  const _Pixels(this.data, this.width, this.height);

  final Uint8List data;
  final int width;
  final int height;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      data[i + 3],
      data[i],
      data[i + 1],
      data[i + 2],
    );
  }

  double luminanceAt(int x, int y) => at(x, y).computeLuminance();
}

/// The opaque fill every placeholder block is painted in.
Color _placeholderFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(BankSkeletonBox),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  group('BankSkeletonLoader shimmer', () {
    testWidgets('highlight band is lighter than the placeholder fill',
        (tester) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          const BankSkeletonLoader(
            height: 40,
            animationDuration: _sweep,
          ),
          brightness: brightness,
        );
        // Half a sweep puts the band's peak dead centre.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final fill = _placeholderFill(tester);
        final pixels = await _rasterise(tester);
        final centre = pixels.luminanceAt(pixels.width ~/ 2, 20);
        final shoulder = pixels.luminanceAt(2, 20);

        // The whole point of item 31: the travelling band is LIGHTER than the
        // slab it crosses, in both brightnesses.
        expect(
          centre,
          greaterThan(fill.computeLuminance()),
          reason: 'band must lighten the placeholder in $brightness',
        );
        expect(centre, greaterThan(shoulder));
        // …and outside the band the slab is exactly its resting tone.
        expect(shoulder, closeTo(fill.computeLuminance(), 0.01));
      }
    });

    testWidgets('band lightens under every preset, light and dark',
        (tester) async {
      for (final preset in BankPreset.values) {
        for (final brightness in Brightness.values) {
          await _pump(
            tester,
            const BankSkeletonLoader(height: 40, animationDuration: _sweep),
            brightness: brightness,
            preset: preset,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final pixels = await _rasterise(tester);
          final centre = pixels.luminanceAt(pixels.width ~/ 2, 20);
          final shoulder = pixels.luminanceAt(2, 20);
          expect(
            centre,
            greaterThan(shoulder),
            reason: '${preset.name} / ${brightness.name} band must lighten',
          );
        }
      }
    });

    testWidgets('band is clipped to the shapes and never paints the gaps',
        (tester) async {
      await _pump(
        tester,
        const BankSkeletonLoader(
          variant: BankSkeletonVariant.transactionTile,
          animationDuration: _sweep,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pixels = await _rasterise(tester);
      // (2, 2) sits in the row's padding — no placeholder there. If the band
      // were painted across the whole tile it would tint this pixel.
      expect(pixels.at(2, 2), _canvas);
      expect(pixels.at(pixels.width ~/ 2, 2), _canvas);
    });

    testWidgets('stacked tiles are phase-offset, and not when told otherwise',
        (tester) async {
      Future<double> deltaBetweenTiles(double phaseOffset) async {
        await _pump(
          tester,
          BankSkeletonLoader(
            count: 2,
            height: 40,
            itemSpacing: 0,
            phaseOffset: phaseOffset,
            animationDuration: _sweep,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final pixels = await _rasterise(tester);
        final x = pixels.width ~/ 2;
        return (pixels.luminanceAt(x, 20) - pixels.luminanceAt(x, 60)).abs();
      }

      expect(await deltaBetweenTiles(0), lessThan(0.001));
      expect(await deltaBetweenTiles(0.12), greaterThan(0.01));
    });

    testWidgets('sweep mirrors under RTL', (tester) async {
      Future<List<double>> edges(TextDirection direction) async {
        await _pump(
          tester,
          const BankSkeletonLoader(height: 40, animationDuration: _sweep),
          textDirection: direction,
        );
        await tester.pump();
        // Two-thirds through the sweep the band has left the centre and sits
        // over the trailing third of the placeholder.
        await tester.pump(const Duration(milliseconds: 650));
        final pixels = await _rasterise(tester);
        return [
          pixels.luminanceAt(40, 20),
          pixels.luminanceAt(pixels.width - 40, 20),
        ];
      }

      final ltr = await edges(TextDirection.ltr);
      final rtl = await edges(TextDirection.rtl);

      // LTR: the band has travelled towards the right edge. RTL: the mirror.
      expect(ltr[1], greaterThan(ltr[0]));
      expect(rtl[0], greaterThan(rtl[1]));
    });

    testWidgets('reduced motion stops the ticker and drops the mask',
        (tester) async {
      await _pump(
        tester,
        const BankSkeletonLoader(
          variant: BankSkeletonVariant.listTile,
          count: 3,
        ),
        disableAnimations: true,
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      // Static, but still a full set of placeholders.
      expect(find.byType(BankSkeletonBox), findsWidgets);
    });

    testWidgets('shimmer runs when motion is allowed', (tester) async {
      await _pump(
        tester,
        const BankSkeletonLoader(
          variant: BankSkeletonVariant.listTile,
          count: 3,
        ),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNWidgets(3));
      expect(tester.hasRunningAnimations, isTrue);

      final mask = tester.widget<ShaderMask>(find.byType(ShaderMask).first);
      expect(mask.blendMode, BlendMode.srcATop);
    });

    testWidgets('placeholder fill is an opaque theme-derived tone',
        (tester) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          const BankSkeletonLoader(height: 40),
          brightness: brightness,
        );
        final fill = _placeholderFill(tester);
        final theme = _bankTheme(brightness);

        expect(fill.a, 1.0, reason: 'blocks must not be a translucent wash');
        expect(fill, isNot(theme.surface));
      }
    });

    testWidgets('every variant lays out without overflow', (tester) async {
      for (final variant in BankSkeletonVariant.values) {
        await _pump(
          tester,
          BankSkeletonLoader(variant: variant, count: 2),
          width: 320,
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '$variant must lay out inside 320 px',
        );
        expect(find.byType(BankSkeletonBox), findsWidgets);
      }
    });

    testWidgets('a host-supplied shape inherits the loader fill',
        (tester) async {
      await _pump(
        tester,
        const BankSkeletonLoader(
          shape: SizedBox(height: 24, child: BankSkeletonBox()),
        ),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(_placeholderFill(tester).a, 1.0);
    });
  });

  // -------------------------------------------------------------------------
  // Published API contract
  //
  // 0.3.0 appended listTile, card, balanceHero, and chart to a four-value enum
  // that 0.2.0 shipped. Dart 3 checks switch exhaustiveness, so that is a
  // compile break for any adopter switching over the enum without a wildcard
  // arm — which doc/enterprise/stability-and-support.md classifies as breaking
  // and CHANGELOG.md must record as such. The break is disclosed; this gate
  // exists so the *next* one cannot land silently.
  // -------------------------------------------------------------------------

  group('BankSkeletonVariant is a published enum', () {
    test('its values and their order are pinned', () {
      expect(
        BankSkeletonVariant.values.map((variant) => variant.name).toList(),
        <String>[
          // Shipped in 0.2.0. These four keep their names and their positions,
          // so a persisted index or name still resolves to the same shape.
          'accountCard',
          'transactionTile',
          'potCard',
          'generic',
          // Appended in 0.3.0, recorded there as a breaking change.
          'listTile',
          'card',
          'balanceHero',
          'chart',
        ],
        reason: 'Adding, removing, renaming, or reordering a value of an '
            'exported enum is a breaking change under '
            'doc/enterprise/stability-and-support.md. Edit this list only '
            'alongside a Breaking entry in CHANGELOG.md.',
      );
    });

    test('the 0.2.0 values keep their indices', () {
      expect(BankSkeletonVariant.accountCard.index, 0);
      expect(BankSkeletonVariant.transactionTile.index, 1);
      expect(BankSkeletonVariant.potCard.index, 2);
      expect(BankSkeletonVariant.generic.index, 3);
    });
  });

  group('BankAsyncContent', () {
    Widget subject(
      BankAsyncStatus status, {
      VoidCallback? onRetry,
      WidgetBuilder? loadingBuilder,
    }) =>
        BankAsyncContent(
          status: status,
          loadingBuilder: loadingBuilder,
          skeletonVariant: BankSkeletonVariant.transactionTile,
          skeletonCount: 2,
          errorTitle: 'Transactions unavailable',
          errorMessage: 'We could not reach your account.',
          onRetry: onRetry,
          emptyTitle: 'No transactions yet',
          emptySubtitle: 'Your payments will appear here.',
          contentBuilder: (context) => const Text('rows'),
        );

    testWidgets('renders the surface matching the status', (tester) async {
      await _pump(tester, subject(BankAsyncStatus.loading));
      await tester.pump();
      expect(find.byType(BankSkeletonLoader), findsOneWidget);

      await _pump(tester, subject(BankAsyncStatus.error, onRetry: () {}));
      await tester.pumpAndSettle();
      expect(find.byType(BankErrorStateView), findsOneWidget);
      expect(find.text('Transactions unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await _pump(tester, subject(BankAsyncStatus.empty));
      await tester.pumpAndSettle();
      expect(find.byType(BankEmptyStateView), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);

      await _pump(tester, subject(BankAsyncStatus.content));
      await tester.pumpAndSettle();
      expect(find.text('rows'), findsOneWidget);
    });

    testWidgets('a custom builder wins over the default surface',
        (tester) async {
      await _pump(
        tester,
        subject(
          BankAsyncStatus.loading,
          loadingBuilder: (context) => const Text('custom'),
        ),
      );
      await tester.pump();

      expect(find.text('custom'), findsOneWidget);
      expect(find.byType(BankSkeletonLoader), findsNothing);
    });

    testWidgets('announces the change, but says nothing on first build',
        (tester) async {
      final spoken = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          final event = message! as Map<Object?, Object?>;
          if (event['type'] == 'announce') {
            final data = event['data']! as Map<Object?, Object?>;
            spoken.add(data['message']! as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
      );

      await _pump(
        tester,
        subject(BankAsyncStatus.loading),
        supportsAnnounce: true,
        keepState: true,
      );
      await tester.pump();
      expect(spoken, isEmpty, reason: 'arriving mid-load is not a change');

      await _pump(
        tester,
        subject(BankAsyncStatus.content),
        supportsAnnounce: true,
        keepState: true,
      );
      await tester.pumpAndSettle();
      expect(spoken, contains('Content loaded'));

      await _pump(
        tester,
        subject(BankAsyncStatus.error, onRetry: () {}),
        supportsAnnounce: true,
        keepState: true,
      );
      await tester.pumpAndSettle();
      expect(spoken, contains('Transactions unavailable'));
    });

    testWidgets('stays silent where the platform cannot announce',
        (tester) async {
      final spoken = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          final event = message! as Map<Object?, Object?>;
          if (event['type'] == 'announce') spoken.add('spoke');
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
      );

      await _pump(tester, subject(BankAsyncStatus.loading), keepState: true);
      await tester.pump();
      await _pump(tester, subject(BankAsyncStatus.content), keepState: true);
      await tester.pumpAndSettle();

      expect(spoken, isEmpty);
    });

    testWidgets('reduced motion swaps surfaces with no cross-fade',
        (tester) async {
      await _pump(
        tester,
        subject(BankAsyncStatus.loading),
        disableAnimations: true,
        keepState: true,
      );
      await tester.pump();

      await _pump(
        tester,
        subject(BankAsyncStatus.content),
        disableAnimations: true,
        keepState: true,
      );
      // One frame, no settle: the swap must already be complete.
      await tester.pump();

      expect(find.text('rows'), findsOneWidget);
      expect(find.byType(BankSkeletonLoader), findsNothing);
    });
  });
}
