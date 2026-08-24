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

  // --------------------------------------------------------- schema v27 ---
  //
  // §2.3's two lethal rules each need a clock, and neither had one. Both
  // default to nought, which is where a character who has just drunk and
  // eaten stands — so a v26 row loads as somebody in good order rather than
  // as somebody two days dry (§11.1.4).

  /// §2.3: seconds since any water at all reached the body.
  ///
  /// Feeds "brak wody > 48 h w warunkach wysiłku = śmierć". Reset by a
  /// swallow, not by a full reserve.
  IntColumn get dryStreakSeconds => integer().withDefault(const Constant(0))();

  /// §2.3: seconds the calorie reserve has been at nought.
  ///
  /// Feeds "0% przez > 24 h → postępująca utrata przytomności". Measured on
  /// the reserve rather than on the last meal, which is what that line says.
  IntColumn get starvedStreakSeconds =>
      integer().withDefault(const Constant(0))();

  // --------------------------------------------------------- schema v28 ---

  /// §2.3, §1.3: what the character weighs now, in kilograms.
  ///
  /// ⚠️ Defaults to nought, which is not a body — it is the marker for "this
  /// row predates a moving mass". The loader fills it from the profile's
  /// creation weight, because that is the only place that knows it (§11.1.4).
  RealColumn get bodyMassKg => real().withDefault(const Constant(0))();

  /// §2.5.5: accumulated sleep shortfall, in whole nights.
  ///
  /// Nought is a rested character, which is the right reading for a row
  /// written before this existed: nobody was ever chronically short of sleep
  /// in a version that could not measure it (§11.1.4).
  RealColumn get sleepStrain => real().withDefault(const Constant(0))();

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

/// Warm layer: §3.6.1's log of what the character did.
///
/// ⚠️ **A kind and a subject, never a sentence.** The words go around it when
/// it is drawn (§1.1), so a player who changes the language does not end up
/// with a diary half in Polish. The subject is data — an item id, an enemy
/// kind, a shop's name off the map — or null where the kind says everything.
///
/// Capped rather than kept forever: a walk writes an entry every few minutes
/// and a streak is measured in months (§13.1).
class JournalRows extends Table {
  @override
  String get tableName => 'journal';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  DateTimeColumn get at => dateTime()();

  /// [JournalKind.wire]. Text rather than an index, so adding a kind in the
  /// middle of the enum does not rewrite everything already on disk.
  TextColumn get kind => text()();

  TextColumn get subject => text().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// Warm layer: §6.5's three pressure points, one row each.
///
/// ⚠️ **A slot is a row, and an empty slot is still a row.** After a hotspot
/// is cleared its place rests for a day or two (§6.5.4) before another appears
/// somewhere else. Modelling that as the *absence* of a record would make "no
/// hotspot here yet" and "this one was just cleared" the same state, and they
/// are opposites: one is the game starting up, the other is a reward the
/// player earned and is owed the quiet for.
class HotspotRows extends Table {
  @override
  String get tableName => 'hotspots';

  IntColumn get profileId => integer()();

  /// 0, 1, 2 — §6.5.1 allows three. The slot outlives the hotspot in it.
  IntColumn get slot => integer()();

  /// What the radius is drawn from, stable for the life of this hotspot.
  IntColumn get seed => integer()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// 1–10 while it exists, 0 while the slot is resting.
  IntColumn get level => integer()();

  RealColumn get integrity => real()();

  DateTimeColumn get bornAt => dateTime()();

  /// §6.5.3: when it grows next. Against the clock — a hotspot promotes with
  /// the app shut, which is the whole point of it being pressure.
  DateTimeColumn get nextLevelAt => dateTime()();

  /// §6.5.4: furious until this moment, or null.
  DateTimeColumn get agitatedUntil => dateTime().nullable()();

