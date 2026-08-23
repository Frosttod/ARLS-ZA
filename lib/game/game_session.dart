/// Builds a playable session out of the pieces (design doc §1.3, §11).
///
/// The composition root for gameplay: it turns a character sheet into a saved
/// profile, or reads an existing one back, and hands over a running
/// [GameLoop]. Kept out of the widgets so the sequence is testable without
/// pumping a UI, and so `main.dart` stays a list of screens.
library;

import 'package:drift/drift.dart';

import '../core/deterministic_rng.dart';
import '../core/game_clock.dart';
import '../data/db/database.dart';
import '../data/persistence/save_bootstrap.dart';
import '../devtools/dev_mode.dart';
import '../devtools/dev_session.dart';
import '../map/geometry.dart';
import '../shelter/shelter.dart';
import '../location/device_position_source.dart';
import '../location/position_source.dart';
import '../location/power_source.dart';
import '../combat/pursuit.dart';
import '../sim/body.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';
import 'game_loop.dart';

/// A character ready to play, with everything derived from its sheet.
class ActiveCharacter {
  const ActiveCharacter({
    required this.profile,
    required this.body,
    required this.state,
    this.bleeding = BleedTier.none,
    this.downUntil,
    this.graceUntil,
    this.pursuit,
  });

  final Profile profile;
  final BodyProfile body;
  final SimState state;

  /// §2.6: what was still open when the app was last closed.
  final BleedTier bleeding;

  /// §9.2: when the hour on the ground runs out, or null while upright.
  final DateTime? downUntil;

  /// §9.2: when they stop being taken for dead, or null once they are.
  final DateTime? graceUntil;

  /// §5.6.2: the fight the player last walked out of, or null.
  final Pursuit? pursuit;

  /// §9: how this character ends.
  DeathMode get deathMode => DeathMode.fromWire(profile.deathMode);

  /// §9.1: hardcore, and already over.
  bool get isDead => profile.diedAt != null;

  SimConstants get constants => body.toSimConstants();
}

/// Creates characters, loads them back, and starts the loop.
class GameSessionFactory {
  const GameSessionFactory(this.session);

  final SaveSession session;

  SaveDatabase get db => session.db;

  /// The character the game should resume into, or null on a first run.
  Future<ActiveCharacter?> loadActive() async {
    final profile = await db.activeProfile();
    if (profile == null) return null;

    final vitals = await db.vitalsFor(profile.id);
    if (vitals == null) return null;

    final body = BodyProfile.from(
      BodySpec(
        sex: Sex.fromWire(profile.sex),
        ageYears: profile.ageYears,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        measuredRestingHr: profile.measuredRestingHr,
      ),
    );

    return ActiveCharacter(
      profile: profile,
      body: body,
      // §2.6: a wound that was still open when the app was closed is still
      // open. Without this a bleed ends every time somebody locks the screen.
      bleeding: BleedTier.fromWire(vitals.bleedTier),
      // §9.2: an hour on the ground runs against the wall clock, so it goes on
      // running while the app is dead. That is the point of it.
      downUntil: vitals.downUntil,
      graceUntil: vitals.graceUntil,
      // §5.6.2: what was still after them when the app went away. Closing it
      // has to cost something, or nothing in §5 costs anything at all.
      pursuit:
          vitals.huntUntil == null ||
              vitals.huntLatitude == null ||
              vitals.huntLongitude == null
          ? null
          : Pursuit(
              at: GeoPoint(vitals.huntLatitude!, vitals.huntLongitude!),
              until: vitals.huntUntil!,
              count: vitals.huntCount,
            ),
      state: SimState(
        lastUpdate: vitals.lastUpdate,
        bloodMl: vitals.bloodMl,
        waterMl: vitals.waterMl,
        caloriesKcal: vitals.caloriesKcal,
        pendingKcal: vitals.pendingKcal,
        pendingWaterMl: vitals.pendingWaterMl,
        heartRateBpm: vitals.heartRateBpm,
        // ⚠️ §11.1.4: a row written before mass moved has nought here, and
        // nought is not a body. The profile's creation weight is the only
        // honest answer, and it is the right one — a save from before this
        // existed is a save in which nobody ever lost a gram.
        bodyMassKg: vitals.bodyMassKg > 0
            ? vitals.bodyMassKg
            : profile.weightKg,
        sleepDebtSeconds: vitals.sleepDebtSeconds,
        sleepStrain: vitals.sleepStrain,
        dryStreakSeconds: vitals.dryStreakSeconds,
        starvedStreakSeconds: vitals.starvedStreakSeconds,
        zone: MetabolicZone.fromWire(vitals.zone),
        rngCursor: 0,
      ),
    );
  }

