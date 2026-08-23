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
const int kSchemaVersion = 29;

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
    Shelters,
    RemainsEntries,
    ProfileStats,
    ShelterItems,
    CraftJobs,
    ActiveActions,
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
  int get schemaVersion => 29;

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

      // Same shape as v5's: loot_boxes was created in v4, so only a save that
      // already has a v4-or-later table needs the column added.
      if (from >= 4 && from < 10) {
        // §10.3.5: how much of a place is left to search. Zero reads as
        // untouched, which is right — every box written before this was
        // emptied outright by its one search.
        await m.addColumn(lootBoxes, lootBoxes.searchUnits);
      }

      // Same shape as v5's: inventory_lines was created in v3.
      if (from >= 3 && from < 11) {
        // §4.7: how much of a piece is left. One reads as whole, which is what
        // every line written before this was.
        await m.addColumn(inventoryLines, inventoryLines.portion);
      }

      // Same shape as v5's: inventory_lines was created in v3.
      if (from >= 3 && from < 12) {
        // §5.6.3: what is bolted to a weapon. Empty reads as a bare one, which
        // is what every line written before this was.
        await m.addColumn(inventoryLines, inventoryLines.attachments);
      }

      if (from < 13) {
        // §8: the place the player comes back to. A table of its own because
        // it outlives every session and because it is the one record in the
        // save that must never be backed up (§8.2).
        await m.createTable(shelters);
      }

      // Same shape as v5's: shelters was created in v13.
      if (from >= 13 && from < 14) {
        // §2.1a.3: work only counts while the player is on the site, so what
        // is left has to be a number rather than a deadline. Null on an
        // existing row reads as "the old deadline still applies".
        await m.addColumn(shelters, shelters.buildLeftSeconds);
        await m.addColumn(shelters, shelters.buildingLeftSeconds);
      }

      if (from < 14) {
        // §9.2: a softcore character who has gone down. Null is upright,
        // which is what every existing save was.
        await m.addColumn(vitals, vitals.downUntil);
      }

      // Same shape as v5's: shelters was created in v13.
      if (from >= 13 && from < 15) {
        // §8.3: when work was last credited. Null reads as "never", and the
        // first tick after the update simply starts the clock.
        await m.addColumn(shelters, shelters.workedAt);
      }

      if (from < 16) {
        // §10.3: bodies outlive a session, because the player put them there.
        await m.createTable(remainsEntries);

        // §5.6.2: and a fight walked out of outlives one too, or closing the
        // app is a perfect escape.
        await m.addColumn(vitals, vitals.huntUntil);
        await m.addColumn(vitals, vitals.huntLatitude);
        await m.addColumn(vitals, vitals.huntLongitude);
        await m.addColumn(vitals, vitals.huntCount);
      }

      // Same shape as v5's: ground_items was created in v7.
      if (from >= 7 && from < 17) {
        // §5.6.3: what is bolted to a thing on the ground. Empty reads as
        // bare, which is what every row written before this was — and, until
        // now, what every rifle put down became.
        await m.addColumn(groundItems, groundItems.attachments);
      }

      if (from < 18) {
        // §9.2: waking up is a thing that happened, not a thing the process
        // remembers. Null reads as "on their feet", which every save written
        // before this was.
        await m.addColumn(vitals, vitals.graceUntil);
      }

      if (from < 19) {
        // §13.1: what a character has done. A tally rather than a state, so it
        // gets a table of its own — vitals is rewritten every minute and a
        // history is not.
        await m.createTable(profileStats);
      }

      if (from < 20) {
        // §18.2: somewhere to put things down. The capacity has been computed
        // since the shelter was built — twenty-five kilograms of barricaded
        // house — and there was nowhere to put anything in it.
        await m.createTable(shelterItems);
      }

      // §5.3: rounds live on the item now. They were one integer in the
      // interface and nothing wrote it down, so reloading took thirty rounds
      // out of the pack and closing the app destroyed them. Nullable, so an
      // existing row reads as "not a thing that holds rounds".
      //
      // ⚠️ Three guarded steps, same shape as v5's, and the guard is the whole
      // point: `createTable` builds a table from *today's* definition, so a
      // save old enough to have the table created during its own migration
      // already has the column. Adding it again is a duplicate-column error,
      // which is exactly what the migration test caught.
      if (from >= 3 && from < 21) {
        await m.addColumn(inventoryLines, inventoryLines.rounds);
      }

      // Same shape as v5's: ground_items was created in v7.
      if (from >= 7 && from < 21) {
        await m.addColumn(groundItems, groundItems.rounds);
      }

      // Same shape as v5's: shelter_items was created in v20.
      if (from >= 20 && from < 21) {
        await m.addColumn(shelterItems, shelterItems.rounds);
      }

      // §18.4, §18.6: making and unmaking are activities with a clock, so
      // they live on a row like the shelter's own build does. A new table
      // rather than columns on Shelters: a job belongs to the player, not to
      // the building, and dismantling happens with a multitool wherever they
      // keep their things.
      if (from < 22) await m.createTable(craftJobs);

      // §18.6: a dismantling can be stopped and gone back to, so how far it
      // got lives on the piece. Same three guarded steps as v21's `rounds`,
      // and the guard is the same point: createTable builds from today's
      // definition, so a table created during this very migration already has
      // the column.
      if (from >= 3 && from < 23) {
        await m.addColumn(inventoryLines, inventoryLines.salvageSeconds);
      }
      if (from >= 7 && from < 23) {
        await m.addColumn(groundItems, groundItems.salvageSeconds);
      }
      if (from >= 20 && from < 23) {
        await m.addColumn(shelterItems, shelterItems.salvageSeconds);
      }

      // §11.1: a piece keeps its name across a save. Same three guarded
      // steps as v21 and v23, same reason: createTable builds from today's
      // definition, so a table made during this very migration already has it.
      if (from >= 3 && from < 24) {
        await m.addColumn(inventoryLines, inventoryLines.uid);
      }
      if (from >= 7 && from < 24) {
        await m.addColumn(groundItems, groundItems.uid);
      }
      if (from >= 20 && from < 24) {
        await m.addColumn(shelterItems, shelterItems.uid);
      }

      // §2.1a: one table for everything with a clock on it. CraftJobs stays
      // for now and is emptied by the migration that moves its rows across —
      // this schema is additive, so a table is dropped a version after it
      // stops being written, never in the same one.
      if (from < 25) await m.createTable(activeActions);

      // §18.6: a sitting can take several things apart, in order. The list
      // lives on the job because the pieces are still in the pack until their
      // turn comes. Guarded from 22 because that is when the table appeared —
      // anything older gets the column from createTable above.
      if (from >= 22 && from < 26) {
        await m.addColumn(craftJobs, craftJobs.salvageBatch);
      }

      // §2.3: the two clocks the lethal rules need. Additive with defaults of
      // nought, which reads as a character who has just eaten and drunk —
      // never as one who is two days dry.
      if (from < 27) {
        await m.addColumn(vitals, vitals.dryStreakSeconds);
        await m.addColumn(vitals, vitals.starvedStreakSeconds);
      }

      // §2.3: mass stops being a constant. Nought means "written before mass
      // moved" and is filled in from the profile's creation weight on load —
      // the only place that knows it.
      if (from < 28) await m.addColumn(vitals, vitals.bodyMassKg);

      // §2.5.5: the weeks-long axis of not sleeping enough. Nought reads as a
      // rested character, which is the honest answer for a row written by a
      // version that could not measure it.
      if (from < 29) await m.addColumn(vitals, vitals.sleepStrain);

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
  /// §4.7: how much of one piece is left, and nothing else.
  ///
  /// ⚠️ **Not [writeInventory].** A meal moves this figure once a second, and
  /// the wholesale write deletes every row a profile owns and inserts them all
  /// back inside a transaction. Doing that every second of every meal is a
  /// pack's worth of rows through the queue per second, ahead of the position
  /// writes and the hot state the loop is trying to save — reported from the
  /// field as the game freezing on food.
  ///
  /// One row, found by the name §11.1 gave it.
  Future<void> writePortion(int profileId, String uid, double portion) =>
      (update(inventoryLines)
            ..where((t) => t.profileId.equals(profileId) & t.uid.equals(uid)))
          .write(InventoryLinesCompanion(portion: Value(portion)));

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

  Future<List<LootBoxe>> lootBoxesFor(int profileId) =>
      (select(lootBoxes)..where((t) => t.profileId.equals(profileId))).get();

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

  Future<List<GroundItem>> groundItemsFor(int profileId) =>
      (select(groundItems)..where((t) => t.profileId.equals(profileId))).get();

  Future<int> addGroundItem(GroundItemsCompanion item) =>
      into(groundItems).insert(item);

  /// Leaves fewer of a pile on the ground than there were.
  ///
  /// What a full pack could not take stays where it was put, rather than
  /// disappearing with the rest of the row (§4.8).
  Future<void> setGroundItemCount(int id, int count) async {
    await (update(groundItems)..where((t) => t.id.equals(id))).write(
      GroundItemsCompanion(count: Value(count)),
    );
  }

  /// Deletes by row id. Used by §4.8's sweep and by picking something back up.
  Future<void> removeGroundItems(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(groundItems)..where((t) => t.id.isIn(ids))).go();
  }

  // -------------------------------------------------------------- bodies ---

  Future<List<RemainsRow>> remainsFor(int profileId) => (select(
    remainsEntries,
  )..where((t) => t.profileId.equals(profileId))).get();

  /// Writes a body, or leaves the one already there alone: the same enemy
  /// cannot fall twice.
  Future<void> addRemainsRow(RemainsEntriesCompanion body) async {
    await into(remainsEntries).insert(body, mode: InsertMode.insertOrIgnore);
  }

  Future<void> markRemainsSearched(int profileId, String enemyId) async {
    await (update(remainsEntries)..where(
          (t) => t.profileId.equals(profileId) & t.enemyId.equals(enemyId),
        ))
        .write(const RemainsEntriesCompanion(searched: Value(true)));
  }

  Future<void> removeRemains(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(remainsEntries)..where((t) => t.id.isIn(ids))).go();
  }

  // --------------------------------------------------------------- stats ---

  Future<StatsRow?> statsFor(int profileId) => (select(
    profileStats,
  )..where((t) => t.profileId.equals(profileId))).getSingleOrNull();

  Future<void> writeStats(ProfileStatsCompanion stats) async {
    await into(profileStats).insert(stats, mode: InsertMode.insertOrReplace);
  }

  // --------------------------------------------------------------- stash ---

  /// §18.2: what is on the shelves of one shelter.
  Future<List<StashRow>> stashFor(int profileId, int shelterId) =>
      (select(shelterItems)..where(
            (t) =>
                t.profileId.equals(profileId) & t.shelterId.equals(shelterId),
          ))
          .get();

  /// Replaces the contents of one shelter, in one transaction.
  ///
  /// Rewritten whole rather than diffed, exactly as the pack is: a stash is a
  /// handful of rows, and half-applied contents would be worse than a rewrite
  /// that costs nothing measurable.
  Future<void> writeStash(
    int profileId,
    int shelterId,
    List<ShelterItemsCompanion> lines,
  ) => transaction(() async {
    await (delete(shelterItems)..where(
          (t) => t.profileId.equals(profileId) & t.shelterId.equals(shelterId),
        ))
        .go();

    for (final line in lines) {
      await into(shelterItems).insert(line);
    }
  });

  // --------------------------------------------------------------- death ---

  /// §9.1: the character is over, and the row stays for the Chronicle.
  Future<void> markProfileDead(
    int id, {
    required DateTime at,
    required String cause,
  }) async {
    await (update(profiles)..where((t) => t.id.equals(id))).write(
      ProfilesCompanion(
        diedAt: Value(at),
        deathCause: Value(cause),
        isActive: const Value(false),
      ),
    );
  }

  Future<int> addChronicleEntry(ChronicleEntriesCompanion entry) =>
      into(chronicleEntries).insert(entry);

  Future<List<ChronicleEntry>> chronicleFor(int profileId) => (select(
    chronicleEntries,
  )..where((t) => t.profileId.equals(profileId))).get();

  // -------------------------------------------------------------- actions ---

  /// §2.1a: what this profile is doing, or null.
  Future<ActiveActionRow?> activeActionFor(int profileId) => (select(
    activeActions,
  )..where((t) => t.profileId.equals(profileId))).getSingleOrNull();

  /// Puts one on, replacing whatever was there.
  ///
  /// ⚠️ Replacing rather than refusing: the caller has already asked whether
  /// the hands are free, and a stale row surviving a crash would otherwise
  /// block every future action with no way to clear it.
  Future<int> beginActiveAction(ActiveActionsCompanion action) =>
      transaction(() async {
        await (delete(
          activeActions,
        )..where((t) => t.profileId.equals(action.profileId.value))).go();
        return into(activeActions).insert(action);
      });

  /// §2.1a.3: writes down what has been earned, without ending anything.
  Future<void> creditActiveAction(int profileId, int seconds) =>
      (update(activeActions)..where((t) => t.profileId.equals(profileId)))
          .write(ActiveActionsCompanion(creditedSeconds: Value(seconds)));

  Future<void> clearActiveAction(int profileId) =>
      (delete(activeActions)..where((t) => t.profileId.equals(profileId))).go();

  // ---------------------------------------------------------------- craft ---

  /// §18.4, §18.6: the job this profile has on the bench, or null.
  Future<CraftJobRow?> craftJobFor(int profileId) => (select(
    craftJobs,
  )..where((t) => t.profileId.equals(profileId))).getSingleOrNull();

  /// Puts one on the bench, replacing whatever was there.
  ///
  /// ⚠️ Replacing rather than refusing, because the caller has already asked
  /// whether the bench is free — and a stale row surviving a crash would
  /// otherwise block every future job with no way to clear it.
  Future<void> beginCraftJob(CraftJobsCompanion job) => transaction(() async {
    await (delete(
      craftJobs,
    )..where((t) => t.profileId.equals(job.profileId.value))).go();
    await into(craftJobs).insert(job);
  });

  Future<void> clearCraftJob(int profileId) =>
      (delete(craftJobs)..where((t) => t.profileId.equals(profileId))).go();

  // ------------------------------------------------------------- shelter ---

  Future<List<ShelterRow>> sheltersFor(int profileId) =>
      (select(shelters)..where((t) => t.profileId.equals(profileId))).get();

  Future<int> addShelter(SheltersCompanion shelter) =>
      into(shelters).insert(shelter);

  Future<void> updateShelter(int id, SheltersCompanion changes) async {
    await (update(shelters)..where((t) => t.id.equals(id))).write(changes);
  }

  Future<void> removeShelter(int id) async {
    await (delete(shelters)..where((t) => t.id.equals(id))).go();
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
