/// The one shape every item shares (design doc §4.1).
///
/// §4.1 is blunt about why there is a single schema: give each kind its own and
/// each kind gets its own incompatible code. A rifle, a tin of beans and a
/// paperback all weigh something, take up room, and can be carried — the
/// inventory of §18.1a only needs those, and everything a rifle knows that a
/// tin does not lives in [props].
///
/// **Two limits, not one.** §4.1 adds `volume_l` for a reason worth repeating:
/// with mass alone a player fits thirty kilograms of down jackets in a pocket.
///
/// **Names come from a key when there is one, and from the file when there is
/// not.** The bundled catalogue uses `name_key` and goes through the ordinary
/// translation pipeline (§1.1). A downloaded content pack cannot — a new key
/// needs a new build, and the point of a content pack is not needing one — so
/// it may carry the names inline instead. A key always wins where both exist.
library;

/// What an item fundamentally is. The value decides how [ItemDefinition.props]
/// is read (§4.2–§4.7).
enum ItemKind {
  firearm,
  melee,
  armor,
  /// §4.5. Its own kind rather than a flavour of [armor]: it is the only thing
  /// that changes the two carry limits, and reading that off a coat would be a
  /// mistake waiting to happen.
  backpack,
  food,
  medical,
  literature,
  tool,
  crafting,

  /// Ammunition. Its own kind rather than a material because §10.3.3 builds an
  /// entire economy on it, and because a player scanning a pack needs to see
  /// rounds as rounds rather than as scrap.
  ammo,

  material,
  misc;

  static ItemKind fromWire(String value) => values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => ItemKind.misc,
  );
}

/// How often the loot tables of §10.3 are allowed to produce it.
enum Rarity {
  common,
  uncommon,
  rare,
  veryRare;

  static const Map<String, Rarity> _wire = {
    'common': Rarity.common,
    'uncommon': Rarity.uncommon,
    'rare': Rarity.rare,
    'very_rare': Rarity.veryRare,
  };

  static Rarity? fromWire(String value) => _wire[value];

  String get wire =>
      _wire.entries.firstWhere((entry) => entry.value == this).key;
}

/// A name that survives both ways of writing it.
class ItemName {
  const ItemName({this.key, this.byLanguage = const {}});

  /// A localisation key, for anything shipped with the app (§1.1).
  final String? key;

  /// Names written straight into the file, keyed by language code. The only
  /// way a content pack can name something the app has never heard of.
  final Map<String, String> byLanguage;

  bool get isEmpty => key == null && byLanguage.isEmpty;

  /// The name to show, given the language in use and a lookup for keys.
  ///
  /// The key wins where both exist: a translated string has been through
  /// review, and an inline one has not.
  String resolve({
    required String language,
    String? Function(String key)? lookup,
  }) {
    final k = key;
    if (k != null) {
      final translated = lookup?.call(k);
      if (translated != null) return translated;
    }
    return byLanguage[language] ??
        byLanguage['en'] ??
        (byLanguage.isNotEmpty ? byLanguage.values.first : k ?? '');
  }
}

/// One entry in the catalogue.
class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.kind,
    required this.name,
    required this.weightKg,
    required this.volumeL,
    required this.rarity,
    this.stackable = false,
    this.condition,
    this.conditionDecayPerUse,
    this.lootTags = const [],
    this.props = const {},
  });

  /// Stable and unique. Referenced by loot tables, recipes and save rows, so it
  /// outlives any rename of the thing it describes.
  final String id;

  final ItemKind kind;
  final ItemName name;

  final double weightKg;

  /// Litres. The second limit of §4.1, without which a pocket holds a wardrobe.
  final double volumeL;

  final Rarity rarity;

  /// Whether several occupy one inventory slot. Never true for anything that
  /// carries per-instance state — a book has its own reading progress (§4.6.3)
  /// and two of them are not interchangeable.
  final bool stackable;

  /// Starting condition, 0–100, or null for something that does not wear out
  /// (§4.1). Food spoils by its own rules and does not use this.
  final double? condition;

  final double? conditionDecayPerUse;

  /// Which places of §10.3 may produce it.
  final List<String> lootTags;

  /// Everything specific to [kind]: calibre and muzzle energy for a firearm,
  /// pages for a book, calories for food. Deliberately untyped here so a new
  /// kind does not require a schema migration of everything else.
  final Map<String, Object?> props;

  /// True when this item cannot be stacked because it carries its own state.
  bool get hasInstanceState => kind == ItemKind.literature || condition != null;
}

/// Why a definition was rejected.
///
/// Collected rather than thrown one at a time: a data file is fixed in one pass
/// by someone reading a list, not by re-running a build to find the next fault.
class ItemProblem {
  const ItemProblem(this.itemId, this.message);

  final String itemId;
  final String message;

  @override
  String toString() => '$itemId: $message';
}
