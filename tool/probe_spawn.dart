// Runs the whole loot layer against a real pack: reads the places, decides
// whether §10.1's backup mode applies, invents what it has to, and reports
// what a player standing there would actually see.
//
// Usage: dart run tool/probe_spawn.dart [pack.pmtiles] [lat] [lon]
import 'dart:io';

import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/loot_world.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/map/map_source.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty
      ? r'C:\Users\przem\Downloads\MAPS\packs\poznan.pmtiles'
      : args.first;
  final centre = GeoPoint(
    args.length > 1 ? double.parse(args[1]) : 52.4084,
    args.length > 2 ? double.parse(args[2]) : 16.9342,
  );

  final tables = LootTableSet.parse(
    File('assets/data/loot_tables.json').readAsStringSync(),
  );
  if (!tables.isClean) {
    stderr.writeln(tables.problems.join('\n'));
    exit(1);
  }

  final world = LootWorld(tables: tables);
  await world.useSource(InstalledPack(path));
  if (!world.isReady) {
    stderr.writeln('no pack at $path');
    exit(1);
  }

  final started = DateTime.now();
  final plan = await world.plan(
    centre: centre,
    existing: const [],
    now: DateTime.now().toUtc(),
    seed: 42,
  );
  final elapsed = DateTime.now().difference(started);

  if (plan == null) {
    stderr.writeln('no plan');
    exit(1);
  }

  print('${plan.boxes.length} boxes, planned in ${elapsed.inMilliseconds} ms');

  final byTable = <String, int>{};
  for (final box in plan.boxes) {
    byTable.update(box.tableId, (v) => v + 1, ifAbsent: () => 1);
  }

  final distances =
      plan.boxes.map((box) => box.position.distanceTo(centre)).toList()..sort();

  print('\ntable                 count');
  for (final row in byTable.entries) {
    print('${row.key.padRight(20)} ${row.value.toString().padLeft(6)}');
  }

  if (distances.isEmpty) return;
  print(
    '\nnearest ${distances.first.round()} m, '
    'median ${distances[distances.length ~/ 2].round()} m, '
    'furthest ${distances.last.round()} m',
  );
  print('${distances.where((d) => d <= 600).length} within 600 m');

  await world.dispose();
}
