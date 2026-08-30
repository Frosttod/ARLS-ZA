/// One thing on the bench, against the clock (§18.4, §18.6, §2.1a.3).
///
/// Making and unmaking are the same shape: something leaves the pack or the
/// shelf, a number of minutes pass, and something else arrives. §2.1a.3 makes
/// both shelter activities — they tick with the app closed, because a
/// forty-five minute pack is not something anybody sits and watches and
/// neither is a quarter of an hour with a multitool.
///
/// ⚠️ **The cost is paid when the job starts, not when it finishes.** Materials
/// leave the pack at the first tap and the item being dismantled goes with
/// them. Charging at the end would let a player start a spear, spend the wood
/// on a splint, and collect both — and dismantling a rifle would leave it
/// loaded and shootable for the quarter of an hour it took to take apart.
library;

import '../items/item_catalogue.dart';
import 'item_recipe.dart';
import 'salvage_batch.dart';

/// What is on the bench.
class CraftJob {
  const CraftJob({
    required this.startedAt,
    required this.readyAt,
    this.recipeId,
    this.salvageItemId,
    this.salvageCondition,
    this.batch = SalvageBatch.empty,
    this.pausedAt,
  });

  /// §18.4: the recipe being made, or null when this is a dismantling.
  final String? recipeId;

  /// §18.6: what is being taken apart, or null when this is a making.
  final String? salvageItemId;

  /// §18.6: how worn it was. The item is gone, so the figure has to travel
  /// with the job.
  final double? salvageCondition;

  /// §18.6: the rest of the sitting, when this is more than one piece.
  ///
  /// Empty for a making, and for a dismantling of one thing written by a
  /// version that did not know about sittings — [salvageItemId] is still the
  /// head either way, so nothing downstream has to ask which kind it is.
  final SalvageBatch batch;

  final DateTime startedAt;
  final DateTime readyAt;

  /// §2.1a.3: kiedy postać wyszła ze strefy, albo null — praca idzie.
  ///
  /// ⚠️ **Zegar ścienny nie wiedział, że nikogo nie ma przy imadle.** `readyAt`
  /// ustawione przy starcie tykało niezależnie od tego, gdzie stoi postać, więc
  /// plecak wojskowy dało się zostawić na warsztacie, przejść pół miasta i
  /// odebrać go w terenie. Obecność sprawdzana była **raz**, przy odpalaniu.
  final DateTime? pausedAt;

  bool get isPaused => pausedAt != null;

  /// Która to godzina dla tej pracy. Stoi, kiedy stoi robota.
  DateTime _clock(DateTime now) => pausedAt ?? now;

  /// §2.1a.3: praca odłożona, bo postać wyszła. Postęp zostaje.
  CraftJob suspended({required DateTime at}) =>
      isPaused ? this : _copy(pausedAt: at);

  /// I podjęta z powrotem — termin przesuwa się o czas nieobecności.
  ///
  /// ⚠️ Przesunięcie, nie skasowanie: praca ma zostać dokładnie tam, gdzie ją
  /// zostawiono, a nie cofnąć się do początku ani przeskoczyć do końca.
  CraftJob resumed({required DateTime at}) {
    final left = pausedAt;
    if (left == null) return this;

    // ⚠️ **Oba stemple, nie sam termin.** Postęp i pasek liczą się od
    // `startedAt`, więc przesunięcie samego `readyAt` wydłużyłoby robotę
    // zamiast ją przesunąć: godzinna praca po dobie nieobecności miałaby
    // dobę i godzinę „całości", a trzydzieści minut zrobione czytałoby się
    // jako dwa procent. Cała robota przesuwa się o czas, w którym jej nie było.
    final away = at.isAfter(left) ? at.difference(left) : Duration.zero;
    return CraftJob(
      recipeId: recipeId,
      salvageItemId: salvageItemId,
      salvageCondition: salvageCondition,
      batch: batch,
      startedAt: startedAt.add(away),
      readyAt: readyAt.add(away),
    );
  }

  CraftJob _copy({DateTime? pausedAt}) => CraftJob(
    recipeId: recipeId,
    salvageItemId: salvageItemId,
    salvageCondition: salvageCondition,
    batch: batch,
    startedAt: startedAt,
    readyAt: readyAt,
    pausedAt: pausedAt ?? this.pausedAt,
  );

  bool get isSalvage => salvageItemId != null;

  /// Whether this sitting has more than one piece in it.
  bool get isBatch => batch.length > 1;

