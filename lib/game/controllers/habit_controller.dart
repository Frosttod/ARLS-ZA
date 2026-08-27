/// §16.4: how much this player actually plays, measured rather than assumed.
///
/// ⚠️ **The world's clock ran on the calendar.** §6.5.3 grows hotspots on a
/// pace that is meant to answer the player, and `PlayHabit` has modelled that
/// since stage 6 — but nothing ever measured a minute, so every save handed it
/// an empty habit and every world in the game grew at the floor. Somebody
/// playing two hours a day and somebody who had not opened the app in a week
/// were given the same city.
///
/// What counts is time with the game **awake**: nothing ticks in the
/// background (§2.1a.3 settles against the wall clock instead), so a phone in
/// a pocket is not play, and neither is a night the app spent installed.
///
/// The running total is flushed on every pause and on a slow timer besides,
/// because the two moments this process is most likely to be killed are the
/// two moments a session ends (§11.1.5).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../sim/play_habit.dart';
import '../../sim/play_store.dart';

/// How often an unbroken session writes its total down. Long, because this is
/// a number in minutes and a crash costs at most this much of it.
const Duration kHabitFlush = Duration(minutes: 5);

class HabitController extends ChangeNotifier {
  HabitController(this._db);

  final SaveDatabase _db;

  /// §16.4's answer, as §6.5.3 asks for it. Reloaded whenever a day's total
  /// changes, so a long session moves the world it is being played in.
  final ValueNotifier<PlayHabit> habit = ValueNotifier(const PlayHabit([]));

  int? _profileId;

  /// When the current awake stretch began, or null while nothing is running.
  DateTime? _since;

  /// Today's totals as they stand on disk, so a flush replaces rather than
  /// adds — a write that lands twice must not count the same minutes twice.
  final Map<String, int> _counted = {};

  Timer? _flush;

  Future<void> load(int profileId, {DateTime? now}) async {
    _profileId = profileId;

    final store = PlayStore(_db);
    final today = now ?? DateTime.now();

    // A device that has been off for a month tidies itself the moment
    // somebody comes back to it.
    await store.trim(
      profileId,
      oldest: today.subtract(const Duration(days: PlayHabit.window)),
    );

    final loaded = await store.load(profileId);
    _counted
      ..clear()
      ..addEntries([
        for (final day in loaded.days)
          MapEntry(dayKey(day.day), day.activeMinutes),
      ]);

    habit.value = loaded;
    notifyListeners();
  }

  /// The game is awake and being played, from [now].
  void woke([DateTime? now]) {
    if (_since != null) return;

    _since = now ?? DateTime.now();
    _flush ??= Timer.periodic(kHabitFlush, (_) => unawaited(settle()));
  }

  /// The game has gone into a pocket. Whatever was running is written down.
  Future<void> slept([DateTime? now]) async {
    await settle(now);

    _since = null;
    _flush?.cancel();
    _flush = null;
  }

  /// Books the stretch so far and starts a new one where it left off.
  ///
  /// ⚠️ The stretch is carried, not ended: this runs on a timer during a
  /// session that is still going. `_since` moves forward by exactly the
  /// minutes written down, so the seconds that did not make a whole minute are
  /// still there for the next flush — otherwise a long session flushed often
  /// enough would count as almost nothing.
  Future<void> settle([DateTime? now]) async {
    final since = _since;
    final profileId = _profileId;
    if (since == null || profileId == null) return;

    final byDay = minutesByDay(since, now ?? DateTime.now());
    if (byDay.isEmpty) return;

    var written = 0;
    final store = PlayStore(_db);

    for (final entry in byDay.entries) {
      final total = (_counted[entry.key] ?? 0) + entry.value;

      _counted[entry.key] = total;
      written += entry.value;
      await store.save(profileId, entry.key, total);
    }

    _since = since.add(Duration(minutes: written));

    habit.value = await store.load(profileId);
    notifyListeners();
  }

  @override
  void dispose() {
    _flush?.cancel();
    _flush = null;
    habit.dispose();
    super.dispose();
  }
}
