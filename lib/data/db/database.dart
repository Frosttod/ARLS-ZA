/// Save database (design doc §11.1).
///
/// Three guarantees hold this together:
///
/// 1. **Atomicity** — WAL mode, every write in a transaction. Killing the
///    process mid-write rolls the transaction back; the database is never left
///    half-updated (§11.1.2).
/// 2. **Additive migrations** — columns and tables are only ever added.
///    Generated schema files are committed and the migration path is covered
///    by tests, because the first update that drops a column deletes everyone's
///    character (§11.1.4).
/// 3. **Rotating snapshots** — see `snapshot_store.dart`.
///
/// This library is deliberately free of Flutter imports. The tick engine runs
/// in an isolate and the migration tests run under plain `dart test`; both
/// break the moment `dart:ui` is pulled in. Resolving the on-device save
/// directory needs `path_provider`, so it lives in `save_location.dart`.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

part 'database.g.dart';

/// Bumped only alongside a migration step in [_migration]. Never reused.
const int kSchemaVersion = 9;

/// Keys used in [MetaEntries].
abstract final class MetaKeys {
  /// Schema version as the app last left it. Redundant with drift's own
  /// `user_version`, kept because a snapshot file has to be inspectable
  /// without opening it as a drift database.
  static const schemaVersion = 'schema_version';

  /// Highest wall-clock timestamp ever accepted, backing the rollback
  /// protection of §2.1.1 across restarts.
  static const clockHighWaterMark = 'clock_high_water_mark';

  /// When the last periodic snapshot was taken.
  static const lastSnapshotAt = 'last_snapshot_at';
}

@DriftDatabase(
  tables: [
    MetaEntries,
    Profiles,
    Vitals,
    ChronicleEntries,
    Settings,
    SnapshotRecords,
    InventoryLines,
    LootBoxes,
    GroundItems,
  ],
)
class SaveDatabase extends _$SaveDatabase {
  SaveDatabase(super.executor);

  /// In-memory database for tests.
  SaveDatabase.memory() : super(NativeDatabase.memory());

