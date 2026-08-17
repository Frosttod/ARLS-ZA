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
import '../map/geometry.dart';
import '../shelter/recipes.dart';
import '../shelter/shelter.dart';
import 'hud.dart' show HudColors;

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
    required this.onCancelBuild,
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

  /// §8.3: gives up on whatever is going up. Asked about first, because the
  /// materials are already in the walls and the work starts again from zero.
  final void Function(Shelter place) onCancelBuild;

  /// §8.5.2: hotspot centres, which a camp may not sit inside.
  final List<GeoPoint> hotspots;

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  /// §8.3: the counters are the whole content of this screen while something
  /// is going up, and a screen whose only content is a number that never moves
  /// reads as broken.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Shelter? _main(List<Shelter> shelters) =>
      shelters.where((s) => s.kind == ShelterKind.main).firstOrNull;

  List<Shelter> _camps(List<Shelter> shelters) =>
      [for (final s in shelters) if (s.kind == ShelterKind.camp) s];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<Shelter>>(
    valueListenable: widget.shelters,
    builder: (context, shelters, _) =>
        ValueListenableBuilder<GeoPoint?>(
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
            if (shelter.isReadyAt(now))
              for (final module in ShelterModule.values)
                _ModuleRow(
                  shelter: shelter,
                  module: module,
                  now: now,
                  carried: widget.carried,
                  itemNameOf: widget.itemNameOf,
                  hasHammer: widget.hasHammer,
                  hasMultitool: widget.hasMultitool,
                  // §2.1a.3: nailing shelves up from the other side of town is
                  // not a thing, so the offer is refused here and says why.
                  away: at == null || !shelter.atSite(at),
                  onBuild: () => widget.onBuildModule(module),
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
    required this.onCancel,
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

  /// §8.3: gives up on the level going up right now.
  final VoidCallback onCancel;

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

/// Hours and minutes, which is how every time in §8 is quoted — and seconds
/// once there is under an hour left.
///
/// A counter reading "12 min" for sixty seconds at a stretch looks stopped,
/// and this screen is watched precisely when somebody is wondering whether it
/// is running at all.
String _short(Duration time) {
  final hours = time.inHours;
  final minutes = time.inMinutes % 60;
  final seconds = time.inSeconds % 60;

  if (hours > 0) return '$hours h $minutes min';
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// What is going up right now, under the stats bar on the map (§8.3).
///
/// The same slot the tin of stew uses, for the same reason: it is the thing
/// the player is waiting on, and the bottom of the screen belongs to whatever
/// they are deciding next. Only while they are standing on the site — off it
/// the work is not happening, and a bar that crept along in a bus would be a
/// lie about the one rule this system has.
class BuildProgress extends StatelessWidget {
  const BuildProgress({required this.shelter, required this.now, super.key});

  final Shelter shelter;
  final DateTime now;

  /// The bar worth drawing here, or null when nothing is going up.
  static BuildProgress? of(List<Shelter> shelters, GeoPoint? at, DateTime now) {
    if (at == null) return null;

    for (final place in shelters) {
      if (!place.atSite(at)) continue;
      if (!place.isReadyAt(now) || place.building != null) {
        return BuildProgress(shelter: place, now: now);
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
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
