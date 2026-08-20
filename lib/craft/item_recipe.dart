/// Making things, and taking them apart again (§18.4, §18.6).
///
/// Two halves of one economy. §18.4 turns materials into the four or five
/// things somebody can actually make before they find a firearm — a stake, a
/// spear, a dressing, a pack. §18.6 turns things back into materials at forty
/// per cent, which is deliberately never worth doing for the materials: it is
/// worth doing to stop carrying something.
///
/// ⚠️ **Shelter modules are not here.** They live in `shelter/recipes.dart`
/// because a module is a level of a building rather than a thing in a pack:
/// it has no output item, it cannot be dismantled into anything, and it is
/// built in place. Sharing one type between them would mean a nullable output
/// on every recipe in the game to serve thirteen rows.
library;

import 'dart:convert';

import '../items/item.dart';
import '../items/item_catalogue.dart';

/// Where the recipes ship from.
const String kRecipesAsset = 'assets/data/recipes.json';

/// §18.6: what comes back out of something taken apart.
///
/// Forty per cent, rounded down, and §18.6 is explicit about why: recycling
/// must never be a way to *get* materials, only a way to stop carrying
/// something without losing everything. Exploration stays the way you get
/// wood and metal.
const double kSalvageReturn = 0.40;

/// §18.6: Engineering at 100% raises it this far, and no further.
const double kSalvageReturnSkilled = 0.55;

/// §18.6: a workshop at level 2 or better adds this many points.
const double kSalvageWorkshopBonus = 0.10;

/// §18.6: how long taking something apart takes, at the ends of the range.
const (Duration, Duration) kSalvageTime = (
  Duration(minutes: 3),
  Duration(minutes: 15),
);

/// One thing that can be made (§18.4).
class ItemRecipe {
  const ItemRecipe({
    required this.id,
    required this.output,
    required this.count,
    required this.materials,
    required this.work,
    this.workshopLevel = 0,
    this.toolsAnyOf = const [],
  });

  final String id;

  /// The item id this produces.
  final String output;

  /// How many of it one run makes.
  final int count;

  /// Item id to count, straight off §18.4's row.
  final Map<String, int> materials;

  /// §18.3's base time, before Engineering, tools and the workshop.
  final Duration work;

  /// The workshop level the shelter must have.
  ///
  /// Nought means no workshop module, not "anywhere": §18.4 frees the medical
  /// rows from the *workshop*, and §2.1a keeps every kind of making a shelter
  /// activity — something that ticks with the app closed because the character
  /// is standing where they keep their things. So a dressing can be made
  /// before a workshop exists, and still not on a pavement.
  final int workshopLevel;

  /// Any one of these will do. Empty means bare hands are enough.
  ///
  /// ⚠️ A list rather than a single id because §18.4 says "knife **or**
  /// multitool" and means it. A single id would quietly make one of the two
  /// the only answer, which is the shape the shelter's own tool rule had wrong
  /// for months.
  final List<String> toolsAnyOf;
}

/// The recipes as shipped, plus whatever went wrong reading them.
class RecipeBook {
  const RecipeBook(this.recipes, this.problems);

  static const RecipeBook empty = RecipeBook([], []);

  final List<ItemRecipe> recipes;

  /// Rows that could not be read. Reported rather than thrown: a broken
  /// recipe should cost that recipe, not the app.
  final List<String> problems;

  /// The recipe that makes [itemId], or null for anything nobody can make.
  ItemRecipe? making(String itemId) {
    for (final recipe in recipes) {
      if (recipe.output == itemId) return recipe;
    }
    return null;
  }

