import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arls_za/map/pack_store.dart';
import 'package:arls_za/map/region_pack.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// §16.6. The failure that matters is not a download that fails — those are
/// expected — but one that half-succeeds and leaves the player walking into a
/// city with a map made of grey squares.
void main() {
  final payload = Uint8List.fromList(
    List<int>.generate(4096, (i) => (i * 37) % 251),
  );
  final checksum = sha256.convert(payload).toString();

  RegionPack packOf({String? sha, int? bytes}) => RegionPack(
    id: 'mazowieckie',
    name: 'Mazowieckie',
    bounds: const GeoBounds(south: 51, west: 19, north: 53.5, east: 23),
    bytes: bytes ?? payload.length,
    sha256: sha ?? checksum,
    url: 'https://example.invalid/mazowieckie.pmtiles',
  );

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_packs_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  PackStore storeWith(PackDownloader downloader) =>
      PackStore(directory: tempDir, downloader: downloader, freeSpaceMargin: 0);

  test('a good download lands as a verified file', () async {
    final store = storeWith(_FakeDownloader(payload));
    final pack = packOf();

    final outcome = await store.install(pack, freeBytes: 1 << 30);

    expect(outcome, InstallOutcome.installed);
    expect(await store.isInstalled(pack), isTrue);
    expect(await store.fileFor(pack).readAsBytes(), payload);
  });

  test('progress is reported against the size the picker showed', () async {
    final store = storeWith(_FakeDownloader(payload, chunkSize: 1024));
    final seen = <double>[];

    await store.install(
      packOf(),
      freeBytes: 1 << 30,
      onProgress: (progress) => seen.add(progress.fraction),
    );

    expect(seen.first, closeTo(0.25, 0.01));
    expect(seen.last, closeTo(1.0, 0.01));
  });

  test('a second install of the same pack is not a download', () async {
    final downloader = _FakeDownloader(payload);
    final store = storeWith(downloader);
    final pack = packOf();
    await store.install(pack, freeBytes: 1 << 30);

    final outcome = await store.install(pack, freeBytes: 1 << 30);

    expect(outcome, InstallOutcome.alreadyPresent);
    expect(
      downloader.calls,
      1,
      reason: 'the picker offers packs the player may already have',
    );
  });

  group('what can go wrong', () {
    test('too little space is refused before the first byte', () async {
      final downloader = _FakeDownloader(payload);
      final store = PackStore(
        directory: tempDir,
        downloader: downloader,
        freeSpaceMargin: 64 * 1024 * 1024,
      );

      final outcome = await store.install(packOf(), freeBytes: 1024 * 1024);

      expect(outcome, InstallOutcome.notEnoughSpace);
      expect(
        downloader.calls,
        0,
        reason: 'finding out at 180 MB is not a design',
      );
    });

    test('the margin protects the save file, not just the pack', () async {
      // Exactly the pack fits, and nothing else. That is a refusal: a device
      // with no room left cannot write the save (§11.1).
      final store = PackStore(
        directory: tempDir,
        downloader: _FakeDownloader(payload),
        freeSpaceMargin: 64 * 1024 * 1024,
      );

      expect(
        await store.install(packOf(), freeBytes: payload.length),
        InstallOutcome.notEnoughSpace,
      );
    });

    test('wrong bytes are deleted, not kept for the next attempt', () async {
      final store = storeWith(_FakeDownloader(payload));
      final pack = packOf(sha: sha256.convert(utf8.encode('other')).toString());

      final outcome = await store.install(pack, freeBytes: 1 << 30);

      expect(outcome, InstallOutcome.corrupted);
      expect(await store.isInstalled(pack), isFalse);
      expect(
        File('${store.fileFor(pack).path}.part').existsSync(),
        isFalse,
        reason: 'resuming from bytes known to be wrong never converges',
      );
    });

    test('a pack with no published checksum is refused', () async {
      final store = storeWith(_FakeDownloader(payload));

      expect(
        await store.install(packOf(sha: ''), freeBytes: 1 << 30),
        InstallOutcome.corrupted,
        reason:
            'a map nobody can verify is one nobody should walk into a '
            'city with',
      );
    });

    test('a broken connection keeps what arrived and resumes', () async {
      final flaky = _FakeDownloader(payload, failAfter: 2048);
      final store = storeWith(flaky);
      final pack = packOf();

      expect(
        await store.install(pack, freeBytes: 1 << 30),
        InstallOutcome.networkFailed,
      );
      expect(File('${store.fileFor(pack).path}.part').lengthSync(), 2048);

      // Second attempt: the rest of the file, asked for from where we stopped.
      final rest = _FakeDownloader(payload);
      final resumed = storeWith(rest);
      expect(
        await resumed.install(pack, freeBytes: 1 << 30),
        InstallOutcome.installed,
      );
      expect(
        rest.lastOffset,
        2048,
        reason: 'those bytes were paid for once already',
      );
      expect(await resumed.fileFor(pack).readAsBytes(), payload);
    });

    test('cancelling stops the download and keeps the partial file', () async {
      final store = storeWith(_FakeDownloader(payload, chunkSize: 1024));
      final pack = packOf();

      final outcome = await store.install(
        pack,
        freeBytes: 1 << 30,
        isCancelled: () async => true,
      );

      expect(outcome, InstallOutcome.cancelled);
      expect(await store.isInstalled(pack), isFalse);
    });
  });

  test('installed packs are read off the disk, not from a record', () async {
    final store = storeWith(_FakeDownloader(payload));
    await store.install(packOf(), freeBytes: 1 << 30);

    expect(await store.installedIds(), {'mazowieckie'});

    // The system storage cleaner takes the file and tells nobody.
    await store.fileFor(packOf()).delete();
    expect(await store.installedIds(), isEmpty);
  });
}

/// Serves [payload] from a given offset, optionally dying part-way.
class _FakeDownloader implements PackDownloader {
  _FakeDownloader(this.payload, {this.chunkSize = 512, this.failAfter});

  final Uint8List payload;
  final int chunkSize;

  /// Bytes to deliver before throwing, counted from the requested offset.
  final int? failAfter;

  int calls = 0;
  int lastOffset = -1;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) async* {
    calls++;
    lastOffset = offset;

    var sent = 0;
    for (var start = offset; start < payload.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, payload.length);
      final chunk = payload.sublist(start, end);

      if (failAfter != null && sent + chunk.length > failAfter!) {
        yield chunk.sublist(0, failAfter! - sent);
        throw const SocketException('connection reset');
      }

      sent += chunk.length;
      yield chunk;
    }
  }
}
