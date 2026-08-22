/// EKWIPUNEK, the second entry of §3.6's bottom menu.
///
/// The screen answers one question — what am I carrying and what is it costing
/// me — so the two limits of §18.1a are at the top, above everything else, and
/// every line carries its own mass and bulk. A player deciding what to leave
/// behind needs both figures per item; a total alone says something must go
/// without saying what.
///
/// **Worn kit is a figure, not a list.** The slots come from §4.4 and are laid
/// out head to foot, so a glance reads as a person rather than as an inventory:
/// what is on, what is missing, and where the armour is. An empty slot is still
/// a row, because the gap is the information — a list of only what exists
/// cannot tell somebody they have no gloves.
///
/// No sprite sheet — §3.1 ships none deliberately — so the figure is drawn in
/// type and rules. That also keeps every line readable aloud, which a grid of
/// unlabelled tiles would not be (§12).
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../craft/craft_job.dart';
import 'fonts.dart';
import 'units.dart';
import 'ticking.dart';
import '../devtools/dev_mode.dart';
import '../inventory/body_slots.dart';
import '../inventory/inventory.dart';
import '../inventory/item_use.dart';
import '../combat/attachment.dart';
import '../items/item.dart';
import '../combat/magazine_item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../l10n/app_localizations.dart';
import '../loot/search.dart';
import '../sim/body.dart';
import '../sim/pinned_goal.dart';
import 'hud.dart' show HudColors;

/// How the pack is ordered (§4.1, §12).
///
/// ⚠️ Three orders rather than one, because the pack answers three different
/// questions. "Where are my bandages" wants the medical things together;
/// "what can I put down" wants the heaviest first; "have I got a crowbar"
/// wants the alphabet. One fixed order answers one of the three and makes the
/// other two a scroll.
/// The things a row can offer to do (§12).
///
/// Named so that the screen can ask one question about all of them: *would
/// this work right now, and if not, why not*.
enum PackAction { use, wear, read, fill, empty, dismantle, stash }

enum PackOrder {
  /// Grouped by §4.1's own categories. The default: a pack is read by kind
  /// far more often than by anything else.
  kind,

  name,

