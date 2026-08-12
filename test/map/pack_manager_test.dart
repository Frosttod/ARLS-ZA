import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arls_za/map/free_space.dart';
import 'package:arls_za/map/pack_coverage.dart';
import 'package:arls_za/map/pack_manager.dart';
import 'package:arls_za/map/pack_store.dart';
import 'package:arls_za/map/region_pack.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// §16.6. The screen that spends several minutes of a player's attention has to
/// know three things before it says anything: what is in the catalogue, what is
/// already on the disk, and what that file actually covers.
void main() {
  /// The real first 127 bytes of the Wielkopolskie pack. Using a genuine header
  /// means the manager is exercised against the extent Planetiler wrote, not a
  /// rectangle invented here.
  final headerBytes = Uint8List.fromList(
    base64Decode(
      'UE1UaWxlcwN/AAAAAAAAAH4AAAAAAAAAQzSyDgAAAAAZBQAAAAAAAFw5sg4AAAAAsHoCAAAAAAAA'
      'QAAAAAAAAEP0sQ4AAAAApVABAAAAAADVTAEAAAAAALBLAQAAAAAAAQICAQAPENdkCezNch6s5mYL'
      'BBT/Hwfe3mUK+PA4Hw==',
    ),
  );

  /// The same header with a different extent written into it. Two packs must
  /// not describe the same rectangle, or the test proves nothing about which
  /// one the manager picks.
  Uint8List headerCovering(GeoBounds bounds) {
    final bytes = Uint8List.fromList(headerBytes);
    final data = ByteData.sublistView(bytes);
    void degrees(int offset, double value) =>
        data.setInt32(offset, (value * 10000000).round(), Endian.little);

    degrees(102, bounds.west);
    degrees(106, bounds.south);
    degrees(110, bounds.east);
    degrees(114, bounds.north);
    return bytes;
  }

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_manager_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  RegionPack packOf({required String id, String? sha, GeoBounds? bounds}) =>
      RegionPack(
        id: id,
        name: id,
        // Deliberately wider than the header's extent, as the hand-maintained
        // catalogue is.
        bounds:
            bounds ??
            const GeoBounds(
              south: 51.06,
              west: 15.68,
              north: 53.71,
              east: 19.19,
            ),
        bytes: headerBytes.length,
        sha256: sha ?? sha256.convert(headerBytes).toString(),
        url: 'https://example.invalid/$id.pmtiles',
      );

  PackManager managerWith(List<RegionPack> packs, {int? freeBytes = 1 << 30}) =>
      PackManager(
        catalogue: RegionCatalogue(packs),
        store: PackStore(
          directory: tempDir,
          downloader: _FixedDownloader(headerBytes),
          freeSpaceMargin: 0,
        ),
        freeSpace: FixedFreeSpace(freeBytes),
      );

  group('what the picker is told', () {
    test('a fresh install has nothing on disk and nothing active', () async {
      final manager = managerWith([packOf(id: 'wielkopolskie')]);

      final statuses = await manager.statuses();

      expect(statuses.single.installed, isFalse);
      expect(statuses.single.header, isNull);
      expect(await manager.activePack(), isNull);
    });

    test('a region published without a checksum is not offered', () async {
      final manager = managerWith([packOf(id: 'lubuskie', sha: '')]);

      expect(
        (await manager.statuses()).single.downloadable,
        isFalse,
        reason: 'a button that cannot work is worse than no button',
      );
      expect(
        await manager.install(packOf(id: 'lubuskie', sha: '')),
        InstallOutcome.corrupted,
      );
    });

    test('an installed pack reports the extent from its own header', () async {
      final manager = managerWith([packOf(id: 'wielkopolskie')]);
      await manager.install(packOf(id: 'wielkopolskie'));

      final status = (await manager.statuses()).single;

      expect(status.installed, isTrue);
      expect(status.header!.maxZoom, 15);
      expect(
        status.header!.bounds.west,
        closeTo(15.760, 0.001),
        reason: 'the catalogue guesses 15.68 for this region',
      );
    });
  });

  group('choosing the pack under the player', () {
    test(
      'the one containing the position wins over the one that does not',
      () async {
        const south = GeoBounds(
          south: 49.07,
          west: 19.08,
          north: 50.59,
          east: 21.44,
        );
        final southBytes = headerCovering(south);

        final malopolskie = RegionPack(
          id: 'malopolskie',
          name: 'malopolskie',
          bounds: south,
          bytes: southBytes.length,
          sha256: sha256.convert(southBytes).toString(),
          url: 'https://example.invalid/malopolskie.pmtiles',
        );
        final wielkopolskie = packOf(id: 'wielkopolskie');

        final manager = PackManager(
          catalogue: RegionCatalogue([malopolskie, wielkopolskie]),
          store: PackStore(
            directory: tempDir,
            downloader: _PerPackDownloader({
              malopolskie.url: southBytes,
              wielkopolskie.url: headerBytes,
            }),
            freeSpaceMargin: 0,
          ),
          freeSpace: const FixedFreeSpace(1 << 30),
        );
        await manager.install(malopolskie);
        await manager.install(wielkopolskie);

        // Poznań.
        final active = await manager.activePack(
          nearLatitude: 52.4064,
          nearLongitude: 16.9252,
        );

        expect(active!.pack.id, 'wielkopolskie');
      },
    );

    test('a position outside every pack still gets a map', () async {
      final manager = managerWith([packOf(id: 'wielkopolskie')]);
      await manager.install(packOf(id: 'wielkopolskie'));

      // Berlin. Nothing covers it, but leaving the screen blank would be
      // worse than showing the map they downloaded.
      final active = await manager.activePack(
        nearLatitude: 52.52,
        nearLongitude: 13.405,
      );

      expect(active, isNotNull);
    });
  });

  group('coverage comes from the file, not the catalogue', () {
    test(
      'a point inside the catalogue but outside the pack is outside',
      () async {
        final manager = managerWith([packOf(id: 'wielkopolskie')]);
        await manager.install(packOf(id: 'wielkopolskie'));
        final status = await manager.activePack();

        final coverage = manager.coverageFor(status);
        final t0 = DateTime.utc(2026, 8, 12, 12);

        // 15.70 E is inside the catalogue's guess (15.68) and outside the
        // header's real western edge (15.76) by about four kilometres.
        coverage.update(52.5, 15.70, t0);
        expect(
          coverage.update(52.5, 15.70, t0.add(const Duration(seconds: 40))),
          Coverage.outside,
        );
      },
    );

    test('no pack at all is its own state', () {
      expect(
        PackManager(
          catalogue: const RegionCatalogue([]),
          store: PackStore(
            directory: tempDir,
            downloader: _FixedDownloader(headerBytes),
          ),
          freeSpace: const FixedFreeSpace(1 << 30),
        ).coverageFor(null).state,
        Coverage.missing,
      );
    });
  });

  group('a download that outlives its screen (§16.6)', () {
    test('reports progress and its outcome to anyone listening', () async {
      final manager = managerWith([packOf(id: 'wielkopolskie')]);
      final seen = <DownloadState>[];
      manager.downloads.listen(seen.add);

      manager.startInstall(packOf(id: 'wielkopolskie'));
      while (manager.isDownloading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(seen.first.fraction, 0);
      expect(seen.last.outcome, InstallOutcome.installed);
      expect(
        await manager.store.isInstalled(packOf(id: 'wielkopolskie')),
        isTrue,
      );
    });

    test('a second start is refused while one is running', () async {
      // Two large downloads over a phone connection finish later than one
      // after the other, and the progress bar stops meaning anything.
      final manager = managerWith([packOf(id: 'wielkopolskie')]);

      manager.startInstall(packOf(id: 'wielkopolskie'));
      final first = manager.currentDownload;
      manager.startInstall(packOf(id: 'malopolskie'));

      expect(manager.currentDownload!.packId, first!.packId);
    });

    test('the last state stays readable after it ends', () async {
      // A screen opened after the fact has to be able to say what happened.
      final manager = managerWith([packOf(id: 'wielkopolskie')]);

      manager.startInstall(packOf(id: 'wielkopolskie'));
      while (manager.isDownloading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(manager.currentDownload!.finished, isTrue);
      expect(manager.currentDownload!.outcome, InstallOutcome.installed);
    });
  });

  group('free space', () {
    test('too little room refuses the download', () async {
      final manager = PackManager(
        catalogue: RegionCatalogue([packOf(id: 'wielkopolskie')]),
        store: PackStore(
          directory: tempDir,
          downloader: _FixedDownloader(headerBytes),
          freeSpaceMargin: 64 * 1024 * 1024,
        ),
        freeSpace: const FixedFreeSpace(1024),
      );

      expect(
        await manager.install(packOf(id: 'wielkopolskie')),
        InstallOutcome.notEnoughSpace,
      );
    });

    test('a platform that will not answer is treated as enough room', () async {
      // Refusing a download because a measurement failed is worse than
      // attempting one that might not fit.
      final manager = managerWith([
        packOf(id: 'wielkopolskie'),
      ], freeBytes: null);

      expect(
        await manager.install(packOf(id: 'wielkopolskie')),
        InstallOutcome.installed,
      );
    });
  });
}

/// Serves different bytes per url, so two packs can differ.
class _PerPackDownloader implements PackDownloader {
  const _PerPackDownloader(this.byUrl);

  final Map<String, Uint8List> byUrl;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) =>
      Stream.value(byUrl[url]!.sublist(offset));
}

class _FixedDownloader implements PackDownloader {
  const _FixedDownloader(this.payload);

  final Uint8List payload;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) =>
      Stream.value(payload.sublist(offset));
}
