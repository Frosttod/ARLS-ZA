/// What a module costs, and what it costs to carry (§18.2, §18.3).
///
/// The table is §18.2's, unchanged. The masses behind it are not chosen here
/// either — they are the five unit masses in `crafting.json`, solved so that
/// all thirteen rows reproduce the document's own kilograms. Camp comes to
/// 31.8 kg, Workshop L3 to 121.4 kg, and the full four-module build to the 731
/// kg §18.2 calls "weeks, not a weekend".
///
/// That figure is the point of the whole system. Thirty round trips with a
/// full pack is what makes the Lounge a real choice against the Storage
/// module, and it is why §17.6's empty winter has something in it.
library;

import 'shelter.dart';

/// What one level of one module takes.
class ShelterRecipe {
  const ShelterRecipe({
    required this.module,
    required this.level,
    required this.materials,
    required this.work,
  });

  final ShelterModule module;
  final int level;

  /// Item id to count. Read straight off §18.2's row.
  final Map<String, int> materials;

  /// §18.2's base time, before tools, Engineering and the workshop's own
  /// discount (§18.3).
  final Duration work;
}

/// §18.2, row by row.
const List<ShelterRecipe> kShelterRecipes = [
  // Storage — wood and metal: shelving, crates, fittings (§18.2.1).
  ShelterRecipe(
    module: ShelterModule.storage,
    level: 1,
    materials: {'mat_wood': 20, 'mat_metal': 6},
    work: Duration(hours: 2),
  ),
  ShelterRecipe(
    module: ShelterModule.storage,
    level: 2,
    materials: {'mat_wood': 28, 'mat_metal': 12, 'mat_plastic': 6},
    work: Duration(hours: 3, minutes: 30),
  ),
  ShelterRecipe(
    module: ShelterModule.storage,
    level: 3,
    materials: {'mat_wood': 36, 'mat_metal': 18, 'mat_plastic': 10},
    work: Duration(hours: 5),
  ),

  // Workshop — metal and components: bench, vice, tool mounts.
  ShelterRecipe(
    module: ShelterModule.workshop,
    level: 1,
    materials: {'mat_wood': 15, 'mat_metal': 20, 'mat_component': 2},
    work: Duration(hours: 4),
  ),
  ShelterRecipe(
    module: ShelterModule.workshop,
    level: 2,
    materials: {
      'mat_wood': 18,
      'mat_metal': 30,
      'mat_plastic': 10,
      'mat_component': 5,
    },
    work: Duration(hours: 6),
  ),
  ShelterRecipe(
    module: ShelterModule.workshop,
    level: 3,
    materials: {
      'mat_wood': 22,
      'mat_metal': 42,
      'mat_plastic': 16,
      'mat_component': 10,
    },
    work: Duration(hours: 9),
  ),

  // Lounge — wood and fabric: bedding, insulation, curtains.
  ShelterRecipe(
    module: ShelterModule.lounge,
    level: 1,
    materials: {'mat_wood': 12, 'mat_fabric': 15},
    work: Duration(hours: 1, minutes: 30),
  ),
  ShelterRecipe(
    module: ShelterModule.lounge,
    level: 2,
    materials: {'mat_wood': 16, 'mat_plastic': 6, 'mat_fabric': 22},
    work: Duration(hours: 2, minutes: 30),
  ),
  ShelterRecipe(
    module: ShelterModule.lounge,
    level: 3,
    materials: {'mat_wood': 20, 'mat_plastic': 10, 'mat_fabric': 30},
    work: Duration(hours: 4),
  ),

  // Laboratory — plastic and components: containers, sealed vessels, apparatus.
  ShelterRecipe(
    module: ShelterModule.laboratory,
    level: 1,
    materials: {'mat_metal': 10, 'mat_plastic': 14, 'mat_component': 4},
    work: Duration(hours: 3),
  ),
  ShelterRecipe(
    module: ShelterModule.laboratory,
    level: 2,
    materials: {'mat_metal': 14, 'mat_plastic': 20, 'mat_component': 8},
    work: Duration(hours: 5),
  ),
  ShelterRecipe(
    module: ShelterModule.laboratory,
    level: 3,
    materials: {'mat_metal': 18, 'mat_plastic': 28, 'mat_component': 14},
    work: Duration(hours: 8),
  ),
];

/// §18.2: a camp is twelve planks, four bits of metal and some cloth.
const Map<String, int> kCampMaterials = {
  'mat_wood': 12,
  'mat_metal': 4,
  'mat_fabric': 6,
};

/// The next level of [module], or null when it is already at three.
ShelterRecipe? nextLevelOf(ShelterModule module, {required int have}) {
  if (have >= ShelterModule.maxLevel) return null;

  for (final recipe in kShelterRecipes) {
    if (recipe.module == module && recipe.level == have + 1) return recipe;
  }
  return null;
}

/// What is still missing from [carried] to build this, or empty when nothing
/// is (§18.2).
Map<String, int> missingFor(
  Map<String, int> materials,
  Map<String, int> carried,
) => {
  for (final entry in materials.entries)
    if ((carried[entry.key] ?? 0) < entry.value)
      entry.key: entry.value - (carried[entry.key] ?? 0),
};

/// §18.3: how long the work actually takes, with what is to hand.
///
/// A hammer is the requirement for every module; a multitool does it in a bit
/// over half again the time, and without either there is no alternative at
/// all — which is the one place §18.3 refuses rather than taxes.
Duration moduleWork(
  ShelterRecipe recipe, {
  bool hasHammer = false,
  bool hasMultitool = false,
  double engineering = 0,
  int workshopLevel = 0,
}) {
  final tools = hasHammer
      ? 1.0
      : hasMultitool
      ? 1.6
      : double.infinity;

  final skill = 1 - kEngineeringBuildDiscount * engineering.clamp(0.0, 1.0);
  final workshop = switch (workshopLevel) {
    0 => 1.0,
    1 => 0.90,
    2 => 0.80,
    _ => 0.70,
  };

  if (tools.isInfinite) return Duration.zero;

  return Duration(
    milliseconds: (recipe.work.inMilliseconds * tools * skill * workshop)
        .round(),
  );
}

/// §18.3: whether this can be attempted at all with what is carried.
///
/// Workshop level 2 and 3 need a multitool as well as a hammer — there is no
/// alternative listed, and inventing one would make the tool optional.
bool toolsAllow(
  ShelterRecipe recipe, {
  required bool hasHammer,
  required bool hasMultitool,
}) {
  if (!hasHammer && !hasMultitool) return false;
  if (recipe.module == ShelterModule.workshop && recipe.level >= 2) {
    return hasHammer && hasMultitool;
  }
  return true;
}
