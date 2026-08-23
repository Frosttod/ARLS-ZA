/// The place you come back to (§8).
///
/// One screen for the whole of it, because from the player's side it is one
/// question asked at different times: what is here, and what could be here if
/// I carried enough back. So the modules are shown whether or not they can be
/// afforded, with what is missing named — a locked row that says "6 more
/// planks" is a reason to go out, and a hidden row is nothing at all.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'effects.dart';
import '../map/geometry.dart';
import '../shelter/recipes.dart';
import '../shelter/shelter.dart';
import 'fonts.dart';
import '../craft/craft_job.dart';
import 'hud.dart' show HudColors;
import 'units.dart';
import 'ticking.dart';

class ShelterScreen extends StatefulWidget {
  const ShelterScreen({
    required this.shelters,
    required this.standingAt,
    required this.carried,
    required this.itemNameOf,
    required this.hasTools,
    required this.hasHammer,
    required this.hasMultitool,
    required this.onBuild,
    required this.onBuildModule,
    this.onDemolishModule,
    required this.onCancelBuild,
    required this.onShelves,
    required this.onCraft,
    required this.craftJob,
    this.onDisassemble,
    required this.shelved,
    required this.shelvedMassKg,
    required this.shelvedVolumeL,
    this.hotspots = const [],
    super.key,
  });

  /// ⚠️ Listened to, not passed by value. This is a pushed route: handed a
  /// list, it kept showing the one it opened with, so starting a build left
  /// the counter at zero until somebody backed out and came in again. Fourth
  /// time this shape of bug has been fixed in this app.
  final ValueListenable<List<Shelter>> shelters;

  /// Where the player is standing. Null with no fix, which is the one state
  /// where nothing here can be started — a shelter goes where you are.
  final ValueListenable<GeoPoint?> standingAt;

  /// Item id to how many are carried, for §18.2's costs.
  final Map<String, int> carried;

  final String Function(String itemId) itemNameOf;

  /// §18.3: a hammer or an axe for the shelter itself.
  final bool hasTools;

  /// §18.3: a hammer for every module, and a multitool as well from Workshop 2.
  final bool hasHammer;
  final bool hasMultitool;

  final void Function(ShelterKind kind) onBuild;
  final void Function(ShelterModule module) onBuildModule;
  final void Function(ShelterModule module)? onDemolishModule;

  /// §8.3: gives up on whatever is going up. Asked about first, because the
  /// materials are already in the walls and the work starts again from zero.
  final void Function(Shelter place) onCancelBuild;

  /// §18.2: opening the shelves of a finished place.
  final void Function(Shelter place) onShelves;

  /// §18.4: the way to the bench.
  final VoidCallback onCraft;

  /// What is on it, so the row can say so without opening it.
  final ValueListenable<CraftJob?> craftJob;

  /// §18.6: taking several things apart at once, from the bench.
  final VoidCallback? onDisassemble;

  /// §18.2: what is on the shelves of the main shelter, by item id.
  ///
  /// ⚠️ Counted towards every recipe alongside the pack. A player standing in
  /// their own shelter is standing next to the shelf, and asking them to pick
  /// twenty planks up off it before the button will light is bookkeeping, not
  /// a decision.
  final Map<String, int> shelved;

  final double shelvedMassKg;
  final double shelvedVolumeL;