  /// §6.5.4: the slot is empty until this moment, or null.
  DateTimeColumn get restingUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {profileId, slot};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// Warm layer: §7's four skills, one row each.
///
/// ⚠️ A row per skill rather than a JSON blob on the profile, and the reason
/// is the write pattern: experience arrives one event at a time — a shot, a
/// page, a bandage — and a blob would mean reading and rewriting all four
/// every time any one of them moved.
class SkillRows extends Table {
  @override
  String get tableName => 'skills';

  IntColumn get profileId => integer()();

  /// The wire name from [Skill]: 'scouting' | 'weapons' | 'medicine' |
  /// 'engineering'. Text rather than an index, because it also appears in
  /// `assets/data/literature.json` and the two must not drift apart.
  TextColumn get skill => text()();

  /// Everything earned in this skill, ever. The level is derived (§7.2) and
  /// never stored — a stored level and a stored total can disagree, and then
  /// nobody knows which one the player earned.
  IntColumn get xp => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {profileId, skill};

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

  /// §5.3: how many rounds are in this piece.
  ///
  /// ⚠️ On the item because that is where they are. It was one integer in the
  /// interface — what is in the gun — and nothing wrote it down: reloading
  /// took thirty rounds out of the pack, put them in a field in memory, and
  /// closing the app destroyed them. A player lost a magazine every restart.
  ///
  /// Null for everything that cannot hold rounds, which is nearly everything.
  IntColumn get rounds => integer().nullable()();

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  IntColumn get salvageSeconds => integer().nullable()();

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  TextColumn get uid => text().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// What has been left in a shelter or a camp (§18.2, §8.5.1).
///
/// The same shape as an [InventoryLines] row minus the slot, because a thing
/// on a shelf is the same thing it was in the pack: a rifle keeps what is
/// bolted to it, a book keeps how far it has been read, and a half-drunk
/// bottle stays half drunk.
///
/// ⚠️ The foreign key cascades on purpose. §8.5.2 says a camp nobody visits
/// for three weeks is gone "with whatever was in the chest", and the store
/// already deletes the row when it reads one that old — so the chest empties
/// itself, in the schema, without a line of code that could forget to.
@DataClassName('StashRow')
class ShelterItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get shelterId => integer()();

  /// Catalogue id (§4.1). Not a foreign key, for the reason in
  /// [InventoryLines]: the catalogue is data files, not tables.
  TextColumn get itemId => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();

  RealColumn get condition => real().nullable()();
  IntColumn get pagesTotal => integer().nullable()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  TextColumn get noteId => text().nullable()();
  RealColumn get portion => real().withDefault(const Constant(1))();
  TextColumn get attachments => text().withDefault(const Constant(''))();

  /// §5.3: how many rounds are in this piece.
  ///
  /// ⚠️ On the item because that is where they are. It was one integer in the
  /// interface — what is in the gun — and nothing wrote it down: reloading
  /// took thirty rounds out of the pack, put them in a field in memory, and
  /// closing the app destroyed them. A player lost a magazine every restart.
  ///
  /// Null for everything that cannot hold rounds, which is nearly everything.
  IntColumn get rounds => integer().nullable()();

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  IntColumn get salvageSeconds => integer().nullable()();

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  TextColumn get uid => text().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
    'FOREIGN KEY (shelter_id) REFERENCES shelters (id) ON DELETE CASCADE',
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

  /// §5.3: how many rounds are in this piece. A loaded rifle put down on the
  /// pavement is still loaded when it is picked up.
  IntColumn get rounds => integer().nullable()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  DateTimeColumn get droppedAt => dateTime()();

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  IntColumn get salvageSeconds => integer().nullable()();

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  TextColumn get uid => text().nullable()();

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

  // --------------------------------------------------------- schema v31 ---

