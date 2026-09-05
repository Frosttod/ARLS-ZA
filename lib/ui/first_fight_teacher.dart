/// The scripted fight, from the side that speaks (§15.6).
///
/// [FirstFight] decides which line is owed; this holds the row on disk, turns a
/// step into words, and knows where the Walker goes. The split is the same one
/// the hints use, and for the same reason: what the game *says* is translated
/// data, and what it *decides* has to be testable without a screen.
library;

import 'dart:math';

import '../combat/blows_away.dart';
import '../combat/combat_session.dart';
import '../combat/enemy.dart';
import '../data/db/database.dart';
import '../game/first_fight.dart';
import '../l10n/app_localizations.dart';
import '../map/geometry.dart';
import '../safety/spawn_exclusion.dart';

/// The settings row it lives in. One key, because it is one story.
const String kFirstFightKey = 'onboarding.firstFight';

class FirstFightTeacher {
  FirstFightTeacher(
    this._db, {
    required this.say,
    required this.enemies,
    required this.targetId,
    required this.loaded,
    required this.noiseM,
  });

  final SaveDatabase _db;

  /// How a line reaches the player: the same one under the HUD as everything
  /// else the game says (§12).
  final void Function(String) say;

  /// Read at the moment of asking rather than passed in per tick — the fight
  /// changes between one and the next, and a snapshot of it would be a fourth
  /// copy of facts that already live somewhere.
  final List<Enemy> Function() enemies;
  final String? Function() targetId;
  final int Function() loaded;
  final double Function() noiseM;

  FirstFight _fight = const FirstFight();
  var _loaded = false;

  bool get isDone => _fight.isDone;
  int get shots => _fight.shots;

  Future<void> load() async {
    _fight = FirstFight.parse(await _db.readSetting(kFirstFightKey));
    _loaded = true;
  }

  /// Says whatever the fight has just taught, through [say].
  Future<void> teach(L10n l10n, {required bool standing}) async {
    if (!_loaded || _fight.isDone) return;

    // ⚠️ Read off the fight that is actually happening. The script chooses
    // *when to speak*; it never decides what is true.
    final walker = enemies()
        .where((enemy) => enemy.id == kFirstFightEnemyId)
        .firstOrNull;

    final step = _fight.due(
      enemyAlive: walker != null && !walker.isDead,
      noticed: walker != null && walker.state != EnemyState.idle,
      targeted: targetId() == kFirstFightEnemyId,
      standing: standing,
      magazineEmpty: loaded() <= 0,
      shotFired: _fight.shots > 0,
    );
    if (step == null) return;

    say(_words(step, l10n, noiseM: noiseM()));
    _fight = _fight.take(step);
    if (step == FirstFightStep.bill) _fight = _fight.ended();

    await _save();
  }

  /// §15.6's seventh line is a count, so every shot at it is counted.
  Future<void> shotFired() async {
    if (!_loaded || _fight.isDone) return;

    _fight = _fight.fired();
    await _save();
  }

  /// §15.6: the swing this Walker is allowed to land.
  ///
  /// ⚠️ Only when the scripted one is the *only* thing swinging. A player who
  /// walked their tutorial Walker into a crowd is in a real fight, and the
  /// script has no business making that one survivable.
  BlowsAway tameBlow(
    BlowsAway hurt, {
    required List<Enemy> swinging,
    required double bloodMl,
    required double maxMl,
  }) {
    final scripted = swinging.every((enemy) => enemy.id == kFirstFightEnemyId);
    if (!scripted || isDone) return hurt;

    return BlowsAway(
      bloodMl: FirstFight.tame(
        blowMl: hurt.bloodMl,
        bloodMl: bloodMl,
        maxMl: maxMl,
      ),
      blows: hurt.blows,
      worst: hurt.worst,
    );
  }

  /// Whether the scripted Walker still has to be put on the map.
  bool get owesEnemy => _loaded && !_fight.isDone && _fight.said.isEmpty;

  /// §15.6, §3.5: a hundred and twenty metres away, on ground a person may
  /// stand on.
  ///
  /// ⚠️ **The direction is chosen, the distance is not.** Sixteen bearings are
  /// tried and the first the exclusion filter allows wins; if every one of them
  /// is a road, a river or somebody's garden then the fight simply waits for
  /// the player to walk somewhere else. A tutorial that puts a Walker on a dual
  /// carriageway is a tutorial that teaches the one thing §3.5 forbids.
  /// Puts it on the map if it is owed, and hands back the session either way.
  CombatSession into(
    CombatSession session,
    GeoPoint player, {
    required SpawnFilter ground,
    required int seed,
  }) {
    if (!owesEnemy) return session;

    final walker = enemyNear(player, ground: ground, seed: seed);
    return walker == null ? session : session.withEnemy(walker);
  }

  Enemy? enemyNear(
    GeoPoint player, {
    required SpawnFilter ground,
    required int seed,
  }) {
    for (var turn = 0; turn < 16; turn++) {
      final at = player.offsetBy(metres: kFirstFightM, bearingDeg: turn * 22.5);
      if (!ground.allows(at)) continue;

      return Enemy.spawn(
        id: kFirstFightEnemyId,
        kind: EnemyKind.walker,
        at: at,
        home: at,
        random: Random(seed),
      );
    }
    return null;
  }

  String _words(FirstFightStep step, L10n l10n, {required double noiseM}) =>
      switch (step) {
        FirstFightStep.spotted => l10n.firstSpotted,
        FirstFightStep.aim => l10n.firstAim,
        FirstFightStep.standStill => l10n.firstStandStill,
        FirstFightStep.noise => l10n.firstNoise(noiseM.round().toString()),
        FirstFightStep.reload => l10n.firstReload,
        FirstFightStep.bill => l10n.firstBill(_fight.shots),
      };

  Future<void> _save() => _db.writeSetting(kFirstFightKey, _fight.wire);
}
