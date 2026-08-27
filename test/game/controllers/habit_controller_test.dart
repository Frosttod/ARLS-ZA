import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/habit_controller.dart';
import 'package:arls_za/sim/play_habit.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// ILE KTOŚ NAPRAWDĘ GRA (§16.4, §6.5.3).
///
/// ⚠️ **The world's clock ran on the calendar.** `PlayHabit` has modelled
/// §16.4's question since stage 6 — can somebody with an hour a day keep up —
/// and nothing ever measured a minute. Every save handed §6.5.3 an empty habit,
/// so a player with two hours a day and a player who had not opened the app in
/// a week were given the same city, growing at the same floor.
///
/// This is the half that was missing: the minutes, on disk, per local day.
void main() {
  final now = DateTime.utc(2026, 8, 10, 12);

  late SaveDatabase db;
  late HabitController habit;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    habit = HabitController(db);

    profileId = await db.createProfile(
      profile: ProfilesCompanion.insert(
        name: 'Ocalały',
        sex: 'M',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        deathMode: 'hardcore',
        rngSeed: 1,
        createdAt: now,
      ),
      vitals: (id) => VitalsCompanion.insert(
        profileId: Value(id),
        lastUpdate: now,
        bloodMl: 5000,
        waterMl: 2500,
        caloriesKcal: 2500,
        heartRateBpm: 60,
      ),
    );
  });

  tearDown(() async {
    habit.dispose();
    await db.close();
  });

  /// A local evening, so the day boundary is the one a player would name.
  DateTime evening(int day, [int hour = 20, int minute = 0]) =>
      DateTime(2026, 8, day, hour, minute);

  group('§16.4: a session is written down', () {
    test('what was played comes back off disk', () async {
      await habit.load(profileId, now: evening(10));

      habit.woke(evening(10, 20));
      await habit.slept(evening(10, 21));

      final reread = HabitController(db);
      addTearDown(reread.dispose);
      await reread.load(profileId, now: evening(10));

      expect(reread.habit.value.days, hasLength(1));
      expect(reread.habit.value.days.single.activeMinutes, 60);
    });

    test('and a pocket is not play', () async {
      // Nothing ticks in the background, so nothing is counted there either.
      await habit.load(profileId, now: evening(10));

      habit.woke(evening(10, 20));
      await habit.slept(evening(10, 20, 30));
      // Eight hours in a coat.
      habit.woke(evening(11, 4, 30));
      await habit.slept(evening(11, 4, 40));

      expect(habit.habit.value.days.first.activeMinutes, 10);
    });
  });

  group('§11.1.5: and a flush that lands twice', () {
    test('does not count the same minutes twice', () async {
      // ⚠️ The reason a day's total is replaced rather than added to. The
      // flush runs on a timer *and* on every pause, and a session that paused
      // a minute after a flush must not be charged the whole stretch again.
      await habit.load(profileId, now: evening(10));

      habit.woke(evening(10, 20));
      await habit.settle(evening(10, 20, 30));
      await habit.settle(evening(10, 20, 45));
      await habit.slept(evening(10, 21));

      expect(habit.habit.value.days.single.activeMinutes, 60);
    });

    test('and the seconds between flushes are carried, not lost', () async {
      // Ten flushes of ninety seconds is fifteen minutes, not ten.
      await habit.load(profileId, now: evening(10));

      habit.woke(evening(10, 20));
      for (var flush = 1; flush <= 10; flush++) {
        await habit.settle(evening(10, 20).add(Duration(seconds: 90 * flush)));
      }

      expect(habit.habit.value.days.single.activeMinutes, 15);
    });
  });

  group('§16.4: a habit, not a history', () {
    test('anything older than the window is dropped on the way in', () async {
      await db.writePlayDay(profileId, dayKey(evening(1)), 120);
      await db.writePlayDay(profileId, dayKey(evening(9)), 30);

      await habit.load(profileId, now: evening(10));

      expect(habit.habit.value.days, hasLength(1));
      expect(habit.habit.value.days.single.activeMinutes, 30);
    });

    test('a save with no week behind it reads as the floor', () async {
      await habit.load(profileId, now: evening(10));

      expect(habit.habit.value.days, isEmpty);
      expect(habit.habit.value.hoursPerDay, kMinPlayHours);
    });

    test('and the days come back newest first', () async {
      await db.writePlayDay(profileId, dayKey(evening(8)), 10);
      await db.writePlayDay(profileId, dayKey(evening(10)), 30);
      await db.writePlayDay(profileId, dayKey(evening(9)), 20);

      await habit.load(profileId, now: evening(10));

      expect(
        [for (final day in habit.habit.value.days) day.activeMinutes],
        [30, 20, 10],
      );
    });
  });

  test('§16.4: waking twice does not start two clocks', () async {
    await habit.load(profileId, now: evening(10));

    habit.woke(evening(10, 20));
    // A dialog over the app, a permission sheet: `resumed` arrives again and
    // the stretch has not been interrupted.
    habit.woke(evening(10, 20, 30));
    await habit.slept(evening(10, 21));

    expect(habit.habit.value.days.single.activeMinutes, 60);
  });

  test('§6.5.3: and the game actually runs the world on it', () {
    // ⚠️ Source-level, and this is the whole of faza B. The model above was
    // written, tested and correct for a stage while the one caller handed it
    // `const PlayHabit([])` — the same defect class as a HUD parameter drawn
    // by nothing: perfect code that nothing reaches.
    // Both files: the binding is a list of its own now, and the lifecycle
    // is still the screen's.
    final main =
        File('lib/main.dart').readAsStringSync() +
        File('lib/game/controller_binding.dart').readAsStringSync();
    final hotspots = File(
      'lib/game/controllers/hotspot_controller.dart',
    ).readAsStringSync();

    expect(
      hotspots.contains('const PlayHabit([])'),
      isFalse,
      reason: 'the world is growing at the floor for everybody again',
    );
    expect(hotspots.contains('required PlayHabit habit,'), isTrue);
    expect(main.contains('habit: _habit.habit.value,'), isTrue);

    // §2.1a.3: measured where the game wakes and sleeps, because nothing
    // ticks in a pocket and a pocket is not play.
    expect(main.contains('habit.woke()'), isTrue);
    expect(main.contains('_habit.slept()'), isTrue);
  });
}
