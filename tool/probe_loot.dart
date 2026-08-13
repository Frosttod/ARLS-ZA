// What §10 would actually find around a point: which loot tables fire, how
// many places each has, and how far the nearest one is.
//
// Usage: dart run tool/probe_loot.dart [pack.pmtiles] [lat] [lon] [radiusM]
import 'dart:io';

import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/map/pmtiles_archive.dart';
import 'package:arls_za/map/poi_source.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty
      ? r'C:\Users\przem\Downloads\MAPS\packs\poznan.pmtiles'
      : args.first;
  final centre = GeoPoint(
    args.length > 1 ? double.parse(args[1]) : 52.4084,
    args.length > 2 ? double.parse(args[2]) : 16.9342,
  );
  final radius = args.length > 3 ? double.parse(args[3]) : 2000.0;

  final tables = LootTableSet.parse(
    File('assets/data/loot_tables.json').readAsStringSync(),
  );
  if (!tables.isClean) {
    stderr.writeln(tables.problems.join('\n'));
    exit(1);
  }

  final archive = await PmtilesArchive.open(File(path));
  final source = PoiSource(archive);

  final started = DateTime.now();
  final pois = await source.near(centre, radiusM: radius);
  final elapsed = DateTime.now().difference(started);

  print('${pois.length} places within ${radius.round()} m, read in '
      '${elapsed.inMilliseconds} ms');

  final byTable = <String, List<double>>{};
  for (final poi in pois) {
    for (final table in tables.forTags(poi.selectors)) {
      byTable
          .putIfAbsent(table.id, () => [])
          .add(poi.position.distanceTo(centre));
    }
  }

  final rows = byTable.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  print('\ntable                 count   nearest   median');
  for (final row in rows) {
    final distances = row.value..sort();
    final median = distances[distances.length ~/ 2];
    print('${row.key.padRight(20)} ${row.value.length.toString().padLeft(6)}  '
        '${distances.first.round().toString().padLeft(6)} m '
        '${median.round().toString().padLeft(7)} m');
  }

  final matched = byTable.values.fold(0, (sum, list) => sum + list.length);
  print('\n$matched of ${pois.length} places match a table');

  // What the player would actually see: the cap of §10 against the ring the
  // spawner guarantees.
  final near = byTable.values
      .expand((d) => d)
      .where((d) => d <= 600)
      .length;
  print('$near of them are within 600 m');

  await archive.close();
}