  static RecipeBook parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return RecipeBook(const [], ['recipes.json: $error']);
    }
    if (decoded is! Map<String, Object?>) {
      return const RecipeBook([], ['recipes.json: not an object']);
    }

    final rows = decoded['recipes'];
    if (rows is! List) {
      return const RecipeBook([], ['recipes.json: no recipes list']);
    }

    final recipes = <ItemRecipe>[];
    final problems = <String>[];

    for (final row in rows) {
      if (row is! Map<String, Object?>) {
        problems.add('a recipe row is not an object');
        continue;
      }

      final id = row['id'];
      final output = row['output'];
      if (id is! String || output is! String) {
        problems.add('a recipe row has no id or no output');
        continue;
      }

      final materials = <String, int>{};
      final raw = row['materials'];
      if (raw is Map<String, Object?>) {
        for (final entry in raw.entries) {
          final count = entry.value;
          if (count is num) materials[entry.key] = count.toInt();
        }
      }

      recipes.add(
        ItemRecipe(
          id: id,
          output: output,
          count: (row['count'] as num?)?.toInt() ?? 1,
          materials: materials,
          work: Duration(
            seconds: (((row['work_minutes'] as num?)?.toDouble() ?? 0) * 60)
                .round(),
          ),
          workshopLevel: (row['workshop_level'] as num?)?.toInt() ?? 0,
          toolsAnyOf: [
            for (final tool in (row['tools_any_of'] as List?) ?? const [])
              if (tool is String) tool,
          ],
        ),
      );
    }

    return RecipeBook(recipes, problems);
  }
}

/// §18.3: how long one run actually takes.
///
/// The same formula the shelter uses, and deliberately the same shape: base
/// time, less Engineering, less whatever the workshop is worth. Tools are a
/// gate here rather than a discount — §18.4 lists them as requirements, not as
/// something that makes the job quicker.
Duration craftWork(
  ItemRecipe recipe, {
  double engineering = 0,
  int workshopLevel = 0,
}) {
  final skill = 1 - 0.30 * engineering.clamp(0.0, 1.0);
  final workshop = switch (workshopLevel) {
    <= 0 => 1.0,
    1 => 0.90,
    2 => 0.80,
    _ => 0.70,
  };

  return Duration(
    milliseconds: (recipe.work.inMilliseconds * skill * workshop).round(),
  );
}

/// §18.6: what one item is made of, in material units.
///
/// The recipe when there is one — that is the material value, exactly — and
/// otherwise the `salvage` map in the catalogue, which is the item's mass split
/// by what it is actually made of and divided by the unit masses in
/// `crafting.json`. A 3.3 kg rifle comes to 2.2 units of metal, half a unit of
/// components and a third of a unit of plastic, and those fractions matter:
/// rounding them away one at a time is what made the whole system return
/// nothing.
Map<String, double> materialContent(ItemDefinition item, RecipeBook book) {
  final recipe = book.making(item.id);
  if (recipe != null) {
    return {
      for (final entry in recipe.materials.entries)
        entry.key: entry.value.toDouble(),
    };
  }

  final raw = item.props['salvage'];
  if (raw is! Map) return const {};

  final content = <String, double>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is num) content[key] = value.toDouble();
  }
  return content;
}

/// §18.6: what [item] actually gives back when taken apart.
///
/// ⚠️ **One budget, shared out — not forty per cent of each material.**
///
/// §18.6 says forty per cent rounded down, and taken literally per material it
/// returns nothing for anything a person carries: forty per cent of a rifle is
/// 0.88 units of metal, which floors to nought, and so does an axe, a spear
/// and a vest. The section's own summary says recycling should never be worth
/// it *for the materials* — not that it should be worth nothing at all.
///
/// So the share is taken against the whole item, rounded once, and handed out
/// by largest remainder. A rifle comes to one piece of metal. A pistol comes
/// to nothing, and should: you do not get scrap out of something that small.
///
/// Condition scales it, exactly as §18.6 insists — without that the cheapest
/// metal in the game would be ruined weapons collected to be broken, and
/// scavenging would stop being about what you can use.
Map<String, int> salvageOf(
  ItemDefinition item,
  RecipeBook book, {
  double condition = 100,
  double share = kSalvageReturn,
}) {
  final content = materialContent(item, book);
  if (content.isEmpty) return const {};

  final wear = (condition / 100).clamp(0.0, 1.0);

  var total = 0.0;
  for (final units in content.values) {
    total += units;
  }

  final budget = (total * share * wear).round();
  if (budget <= 0) return const {};

  // Largest remainder: everything gets its proportional share, and the units
  // left over after flooring go to whatever was closest to earning one.
  final exact = <String, double>{
    for (final entry in content.entries)
      entry.key: budget * entry.value / total,
  };

  final out = <String, int>{};
  var given = 0;
  for (final entry in exact.entries) {
    final whole = entry.value.floor();
    if (whole > 0) out[entry.key] = whole;
    given += whole;
  }

  final queue = exact.entries.toList()
    ..sort((a, b) {
      final remainder = (b.value - b.value.floor()).compareTo(
        a.value - a.value.floor(),
      );
      // Ties by name, so the same item always comes apart the same way.
      return remainder != 0 ? remainder : a.key.compareTo(b.key);
    });

  for (var i = 0; given < budget && i < queue.length; i++) {
    out[queue[i].key] = (out[queue[i].key] ?? 0) + 1;
    given++;
  }

  return out;
}

