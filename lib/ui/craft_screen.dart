/// The bench (§18.4, §18.6).
///
/// Everything §18.4 knows how to make, in tabs by what it makes, each row
/// saying what it costs and — when it cannot be started — why not, in that
/// order. A recipe that is out of reach stays on the list rather than
/// disappearing: knowing a spear needs a workshop is the reason to build one.
///
/// ⚠️ **Tabs, because the list outgrew a list.** Eight rows read fine;
/// twenty-six do not, and a player looking for a coat had to scroll past four
/// dressings, three packs and a crowbar to find out whether one exists. The
/// tab is the item's own kind (§4.1), so nothing here decides categories —
/// the catalogue already did.
///
/// ⚠️ The refusal is on the row, not in a message after the tap. A greyed
/// button that says nothing is the thing this screen exists to avoid; the
/// shelter's own requirement rows were read as broken for exactly that reason
/// until they started showing ✓ against what was already held.
library;

import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../craft/craft_job.dart';
import '../craft/item_recipe.dart';
import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_names.dart';
import '../items/item_catalogue.dart';
import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'inventory_screen.dart' show kindName;
import 'item_details_sheet.dart';
import '../sim/pinned_goal.dart';
import 'units.dart';
import 'hud.dart' show HudColors;

class CraftScreen extends StatefulWidget {
  const CraftScreen({
    required this.book,
    required this.catalogue,
    required this.bench,
    required this.job,
    required this.inventory,
    required this.names,
    required this.itemNameOf,
    required this.onCraft,
    required this.onCancel,
    super.key,
  });

  final RecipeBook book;
  final ItemCatalogue catalogue;
  final CraftBench bench;

  /// What is already on the bench, if anything.
  final CraftJob? job;

  /// §12: so a row can show what the thing would actually be, before it is
  /// made. The sheet compares against what is worn, which is the question a
  /// player asks about a coat they are thinking of sewing.
  final ValueListenable<Inventory> inventory;
  final ItemNames names;

  final String Function(String itemId) itemNameOf;
  final void Function(ItemRecipe) onCraft;
  final VoidCallback onCancel;

  @override
  State<CraftScreen> createState() => _CraftScreenState();
}

class _CraftScreenState extends State<CraftScreen> {
  /// §12: whether the list is cut down to what could be started right now.
  ///
  /// ⚠️ **Off by default, and it stays that way.** A recipe out of reach is
  /// the reason to build a workshop or go looking for leather — hiding it by
  /// default would hide the goal along with the row. This is a tool for
  /// somebody standing at the bench with materials in hand asking "what can I
  /// do with these", which is a different question and a real one.
  bool _onlyPossible = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final catalogue = widget.catalogue;
    final job = widget.job;
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    // Cheapest first, and within that by what it makes. A list that reorders
    // itself as materials come and go would be unreadable; this one never
    // moves.
    final recipes = [...book.recipes]
      ..sort((a, b) {
        final work = a.work.compareTo(b.work);
        return work != 0 ? work : a.output.compareTo(b.output);
      });

    // §4.1's own kinds, in the enum's order, and only the ones something is
    // actually made of. A tab with nothing behind it is a promise the bench
    // does not keep.
    final kinds = [
      for (final kind in ItemKind.values)
        if (recipes.any((recipe) => catalogue[recipe.output]?.kind == kind))
          kind,
    ];

