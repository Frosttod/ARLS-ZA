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

  /// §9.2: when a softcore character comes round, or null while they are on
  /// their feet. Wall-clock, and the one state in the game that runs with the
  /// app closed on purpose — being unconscious cannot require watching a
  /// screen.
  DateTimeColumn get downUntil => dateTime().nullable()();

  /// §9.2: when they stop being taken for dead, or null once they are on
  /// their feet properly.
  ///
  /// ⚠️ Its own column, and not a flag in memory. Held in memory, "already
  /// woken" was forgotten every time the process died — so reopening the app
  /// ran the waking again, put the character back to a quarter of their blood
  /// and announced the caches a second time. A character cannot wake up twice
  /// from the same blackout.
  DateTimeColumn get graceUntil => dateTime().nullable()();

  /// §5.6.2, §6.1a: a fight the player walked out of, and where.
  ///
  /// ⚠️ The enemies themselves are not written down — §6.4 remakes them every
  /// run — so without this, closing the app is a perfect escape from anything.
  /// Four numbers is all it takes to make it not one: when the street was last
  /// stirred up, where, and by how many.
  DateTimeColumn get huntUntil => dateTime().nullable()();
  RealColumn get huntLatitude => real().nullable()();
  RealColumn get huntLongitude => real().nullable()();
  IntColumn get huntCount => integer().withDefault(const Constant(0))();

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

  /// Eaten and drunk, not yet absorbed (§2.2, §2.3).
  ///
  /// Persisted because it is real: a player who eats and closes the app has
  /// food in them, and losing it on a restart would teach them to stand and
  /// watch the bar instead.
  RealColumn get pendingKcal => real().withDefault(const Constant(0))();
  RealColumn get pendingWaterMl => real().withDefault(const Constant(0))();

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

  /// Which note this is, for a picked-up `lit_note` (§19.1). Null for anything
  /// else. The text is not stored: it lives in `notes.json` and is resolved
  /// again on reading, so a corrected translation reaches notes already in a
  /// player's pack.
  TextColumn get noteId => text().nullable()();

  /// How much of the piece is left, 0–1 (§4.7). One for everything whole, and
  /// for every line written before a half-drunk bottle was a thing the game
  /// could hold.
  RealColumn get portion => real().withDefault(const Constant(1))();

  /// §5.6.3: what is bolted to this piece, as item ids separated by commas.
  ///
  /// A list in a column, which is a compromise: a table of its own would be
  /// correct and would also mean a join for something that is never queried on
  /// its own. Empty for everything that is not a weapon with something on it.
  TextColumn get attachments => text().withDefault(const Constant(''))();

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

  /// How much of §10.3.5's budget has been spent searching this place.
  ///
  /// Persisted for the same reason the barrier is: a shelf somebody already
  /// turned over is still turned over after a restart. Zero on every save
  /// written before this existed, which reads as untouched — right for a box
  /// that had only ever been searched once and emptied by it.
  IntColumn get searchUnits => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
    'UNIQUE (profile_id, poi_id)',
  ];
}

/// Items a player put down and may come back for (§4.8).
///
/// Kept apart from [InventoryLines] because they belong to a place rather than
/// to a character's back, and apart from [LootBoxes] because a lootbox is
/// somewhere the world put something and this is somewhere a person did.
///
/// Named for the ground rather than for the act, so drift's generated row
/// class is `GroundItem` and does not collide with the game's own
/// `DroppedItem`. Two types with one name in two libraries is a prefix in
/// every file that touches either.
class GroundItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  TextColumn get itemId => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();

  /// Per-piece state, exactly as the inventory keeps it: a dropped rifle is
  /// still as worn as it was, and a part-read book keeps its place (§4.6.3).
  RealColumn get condition => real().nullable()();
  IntColumn get pagesTotal => integer().nullable()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();

  /// §5.6.3: and what was bolted to it. Same shape as the inventory's column,
  /// `att_red_dot,tool_suppressor`.
  ///
  /// ⚠️ Putting a rifle down used to strip it. The sights, the suppressor and
  /// the long magazine simply stopped existing — the rarest things in the game
  /// (§5.6.3), evaporating on the pavement because the row they were written
  /// to had nowhere to put them.
  TextColumn get attachments => text().withDefault(const Constant(''))();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  DateTimeColumn get droppedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// The place the player comes back to (§8).
