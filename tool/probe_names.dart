// What the map calls a place (§19.1.1), read from a real pack.
//
// Usage: dart run tool/probe_names.dart [pack.pmtiles] [lat] [lon]

import 'package:arls_za/loot/ground_reader.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty
      ? r'C:\Users\przem\Downloads\MAPS\packs\poznan.pmtiles'
      : args.first;

  const spots = [
    (52.4084, 16.9342, 'Stary Rynek'),
    (52.4650, 16.9130, 'Piatkowo'),
    (52.3350, 16.9500, 'poludniowy skraj'),
    (52.4010, 16.8800, 'Grunwald'),
  ];

  for (final spot in spots) {
    final lat = args.length > 1 ? double.parse(args[1]) : spot.$1;
    final lon = args.length > 2 ? double.parse(args[2]) : spot.$2;

    final ground = await readGround(
      packPath: path,
      latitude: lat,
      longitude: lon,
      radiusM: 200,
    );
    final names = ground.names;

    print(
      '${spot.$3.padRight(18)} '
      'street=${names.street ?? "-"}  '
      'district=${names.district ?? "-"}  '
      'city=${names.city ?? "-"}',
    );

    if (args.length > 1) break;
  }
}
