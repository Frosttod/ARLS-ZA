/// The searching controls, at the bottom of the map (§10.2, §19.3).
///
/// One panel with two jobs, because from the player's side they are one
/// decision: what to spend the next half-minute to three minutes on. Standing
/// still is the cost of both, so both live where a thumb already is.
///
/// While a search runs the panel becomes the search: a bar, the time left, and
/// one way out. Nothing else on the map is worth reading during it, and §3.5
/// would rather the player looked up anyway.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
    required this.onSearchArea,
    required this.onSearchHere,
    required this.onCancel,
    this.barrier,
    this.carried = const {},
    this.onBreach,
    this.droppedLabel,
    this.onTakeDropped,
    super.key,
  });

  /// The search in progress, or null when the player is free.
  final Search? search;

  /// What is within reach, named. Null when nothing is.
  final String? targetName;

  /// False when the nearest place is too far, or already emptied.
  final bool canSearchHere;

  /// §10.3.5: how much of the place in reach is left to turn over, out of
  /// [kSearchBudget]. Decides which depths are still worth offering.
  final int searchUnitsLeft;

  final VoidCallback onSearchArea;
  final void Function(SearchDepth depth) onSearchHere;
  final VoidCallback onCancel;

  /// §19.3: what shuts the place in reach, or null when it is open or there is
  /// nothing there.
  final Barrier? barrier;

  /// Item ids the player has, which is what decides the ways in.
  final Set<String> carried;

  final void Function(BarrierBreach breach)? onBreach;

  /// §4.8: a pile the player left within arm's reach, named for the button.
  /// Null when there is nothing at their feet.
  final String? droppedLabel;

  final VoidCallback? onTakeDropped;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final running = search;

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: running != null && running.isRunning
              ? _Running(search: running, onCancel: onCancel, colours: colours)
              : barrier != null && canSearchHere
              ? _Barrier(
                  barrier: barrier!,
                  targetName: targetName,
                  carried: carried,
                  onBreach: onBreach,
                  onSearchArea: onSearchArea,
                  colours: colours,
                  l10n: l10n,
                )
              : _Choices(
                  targetName: targetName,
                  canSearchHere: canSearchHere,
                  searchUnitsLeft: searchUnitsLeft,
                  onSearchArea: onSearchArea,
                  onSearchHere: onSearchHere,
                  droppedLabel: droppedLabel,
                  onTakeDropped: onTakeDropped,
                  colours: colours,
                  l10n: l10n,
                ),
        ),
      ),
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({
    required this.search,
    required this.onCancel,
    required this.colours,
  });

  final Search search;
  final VoidCallback onCancel;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final seconds = search.remaining.inSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                search.usingLabel ??
                    (search.isArea ? l10n.searchAreaRunning : l10n.searchHere),
                style: TextStyle(fontSize: 13, color: colours.text),
              ),
            ),
            Text(
              '$seconds s',
              style: TextStyle(
                fontSize: 13,
                color: colours.data,
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
    );
  }
}

/// What shuts a place, and the ways through it (§19.3).
///
/// The quiet way is listed first where there is one. The loud way is always
/// available and always obvious; a player deciding in the dark should meet the
/// careful option before the impatient one.
class _Barrier extends StatelessWidget {
  const _Barrier({
    required this.barrier,
    required this.targetName,
    required this.carried,
    required this.onBreach,
    required this.onSearchArea,
    required this.colours,
    required this.l10n,
  });

