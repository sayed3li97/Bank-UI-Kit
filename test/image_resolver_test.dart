import 'dart:typed_data';

import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1x1 transparent PNG, small enough to decode instantly in tests.
final Uint8List _transparentPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82, //
]);

/// Hosts [child] in a themed [BankUiScope] so [BankEmblem] can resolve
/// [BankThemeData.of] and the scope's image resolver.
Widget _host(Widget child, BankUiScopeData data) {
  return BankUiScope(
    initialData: data,
    child: MaterialApp(
      theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Image _emblemImage(WidgetTester tester) => tester.widget<Image>(
      find.descendant(
        of: find.byType(BankEmblem),
        matching: find.byType(Image),
      ),
    );

void main() {
  const url = 'https://cdn.example.com/avatars/ada.png';

  testWidgets(
    'BankEmblem routes imageUrl through the scope imageResolver',
    (tester) async {
      final requestedUrls = <String>[];

      await tester.pumpWidget(
        _host(
          const BankEmblem(imageUrl: url, initialsFrom: 'Ada Lovelace'),
          BankUiScopeData(
            imageResolver: (u) {
              requestedUrls.add(u);
              return MemoryImage(_transparentPng);
            },
          ),
        ),
      );
      await tester.pump();

      final image = _emblemImage(tester);
      expect(image.image, isA<MemoryImage>());
      expect(image.image, isNot(isA<NetworkImage>()));
      expect(requestedUrls, [url]);
    },
  );

  testWidgets(
    'BankEmblem imageProvider bypasses URL resolution entirely',
    (tester) async {
      var resolverCalls = 0;
      final provider = MemoryImage(_transparentPng);

      await tester.pumpWidget(
        _host(
          BankEmblem(imageUrl: url, imageProvider: provider),
          BankUiScopeData(
            imageResolver: (u) {
              resolverCalls++;
              return MemoryImage(_transparentPng);
            },
          ),
        ),
      );
      await tester.pump();

      expect(_emblemImage(tester).image, same(provider));
      expect(resolverCalls, 0);
    },
  );

  testWidgets(
    'BankEmblem falls back to NetworkImage when no resolver is set',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const BankEmblem(imageUrl: url),
          const BankUiScopeData(),
        ),
      );

      final image = _emblemImage(tester);
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, url);

      // Drain the (failing) mock network load handled by the emblem's
      // errorBuilder so the test ends with no pending image work.
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test('BankUiScopeData wires imageResolver through copyWith and ==', () {
    ImageProvider resolve(String u) => MemoryImage(_transparentPng);

    const base = BankUiScopeData();
    final withResolver = base.copyWith(imageResolver: resolve);

    expect(base.imageResolver, isNull);
    expect(withResolver.imageResolver, same(resolve));
    expect(withResolver, isNot(equals(base)));
    expect(
      withResolver.copyWith(privacyEnabled: true).imageResolver,
      same(resolve),
    );
    expect(base.copyWith(), equals(base));
  });
}