  /// §8.5.2: hotspot centres, which a camp may not sit inside.
  final List<GeoPoint> hotspots;

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen>
    with WidgetsBindingObserver, Ticking<ShelterScreen> {
  /// §8.3: the counters are the whole content of this screen while something
  /// is going up, and a screen whose only content is a number that never moves
  /// reads as broken.
  /// §8.3: only while something is going up. A finished shelter is a page of
  /// figures that do not move.
  @override
  bool get ticking => widget.shelters.value.any(
    (place) =>
        !place.isReadyAt(DateTime.now().toUtc()) || place.building != null,
  );

  Shelter? _main(List<Shelter> shelters) =>
      shelters.where((s) => s.kind == ShelterKind.main).firstOrNull;

  List<Shelter> _camps(List<Shelter> shelters) => [
    for (final s in shelters)
      if (s.kind == ShelterKind.camp) s,
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<Shelter>>(
    valueListenable: widget.shelters,
    builder: (context, shelters, _) => ValueListenableBuilder<GeoPoint?>(
      valueListenable: widget.standingAt,
      builder: (context, at, _) => _body(context, shelters, at),
    ),
  );

  Widget _body(BuildContext context, List<Shelter> shelters, GeoPoint? at) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final shelter = _main(shelters);
    final now = DateTime.now().toUtc();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuShelter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (shelter == null)
            _BuildOffer(
              kind: ShelterKind.main,
              body: l10n.shelterNoneWhat,
              time: buildTimeFor(ShelterKind.main, hasTools: widget.hasTools),
              refusal: at == null ? l10n.shelterNoFix : null,
              onBuild: () => widget.onBuild(ShelterKind.main),
              colours: colours,
            )
          else ...[
            _Standing(
              shelter: shelter,
              now: now,
              away: at == null || !shelter.atSite(at),
              onCancel: () => _confirmCancel(context, shelter),
              colours: colours,
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 12),
            if (shelter.isReadyAt(now))
              for (final module in ShelterModule.values)
                _ModuleRow(
                  // §18.2, §18.4: the shelves belong to Storage and the bench
                  // belongs to Workshop, because that is what those modules
                  // are for. They were two more cards above this list, and a
                  // player reading "Magazyn 2/3" beside a separate "Półki"
                  // card had to work out for themselves that the first was
                  // the reason for the second.
                  panel: switch (module) {
                    ShelterModule.storage => _ShelvesRow(
                      shelter: shelter,
                      away: at == null || !shelter.atSite(at),
                      massKg: widget.shelvedMassKg,
                      volumeL: widget.shelvedVolumeL,
                      onOpen: () => widget.onShelves(shelter),
                      colours: colours,
                    ),
                    ShelterModule.workshop => ValueListenableBuilder<CraftJob?>(
                      valueListenable: widget.craftJob,
                      builder: (_, job, _) => _CraftRow(
                        away: at == null || !shelter.atSite(at),
                        job: job,
                        onOpen: widget.onCraft,
                        onDisassemble: widget.onDisassemble,
                        colours: colours,
                        l10n: l10n,
                      ),
                    ),
                    _ => null,
                  },
                  shelter: shelter,
                  module: module,
                  now: now,
                  carried: widget.carried,
                  shelved: widget.shelved,
                  itemNameOf: widget.itemNameOf,
                  hasHammer: widget.hasHammer,
                  hasMultitool: widget.hasMultitool,
                  // §2.1a.3: nailing shelves up from the other side of town is
                  // not a thing, so the offer is refused here and says why.
                  away: at == null || !shelter.atSite(at),
                  onBuild: () => widget.onBuildModule(module),
                  onDemolish: widget.onDemolishModule == null
                      ? null
                      : () => widget.onDemolishModule!(module),
                  onCancel: () => _confirmCancel(context, shelter),
                  colours: colours,
                ),
          ],

          const SizedBox(height: 20),
          Text(
            l10n.shelterCamps.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: colours.muted,
            ),
          ),
          const SizedBox(height: 8),

          for (final camp in _camps(shelters)) ...[
            _Standing(
              shelter: camp,
              now: now,
              away: at == null || !camp.atSite(at),
              onCancel: () => _confirmCancel(context, camp),
              colours: colours,
            ),
            const SizedBox(height: 12),
          ],

          _BuildOffer(
            kind: ShelterKind.camp,
            body: l10n.campWhat,
            time: buildTimeFor(ShelterKind.camp, hasTools: widget.hasTools),
            refusal: _campRefusal(l10n, shelters, at),
            onBuild: () => widget.onBuild(ShelterKind.camp),
            colours: colours,
          ),
        ],
      ),
    );
  }

  /// §8.3: says what giving up costs, before it costs it.
  ///
  /// Nothing here can be undone: the materials went into the walls, and the
  /// hours start again from nothing. A confirmation is not friction — it is
  /// the only place the player is ever told that.
  Future<void> _confirmCancel(BuildContext context, Shelter place) async {
    final l10n = L10n.of(context);

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shelterCancelTitle),
        content: Text(
          place.building != null
              ? l10n.shelterCancelModuleWhat
              : place.kind == ShelterKind.main
              ? l10n.shelterCancelShelterWhat
              : l10n.shelterCancelCampWhat,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.shelterCancelKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shelterCancelConfirm),
          ),
        ],
      ),
    );

    if (sure ?? false) widget.onCancelBuild(place);
  }

  String? _campRefusal(L10n l10n, List<Shelter> shelters, GeoPoint? at) {
    final here = at;
    if (here == null) return l10n.shelterNoFix;

    final missing = missingFor(kCampMaterials, widget.carried);
    if (missing.isNotEmpty) {
      return l10n.shelterMissing(
        [
          for (final entry in missing.entries)
            '${widget.itemNameOf(entry.key)} ×${entry.value}',
        ].join(', '),
      );
    }

    return switch (campRefusalAt(
      here,
      existing: shelters,
      hotspots: widget.hotspots,
    )) {
      null => null,
      CampRefusal.tooMany => l10n.campTooMany,
      CampRefusal.tooCloseToShelter => l10n.campTooCloseToShelter,
      CampRefusal.tooCloseToCamp => l10n.campTooCloseToCamp,
      CampRefusal.tooCloseToHotspot => l10n.campTooCloseToHotspot,
    };
  }
}

