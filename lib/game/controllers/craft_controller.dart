/// What is on the bench, and what is coming apart on it (§18.4, §18.6).
///
/// ⚠️ **This is the one that genuinely needs two others, and it gets neither.**
///
/// §18.2 makes the pack and the shelves one pile at a bench: a recipe spends
/// off the shelves first and the pack second, and a sitting can take apart a
/// rifle from either. That is a real dependency, and pretending otherwise
/// would be dishonest — but a controller that imports two neighbours is a
/// controller nobody can move, test or read without dragging both along.
///
/// So the *spending* stays with the screen for now, because the screen is the
/// thing that already knows about both piles. When it moves, it moves behind
/// a narrow interface — a few methods about materials, nothing about who is
/// holding them — and not by importing a sibling. An interface with no caller
/// would be dead code today, so it is written down here rather than declared.
///
/// What is here is the job, the sitting, and the cache that stopped the bench
/// being recomputed once per row of a scrolling list.
library;

import 'package:flutter/foundation.dart';

import '../../craft/craft_job.dart';
import '../../craft/craft_store.dart';
import '../../craft/item_recipe.dart';
import '../../craft/salvage_batch.dart';
import '../../data/db/database.dart';
import '../../inventory/inventory.dart';
import '../../items/item_catalogue.dart';
import '../../map/geometry.dart';
import '../../shelter/shelter.dart';

class CraftController extends ChangeNotifier {
  CraftController(this._db);

  final SaveDatabase _db;

  /// §18.4, §18.6: the one thing on the bench, or null.
  final ValueNotifier<CraftJob?> job = ValueNotifier(null);

  /// §18.6: every piece spoken for by the sitting.
  ///
  /// ⚠️ The order is the order it happens in. The first is the one actually
  /// under the multitool and the only one with a bar; the rest are locked and
  /// waiting their turn. Everything in here is unusable — a rifle in a sitting
  /// cannot be worn, fired, dropped or shelved, which is why the pieces stay
  /// visible instead of vanishing for a quarter of an hour.
  final ValueNotifier<List<CarriedItem>> sitting = ValueNotifier(const []);

  int? _profileId;

  void bind({required int profileId}) => _profileId = profileId;

  /// Whether this piece is spoken for by the sitting on the bench.
  bool inSitting(CarriedItem line) =>
      sitting.value.any((piece) => piece.isSame(line));

  // -------------------------------------------------------------- reading --

  /// §18.6: the sitting on a job, whether it was written as one piece or many.
  ///
  /// A job from before sittings existed has no list, and is a sitting of one.
  /// Everything downstream reads this rather than [CraftJob.batch] so that the
  /// two kinds of row never need telling apart again.
  static SalvageBatch sittingOf(CraftJob job) {
    if (job.batch.isNotEmpty) return job.batch;
    if (!job.isSalvage) return SalvageBatch.empty;

    return SalvageBatch([
      SalvageStep(
        itemId: job.salvageItemId!,
        condition: job.salvageCondition ?? 100,
        takes: job.readyAt.difference(job.startedAt),
      ),
    ]);
  }

  /// §18.6: whether anything would actually come out of this piece.
  ///
  /// ⚠️ **Cached, because this is on the hot path.** It is asked once per row
  /// of a list somebody is scrolling, and each answer costs a recipe lookup, a
  /// material breakdown and a largest-remainder allocation. The same rifle
  /// asked thirty times a second is thirty identical answers.
  ///
  /// The key is what the answer actually depends on: what it is, how worn it
  /// is, and §18.6's share — which moves only with skills and the workshop.
  bool worthTakingApart(
    CarriedItem line, {
    required CraftBench bench,
    required ItemCatalogue catalogue,
    required RecipeBook book,
  }) {
    if (line.isPartlyDismantled) return true;

    final key =
        '${line.itemId}.${(line.condition ?? 100).round()}'
        '.${bench.workshopLevel}.${bench.engineering}';

    final known = _worth[key];
    if (known != null) return known;

    final worth = salvagePreview(
      line.itemId,
      bench,
      catalogue: catalogue,
      book: book,
      condition: line.condition ?? 100,
    ).isNotEmpty;

    // Bounded, because condition is a continuum: a hundred and one distinct
    // answers per item is more than the catalogue has items, and a pack is
    // nowhere near that. Cleared wholesale rather than aged — the entries are
    // booleans and rebuilding one is cheap.
    if (_worth.length > 512) _worth.clear();
    _worth[key] = worth;

    return worth;
  }

