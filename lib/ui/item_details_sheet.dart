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
///
/// It works per copy rather than per item id: two soft vests, one at 90% and
/// one at 40%, are two different things to own and the second one is the case
/// a player actually hits.
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'fonts.dart';
import '../inventory/inventory.dart';
import '../items/item.dart';
import '../combat/attachment.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../items/item_stats.dart';
import '../l10n/app_localizations.dart';
import 'hud.dart' show HudColors;

Future<void> showItemDetails(
  BuildContext context, {
  required CarriedItem line,
  required ValueListenable<Inventory> inventory,
  required ItemCatalogue catalogue,
  required ItemNames names,
  VoidCallback? onWear,
  String? wearLabel,
  void Function(CarriedItem line, CarriedItem attachment)? onAttach,
  void Function(CarriedItem line, String attachmentId)? onDetach,

  /// Whether this piece is one the player is carrying.
  ///
  /// False for anything being looked at from outside the pack — a pile on the
  /// ground, a body's pockets. Such a thing has no counterpart in the
  /// inventory, and pretending it does is how a rifle on the pavement ended up
  /// wearing the sights off the one in the player's hands.
  bool fromPack = true,
}) {
  final language = Localizations.localeOf(context).languageCode;
  final item = catalogue[line.itemId];
  if (item == null) return Future<void>.value();

  String nameOf(ItemDefinition definition) => definition.name.resolve(
    language: language,
    lookup: names.forLanguage(language),
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // ⚠️ The live pack, not a copy of it. This is a pushed route over a game
    // that keeps running: handed a snapshot, fitting a sight to a rifle
    // changed nothing on screen and looked broken. Fourth time this shape of
    // bug has come back.
    builder: (context) => ValueListenableBuilder<Inventory>(
      valueListenable: inventory,
      builder: (context, pack, _) {
        final colours = HudColors.of(context);
        final l10n = L10n.of(context);

        // What this would replace: whatever occupies the same slot on the
        // body, read from the pack as it is now.
        // ⚠️ Worn as well as carried. The weapon a player wants a light on is
        // the one in their hand, and the hand is `worn` — looking only in the
        // pack found a stale copy of it, so fitting anything did nothing.
        final current = _liveLine(pack, line, mine: fromPack);
        // Against what is on the body, and nothing else. The question a player
        // is actually asking is "is this better than mine" — comparing two
        // things in the same pack answers a question nobody has, and comparing
        // the worn one against another worn one answers it twice.
        final onBody = pack.worn.any((other) => identical(other, current));
        final against = onBody
            ? null
            : _rival(current, item, pack.worn, catalogue);

        // §5.6.3: with whatever is bolted to each of them. Two rifles are only
        // comparable as the rifles they are, suppressor and optic included.
        final mine = statsOf(
          item,
          condition: current.condition,
          attachments: _partsOf(current, catalogue),
        );
        final theirs = against == null
            ? const <ItemStat>[]
            : statsOf(
                catalogue[against.itemId]!,
                condition: against.condition,
                attachments: _partsOf(against, catalogue),
              );

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
                    '${l10n.itemCompare}: '
                    '${nameOf(catalogue[against.itemId]!)} '
                    '(${l10n.itemWorn})',
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                ],
                // §5.6.3: what is on this weapon, and what is left to put on
                // it. On the piece rather than on the player: two rifles in one
                // pack are two rifles.
                if (item.kind == ItemKind.firearm) ...[
                  const SizedBox(height: 12),
                  _Attachments(
                    line: current,
                    weapon: item,
                    inventory: pack,
                    catalogue: catalogue,
                    nameOf: nameOf,
                    colours: colours,
                    l10n: l10n,
                    onAttach: onAttach,
                    onDetach: onDetach,
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
                      child: Text(l10n.commonOk),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// The copy this one would be swapped for, out of [among].
///
/// Never the copy being looked at, which is what makes this per entry rather
/// than per item id: two spare vests in a bag are a choice worth laying out,
/// and that is the case a player hits first — they find the new one before
/// they take the old one off.
CarriedItem? _rival(
  CarriedItem line,
  ItemDefinition item,
  List<CarriedItem> among,
  ItemCatalogue catalogue,
) {
  for (final other in among) {
    if (identical(other, line)) continue;
    final definition = catalogue[other.itemId];
    if (definition != null && comparable(item, definition)) return other;
  }
  return null;
}

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
                fontFamily: kDataFont,
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
                  fontFamily: kDataFont,
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
  'condition' => l10n.statCondition,
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
  'settle' => l10n.statSettle,
  'craftSkill' => l10n.statCraftSkill,
  'mass' => l10n.statMass,
  'bulk' => l10n.statBulk,
  _ => key,
};

/// §5.6.3: the rails on one weapon, filled and empty.
class _Attachments extends StatelessWidget {
  const _Attachments({
    required this.line,
    required this.weapon,
    required this.inventory,
    required this.catalogue,
    required this.nameOf,
    required this.colours,
    required this.l10n,
    required this.onAttach,
    required this.onDetach,
  });

  final CarriedItem line;
  final ItemDefinition weapon;
  final Inventory inventory;
  final ItemCatalogue catalogue;
  final String Function(ItemDefinition) nameOf;
  final HudColors colours;
  final L10n l10n;

  /// Handed the *current* piece as well as the part, because the sheet outlives
  /// the object it was opened with: every fit rebuilds the line, and a callback
  /// holding the old one would be bolting things onto a piece that is no longer
  /// in the pack.
  final void Function(CarriedItem line, CarriedItem attachment)? onAttach;
  final void Function(CarriedItem line, String attachmentId)? onDetach;

  @override
  Widget build(BuildContext context) {
    final slots = attachmentSlots(weapon);
    if (slots <= 0) return const SizedBox.shrink();

    final free = slots - line.attachments.length;

    // What is in the pack that would go on this, and is not already on it.
    final candidates = [
      for (final carried in inventory.carried)
        if (catalogue[carried.itemId] != null &&
            fitsWeapon(catalogue[carried.itemId]!, weapon) &&
            !line.attachments.contains(carried.itemId))
          carried,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.attachmentsFitted} · ${l10n.attachmentsFree(free)}',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            color: colours.muted,
          ),
        ),
        const SizedBox(height: 4),

        if (line.attachments.isEmpty)
          Text(
            l10n.attachmentsNone,
            style: TextStyle(fontSize: 12, color: colours.muted),
          )
        else
          for (final id in line.attachments)
            Row(
              children: [
                Expanded(
                  child: Text(
                    catalogue[id] == null ? id : nameOf(catalogue[id]!),
                    style: TextStyle(fontSize: 13, color: colours.text),
                  ),
                ),
                if (onDetach != null)
                  TextButton(
                    onPressed: () => onDetach!(line, id),
                    child: Text(l10n.attachmentRemove),
                  ),
              ],
            ),

        // Only where there is a rail left: an offer that would be refused is
        // worse than no offer.
        if (free > 0 && onAttach != null)
          for (final candidate in candidates)
            Row(
              children: [
                Expanded(
                  child: Text(
                    nameOf(catalogue[candidate.itemId]!),
                    style: TextStyle(fontSize: 13, color: colours.muted),
                  ),
                ),
                TextButton(
                  onPressed: () => onAttach!(line, candidate),
                  child: Text(l10n.attachmentFit),
                ),
              ],
            ),
      ],
    );
  }
}

