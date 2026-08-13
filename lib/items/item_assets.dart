/// Where the catalogue comes from at runtime.
///
/// Two places, in this order: the files shipped inside the app, then any
/// content pack the player has downloaded into the pack directory. Order is
/// the whole policy — a pack read last can add items and, deliberately, fix a
/// bundled one (§4.1, [ItemCatalogue]).
library;

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'item_catalogue.dart';
import 'item_names.dart';

/// Reads the bundled name table. Packs carry their names inline, so this is
/// only the shipped one.
Future<ItemNames> loadItemNames() async =>
    ItemNames.parse(await rootBundle.loadString(kItemNamesAsset));

/// Reads the bundled catalogue, and any content pack found in [packDirectory].
///
/// Packs are read in name order so two devices with the same files end up with
/// the same catalogue — otherwise which pack wins would depend on the
/// filesystem, and a balance change would apply on one phone and not another.
Future<ItemCatalogue> loadItemCatalogue({Directory? packDirectory}) async {
  final sources = <ItemSource>[];

  for (final asset in kBundledItemAssets) {
    sources.add(ItemSource(asset, await rootBundle.loadString(asset)));
  }

  final dir = packDirectory;
  if (dir != null && dir.existsSync()) {
    final packs =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith(kItemPackSuffix))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final pack in packs) {
      try {
        sources.add(ItemSource(pack.uri.pathSegments.last, pack.readAsStringSync()));
      } on FileSystemException {
        // An unreadable pack is not a reason to start without a catalogue. It
        // is reported by its absence from the list the settings screen shows.
        continue;
      }
    }
  }

  return ItemCatalogue.load(sources);
}