/// What is here now: the radius, the sleep, the storage (§8.1, §8.5.1).
class _Standing extends StatelessWidget {
  const _Standing({
    required this.shelter,
    required this.now,
    required this.away,
    required this.onCancel,
    required this.colours,
  });

  final Shelter shelter;
  final DateTime now;

  /// §2.1a.3: the work is standing still while nobody is here.
  final bool away;

  /// §8.3: gives up on it. Only offered while something is actually going up.
  final VoidCallback onCancel;

  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final building = !shelter.isReadyAt(now);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shelter.kind == ShelterKind.main
                  ? l10n.shelterTitle
                  : l10n.campTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (building) ...[
              // §8.3: against the clock, so this is a time to come back at
              // rather than a bar to sit in front of.
              LinearProgressIndicator(
                value: shelter.buildTime <= Duration.zero
                    ? 1
                    : 1 -
                          shelter
                                  .buildLeftAt(now, onSite: !away)
                                  .inMilliseconds /
                              shelter.buildTime.inMilliseconds,
                minHeight: 4,
                backgroundColor: colours.muted.withValues(alpha: 0.25),
                color: colours.data,
              ),
              const SizedBox(height: 6),
              Text(
                away
                    ? l10n.shelterWorkStopped
                    : l10n.shelterBuildingLeft(
                        _short(
                          shelter.buildLeft == null
                              ? shelter.readyAt.difference(now)
                              : shelter.buildLeftAt(now, onSite: !away),
                        ),
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: away ? const Color(0xFFE8B33A) : colours.text,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(l10n.shelterCancel),
                ),
              ),
            ] else ...[
              _Line(
                label: l10n.shelterSafeZone,
                value: '${shelter.kind.safeRadiusM.round()} m',
                colours: colours,
              ),
              // §8.4, §8.5.1: the same shape the module cards use — a
              // multiplier, never a percentage, because a Lounge at level two
              // is ×1,30 and that is not "+15% twice" in any arithmetic a
              // player does in their head.
              _Line(
                label: l10n.shelterSleep,
                value: times(shelter.sleepRate),
                colours: colours,
              ),
              // ⚠️ No storage line here any more. The shelves row below says
              // the same capacity *and* how much of it is used, and a figure
              // printed twice on one screen is a figure the reader has to
              // check against itself. A camp keeps it, because a camp has no
              // shelves row — its chest is the place itself.
              if (shelter.kind == ShelterKind.camp)
                _Line(
                  label: l10n.shelterStorage,
                  value: effects([
                    '${shelter.storageKg.round()} kg',
                    '${shelter.storageL.round()} l',
                  ]),
                  colours: colours,
                ),
              if (shelter.isDecayingAt(now))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.campDecaying,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE8B33A),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One module: what it is worth, what it costs, and what is stopping it.
class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.shelter,
    required this.module,
    required this.now,
    required this.carried,
    required this.shelved,
    required this.itemNameOf,
    required this.hasHammer,
    required this.hasMultitool,
    required this.away,
    required this.onBuild,
    this.onDemolish,
    required this.onCancel,
    required this.colours,
    this.panel,
  });

  /// ⚠️ What this module lets the player *do*, under what it costs to build.
  ///
  /// The shelves and the bench used to be their own cards above the modules,
  /// and that split one thing in two on screen: the Storage module exists to
  /// make the shelves bigger, and the Workshop module exists to make the bench
  /// better. A player looking at "Magazyn 2/3" and a separate "Półki" card had
  /// to work out for themselves that the first was the reason for the second.
  final Widget? panel;

  final Shelter shelter;
  final ShelterModule module;

  /// §2.1a.3: the player is not standing on the site.
  final bool away;
  final DateTime now;
  final Map<String, int> carried;

  /// §18.2: what is on the shelves, counted alongside the pack.
  final Map<String, int> shelved;

  final String Function(String) itemNameOf;
  final bool hasHammer;
  final bool hasMultitool;
  final VoidCallback onBuild;
  final VoidCallback? onDemolish;

  /// §8.3: gives up on the level going up right now.
  final VoidCallback onCancel;

  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final level = shelter.levelOf(module);
    final underway = shelter.building == module;
    final next = nextLevelOf(module, have: level);

    // Pack and shelves together, because that is what is within reach.
    final have = {...carried};
    for (final entry in shelved.entries) {
      have[entry.key] = (have[entry.key] ?? 0) + entry.value;
    }

    final missing = next == null
        ? const <String, int>{}
        : missingFor(next.materials, have);
    final tools =
        next != null &&
        toolsAllow(next, hasHammer: hasHammer, hasMultitool: hasMultitool);

    final work = next == null
        ? Duration.zero
        : moduleWork(
            next,
            hasHammer: hasHammer,
            hasMultitool: hasMultitool,
            workshopLevel: shelter.levelOf(ShelterModule.workshop),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    moduleName(l10n, module),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$level / ${ShelterModule.maxLevel}',
                  style: TextStyle(fontSize: 13, color: colours.data),
                ),
                if (level > 0 && !underway && onDemolish != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onDemolish,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.shelterDemolish,
                      style: TextStyle(fontSize: 12, color: colours.alert),
                    ),
                  ),
                ],
              ],
            ),
            // §12: what it is worth, in the same shape everywhere — a label,
            // a number, and where there is a next level, an arrow to it.
            //
            // ⚠️ The sentence that used to be here is gone rather than kept
            // alongside. "Fifteen per cent a level less to sleep off" is true,
            // is a paragraph, and still left a player working out what their
            // own Lounge was doing — which is the question the card is for.
            const SizedBox(height: 4),
            Text(
              effect(
                moduleEffectLabel(l10n, module),
                step(
                  moduleEffectAt(
                    l10n,
                    module,
                    level,
                    baseStorageKg: shelter.kind.storageKg,
                  ),
                  level >= ShelterModule.maxLevel
                      ? null
                      : moduleEffectAt(
                          l10n,
                          module,
                          level + 1,
                          baseStorageKg: shelter.kind.storageKg,
                        ),
                ),
              ),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: level >= ShelterModule.maxLevel
                    ? colours.muted
                    : colours.text,
              ),
            ),

            // ⚠️ What the module *does*, above what the next level costs.
            //
            // A player walks into a shelter to put something down or to make
            // something, and only sometimes to plan a build. The doing comes
            // first on the card for the same reason it used to be a separate
            // card above the modules — what changed is that it is no longer a
            // separate card, because the shelves and the Storage module were
            // never two things.
            if (panel != null) ...[const SizedBox(height: 10), panel!],

            if (underway) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      away
                          ? l10n.shelterWorkStopped
                          : l10n.shelterBuildingLeft(
                              _short(
                                shelter.buildingLeftAt(now, onSite: !away),
                              ),
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        color: away ? const Color(0xFFE8B33A) : colours.data,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(l10n.shelterCancel),
                  ),
                ],
              ),
            ] else if (next != null) ...[
              const SizedBox(height: 8),

              // ⚠️ Have against need, per material, rather than a list of
              // what a level costs and a separate line about what is short.
              // The question a player is answering here is "how many more
              // planks", and the old pair of lines made them do the
              // subtraction themselves.
              for (final entry in next.materials.entries)
                _Need(
                  label: itemNameOf(entry.key),
                  have: have[entry.key] ?? 0,
                  need: entry.value,
                  colours: colours,
                ),

              // §18.3: and the tool.
              //
              // ⚠️ Not as "1/1". A material is spent and a tool is not, and a
              // count beside a hammer says the hammer is about to be used up —
              // which sent a player looking for a second one. What matters
              // about a tool is only whether it is to hand.
              _Need.tool(
                label: itemNameOf(kHammerId),
                held: hasHammer,
                colours: colours,
              ),
              if (module == ShelterModule.workshop && next.level >= 2)
                _Need.tool(
                  label: itemNameOf(kMultitoolId),
                  held: hasMultitool,
                  colours: colours,
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      away
                          ? l10n.shelterNotHere
                          : !tools
                          ? l10n.shelterNeedsTool
                          : missing.isNotEmpty
                          ? l10n.shelterMissing(
                              [
                                for (final entry in missing.entries)
                                  '${itemNameOf(entry.key)} ×${entry.value}',
                              ].join(', '),
                            )
                          : _short(work),
                      style: TextStyle(
                        fontSize: 12,
                        color: missing.isEmpty && tools && !away
                            ? colours.muted
                            : const Color(0xFFE8B33A),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        missing.isEmpty &&
                            tools &&
                            !away &&
                            shelter.building == null
                        ? onBuild
                        : null,
                    child: Text(l10n.shelterBuild),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The offer to put something up here, and what is stopping it.
class _BuildOffer extends StatelessWidget {
  const _BuildOffer({
    required this.kind,
    required this.body,
    required this.time,
    required this.refusal,
    required this.onBuild,
    required this.colours,
  });

  final ShelterKind kind;
  final String body;
  final Duration time;

  /// Why it cannot go here, or null when it can.
  final String? refusal;

  final VoidCallback onBuild;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kind == ShelterKind.main ? l10n.shelterTitle : l10n.campTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(fontSize: 13, height: 1.4, color: colours.text),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    refusal ?? _short(time),
                    style: TextStyle(
                      fontSize: 12,
                      color: refusal == null
                          ? colours.muted
                          : const Color(0xFFE8B33A),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: refusal == null ? onBuild : null,
                  child: Text(l10n.shelterBuildHere),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.colours,
  });

  final String label;
  final String value;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colours.muted),
          ),
        ),
        Text(value, style: TextStyle(fontSize: 13, color: colours.text)),
      ],
    ),
  );
}