  /// Heaviest first, which is the order §18.1a's decision is made in.
  mass,
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    required this.inventory,
    required this.order,
    required this.catalogue,
    required this.names,
    required this.body,
    this.onDrop,
    this.onWear,
    this.onTakeOff,
    this.onUse,
    this.onRead,
    this.onFill,
    this.onEmpty,
    this.onDismantle,
    this.canDismantle,
    this.onStash,
    this.onStopDismantle,
    this.refusalOf,
    this.craftJob,
    this.craftLines,
    this.onDetails,
    this.usingLine,
    this.onDevFill,
    this.action,
    this.onCancelAction,
    super.key,
  });

  /// Listened to rather than passed by value.
  ///
  /// ⚠️ This screen is a pushed route: its builder runs once. Handed a plain
  /// [Inventory] it kept showing the one it opened with, so dropping something
  /// changed nothing on screen and the same item could be dropped again and
  /// again against a list that was already out of date.
  final ValueListenable<Inventory> inventory;

  /// §12: how the pack is sorted, held by the caller so the choice outlives
  /// closing this screen.
  final ValueNotifier<PackOrder> order;

  final ItemCatalogue catalogue;
  final ItemNames names;
  final BodyProfile body;

  /// Puts something on the ground (§4.8), as many of the line as asked for.
  final void Function(CarriedItem line, int count)? onDrop;

  /// Puts something on (§4.4). Whatever was in that slot comes off into the
  /// pack.
  final void Function(CarriedItem line)? onWear;

  /// Takes a worn piece off into the pack (§4.4).
  final void Function(CarriedItem line)? onTakeOff;

  /// Eats, drinks or dresses a wound (§4.7), for as long as the data says.
  final void Function(CarriedItem line)? onUse;

  /// §4.2: filling a magazine from loose rounds.
  final void Function(CarriedItem line)? onFill;

  /// §18.6: taking something apart for what is in it.
  final void Function(CarriedItem line)? onDismantle;

  /// Whether there is anything in it worth getting back. The button is absent
  /// rather than dead for a tin of beans — a control that cannot be used is
  /// worse than no control at all.
  final bool Function(CarriedItem line)? canDismantle;

  /// §18.2: straight onto the shelf, without opening the shelves first.
  /// Null when they are not within arm's reach.
  final void Function(CarriedItem line)? onStash;

  /// §18.6: stops the job half way, keeping the work already done.
  final VoidCallback? onStopDismantle;

  /// Why this action would not work on this piece **right now**, or null.
  ///
  /// ⚠️ Two different kinds of "no", and they get two different answers.
  ///
  /// An action that does not apply to the thing at all — dismantling a tin of
  /// beans, reloading a crowbar — shows no button, and this is never asked
  /// about it. An action that applies but cannot happen *yet* — the shelves
  /// are full, something else is on the bench — shows the button greyed, and
  /// says why under the row when it is pressed.
  ///
  /// The difference matters because the second kind is something the player
  /// can go and fix. Hiding it would leave them looking for a control that was
  /// there a minute ago; a dead button with no explanation reads as broken.
  final String? Function(CarriedItem line, PackAction action)? refusalOf;

  /// §18.6, §2.1a.3: the job on the bench, and which piece it is holding.
  final ValueListenable<CraftJob?>? craftJob;

  /// §18.6: every piece spoken for by the sitting on the bench.
  ///
  /// ⚠️ A list, and the order matters: the first is the one actually under the
  /// multitool and the only one that gets a bar. The rest are waiting their
  /// turn — locked, so a rifle queued for the sitting cannot be worn and
  /// fired, but not pretending to be in progress.
  final ValueListenable<List<CarriedItem>>? craftLines;

  /// §4.2: tipping them back out again.
  final void Function(CarriedItem line)? onEmpty;

  /// §19.1: opens a note somebody left. Null for anything that is not one.
  final void Function(CarriedItem line)? onRead;

  /// Opens the numbers, and whatever this would replace beside them.
  final void Function(CarriedItem line)? onDetails;

  /// §4.7: the very piece being eaten or drunk, so the bar is drawn under it
  /// and not under every other tin of the same kind in the pack.
  final ValueListenable<CarriedItem?>? usingLine;

  /// Fills the pack with a sample kit. Developer builds only.
  final VoidCallback? onDevFill;

  /// What is being used right now (§4.7), so the screen the player started it
  /// from is the screen that shows it. Without this, using a tin from here
  /// looked like nothing had happened until they walked back to the map.
  final ValueListenable<Search?>? action;

  final VoidCallback? onCancelAction;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Inventory>(
    valueListenable: inventory,
    builder: (context, inventory, _) => ValueListenableBuilder<PackOrder>(
      valueListenable: order,
      // ⚠️ A notifier owned by the caller, not local state. This screen is a
      // pushed route, and a choice held inside one is a choice forgotten every
      // time the player closes it — which is the bug class this codebase has
      // now found six times.
      builder: (context, _, _) => _build(context, inventory),
    ),
  );

  PackOrder get _order => order.value;

  Widget _build(BuildContext context, Inventory inventory) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final limits = inventory.limits(body, catalogue);
    final language = Localizations.localeOf(context).languageCode;

    final mass = inventory.massKg(catalogue);
    final volume = inventory.volumeL(catalogue);
    final overComfort = mass > limits.comfortKg;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        actions: [
          if (kDevTools && onDevFill != null)
            IconButton(
              onPressed: onDevFill,
              icon: const Icon(Icons.science_outlined),
              tooltip: 'dev: fill',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ValueListenableBuilder<PinnedGoal?>(
            valueListenable: PinnedGoalManager.current,
            builder: (context, goal, _) {
              if (goal == null) return const SizedBox.shrink();
              return _QuestStatusDisplay(
                goal: goal,
                inventory: inventory,
                catalogue: catalogue,
                language: language,
              );
            },
          ),
          const SizedBox(height: 8),
          _Limits(
            massKg: mass,
            comfortKg: limits.comfortKg,
            maxKg: limits.maxKg,
            volumeL: volume,
            capacityL: limits.capacityL,
            massLabel: l10n.hudCarry,
            bulkLabel: l10n.hudBulk,
          ),
          if (overComfort) ...[
            const SizedBox(height: 8),
            Text(
              l10n.inventoryOverComfort,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE8B33A)),
            ),
          ],

          const SizedBox(height: 20),
          _SectionHeader(label: l10n.inventoryWorn, colours: colours),
          for (final slot in BodySlot.values)
            _SlotRow(
              label: _slotName(l10n, slot),
              line: _wornIn(inventory, slot),
              catalogue: catalogue,
              nameOf: (id) => _nameOf(id, language),
              emptyLabel: l10n.inventoryEmptySlot,
              takeOffLabel: l10n.inventoryTakeOff,
              onTakeOff: onTakeOff,
              onDetails: onDetails,
              colours: colours,
            ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  label: l10n.inventoryPack,
                  colours: colours,
                ),
              ),

              // Cycles rather than opening a menu: three options is one tap
              // each way, and a menu on a screen read while walking is two
              // taps and a target the size of a fingernail.
              TextButton(
                onPressed: () => order.value = switch (_order) {
                  PackOrder.kind => PackOrder.name,
                  PackOrder.name => PackOrder.mass,
                  PackOrder.mass => PackOrder.kind,
                },
                child: Text(switch (_order) {
                  PackOrder.kind => l10n.packOrderKind,
                  PackOrder.name => l10n.packOrderName,
                  PackOrder.mass => l10n.packOrderMass,
                }, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (inventory.carried.isEmpty)
            _Empty(
              title: l10n.inventoryEmpty,
              hint: l10n.inventoryEmptyHint,
              colours: colours,
            )
          else
            // Keyed by position, not by item id: two knives at different
            // conditions are two rows with one id, and a list cannot hold two
            // children under one key.
            for (final (index, line) in _sorted(
              inventory.carried,
              language,
            ).indexed)
              _ItemRow(
                key: ValueKey('$index.${line.itemId}'),
                line: line,
                definition: catalogue[line.itemId]!,
                catalogue: catalogue,
                name: _nameOf(line.itemId, language),
                kind: kindName(l10n, catalogue[line.itemId]!.kind),
                l10n: l10n,
                onDrop: onDrop,
                onWear: onWear,
                onUse: onUse,
                onRead: onRead,
                onFill: onFill,
                onEmpty: onEmpty,
                onDismantle: onDismantle,
                canDismantle: canDismantle,
                onStash: onStash,
                onStopDismantle: onStopDismantle,
                refusalOf: refusalOf,
                craftJob: craftJob,
                craftLines: craftLines,
                onDetails: onDetails,
                // The progress bar belongs under the thing it belongs to, not
                // at the top of the screen: a player who taps "use" looks at
                // what they tapped.
                action: action,
                usingLine: usingLine,
                onCancelAction: onCancelAction,
                // §5.6.3: what is bolted to this very piece, so the row can
                // say what the rifle actually does rather than what a
                // catalogue entry of that name would do.
                attachments: [
                  for (final id in line.attachments)
                    if (catalogue[id] != null) catalogue[id]!,
                ],
                attachmentNames: [
                  for (final id in line.attachments)
                    if (catalogue[id] != null) _nameOf(id, language),
                ],
              ),
        ],
      ),
    );
  }

  CarriedItem? _wornIn(Inventory inventory, BodySlot slot) {
    if (slot == BodySlot.back) {
      final packId = inventory.packId;
      return packId == null ? null : CarriedItem(itemId: packId);
    }
    for (final line in inventory.worn) {
      final definition = catalogue[line.itemId];
      final where = definition == null
          ? null
          : BodySlot.fromWire(wearSlotOf(definition));
      if (where == slot) return line;
    }
    return null;
  }

  String _slotName(L10n l10n, BodySlot slot) => switch (slot) {
    BodySlot.hand => l10n.slotHand,
    BodySlot.head => l10n.slotHead,
    BodySlot.torsoBase => l10n.slotTorsoBase,
    BodySlot.torsoMid => l10n.slotTorsoMid,
    BodySlot.torsoOuter => l10n.slotTorsoOuter,
    BodySlot.torsoArmor => l10n.slotTorsoArmor,
    BodySlot.arms => l10n.slotArms,
    BodySlot.hands => l10n.slotHands,
    BodySlot.legs => l10n.slotLegs,
    BodySlot.feet => l10n.slotFeet,
    BodySlot.back => l10n.slotBack,
  };

  String _nameOf(String itemId, String language) {
    final definition = catalogue[itemId];
    if (definition == null) return itemId;
    return definition.name.resolve(
      language: language,
      lookup: names.forLanguage(language),
    );
  }

  /// Heaviest first. What a player is looking for when the pack is full is the
  /// thing to leave behind, and that is nearly always the heaviest one.
  List<CarriedItem> _sorted(List<CarriedItem> lines, String language) {
    final sorted = [...lines];

    // ⚠️ Every order falls back to the name, and the name is the *translated*
    // one. Sorting a Polish pack by an English item id put Bandaż between
    // Latarka and Lina, which is nobody's alphabet.
    int byName(CarriedItem a, CarriedItem b) => _nameOf(
      a.itemId,
      language,
    ).toLowerCase().compareTo(_nameOf(b.itemId, language).toLowerCase());

    sorted.sort((a, b) {
      switch (_order) {
        case PackOrder.kind:
          // §4.1's own categories, in the order the enum declares them, so
          // the grouping is the same on every run and in every language.
          final byKind = catalogue[a.itemId]!.kind.index.compareTo(
            catalogue[b.itemId]!.kind.index,
          );
          return byKind != 0 ? byKind : byName(a, b);

        case PackOrder.mass:
          final byMass = b
              .massKg(catalogue[b.itemId]!, catalogue: catalogue)
              .compareTo(a.massKg(catalogue[a.itemId]!, catalogue: catalogue));
          return byMass != 0 ? byMass : byName(a, b);

        case PackOrder.name:
          return byName(a, b);
      }
    });

    return sorted;
  }
}

