/// One item's numbers, and the one it would replace (§4.2–§4.7).
///
/// A player who finds a second vest has one question — is this one better —
/// and the honest answer is a table, not a verdict. Both columns are shown
/// with the difference beside them, marked + where it is an improvement and
/// − where it is a loss, because which direction counts as better differs per
/// reading: two hundred joules more is better and two hundred grams more is
/// not.
///
/// The comparison is against what is *worn* in that slot, since that is the
/// thing the new one would displace. Where nothing is worn there is nothing to
/// compare and the sheet is simply the item.
library;

import 'package:flutter/material.dart';

import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../items/item_stats.dart';
import '../l10n/app_localizations.dart';
import 'hud.dart' show HudColors;

Future<void> showItemDetails(
  BuildContext context, {
  required ItemDefinition item,
  required Inventory inventory,
  required ItemCatalogue catalogue,
  required ItemNames names,
  VoidCallback? onWear,
  String? wearLabel,
}) {
  final language = Localizations.localeOf(context).languageCode;

  String nameOf(ItemDefinition definition) => definition.name.resolve(
    language: language,
    lookup: names.forLanguage(language),
  );

  // What this would replace: whatever occupies the same slot on the body.
  final worn = inventory.worn
      .map((line) => catalogue[line.itemId])
      .nonNulls
      .where((other) => comparable(item, other))
      .firstOrNull;
  final against = worn ?? _packRival(item, inventory, catalogue);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final colours = HudColors.of(context);
      final l10n = L10n.of(context);

      final mine = statsOf(item);
      final theirs = against == null
          ? const <ItemStat>[]
          : statsOf(against);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameOf(item),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colours.text,
                ),
              ),
              if (against != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${l10n.itemCompare}: ${nameOf(against)} '
                  '(${worn != null ? l10n.itemWorn : l10n.itemCarried})',
                  style: TextStyle(fontSize: 11, color: colours.muted),
                ),
              ],
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final stat in mine)
                        _StatRow(
                          label: _statLabel(l10n, stat.key),
                          mine: stat,
                          theirs: theirs
                              .where((other) => other.key == stat.key)
                              .firstOrNull,
                          colours: colours,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onWear != null)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onWear();
                      },
                      child: Text(wearLabel ?? ''),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.noteClose),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The other one in the pack, when nothing of the sort is being worn.
///
/// Two spare vests in a bag is still a choice worth laying out, and it is the
/// case a player hits first: they find the new one before they take the old
/// one off.
ItemDefinition? _packRival(
  ItemDefinition item,
  Inventory inventory,
  ItemCatalogue catalogue,
) => inventory.carried
    .map((line) => catalogue[line.itemId])
    .nonNulls
    .where((other) => comparable(item, other))
    .firstOrNull;

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.mine,
    required this.theirs,
    required this.colours,
  });

  final String label;
  final ItemStat mine;
  final ItemStat? theirs;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final other = theirs;
    final gain = other == null ? 0.0 : improvement(mine, other);
    final difference = other == null ? 0.0 : mine.value - other.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colours.muted),
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              mine.formatted,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: colours.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (other != null) ...[
            SizedBox(
              width: 92,
              child: Text(
                other.formatted,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  color: colours.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 30,
              child: difference == 0
                  ? const SizedBox.shrink()
                  : Icon(
                      // The sign follows the *reading*, not the arithmetic:
                      // lighter is better and fewer minutes of angle are
                      // better, so both show a plus.
                      gain > 0 ? Icons.add : Icons.remove,
                      size: 16,
                      color: gain > 0
                          ? colours.data
                          : gain < 0
                          ? colours.alert
                          : colours.muted,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

String _statLabel(L10n l10n, String key) => switch (key) {
  'energy' => l10n.statEnergy,
  'moa' => l10n.statMoa,
  'magazine' => l10n.statMagazine,
  'reload' => l10n.statReload,
  'range' => l10n.statRange,
  'noise' => l10n.statNoise,
  'bleed' => l10n.statBleed,
  'swing' => l10n.statSwing,
  'reach' => l10n.statReach,
  'strength' => l10n.statStrength,
  'insulation' => l10n.statInsulation,
  'protection' => l10n.statProtection,
  'coverage' => l10n.statCoverage,
  'capacity' => l10n.statCapacity,
  'carry' => l10n.statCarry,
  'kcal' => l10n.statKcal,
  'water' => l10n.statWater,
  'eatTime' => l10n.statEatTime,
  'useTime' => l10n.statUseTime,
  'uses' => l10n.statUses,
  'blood' => l10n.statBlood,
  'pagesMin' => l10n.statPagesMin,
  'pagesMax' => l10n.statPagesMax,
  'xpPerPage' => l10n.statXpPerPage,
  'light' => l10n.statLight,
  'battery' => l10n.statBattery,
  'craftTime' => l10n.statCraftTime,
  'searchBonus' => l10n.statSearchBonus,
  'mass' => l10n.statMass,
  'bulk' => l10n.statBulk,
  _ => key,
};
