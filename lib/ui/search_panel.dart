/// The searching controls, at the bottom of the map (§10.2, §19.3).
///
/// One panel with two jobs, because from the player's side they are one
/// decision: what to spend the next half-minute to three minutes on. Standing
/// still is the cost of both, so both live where a thumb already is.
///
/// While something is running the bar for it lives at the *top* of the screen,
/// under the stats, and not here — found on a phone: a bite of stew taken with
/// a Walker in the sights put the progress bar underneath the combat panel,
/// so the one thing the player was waiting on was the one thing they could not
/// see. See [ActionProgress].
library;

import 'package:flutter/material.dart';

import 'fonts.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';
import '../combat/attachment.dart';
import '../combat/magazine_item.dart';
import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import 'status_notes.dart';
import '../loot/loot_table.dart';
import '../loot/obstacle.dart';
import '../loot/search.dart';
import 'hud.dart' show HudColors;

class SearchPanel extends StatelessWidget {
  const SearchPanel({
    required this.search,
    required this.targetName,
    required this.canSearchHere,
    required this.searchUnitsLeft,
    this.searchTimes = const {},
    required this.onSearchArea,
    required this.onSearchHere,
    required this.onCancel,
    this.barrier,
    this.carried = const {},
    this.toolName,
    this.onBreach,
    this.droppedLabel,
    this.onTakeDropped,
    this.onFireAway,
    this.weapon,
    this.rounds,
    this.capacity,
    this.onReload,
    this.fittings = const [],
    this.reload,
    super.key,
  });

  /// §5.3: what is in hand, or null with empty hands.
  final String? weapon;

  /// What is in it, and what it would hold with the magazine currently fitted.
  /// Null capacity means a magazine-fed weapon with no magazine in it.
  final int? rounds;
  final int? capacity;

  /// §5.5.4: swapping a magazine, or feeding a revolver.
  final VoidCallback? onReload;

  /// §5.6.3: what is on the weapon, one line per place.
  final List<WeaponFitting> fittings;

  /// A magazine change under way, for the bar. Null when nothing is running.
  final ReloadProgress? reload;

  /// The search in progress, or null when the player is free.
  final Search? search;

  /// What is within reach, named. Null when nothing is.
  final String? targetName;

  /// False when the nearest place is too far, or already emptied.
  final bool canSearchHere;

  /// §10.3.5: how much of the place in reach is left to turn over, out of
  /// [kSearchBudget]. Decides which depths are still worth offering.
  final int searchUnitsLeft;

  /// §10.3.5: how long each depth takes at the place in reach. A bin is not a
  /// supermarket, and the caption is where the player finds that out.
  final Map<SearchDepth, Duration> searchTimes;

  final VoidCallback onSearchArea;
  final void Function(SearchDepth depth) onSearchHere;

  /// Kept for the callers that still hand it in; the bar that uses it now
  /// lives in [ActionProgress].
  final VoidCallback onCancel;

  /// §19.3: what shuts the place in reach, or null when it is open or there is
  /// nothing there.
  final Barrier? barrier;

  /// Item ids the player has, which is what decides the ways in.
  final Set<String> carried;

  /// §12: jak się nazywa przedmiot o tym id. Bez tego panel mówi „podważ",
  /// a gracz i tak musi zgadnąć, czym.
  final String Function(String itemId)? toolName;

  final void Function(BarrierBreach breach)? onBreach;

  /// §4.8: a pile the player left within arm's reach, named for the button.
  /// Null when there is nothing at their feet.
  final String? droppedLabel;

  final VoidCallback? onTakeDropped;

  /// §5.6.2: a round into the air, with nothing in the sights.
  ///
  /// Not a wasted bullet — a decision. §5.6.2 sends everything that hears it
  /// to *where the sound was*, so a shot fired from a corner and then left
  /// behind is the one tool the player has for moving a street. Null with an
  /// empty or unloaded weapon.
  final VoidCallback? onFireAway;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final running = search;

