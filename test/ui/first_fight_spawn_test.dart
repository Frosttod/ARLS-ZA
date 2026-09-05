import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/first_fight.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:arls_za/ui/first_fight_teacher.dart';
import 'package:flutter_test/flutter_test.dart';

/// §15.6, §3.5: where the one scripted Walker is allowed to stand.
void main() {
  const here = GeoPoint(52.4064, 16.9252);

  FirstFightTeacher teacher(SaveDatabase db) => FirstFightTeacher(
    db,
    say: (_) {},
    enemies: () => const [],
    targetId: () => null,
    loaded: () => 30,
    noiseM: () => 700,
  );

  late SaveDatabase db;

  setUp(() => db = SaveDatabase.memory());
  tearDown(() => db.close());

  test('a hundred and twenty metres away, and it is a Walker', () async {
    final first = teacher(db);
    await first.load();

    final walker = first.enemyNear(
      here,
      ground: SpawnFilter(const []),
      seed: 7,
    );

    expect(walker, isNotNull);
    expect(walker!.id, kFirstFightEnemyId);
    expect(walker.position.distanceTo(here), closeTo(kFirstFightM, 1));
    expect(kFirstFightM, 120);
  });

  test('§3.5: never on a road, whatever direction that takes', () async {
    // A motorway running east-west through the player. The east and west
    // bearings are refused; the ones that are not are still 120 m out.
    final motorway = MapFeature(
      shape: FeatureShape.line,
      geometry: [
        here.offsetBy(metres: 500, bearingDeg: 270),
        here.offsetBy(metres: 500, bearingDeg: 90),
      ],
      tags: const {'highway': 'motorway'},
    );

    final first = teacher(db);
    await first.load();

    final walker = first.enemyNear(
      here,
      ground: SpawnFilter([motorway]),
      seed: 7,
    );

    expect(walker, isNotNull);
    expect(
      SpawnFilter([motorway]).refuse(walker!.position),
      isNull,
      reason:
          'a tutorial that puts a Walker on a dual carriageway teaches the '
          'one thing §3.5 forbids',
    );
  });

  test('and nowhere at all if every direction is refused', () async {
    // Standing in the middle of a lake big enough to cover every bearing.
    final lake = MapFeature(
      shape: FeatureShape.area,
      geometry: [
        for (var bearing = 0; bearing < 360; bearing += 45)
          here.offsetBy(metres: 400, bearingDeg: bearing.toDouble()),
      ],
      tags: const {'natural': 'water'},
    );

    final first = teacher(db);
    await first.load();

    expect(
      first.enemyNear(here, ground: SpawnFilter([lake]), seed: 7),
      isNull,
      reason: 'the fight waits for the player to walk somewhere else',
    );
  });

  test('it is put on the map once, however many ticks run', () async {
    final first = teacher(db);
    await first.load();

    var session = const CombatSession(seed: 1);
    for (var tick = 0; tick < 5; tick++) {
      session = first.into(
        session,
        here,
        ground: SpawnFilter(const []),
        seed: 7,
      );
    }

    expect(
      session.enemies.where((e) => e.id == kFirstFightEnemyId),
      hasLength(1),
    );
  });
}
