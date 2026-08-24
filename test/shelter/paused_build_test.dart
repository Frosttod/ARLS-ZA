import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/shelter/shelter_store.dart';
import 'package:arls_za/sim/daylight.dart';
import 'package:test/test.dart';

import '../db/db_fixture.dart';

/// ODŁOŻONA ROBOTA (§2.1a, §8.3).
///
/// ⚠️ **The only way out of a build was to cancel it.**
///
/// A build is an occupation (§2.1a) and an occupation blocks every other one,
/// which is right — one pair of hands. But cancelling hands the materials back
/// and throws the *hours* away, so somebody nine hours into a workshop could
/// not search the house they were standing in without starting the workshop
/// again from nothing.
///
/// Putting the work down throws away neither. The timber stays in the walls,
/// the hours stay on the row, and what stops is the clock.
///
/// ⚠️ Not the same thing as walking off. §2.1a.3 already stops the clock when
/// the player leaves the site and starts it again when they come back — that
/// is the world deciding. This is the player deciding, on their own site, and
/// it is the half that was missing.
void main() {
  const home = GeoPoint(52.4084, 16.9342);
  final t0 = DateTime.utc(2026, 8, 24, 12);

  Shelter building({bool paused = false}) => Shelter(
    id: 1,
    kind: ShelterKind.main,
    position: home,
    startedAt: t0,
    buildTime: const Duration(hours: 3),
    buildLeft: const Duration(hours: 2),
    workedAt: t0,
    paused: paused,
  );

  group('the clock stops and nothing else does', () {
    test('an hour on site pays an hour in', () {
      final after = building().worked(const Duration(hours: 1), at: t0);

      expect(after.buildLeft, const Duration(hours: 1));
    });

    test('and an hour on a site put down pays nothing', () {
      final after = building(
        paused: true,
      ).worked(const Duration(hours: 1), at: t0);

      expect(after.buildLeft, const Duration(hours: 2));
    });

    test('the counter on screen stands still too', () {
      // ⚠️ Otherwise a player who put the work down would watch it finish.
      // The live figure counts the seconds since the last write (§8.3), and
      // that clock has to stop with the rest of it.
      final later = t0.add(const Duration(hours: 1));

      expect(
        building().buildLeftAt(later, onSite: true),
        const Duration(hours: 1),
      );
      expect(
        building(paused: true).buildLeftAt(later, onSite: true),
        const Duration(hours: 2),
      );
    });

    test('and nothing about the work itself has changed', () {
      final down = building(paused: true);

      expect(down.buildLeft, building().buildLeft);
      expect(down.buildTime, building().buildTime);
      expect(down.isReadyAt(t0.add(const Duration(days: 9))), isFalse);
    });
  });

  group('§11.1: it survives the app being killed', () {
    late SaveDatabase db;
    late ShelterStore store;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
      store = ShelterStore(db);
    });

    tearDown(() => db.close());

    test('put down stays put down', () async {
      final id = await store.begin(
        profileId,
        kind: ShelterKind.main,
        at: home,
        now: t0,
        buildTime: const Duration(hours: 3),
      );

      await store.setPaused(id, paused: true, now: t0);

      final back = (await store.load(profileId, t0)).single;
      expect(back.paused, isTrue);
      expect(back.isWorking, isFalse);
    });

    test('and picking it up again starts the clock, not the work', () async {
      final id = await store.begin(
        profileId,
        kind: ShelterKind.main,
        at: home,
        now: t0,
        buildTime: const Duration(hours: 3),
      );

      await store.setPaused(id, paused: true, now: t0);
      final resumedAt = t0.add(const Duration(hours: 5));
      await store.setPaused(id, paused: false, now: resumedAt);

      final back = (await store.load(profileId, resumedAt)).single;

      expect(back.paused, isFalse);
      // ⚠️ The five hours spent doing something else are not paid in as work.
      // Without moving the crediting mark, picking the job back up would
      // credit the whole break the moment the next tick landed.
      expect(back.workedAt, resumedAt);
      expect(
        back.buildLeftAt(resumedAt, onSite: true),
        const Duration(hours: 3),
      );
    });

    test(
      'a save from before this reads as nothing put down (§11.1.4)',
      () async {
        final id = await store.begin(
          profileId,
          kind: ShelterKind.main,
          at: home,
          now: t0,
          buildTime: const Duration(hours: 3),
        );

        expect((await store.load(profileId, t0)).single.paused, isFalse);
        expect(id, greaterThan(0));
      },
    );
  });

  test('§2.1a: put down, it stops blocking everything else', () {
    // Source-level: the busy check is a list, and a list is a bug waiting for
    // the next thing somebody adds to it. Same budget the one-action tests
    // keep over the same function.
    final main = File('lib/main.dart').readAsStringSync();
    final start = main.indexOf('String? _alreadyBusy()');
    final body = main.substring(start, main.indexOf('\n  /// ', start));

    expect(
      body.contains('if (place.paused) continue;'),
      isTrue,
      reason: 'work put down is an occupation again',
    );
  });

  test('§12, §17.2: and there is a countdown to dusk to plan it against', () {
    // The other half of the same decision: whether to pick the work back up
    // now or wait, and how much light is left to do anything else in.
    final ahead = twilightAhead(
      fromUtc: DateTime.utc(2026, 6, 21, 12),
      latitude: 52.41,
      longitude: 16.93,
    );

    expect(ahead, isNotNull);
    expect(ahead!.untilDark, isTrue);
    expect(ahead.left, greaterThan(const Duration(hours: 5)));

    // And the other way round, from the middle of the night.
    final dawn = twilightAhead(
      fromUtc: DateTime.utc(2026, 6, 21, 23),
      latitude: 52.41,
      longitude: 16.93,
    );

    expect(dawn!.untilDark, isFalse);
  });

  test('a polar summer has no dusk to count to', () {
    // ⚠️ Null rather than a made-up figure. A countdown that never arrives is
    // worse than no countdown: it is a promise the sky will not keep.
    expect(
      twilightAhead(
        fromUtc: DateTime.utc(2026, 6, 21, 12),
        latitude: 69.6,
        longitude: 18.9,
      ),
      isNull,
    );
  });
}
