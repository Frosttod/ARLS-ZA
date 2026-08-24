/// What is left where something went down (§10.3, §12).
///
/// The sheet exists because the map deliberately does not say what is in the
/// pockets. A skull two hundred metres off is a fact — something died there —
/// and the contents are a reason to walk over, not a thing to read from here.
/// So this says what it was, how far it is, and whether anybody has been
/// through it already, and it offers the one action at arm's length.
library;

import 'package:flutter/material.dart';

import '../combat/remains.dart';
import '../l10n/app_localizations.dart';
import '../loot/search.dart' show kStillnessM;
import '../map/geometry.dart';
import 'combat_panel.dart' show enemyKindName;
import 'effects.dart';
import 'hud.dart' show HudColors;

Future<void> showRemains(
  BuildContext context, {
  required String kindName,
  required double distanceM,
  required bool searched,
  required VoidCallback? onSearch,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => RemainsSheet(
    kindName: kindName,
    distanceM: distanceM,
    searched: searched,
    onSearch: onSearch,
  ),
);

/// §10.3: the same, found by the marker the player actually tapped.
///
/// ⚠️ The lookup and the reach rule belong here rather than on the screen. How
/// a body's marker id is spelled is a fact about how these markers are made,
/// and how close is close enough to go through the pockets is §4.8's arm's
/// length — neither is something a screen should be holding a copy of.
Future<void> showRemainsFor(
  BuildContext context, {
  required List<Remains> bodies,
  required String markerId,
  required GeoPoint standingAt,
  required void Function(Remains body) onSearch,
}) async {
  final id = markerId.startsWith('remains.')
      ? markerId.substring('remains.'.length)
      : markerId;

  final body = bodies.where((each) => each.id == id).firstOrNull;
  if (body == null) return;

  final metres = body.position.distanceTo(standingAt);

  await showRemains(
    context,
    kindName: enemyKindName(L10n.of(context), body.kind),
    distanceM: metres,
    searched: body.searched,
    // §4.8: arm's length, and nothing offered from further than that.
    onSearch: body.searched || metres > kStillnessM
        ? null
        : () => onSearch(body),
  );
}

/// The id a body's marker carries, written once so the map and the tap cannot
/// disagree about it.
String remainsMarkerId(Remains body) => 'remains.${body.id}';

class RemainsSheet extends StatelessWidget {
  const RemainsSheet({
    required this.kindName,
    required this.distanceM,
    required this.searched,
    required this.onSearch,
    super.key,
  });

  final String kindName;
  final double distanceM;
  final bool searched;

  /// Null when it has already been turned out, or when it is out of reach —
  /// §4.8's arm's length, the same one a pile on the ground uses.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('☠', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effects([l10n.remainsTitle, kindName]),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colours.text,
                    ),
                  ),
                ),
                Text(
                  '${distanceM.round()} m',
                  style: TextStyle(fontSize: 13, color: colours.data),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              searched ? l10n.remainsEmptied : l10n.remainsUnsearched,
              style: TextStyle(fontSize: 13, height: 1.4, color: colours.muted),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonOk),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: onSearch == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onSearch!();
                          },
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(l10n.remainsSearch),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
