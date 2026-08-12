import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/map/free_space.dart';
import 'package:arls_za/map/pack_manager.dart';
import 'package:arls_za/map/pack_store.dart';
import 'package:arls_za/map/region_pack.dart';
import 'package:arls_za/ui/region_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// §16.6. This screen spends several minutes of a player's attention over a
/// connection that may not survive them, so what matters is what it says when
/// things go wrong.
void main() {
  final payload = Uint8List.fromList(List<int>.generate(2048, (i) => i % 251));
  final checksum = sha256.convert(payload).toString();

  RegionPack packOf({
    required String id,
    required String name,
    required GeoBounds bounds,
    String? sha,
  }) => RegionPack(
    id: id,
    name: name,
    bounds: bounds,
    bytes: payload.length,
    sha256: sha ?? checksum,
    url: 'https://example.invalid/$id.pmtiles',
  );

  const wielkopolska = GeoBounds(
    south: 51.06,
    west: 15.68,
    north: 53.71,
    east: 19.19,
  );
  const malopolska = GeoBounds(
    south: 49.07,
    west: 19.08,
    north: 50.59,
    east: 21.44,
  );

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_picker_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  PackManager managerWith(
    List<RegionPack> packs, {
    PackDownloader? downloader,
    int? freeBytes = 1 << 30,
  }) => PackManager(
    catalogue: RegionCatalogue(packs),
    store: PackStore(
      directory: tempDir,
      downloader: downloader ?? _FakeDownloader(payload),
      freeSpaceMargin: 0,
    ),
    freeSpace: FixedFreeSpace(freeBytes),
  );

  /// Lets real file and stream work finish, then rebuilds.
  ///
  /// `pumpAndSettle` cannot be used on this screen: it waits for the frame
  /// pipeline to go quiet, and an indeterminate progress indicator never does.
  /// `runAsync` is also what lets the store's actual file I/O run. The count
  /// is deliberately generous: a download here is a real stream writing a real
  /// file, and a CI machine under load is slower than this one.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> pumpPicker(
    WidgetTester tester,
    PackManager manager, {
    double? latitude,
    double? longitude,
    VoidCallback? onDone,
    void Function(RegionPack pack)? onPlayStreamed,
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: RegionPickerScreen(
          manager: manager,
          nearLatitude: latitude,
          nearLongitude: longitude,
          onDone: onDone,
          onPlayStreamed: onPlayStreamed,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('the region under the player comes first and says so', (
    tester,
  ) async {
    final manager = managerWith([
      packOf(id: 'malopolskie', name: 'Małopolskie', bounds: malopolska),
      packOf(id: 'wielkopolskie', name: 'Wielkopolskie', bounds: wielkopolska),
    ]);

    // Poznań.
    await pumpPicker(tester, manager, latitude: 52.4064, longitude: 16.9252);

    final wielkopolskieY = tester.getTopLeft(find.text('Wielkopolskie')).dy;
    final malopolskieY = tester.getTopLeft(find.text('Małopolskie')).dy;

    expect(
      wielkopolskieY,
      lessThan(malopolskieY),
      reason: 'sixteen voivodeships with no hint is a quiz',
    );
    expect(find.textContaining('W twojej okolicy'), findsOneWidget);
  });

  testWidgets('an unpublished region is shown with a reason, not hidden', (
    tester,
  ) async {
    final manager = managerWith([
      packOf(id: 'lubuskie', name: 'Lubuskie', bounds: wielkopolska, sha: ''),
    ]);

    await pumpPicker(tester, manager);

    expect(
      find.text('Lubuskie'),
      findsOneWidget,
      reason: 'missing from a list reads as a bug',
    );
    expect(find.text('Niedostępny'), findsOneWidget);
    expect(
      find.text('Pobierz'),
      findsNothing,
      reason: 'a button that cannot work is worse than no button',
    );
  });

  testWidgets('a download reports progress and then reads as installed', (
    tester,
  ) async {
    final manager = managerWith([
      packOf(id: 'wielkopolskie', name: 'Wielkopolskie', bounds: wielkopolska),
    ]);
    var done = false;
    await pumpPicker(tester, manager, onDone: () => done = true);

    await tester.tap(find.text('Pobierz'));
    await settle(tester);

    expect(find.text('Pobrany'), findsOneWidget);
    expect(find.text('Usuń'), findsOneWidget);
    expect(done, isTrue);
  });

  testWidgets('too little room says so and keeps the button', (tester) async {
    final manager = PackManager(
      catalogue: RegionCatalogue([
        packOf(
          id: 'wielkopolskie',
          name: 'Wielkopolskie',
          bounds: wielkopolska,
        ),
      ]),
      store: PackStore(
        directory: tempDir,
        downloader: _FakeDownloader(payload),
        freeSpaceMargin: 64 * 1024 * 1024,
      ),
      freeSpace: const FixedFreeSpace(1024),
    );
    await pumpPicker(tester, manager);

    await tester.tap(find.text('Pobierz'));
    await settle(tester);

    expect(find.textContaining('Za mało miejsca'), findsOneWidget);
    expect(
      find.text('Spróbuj ponownie'),
      findsOneWidget,
      reason: 'a dead end is not an answer',
    );
  });

  testWidgets('a broken connection promises the next attempt finishes', (
    tester,
  ) async {
    final manager = managerWith([
      packOf(id: 'wielkopolskie', name: 'Wielkopolskie', bounds: wielkopolska),
    ], downloader: _FakeDownloader(payload, failAfter: 512));
    await pumpPicker(tester, manager);

    await tester.tap(find.text('Pobierz'));
    await settle(tester);

    expect(find.textContaining('Pobieranie przerwane'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
  });

  testWidgets('a file that fails its checksum says it was deleted', (
    tester,
  ) async {
    final manager = managerWith([
      packOf(
        id: 'wielkopolskie',
        name: 'Wielkopolskie',
        bounds: wielkopolska,
        sha: sha256.convert(Uint8List(8)).toString(),
      ),
    ]);
    await pumpPicker(tester, manager);

    await tester.tap(find.text('Pobierz'));
    await settle(tester);

    expect(find.textContaining('sumą kontrolną'), findsOneWidget);
    expect(find.text('Pobrany'), findsNothing);
  });

  group('playing without downloading (§16.6)', () {
    testWidgets('every published region offers it', (tester) async {
      final manager = managerWith([
        packOf(
          id: 'wielkopolskie',
          name: 'Wielkopolskie',
          bounds: wielkopolska,
        ),
      ]);

      await pumpPicker(tester, manager, onPlayStreamed: (_) {});

      expect(
        find.text('Graj teraz'),
        findsOneWidget,
        reason: 'nobody should wait for 235 MB to see whether they like it',
      );
    });

    testWidgets('an unpublished region offers neither way in', (tester) async {
      final manager = managerWith([
        packOf(id: 'lubuskie', name: 'Lubuskie', bounds: wielkopolska, sha: ''),
      ]);

      await pumpPicker(tester, manager, onPlayStreamed: (_) {});

      expect(find.text('Graj teraz'), findsNothing);
      expect(find.text('Pobierz'), findsNothing);
    });

    testWidgets('the cost is stated before it is paid', (tester) async {
      final manager = managerWith([
        packOf(
          id: 'wielkopolskie',
          name: 'Wielkopolskie',
          bounds: wielkopolska,
        ),
      ]);
      RegionPack? chosen;
      await pumpPicker(
        tester,
        manager,
        onPlayStreamed: (pack) => chosen = pack,
      );

      await tester.tap(find.text('Graj teraz'));
      await settle(tester);

      // Both costs, in words: a signal for the whole session, and the host
      // learning roughly where the player is.
      expect(find.textContaining('zasięgu przez całą sesję'), findsOneWidget);
      expect(find.textContaining('gdzie jesteś'), findsOneWidget);
      expect(chosen, isNull, reason: 'nothing happens until it is accepted');

      await tester.tap(find.text('Rozumiem, gram z sieci'));
      await settle(tester);

      expect(chosen!.id, 'wielkopolskie');
    });

    testWidgets('declining leaves the player where they were', (tester) async {
      final manager = managerWith([
        packOf(
          id: 'wielkopolskie',
          name: 'Wielkopolskie',
          bounds: wielkopolska,
        ),
      ]);
      var chosen = false;
      await pumpPicker(tester, manager, onPlayStreamed: (_) => chosen = true);

      await tester.tap(find.text('Graj teraz'));
      await settle(tester);
      await tester.tap(find.text('Przerwij'));
      await settle(tester);

      expect(chosen, isFalse);
      expect(find.text('Pobierz'), findsOneWidget);
    });
  });

  testWidgets('deleting a pack puts the download button back', (tester) async {
    final manager = managerWith([
      packOf(id: 'wielkopolskie', name: 'Wielkopolskie', bounds: wielkopolska),
    ]);
    await pumpPicker(tester, manager);
    await tester.tap(find.text('Pobierz'));
    await settle(tester);

    await tester.tap(find.text('Usuń'));
    await settle(tester);

    expect(find.text('Pobierz'), findsOneWidget);
    expect(find.text('Pobrany'), findsNothing);
  });

  testWidgets('reads in English too', (tester) async {
    final manager = managerWith([
      packOf(id: 'wielkopolskie', name: 'Wielkopolskie', bounds: wielkopolska),
    ]);

    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: RegionPickerScreen(manager: manager),
      ),
    );
    await settle(tester);

    expect(find.text('Choose a region'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });
}

class _FakeDownloader implements PackDownloader {
  _FakeDownloader(this.payload, {this.failAfter});

  final Uint8List payload;
  final int? failAfter;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) async* {
    const chunk = 512;
    var sent = 0;
    for (var start = offset; start < payload.length; start += chunk) {
      final end = (start + chunk).clamp(0, payload.length);
      if (failAfter != null && sent >= failAfter!) {
        throw const SocketException('connection reset');
      }
      sent += end - start;
      yield payload.sublist(start, end);
    }
  }
}
