/// What a circle on the map actually is (§6.5.6, §12).
///
/// ⚠️ **A red ring is a warning and not an explanation.** It says the ground is
/// hostile and nothing else — not how hostile, not how many are in there, not
/// whether walking in is a fight or an afternoon, and above all not what to do
/// about it. §6.5.4's whole operation is a sequence a player has to be told
/// once: kill what it sends, watch the wall come down, survive ten minutes of
/// something worse, repeat.
///
/// So this is the only screen in the game that explains a mechanic in prose.
/// Everything else says what a thing is worth and lets the player work out the
/// rest, because everything else is a number they can compare. A hotspot is a
/// procedure, and a procedure nobody has been told is a wall.
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

              const SizedBox(height: 10),
              Text(
                l10n.hotspotWhat,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
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
                const SizedBox(height: 12),
                _Warning(
                  text: l10n.hotspotAgitated(
                    remaining(spot.agitatedUntil!.difference(now)),
                  ),
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
              const SizedBox(height: 6),
              Text(
                l10n.hotspotHowToBody(
                  killPoints(EnemyKind.walker, insideRadius: true),
                  killPoints(EnemyKind.walker, insideRadius: false),
                ),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: colours.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                effects([
                  l10n.hotspotEscape(kAgitationEscapeM.round()),
                  l10n.hotspotHealing((kIntegrityRegenPerHour * 100).round()),
                ]),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: colours.muted,
                ),
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
  const _Warning({required this.text, required this.colours});

  final String text;
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
          child: Text(
            text,
            style: TextStyle(fontSize: 12, height: 1.45, color: colours.alert),
          ),
        ),
      ],
    ),
  );
}
