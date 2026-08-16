/// The place you come back to (§8).
///
/// One screen for the whole of it, because from the player's side it is one
/// question asked at different times: what is here, and what could be here if
/// I carried enough back. So the modules are shown whether or not they can be
/// afforded, with what is missing named — a locked row that says "6 more
/// planks" is a reason to go out, and a hidden row is nothing at all.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../map/geometry.dart';
import '../shelter/recipes.dart';
import '../shelter/shelter.dart';
import 'hud.dart' show HudColors;

class ShelterScreen extends StatelessWidget {
  const ShelterScreen({
    required this.shelters,
    required this.at,
    required this.now,
    required this.carried,
    required this.itemNameOf,
    required this.hasTools,
    required this.hasHammer,
    required this.hasMultitool,
    required this.onBuild,
    required this.onBuildModule,
    this.hotspots = const [],
    super.key,
  });

  final List<Shelter> shelters;

  /// Where the player is standing. Null with no fix, which is the one state
  /// where nothing here can be started — a shelter goes where you are.
  final GeoPoint? at;

  final DateTime now;

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

  /// §8.5.2: hotspot centres, which a camp may not sit inside.
  final List<GeoPoint> hotspots;

  Shelter? get _main =>
      shelters.where((s) => s.kind == ShelterKind.main).firstOrNull;

  List<Shelter> get _camps =>
      [for (final s in shelters) if (s.kind == ShelterKind.camp) s];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final shelter = _main;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuShelter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (shelter == null)
            _BuildOffer(
              kind: ShelterKind.main,
              body: l10n.shelterNoneWhat,
              time: buildTimeFor(ShelterKind.main, hasTools: hasTools),
              refusal: at == null ? l10n.shelterNoFix : null,
              onBuild: () => onBuild(ShelterKind.main),
              colours: colours,
            )
          else ...[
            _Standing(
              shelter: shelter,
              now: now,
              away: at == null || !shelter.atSite(at!),
              colours: colours,
            ),
            const SizedBox(height: 16),
            if (shelter.isReadyAt(now))
              for (final module in ShelterModule.values)
                _ModuleRow(
                  shelter: shelter,
                  module: module,
                  now: now,
                  carried: carried,
                  itemNameOf: itemNameOf,
                  hasHammer: hasHammer,
                  hasMultitool: hasMultitool,
                  // §2.1a.3: nailing shelves up from the other side of town is
                  // not a thing, so the offer is refused here and says why.
                  away: at == null || !shelter.atSite(at!),
                  onBuild: () => onBuildModule(module),
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

          for (final camp in _camps) ...[
            _Standing(
              shelter: camp,
              now: now,
              away: at == null || !camp.atSite(at!),
              colours: colours,
            ),
            const SizedBox(height: 12),
          ],

          _BuildOffer(
            kind: ShelterKind.camp,
            body: l10n.campWhat,
            time: buildTimeFor(ShelterKind.camp, hasTools: hasTools),
            refusal: _campRefusal(l10n),
            onBuild: () => onBuild(ShelterKind.camp),
            colours: colours,
          ),
        ],
      ),
    );
  }

  String? _campRefusal(L10n l10n) {
    final here = at;
    if (here == null) return l10n.shelterNoFix;

    final missing = missingFor(kCampMaterials, carried);
    if (missing.isNotEmpty) {
      return l10n.shelterMissing(
        [
          for (final entry in missing.entries)
            '${itemNameOf(entry.key)} ×${entry.value}',
        ].join(', '),
      );
    }

    return switch (campRefusalAt(
      here,
      existing: shelters,
      hotspots: hotspots,
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
    required this.colours,
  });

  final Shelter shelter;
  final DateTime now;

  /// §2.1a.3: the work is standing still while nobody is here.
  final bool away;
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
                value: shelter.progressAt(now),
                minHeight: 4,
                backgroundColor: colours.muted.withValues(alpha: 0.25),
                color: colours.data,
              ),
              const SizedBox(height: 6),
              Text(
                away
                    ? l10n.shelterWorkStopped
                    : l10n.shelterBuildingLeft(
                        _short(shelter.buildLeft ?? shelter.readyAt.difference(now)),
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: away ? const Color(0xFFE8B33A) : colours.text,
                ),
              ),
            ] else ...[
              _Line(
                label: l10n.shelterSafeZone,
                value: '${shelter.kind.safeRadiusM.round()} m',
                colours: colours,
              ),
              _Line(
                label: l10n.shelterSleep,
                value: '${(shelter.sleepRate * 100).round()}%',
                colours: colours,
              ),
              _Line(
                label: l10n.shelterStorage,
                value:
                    '${shelter.storageKg.round()} kg · '
                    '${shelter.storageL.round()} l',
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
    required this.itemNameOf,
    required this.hasHammer,
    required this.hasMultitool,
    required this.away,
    required this.onBuild,
    required this.colours,
  });

  final Shelter shelter;
  final ShelterModule module;

  /// §2.1a.3: the player is not standing on the site.
  final bool away;
  final DateTime now;
  final Map<String, int> carried;
  final String Function(String) itemNameOf;
  final bool hasHammer;
  final bool hasMultitool;
  final VoidCallback onBuild;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final level = shelter.levelOf(module);
    final underway = shelter.building == module;
    final next = nextLevelOf(module, have: level);

    final missing = next == null
        ? const <String, int>{}
        : missingFor(next.materials, carried);
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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              moduleWhat(l10n, module),
              style: TextStyle(fontSize: 12, height: 1.35, color: colours.muted),
            ),

            if (underway) ...[
              const SizedBox(height: 8),
              Text(
                away
                    ? l10n.shelterWorkStopped
                    : l10n.shelterBuildingLeft(
                        _short(shelter.buildingLeft ?? Duration.zero),
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: away ? const Color(0xFFE8B33A) : colours.data,
                ),
              ),
            ] else if (next != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  for (final entry in next.materials.entries)
                    '${itemNameOf(entry.key)} ×${entry.value}',
                ].join(' · '),
                style: TextStyle(fontSize: 12, color: colours.text),
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

String moduleWhat(L10n l10n, ShelterModule module) => switch (module) {
  ShelterModule.storage => l10n.moduleStorageWhat,
  ShelterModule.workshop => l10n.moduleWorkshopWhat,
  ShelterModule.lounge => l10n.moduleLoungeWhat,
  ShelterModule.laboratory => l10n.moduleLaboratoryWhat,
};

/// Hours and minutes, which is how every time in §8 is quoted.
String _short(Duration time) {
  final hours = time.inHours;
  final minutes = time.inMinutes % 60;

  return hours <= 0 ? '$minutes min' : '$hours h $minutes min';
}