/// The piece as the pack has it now, matched by identity first and by id after.
///
/// A sheet stays open across fits and removals, so the object it was opened
/// with goes stale on the first one. Identity is the honest match — two rifles
/// in one bag are two rifles — and the id is the fallback for exactly the case
/// identity cannot survive: the very piece was rebuilt by the last edit.
CarriedItem _liveLine(Inventory pack, CarriedItem line, {required bool mine}) {
  // ⚠️ Only for a piece that came out of the pack. Found on a phone: tapping a
  // rifle lying on the ground showed the attachments of the rifle in the
  // player's own hands, and taking one off the ground copy took it off theirs
  // — because the by-id match below happily found *their* weapon and every
  // control on the sheet then pointed at it. Something on the ground is not in
  // the pack, so there is nothing here to look up.
  if (!mine) return line;

  final everything = [...pack.worn, ...pack.carried];

  for (final entry in everything) {
    if (identical(entry, line)) return entry;
  }

  // By id only as a fallback, and only for a piece known to be in the pack:
  // every fit rebuilds the line, so identity is gone after the first one.
  for (final entry in everything) {
    if (entry.itemId == line.itemId) return entry;
  }
  return line;
}

/// What is bolted to this piece, as definitions (§5.6.3).
List<ItemDefinition> _partsOf(CarriedItem line, ItemCatalogue catalogue) => [
  for (final id in line.attachments)
    if (catalogue[id] != null) catalogue[id]!,
];