/// The action in progress, at the top of the screen it was started from.
class _Running extends StatelessWidget {
  const _Running({
    required this.search,
    required this.onCancel,
    required this.colours,
    required this.cancelLabel,
  });

  final Search search;
  final VoidCallback? onCancel;
  final HudColors colours;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                search.usingLabel ?? '',
                style: TextStyle(fontSize: 13, color: colours.text),
              ),
            ),
            Text(
              '${search.remaining.inSeconds} s',
              style: TextStyle(
                fontSize: 13,
                color: colours.data,
                fontFamily: kDataFont,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (onCancel != null)
              TextButton(onPressed: onCancel, child: Text(cancelLabel)),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: search.progress,
          minHeight: 4,
          backgroundColor: colours.muted.withValues(alpha: 0.25),
          color: colours.data,
        ),
      ],
    ),
  );
}

/// One place on the body, filled or not.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.label,
    required this.line,
    required this.catalogue,
    required this.nameOf,
    required this.emptyLabel,
    required this.takeOffLabel,
    required this.onTakeOff,
    required this.onDetails,
    required this.colours,
  });

  final String label;
  final CarriedItem? line;

  final ItemCatalogue catalogue;
  final String Function(String itemId) nameOf;
  final String emptyLabel;
  final String takeOffLabel;
  final void Function(CarriedItem)? onTakeOff;
  final void Function(CarriedItem)? onDetails;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final worn = line;
    final definition = worn == null ? null : catalogue[worn.itemId];

    return Semantics(
      label: '$label: ${worn == null ? emptyLabel : nameOf(worn.itemId)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: colours.muted.withValues(alpha: worn == null ? 0.2 : 0.5),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.1,
                  color: colours.muted,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: worn == null || onDetails == null
                    ? null
                    : () => onDetails!(worn),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      worn == null ? emptyLabel : nameOf(worn.itemId),
                      style: TextStyle(
                        fontSize: 13,
                        color: worn == null ? colours.muted : colours.text,
                        fontStyle: worn == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),

                    // §5.6.3: and what is bolted to it.
                    //
                    // ⚠️ The pack row said this and the slot row did not — so
                    // fitting a sight to the rifle in your hands, the one
                    // weapon it matters for, was the one case where nothing on
                    // screen changed.
                    if (worn != null && worn.attachments.isNotEmpty)
                      Text(
                        [
                          for (final id in worn.attachments) nameOf(id),
                        ].join(' · '),
                        style: TextStyle(fontSize: 11, color: colours.data),
                      ),
                  ],
                ),
              ),
            ),
            if (definition != null)
              Text(
                kilograms(worn!.massKg(definition, catalogue: catalogue)),
                style: TextStyle(fontSize: 11, color: colours.data),
              ),
            if (worn != null && onTakeOff != null)
              TextButton(
                onPressed: () => onTakeOff!(worn),
                child: Text(takeOffLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _Limits extends StatelessWidget {
  const _Limits({
    required this.massKg,
    required this.comfortKg,
    required this.maxKg,
    required this.volumeL,
    required this.capacityL,
    required this.massLabel,
    required this.bulkLabel,
  });

  final double massKg;
  final double comfortKg;
  final double maxKg;
  final double volumeL;
  final double capacityL;
  final String massLabel;
  final String bulkLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Gauge(
          label: massLabel,
          value: outOfKg(massKg, maxKg),
          fraction: maxKg > 0 ? massKg / maxKg : 0,
          markAt: maxKg > 0 ? comfortKg / maxKg : null,
          warning: massKg > comfortKg,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _Gauge(
          label: bulkLabel,
          value: outOfL(volumeL, capacityL),
          fraction: capacityL > 0 ? volumeL / capacityL : 0,
          warning: capacityL > 0 && volumeL > capacityL * 0.9,
        ),
      ),
    ],
  );
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.fraction,
    required this.warning,
    this.markAt,
  });

  final String label;
  final String value;
  final double fraction;
  final double? markAt;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final full = fraction >= 0.999;
    final colour = full
        ? colours.alert
        : warning
        ? const Color(0xFFE8B33A)
        : colours.data;

    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: colours.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: warning || full ? colour : colours.text,
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colours.muted.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                if (markAt != null && markAt! < 1)
                  Positioned(
                    left: constraints.maxWidth * markAt!.clamp(0.0, 1.0) - 0.5,
                    child: Container(
                      height: 6,
                      width: 1,
                      color: colours.text.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colours});

  final String label;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: colours.muted),
    ),
  );
}