  /// Must be a literal: `drift_dev schema dump` reads it statically and cannot
  /// follow a constant reference. `schema_test.dart` keeps it in step with
  /// [kSchemaVersion].
  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _writeSchemaVersion(kSchemaVersion);
    },
    onUpgrade: (m, from, to) async {
      // Additive only. Each step is its own block, applied in sequence, so a
      // device jumping v1 -> v3 runs v1->v2 then v2->v3 (§11.1.4).

      if (from < 2) {
        // The physiology of §2 needs somewhere to keep the wound, the
        // occupation and the movement inputs. All four carry defaults, so an
        // existing v1 character loads without anything being backfilled.
        await m.addColumn(vitals, vitals.bleedTier);
        await m.addColumn(vitals, vitals.occupationJson);
        await m.addColumn(vitals, vitals.speedKmh);
        await m.addColumn(vitals, vitals.carriedKg);
      }

      if (from < 3) {
        // Stage 4 gives the character something to carry. A new table rather
        // than columns: an inventory is a list, and the old carriedKg figure
        // stays where it is so a v2 save keeps its load surcharge until the
        // first real pickup replaces it.
        await m.createTable(inventoryLines);
      }

      if (from < 4) {
        // §10 puts loot on the map. A table of its own because a box outlives
        // any single session and has to be the same box when the player comes
        // back to it.
        await m.createTable(lootBoxes);
      }

      // ⚠️ `from >= 4`, not just `from < 5`.
      //
      // `createTable` above builds the table from *today's* definition, which
      // already has this column — so a device jumping from v3 gets it there and
      // adding it again is a duplicate-column error. Only a save that has a
      // v4-shaped table needs the column added. Every future column on a table
      // introduced mid-life has the same shape.
      if (from >= 4 && from < 5) {
        // §19.3 puts a door in front of some places. A box from v4 has none,
        // and the default of null reads as "still shut" — which is right: the
        // barrier was always there, the game just did not model it.
        await m.addColumn(lootBoxes, lootBoxes.openedAt);
      }

      if (from < 6) {
        // §2.4: a player who knows their own resting heart rate can say so.
        // Null keeps the estimate, so every existing character is unchanged.
        await m.addColumn(profiles, profiles.measuredRestingHr);
      }

      if (from < 7) {
        // §4.8: what a player put down, so they can come back for it.
        await m.createTable(groundItems);
      }

      // Same shape as v5's: inventory_lines was created in v3, so only a save
      // that already has a v3-or-later table needs the column added.
      if (from >= 3 && from < 8) {
        // §19.1: a note in the pack remembers which note it is.
        await m.addColumn(inventoryLines, inventoryLines.noteId);
      }

      if (from < 9) {
        // §2.2, §2.3: what has been eaten but not yet absorbed. Both default
        // to zero, so an existing character simply has nothing in the stomach.
        await m.addColumn(vitals, vitals.pendingKcal);
        await m.addColumn(vitals, vitals.pendingWaterMl);
      }

      await _writeSchemaVersion(to);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated || details.hadUpgrade) {
        await _writeSchemaVersion(schemaVersion);
      }
    },
  );

  Future<void> _writeSchemaVersion(int version) => into(metaEntries).insert(
    MetaEntriesCompanion.insert(key: MetaKeys.schemaVersion, value: '$version'),
    mode: InsertMode.insertOrReplace,
  );

  // ---------------------------------------------------------------- meta ---

  Future<String?> readMeta(String key) async {
    final row = await (select(
      metaEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeMeta(String key, String value) => into(metaEntries).insert(
    MetaEntriesCompanion.insert(key: key, value: value),
    mode: InsertMode.insertOrReplace,
  );

  // ------------------------------------------------------------ settings ---

  /// Player-facing settings, as opposed to [MetaEntries], which is the
  /// database's own bookkeeping. Kept apart so a factory reset of one does not
  /// take the other with it.
  Future<String?> readSetting(String key) async {
    final row = await (select(
      settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) => into(settings).insert(
    SettingsCompanion.insert(key: key, value: value),
    mode: InsertMode.insertOrReplace,
  );

  Future<DateTime?> readMetaTimestamp(String key) async {
    final raw = await readMeta(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> writeMetaTimestamp(String key, DateTime value) =>
      writeMeta(key, value.toUtc().toIso8601String());

  // ------------------------------------------------------------ profiles ---

  Future<Profile?> activeProfile() => (select(
    profiles,
  )..where((t) => t.isActive.equals(true))).getSingleOrNull();

  Future<Profile?> profileById(int id) =>
      (select(profiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Profile>> allProfiles() => select(profiles).get();

  /// Creates a character and its hot-layer row in one transaction, so a crash
  /// can never leave a profile without vitals.
  Future<int> createProfile({
    required ProfilesCompanion profile,
    required VitalsCompanion Function(int profileId) vitals,
  }) => transaction(() async {
    await (update(profiles)..where((t) => t.isActive.equals(true))).write(
      const ProfilesCompanion(isActive: Value(false)),
    );
    final id = await into(profiles).insert(profile);
    await into(this.vitals).insert(vitals(id));
    return id;
  });

  // --------------------------------------------------------------- hot ---

  Future<Vital?> vitalsFor(int profileId) => (select(
    vitals,
  )..where((t) => t.profileId.equals(profileId))).getSingleOrNull();

  /// Writes the hot layer. Called on the 60 s cadence and on every transition
  /// to the background (§11.1.1).
  Future<void> writeVitals(VitalsCompanion value) => transaction(
    () => into(vitals).insert(value, mode: InsertMode.insertOrReplace),
  );

  // --------------------------------------------------------- inventory ---

  Future<List<InventoryLine>> inventoryFor(int profileId) => (select(
    inventoryLines,
  )..where((t) => t.profileId.equals(profileId))).get();

  /// Replaces the whole inventory for a profile.
  ///
  /// Whole rather than line by line: the in-memory [Inventory] is a value, and
  /// diffing it against rows would mean two descriptions of the same thing
  /// disagreeing after a crash. An inventory is tens of rows, so the write is
  /// cheap and always correct.
  Future<void> writeInventory(
    int profileId,
    List<InventoryLinesCompanion> lines,
  ) => transaction(() async {
    await (delete(
      inventoryLines,
    )..where((t) => t.profileId.equals(profileId))).go();
    await batch((b) => b.insertAll(inventoryLines, lines));
  });

  // --------------------------------------------------------------- loot ---

  Future<List<LootBoxe>> lootBoxesFor(int profileId) => (select(
    lootBoxes,
  )..where((t) => t.profileId.equals(profileId))).get();

  /// Writes what the spawner decided.
  ///
  /// Additions and updates rather than a wholesale replace: a box is something
  /// the player may be walking towards, and rewriting the table would give it a
  /// new row id every pass for no reason. [forgotten] are the ones that fell
  /// out of range.
  Future<void> writeLootBoxes(
    int profileId, {
    required List<LootBoxesCompanion> boxes,
    List<String> forgotten = const [],
  }) => transaction(() async {
    for (final box in boxes) {
      await into(lootBoxes).insert(box, mode: InsertMode.insertOrReplace);
    }
    if (forgotten.isEmpty) return;
    await (delete(lootBoxes)..where(
          (t) => t.profileId.equals(profileId) & t.poiId.isIn(forgotten),
        ))
        .go();
  });

  // ------------------------------------------------------------ dropped ---

  Future<List<GroundItem>> groundItemsFor(int profileId) => (select(
    groundItems,
  )..where((t) => t.profileId.equals(profileId))).get();

  Future<int> addGroundItem(GroundItemsCompanion item) =>
      into(groundItems).insert(item);

  /// Deletes by row id. Used by §4.8's sweep and by picking something back up.
  Future<void> removeGroundItems(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(groundItems)..where((t) => t.id.isIn(ids))).go();
  }

  // -------------------------------------------------------- maintenance ---

  /// Forces a WAL checkpoint. Called when the app goes to the background and
  /// from the foreground service's `onDestroy` (§11.1.2), so the `-wal` file
  /// never holds state the main database file lacks.
  Future<void> checkpoint() =>
      customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

  /// Runs SQLite's own consistency check. Used at startup before trusting the
  /// database, and after restoring a snapshot.
  Future<bool> isHealthy() async {
    try {
      final rows = await customSelect('PRAGMA integrity_check').get();
      if (rows.isEmpty) return false;
      final verdict = rows.first.data.values.first;
      return verdict == 'ok';
    } on Object {
      return false;
    }
  }

  /// Schema version recorded inside the file, or null for a database that was
  /// never opened by this app.
  Future<int?> storedSchemaVersion() async {
    final raw = await readMeta(MetaKeys.schemaVersion);
    return raw == null ? null : int.tryParse(raw);
  }
}

/// Where the save lives. Everything sits in the app's private directory, which
/// is excluded from Android auto-backup (§11.1.3, manifest `allowBackup=false`).
class SavePaths {
  const SavePaths(this.directory);

  final Directory directory;

  static const databaseFileName = 'arls_za.sqlite';
  static const snapshotDirName = 'snapshots';

  File get databaseFile => File(p.join(directory.path, databaseFileName));

  Directory get snapshotDir =>
      Directory(p.join(directory.path, snapshotDirName));

  Future<void> ensureExists() async {
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    if (!snapshotDir.existsSync()) {
      await snapshotDir.create(recursive: true);
    }
  }
}

/// Opens the save database in WAL mode.
///
/// WAL is what makes an interrupted write safe: readers never see a partial
/// transaction, and a killed process leaves the last committed state intact
/// (§11.1.2).
QueryExecutor openSaveExecutor(File file, {bool logStatements = false}) {
  return NativeDatabase.createInBackground(
    file,
    logStatements: logStatements,
    setup: (db) {
      db.execute('PRAGMA journal_mode = WAL');
      // NORMAL is the right trade for WAL: an OS crash can cost the last
      // transaction, a process kill cannot. FULL would fsync on every commit
      // and burn flash for a guarantee the 60 s hot-layer cadence already
      // makes unnecessary.
      db.execute('PRAGMA synchronous = NORMAL');
      db.execute('PRAGMA foreign_keys = ON');
      db.execute('PRAGMA busy_timeout = 5000');
    },
  );
}

/// Opens the database file directly, bypassing drift. Used to inspect a
/// snapshot before deciding whether to restore it.
Database openRawDatabase(File file) => sqlite3.open(file.path);