  final Map<String, bool> _worth = {};

  // -------------------------------------------------------------- writing --

  Future<CraftJob?> load() async {
    final profileId = _profileId;
    if (profileId == null) return null;

    return CraftStore(_db).load(profileId);
  }

  /// §18.4: puts one thing on the bench.
  Future<void> beginCraft({
    required String recipeId,
    required DateTime now,
    required Duration work,
  }) async {
    final profileId = _profileId;
    if (profileId == null) return;

    await CraftStore(
      _db,
    ).beginCraft(profileId, recipeId: recipeId, now: now, work: work);
  }

  /// §18.6: starts on one piece, the way the single-item path always has.
  ///
  /// ⚠️ Kept separate from [beginSalvage] rather than folded into a sitting of
  /// one. The two say the same thing differently — this one starts the clock
  /// in the past by however much the piece has already had, so the bar picks
  /// up where it was left; a sitting says the same thing by shortening the
  /// step. Merging them is a change of behaviour dressed as tidiness.
  Future<void> beginSalvageOne({
    required String itemId,
    required double condition,
    required DateTime now,
    required Duration work,
  }) async {
    final profileId = _profileId;
    if (profileId == null) return;

    await CraftStore(_db).beginSalvage(
      profileId,
      itemId: itemId,
      condition: condition,
      now: now,
      work: work,
    );
  }

  /// §18.6: starts a sitting, of one piece or of several.
  Future<void> beginSalvage(SalvageBatch batch, {required DateTime now}) async {
    final profileId = _profileId;
    if (profileId == null) return;

    await CraftStore(_db).beginBatchSalvage(profileId, batch, now: now);
  }

  /// §2.1a.3: praca stoi, kiedy nikogo nie ma przy imadle.
  ///
  /// ⚠️ **Zamrożenie, nie utrata.** Wyjście ze strefy odkłada robotę tam, gdzie
  /// była, a powrót przesuwa termin o czas nieobecności — plecak wojskowy
  /// zostawiony na warsztacie nie robi się sam przez pół miasta, ale też nie
  /// przepada za to, że gracz wyszedł po wodę.
  ///
  /// Zwraca `true`, jeśli coś się zmieniło — wołający ma wtedy co zapisać.
  Future<bool> presence({
    required List<Shelter> shelters,
    required GeoPoint? at,
    required DateTime now,
  }) async {
    final profileId = _profileId;
    final current = job.value;
    if (profileId == null || current == null) return false;

    // Ta sama odpowiedź, którą liczy warsztat, oferując robotę: obóz jest
    // miejscem, w którym się trzyma rzeczy, więc i on liczy się za warsztat
    // (§8.5). Dwie różne odpowiedzi znaczyłyby, że gra przyjmuje zlecenia
    // tam, gdzie ich nie wykonuje.
    final atShelter = at != null && shelterAt(at, shelters, now: now) != null;

    // Skończonej pracy się nie odkłada: to już jest wynik, a nie robota, i
    // czeka na odbiór tam, gdzie leży.
    if (current.isDoneAt(now)) return false;

    final next = atShelter
        ? current.resumed(at: now)
        : current.suspended(at: now);
    if (identical(next, current)) return false;

    job.value = next;
    notifyListeners();

    await CraftStore(_db).saveClock(profileId, next);
    return true;
  }

  Future<void> clear() async {
    final profileId = _profileId;
    if (profileId == null) return;

    await CraftStore(_db).clear(profileId);
  }

  /// Takes the bench off the clock and lets go of everything it was holding.
  void stop() {
    job.value = null;
    sitting.value = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    job.dispose();
    sitting.dispose();
    super.dispose();
  }
}
