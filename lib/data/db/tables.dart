/// Save schema, split by write frequency (design doc §11.1.1).
///
/// | layer | contents                                   | written              |
/// | ----- | ------------------------------------------ | -------------------- |
/// | hot   | position, blood, water, calories, HR       | every 60 s, on pause |
/// | warm  | inventory, skills, shelter, hotspots       | on every change      |
/// | cold  | chronicle, records, settings               | on event             |
///
/// Migrations are additive only (§11.1.4): columns and tables get added, never
/// removed or renamed. A column that falls out of use stays in the schema
/// marked deprecated, because an old save must still load.
library;

import 'package:drift/drift.dart';

/// Key/value store for schema metadata and engine bookkeeping. Cold layer.
class MetaEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One row per character. Cold layer — written at creation and on death.
///
/// Body parameters live here and never leave the device (§1.2).
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 4, max: 16)();

  /// 'M' or 'F'. Needed by the Nadler and Mifflin–St Jeor formulas (§1.3),
  /// nothing else.
  TextColumn get sex => text().withLength(min: 1, max: 1)();

  IntColumn get ageYears => integer()();
  IntColumn get heightCm => integer()();
  RealColumn get weightKg => real()();

  /// The player's own resting heart rate, or null to use §1.3's estimate.
  ///
  /// Self-reported, like height and weight, and it never leaves the device
  /// (§1.3). Nullable because most people do not know theirs, and a guessed
  /// number would be worse than the formula.
  IntColumn get measuredRestingHr => integer().nullable()();

  /// 'hardcore' | 'softcore'. Chosen once, never changed (§9).
  TextColumn get deathMode => text().withLength(min: 1, max: 16)();

  /// Root seed for the deterministic RNG (§11).
  IntColumn get rngSeed => integer()();

  DateTimeColumn get createdAt => dateTime()();

  /// Set when a hardcore character dies; the row is kept for the Chronicle.
  DateTimeColumn get diedAt => dateTime().nullable()();
  TextColumn get deathCause => text().nullable()();

  /// Whether this is the character the game resumes into.
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

/// Hot layer: physiology and position. One row per profile, overwritten in
/// place every 60 s and whenever the app goes to the background (§11.1.1).
///
/// A crash costs at most 60 seconds of physiology — a minute rewound, not
/// hours of progression.
class Vitals extends Table {
  IntColumn get profileId => integer()();

  /// Monotonic timestamp the simulation has been advanced to. Every tick is
  /// derived from this rather than from an incrementing counter, which is what
  /// makes replaying a tick idempotent (§11.1.2).
  DateTimeColumn get lastUpdate => dateTime()();

  RealColumn get bloodMl => real()();
  RealColumn get waterMl => real()();
  RealColumn get caloriesKcal => real()();
  RealColumn get heartRateBpm => real()();

  /// Accumulated sleep debt in seconds (§2.5.4).
  IntColumn get sleepDebtSeconds => integer().withDefault(const Constant(0))();

  /// Last known metabolic zone: 'open' | 'camp' | 'shelter' | 'sleep' (§2.1).
  /// With GPS off the game assumes the character stayed in this zone.
  TextColumn get zone => text().withDefault(const Constant('open'))();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get accuracyM => real().nullable()();

  /// Draw position of each RNG stream, so a resumed session continues the
  /// sequence instead of restarting it.
  TextColumn get rngCursors => text().withDefault(const Constant('{}'))();

  // ---------------------------------------------------------- schema v2 ---
  //
  // Added when the physiology of §2 replaced the placeholder model. Additive
  // only: every column below has a default, so a v1 row loads without needing
  // anything backfilled (§11.1.4).

  /// Current bleeding tier (§2.6): none | superficial | moderate | severe |
  /// arterial. A wound has to survive the app being killed — otherwise closing
  /// the app would be first aid.
  TextColumn get bleedTier => text().withDefault(const Constant('none'))();

  /// Occupation in progress, as JSON (§2.1a). Null when the character is idle.
  ///
  /// Stored opaquely rather than as columns: occupations gain fields as the
  /// shelter systems of §8 and §18 arrive, and each of those would otherwise
  /// be a schema migration.
  TextColumn get occupationJson => text().nullable()();

