/// What a circle on the map actually is (§6.5.6, §12).
///
/// ⚠️ **A red ring is a warning and not an explanation.** It says the ground is
/// hostile and nothing else — not how many are in there, not what it costs to
/// pull one down, and not that the wall grows back while nobody is on it.
///
/// Said the way every other sheet in this game says things: a label and a
/// number. §6.5.4 is a procedure, but a procedure written as a paragraph is a
/// paragraph nobody reads standing in a street at dusk.
library;

import 'package:flutter/material.dart';

import '../combat/enemy.dart';
import '../combat/hotspot.dart';
import '../l10n/app_localizations.dart';
import '../map/geometry.dart';
import 'combat_panel.dart' show enemyKindName;
import 'effects.dart';
import 'fonts.dart';
import 'hud.dart' show HudColors;
import 'units.dart';

Future<void> showHotspot(
  BuildContext context, {
  required Hotspot spot,
  required DateTime now,
  required double distanceM,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) =>
      HotspotSheet(spot: spot, now: now, distanceM: distanceM),
);

/// The same, found by the marker the player actually tapped.
///
/// ⚠️ The lookup belongs here rather than on the screen: which hotspot a
/// marker id names is a fact about how [MarkerKind.hotspot] markers are built,
/// and that is this file's business. A screen that had to know the shape of
/// the id would be a screen that breaks when the id changes.
Future<void> showHotspotFor(
  BuildContext context, {
  required List<Hotspot> hotspots,
  required String markerId,
  required GeoPoint standingAt,
  required DateTime now,
}) async {
  final spot = hotspots
      .where((each) => hotspotMarkerId(each) == markerId)
      .firstOrNull;
  if (spot == null) return;

  await showHotspot(
    context,
    spot: spot,
    now: now,
    distanceM: spot.centre.distanceTo(standingAt),
  );
}

/// The id a hotspot's marker carries, written once so the map and the tap
/// cannot disagree about it.
String hotspotMarkerId(Hotspot spot) => 'hotspot.${spot.id}';

class HotspotSheet extends StatelessWidget {
  const HotspotSheet({
    required this.spot,
    required this.now,
    required this.distanceM,
    super.key,
  });

  final Hotspot spot;
  final DateTime now;
  final double distanceM;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    final agitated = spot.isAgitatedAt(now);
    // §6.5.2: the bag is a hundred entries so the percentages come out exact.
    // What a player wants is the two or three sorts in it, not the arithmetic.
    final kinds = spot.compositionNow(now).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final (restLow, restHigh) = kRestAfterClearing;
    // §6.5.4: what agitation is worth, read off the table rather than written
    // down twice. The rows above already show the raised numbers; this says by
    // how much they are raised, which is the part that decides whether to run.
    final calm = levelRow(spot.level);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hotspotTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.hotspotLevelOf(spot.level, kHotspotLevels.length),
                style: TextStyle(
                  fontSize: 14,
                  color: colours.data,
                  fontFamily: kDataFont,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                l10n.hotspotWhat,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: colours.muted,
                ),
              ),

              const SizedBox(height: 16),

              // §6.5.4: the wall, first, because it is the number that moves
              // while the player is standing there doing something about it.
              _Bar(
                label: l10n.hotspotIntegrity,
                value: '${spot.integrity.round()} / ${spot.integrityMax}',
                fraction: spot.integrityFraction,
                colour: colours.data,
                colours: colours,
              ),

              const SizedBox(height: 12),
              _Line(
                label: l10n.hotspotEnemies,
                value: '${spot.enemyCapAt(now)}',
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotRespawn,
                value: remaining(spot.respawnAt(now)),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotComposition,
                value: effects([
                  for (final kind in kinds) enemyKindName(l10n, kind),
                ]),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotRadius,
                value: '${spot.radiusM.round()} m',
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotDistance,
                value: distanceM <= spot.radiusM
                    ? l10n.hotspotInside
                    : '${distanceM.round()} m',
                colours: colours,
              ),

              // §6.5.4: said loudly, because ten minutes of this is the one
              // window where withdrawing is the correct move and the interface
              // has to make that obvious while it is happening.
              if (agitated) ...[
                const SizedBox(height: 8),
                _Warning(
                  title: l10n.hotspotAgitated(
                    remaining(spot.agitatedUntil!.difference(now)),
                  ),
                  detail: effects([
                    l10n.hotspotAgitatedSorts,
                    l10n.hotspotAgitatedMore(
                      (spot.enemyCapAt(now) / calm.enemyCap * 100 - 100)
                          .round(),
                    ),
                    l10n.hotspotAgitatedRespawn(
                      (calm.respawn.inSeconds / spot.respawnAt(now).inSeconds)
                          .round(),
                    ),
                  ]),
                  colours: colours,
                ),
              ],

              const SizedBox(height: 18),
              Text(
                l10n.hotspotHowTo.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: colours.muted,
                ),
              ),
              const SizedBox(height: 8),

              // §6.5.4's whole trade, as numbers rather than a paragraph: a
              // body inside is worth twice one lured out, the wall costs a
              // level, the level costs ten minutes of something worse, and
              // everything comes back at five per cent an hour to anybody who
              // walks off half way through.
              _Line(
                label: l10n.hotspotKillInside,
                value: l10n.hotspotPoints(
                  killPoints(EnemyKind.walker, insideRadius: true),
                ),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotKillOutside,
                value: l10n.hotspotPoints(
                  killPoints(EnemyKind.walker, insideRadius: false),
                ),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotAtZero,
                value: l10n.hotspotAtZeroValue,
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotThen,
                value: l10n.hotspotThenValue(kAgitationLength.inMinutes),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotRegen,
                value: l10n.hotspotRegenValue(
                  (kIntegrityRegenPerHour * 100).round(),
                ),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotEscape,
                value: l10n.hotspotEscapeValue(kAgitationEscapeM.round()),
                colours: colours,
              ),
              _Line(
                label: l10n.hotspotCleared,
                value: l10n.hotspotClearedValue(
                  restLow.inHours,
                  restHigh.inHours,
                ),
                colours: colours,
              ),
            ],
          ),
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
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colours.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            color: colours.text,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.colour,
    required this.colours,
  });

  final String label;
  final String value;
  final double fraction;
  final Color colour;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colours.muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: colour,
              fontFamily: kDataFont,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      LinearProgressIndicator(
        value: fraction,
        minHeight: 5,
        backgroundColor: colours.muted.withValues(alpha: 0.25),
        color: colour,
      ),
    ],
  );
}

class _Warning extends StatelessWidget {
  const _Warning({
    required this.title,
    required this.detail,
    required this.colours,
  });

  final String title;
  final String detail;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: colours.alert.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_outlined, size: 16, color: colours.alert),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: colours.alert)),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: colours.alert.withValues(alpha: 0.8),
                  fontFamily: kDataFont,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
