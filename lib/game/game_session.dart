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
import '../location/device_position_source.dart';
import '../location/position_source.dart';
import '../location/power_source.dart';
import '../sim/body.dart';
import '../sim/tick.dart';
import 'game_loop.dart';

/// A character ready to play, with everything derived from its sheet.
class ActiveCharacter {
  const ActiveCharacter({
    required this.profile,
    required this.body,
    required this.state,
  });

  final Profile profile;
  final BodyProfile body;
  final SimState state;

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
      state: SimState(
        lastUpdate: vitals.lastUpdate,
        bloodMl: vitals.bloodMl,
        waterMl: vitals.waterMl,
        caloriesKcal: vitals.caloriesKcal,
        pendingKcal: vitals.pendingKcal,
        pendingWaterMl: vitals.pendingWaterMl,
        heartRateBpm: vitals.heartRateBpm,
        sleepDebtSeconds: vitals.sleepDebtSeconds,
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
    final state = SimState.fresh(at: now, constants: constants);

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

  /// Starts the loop for [character] over [source].
  Future<GameLoop> startLoop({
    required ActiveCharacter character,
    required PositionSource source,
    GameClock? clock,
    PowerSource? power,
  }) async {
    final loop = GameLoop(
      session: session,
      source: source,
      profileId: character.profile.id,
      constants: character.constants,
      initialState: character.state,
      clock: clock,
      power: power,
    );
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