String moduleName(L10n l10n, ShelterModule module) => switch (module) {
  ShelterModule.storage => l10n.moduleStorage,
  ShelterModule.workshop => l10n.moduleWorkshop,
  ShelterModule.lounge => l10n.moduleLounge,
  ShelterModule.laboratory => l10n.moduleLaboratory,
};

/// §8.4, §12: what this module is worth at [level], as a number.
///
/// ⚠️ **A number, because a sentence was not answering the question.** The
/// rows used to read "fifteen per cent a level less to sleep off", which is
/// true, is a paragraph, and still leaves a player working out what their own
/// Lounge is doing right now. This says `×1,15`, and the row beside it says
/// what the next level makes it.
///
/// [baseStorageKg] is the shelter's own capacity before any shelves, because
/// §18.2's figure is a total rather than a bonus and a player reads the total.
String moduleEffectAt(
  L10n l10n,
  ShelterModule module,
  int level, {
  required double baseStorageKg,
}) => switch (module) {
  ShelterModule.storage =>
    '${(baseStorageKg + kStorageKgPerLevel * level).round()} kg',

  // The only module whose steps are not one figure repeated: level two also
  // opens §18.4's complex recipes, and that is worth more than the ten points
  // of condition beside it.
  ShelterModule.workshop => switch (level) {
    0 => l10n.moduleWorkshopNone,
    1 => percent(0.60),
    2 => '${percent(0.85)}$kEffectGap${l10n.moduleWorkshopComplex}',
    _ => percent(1.0),
  },

  ShelterModule.lounge => times(1 + kLoungeSleepPerLevel * level),
  ShelterModule.laboratory => times(1 + kLabNutritionPerLevel * level),
};