  /// Ground speed from the last accepted fix, in km/h. Persisted so a catch-up
  /// after a crash does not restart the character from a standstill.
  RealColumn get speedKmh => real().withDefault(const Constant(0))();

  /// What the character is carrying, in kilograms. Feeds the load surcharge of
  /// §2.2 until the real inventory arrives in stage 4.
  RealColumn get carriedKg => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {profileId};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// Cold layer: one row per finished survival streak, feeding the Chronicle
/// screen (§13.1). Never updated after insert.
class ChronicleEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  IntColumn get survivalDays => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();

  TextColumn get cause => text()();
  TextColumn get deathMode => text()();

  /// Full state dump at the moment the streak ended, as JSON: hotspot levels,
  /// skills, location. Kept opaque so adding fields never needs a migration.
  TextColumn get snapshotJson => text().withDefault(const Constant('{}'))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// Cold layer: player settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Bookkeeping for the rotating snapshots of §11.1.3. The snapshot files
/// themselves live next to the database; this table records what exists and
/// whether it verified.
class SnapshotRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get fileName => text()();
  DateTimeColumn get takenAt => dateTime()();
  IntColumn get sizeBytes => integer()();

  /// SHA-256 of the snapshot file, checked before any restore.
  TextColumn get checksum => text()();

  /// Schema version the snapshot was taken at, so a snapshot from an older
  /// build is migrated rather than loaded blind.
  IntColumn get schemaVersion => integer()();

  /// 'periodic' | 'pre_migration' — a pre-migration snapshot is never rotated
  /// out until the migration it guards has been proven good.
  TextColumn get reason => text().withDefault(const Constant('periodic'))();
}

/// What a character is carrying (§4.1, §18.1a).
///
/// One row per inventory line rather than one per piece: a stack of forty
/// rounds is one row with a count. Anything carrying its own state — a rifle
/// with its own wear, a part-read book (§4.6.3) — is one row per piece, and
/// [count] stays at one.
///
/// The item is stored by id and never by its parameters. Mass, volume and
/// everything else come from the catalogue at read time, so a content pack
/// that corrects a weight corrects it for items already in a player's pack.
class InventoryLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// Catalogue id (§4.1). Not a foreign key: the catalogue is data files, not
  /// tables, and an item that a removed content pack defined must not take the
  /// save down with it — it is dropped on read and reported.
  TextColumn get itemId => text()();

  IntColumn get count => integer().withDefault(const Constant(1))();

  /// 'pack' | 'worn'. Worn kit costs mass but not volume (§18.1a), so where a
  /// thing is decides which limit it counts against.
  TextColumn get slot => text().withDefault(const Constant('pack'))();

  /// 0–100 for anything that wears out, null for anything that does not.
  RealColumn get condition => real().nullable()();

  /// Rolled per copy at generation (§4.6.4). Null for anything but literature.
  IntColumn get pagesTotal => integer().nullable()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// Lootboxes standing on the map (§10).
///
/// One row per place, keyed by the POI it sits on, so "one box per place"
/// survives a restart. Position is stored with it rather than looked up again:
/// the box has to be findable even if the player uninstalls the map pack it
/// came from, and a marker that moved because a tile was reread would be a
/// marker the player walked to for nothing.
class LootBoxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// From `Poi.id`: position to six decimals plus what the place is.
  TextColumn get poiId => text()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// Which table of §10.3 this place draws from.
  TextColumn get tableId => text()();

  /// The name off the tile, where the map had one. Shown on the marker.
  TextColumn get name => text().nullable()();

  DateTimeColumn get spawnedAt => dateTime()();

  /// Null while it still has something in it.
  DateTimeColumn get lootedAt => dateTime().nullable()();

  /// Rolled when it is emptied, never on a schedule — a fixed interval would
  /// let a player time a whole city off one box (§10).
  DateTimeColumn get respawnAt => dateTime().nullable()();

  /// When the barrier of §19.3 was got through, or null while it still shuts.
  ///
  /// Persisted because a forced door stays forced. Making the player break in
  /// again after a restart would turn one decision into a chore.
  DateTimeColumn get openedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
    'UNIQUE (profile_id, poi_id)',
  ];
}