    // A pass already under way rules out starting another one; the glyphs
    // stay where they are and go grey, so the panel does not reshuffle under
    // a thumb halfway to a button.
    final busy = running != null && running.isRunning;

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⚠️ §5.3's state, on the screen that is always there.
              //
              // The weapon used to appear only beside a target, so there was
              // nowhere to see what was in it and nowhere to reload — and
              // §4.2's whole point is that a magazine is filled and swapped
              // *before* anything is in front of you. A panel that only exists
              // during a fight is a panel that arrives too late to prepare on.
              if (weapon != null)
                _WeaponRow(
                  name: weapon!,
                  rounds: rounds,
                  capacity: capacity,
                  onReload: busy ? null : onReload,
                  fittings: fittings,
                  reload: reload,
                  colours: colours,
                  l10n: l10n,
                ),

              _Actions(
                targetName: targetName,
                canSearchHere: canSearchHere,
                searchUnitsLeft: searchUnitsLeft,
                barrier: canSearchHere ? barrier : null,
                searchTimes: searchTimes,
                carried: carried,
                toolName: toolName,
                onBreach: busy ? null : onBreach,
                onSearchArea: busy ? null : onSearchArea,
                onSearchHere: busy ? null : onSearchHere,
                onTakeDropped: busy ? null : onTakeDropped,
                onFireAway: busy ? null : onFireAway,
                droppedLabel: droppedLabel,
                colours: colours,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What is running right now, at the top of the screen (§10.2, §4.6).
///
/// Under the stats bar rather than over the thumb, because it is a thing to
/// watch rather than a thing to press — and because the bottom of the map
/// belongs to whatever the player is deciding next, which during a long search
/// is quite often a fight.
class ActionProgress extends StatelessWidget {
  const ActionProgress({
    required this.search,
    required this.onCancel,
    super.key,
  });

  final Search search;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final seconds = search.remaining.inSeconds;

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    search.usingLabel ??
                        (search.isArea
                            ? l10n.searchAreaRunning
                            : l10n.searchHere),
                    style: TextStyle(fontSize: 13, color: colours.text),
                  ),
                ),
                Text(
                  '$seconds s',
                  style: TextStyle(
                    fontSize: 13,
                    color: colours.data,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: onCancel, child: Text(l10n.searchCancel)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: search.progress,
              minHeight: 4,
              backgroundColor: colours.muted.withValues(alpha: 0.25),
              color: colours.data,
            ),
            const SizedBox(height: 6),
            Text(
              // §19.3, §5.6: an object search is heard from eighty metres. Said
              // plainly, because it is the reason to choose the shorter one.
              // Eating makes no noise worth mentioning, so it says nothing.
              search.isArea || search.isUse ? '' : l10n.searchNoise,
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the player can do standing exactly here (§10.2, §19.3, §4.8).
///
/// One row, on the right where a thumb is. Nothing in it is a control that
/// cannot be used: an icon appears when the thing it acts on is within reach
/// and is simply absent otherwise, which makes the panel a list of what is
/// possible rather than a menu to read. Reconnaissance is the exception and is
/// always there, because §10.2.1 gives it no cooldown and no target - it is
/// what a player does when nothing else is offered.
///
/// The quiet way through a barrier comes before the loud one. The loud one is
/// always available and always obvious; somebody deciding in the dark should
/// meet the careful option first.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.targetName,
    required this.canSearchHere,
    required this.searchUnitsLeft,
    required this.searchTimes,
    required this.barrier,
    required this.carried,
    required this.toolName,
    required this.onBreach,
    required this.onSearchArea,
    required this.onSearchHere,
    required this.onTakeDropped,
    required this.onFireAway,
    required this.droppedLabel,
    required this.colours,
    required this.l10n,
  });

  final String? targetName;
  final bool canSearchHere;

  /// §10.3.5: what is left of this place, out of [kSearchBudget].
  final int searchUnitsLeft;

  /// §10.3.5: what each depth costs in seconds, at this place.
  final Map<SearchDepth, Duration> searchTimes;

  final Barrier? barrier;
  final Set<String> carried;
  final String Function(String itemId)? toolName;
  final void Function(BarrierBreach)? onBreach;
  final VoidCallback? onSearchArea;
  final void Function(SearchDepth)? onSearchHere;

  /// §4.8: opens the heap at the player's feet. Null when there is none.
  final VoidCallback? onTakeDropped;

  /// §5.6.2: a round into the air, to move a street.
  final VoidCallback? onFireAway;

