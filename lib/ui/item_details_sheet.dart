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
import '../combat/magazine_item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../items/item_stats.dart';
import '../craft/craft_job.dart';
import '../craft/item_recipe.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';
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

  /// §18.6, §18.2, §4.8: the three things somebody decides here.
  ///
  /// The sheet is where a player works out whether a thing is worth its
  /// weight. Deciding it is not and then having to close the sheet, find the
  /// row again and hunt for the right glyph is the answer arriving three taps
  /// after the question. Null for anything not offered — an absent control
  /// beats a dead one.
  void Function(CarriedItem line)? onDismantle,
  void Function(CarriedItem line)? onStash,
  void Function(CarriedItem line)? onDrop,

  /// §18.6: what this very piece would leave behind, and how long it takes.
  ///
  /// ⚠️ **At this player's share, not at the table's.** Engineering and the
  /// workshop move the figure from 40% to 65%, and a sheet quoting the raw
  /// table would tell somebody who has read three books the wrong number about
  /// the thing in their hands. Null where there is no bench to ask — a pile on
  /// the pavement is looked at, not costed.
  CraftBench? bench,
  RecipeBook? book,

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
        final onBody = pack.worn.any((other) => other.isSame(current));
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

                // §18.6: and what would be left of it. Under the numbers,
                // because "is it worth more in pieces" is the question asked
                // after "is it any good", never before it.
                if (bench != null && book != null)
                  _Salvage(
                    line: line,
                    item: item,
                    bench: bench,
                    book: book,
                    catalogue: catalogue,
                    nameOf: nameOf,
                    colours: colours,
                    l10n: l10n,
                  ),

                const SizedBox(height: 8),

                // ⚠️ Away from the others, on the left, with the harmless
                // buttons on the right. Two of these three destroy or give
                // away the thing being looked at, and a thumb that has just
                // read a number should not find them where "OK" was a moment
                // ago on the previous sheet.
                Row(
                  children: [
                    if (onDismantle != null)
                      _QuickAction(
                        icon: Icons.handyman,
                        tooltip: l10n.craftTakeApart,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismantle(line);
                        },
                        colours: colours,
                      ),
                    if (onStash != null)
                      _QuickAction(
                        icon: Icons.inventory_2,
                        tooltip: l10n.stashStore,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onStash(line);
                        },
                        colours: colours,
                      ),
                    if (onDrop != null)
                      _QuickAction(
                        icon: Icons.file_download,
                        tooltip: l10n.inventoryDrop,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDrop(line);
                        },
                        colours: colours,
                      ),
                  ],
                ),

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
    if (other.isSame(line)) continue;
    final definition = catalogue[other.itemId];
    if (definition != null && comparable(item, definition)) return other;
  }
  return null;
}

/// The glyph that opens [showItemDetails], wherever a piece is listed.
///
/// ⚠️ **One button, because there are three lists.** The pack, the shelves and
/// the slots on the body all show the same thing and all need the same way in
/// — and the slot row was the one that never got it, so the pieces a player is
/// actually wearing were the pieces they had to guess were tappable.
class ItemInfoButton extends StatelessWidget {
  const ItemInfoButton({
    required this.onPressed,
    required this.colour,
    super.key,
  });

  final VoidCallback onPressed;
  final Color colour;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: const Icon(Icons.info_outline, size: 18),
    color: colour,
    tooltip: L10n.of(context).itemDetails,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.symmetric(horizontal: 6),
  );
}

/// §18.6: what comes back out of this piece, and what it costs to get it.
///
/// ⚠️ **Off the same functions the bench uses, never a second arithmetic.**
/// The disassembly screen and this sheet answering differently would be worse
/// than the sheet saying nothing: a player reads one, acts on the other, and
/// the game has lied to them about the only thing they were deciding.
class _Salvage extends StatelessWidget {
  const _Salvage({
    required this.line,
    required this.item,
    required this.bench,
    required this.book,
    required this.catalogue,
    required this.nameOf,
    required this.colours,
    required this.l10n,
  });