    return DefaultTabController(
      length: kinds.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.craftTitle),
          actions: [
            IconButton(
              tooltip: l10n.craftOnlyPossible,
              onPressed: () => setState(() => _onlyPossible = !_onlyPossible),
              icon: Icon(
                _onlyPossible ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.craftAll),
              for (final kind in kinds) Tab(text: kindName(l10n, kind)),
            ],
          ),
        ),
        body: Column(
          children: [
            // ⚠️ Above the tabs, not inside one of them. A player who started
            // a coat and then looked at the knives would otherwise find the
            // bar gone and the bench apparently empty.
            if (job != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _Running(
                  job: job,
                  label: _jobLabel(l10n, job),
                  onCancel: widget.onCancel,
                  colours: colours,
                  l10n: l10n,
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(recipes, colours, l10n),
                  for (final kind in kinds)
                    _list(
                      [
                        for (final recipe in recipes)
                          if (catalogue[recipe.output]?.kind == kind) recipe,
                      ],
                      colours,
                      l10n,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<ItemRecipe> rows, HudColors colours, L10n l10n) {
    final bench = widget.bench;
    final catalogue = widget.catalogue;

    // ⚠️ A busy bench is not a reason to hide anything. Everything is refused
    // while something is on the vice, so filtering on the refusal alone would
    // empty every tab the moment a job started — and the player would read an
    // empty bench rather than a busy one.
    final shown = _onlyPossible
        ? [
            for (final recipe in rows)
              if (refusalFor(recipe, bench) case null || CraftRefusal.busy)
                recipe,
          ]
        : rows;

    if (shown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.craftNoneHere,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colours.muted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        for (final recipe in shown)
          _RecipeRow(
            recipe: recipe,
            definition: catalogue[recipe.output],
            name: widget.itemNameOf(recipe.output),
            bench: bench,
            book: widget.book,
            catalogue: catalogue,
            inventory: widget.inventory,
            names: widget.names,
            refusal: refusalFor(recipe, bench),
            itemNameOf: widget.itemNameOf,
            onCraft: () => widget.onCraft(recipe),
            colours: colours,
            l10n: l10n,
          ),
      ],
    );
  }

  String _jobLabel(L10n l10n, CraftJob running) {
    if (running.isSalvage) {
      return l10n.craftTakingApart(widget.itemNameOf(running.salvageItemId!));
    }

    final recipe = widget.book.recipes
        .where((entry) => entry.id == running.recipeId)
        .firstOrNull;
    return recipe == null
        ? l10n.craftTitle
        : l10n.craftMaking(widget.itemNameOf(recipe.output));
  }
}

/// §2.1a.3: what is on the bench now, and how much of it is left.
class _Running extends StatelessWidget {
  const _Running({
    required this.job,
    required this.label,
    required this.onCancel,
    required this.colours,
    required this.l10n,
  });

  final CraftJob job;
  final String label;
  final VoidCallback onCancel;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final left = job.remainingAt(now);

    return Card(
      color: colours.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: colours.text),
                  ),
                ),
                Text(
                  _saidAs(left),
                  style: TextStyle(
                    fontSize: 13,
                    color: colours.data,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: job.progressAt(now),
              minHeight: 4,
              backgroundColor: colours.muted.withValues(alpha: 0.25),
              color: colours.data,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text(l10n.craftCancel),
              ),
            ),

            // ⚠️ Said where the button is, because it is not what "cancel"
            // means anywhere else in this game. §18 has no rule giving
            // anything back from work abandoned half way, and inventing one
            // would make starting a job free.
            Text(
              l10n.craftCancelWarning,
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
          ],
        ),
      ),
    );
  }

  String _saidAs(Duration left) => remaining(left);
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({
    required this.recipe,
    required this.definition,
    required this.name,
    required this.bench,
    required this.book,
    required this.catalogue,
    required this.inventory,
    required this.names,
    required this.refusal,
    required this.itemNameOf,
    required this.onCraft,
    required this.colours,
    required this.l10n,
  });

  final ItemRecipe recipe;
  final ItemDefinition? definition;
  final String name;
  final CraftBench bench;
  final RecipeBook book;
  final ItemCatalogue catalogue;
  final ValueListenable<Inventory> inventory;
  final ItemNames names;
  final CraftRefusal? refusal;
  final String Function(String itemId) itemNameOf;
  final VoidCallback onCraft;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final work = craftWork(
      recipe,
      engineering: bench.engineering,
      workshopLevel: bench.workshopLevel,
    );

    return Card(
      color: colours.panel,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.count > 1 ? '$name ×${recipe.count}' : name,
                    style: TextStyle(fontSize: 15, color: colours.text),
                  ),
                ),
                Text(
                  worked(work),
                  style: TextStyle(
                    fontSize: 13,
                    color: colours.muted,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // §12: what the thing actually is, before an hour is spent
                // on it. The same sheet the pack shows, so a coat being
                // considered is compared against the coat being worn.
                if (definition != null)
                  ItemInfoButton(
                    onPressed: () => unawaited(
                      showItemDetails(
                        context,
                        line: CarriedItem(itemId: recipe.output),
                        inventory: inventory,
                        catalogue: catalogue,
                        names: names,
                        bench: bench,
                        book: book,
                        // Nothing here is owned yet: no wearing, no dropping,
                        // and nothing to take apart.
                        fromPack: false,
                      ),
                    ),
                    colour: colours.muted,
                  ),
                IconButton(
                  icon: const Icon(Icons.push_pin_outlined, size: 18),
                  tooltip: l10n.goalPin,
                  onPressed: () {
                    PinnedGoalManager.pin(name, {
                      for (final entry in recipe.materials.entries)
                        entry.key: entry.value,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.goalPinned(name))),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Each material with what is held against what it takes, and a ✓
            // on the ones already covered. The shelter learned this the hard
            // way: a grey figure that was already met read as disabled.
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                for (final entry in recipe.materials.entries)
                  _Need(
                    label: itemNameOf(entry.key),
                    have: bench.materials[entry.key] ?? 0,
                    need: entry.value,
                    colours: colours,
                  ),
              ],
            ),

            // §18.4, §12: narzędzia i warsztat w jednym wierszu.
            //
            // ⚠️ Poziom warsztatu był wypisany dwa razy — raz tutaj, raz przy
            // przycisku jako odmowa — i zajmował wiersz w każdej karcie, w
            // której cokolwiek go wymaga. Ta sama rzecz powiedziana dwa razy
            // czyta się jak dwie różne rzeczy.
            if (recipe.toolsAnyOf.isNotEmpty || recipe.workshopLevel > 0) ...[
              const SizedBox(height: 2),
              Wrap(
                spacing: 10,
                children: [
                  if (recipe.toolsAnyOf.isNotEmpty)
                    Text(
                      '${l10n.craftNeedsTool}: '
                      '${recipe.toolsAnyOf.map(itemNameOf).join(' / ')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: craftToolsAllow(recipe, bench.atHand)
                            ? colours.data
                            : colours.alert,
                      ),
                    ),
                  if (recipe.workshopLevel > 0)
                    Text(
                      l10n.craftNeedsWorkshop(recipe.workshopLevel),
                      style: TextStyle(
                        fontSize: 11,
                        color: bench.workshopLevel >= recipe.workshopLevel
                            ? colours.data
                            : colours.alert,
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            Row(
              children: [
                // ⚠️ Everything except being busy. "Something is already
                // being made" repeated down twenty-six rows says one thing
                // twenty-six times, and the one thing is already said by the
                // bar at the top and by every button being dead. What belongs
                // here is what is missing *from this row*.
                // ⚠️ I nie powtarza tego, co stoi wyżej w wymaganiach.
                // „Warsztat L1" pod przyciskiem i „Warsztat L1" w wymaganiach
                // to jeden wiersz zajęty na nic — a to, czego brakuje, jest
                // już zaznaczone kolorem tam, gdzie jest wypisane.
                Expanded(
                  child: Text(
                    refusal == null ||
                            refusal == CraftRefusal.busy ||
                            refusal == CraftRefusal.noWorkshop ||
                            refusal == CraftRefusal.noTool ||
                            refusal == CraftRefusal.noMaterials
                        ? ''
                        : _said(l10n, refusal!),
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                ),
                FilledButton(
                  onPressed: refusal == null ? onCraft : null,
                  child: Text(l10n.craftMake),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _said(L10n l10n, CraftRefusal refusal) =>
      craftRefusalText(l10n, refusal, workshopLevel: recipe.workshopLevel);
}

/// §18.4, §18.6, §12: why the bench will not take this, in the player's words.
///
/// ⚠️ **One of these, not two.** There were two — this one and a copy on the
/// game screen — and they had drifted: the copy answered a missing *workshop*
/// with "nothing to do it with", which is the wrong sentence. A player reads
/// that and goes looking for a tool they already have.
///
/// [workshopLevel] is what §18.4 asks for, when the caller knows. Without it
/// the refusal still names the workshop rather than a tool, because that is
/// what is actually missing.
String craftRefusalText(
  L10n l10n,
  CraftRefusal refusal, {
  int? workshopLevel,
}) => switch (refusal) {
  CraftRefusal.busy => l10n.craftBenchBusy,
  CraftRefusal.noWorkshop => l10n.craftNeedsWorkshop(workshopLevel ?? 1),
  CraftRefusal.noTool => l10n.craftNoTool,
  CraftRefusal.noMaterials => l10n.craftNoMaterials,
  CraftRefusal.nothingBack => l10n.craftNothingBack,
  CraftRefusal.notAtShelter => l10n.craftNotAtShelter,
};

/// One material: what is held against what it takes.
class _Need extends StatelessWidget {
  const _Need({
    required this.label,
    required this.have,
    required this.need,
    required this.colours,
  });

  final String label;
  final int have;
  final int need;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final met = have >= need;

    return Text(
      '${met ? '✓ ' : ''}$label $have / $need',
      style: TextStyle(
        fontSize: 12,
        color: met ? colours.data : colours.alert,
        fontFamily: kDataFont,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
