/// What is known about a place before walking to it (§10, §19.3).
///
/// A yellow dot on a map says "something is here" and nothing else, so every
/// dot is worth the same walk — which means none of them is a decision. What a
/// player standing in a street can actually tell from three hundred metres is
/// what kind of building it is, and therefore what kind of thing is in it;
/// whether the door is hanging open; and whether they have already been.
///
/// So that is what this shows, and no more: the kinds of thing the table can
/// give, never the roll itself. Naming the contents in advance would turn the
/// walk into a shopping trip.
library;

import 'package:flutter/material.dart';

import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../l10n/app_localizations.dart';
import '../loot/loot_spawner.dart';
import '../loot/loot_table.dart';
import '../loot/obstacle.dart';
import 'hud.dart' show HudColors;
import 'inventory_screen.dart' show kindName;

Future<void> showPlaceDetails(
  BuildContext context, {
  required LootBox box,
  required LootTable? table,
  required double distanceM,
  required ItemCatalogue catalogue,
  required DateTime now,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);

    final kinds = _kindsIn(table, catalogue);
    final barrier = box.isOpen ? null : table?.barrier;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              box.name ?? l10n.mapMarkerLoot,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colours.text,
              ),
            ),
            const SizedBox(height: 12),

            _Line(
              label: l10n.placeDistance,
              value: '${distanceM.round()} m',
              colours: colours,
            ),
            _Line(
              label: l10n.placeWayIn,
              value: barrier == null
                  ? l10n.placeOpen
                  : _barrierName(l10n, barrier),
              colours: colours,
            ),
            _Line(
              label: l10n.placeSearched,
              value: _searchedState(l10n, box, now),
              colours: colours,
            ),
            // §10.3.5: which passes the place still has room for. "67% left"
            // is a number; "a quick look or a thorough one, not a deep one" is
            // the decision itself.
            _Line(
              label: l10n.placeCanStill,
              value: _stillFits(l10n, box, now),
              colours: colours,
            ),

            if (kinds.isNotEmpty)
              _Line(
                label: l10n.placeHolds,
                value: kinds.map((kind) => kindName(l10n, kind)).join(', '),
                colours: colours,
              ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.noteClose),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// What kinds of thing this table can give, in the order the file lists them.
///
/// Kinds, not items: which tin of beans is in which shop is what the walk is
/// for. That a pharmacy holds medicine and a hardware shop holds tools is
/// something anybody could tell from the street.
List<ItemKind> _kindsIn(LootTable? table, ItemCatalogue catalogue) {
  if (table == null) return const [];

  final kinds = <ItemKind>[];
  for (final entry in table.entries) {
    final kind = catalogue[entry.itemId]?.kind;
    if (kind != null && !kinds.contains(kind)) kinds.add(kind);
  }
  return kinds;
}

/// How much of the place is left, in the words a player would use.
String _searchedState(L10n l10n, LootBox box, DateTime now) {
  if (!box.isActiveAt(now)) {
    final at = box.respawnAt;
    final hours = at == null ? 0 : at.difference(now).inHours;
    return l10n.placeStripped(hours < 1 ? 1 : hours);
  }

  if (box.searchUnits <= 0) return l10n.placeUntouched;
  return l10n.placePartly((box.searchUnitsLeft / kSearchBudget * 100).round());
}

/// What passes are left in this place, in the player's own units (§10.3.5).
String _stillFits(L10n l10n, LootBox box, DateTime now) {
  if (!box.isActiveAt(now)) return l10n.placeNothingLeft;

  final left = [
    for (final depth in SearchDepth.values)
      // The label already carries its own seconds (§10.3.5).
      if (box.canSearchAt(depth)) _depthName(l10n, depth),
  ];

  return left.isEmpty ? l10n.placeNothingLeft : left.join(', ');
}

String _depthName(L10n l10n, SearchDepth depth) => switch (depth) {
  SearchDepth.shallow => l10n.searchShallow,
  SearchDepth.thorough => l10n.searchThorough,
  SearchDepth.deep => l10n.searchDeep,
};

String _barrierName(L10n l10n, Barrier barrier) => switch (barrier) {
  Barrier.door => l10n.barrierDoor,
  Barrier.padlock => l10n.barrierPadlock,
  Barrier.window => l10n.barrierWindow,
};

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
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colours.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: colours.text),
          ),
        ),
      ],
    ),
  );
}