  final CarriedItem line;
  final ItemDefinition item;
  final CraftBench bench;
  final RecipeBook book;
  final ItemCatalogue catalogue;
  final String Function(ItemDefinition definition) nameOf;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final yields = salvagePreview(
      line.itemId,
      bench,
      catalogue: catalogue,
      book: book,
      condition: line.condition ?? item.condition ?? 100,
    );

    // ⚠️ Silent about things that are not taken apart at all — food, a
    // dressing, a book. A row saying "nothing would be left of it" under every
    // sandwich in the pack is noise, and noise is what makes a player stop
    // reading the rows that matter.
    if (materialContent(item, book).isEmpty) return const SizedBox.shrink();

    final minutes = salvageTime(materialContent(item, book)).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              l10n.itemSalvageTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.1,
                color: colours.muted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.itemSalvageTakes(minutes),
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          yields.isEmpty
              ? l10n.itemSalvageNothing
              : effects([
                  for (final entry in yields.entries)
                    '${_materialName(entry.key)} ×${entry.value}',
                ]),
          style: TextStyle(
            fontSize: 12,
            color: yields.isEmpty ? colours.muted : colours.data,
          ),
        ),
      ],
    );
  }

  String _materialName(String itemId) {
    final material = catalogue[itemId];
    return material == null ? itemId : nameOf(material);
  }
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

    final free =
        slots -
        slotsUsedBy([for (final id in line.attachments) ?catalogue[id]]);

    // §5.6.3: grouped by place, because the place is the choice.
    //
    // ⚠️ It used to be one flat list — everything fitted, then everything in
    // the pack that would go on, each with a button saying "fit". Nothing said
    // where any of it went, so two optics looked like two upgrades rather than
    // one decision, and nothing told a player what a button was about to
    // replace. A weapon has one barrel and one rail. The interface offers the
    // place, and the parts under it.
    final fittedBy = <AttachmentSlot, ItemDefinition>{};
    for (final id in line.attachments) {
      final part = catalogue[id];
      if (part == null) continue;
      fittedBy[slotOf(part) ?? AttachmentSlot.rail] = part;
    }

    final offers = <AttachmentSlot, List<CarriedItem>>{};
    for (final carried in inventory.carried) {
      final part = catalogue[carried.itemId];
      if (part == null || !partFitsWeapon(part, weapon)) continue;
      if (line.attachments.contains(carried.itemId)) continue;

      offers
          .putIfAbsent(slotOf(part) ?? AttachmentSlot.rail, () => [])
          .add(carried);
    }

    // ⚠️ The magazine well is always shown on a weapon that has one, even
    // with nothing to put in it. A rifle with no magazine is the single most
    // important thing this sheet can say, and hiding the row for want of a
    // candidate said nothing at all — the well simply was not there.
    final needsWell = Feed.of(weapon) == Feed.magazine;

    final places = [
      for (final place in AttachmentSlot.values)
        if (fittedBy.containsKey(place) ||
            offers.containsKey(place) ||
            (place == AttachmentSlot.magazine && needsWell))
          place,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          effects([l10n.attachmentsFitted, l10n.attachmentsFree(free)]),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            color: colours.muted,
          ),
        ),

        if (places.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.attachmentsNone,
            style: TextStyle(fontSize: 12, color: colours.muted),
          ),
        ],

        for (final place in places) ...[
          const SizedBox(height: 6),
          Text(
            _placeName(place).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              color: colours.muted,
            ),
          ),

          if (fittedBy[place] case final part?)
            _PartRow(
              name: nameOf(part),
              effect: attachmentEffect(
                part,
                rounds: Magazine.of(part) == null ? null : (line.rounds ?? 0),
                capacity: Magazine.of(part)?.capacity,
              ),
              action: onDetach == null ? null : l10n.attachmentRemove,
              onPressed: onDetach == null
                  ? null
                  : () => onDetach!(line, part.id),
              fitted: true,
              colours: colours,
            )
          else
            Text(
              l10n.slotEmpty,
              style: TextStyle(fontSize: 12, color: colours.muted),
            ),

          // Only where the place is free, and only while there is a slot left:
          // an offer that would be refused is worse than no offer. Taking the
          // old part off first is one tap, and it is the tap that says what is
          // being given up.
          if (fittedBy[place] == null &&
              (free > 0 || place == AttachmentSlot.magazine) &&
              onAttach != null)
            _Offers(
              candidates: offers[place] ?? const [],
              catalogue: catalogue,
              nameOf: nameOf,
              onPick: (candidate) => onAttach!(line, candidate),
              colours: colours,
              l10n: l10n,
            ),
        ],
      ],
    );
  }

  String _placeName(AttachmentSlot place) => switch (place) {
    AttachmentSlot.magazine => l10n.slotMagazine,
    AttachmentSlot.optic => l10n.slotOptic,
    AttachmentSlot.barrel => l10n.slotBarrel,
    AttachmentSlot.grip => l10n.slotGrip,
    AttachmentSlot.rail => l10n.slotRail,
  };
}

