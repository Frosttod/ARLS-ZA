// Measures what a real pack actually carries, so the OSM -> OpenMapTiles
// mapping of §10 is written from tiles rather than from memory.
//
// Usage: dart run tool/probe_pack.dart [pack.pmtiles] [lat] [lon]
import 'dart:io';
import 'dart:math';

import 'package:arls_za/map/mvt.dart';
import 'package:arls_za/map/pmtiles_archive.dart';

({int x, int y}) tileOf(double lat, double lon, int z) {
  final n = 1 << z;
  final x = ((lon + 180) / 360 * n).floor();
  final latRad = lat * pi / 180;
  final y = ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();
  return (x: x, y: y);
}

Future<void> main(List<String> args) async {
  final path = args.isEmpty
      ? r'C:\Users\przem\Downloads\MAPS\packs\poznan.pmtiles'
      : args.first;
  final lat = args.length > 1 ? double.parse(args[1]) : 52.4084;
  final lon = args.length > 2 ? double.parse(args[2]) : 16.9342;

  final archive = await PmtilesArchive.open(File(path));
  print(
    'header: z${archive.header.minZoom}-${archive.header.maxZoom} '
    'tiles=${archive.header.tileCount}',
  );

  const z = 14;
  final centre = tileOf(lat, lon, z);

  final subclasses = <String, int>{};
  final classes = <String, int>{};
  final landuse = <String, int>{};
  final buildingProps = <String, int>{};
  var tiles = 0;
  var poi = 0;

  // A 5x5 block of z14 tiles is roughly 12 km across at this latitude — more
  // than the 2 km §10 spawns within, which is the point: it shows what a
  // whole city carries, not what one square happens to.
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = -2; dy <= 2; dy++) {
      final bytes = await archive.tile(z, centre.x + dx, centre.y + dy);
      if (bytes == null) continue;
      tiles++;

      final tile = decodeMvt(bytes, layers: {'poi', 'landuse', 'building'});
      for (final feature in tile.layer('poi')) {
        poi++;
        final subclass = feature.properties['subclass'];
        final klass = feature.properties['class'];
        if (subclass != null) {
          subclasses.update('$subclass', (v) => v + 1, ifAbsent: () => 1);
        }
        if (klass != null) {
          classes.update('$klass', (v) => v + 1, ifAbsent: () => 1);
        }
      }
      for (final feature in tile.layer('landuse')) {
        final klass = feature.properties['class'];
        if (klass != null) {
          landuse.update('$klass', (v) => v + 1, ifAbsent: () => 1);
        }
      }
      for (final feature in tile.layer('building')) {
        for (final key in feature.properties.keys) {
          buildingProps.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  print('read $tiles tiles, $poi POI');
  print('\npoi class:\n  ${_all(classes)}');
  print('\npoi subclass:\n  ${_all(subclasses)}');
  print('\nlanduse class:\n  ${_all(landuse)}');
  print('\nbuilding properties:\n  ${_all(buildingProps)}');

  // The tags §10's loot tables name, checked one by one against what is here.
  const wanted = [
    'pharmacy',
    'supermarket',
    'convenience',
    'doityourself',
    'hardware',
    'sports',
    'outdoor',
    'weapons',
    'hunting',
    'police',
    'library',
    'books',
    'school',
    'college',
    'university',
    'hospital',
    'clinic',
    'doctors',
    'car_repair',
    'fuel',
    'shelter',
    'picnic_site',
    'hunting_stand',
    'drinking_water',
    'water_tower',
    'recycling',
    'waste_disposal',
    'parking',
    'garden_centre',
    'chemist',
    'department_store',
    'mall',
    'greengrocer',
    'butcher',
    'bakery',
    'veterinary',
    'pet',
    'wholesale',
  ];
  print('\nwhat §10 asks for:');
  for (final tag in wanted) {
    final count = subclasses[tag] ?? 0;
    print('  ${count == 0 ? "MISSING" : count.toString().padLeft(6)}  $tag');
  }

  await archive.close();
}

String _all(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => '${e.key}=${e.value}').join(', ');
}
