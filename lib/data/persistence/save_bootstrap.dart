/// Startup sequence for the save layer (design doc §11.1).
///
/// Order matters and is not negotiable:
///
/// 1. verify the database file, restoring a snapshot if it is broken — before
///    anything writes to it;
/// 2. open it, which runs migrations;
/// 3. take a pre-migration snapshot when the schema is about to change, so a
///    bad migration can be rolled back;
/// 4. restore the clock high-water mark, so the rollback protection of §2.1.1
///    survives a restart;
/// 5. hand the caller a writer and whatever the player needs to be told.
library;

import 'dart:async';

import '../../core/game_clock.dart';
import '../db/database.dart';
import '../db/snapshot_store.dart';
import 'save_writer.dart';

/// Everything the app needs after a successful boot.
class SaveSession {
  SaveSession({
    required this.db,
    required this.writer,
    required this.snapshots,
    required this.clock,
    required this.recovery,
    required this.migratedFrom,
  });

  final SaveDatabase db;
  final SaveWriter writer;
  final SnapshotStore snapshots;
  final GameClock clock;

  /// What the startup health check found. Anything other than
  /// [SaveHealth.ok] has to reach the player (§11.1.3).
  final SaveRecovery recovery;

  /// Schema version the database was on before this launch, or null when it
  /// was created fresh.
  final int? migratedFrom;

  bool get didMigrate => migratedFrom != null && migratedFrom != kSchemaVersion;

  Future<void> close() async {
    await db.close();
  }
}

class SaveBootstrap {
  SaveBootstrap({
    required this.paths,
    GameClock? clock,
    SaveDatabase Function(SavePaths paths)? openDatabase,
  }) : clock = clock ?? GameClock(),
       _openDatabase = openDatabase ?? _defaultOpen;

  final SavePaths paths;
  final GameClock clock;
  final SaveDatabase Function(SavePaths paths) _openDatabase;

  static SaveDatabase _defaultOpen(SavePaths paths) =>
      SaveDatabase(openSaveExecutor(paths.databaseFile));

  Future<SaveSession> boot({required DateTime now}) async {
    await paths.ensureExists();

    final snapshots = SnapshotStore(paths);

    // 1. Verify before opening. A corrupt file that gets opened read-write is
    //    a corrupt file that can no longer be diagnosed.
    final recovery = await snapshots.verifyAndRecover(now: now);

    // 2. Note the version on disk before drift touches it, so we know whether
    //    a migration is about to run.
    final versionBefore = await _peekSchemaVersion(paths);

    // 3. A migration is coming: snapshot first. §11.1.4 makes this mandatory,
    //    because the alternative is discovering the migration was wrong after
    //    it has already run on everyone's device.
    if (versionBefore != null && versionBefore != kSchemaVersion) {
      final preMigrationDb = _openDatabase(paths);
      try {
        await snapshots.capture(
          preMigrationDb,
          now: now,
          reason: SnapshotReason.preMigration,
        );
      } finally {
        await preMigrationDb.close();
      }
    }

    // 4. Open for real. Drift runs onCreate/onUpgrade here.
    final db = _openDatabase(paths);
    await db.customStatement('SELECT 1'); // force the connection open

    if (!await db.isHealthy()) {
      // Opened, but SQLite does not like what it sees. Treat it as corruption
      // rather than limping on.
      await db.close();
      throw StateError('Database failed integrity check after opening');
    }

    // 5. Reinstate the monotonic clock.
    final mark = await db.readMetaTimestamp(MetaKeys.clockHighWaterMark);
    clock.restore(mark);

    return SaveSession(
      db: db,
      writer: SaveWriter(db),
      snapshots: snapshots,
      clock: clock,
      recovery: recovery,
      migratedFrom: versionBefore,
    );
  }

  /// Reads the schema version without opening the file as a drift database.
  Future<int?> _peekSchemaVersion(SavePaths paths) async {
    final file = paths.databaseFile;
    if (!file.existsSync()) return null;
    try {
      final raw = openRawDatabase(file);
      try {
        final rows = raw.select(
          'SELECT value FROM meta_entries WHERE key = ?',
          [MetaKeys.schemaVersion],
        );
        if (rows.isEmpty) return null;
        return int.tryParse('${rows.first.values.first}');
      } finally {
        raw.dispose();
      }
    } on Object {
      return null;
    }
  }
}

/// Persists the clock high-water mark. Called on every hot-layer flush so the
/// rollback guard cannot be defeated by killing the app (§2.1.1).
Future<void> persistClockMark(SaveDatabase db, GameClock clock) async {
  final mark = clock.highWaterMark;
  if (mark == null) return;
  await db.writeMetaTimestamp(MetaKeys.clockHighWaterMark, mark);
}