  /// What is nearest in that heap. Never drawn - the list says it, and saying
  /// it twice cost a line of the map. It names the button for a long press and
  /// for the screen reader (§12).
  final String? droppedLabel;

  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final shut = barrier;
    final ways = shut == null
        ? const <BarrierBreach>[]
        : shut.breachesWith(carried);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (targetName != null || shut != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              [
                ?targetName,
                if (shut != null) _barrierName(l10n, shut),
              ].join(' \u00b7 '),
              style: TextStyle(fontSize: 12, color: colours.text),
            ),
          ),

        if (shut != null && ways.isEmpty)
          // Only ever a padlock. §19.3 names it as the barrier that needs a
          // tool, and softening that would make every tool optional. Said in
          // words, because a missing icon explains nothing.
          Text(
            l10n.breachNoTool,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE8B33A)),
          ),

        // §19.3: a way in comes before anything to do inside — i wierszem, nie
        // ikoną. Zgłoszone z terenu: trzy glify z sekundami pod spodem mówiły,
        // że **coś** kosztuje dwanaście sekund, ale nie mówiły czym się to
        // robi. Gracz z siekierą i bez łomu widział ten sam klucz francuski.
        for (final way in ways)
          _BreachWay(
            barrier: shut!,
            way: way,
            toolId: way.toolWith(carried),
            toolName: toolName,
            colours: colours,
            l10n: l10n,
            onPressed: onBreach == null ? null : () => onBreach!(way),
          ),

        // Wrapped, not a row: four glyphs with their times under them do not
        // fit across a phone, and a clipped control is one nobody can press.
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 4,
          children: [
            IconButton(
              onPressed: onSearchArea,
              icon: const Icon(Icons.travel_explore),
              tooltip: l10n.searchArea,
              color: colours.text,
            ),

            // The three depths of §10.3.5, all three at once. Hiding the slow
            // ones behind a menu would hide the decision - and one with no
            // room left in the place is greyed rather than removed, so a
            // player who searched thoroughly twice can see why the third pass
            // is gone.
            if (shut == null && canSearchHere)
              for (final depth in SearchDepth.values)
                _ActionIcon(
                  icon: _depthIcon(depth),
                  caption:
                      '${(searchTimes[depth] ?? Duration(seconds: depth.seconds)).inSeconds} s',
                  tooltip: _depthName(l10n, depth),
                  colours: colours,
                  onPressed:
                      onSearchHere != null && depth.cost <= searchUnitsLeft
                      ? () => onSearchHere!(depth)
                      : null,
                ),

            // §5.6.2: a shot with nothing in the sights. The whole of the
            // noise system is that they walk to where the sound was, and this
            // is the only way to use that on purpose.
            if (onFireAway != null)
              IconButton(
                onPressed: onFireAway,
                icon: const Icon(Icons.campaign_outlined),
                tooltip: l10n.combatFireAway,
                color: colours.alert,
              ),

            if (onTakeDropped != null)
              // A hand, because the act is reaching down for something. The
              // pack said where it ends up rather than what the button does,
              // which is one step too far along for a glyph.
              IconButton(
                onPressed: onTakeDropped,
                icon: const Icon(Icons.back_hand_outlined),
                tooltip: droppedLabel == null
                    ? l10n.droppedTake
                    : '${l10n.droppedTake} \u00b7 $droppedLabel',
                color: colours.text,
              ),
          ],
        ),
      ],
    );
  }
}

/// Jedna droga przez barierę: czym, jak długo i jak głośno (§19.3, §12).
///
/// ⚠️ **Nazwa narzędzia jest tu treścią, nie ozdobą.** Drzwi podważa łom *albo*
/// siekiera, a kłódkę tnie przecinak — do tej pory panel pokazywał jedną ikonę
/// „podważ" dla wszystkich trzech, więc gracz nie wiedział, co mu zejdzie i
/// czego mu brakuje. Pokazywane jest to narzędzie, którym gra naprawdę otworzy:
/// pierwsze z `toolIds`, które gracz ma — ta sama kolejność, którą zużywa
/// `InventoryController.useTool`.
///
/// Rozwijane nie jest, choć takie było zgłoszenie: dróg jest najwyżej trzy, a
/// zwinięta lista chowa dokładnie tę decyzję, dla której §19.3 stawia bariery —
/// szybko i głośno przeciw wolno i cicho. Jeden dotyk zamiast dwóch.
class _BreachWay extends StatelessWidget {
  const _BreachWay({
    required this.barrier,
    required this.way,
    required this.toolId,
    required this.toolName,
    required this.colours,
    required this.l10n,
    required this.onPressed,
  });