/// The label the figure above belongs to.
String moduleEffectLabel(L10n l10n, ShelterModule module) => switch (module) {
  ShelterModule.storage => l10n.moduleStorageEffect,
  ShelterModule.workshop => l10n.moduleWorkshopEffect,
  ShelterModule.lounge => l10n.moduleLoungeEffect,
  ShelterModule.laboratory => l10n.moduleLaboratoryEffect,
};

/// Hours and minutes, which is how every time in §8 is quoted — and seconds
/// once there is under an hour left.
///
/// A counter reading "12 min" for sixty seconds at a stretch looks stopped,
/// and this screen is watched precisely when somebody is wondering whether it
/// is running at all.
/// §12: a clock, like every other span in the game.
String _short(Duration time) => remaining(time);

/// What is going up right now, under the stats bar on the map (§8.3).
///
/// The same slot the tin of stew uses, for the same reason: it is the thing
/// the player is waiting on, and the bottom of the screen belongs to whatever
/// they are deciding next. Only while they are standing on the site — off it
/// the work is not happening, and a bar that crept along in a bus would be a
/// lie about the one rule this system has.
class BuildProgress extends StatelessWidget {
  const BuildProgress({
    required this.shelter,
    required this.now,
    this.onStop,
    super.key,
  });

  final Shelter shelter;
  final DateTime now;