  /// §18.6: how much work this job has been credited with by [now].
  ///
  /// Capped at the total, because a job left running while the app was closed
  /// cannot earn more than it was worth.
  Duration creditedAt(DateTime now) {
    final total = readyAt.difference(startedAt);
    final done = _clock(now).difference(startedAt);

    if (done.isNegative) return Duration.zero;
    return done > total ? total : done;
  }

  bool isDoneAt(DateTime now) => !_clock(now).isBefore(readyAt);

  Duration remainingAt(DateTime now) {
    final left = readyAt.difference(_clock(now));
    return left.isNegative ? Duration.zero : left;
  }

  /// 0–1 for a bar that means something.
  double progressAt(DateTime now) {
    final total = readyAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1;

    final done = _clock(now).difference(startedAt).inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }
}

/// Why a job cannot start.
enum CraftRefusal {
  /// Something else is already on the bench.
  busy,

  /// §18.4: no workshop, or not a good enough one.
  noWorkshop,

  /// §18.4, §18.6: nothing at hand that would do the job.
  noTool,

  /// Not enough of something.
  noMaterials,

  /// §18.6: there is nothing in it worth getting back.
  ///
  /// ⚠️ Said before the minutes are spent. Forty per cent of a pistol is
  /// nothing at all, and finding that out after a quarter of an hour is the
  /// worst way for a player to learn the rule.
  nothingBack,

  /// §2.1a: not standing anywhere you keep your things.
  notAtShelter,
}

/// Everything needed to decide whether one recipe can be started.
class CraftBench {
  const CraftBench({
    required this.atShelter,
    required this.workshopLevel,
    required this.atHand,
    required this.materials,
    this.busy = false,
    this.engineering = 0,
  });

  /// §2.1a: standing in a shelter or camp zone.
  final bool atShelter;

  /// §8.4: the workshop module's level, nought for none.
  final int workshopLevel;

  /// Item ids in the pack **and** on the shelves.
  ///
  /// ⚠️ Both, because §18.3 already learned this the hard way: making somebody
  /// pick their own hammer up off their own shelf before the button lights is
  /// bookkeeping, not a decision.
  final Set<String> atHand;

  /// Counts of everything at hand, for the material check.
  final Map<String, int> materials;

  final bool busy;
  final double engineering;
}

/// §18.4: whether this recipe can be started now, and why not.
CraftRefusal? refusalFor(ItemRecipe recipe, CraftBench bench) {
  if (bench.busy) return CraftRefusal.busy;
  if (!bench.atShelter) return CraftRefusal.notAtShelter;
  if (recipe.workshopLevel > bench.workshopLevel) {
    return CraftRefusal.noWorkshop;
  }
  if (!craftToolsAllow(recipe, bench.atHand)) return CraftRefusal.noTool;

  for (final entry in recipe.materials.entries) {
    if ((bench.materials[entry.key] ?? 0) < entry.value) {
      return CraftRefusal.noMaterials;
    }
  }
  return null;
}

/// §18.6: whether this item can be taken apart now, and why not.
CraftRefusal? salvageRefusalFor(
  String itemId,
  CraftBench bench, {
  required ItemCatalogue catalogue,
  required RecipeBook book,
  double condition = 100,
}) {
  if (bench.busy) return CraftRefusal.busy;
  if (!bench.atShelter) return CraftRefusal.notAtShelter;
  if (!canSalvageWith(bench.atHand)) return CraftRefusal.noTool;

  final item = catalogue[itemId];
  if (item == null) return CraftRefusal.nothingBack;

  final back = salvageOf(
    item,
    book,
    condition: condition,
    share: salvageShare(
      engineering: bench.engineering,
      workshopLevel: bench.workshopLevel,
    ),
  );

  return back.isEmpty ? CraftRefusal.nothingBack : null;
}

/// §18.6: what this dismantling will actually hand back.
///
/// The same call the refusal makes, exposed so the interface can say it out
/// loud *before* the item is destroyed. Nothing here is reversible, and a
/// player is entitled to read the price first.
Map<String, int> salvagePreview(
  String itemId,
  CraftBench bench, {
  required ItemCatalogue catalogue,
  required RecipeBook book,
  double condition = 100,
}) {
  final item = catalogue[itemId];
  if (item == null) return const {};

  return salvageOf(
    item,
    book,
    condition: condition,
    share: salvageShare(
      engineering: bench.engineering,
      workshopLevel: bench.workshopLevel,
    ),
  );
}
