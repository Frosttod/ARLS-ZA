import 'dart:io';
import 'dart:typed_data';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/db/snapshot_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'db_fixture.dart';

/// Covers the rotating-snapshot guarantees of §11.1.3: three snapshots kept,
/// checksums verified, a corrupt database replaced by the newest good copy and
/// the player told what it cost.
void main() {
  late Directory tempDir;
  late SavePaths paths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_snapshot_');
    paths = SavePaths(tempDir);
    await paths.ensureExists();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<SaveDatabase> openOnDisk() async {
    final db = SaveDatabase(openSaveExecutor(paths.databaseFile));
    await db.customStatement('SELECT 1');
    return db;
  }

  group('capture', () {
    test('writes a file, a record and a checksum that verifies', () async {
      final db = await openOnDisk();
      addTearDown(db.close);
      await insertProfile(db);

      final store = SnapshotStore(paths);
      final now = DateTime.utc(2026, 8, 9, 12);
      final info = await store.capture(db, now: now);

      expect(info.file.existsSync(), isTrue);
      expect(info.checksum, hasLength(64));
      expect(info.schemaVersion, kSchemaVersion);

      final listed = await store.listVerified();
      expect(listed, hasLength(1));
      expect(
        listed.single.checksum,
        info.checksum,
        reason: 'a re-read that changes the checksum means a damaged file',
      );

      final records = await db.select(db.snapshotRecords).get();
      expect(records, hasLength(1));
      expect(records.single.checksum, info.checksum);
    });

    test('the snapshot contains data written just before it', () async {
      final db = await openOnDisk();
      addTearDown(db.close);
      await insertProfile(db, name: 'Halina');

      final store = SnapshotStore(paths);
      final info = await store.capture(db, now: DateTime.utc(2026, 8, 9));

      // Read the snapshot as a plain SQLite file. A missing WAL checkpoint
      // would show up right here as an empty table.
      final raw = openRawDatabase(info.file);
      addTearDown(raw.dispose);
      final rows = raw.select('SELECT name FROM profiles');

      expect(rows.single['name'], 'Halina');
    });

    test('keeps three periodic snapshots and drops the oldest', () async {
      final db = await openOnDisk();
      addTearDown(db.close);
      await insertProfile(db);

      final store = SnapshotStore(paths, keepPeriodic: 3);
      final base = DateTime.utc(2026, 8, 9, 12);

      for (var i = 0; i < 5; i++) {
        await store.capture(db, now: base.add(Duration(minutes: 30 * i)));
      }

      final listed = await store.listVerified();
      expect(listed, hasLength(3));
      expect(listed.first.takenAt, base.add(const Duration(minutes: 120)));
      expect(listed.last.takenAt, base.add(const Duration(minutes: 60)));

      final records = await db.select(db.snapshotRecords).get();
      expect(records, hasLength(3), reason: 'bookkeeping must follow the disk');
    });

    test('a pre-migration snapshot survives periodic rotation', () async {
      final db = await openOnDisk();
      addTearDown(db.close);
      await insertProfile(db);

      final store = SnapshotStore(paths, keepPeriodic: 2);
      final base = DateTime.utc(2026, 8, 9, 12);

      await store.capture(db, now: base, reason: SnapshotReason.preMigration);
      for (var i = 1; i <= 4; i++) {
        await store.capture(db, now: base.add(Duration(minutes: 30 * i)));
      }

      final listed = await store.listVerified();
      final preMigration = listed.where(
        (s) => s.reason == SnapshotReason.preMigration,
      );

      expect(
        preMigration,
        hasLength(1),
        reason: 'the only thing standing between a bad migration and the save',
      );
      expect(
        listed.where((s) => s.reason == SnapshotReason.periodic),
        hasLength(2),
      );
    });
  });

  group('isDue', () {
    test('true on a fresh database', () async {
      final db = await openOnDisk();
      addTearDown(db.close);

      expect(await SnapshotStore(paths).isDue(db, DateTime.utc(2026)), isTrue);
    });

    test('false until the interval elapses', () async {
      final db = await openOnDisk();
      addTearDown(db.close);
      await insertProfile(db);

      final store = SnapshotStore(paths);
      final base = DateTime.utc(2026, 8, 9, 12);
      await store.capture(db, now: base);

      expect(
        await store.isDue(db, base.add(const Duration(minutes: 29))),
        isFalse,
      );
      expect(
        await store.isDue(db, base.add(const Duration(minutes: 30))),
        isTrue,
      );
    });
  });

  group('verifyAndRecover', () {
    test('reports absent when there is no database yet', () async {
      final result = await SnapshotStore(
        paths,
      ).verifyAndRecover(now: DateTime.utc(2026));

      expect(result.health, SaveHealth.absent);
    });

    test('reports ok for a healthy database', () async {
      final db = await openOnDisk();
      await insertProfile(db);
      await db.close();

      final result = await SnapshotStore(
        paths,
      ).verifyAndRecover(now: DateTime.utc(2026));

      expect(result.health, SaveHealth.ok);
    });

    test(
      'restores the newest good snapshot and reports the time lost',
      () async {
        final db = await openOnDisk();
        await insertProfile(db, name: 'Przed');

        final store = SnapshotStore(paths);
        final snapshotAt = DateTime.utc(2026, 8, 9, 12);
        await store.capture(db, now: snapshotAt);
        await db.close();

        _corrupt(paths.databaseFile);

        final now = snapshotAt.add(const Duration(minutes: 17));
        final result = await store.verifyAndRecover(now: now);

        expect(result.health, SaveHealth.restored);
        expect(result.timeLost, const Duration(minutes: 17));

        final reopened = await openOnDisk();
        addTearDown(reopened.close);
        final profiles = await reopened.allProfiles();
        expect(profiles.single.name, 'Przed');
      },
    );

    test(
      'keeps the corrupt file for diagnosis instead of deleting it',
      () async {
        final db = await openOnDisk();
        await insertProfile(db);
        final store = SnapshotStore(paths);
        await store.capture(db, now: DateTime.utc(2026, 8, 9, 12));
        await db.close();

        _corrupt(paths.databaseFile);
        await store.verifyAndRecover(now: DateTime.utc(2026, 8, 9, 13));

        final quarantined = tempDir.listSync().whereType<File>().where(
          (f) => f.path.contains('.corrupt.'),
        );

        expect(quarantined, isNotEmpty);
      },
    );

    test('reports lost when no snapshot is usable', () async {
      final db = await openOnDisk();
      await insertProfile(db);
      final store = SnapshotStore(paths);
      await store.capture(db, now: DateTime.utc(2026, 8, 9, 12));
      await db.close();

      _corrupt(paths.databaseFile);
      for (final snapshot in paths.snapshotDir.listSync().whereType<File>()) {
        _corrupt(snapshot);
      }

      final result = await store.verifyAndRecover(
        now: DateTime.utc(2026, 8, 9, 13),
      );

      expect(result.health, SaveHealth.lost);
    });

    test('skips a damaged snapshot and falls back to an older one', () async {
      final db = await openOnDisk();
      await insertProfile(db, name: 'Stara');
      final store = SnapshotStore(paths);

      final base = DateTime.utc(2026, 8, 9, 12);
      final old = await store.capture(db, now: base);
      final recent = await store.capture(
        db,
        now: base.add(const Duration(minutes: 30)),
      );
      await db.close();

      _corrupt(paths.databaseFile);
      _corrupt(recent.file);

      final result = await store.verifyAndRecover(
        now: base.add(const Duration(hours: 1)),
      );

      expect(result.health, SaveHealth.restored);
      expect(result.restoredFrom?.takenAt, old.takenAt);
    });
  });

  group('checksums', () {
    test('the same bytes hash the same, different bytes do not', () {
      expect(checksumOfString('abc'), checksumOfString('abc'));
      expect(checksumOfString('abc'), isNot(checksumOfString('abd')));
      expect(checksumOfString('abc'), hasLength(64));
    });
  });
}

/// Overwrites the SQLite header so the file stops being a database at all.
void _corrupt(File file) {
  final bytes = file.readAsBytesSync();
  final damaged = Uint8List.fromList(bytes);
  for (var i = 0; i < 64 && i < damaged.length; i++) {
    damaged[i] = 0x00;
  }
  file.writeAsBytesSync(damaged, flush: true);
}
