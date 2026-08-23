/// The bench (§18.4, §18.6).
///
/// One list of everything §18.4 knows how to make, each row saying what it
/// costs and — when it cannot be started — why not, in that order. A recipe
/// that is out of reach stays on the list rather than disappearing: knowing a
/// spear needs a workshop is the reason to build one.
///
/// ⚠️ The refusal is on the row, not in a message after the tap. A greyed
/// button that says nothing is the thing this screen exists to avoid; the
/// shelter's own requirement rows were read as broken for exactly that reason
/// until they started showing ✓ against what was already held.
library;

import 'package:flutter/material.dart';

import '../craft/craft_job.dart';
import '../craft/item_recipe.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../l10n/app_localizations.dart';
import 'fonts.dart';
import '../sim/pinned_goal.dart';
import 'units.dart';
import 'hud.dart' show HudColors;

class CraftScreen extends StatelessWidget {
  const CraftScreen({
    required this.book,
    required this.catalogue,
    required this.bench,
    required this.job,
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

  final String Function(String itemId) itemNameOf;
  final void Function(ItemRecipe) onCraft;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.craftTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          if (job != null) ...[
            _Running(
              job: job!,
              label: _jobLabel(l10n, job!),
              onCancel: onCancel,
              colours: colours,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
          ],

          for (final recipe in recipes)
            _RecipeRow(
              recipe: recipe,
              definition: catalogue[recipe.output],
              name: itemNameOf(recipe.output),
              bench: bench,
              refusal: refusalFor(recipe, bench),
              itemNameOf: itemNameOf,
              onCraft: () => onCraft(recipe),
              colours: colours,
              l10n: l10n,
            ),
        ],
      ),
    );
  }

  String _jobLabel(L10n l10n, CraftJob running) {
    if (running.isSalvage) {
      return l10n.craftTakingApart(itemNameOf(running.salvageItemId!));
    }

    final recipe = book.recipes
        .where((entry) => entry.id == running.recipeId)
        .firstOrNull;
    return recipe == null
        ? l10n.craftTitle
        : l10n.craftMaking(itemNameOf(recipe.output));
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
                  remaining(work),
                  style: TextStyle(
                    fontSize: 13,
                    color: colours.muted,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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

            if (recipe.toolsAnyOf.isNotEmpty) ...[
              const SizedBox(height: 2),
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
            ],

            if (recipe.workshopLevel > 0) ...[
              const SizedBox(height: 2),
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

            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    refusal == null ? '' : _said(l10n, refusal!),
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

  String _said(L10n l10n, CraftRefusal refusal) => switch (refusal) {
    CraftRefusal.busy => l10n.craftBenchBusy,
    CraftRefusal.noWorkshop => l10n.craftNeedsWorkshop(recipe.workshopLevel),
    CraftRefusal.noTool => l10n.craftNoTool,
    CraftRefusal.noMaterials => l10n.craftNoMaterials,
    CraftRefusal.nothingBack => l10n.craftNothingBack,
    CraftRefusal.notAtShelter => l10n.craftNotAtShelter,
  };
}

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
