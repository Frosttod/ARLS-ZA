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