///
/// ⚠️ **These coordinates are the player's home address.** §8.2 is explicit
/// about what that means: they are written here, they never leave the phone,
/// and this table is excluded from Android's automatic backup — an unencrypted
/// cloud copy of where somebody sleeps is not a risk worth any convenience.
@DataClassName('ShelterRow')
class Shelters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// `main` or `camp` (§8.5.1). Text rather than an index so a save is
  /// readable, as everywhere else in this schema.
  TextColumn get kind => text()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// §2.1a.3: building runs against the clock, so the record keeps when it
  /// began and what it was going to take. Recomputing the second from the
  /// first would let a hammer lost halfway through lengthen a finished job.
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get buildSeconds => integer()();

  /// §2.1a.3: how much of that work is left, and it only comes down while the
  /// player is standing on the site. Null on a row written before the rule
  /// existed, which then falls back to the plain deadline.
  IntColumn get buildLeftSeconds => integer().nullable()();

  /// §8.3: when work was last credited against this place.
  ///
  /// ⚠️ On the row rather than in memory. Held in memory it started again at
  /// nothing every time the process did — so a shelter left to build overnight,
  /// with the app closed as §8.3 intends, was in exactly the same state in the
  /// morning as it had been at bedtime.
  DateTimeColumn get workedAt => dateTime().nullable()();

  /// §8.4: `storage:2,lounge:1`. Absent means nought, which is what every
  /// shelter starts as.
  TextColumn get modules => text().withDefault(const Constant(''))();

  /// §8.5.2: when the player was last inside. A camp nobody comes back to
  /// falls down; the shelter never does.
  DateTimeColumn get visitedAt => dateTime().nullable()();

  /// §8.4, §18.2: the module currently going up, as `lounge:2`, and when it
  /// will be finished. Both null when nothing is being built.
  ///
  /// On the row rather than in an occupation because it has to finish while
  /// the app is dead — §8.3 says as much about the shelter itself, and a
  /// nine-hour workshop is even less of a thing to sit and watch.
  TextColumn get building => text().nullable()();
  DateTimeColumn get buildingReadyAt => dateTime().nullable()();

  /// §2.1a.3 again, for the module: work left, spent only on site.
  IntColumn get buildingLeftSeconds => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// §10.3: bodies, where they fell.
///
/// Persisted, unlike the enemies themselves. §6.4 remakes the population every
/// time the game runs, and that is right for a Walker — it is not a place. A
/// body is: the player put it there, remembered where, and is entitled to walk
/// back for the pockets. Losing it to a restart takes away their own work.
@DataClassName('RemainsRow')
class RemainsEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// The enemy's own id, so the same body cannot be written twice.
  TextColumn get enemyId => text()();

  /// §6.2's kind, by name — what it was decides what is in its pockets.
  TextColumn get kind => text()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  DateTimeColumn get diedAt => dateTime()();

  /// Pockets already turned out. The mark stays on the map rather than the row
  /// being deleted: a player who searched it should be able to see that they
  /// did, or they walk back to it a second time.
  BoolColumn get searched => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
    'UNIQUE (profile_id, enemy_id)',
  ];
}

/// What a character has done, counted (§13.1, §16.5).
///
/// One row per character, all of it counters. Kept apart from `vitals` because
/// vitals is rewritten every sixty seconds with the state of a body and this is
/// a tally that only ever grows — mixing the two would mean rewriting a history
/// to record a heartbeat.
///
/// ⚠️ Nothing here leaves the phone. §16.5 allows only aggregated telemetry,
/// off by default and with explicit consent; this is the player's own record,
/// for the player's own screen.
@DataClassName('StatsRow')
class ProfileStats extends Table {
  IntColumn get profileId => integer()();

  /// §5.1: every trigger pull, and how many of them landed.
  IntColumn get shotsFired => integer().withDefault(const Constant(0))();
  IntColumn get shotsHit => integer().withDefault(const Constant(0))();

  /// §5.4: the same for anything swung.
  IntColumn get swings => integer().withDefault(const Constant(0))();
  IntColumn get swingsHit => integer().withDefault(const Constant(0))();

  /// §2.6: where the ones that landed landed.
  IntColumn get hitsHead => integer().withDefault(const Constant(0))();
  IntColumn get hitsTorso => integer().withDefault(const Constant(0))();
  IntColumn get hitsArms => integer().withDefault(const Constant(0))();
  IntColumn get hitsLegs => integer().withDefault(const Constant(0))();

  /// §6.2: how many went down, and how much blood it took to do it.
  IntColumn get kills => integer().withDefault(const Constant(0))();
  RealColumn get bloodDealtMl => real().withDefault(const Constant(0))();

  /// §2.6: and how much of the player's own went the other way.
  RealColumn get bloodLostMl => real().withDefault(const Constant(0))();

  /// §10.2: places turned over, and §9.2's blackouts.
  IntColumn get searches => integer().withDefault(const Constant(0))();
  IntColumn get blackouts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {profileId};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}