  /// §2.1a, §8.3: whether the work here has been put down on purpose.
  ///
  /// ⚠️ **Not the same as not being on site.** Walking away already stops the
  /// clock (§2.1a.3) and starts it again on the way back, which is right. This
  /// is the player standing on their own site and saying *not now* — because a
  /// build in progress is an occupation (§2.1a) and blocks every other one, so
  /// without it the only way to search a house while a workshop was half up
  /// was to cancel the workshop.
  ///
  /// Nought is a save from before this existed, which is a save where nothing
  /// was ever put down (§11.1.4).
  BoolColumn get paused => boolean().withDefault(const Constant(false))();

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

/// §18.4, §18.6, §2.1a: one thing being made or taken apart, against the clock.
///
/// ⚠️ On a row rather than in memory, and for the reason the shelter's own
/// build column exists: §2.1a.3 says a shelter activity ticks with the app
/// closed. A forty-five minute pack is not something anybody sits and watches,
/// and neither is a quarter of an hour with a multitool.
///
/// One job at a time per profile. Two would need a queue, a queue would need
/// an order, and §18 never asks for either — a person has one pair of hands.
@DataClassName('CraftJobRow')
class CraftJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// The recipe being made (§18.4), or null when this is a dismantling.
  TextColumn get recipeId => text().nullable()();

  /// What is being taken apart (§18.6), or null when this is a making.
  ///
  /// Exactly one of the two is set. The item is **already gone from the pack**
  /// when the job starts: leaving it there until the job finished would let a
  /// player dismantle a rifle and shoot it for the next quarter of an hour.
  TextColumn get salvageItemId => text().nullable()();

  /// §18.6: how worn it was, because the return is scaled by it and the item
  /// itself is no longer around to ask.
  RealColumn get salvageCondition => real().nullable()();

  /// §18.6: several things taken apart in one sitting, in the order they come
  /// apart. JSON, null for anything else.
  ///
  /// ⚠️ **Still one job, not a queue.** The comment above is unchanged: a
  /// person has one pair of hands, and this row is still the one thing they
  /// are doing. What the list adds is that the sitting has parts — the rifle
  /// first, then the vest — so that stopping half way through leaves every
  /// piece either finished or untouched, and never something in between.
  ///
  /// The pieces named here are **still in the pack**, locked, waiting their
  /// turn. Only the one at the head is being worked on, which is why only it
  /// carries a bar and why the others can be given back untouched.
  TextColumn get salvageBatch => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get readyAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}

/// §2.1a, §11.1: the one thing the character is doing, on a row.
///
/// ⚠️ **This replaces four separate records of the same idea.** An occupation
/// as JSON on the vitals row, a craft job in its own table, three columns on
/// the shelter row — and, for eating, drinking, dressing a wound, searching
/// and forcing a door, nothing at all. That last gap is why closing the app
/// halfway through a meal handed the sandwich back untouched: the action lived
/// in a notifier inside a widget, so killing the process was a way to eat for
/// free.
///
/// One row per profile. §2.1a gives the character one pair of hands, and a
/// table that can only hold one row is a rule that cannot be forgotten.
@DataClassName('ActiveActionRow')
class ActiveActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// What is being done: an ActionKind's name, or one of ActionKinds'.
  TextColumn get kind => text()();

  /// §11.1: which piece it is being done to, by uid. Never the item id — a
  /// half-eaten sandwich must not come back as a bite out of its neighbour.
  TextColumn get subjectUid => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get totalSeconds => integer()();

  /// ⚠️ How much has been **earned**, which is not how much has passed.
  ///
  /// §4.7 and §10.2 give an action a rate: a dressing walked away from has
  /// been running ten minutes and earned six, and a search whose owner stepped
  /// off the spot has been running and earned nothing. Storing the elapsed
  /// time instead would hand both of them back finished.
  IntColumn get creditedSeconds => integer().withDefault(const Constant(0))();

  /// §10.2: where it began, for anything that has to stay put.
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  /// Whatever else this kind needs — a recipe id, a POI, a search depth.
  /// Opaque for the reason §2.1a's occupation column is: new kinds arrive with
  /// new fields, and each would otherwise be a migration.
  TextColumn get extraJson => text().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE',
  ];
}
