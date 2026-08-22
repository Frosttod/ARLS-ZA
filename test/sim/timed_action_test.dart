import 'package:arls_za/actions/action_store.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/action_pace.dart';
import 'package:arls_za/sim/timed_action.dart';
import 'package:test/test.dart';

import '../db/db_fixture.dart';

/// JEDNA RZECZ, KTÓRĄ POSTAĆ ROBI (§2.1a, §11.1).
///
/// ⚠️ **Four records of one idea became one.** An occupation as JSON on the
/// vitals row, a craft job in its own table, three columns on the shelter row
/// — and for eating, drinking, dressing a wound, searching and forcing a door,
/// nothing at all.
///
/// That last gap is the reported bug: close the app halfway through a meal and
/// the sandwich came back untouched, because the action lived in a notifier
/// inside a widget. Killing the process was a way to eat for free.
void main() {
  final t0 = DateTime.utc(2026, 8, 20, 12);

  TimedAction eating({Duration credited = Duration.zero}) => TimedAction(
    kind: 'eating',
    subjectUid: 'a.1',
    startedAt: t0,
    total: const Duration(seconds: 75),
    credited: credited,
  );

  group('earning time rather than passing it', () {
    test('standing still, a second is a second', () {
      final after = eating().advanced(
        const Duration(seconds: 10),
        const PaceContext(),
      );

      expect(after.credited, const Duration(seconds: 10));
    });

    test('walking, a second is less than a second', () {
      // ⚠️ The whole reason `credited` is stored rather than worked out from
      // `now − startedAt`. Ten minutes of walking with a dressing on is ten
      // minutes passed and six earned.
      final after = eating().advanced(
        const Duration(seconds: 16),
        const PaceContext(speedKmh: 4),
      );

      expect(after.credited.inSeconds, 10);
    });

    test('running, a second is nothing', () {
      final after = eating().advanced(
        const Duration(seconds: 60),
        const PaceContext(speedKmh: 12),
      );

      expect(after.credited, Duration.zero);
    });

    test('and it never earns more than the job is worth', () {
      final after = eating().advanced(
        const Duration(hours: 3),
        const PaceContext(),
      );

      expect(after.credited, after.total);
      expect(after.isDone, isTrue);
      expect(after.progress, 1);
    });

    test('a search stopped by a step earns nothing at all', () {
      // §10.2: half a shop turned over from across the road is not a slower
      // search, it is not a search.
      final search = TimedAction(
        kind: 'searching',
        startedAt: t0,
        total: const Duration(seconds: 45),
        at: const GeoPoint(52.4064, 16.9252),
      );

      final after = search.advanced(
        const Duration(seconds: 30),
        const PaceContext(atStartingPlace: false),
      );

      expect(after.credited, Duration.zero);
    });

    test('and picks up where it left off when they come back', () {
      // Stopped, not failed. §18.6 and §8.3 already work this way.
      var search = TimedAction(
        kind: 'searching',
        startedAt: t0,
        total: const Duration(seconds: 45),
      );

      search = search.advanced(
        const Duration(seconds: 20),
        const PaceContext(),
      );
      search = search.advanced(
        const Duration(seconds: 60),
        const PaceContext(atStartingPlace: false),
      );
      search = search.advanced(
        const Duration(seconds: 20),
        const PaceContext(),
      );

      expect(search.credited, const Duration(seconds: 40));
      expect(search.isDone, isFalse);
    });
  });

  group('what the player is told', () {
    test('what is left is what is left, not what has passed', () {
      final half = eating(credited: const Duration(seconds: 30));

      expect(half.left, const Duration(seconds: 45));
      expect(half.progress, closeTo(0.4, 0.001));
    });

    test('and on the move it says the longer figure', () {
      // §12: the number on screen is the number that will happen.
      final half = eating(credited: const Duration(seconds: 30));
      final walking = rateFor(
        ActionPace.handsOn,
        const PaceContext(speedKmh: 4),
      );

      expect(half.leftAt(walking)!.inSeconds, 72);
    });

    test('a stopped action has no end to give', () {
      expect(eating().leftAt(0), isNull);
    });
  });

  group('what kind of clock each thing has', () {
    test('the short actions of §4.7 are hands-on', () {
      for (final kind in ['eating', 'drinking', 'dressing', 'suturing']) {
        expect(paceOf(kind), ActionPace.handsOn, reason: kind);
      }
    });

    test('crafting and building run unattended', () {
      for (final kind in [
        ActionKinds.crafting,
        ActionKinds.recycling,
        ActionKinds.building,
      ]) {
        expect(paceOf(kind), ActionPace.unattended, reason: kind);
      }
    });

    test('and anything unknown is assumed to need the player present', () {
      // ⚠️ The safe default. A kind nobody has classified running unattended
      // would be an action that finishes itself in a pocket, which is the
      // failure that costs a player something.
      expect(paceOf('something_nobody_wrote_yet'), ActionPace.onTheSpot);
    });

    test('only suturing is ruined by running', () {
      expect(ruinedByRunning('suturing'), isTrue);
      expect(ruinedByRunning('eating'), isFalse);
      expect(ruinedByRunning(ActionKinds.crafting), isFalse);
    });
  });

  group('it survives the app being killed (§11.1)', () {
    late SaveDatabase db;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
    });

    tearDown(() => db.close());

    test('a meal begun is on disk before the first second passes', () async {
      // ⚠️ The reported bug, closed. A process can be killed in the first
      // second as easily as the last.
      final store = ActionStore(db);
      await store.begin(profileId, eating());

      final back = (await store.load(profileId))!;

      expect(back.kind, 'eating');
      expect(back.subjectUid, 'a.1');
      expect(back.total, const Duration(seconds: 75));
    });

    test(
      'and comes back with what it had earned, not what had passed',
      () async {
        final store = ActionStore(db);
        final begun = await store.begin(
          profileId,
          eating(credited: const Duration(seconds: 30)),
        );

        await store.checkpoint(profileId, begun);
        final back = (await store.load(profileId))!;

        expect(back.credited, const Duration(seconds: 30));
        expect(back.progress, closeTo(0.4, 0.001));
      },
    );

    test('the place it started in survives too (§10.2)', () async {
      final store = ActionStore(db);
      await store.begin(
        profileId,
        TimedAction(
          kind: 'searching',
          startedAt: t0,
          total: const Duration(seconds: 45),
          at: const GeoPoint(52.4064, 16.9252),
        ),
      );

      final back = (await store.load(profileId))!;

      expect(back.at?.latitude, closeTo(52.4064, 1e-9));
    });

    test('and whatever else the kind needed', () async {
      final store = ActionStore(db);
      await store.begin(
        profileId,
        TimedAction(
          kind: ActionKinds.crafting,
          startedAt: t0,
          total: const Duration(minutes: 25),
          extra: const {'recipe': 'craft_spear', 'count': 1},
        ),
      );

      final back = (await store.load(profileId))!;

      expect(back.extra['recipe'], 'craft_spear');
      expect(back.extra['count'], 1);
    });

    test('only one thing is ever on the go', () async {
      // §2.1a gives the character one pair of hands, and a store that can
      // hold one row is a rule nobody has to remember to enforce.
      final store = ActionStore(db);
      await store.begin(profileId, eating());
      await store.begin(
        profileId,
        TimedAction(
          kind: 'searching',
          startedAt: t0,
          total: const Duration(seconds: 45),
        ),
      );

      expect((await store.load(profileId))!.kind, 'searching');
    });

    test('and clearing leaves nothing behind', () async {
      final store = ActionStore(db);
      await store.begin(profileId, eating());
      await store.clear(profileId);

      expect(await store.load(profileId), isNull);
    });

    test('unreadable extras cost one action, not the launch', () async {
      // The same rule the item catalogue keeps: a row nobody can read is
      // dropped, never fatal.
      expect(TimedAction.extraFrom('{not json'), isEmpty);
      expect(TimedAction.extraFrom(null), isEmpty);
    });
  });
}