/// What could go in this place, and what is in each of them (§4.2).
///
/// One button with a menu rather than a row per candidate. Magazines are the
/// reason: a player carrying five of them wants to pick *the full one*, and
/// five rows of the same name with different numbers is a worse way to ask
/// that question than one list showing the numbers side by side. With a single
/// candidate there is nothing to choose, so it stays a plain button.
class _Offers extends StatelessWidget {
  const _Offers({
    required this.candidates,
    required this.catalogue,
    required this.nameOf,
    required this.onPick,
    required this.colours,
    required this.l10n,
  });

  final List<CarriedItem> candidates;
  final ItemCatalogue catalogue;
  final String Function(ItemDefinition) nameOf;
  final void Function(CarriedItem) onPick;
  final HudColors colours;
  final L10n l10n;

  String? _effect(CarriedItem candidate) {
    final part = catalogue[candidate.itemId]!;
    return attachmentEffect(
      part,
      rounds: candidate.rounds,
      capacity: Magazine.of(part)?.capacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    if (candidates.length == 1) {
      final only = candidates.single;
      return _PartRow(
        name: nameOf(catalogue[only.itemId]!),
        effect: _effect(only),
        action: l10n.attachmentFit,
        onPressed: () => onPick(only),
        fitted: false,
        colours: colours,
      );
    }

    // Fullest first: it is what somebody reaching for a magazine wants, and
    // sorting by it means the top of the list is almost always the answer.
    final sorted = [...candidates]
      ..sort((a, b) => (b.rounds ?? -1).compareTo(a.rounds ?? -1));

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.attachmentChoose(sorted.length),
            style: TextStyle(fontSize: 13, color: colours.muted),
          ),
        ),
        PopupMenuButton<CarriedItem>(
          onSelected: onPick,
          tooltip: l10n.attachmentFit,
          itemBuilder: (context) => [
            for (final candidate in sorted)
              PopupMenuItem(
                value: candidate,
                child: Row(
                  children: [
                    Expanded(child: Text(nameOf(catalogue[candidate.itemId]!))),
                    if (_effect(candidate) case final said?) ...[
                      const SizedBox(width: 12),
                      Text(
                        said,
                        style: TextStyle(
                          fontSize: 12,
                          color: colours.data,
                          fontFamily: kDataFont,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.attachmentFit,
                  style: TextStyle(fontSize: 14, color: colours.alert),
                ),
                Icon(Icons.arrow_drop_down, size: 18, color: colours.alert),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One part, fitted or on offer, with what it does to the weapon.
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.name,
    required this.effect,
    required this.action,
    required this.onPressed,
    required this.fitted,
    required this.colours,
  });

  final String name;
  final String? effect;
  final String? action;
  final VoidCallback? onPressed;
  final bool fitted;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: fitted ? colours.text : colours.muted,
          ),
        ),
      ),
      if (effect != null) ...[
        Text(
          effect!,
          style: TextStyle(
            fontSize: 11,
            color: fitted ? colours.data : colours.muted,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
      ],
      if (action != null)
        TextButton(onPressed: onPressed, child: Text(action!)),
    ],
  );
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
    if (entry.isSame(line)) return entry;
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

/// One of the three decisions the sheet lets somebody act on (§18.6, §18.2,
/// §4.8).
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colours,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    tooltip: tooltip,
    color: colours.muted,
    visualDensity: VisualDensity.compact,
  );
}