  final Barrier barrier;
  final BarrierBreach way;

  /// Czym gracz tędy wejdzie, albo null — gołymi rękami.
  final String? toolId;

  final String Function(String itemId)? toolName;
  final HudColors colours;
  final L10n l10n;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final named = toolId == null ? null : toolName?.call(toolId!);

    return Semantics(
      button: true,
      // §12: czytnik ekranu dostaje czasownik, którego wiersz już nie pisze —
      // „podważ łomem", a nie samo „łom".
      label: effects([
        _verb(l10n, barrier, way),
        named ?? l10n.breachBareHands,
      ]),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                _wayIcon(barrier, way),
                size: 18,
                color: onPressed == null ? colours.muted : colours.text,
              ),
              const SizedBox(width: 8),

              // Czym. Gołe ręce też są odpowiedzią — i tą, która boli.
              Expanded(
                child: Text(
                  named ?? l10n.breachBareHands,
                  style: TextStyle(
                    fontSize: 12,
                    color: onPressed == null ? colours.muted : colours.text,
                  ),
                ),
              ),

              // Ile to kosztuje, w jednostkach gracza: sekundy i metry hałasu.
              // §19.3 nie ma innej treści niż te dwie liczby.
              Text(
                effects([
                  '${way.seconds} s',
                  l10n.breachNoise(way.noiseM.round()),
                ]),
                style: TextStyle(fontSize: 11, color: colours.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _barrierName(L10n l10n, Barrier barrier) => switch (barrier) {
  Barrier.door => l10n.barrierDoor,
  Barrier.padlock => l10n.barrierPadlock,
  Barrier.window => l10n.barrierWindow,
};

/// Picks, a lever, or shoulders - which is exactly what the three ways are.
IconData _wayIcon(Barrier barrier, BarrierBreach way) {
  if (identical(way, barrier.quiet)) return Icons.vpn_key_outlined;
  if (identical(way, barrier.pry)) return Icons.construction_outlined;
  return Icons.front_hand_outlined;
}

String _verb(L10n l10n, Barrier barrier, BarrierBreach way) {
  if (identical(way, barrier.quiet)) return l10n.breachPick;
  if (identical(way, barrier.pry)) return l10n.breachPry;
  return l10n.breachForce;
}

/// One thing the player can do here: a glyph, and under it what it costs.
///
/// A glyph alone would hide the decision. §10.3.5 and §19.3 are both choices
/// between time and attention — thirty seconds or a hundred and eighty, twenty
/// metres of noise or a hundred and fifty — so the seconds stay on the button
/// and the icon only says which kind of thing it is.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.caption,
    required this.tooltip,
    required this.onPressed,
    required this.colours,
  });

  final IconData icon;

  /// The cost, in the player's units: seconds, and metres of noise.
  final String caption;

  /// What it is, for a long press and for the screen reader (§12).
  final String tooltip;

  /// Null where the place has nothing left for a pass this deep, or no way
  /// through this barrier with what is being carried.
  final VoidCallback? onPressed;

  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final off = onPressed == null;

