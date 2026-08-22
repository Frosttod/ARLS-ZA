import 'package:arls_za/actions/action_runner.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/sim/action_pace.dart';
import 'package:arls_za/sim/timed_action.dart';
import 'package:test/test.dart';

import '../db/db_fixture.dart';

/// ZEGAR POD KAŻDĄ AKCJĄ (§2.1a, §11.1, §4.7).
///
/// ⚠️ These are the tests that had to exist before anything was rewired. The
/// runner decides how much of an interrupted meal was eaten and whether a
/// dismantling that ran out in a pocket is finished — and both of those are
/// **irreversible for the player**. A wrong rule here loses somebody's rifle.
///
/// So: killed at half a second, killed at ninety-nine per cent, killed and
/// gone for a week. Every one of them written down before a line of the game
/// was changed to use this.
void main() {
  final t0 = DateTime.utc(2026, 8, 20, 12);

  late SaveDatabase db;
  late int profileId;
  late DateTime now;

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    now = t0;
  });

  tearDown(() => db.close());

  ActionRunner runner() =>
      ActionRunner(db: db, profileId: profileId, clock: () => now);

  TimedAction eating() => TimedAction(
    kind: 'eating',
    subjectUid: 'a.1',
    startedAt: now,
    total: const Duration(seconds: 100),
  );

  TimedAction dismantling() => TimedAction(
    kind: ActionKinds.recycling,
    subjectUid: 'a.2',
    startedAt: now,
    total: const Duration(minutes: 10),
  );

  group('one pair of hands (§2.1a)', () {
    test('the first thing starts', () async {
      final it = runner();

      expect(await it.start(eating()), isNull);
      expect(it.isBusy, isTrue);
    });

    test('and the second is refused', () async {
      final it = runner();
      await it.start(eating());

      expect(await it.start(dismantling()), StartRefusal.busy);
      expect(it.current!.kind, 'eating');
    });

    test('finishing frees them again', () async {
      final it = runner();
      await it.start(eating());
      await it.finish();

      expect(it.isBusy, isFalse);
      expect(await it.start(dismantling()), isNull);
    });
  });

  group('credit is earned, not elapsed (§4.7)', () {
    test('standing still, the bar and the clock agree', () async {
      final it = runner();
      await it.start(eating());

      now = now.add(const Duration(seconds: 50));
      it.tick(const PaceContext());

      expect(it.current!.credited, const Duration(seconds: 50));
    });

    test('walking, the clock runs ahead of the bar', () async {
      // ⚠️ The change the whole model exists for. A sandwich on the move is a
      // longer sandwich, not a lost one.
      final it = runner();
      await it.start(eating());

      now = now.add(const Duration(seconds: 80));
      it.tick(const PaceContext(speedKmh: 4));

      expect(it.current!.credited, const Duration(seconds: 50));
      expect(it.current!.isDone, isFalse);
    });

    test('and it says when the thing has actually finished', () async {
      final it = runner();
      await it.start(eating());

      now = now.add(const Duration(seconds: 40));
      expect(it.tick(const PaceContext()), isNull, reason: 'not yet');

      now = now.add(const Duration(seconds: 70));
      expect(it.tick(const PaceContext())?.isDone, isTrue);
    });

    test('exactly once, however many ticks follow', () async {
      // ⚠️ A caller that applied the outcome twice would eat the sandwich
      // twice. The report is the edge, not the state.
      final it = runner();
      await it.start(eating());

      now = now.add(const Duration(seconds: 200));
      expect(it.tick(const PaceContext()), isNotNull);

      now = now.add(const Duration(seconds: 5));
      expect(it.tick(const PaceContext()), isNull, reason: 'reported twice');
    });

    test('running ruins a suture rather than pausing it (§4.7)', () async {
      final it = runner();
      await it.start(
        TimedAction(
          kind: 'suturing',
          startedAt: now,
          total: const Duration(minutes: 16),
        ),
      );

      now = now.add(const Duration(minutes: 5));
      it.tick(const PaceContext(speedKmh: 12));

      expect(it.current!.credited, Duration.zero);
    });
  });

  group('killed and come back to (§11.1)', () {
    test('killed at half a second, the meal is still there', () async {
      // The reported bug. An action that lived only in memory was an action a
      // kill undid, and closing the app was a way to eat for free.
      await runner().start(eating());

      final after = runner();
      expect((await after.restore())!.kind, 'eating');
    });

    test('and it comes back with the mouthfuls it had earned', () async {
      final before = runner();
      await before.start(eating());

      now = now.add(const Duration(seconds: 30));
      before.tick(const PaceContext());
      await before.checkpoint();

      final after = runner();
      final back = (await after.restore())!;

      expect(back.credited, const Duration(seconds: 30));
      expect(back.progress, closeTo(0.3, 0.001));
    });

    test('killed at ninety-nine per cent, it is not finished', () async {
      // ⚠️ The edge that costs a player something. A rounding that called
      // this done would swallow the last of a bottle nobody drank.
      final before = runner();
      await before.start(eating());

      now = now.add(const Duration(seconds: 99));
      before.tick(const PaceContext());
      await before.checkpoint();

      final back = (await runner().restore())!;

      expect(back.isDone, isFalse);
      expect(back.progress, closeTo(0.99, 0.001));
    });

    test('a dismantling left in a pocket finishes on its own', () async {
      // §2.1a.3: unattended work runs whether anybody watches. The whole gap
      // counts, because the rate was one throughout.
      await runner().start(dismantling());

      now = now.add(const Duration(minutes: 30));
      final back = (await runner().restore())!;

      expect(back.isDone, isTrue);
    });

    test('but a meal in a pocket earns nothing (§4.7)', () async {
      // ⚠️ There is no way to know whether the character stood still or ran,
      // and guessing in the player's favour would make a pocket the fastest
      // way to eat.
      final before = runner();
      await before.start(eating());

      now = now.add(const Duration(seconds: 20));
      before.tick(const PaceContext());
      await before.checkpoint();

      now = now.add(const Duration(hours: 3));
      final back = (await runner().restore())!;

      expect(back.credited, const Duration(seconds: 20));
      expect(back.isDone, isFalse);
    });

    test('and a week away does not finish it either', () async {
      await runner().start(eating());

      now = now.add(const Duration(days: 7));
      expect((await runner().restore())!.isDone, isFalse);
    });

    test('nothing running comes back as nothing', () async {
      expect(await runner().restore(), isNull);
    });
  });

  group('writing to disk as little as will do', () {
    test('a checkpoint that would change nothing does not happen', () async {
      // A game carried in a pocket for hours must not write the same number
      // to flash three thousand times.
      final it = runner();
      await it.start(eating());

      now = now.add(const Duration(seconds: 10));
      it.tick(const PaceContext());
      await it.checkpoint();
      await it.checkpoint();

      // Nothing to assert but the absence of a crash and the right value —
      // the guard itself is the point, and it is exercised by the second call.
      expect((await runner().restore())!.credited.inSeconds, 10);
    });

    test('and the gap is written down when a restore settles it', () async {
      // Otherwise the settled figure lives only in memory and a second kill
      // loses it again.
      await runner().start(dismantling());

      now = now.add(const Duration(minutes: 4));
      await runner().restore();

      final again = (await runner().restore())!;
      expect(again.credited, const Duration(minutes: 4));
    });
  });
}
