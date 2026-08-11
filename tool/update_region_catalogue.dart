/// Fills `assets/regions.json` in from the packs that were actually built.
///
/// The catalogue ships with placeholder sizes and empty checksums, and a pack
/// with an empty checksum is refused on purpose (§16.6). This tool closes that
/// gap: point it at a directory of `.pmtiles` files and it writes the real byte
/// count and SHA-256 for each region it finds, leaving the rest alone.
///
/// ```
/// dart run tool/update_region_catalogue.dart path/to/packs
/// ```
///
/// Regions with no file in the directory keep their placeholder and stay
/// unbuyable, which is the correct state for a pack nobody has published.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/update_region_catalogue.dart <directory> '
      '[catalogue.json]',
    );
    exitCode = 64;
    return;
  }

  final packDir = Directory(args[0]);
  final cataloguePath = args.length > 1 ? args[1] : 'assets/regions.json';

  if (!packDir.existsSync()) {
    stderr.writeln('no such directory: ${packDir.path}');
    exitCode = 66;
    return;
  }

  final file = File(cataloguePath);
  final catalogue = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final regions = catalogue['regions']! as List<Object?>;

  var updated = 0;
  var missing = 0;

  for (final entry in regions) {
    final region = entry! as Map<String, Object?>;
    final id = region['id']! as String;
    final pack = File('${packDir.path}${Platform.pathSeparator}$id.pmtiles');

    if (!pack.existsSync()) {
      missing++;
      stdout.writeln('  skipped  $id  (no file)');
      continue;
    }

    final bytes = await pack.length();
    final digest = await sha256.bind(pack.openRead()).first;

    region['bytes'] = bytes;
    region['sha256'] = digest.toString();
    updated++;

    final megabytes = (bytes / (1024 * 1024)).toStringAsFixed(1);
    stdout.writeln('  updated  $id  ${megabytes.padLeft(7)} MB  $digest');
  }

  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalogue)}\n',
  );

  stdout
    ..writeln()
    ..writeln('$updated region(s) updated, $missing still unpublished.')
    ..writeln('Wrote $cataloguePath');
}
