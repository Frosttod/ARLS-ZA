/// Builds the map layer out of platform pieces (§3.1, §16.6).
///
/// The only Flutter-dependent file in `lib/map/`, kept apart so everything else
/// there stays loadable from `dart test` and from an isolate. It knows three
/// things nothing else should: where the bundled catalogue lives, where packs
/// go on disk, and which HTTP client fetches them.
library;

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'http_pack_downloader.dart';
import 'pack_manager.dart';
import 'pack_store.dart';
import 'region_pack.dart';

/// Where the catalogue is bundled. Also read by a test, which is why it is a
/// constant rather than a string typed twice.
const String kRegionCataloguePath = 'assets/regions.json';

/// Packs live beside the save rather than in a cache directory: Android empties
/// caches without asking, and a 235 MB download that vanishes overnight is a
/// worse experience than one that never fits (§16.6).
Future<Directory> resolveMapDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  final maps = Directory('${documents.path}${Platform.pathSeparator}maps');
  if (!maps.existsSync()) await maps.create(recursive: true);
  return maps;
}

Future<PackManager> bootMapPacks() async {
  final catalogue = RegionCatalogue.parse(
    await rootBundle.loadString(kRegionCataloguePath),
  );

  return PackManager(
    catalogue: catalogue,
    store: PackStore(
      directory: await resolveMapDirectory(),
      downloader: HttpPackDownloader(),
    ),
  );
}
