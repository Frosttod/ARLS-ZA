/// Reading and writing the bodies (§10.3, §11.1).
///
/// The one part of a fight that is written down. §6.4 remakes the population
/// every time the game runs, and that is right for a Walker — it is not a
/// place. A body is: the player put it there, remembered where, and is
/// entitled to walk back for the pockets. Losing it to a restart takes away
/// their own work, which is the opposite of what §10.3 is for.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import 'enemy.dart';
import 'remains.dart';

class RemainsStore {
  const RemainsStore(this._db);

  final SaveDatabase _db;

  /// Every body still worth walking back to, with §10.3's clock applied.
  ///
  /// Swept on read, exactly as the ground piles and the camps are: one that
  /// went cold while the app was closed went cold all the same, and a timer
  /// that fires with the process dead is a timer that does not fire.
  Future<List<Remains>> load(int profileId, DateTime now) async {
    final rows = await _db.remainsFor(profileId);

    final gone = <int>[];
    final kept = <Remains>[];

    for (final row in rows) {
      final body = Remains(
        id: row.enemyId,
        kind: EnemyKind.values.firstWhere(
          (kind) => kind.name == row.kind,
          orElse: () => EnemyKind.walker,
        ),
        position: GeoPoint(row.latitude, row.longitude),
        diedAt: row.diedAt,
        searched: row.searched,
      );

      if (body.isGoneAt(now)) {
        gone.add(row.id);
        continue;
      }
      kept.add(body);
    }

    await _db.removeRemains(gone);
    return kept;
  }

  /// Writes one down. The same enemy cannot fall twice — a kill can be noticed
  /// by the shot that finished it and again by the tick that saw it finished.
  Future<void> add(int profileId, Remains body) => _db.addRemainsRow(
    RemainsEntriesCompanion.insert(
      profileId: profileId,
      enemyId: body.id,
      kind: body.kind.name,
      latitude: body.position.latitude,
      longitude: body.position.longitude,
      diedAt: body.diedAt,
      searched: Value(body.searched),
    ),
  );

  Future<void> searched(int profileId, String enemyId) =>
      _db.markRemainsSearched(profileId, enemyId);
}
