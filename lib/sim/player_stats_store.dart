/// Reading and writing the tally (§13.1, §11.1).
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import 'player_stats.dart';

class PlayerStatsStore {
  const PlayerStatsStore(this._db);

  final SaveDatabase _db;

  Future<PlayerStats> load(int profileId) async {
    final row = await _db.statsFor(profileId);
    if (row == null) return PlayerStats.empty;

    return PlayerStats(
      shotsFired: row.shotsFired,
      shotsHit: row.shotsHit,
      swings: row.swings,
      swingsHit: row.swingsHit,
      hitsHead: row.hitsHead,
      hitsTorso: row.hitsTorso,
      hitsArms: row.hitsArms,
      hitsLegs: row.hitsLegs,
      kills: row.kills,
      bloodDealtMl: row.bloodDealtMl,
      bloodLostMl: row.bloodLostMl,
      searches: row.searches,
      blackouts: row.blackouts,
    );
  }

  Future<void> save(int profileId, PlayerStats stats) => _db.writeStats(
    ProfileStatsCompanion.insert(
      profileId: Value(profileId),
      shotsFired: Value(stats.shotsFired),
      shotsHit: Value(stats.shotsHit),
      swings: Value(stats.swings),
      swingsHit: Value(stats.swingsHit),
      hitsHead: Value(stats.hitsHead),
      hitsTorso: Value(stats.hitsTorso),
      hitsArms: Value(stats.hitsArms),
      hitsLegs: Value(stats.hitsLegs),
      kills: Value(stats.kills),
      bloodDealtMl: Value(stats.bloodDealtMl),
      bloodLostMl: Value(stats.bloodLostMl),
      searches: Value(stats.searches),
      blackouts: Value(stats.blackouts),
    ),
  );
}
