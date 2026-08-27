/// Reading and writing §16.4's habit (§11.1).
library;

import '../data/db/database.dart';
import 'play_habit.dart';

class PlayStore {
  const PlayStore(this._db);

  final SaveDatabase _db;

  /// The window's days, newest first, and nothing older.
  ///
  /// ⚠️ Trimmed on the way in rather than on a schedule. This is read once a
  /// session, which is exactly often enough — and a device that has been off
  /// for a month tidies itself the moment somebody comes back to it.
  Future<PlayHabit> load(int profileId) async {
    final rows = await _db.playDaysFor(profileId, limit: PlayHabit.window);

    return PlayHabit([
      for (final row in rows)
        if (dayOf(row.day) case final day?)
          PlayDay(day: day, activeMinutes: row.activeMinutes),
    ]);
  }

  /// One day's running total, replaced.
  Future<void> save(int profileId, String day, int activeMinutes) =>
      _db.writePlayDay(profileId, day, activeMinutes);

  /// Everything from before [oldest], which is nobody's habit any more.
  Future<void> trim(int profileId, {required DateTime oldest}) =>
      _db.trimPlayDays(profileId, before: dayKey(oldest));
}

/// A `YYYY-MM-DD` back into a local midnight, or null if it is not one.
///
/// ⚠️ Null rather than a guess. A row this build cannot read is a row written
/// by another one, and inventing a date for it would put a day in the habit
/// that nobody played.
DateTime? dayOf(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;

  return DateTime(year, month, day);
}
