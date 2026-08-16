/// Every item the game knows about, from however many files (§4.1).
///
/// The catalogue is split by kind — `weapons.json`, `food.json`, and so on —
/// because a single file of ninety entries is a file nobody edits confidently.
/// Nothing downstream cares: loot tables and inventories look items up by id,
/// and an id is unique across the whole catalogue, not per file.
///
/// **Content packs are the reason this is a merge and not a constant.** A pack
/// is a file in the same format, read from disk after the bundled ones, so a
/// new item ships without a new build — the whole point of §4.1's data-driven
/// schema. It is parsed exactly as strictly as the bundled files were.
///
/// **A pack may replace a bundled item.** That is how a balance fix reaches
/// players who have not updated, so it is allowed and recorded rather than
/// silently permitted: [ItemCatalogue.replacements] names every id a later
/// source overwrote, and a build that did not intend any can assert it is
/// empty.
library;

import 'item.dart';
import 'item_parser.dart';

/// The bundled files, split by kind because a ninety-entry file is one nobody
/// edits with confidence. Listed explicitly rather than discovered: an asset
/// that silently stops being shipped should break the build, not the game.
///
/// Lives here rather than beside the asset loader so a plain Dart test can read
/// the same list off disk without dragging Flutter in.
const List<String> kBundledItemAssets = [
  'assets/data/weapons.json',
  'assets/data/ammo.json',
  'assets/data/melee.json',
  'assets/data/armor.json',
  'assets/data/backpacks.json',
  'assets/data/food.json',
  'assets/data/medical.json',
  'assets/data/literature.json',
  'assets/data/tools.json',
  'assets/data/attachments.json',
  'assets/data/crafting.json',
];

/// Content packs are `*.items.json` so a stray file in the directory is not
/// mistaken for one.
const String kItemPackSuffix = '.items.json';

/// One file to read, named so problems can be traced back to it.
class ItemSource {
  const ItemSource(this.origin, this.contents);

  /// Where it came from — an asset path or a pack file name. Appears in every
  /// problem this source produces.
  final String origin;

  final String contents;
}

class ItemCatalogue {
  ItemCatalogue._(this._byId, this.problems, this.replacements);

  final Map<String, ItemDefinition> _byId;

  /// Everything wrong with everything read, in the order it was found. Never
  /// thrown: one pass should fix a file, not one fault per build (§4.1).
  final List<ItemProblem> problems;

  /// Ids a later source overwrote, mapped to the origin that did it.
  final Map<String, String> replacements;

  /// Reads [sources] in order. Later sources win on a clash.
  factory ItemCatalogue.load(Iterable<ItemSource> sources) {
    final byId = <String, ItemDefinition>{};
    final origins = <String, String>{};
    final problems = <ItemProblem>[];
    final replacements = <String, String>{};

    for (final source in sources) {
      final result = parseItems(source.contents, origin: source.origin);
      problems.addAll(result.problems);

      for (final item in result.items) {
        final previous = origins[item.id];
        if (previous != null && previous != source.origin) {
          replacements[item.id] = source.origin;
        }
        byId[item.id] = item;
        origins[item.id] = source.origin;
      }
    }

    return ItemCatalogue._(byId, problems, replacements);
  }

  /// True when nothing was rejected. What a build asserts before shipping.
  bool get isClean => problems.isEmpty;

  int get length => _byId.length;

  Iterable<ItemDefinition> get all => _byId.values;

  ItemDefinition? operator [](String id) => _byId[id];

  Iterable<ItemDefinition> ofKind(ItemKind kind) =>
      _byId.values.where((item) => item.kind == kind);

  /// Everything a place of §10.3 may produce. A tag matches an item that
  /// carries it; `any` on an item means it turns up anywhere.
  Iterable<ItemDefinition> taggedFor(String lootTag) => _byId.values.where(
    (item) => item.lootTags.contains(lootTag) || item.lootTags.contains('any'),
  );
}