  /// §12: a way out, from the screen the player is on.
  ///
  /// Not a quiet one — the caller asks first, because §18.2's materials are
  /// already in the frame and nothing gives them back.
  final void Function(Shelter place)? onStop;

  /// The bar worth drawing here, or null when nothing is going up.
  static BuildProgress? of(
    List<Shelter> shelters,
    GeoPoint? at,
    DateTime now, {
    void Function(Shelter place)? onStop,
  }) {
    if (at == null) return null;

    for (final place in shelters) {
      if (!place.atSite(at)) continue;
      if (!place.isReadyAt(now) || place.building != null) {
        return BuildProgress(shelter: place, now: now, onStop: onStop);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final onPlace = !shelter.isReadyAt(now);

    // On site by construction: [of] only returns a bar for a site the player
    // is standing on, so the seconds run.
    final left = onPlace
        ? shelter.buildLeftAt(now, onSite: true)
        : shelter.buildingLeftAt(now, onSite: true);
    final total = onPlace
        ? shelter.buildTime
        : (shelter.buildingLeft ?? Duration.zero);

    final done = total <= Duration.zero
        ? 1.0
        : 1 - left.inMilliseconds / total.inMilliseconds;

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    onPlace
                        ? (shelter.kind == ShelterKind.main
                              ? l10n.shelterTitle
                              : l10n.campTitle)
                        : moduleName(l10n, shelter.building!),
                    style: TextStyle(fontSize: 13, color: colours.text),
                  ),
                ),
                Text(
                  _short(left.isNegative ? Duration.zero : left),
                  style: TextStyle(
                    fontSize: 13,
                    color: colours.data,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // §12: a way out of this, from the screen the player is on.
                if (onStop != null)
                  IconButton(
                    onPressed: () => onStop!(shelter),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    tooltip: l10n.shelterCancel,
                    color: colours.muted,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: done.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: colours.muted.withValues(alpha: 0.25),
              color: colours.data,
            ),
          ],
        ),
      ),
    );
  }
}

/// §18.2: the shelves, and the one reason they might be refused.
class _ShelvesRow extends StatelessWidget {
  const _ShelvesRow({
    required this.shelter,
    required this.away,
    required this.massKg,
    required this.volumeL,
    required this.onOpen,
    required this.colours,
  });

  /// §18.1a: how full, on the screen the player is already looking at.
  ///
  /// Both limits, because either is the one that runs out — and here rather
  /// than only inside, because "have I room for this" is a question asked on
  /// the way in, not after two taps.
  final double massKg;
  final double volumeL;

  final Shelter shelter;