/// §18.6: the share that actually comes back, for this player.
double salvageShare({double engineering = 0, int workshopLevel = 0}) {
  final skilled =
      kSalvageReturn +
      (kSalvageReturnSkilled - kSalvageReturn) * engineering.clamp(0.0, 1.0);

  return workshopLevel >= 2 ? skilled + kSalvageWorkshopBonus : skilled;
}

/// §18.6: three to fifteen minutes, by how much there is to undo.
///
/// Measured against the item's own material content rather than its recipe,
/// because most of what gets taken apart was never made by anybody — a rifle
/// has no recipe and is still a quarter of an hour of work. Ten units is the
/// top of the range: the biggest row in §18.4 and about a full pack.
Duration salvageTime(Map<String, double> content) {
  final (fastest, slowest) = kSalvageTime;

  var units = 0.0;
  for (final count in content.values) {
    units += count;
  }

  final share = (units / 10).clamp(0.0, 1.0);
  final span = slowest.inSeconds - fastest.inSeconds;

  return Duration(seconds: fastest.inSeconds + (span * share).round());
}

/// §18.4: whether this can be attempted with what is at hand.
///
/// ⚠️ Named apart from the shelter's own `toolsAllow`, which asks the same
/// question about a module and takes different arguments. Two functions of one
/// name in two libraries is an ambiguous import the day somebody needs both,
/// and this file and that one are needed together on the crafting screen.
bool craftToolsAllow(ItemRecipe recipe, Iterable<String> carriedIds) {
  if (recipe.toolsAnyOf.isEmpty) return true;

  for (final id in carriedIds) {
    if (recipe.toolsAnyOf.contains(id)) return true;
  }
  return false;
}

/// §18.6: taking anything apart needs a multitool, whatever it is made of.
///
/// §18.6 says "a tool appropriate to the material — multitool, axe, wrench".
/// The multitool is the one that covers every material, and until there is a
/// reason to make somebody carry three, one requirement is one rule to learn.
const String kSalvageToolId = 'tool_multitool';

/// Whether [items] contains anything that can take things apart.
bool canSalvageWith(Iterable<String> carriedIds) =>
    carriedIds.contains(kSalvageToolId);

/// Every recipe whose output the catalogue actually defines.
///
/// A recipe naming an item nothing defines is dropped and reported, exactly as
/// an inventory row naming a missing item is: a content pack that was removed
/// should cost its own recipes and nothing else.
RecipeBook checkedAgainst(RecipeBook book, ItemCatalogue catalogue) {
  final good = <ItemRecipe>[];
  final problems = [...book.problems];

  for (final recipe in book.recipes) {
    if (catalogue[recipe.output] == null) {
      problems.add('${recipe.id}: no such item as ${recipe.output}');
      continue;
    }

    var ok = true;
    for (final id in recipe.materials.keys) {
      if (catalogue[id] == null) {
        problems.add('${recipe.id}: no such material as $id');
        ok = false;
      }
    }
    for (final id in recipe.toolsAnyOf) {
      if (catalogue[id] == null) {
        problems.add('${recipe.id}: no such tool as $id');
        ok = false;
      }
    }

    if (ok) good.add(recipe);
  }

  return RecipeBook(good, problems);
}