/// One line in the pack, with everything that can be done to it.
///
/// Stateful for one reason: how many to put down. §18.1a makes a full pack a
/// decision, and "all or nothing" is not the decision — a player shedding a
/// kilogram of wood should not lose six.
class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.line,
    required this.definition,
    required this.catalogue,
    required this.name,
    this.attachments = const [],
    this.attachmentNames = const [],
    required this.kind,
    required this.l10n,
    super.key,
    this.onDrop,
    this.onWear,
    this.onUse,
    this.onRead,
    this.onFill,
    this.onEmpty,
    this.onDismantle,
    this.canDismantle,
    this.onStash,
    this.onStopDismantle,
    this.refusalOf,
    this.craftJob,
    this.craftLines,
    this.onDetails,
    this.action,
    this.usingLine,
    this.onCancelAction,
  });

  final CarriedItem line;
  final ItemDefinition definition;

  /// Needed for the mass of whatever is bolted on (§5.6.3, §18.1a).
  final ItemCatalogue catalogue;

  final String name;

  /// §5.6.3: what is on this weapon, and what those parts are called.
  final List<ItemDefinition> attachments;
  final List<String> attachmentNames;

  final String kind;
  final L10n l10n;

  final void Function(CarriedItem, int)? onDrop;
  final void Function(CarriedItem)? onWear;
  final void Function(CarriedItem)? onUse;

  /// §4.2: filling a magazine from loose rounds.
  final void Function(CarriedItem)? onFill;

  /// §18.6: taking something apart for what is in it.
  final void Function(CarriedItem)? onDismantle;
  final bool Function(CarriedItem)? canDismantle;
  final void Function(CarriedItem)? onStash;
  final VoidCallback? onStopDismantle;
  final String? Function(CarriedItem line, PackAction action)? refusalOf;
  final ValueListenable<CraftJob?>? craftJob;
  final ValueListenable<List<CarriedItem>>? craftLines;

  /// §4.2: tipping them back out again.
  final void Function(CarriedItem)? onEmpty;
  final void Function(CarriedItem)? onRead;
  final void Function(CarriedItem)? onDetails;

  final ValueListenable<Search?>? action;
  final ValueListenable<CarriedItem?>? usingLine;
  final VoidCallback? onCancelAction;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  int _toDrop = 1;

  /// The last reason this row gave for not doing something.
  ///
  /// Held per row rather than shouted at the top of the screen, because the
  /// answer belongs where the question was asked — four rows all saying "the
  /// shelves are full" at once is a wall, and one row saying it under the
  /// glyph that was pressed is an answer.
  String? _refused;

  String? _no(PackAction action) => widget.refusalOf?.call(widget.line, action);

  void _sayNo(String reason) => setState(() => _refused = reason);

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);

    // ⚠️ The reason goes as soon as it stops being true. Left behind, a row
    // would go on saying the shelves are full long after they were emptied —
    // the same lie a dead button tells, only in words.
    if (_refused == null) return;

    final stillTrue = PackAction.values.any(
      (action) => widget.refusalOf?.call(widget.line, action) == _refused,
    );
    if (!stillTrue) _refused = null;
  }

  /// §18.6: whether this very piece is spoken for by the bench.
  ///
  /// ⚠️ Anywhere in the sitting, not just at the head of it. A piece waiting
  /// its turn is as unusable as the one under the multitool — it has been
  /// promised, and letting somebody fire a rifle that is third in the queue
  /// would put it back in the pack in the middle of its own dismantling.
  bool get _busy =>
      widget.craftJob?.value != null &&
      (widget.craftLines?.value ?? const []).any(widget.line.isSame);

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      if (widget.craftJob != null) widget.craftJob!,
      if (widget.craftLines != null) widget.craftLines!,
      if (widget.action != null) widget.action!,
      if (widget.usingLine != null) widget.usingLine!,
    ];

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final colours = HudColors.of(context);
        final line = widget.line;
        final l10n = widget.l10n;

        // §5.6.3: with whatever is bolted on. A suppressor that costs nothing to
        // carry is a suppressor nobody would ever leave behind.
        final mass = line.massKg(
          widget.definition,
          catalogue: widget.catalogue,
        );
        final volume = line.volumeL(
          widget.definition,
          catalogue: widget.catalogue,
        );
        final wearable =
            BodySlot.fromWire(wearSlotOf(widget.definition)) != null ||
            widget.definition.kind == ItemKind.backpack;
        final usable = useOf(widget.definition) != null;

        final count = line.count < 1 ? 1 : line.count;
        final toDrop = _toDrop > count ? count : _toDrop;

        return Container(
          // A frame each. A flat list of rows with two lines of buttons under
          // every one reads as a wall; a boxed row reads as a thing you own.
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(
            border: Border.all(color: colours.muted.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: what it is. Tapping it opens the numbers, and so does
                  // the glyph beside it for anybody who looks for a button.
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onDetails == null
                          ? null
                          : () => widget.onDetails!(line),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  count > 1
                                      ? '${widget.name}  \u00d7$count'
                                      : widget.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colours.text,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _subtitle(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colours.muted,
                                  ),
                                ),

                                // §5.6.3: what is bolted on, and what it bought.
                                // On the row rather than behind a tap, because
                                // which of two rifles to carry into a town is
                                // decided by exactly this line.
                                if (widget.attachments.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.attachmentNames.join(' · '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colours.data,
                                    ),
                                  ),
                                  if (_bonuses().isNotEmpty)
                                    Text(
                                      _bonuses(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colours.data,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.onDetails != null)
                            IconButton(
                              onPressed: () => widget.onDetails!(line),
                              icon: const Icon(Icons.info_outline, size: 18),
                              color: colours.muted,
                              tooltip: l10n.itemDetails,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right: what it costs, and what can be done about it.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${kilograms(mass)}  ·  ${litres(volume)}',
                        style: TextStyle(fontSize: 11, color: colours.data),
                      ),
                      const SizedBox(height: 2),
                      // ⚠️ Nothing at all while it is on the bench (§18.6). Not
                      // greyed — absent. A piece being taken apart that could
                      // still be worn, eaten, dropped or shelved is a piece the
                      // player can spend twice, and the rifle case is the loud
                      // one: it would go on being fired for the quarter of an
                      // hour it takes to open it up.
                      // ⚠️ And nothing on a piece somebody has already opened up
                      // (§18.6). Half a rifle is not a rifle and half a coat does
                      // not keep the rain off — which is what makes stopping half
                      // way a decision rather than a free look inside. What is
                      // left to do with it is finish it, and that is the one glyph
                      // [_ItemRow] still draws below.
                      if (_busy)
                        const SizedBox.shrink()
                      else if (line.isPartlyDismantled)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onDismantle != null)
                              _RowAction(
                                icon: Icons.handyman,
                                tooltip: l10n.craftTakeApart,
                                onPressed: () => widget.onDismantle!(line),
                                colours: colours,
                                refusal: _no(PackAction.dismantle),
                                onRefused: _sayNo,
                              ),
                          ],
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // §4.2: thumbing loose rounds into a magazine. Its own
                            // action, not a reload — it is half a minute of standing
                            // still, which is why it belongs on this screen rather
                            // than on the one the fight is on.
                            if (widget.onFill != null &&
                                Magazine.of(
                                      widget.definition,
                                      rounds: line.rounds ?? 0,
                                    )?.isFull ==
                                    false)
                              _RowAction(
                                icon: Icons.download,
                                tooltip: l10n.magazineFill,
                                onPressed: () => widget.onFill!(line),
                                colours: colours,
                                refusal: _no(PackAction.fill),
                                onRefused: _sayNo,
                              ),

                            // §4.2: and tipping them back out. A magazine is emptied
                            // to fill a different one, or to leave the weight behind
                            // — the same half minute, in the other direction.
                            if (widget.onEmpty != null &&
                                Magazine.of(
                                      widget.definition,
                                      rounds: line.rounds ?? 0,
                                    )?.isEmpty ==
                                    false)
                              _RowAction(
                                icon: Icons.upload,
                                tooltip: l10n.magazineEmpty,
                                onPressed: () => widget.onEmpty!(line),
                                colours: colours,
                                refusal: _no(PackAction.empty),
                                onRefused: _sayNo,
                              ),

                            // §18.2: onto the shelf, one tap, without going
                            // through the shelves screen — that screen is for
                            // taking things *out*, and putting four things away
                            // through it was four trips.
                            if (widget.onStash != null)
                              _RowAction(
                                icon: Icons.inventory_2,
                                tooltip: l10n.stashStore,
                                onPressed: () => widget.onStash!(line),
                                colours: colours,
                                refusal: _no(PackAction.stash),
                                onRefused: _sayNo,
                              ),

                            // §18.6: taking it apart for what is in it. Last in
                            // the row, because nothing else here destroys the thing
                            // it acts on.
                            if (widget.onDismantle != null &&
                                (widget.canDismantle?.call(line) ?? false))
                              _RowAction(
                                icon: Icons.handyman,
                                tooltip: l10n.craftTakeApart,
                                onPressed: () => widget.onDismantle!(line),
                                colours: colours,
                                refusal: _no(PackAction.dismantle),
                                onRefused: _sayNo,
                              ),

                            if (usable && widget.onUse != null)
                              _RowAction(
                                icon: Icons.restaurant,
                                tooltip: l10n.inventoryUse,
                                onPressed: () => widget.onUse!(line),
                                colours: colours,
                                refusal: _no(PackAction.use),
                                onRefused: _sayNo,
                              ),
                            if (wearable && widget.onWear != null)
                              _RowAction(
                                icon: Icons.checkroom,
                                tooltip: l10n.inventoryWear,
                                onPressed: () => widget.onWear!(line),
                                colours: colours,
                                refusal: _no(PackAction.wear),
                                onRefused: _sayNo,
                              ),
                            if (line.noteId != null && widget.onRead != null)
                              _RowAction(
                                icon: Icons.description_outlined,
                                tooltip: l10n.noteRead,
                                onPressed: () => widget.onRead!(line),
                                colours: colours,
                                refusal: _no(PackAction.read),
                                onRefused: _sayNo,
                              ),
                            if (widget.onDrop != null) ...[
                              // Only where there is a choice to make. A stepper
                              // beside a single bandage is a control with one
                              // setting.
                              if (count > 1)
                                _Stepper(
                                  value: toDrop,
                                  max: count,
                                  onChanged: (value) =>
                                      setState(() => _toDrop = value),
                                  colours: colours,
                                ),
                              _RowAction(
                                icon: Icons.delete_outline,
                                tooltip: l10n.inventoryDrop,
                                onPressed: () => widget.onDrop!(line, toDrop),
                                colours: colours,
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              // Under this piece, and only while it is this piece being used.
              //
              // \u26a0\ufe0f The piece, not the item id. Found on a phone: a tin opened
              // out of a stack of four leaves a part-eaten one beside three whole
              // ones, and matching by id drew the same bar under both rows.
              // The last thing this row would not do, and why (§12).
              //
              // ⚠️ Under the row rather than shouted at the top of the screen.
              // Four rows all saying "the shelves are full" at once is a wall;
              // one row saying it under the glyph that was pressed is an answer.
              if (_refused case final reason?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 12, color: colours.alert),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(fontSize: 11, color: colours.alert),
                        ),
                      ),
                    ],
                  ),
                ),

              // §18.6, §2.1a.3: the multitool, under the thing it is opening.
              //
              // ⚠️ The bar belongs here rather than on the bench screen, because
              // this is where the player is looking: they tapped a row, and the
              // row is what has to answer. The same piece is locked while it runs,
              // so a rifle being taken apart cannot be worn and fired.
              if (widget.craftJob != null)
                ValueListenableBuilder<List<CarriedItem>>(
                  valueListenable: widget.craftLines ?? const _NoLines(),
                  builder: (context, sitting, _) =>
                      ValueListenableBuilder<CraftJob?>(
                        valueListenable: widget.craftJob!,
                        builder: (context, job, _) {
                          // ⚠️ The head only. Everything else in the sitting is
                          // locked and waiting, and a bar under a row that has
                          // not been started on is a bar that lies.
                          final head = sitting.firstOrNull;
                          if (job == null ||
                              head == null ||
                              !line.isSame(head)) {
                            return const SizedBox.shrink();
                          }

                          return _CraftRunning(
                            job: job,
                            onStop: widget.onStopDismantle,
                            colours: colours,
                          );
                        },
                      ),
                ),

              if (widget.action != null)
                ValueListenableBuilder<CarriedItem?>(
                  // Listened to as well as read: which piece is in hand changes
                  // when a use ends, and a bar left behind by a finished action is
                  // a bar that never goes away.
                  valueListenable: widget.usingLine ?? const _NoLine(),
                  builder: (context, using, _) =>
                      ValueListenableBuilder<Search?>(
                        valueListenable: widget.action!,
                        builder: (context, running, _) =>
                            running == null ||
                                !running.isRunning ||
                                !_isMine(running, using)
                            ? const SizedBox.shrink()
                            : _Running(
                                search: running,
                                onCancel: widget.onCancelAction,
                                colours: colours,
                                cancelLabel: l10n.searchCancel,
                              ),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Whether the running action belongs to this row.
  ///
  /// By identity where the screen was told which piece is in hand, and by item
  /// id only as a fallback — which is right for a caller that has no way to
  /// say, and wrong the moment two rows share an id.
  bool _isMine(Search running, CarriedItem? using) {
    if (using != null) return widget.line.isSame(using);
    if (widget.usingLine != null) return false;
    return running.usingItemId == widget.line.itemId;
  }

  /// What the line is, plus whatever per-piece state it carries: how worn it
  /// is, or how far through a book the player has read (§4.6.3).
  /// What the fitted parts changed, as the differences themselves.
  ///
  /// Differences rather than totals: "−1,5 MOA" is the reason to bolt the
  /// thing on, and "3,2 MOA" is a number that means nothing without the one it
  /// replaced.
  String _bonuses() {
    if (widget.attachments.isEmpty) return '';

    final bare = FittedWeapon(weapon: widget.definition);
    final fitted = FittedWeapon(
      weapon: widget.definition,
      attachments: widget.attachments,
    );

    final parts = <String>[];

    void delta(String unit, double from, double to, {int decimals = 0}) {
      final change = to - from;
      if (change.abs() < 0.05) return;

      final sign = change > 0 ? '+' : '−';
      parts.add('$sign${change.abs().toStringAsFixed(decimals)} $unit');
    }

    delta('MOA', bare.moa, fitted.moa, decimals: 1);
    delta(
      widget.l10n.statMagazine,
      bare.magazine.toDouble(),
      fitted.magazine.toDouble(),
    );
    delta('m', bare.noiseRangeM, fitted.noiseRangeM);
    delta(
      's',
      bare.reloadTime.inMilliseconds / 1000,
      fitted.reloadTime.inMilliseconds / 1000,
      decimals: 1,
    );

    if (fitted.lightRadiusM > 0) {
      parts.add('${fitted.lightRadiusM.round()} m ${widget.l10n.statLight}');
    }
    return parts.join(' · ');
  }

  String _subtitle() {
    final parts = <String>[widget.kind];

    final condition = widget.line.condition;
    if (condition != null) parts.add('${condition.round()}%');

    final pages = widget.line.pagesTotal;
    if (pages != null) parts.add('${widget.line.pagesRead} / $pages');

    // §4.7: what is left of a bottle somebody put down half way through.
    final portion = widget.line.portion;
    if (portion < 1) {
      parts.add(widget.l10n.inventoryPortion((portion * 100).round()));
    }

    // §18.6: and whether somebody has already been at it with a multitool.
    // Said first among the qualifiers, because it is the one that decides
    // whether the thing works at all.
    if (widget.line.isPartlyDismantled) {
      parts.add(widget.l10n.craftPartlyApart);
    }

    // §5.3: and what is in a magazine, or in the gun. The one number that
    // decides whether a rifle in the pack is a weapon or a stick — and until
    // now the pack said nothing about it at all.
    final rounds = widget.line.rounds;
    if (rounds != null) {
      final magazine = Magazine.of(widget.definition, rounds: rounds);
      parts.add(
        magazine == null
            ? '$rounds'
            : widget.l10n.magazineRounds(rounds, magazine.capacity),
      );
    }

    return parts.join(' · ');
  }
}

/// A listenable that is always null, for a screen told nothing about which
/// piece is in hand — every test that predates part-used items, and the dev
/// tools. Const, so it costs nothing to hand out.
class _NoLines implements ValueListenable<List<CarriedItem>> {
  const _NoLines();

  @override
  List<CarriedItem> get value => const [];

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _NoLine implements ValueListenable<CarriedItem?> {
  const _NoLine();

  @override
  CarriedItem? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// One thing that can be done to a row: a glyph, named for a long press.
///
/// Words here cost a line each and there are four of them; a row that spends
/// two lines on its own buttons stops being a row. What the glyph means is in
/// its tooltip and in the screen-reader label, which is where \u00a712 asks for it.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colours,
    this.refusal,
    this.onRefused,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final HudColors colours;

  /// Why this cannot happen right now, or null.
  final String? refusal;

  /// What to do when somebody presses it anyway: say the reason under the row.
  ///
  /// ⚠️ Still pressable. A greyed control that swallows the tap teaches
  /// nothing — the player presses it twice, decides the game is broken and
  /// writes that down. This one answers.
  final void Function(String reason)? onRefused;

  @override
  Widget build(BuildContext context) {
    final no = refusal;

    return IconButton(
      onPressed: no == null ? onPressed : () => onRefused?.call(no),
      icon: Icon(icon, size: 20),
      tooltip: no ?? tooltip,
      color: no == null ? colours.text : colours.muted.withValues(alpha: 0.55),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}

/// How many of a stack to put down.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.colours,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove, size: 18),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
      SizedBox(
        width: 24,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: colours.text,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      IconButton(
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add, size: 18),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    ],
  );
}

/// What a kind of item is called, in the player's language.
///
/// The enum name is not a label: a Polish player reading "armor" under a coat
/// is reading the source code (§1.1).
String kindName(L10n l10n, ItemKind kind) => switch (kind) {
  ItemKind.firearm => l10n.kindFirearm,
  ItemKind.melee => l10n.kindMelee,
  ItemKind.armor => l10n.kindArmor,
  ItemKind.backpack => l10n.kindBackpack,
  ItemKind.food => l10n.kindFood,
  ItemKind.medical => l10n.kindMedical,
  ItemKind.literature => l10n.kindLiterature,
  ItemKind.tool => l10n.kindTool,
  ItemKind.attachment => l10n.kindAttachment,
  ItemKind.crafting => l10n.kindCrafting,
  ItemKind.ammo => l10n.kindAmmo,
  ItemKind.material => l10n.kindMaterial,
  ItemKind.misc => l10n.kindMisc,
};

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.hint,
    required this.colours,
  });

  final String title;
  final String hint;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: colours.text)),
        const SizedBox(height: 4),
        Text(hint, style: TextStyle(fontSize: 12, color: colours.muted)),
      ],
    ),
  );
}