  /// Writes a new character and its opening vitals in one transaction.
  ///
  /// The seed is drawn once here and never again: it is what makes a run
  /// replayable, so it belongs to the character rather than to the session
  /// (§11).
  Future<ActiveCharacter> create({
    required String name,
    required BodySpec spec,
    required DeathMode deathMode,
    required DateTime now,
  }) async {
    final body = BodyProfile.from(spec);
    final constants = body.toSimConstants();
    final state = SimState.fresh(
      at: now,
      constants: constants,
      massKg: spec.weightKg,
    );

    final id = await db.createProfile(
      profile: ProfilesCompanion.insert(
        name: name,
        sex: spec.sex.wire,
        ageYears: spec.ageYears,
        heightCm: spec.heightCm,
        weightKg: spec.weightKg,
        measuredRestingHr: Value(spec.measuredRestingHr),
        deathMode: deathMode.wire,
        rngSeed: DeterministicRng.newSeed(),
        createdAt: now.toUtc(),
        isActive: const Value(true),
      ),
      vitals: (profileId) => VitalsCompanion.insert(
        profileId: Value(profileId),
        lastUpdate: state.lastUpdate,
        bloodMl: state.bloodMl,
        waterMl: state.waterMl,
        caloriesKcal: state.caloriesKcal,
        heartRateBpm: state.heartRateBpm,
        bodyMassKg: Value(state.bodyMassKg),
        zone: Value(state.zone.wire),
      ),
    );

    final profile = await db.profileById(id);
    return ActiveCharacter(profile: profile!, body: body, state: state);
  }

  /// The last position written to the save, or null if there never was one.
  ///
  /// The region screen opens before the first fix arrives — a lock takes
  /// seconds and the screen is the first thing a player sees — so without this
  /// it cannot tell which region is under their feet and offers sixteen in
  /// catalogue order (§16.6).
  Future<({double latitude, double longitude})?> lastKnownPosition(
    int profileId,
  ) async {
    final vitals = await db.vitalsFor(profileId);
    final latitude = vitals?.latitude;
    final longitude = vitals?.longitude;
    if (latitude == null || longitude == null) return null;
    return (latitude: latitude, longitude: longitude);
  }

  /// §9.1: ends a hardcore character, and files them in the Chronicle.
  ///
  /// The row is kept rather than deleted: §13.1 is the whole point of playing
  /// hardcore, and a streak nobody can look at afterwards is not a streak.
  Future<void> recordDeath({
    required ActiveCharacter character,
    required String cause,
    required DateTime now,
  }) async {
    await db.markProfileDead(character.profile.id, at: now, cause: cause);
    await db.addChronicleEntry(
      ChronicleEntriesCompanion.insert(
        profileId: character.profile.id,
        survivalDays: now.difference(character.profile.createdAt).inDays,
        startedAt: character.profile.createdAt,
        endedAt: now,
        cause: cause,
        deathMode: character.profile.deathMode,
      ),
    );
  }

  /// Starts the loop for [character] over [source].
  /// ⚠️ [shelters] and [standingAt] are given *before* the loop starts, and
  /// that ordering is the whole reason they are parameters.
  ///
  /// [GameLoop.start] replays everything that passed while the app was gone
  /// (§11.1.2). A night is one span, and what it is credited as depends
  /// entirely on where the loop believes the character was standing. Told
  /// afterwards — which is what the interface used to do, two awaits later —
  /// the loop replayed the whole night as somebody stood outdoors and awake:
  /// the sleep debt *grew* by a third of the night instead of falling, and the
  /// night cost open-ground food and water instead of §2.1's fifth.
  Future<GameLoop> startLoop({
    required ActiveCharacter character,
    required PositionSource source,
    GameClock? clock,
    PowerSource? power,
    List<Shelter> shelters = const [],
    GeoPoint? standingAt,
  }) async {
    final loop = GameLoop(
      session: session,
      source: source,
      profileId: character.profile.id,
      constants: character.constants,
      // §2.3: so the loop can re-derive §1.3's figures when the character's
      // weight moves. Without it a starving body keeps a healthy body's carry
      // limits, blood volume and daily requirement.
      body: character.body,
      initialState: character.state,
      initialBleeding: character.bleeding,
      deathMode: character.deathMode,
      downUntil: character.downUntil,
      graceUntil: character.graceUntil,
      pursuit: character.pursuit,
      dead: character.isDead,
      clock: clock,
      power: power,
    );
    // Before start(), never after: see the note on this method.
    if (shelters.isNotEmpty) loop.setShelters(shelters);
    if (standingAt != null) loop.setStandingAt(standingAt);

    await loop.start();
    return loop;
  }
}

/// Where the position comes from (§11.2).
///
/// The simulator is used only when it has been asked for — see
/// [kSimulatorSettingKey]. Everything else, including an ordinary debug build,
/// gets the real chip. Downstream nothing can tell the difference, which is the
/// whole point.
PositionSource buildPositionSource({
  required ForegroundNotice notice,
  DevSession? dev,
  bool useSimulator = false,
}) {
  if (kDevTools && useSimulator && dev != null) return dev.source;
  return DevicePositionSource(notice: notice);
}