    return Semantics(
      button: true,
      enabled: !off,
      label: '$tooltip, $caption',
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: off
                      ? colours.muted.withValues(alpha: 0.4)
                      : colours.text,
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 10,
                    color: off
                        ? colours.muted.withValues(alpha: 0.4)
                        : colours.muted,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One glass, then a glass over shelves, then a glass over a whole page:
/// the same act, done to more of the place each time (§10.3.5).
IconData _depthIcon(SearchDepth depth) => switch (depth) {
  SearchDepth.shallow => Icons.search,
  SearchDepth.thorough => Icons.manage_search,
  SearchDepth.deep => Icons.pageview_outlined,
};

String _depthName(L10n l10n, SearchDepth depth) => switch (depth) {
  SearchDepth.shallow => l10n.searchShallow,
  SearchDepth.thorough => l10n.searchThorough,
  SearchDepth.deep => l10n.searchDeep,
};

/// §5.3: the weapon in hand, and what is in it.
///
/// One line, because it is a readout rather than a screen: the name, the
/// rounds, and the one button that changes them.
/// One part on the weapon, as the HUD says it (§5.6.3).
///
/// The place comes first because that is what a player is choosing between:
/// there is one barrel and one rail, and knowing what is on each is the whole
/// question. The effect is in the part's own units — minutes of angle,
/// decibels, metres — so a line reads without a legend.
/// §5.6.3, §5.3: co siedzi na broni w ręce, gotowe do wypisania.
///
/// Posortowane po miejscu, nie po kolejności zakładania: gniazda czyta się
/// zawsze w tej samej kolejności, więc lista, która skacze, jest listą, którą
/// trzeba czytać od nowa.
List<WeaponFitting> weaponFittings({
  required CarriedItem? line,
  required ItemCatalogue? catalogue,
  required L10n l10n,
  required String Function(ItemDefinition item) nameOf,
}) {
  if (line == null || catalogue == null) return const [];

  final fitted = <(AttachmentSlot, WeaponFitting)>[];
  for (final id in line.attachments) {
    final part = catalogue[id];
    if (part == null) continue;

    final place = slotOf(part) ?? AttachmentSlot.rail;
    final magazine = Magazine.of(part);

    fitted.add((
      place,
      WeaponFitting(
        place: attachmentPlaceName(l10n, place),
        name: nameOf(part),
        // §5.3: magazynek mówi, co w nim jest — to jedyna liczba warta
        // spojrzenia przed wyjściem zza rogu.
        effect: attachmentEffect(
          part,
          rounds: magazine == null ? null : (line.rounds ?? 0),
          capacity: magazine?.capacity,
        ),
      ),
    ));
  }

  fitted.sort((a, b) => a.$1.index.compareTo(b.$1.index));
  return [for (final entry in fitted) entry.$2];
}

class WeaponFitting {
  const WeaponFitting({required this.place, required this.name, this.effect});

  final String place;
  final String name;
  final String? effect;
}

/// A magazine change under way (§5.5.4).
class ReloadProgress {
  const ReloadProgress({required this.label, required this.value});

  final String label;
  final double value;
}

class _WeaponRow extends StatelessWidget {
  const _WeaponRow({
    required this.name,
    required this.rounds,
    required this.capacity,
    required this.onReload,
    required this.fittings,
    required this.reload,
    required this.colours,
    required this.l10n,
  });

  final String name;
  final int? rounds;
  final int? capacity;
  final VoidCallback? onReload;
  final List<WeaponFitting> fittings;
  final ReloadProgress? reload;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // ⚠️ No capacity means no magazine, which is a different sentence from
    // "nought rounds" and the one a player needs: a rifle with nothing in it
    // is waiting for a magazine, not broken.
    final empty = (rounds ?? 0) <= 0;

    final running = reload;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                size: 14,
                color: empty ? colours.alert : colours.data,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colours.text),
                ),
              ),
              Text(
                capacity == null
                    ? l10n.reloadNoMagazine
                    : '${rounds ?? 0} / $capacity',
                style: TextStyle(
                  fontSize: 12,
                  color: empty ? colours.alert : colours.muted,
                  fontFamily: capacity == null ? null : kDataFont,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (onReload != null && running == null)
                _RowReload(onPressed: onReload!, colours: colours, l10n: l10n),
            ],
          ),

          // ⚠️ The bar for §5.5.4's seconds, on the screen the player is
          // actually looking at. Pressing reload used to change nothing
          // visible at all: the only sign it had worked was the count moving
          // three and a half seconds later, and indoors it never did.
          if (running != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    running.label,
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            LinearProgressIndicator(
              value: running.value,
              minHeight: 3,
              backgroundColor: colours.muted.withValues(alpha: 0.25),
              color: colours.data,
            ),
          ],

          // §5.6.3: one line per place, so what is bolted on is readable
          // without opening anything. A part that changes nothing a player can
          // feel says only its name.
          for (final fitting in fittings) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const SizedBox(width: 20),
                Text(
                  fitting.place.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    color: colours.muted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fitting.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colours.text),
                  ),
                ),
                if (fitting.effect != null)
                  Text(
                    fitting.effect!,
                    style: TextStyle(
                      fontSize: 11,
                      color: colours.data,
                      fontFamily: kDataFont,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RowReload extends StatelessWidget {
  const _RowReload({
    required this.onPressed,
    required this.colours,
    required this.l10n,
  });

  final VoidCallback onPressed;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: const Icon(Icons.autorenew, size: 18),
    tooltip: l10n.combatReload,
    color: colours.data,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.symmetric(horizontal: 6),
  );
}
