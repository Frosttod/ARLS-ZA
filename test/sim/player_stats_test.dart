import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/sim/player_stats.dart';
import 'package:arls_za/sim/player_stats_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// STATYSTYKI POSTACI (§13.1).
///
/// A tally, not a state: it only ever grows, and it survives the app being
/// closed — which is the only reason it is worth keeping at all. A player who
/// wants to know whether they are getting better at this needs a number that
/// spans more than one afternoon.
void main() {
  group('what gets counted', () {
    test('accuracy is nothing at all before the first round', () {
      expect(PlayerStats.empty.accuracy, isNull);
      expect(PlayerStats.empty.meleeAccuracy, isNull);
      expect(PlayerStats.empty.shotsPerKill, isNull);
    });

    test('a miss costs accuracy and lands in no location', () {
      final stats = PlayerStats.empty
          .fired(where: HitLocation.torso, bloodMl: 300)
          .fired();

      expect(stats.shotsFired, 2);
      expect(stats.shotsHit, 1);
      expect(stats.accuracy, 0.5);
      expect(stats.bloodDealtMl, 300);
      expect(stats.hitsCounted, 1);
      expect(stats.hitsAt(HitLocation.torso), 1);
    });

    test('every location is counted apart', () {
      var stats = PlayerStats.empty;
      for (final where in HitLocation.values) {
        stats = stats.fired(where: where);
      }

      for (final where in HitLocation.values) {
        expect(stats.hitsAt(where), 1, reason: where.name);
      }
      expect(stats.hitsCounted, HitLocation.values.length);
    });

    test('rounds per kill is measured, not promised', () {
      final stats = PlayerStats.empty
          .fired(where: HitLocation.torso)
          .fired(where: HitLocation.torso)
          .fired()
          .killed();

      expect(stats.shotsPerKill, 3);
    });

    test('swings are their own accuracy', () {
      final stats = PlayerStats.empty
          .swung(where: HitLocation.head, bloodMl: 90)
          .swung();

      expect(stats.swings, 2);
      expect(stats.meleeAccuracy, 0.5);
      expect(stats.hitsAt(HitLocation.head), 1);
      // §5.2 and §5.1 are separate figures: a blade landing does not make the
      // shooting look better.
      expect(stats.accuracy, isNull);
    });

    test('blood taken and blood lost are two different tallies', () {
      final stats = PlayerStats.empty
          .fired(where: HitLocation.legs, bloodMl: 120)
          .hurt(200)
          .hurt(50);

      expect(stats.bloodDealtMl, 120);
      expect(stats.bloodLostMl, 250);
    });
  });

  group('across a restart', () {
    late SaveDatabase db;
    late PlayerStatsStore store;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
      store = PlayerStatsStore(db);
    });

    tearDown(() => db.close());

    test('a character who has done nothing has an empty tally', () async {
      final loaded = await store.load(profileId);

      expect(loaded.shotsFired, 0);
      expect(loaded.accuracy, isNull);
    });

    test('the tally comes back as it was left', () async {
      final stats = PlayerStats.empty
          .fired(where: HitLocation.head, bloodMl: 400)
          .fired()
          .swung(where: HitLocation.arms, bloodMl: 40)
          .killed()
          .hurt(150)
          .searchedSomething()
          .wentDown();

      await store.save(profileId, stats);
      final loaded = await store.load(profileId);

      expect(loaded.shotsFired, 2);
      expect(loaded.shotsHit, 1);
      expect(loaded.swings, 1);
      expect(loaded.swingsHit, 1);
      expect(loaded.hitsAt(HitLocation.head), 1);
      expect(loaded.hitsAt(HitLocation.arms), 1);
      expect(loaded.kills, 1);
      expect(loaded.bloodDealtMl, 440);
      expect(loaded.bloodLostMl, 150);
      expect(loaded.searches, 1);
      expect(loaded.blackouts, 1);
    });

    test('saving twice keeps one row, not two', () async {
      await store.save(profileId, PlayerStats.empty.fired());
      await store.save(profileId, PlayerStats.empty.fired().fired());

      final loaded = await store.load(profileId);

      expect(loaded.shotsFired, 2);
    });
  });
}
