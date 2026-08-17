/// Reading and writing where the player lives (§8.2, §11.1).
///
/// ⚠️ These rows hold a home address. They are never sent anywhere, and the
/// whole save is outside Android's automatic backup — `allowBackup="false"`
/// and `res/xml/data_extraction_rules.xml` in the manifest, which §8.2 asks
/// for by name. Nothing in this file may grow a network call.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import 'shelter.dart';

class ShelterStore {
  const ShelterStore(this._db);

  final SaveDatabase _db;

  /// Everything this character has built, with §8.5.2's decay applied.
  ///
  /// Swept on read rather than on a timer, exactly as the ground piles are: a
  /// camp that fell down while the app was closed fell down all the same, and
  /// a timer that fires with the process dead is a timer that does not fire.
  Future<List<Shelter>> load(int profileId, DateTime now) async {
    final rows = await _db.sheltersFor(profileId);
    final kept = <Shelter>[];

    for (final row in rows) {
      final place = _fromRow(row);
      if (place.isLostAt(now)) {
        await _db.removeShelter(row.id);
        continue;
      }

      // §8.4: a module finished while the app was dead is finished. Written
      // back the first time anybody looks, so the row and the game agree.
      final settled = place.settledAt(now);
      if (!identical(settled, place)) {
        await _db.updateShelter(
          row.id,
          SheltersCompanion(
            modules: Value(_wire(settled.modules)),
            building: const Value(null),
            buildingReadyAt: const Value(null),
            buildingLeftSeconds: const Value(null),
          ),
        );
      }
      kept.add(settled);
    }
    return kept;
  }

  /// Starts the work. The place exists from this moment; it simply does not
  /// keep anything out until [Shelter.readyAt] (§8.3).
  Future<int> begin(
    int profileId, {
    required ShelterKind kind,
    required GeoPoint at,
    required DateTime now,
    required Duration buildTime,
  }) => _db.addShelter(
    SheltersCompanion.insert(
      profileId: profileId,
      kind: kind.name,
      latitude: at.latitude,
      longitude: at.longitude,
      startedAt: now,
      buildSeconds: buildTime.inSeconds,
      buildLeftSeconds: Value(buildTime.inSeconds),
      workedAt: Value(now),
      visitedAt: Value(now),
    ),
  );

  /// §2.1a.3, §8.3: writes back what a stretch on the site bought, and when
  /// the crediting last happened. Both, always — the timestamp is what lets a
  /// build survive the process being killed overnight.
  Future<void> saveWork(Shelter place) => _db.updateShelter(
    place.id,
    SheltersCompanion(
      buildLeftSeconds: Value(place.buildLeft?.inSeconds),
      buildingLeftSeconds: Value(place.buildingLeft?.inSeconds),
      workedAt: Value(place.workedAt),
    ),
  );

  /// §8.5.2: the player was here, so the clock on a camp starts again.
  Future<void> visited(int id, DateTime now) =>
      _db.updateShelter(id, SheltersCompanion(visitedAt: Value(now)));

  /// §8.4: one level onto one module.
  Future<void> setModules(int id, Map<ShelterModule, int> modules) =>
      _db.updateShelter(id, SheltersCompanion(modules: Value(_wire(modules))));

  /// §8.4, §18.2: starts a module. The materials are taken by the caller —
  /// this only records what is going up and when it is done.
  Future<void> beginModule(
    int id, {
    required ShelterModule module,
    required int level,
    required DateTime readyAt,
    required Duration work,
  }) => _db.updateShelter(
    id,
    SheltersCompanion(
      building: Value('${module.name}:$level'),
      buildingReadyAt: Value(readyAt),
      buildingLeftSeconds: Value(work.inSeconds),
      workedAt: Value(DateTime.now().toUtc()),
    ),
  );

  /// §8.2: moving house costs the full rebuild, which is the point of asking.
  Future<void> moveTo(
    int id, {
    required GeoPoint at,
    required DateTime now,
    required Duration buildTime,
  }) => _db.updateShelter(
    id,
    SheltersCompanion(
      latitude: Value(at.latitude),
      longitude: Value(at.longitude),
      startedAt: Value(now),
      buildSeconds: Value(buildTime.inSeconds),
      // The whole job again, from nothing: §8.2 is explicit that moving costs
      // the full rebuild, and that is the point of asking before doing it.
      buildLeftSeconds: Value(buildTime.inSeconds),
      workedAt: Value(now),
      visitedAt: Value(now),
    ),
  );

  /// §8.3: gives up on the module going up here. The levels already built
  /// stay; the one in progress and the materials that went into it do not.
  Future<void> cancelModule(int id) => _db.updateShelter(
    id,
    const SheltersCompanion(
      building: Value(null),
      buildingReadyAt: Value(null),
      buildingLeftSeconds: Value(null),
    ),
  );

  Future<void> remove(int id) => _db.removeShelter(id);

  Shelter _fromRow(ShelterRow row) => Shelter(
    id: row.id,
    kind: ShelterKind.values.firstWhere(
      (kind) => kind.name == row.kind,
      orElse: () => ShelterKind.camp,
    ),
    position: GeoPoint(row.latitude, row.longitude),
    startedAt: row.startedAt,
    buildTime: Duration(seconds: row.buildSeconds),
    modules: _modules(row.modules),
    visitedAt: row.visitedAt,
    building: _moduleOf(row.building),
    buildingLevel: _levelOf(row.building),
    buildingReadyAt: row.buildingReadyAt,
    buildLeft: row.buildLeftSeconds == null
        ? null
        : Duration(seconds: row.buildLeftSeconds!),
    buildingLeft: row.buildingLeftSeconds == null
        ? null
        : Duration(seconds: row.buildingLeftSeconds!),
    workedAt: row.workedAt,
  );
}

/// `storage:2,lounge:1`, which is readable in a database browser and survives
/// a module being added later without a migration.
String _wire(Map<ShelterModule, int> modules) => [
  for (final entry in modules.entries)
    if (entry.value > 0) '${entry.key.name}:${entry.value}',
].join(',');

ShelterModule? _moduleOf(String? wire) {
  if (wire == null) return null;

  final name = wire.split(':').first;
  return ShelterModule.values.where((m) => m.name == name).firstOrNull;
}

int _levelOf(String? wire) =>
    wire == null ? 0 : int.tryParse(wire.split(':').last) ?? 0;

Map<ShelterModule, int> _modules(String wire) {
  if (wire.isEmpty) return const {};

  final parsed = <ShelterModule, int>{};
  for (final part in wire.split(',')) {
    final halves = part.split(':');
    if (halves.length != 2) continue;

    final module = ShelterModule.values
        .where((m) => m.name == halves.first)
        .firstOrNull;
    final level = int.tryParse(halves.last);
    if (module == null || level == null || level <= 0) continue;

    parsed[module] = level.clamp(0, ShelterModule.maxLevel);
  }
  return parsed;
}