  final Barrier barrier;
  final String? targetName;
  final Set<String> carried;
  final void Function(BarrierBreach)? onBreach;
  final VoidCallback onSearchArea;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final ways = barrier.breachesWith(carried);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          targetName == null
              ? _name(barrier)
              : '${targetName!} · ${_name(barrier)}',
          style: TextStyle(fontSize: 12, color: colours.text),
        ),
        const SizedBox(height: 2),
        if (ways.isEmpty)
          // Only ever a padlock. §19.3 names it as the barrier that needs a
          // tool, and softening that would make every tool optional.
          Text(
            l10n.breachNoTool,
            style: TextStyle(fontSize: 11, color: const Color(0xFFE8B33A)),
          ),
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
            for (final way in ways)
              _ActionIcon(
                icon: _wayIcon(way),
                // Seconds and metres of noise: §19.3's whole choice, and not
                // one an icon can carry on its own.
                caption:
                    '${way.seconds} s · ${l10n.breachNoise(way.noiseM.round())}',
                tooltip: _verb(way),
                colours: colours,
                onPressed: onBreach == null ? null : () => onBreach!(way),
              ),
          ],
        ),
      ],
    );
  }

  String _name(Barrier barrier) => switch (barrier) {
    Barrier.door => l10n.barrierDoor,
    Barrier.padlock => l10n.barrierPadlock,
    Barrier.window => l10n.barrierWindow,
  };

  /// Picks, a lever, or shoulders — which is exactly what the three ways are.
  IconData _wayIcon(BarrierBreach way) {
    if (identical(way, barrier.quiet)) return Icons.vpn_key_outlined;
    if (identical(way, barrier.pry)) return Icons.construction_outlined;
    return Icons.front_hand_outlined;
  }

  String _verb(BarrierBreach way) {
    if (identical(way, barrier.quiet)) return l10n.breachPick;
    if (identical(way, barrier.pry)) return l10n.breachPry;
    return l10n.breachForce;
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.targetName,
    required this.canSearchHere,
    required this.searchUnitsLeft,
    required this.onSearchArea,
    required this.onSearchHere,
    required this.droppedLabel,
    required this.onTakeDropped,
    required this.colours,
    required this.l10n,
  });

  final String? targetName;
  final bool canSearchHere;

  /// §10.3.5: what is left of this place, out of [kSearchBudget].
  final int searchUnitsLeft;

  final VoidCallback onSearchArea;
  final void Function(SearchDepth) onSearchHere;
  final String? droppedLabel;
  final VoidCallback? onTakeDropped;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (targetName != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            targetName!,
            style: TextStyle(fontSize: 12, color: colours.text),
          ),
        ),
      if (droppedLabel != null)
        // §4.8: what the player left here. Picking it up is instant — the time
        // was already spent deciding to put it down.
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.droppedHere}: $droppedLabel',
                  style: TextStyle(fontSize: 12, color: colours.muted),
                ),
              ),
              // Into the pack, which is what the act is. The name of what is
              // lying here stays in words beside it: a glyph can say "take",
              // never "take what".
              IconButton(
                onPressed: onTakeDropped,
                icon: const Icon(Icons.backpack_outlined),
                tooltip: l10n.droppedTake,
                color: colours.text,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      // Wrapped, not a row: four buttons with their times on them do not fit
      // across a phone, and a clipped control is a control nobody can press.
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 4,
        children: [
          // Reconnaissance is always available: §10.2.1 gives it no cooldown,
          // only a cost. Its own glyph, and never the plain glass: looking
          // around a district and turning over one shop are different acts,
          // and two controls that look alike would be pressed by mistake in
          // the dark.
          IconButton(
            onPressed: onSearchArea,
            icon: const Icon(Icons.travel_explore),
            tooltip: l10n.searchArea,
            color: colours.text,
          ),
          if (canSearchHere)
            // The three depths of §10.3.5, all three on screen at once. Hiding
            // the slow ones behind a menu would hide the decision.
            // A depth with no room left in the place is shown and refused,
            // not hidden: a player who searched thoroughly twice should see
            // why the third pass is gone.
            ...[
              for (final depth in SearchDepth.values)
                _ActionIcon(
                  icon: _depthIcon(depth),
                  caption: '${depth.seconds} s',
                  tooltip: _depthName(l10n, depth),
                  colours: colours,
                  onPressed: depth.cost <= searchUnitsLeft
                      ? () => onSearchHere(depth)
                      : null,
                ),
            ],
        ],
      ),
    ],
  );
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