/// §18.6, §2.1a.3: the bench, under the row it is holding.
///
/// ⚠️ Its own clock. The job is a row in a database with a deadline on it,
/// not a ticking notifier — nothing pushes an update every second, so a bar
/// drawn from it would sit perfectly still for a quarter of an hour and read
/// as broken.
class _CraftRunning extends StatefulWidget {
  const _CraftRunning({
    required this.job,
    required this.onStop,
    required this.colours,
  });

  final CraftJob job;

  /// §18.6: stopping keeps the work. It does not give the piece back.
  final VoidCallback? onStop;

  final HudColors colours;

  @override
  State<_CraftRunning> createState() => _CraftRunningState();
}

class _CraftRunningState extends State<_CraftRunning>
    with WidgetsBindingObserver, Ticking<_CraftRunning> {
  @override
  bool get ticking => !widget.job.isDoneAt(DateTime.now().toUtc());

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final left = widget.job.remainingAt(now);
    final l10n = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handyman, size: 13, color: widget.colours.data),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.craftTakeApartRunning,
                  style: TextStyle(fontSize: 11, color: widget.colours.muted),
                ),
              ),
              Text(
                remaining(left),
                style: TextStyle(
                  fontSize: 11,
                  color: widget.colours.data,
                  fontFamily: kDataFont,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (widget.onStop != null)
                IconButton(
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  tooltip: l10n.craftStop,
                  color: widget.colours.muted,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: widget.job.progressAt(now),
            minHeight: 3,
            backgroundColor: widget.colours.muted.withValues(alpha: 0.25),
            color: widget.colours.data,
          ),
        ],
      ),
    );
  }
}

