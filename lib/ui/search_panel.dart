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
    required this.onSearchArea,
    required this.onSearchHere,
    required this.onCancel,
    this.barrier,
    this.carried = const {},
    this.onBreach,
    super.key,
  });

  /// The search in progress, or null when the player is free.
  final Search? search;

  /// What is within reach, named. Null when nothing is.
  final String? targetName;

  /// False when the nearest place is too far, or already emptied.
  final bool canSearchHere;

  final VoidCallback onSearchArea;
  final void Function(SearchDepth depth) onSearchHere;
  final VoidCallback onCancel;

  /// §19.3: what shuts the place in reach, or null when it is open or there is
  /// nothing there.
  final Barrier? barrier;

  /// Item ids the player has, which is what decides the ways in.
  final Set<String> carried;

  final void Function(BarrierBreach breach)? onBreach;

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
                  onSearchArea: onSearchArea,
                  onSearchHere: onSearchHere,
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
                search.isArea ? l10n.searchAreaRunning : l10n.searchHere,
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
          search.isArea ? '' : l10n.searchNoise,
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
        Row(
          children: [
            TextButton(onPressed: onSearchArea, child: Text(l10n.searchArea)),
            const Spacer(),
            for (final way in ways)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TextButton(
                  onPressed: onBreach == null ? null : () => onBreach!(way),
                  child: Text(
                    '${_verb(way)}  ${way.seconds} s · '
                    '${l10n.breachNoise(way.noiseM.round())}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
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
    required this.onSearchArea,
    required this.onSearchHere,
    required this.colours,
    required this.l10n,
  });

  final String? targetName;
  final bool canSearchHere;
  final VoidCallback onSearchArea;
  final void Function(SearchDepth) onSearchHere;
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
      Row(
        children: [
          // Reconnaissance is always available: §10.2.1 gives it no cooldown,
          // only a cost.
          TextButton(onPressed: onSearchArea, child: Text(l10n.searchArea)),
          const Spacer(),
          if (canSearchHere)
            // The three depths of §10.3.5, all three on screen at once. Hiding
            // the slow ones behind a menu would hide the decision.
            ...[
              _DepthButton(
                label: l10n.searchShallow,
                onPressed: () => onSearchHere(SearchDepth.shallow),
              ),
              _DepthButton(
                label: l10n.searchThorough,
                onPressed: () => onSearchHere(SearchDepth.thorough),
              ),
              _DepthButton(
                label: l10n.searchDeep,
                onPressed: () => onSearchHere(SearchDepth.deep),
              ),
            ],
        ],
      ),
    ],
  );
}

class _DepthButton extends StatelessWidget {
  const _DepthButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: TextButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    ),
  );
}
