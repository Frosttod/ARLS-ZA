/// Reading and writing §6.5's three slots.
///
/// ⚠️ **Three rows, always.** A slot is a place in the world's difficulty
/// curve, not a hotspot — it exists whether or not there is anything standing
/// in it, and an empty one is resting rather than absent (§6.5.4). Loading
/// therefore returns what is on disk unchanged and leaves the *filling* of
/// empty slots to whoever knows where the shelter is, which this does not.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import 'hotspot.dart';

class HotspotStore {
  const HotspotStore(this._db);

  final SaveDatabase _db;

  /// What the three slots hold, by slot number.
  ///
  /// Sorted, because the slot number is the identity a save round-trips on and
  /// a list that came back in a different order every boot would make the
  /// first hotspot on the map a different one each time.
  Future<Map<int, Hotspot>> load(int profileId) async {
    final rows = await _db.hotspotsFor(profileId);

    return {
      for (final row in rows..sort((a, b) => a.slot.compareTo(b.slot)))
        row.slot: Hotspot(
          id: '${row.profileId}.${row.slot}',
          seed: row.seed,
          centre: GeoPoint(row.latitude, row.longitude),
          level: row.level,
          integrity: row.integrity,
          bornAt: row.bornAt,
          nextLevelAt: row.nextLevelAt,
          agitatedUntil: row.agitatedUntil,
          restingUntil: row.restingUntil,
        ),
    };
  }

  /// Writes one slot.
  ///
  /// ⚠️ Outright rather than as a delta. §6.5.3's promotions are settled on
  /// *read* — a hotspot that grew twice while the app was shut arrives already
  /// grown — so the row is only ever a photograph of what the model decided,
  /// never a thing the database does arithmetic on.
  Future<void> save(int profileId, int slot, Hotspot spot) => _db.writeHotspot(
    HotspotRowsCompanion.insert(
      profileId: profileId,
      slot: slot,
      seed: spot.seed,
      latitude: spot.centre.latitude,
      longitude: spot.centre.longitude,
      level: spot.level,
      integrity: spot.integrity,
      bornAt: spot.bornAt,
      nextLevelAt: spot.nextLevelAt,
      agitatedUntil: Value(spot.agitatedUntil),
      restingUntil: Value(spot.restingUntil),
    ),
  );
}