class _QuestStatusDisplay extends StatelessWidget {
  const _QuestStatusDisplay({
    required this.goal,
    required this.inventory,
    required this.catalogue,
    required this.language,
  });

  final PinnedGoal goal;
  final Inventory inventory;
  final ItemCatalogue catalogue;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);

    // Check if goal is fully met
    bool allMet = true;
    final List<Widget> requirements = [];

    for (final entry in goal.requirements.entries) {
      final itemId = entry.key;
      final requiredCount = entry.value;
      final haveCount = inventory.countOf(itemId);
      final met = haveCount >= requiredCount;
      if (!met) allMet = false;

      final def = catalogue[itemId];
      final name =
          def?.name.resolve(language: language, lookup: null) ?? itemId;

      requirements.add(
        Text(
          '${met ? '✓ ' : ''}$name: $haveCount / $requiredCount',
          style: TextStyle(
            fontSize: 12,
            color: met ? colours.data : colours.alert,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colours.panel.withValues(alpha: 0.8),
        border: Border.all(color: allMet ? colours.data : colours.alert),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, size: 16, color: colours.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cel: ${goal.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colours.text,
                  ),
                ),
              ),
              if (allMet)
                Text(
                  'GOTOWE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colours.data,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: requirements),
        ],
      ),
    );
  }
}
