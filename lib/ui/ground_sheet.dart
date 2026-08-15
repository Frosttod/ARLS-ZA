/// What is lying within reach, and which of it to pick up (§4.8).
///
/// A player standing where they emptied their pack has a heap at their feet,
/// and the panel could only ever offer them the nearest thing in it. Picking a
/// rifle out of that heap meant taking six bandages first, which is not a
/// decision — it is a queue.
///
/// The list is live: it is a pushed route over a game that keeps running, so
/// it reads the notifier rather than a copy of it. A screen that shows what
/// was on the ground when it opened is the same bug three times over now.
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../l10n/app_localizations.dart';
import '../loot/dropped_items.dart';
import '../map/geometry.dart';
import 'hud.dart' show HudColors;

Future<void> showGroundItems(
  BuildContext context, {
  required ValueListenable<List<DroppedItem>> dropped,
  required ValueListenable<GeoPoint?> at,
  required double reachM,
  required ItemCatalogue catalogue,
  required ItemNames names,
  required void Function(GroundPile pile) onTake,
  void Function(GroundPile pile)? onDetails,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final language = Localizations.localeOf(context).languageCode;

    String nameOf(String itemId) {
      final definition = catalogue[itemId];
      if (definition == null) return itemId;
      return definition.name.resolve(
        language: language,
        lookup: names.forLanguage(language),
      );
    }

    return SafeArea(
      child: ValueListenableBuilder<List<DroppedItem>>(
        valueListenable: dropped,
        builder: (context, items, _) => ValueListenableBuilder<GeoPoint?>(
          valueListenable: at,
          builder: (context, position, _) {
            final piles = position == null
                ? const <GroundPile>[]
                : pilesWithin(items, position, reachM: reachM);

            // Everything taken, or walked away from. Either way there is
            // nothing left to choose between.
            if (piles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.groundEmpty,
                        style: TextStyle(fontSize: 13, color: colours.muted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.noteClose),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.droppedHere,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colours.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final pile in piles)
                          _PileRow(
                            pile: pile,
                            name: nameOf(pile.itemId),
                            catalogue: catalogue,
                            colours: colours,
                            takeLabel: l10n.droppedTake,
                            onTake: () => onTake(pile),
                            onDetails: onDetails == null
                                ? null
                                : () => onDetails(pile),
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.noteClose),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  },
);

class _PileRow extends StatelessWidget {
  const _PileRow({
    required this.pile,
    required this.name,
    required this.catalogue,
    required this.colours,
    required this.takeLabel,
    required this.onTake,
    required this.onDetails,
  });

  final GroundPile pile;
  final String name;
  final ItemCatalogue catalogue;
  final HudColors colours;
  final String takeLabel;
  final VoidCallback onTake;

  /// What it is, for somebody deciding whether it is worth the kilogram.
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final definition = catalogue[pile.itemId];
    final mass = (definition?.weightKg ?? 0) * pile.count;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDetails,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pile.count > 1 ? '$name  ×${pile.count}' : name,
                    style: TextStyle(fontSize: 14, color: colours.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${mass.toStringAsFixed(mass < 1 ? 2 : 1)} kg',
            style: TextStyle(fontSize: 11, color: colours.data),
          ),
          TextButton(onPressed: onTake, child: Text(takeLabel)),
        ],
      ),
    );
  }

  /// How far, how worn, and how far read — the three things that decide which
  /// of two identical-looking piles is the one worth carrying.
  String _subtitle() {
    final parts = <String>['${pile.distanceM.round()} m'];

    final condition = pile.condition;
    if (condition != null) parts.add('${condition.round()}%');

    final pages = pile.pagesTotal;
    if (pages != null) parts.add('${pile.pagesRead} / $pages');

    return parts.join(' · ');
  }
}
