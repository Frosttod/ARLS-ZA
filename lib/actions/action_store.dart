/// Reading and writing what the character is doing (§2.1a, §11.1).
///
/// One row per profile, replaced rather than appended: §2.1a gives a person one
/// pair of hands, and a store that can only hold one is a rule nobody has to
/// remember to enforce.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import '../sim/timed_action.dart';

class ActionStore {
  const ActionStore(this.db);

  final SaveDatabase db;

  /// What is on the go, or null.
  Future<TimedAction?> load(int profileId) async {
    final row = await db.activeActionFor(profileId);
    if (row == null) return null;

    final latitude = row.latitude;
    final longitude = row.longitude;

    return TimedAction(
      id: row.id,
      kind: row.kind,
      subjectUid: row.subjectUid,
      startedAt: row.startedAt,
      total: Duration(seconds: row.totalSeconds),
      credited: Duration(seconds: row.creditedSeconds),
      at: latitude == null || longitude == null
          ? null
          : GeoPoint(latitude, longitude),
      extra: TimedAction.extraFrom(row.extraJson),
    );
  }

  /// Starts one, replacing whatever was there.
  ///
  /// ⚠️ Written before the first second passes, not at the first checkpoint.
  /// The whole reason this table exists is that an action which lived only in
  /// memory was an action that a killed process undid — and a process can be
  /// killed in the first second as easily as the last.
  Future<TimedAction> begin(int profileId, TimedAction action) async {
    final id = await db.beginActiveAction(_companion(profileId, action));
    return action.copyWith(id: id);
  }

  /// §2.1a.3: writes down how much has been earned, without ending anything.
  ///
  /// Called on the way into the background and every so often while running.
  /// Not every second: the worst case is losing that much progress, and the
  /// shortest unattended action in the game is four minutes.
  Future<void> checkpoint(int profileId, TimedAction action) =>
      db.creditActiveAction(profileId, action.credited.inSeconds);

  Future<void> clear(int profileId) => db.clearActiveAction(profileId);

  ActiveActionsCompanion _companion(int profileId, TimedAction action) =>
      ActiveActionsCompanion.insert(
        profileId: profileId,
        kind: action.kind,
        startedAt: action.startedAt,
        totalSeconds: action.total.inSeconds,
        subjectUid: Value(action.subjectUid),
        creditedSeconds: Value(action.credited.inSeconds),
        latitude: Value(action.at?.latitude),
        longitude: Value(action.at?.longitude),
        extraJson: Value(action.extraJson),
      );
}