  /// §2.1a.3: a shelf is somewhere you have to be standing. Reaching into
  /// one's own house from the other side of town is not a thing, and it is the
  /// same refusal the modules already make.
  final bool away;

  final VoidCallback onOpen;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    // ⚠️ No heading of its own any more. This is inside the Storage module,
    // which is already titled, and a card that said "Magazyn" over a row that
    // said "Półki" was two names for one thing — the module *is* the shelves.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          away
              ? l10n.shelterNotHere
              : effects([
                  outOfKg(massKg, shelter.storageKg),
                  outOfL(volumeL, shelter.storageL),
                ]),
          style: TextStyle(
            fontSize: 12,
            color: colours.muted,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.tonalIcon(
          onPressed: away ? null : onOpen,
          icon: const Icon(Icons.inventory_2, size: 18),
          label: Text(l10n.shelterShelves),
        ),
      ],
    );
  }
}

/// One line of "what this costs, and what you have" (§18.2, §18.3).
///
/// Amber until it is met, so the whole list can be read down the left edge
/// without reading any of the words.
class _Need extends StatelessWidget {
  const _Need({
    required this.label,
    required this.have,
    required this.need,
    required this.colours,
  }) : tally = true;

  /// §18.3: something the work needs to hand and gives back.
  ///
  /// A hammer is not two planks. It is checked, used and still there
  /// afterwards, so it gets a tick or a dash rather than a count — "1/1
  /// młotek" reads as a hammer being consumed by the wall.
  const _Need.tool({
    required this.label,
    required bool held,
    required this.colours,
  }) : have = held ? 1 : 0,
       need = 1,
       tally = false;

  final String label;
  final int have;
  final int need;
  final bool tally;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final met = have >= need;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: met ? colours.muted : colours.text,
              ),
            ),
          ),
          // ⚠️ A tick beside a met requirement, and it is not decoration.
          //
          // Reported from a screenshot: with fourteen scrap on the shelf, one
          // module read "14 / 6" in grey and another "14 / 20" in amber, and
          // the player took the grey one for an error. The arithmetic was
          // right — different modules want different amounts — but grey alone
          // reads as *disabled*, not as *satisfied*, and nothing on the row
          // said which. §12 asks for the same thing for a different reason:
          // never colour alone.
          if (met && tally) ...[
            Text('✓', style: TextStyle(fontSize: 12, color: colours.data)),
            const SizedBox(width: 6),
          ],
          Text(
            tally ? '$have / $need' : (met ? '✓' : '—'),
            style: TextStyle(
              fontSize: 12,
              color: met ? colours.muted : const Color(0xFFE8B33A),
              fontFamily: tally ? kDataFont : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// §18.4: the way to the bench, and what is on it.
/// §18.4, §18.6: what the bench is doing and what can be done at it.
///
/// Lives inside the Workshop module rather than beside it. Making something
/// and taking something apart are both "use the workshop", and offering them
/// on a card of their own said the module was one thing and the bench another.
class _CraftRow extends StatelessWidget {
  const _CraftRow({
    required this.away,
    required this.job,
    required this.onOpen,
    required this.colours,
    required this.l10n,
    this.onDisassemble,
  });

  final bool away;
  final CraftJob? job;
  final VoidCallback onOpen;
  final VoidCallback? onDisassemble;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final running = job;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          running == null
              ? l10n.craftBenchFree
              : '${(running.progressAt(DateTime.now().toUtc()) * 100).round()}%',
          style: TextStyle(fontSize: 12, color: colours.muted),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // ⚠️ Standing on the site, not merely inside the zone. The same
            // rule the shelves keep, and for the same reason: the bench is a
            // place, not a permission.
            FilledButton.tonalIcon(
              onPressed: away ? null : onOpen,
              icon: const Icon(Icons.handyman, size: 18),
              label: Text(l10n.craftMake),
            ),
            const SizedBox(width: 8),
            if (onDisassemble != null)
              OutlinedButton.icon(
                onPressed: away ? null : onDisassemble,
                icon: const Icon(Icons.content_cut, size: 18),
                label: Text(l10n.craftTakeApart),
              ),
          ],
        ),
      ],
    );
  }
}
