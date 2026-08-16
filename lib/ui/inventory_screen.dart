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

import '../devtools/dev_mode.dart';
import '../inventory/body_slots.dart';
import '../inventory/inventory.dart';
import '../inventory/item_use.dart';
import '../combat/attachment.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../l10n/app_localizations.dart';
import '../loot/search.dart';
import '../sim/body.dart';
import 'hud.dart' show HudColors;

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    required this.inventory,
    required this.catalogue,
    required this.names,
    required this.body,
    this.onDrop,
    this.onWear,
    this.onTakeOff,
    this.onUse,
    this.onRead,
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
    builder: (context, inventory, _) => _build(context, inventory),
  );

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
          _SectionHeader(label: l10n.inventoryPack, colours: colours),
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
            for (final (index, line) in _sorted(inventory.carried).indexed)
              _ItemRow(
                key: ValueKey('$index.${line.itemId}'),
                line: line,
                definition: catalogue[line.itemId]!,
                name: _nameOf(line.itemId, language),
                kind: kindName(l10n, catalogue[line.itemId]!.kind),
                l10n: l10n,
                onDrop: onDrop,
                onWear: onWear,
                onUse: onUse,
                onRead: onRead,
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
  List<CarriedItem> _sorted(List<CarriedItem> lines) {
    final sorted = [...lines];
    sorted.sort((a, b) {
      final byMass = b
          .massKg(catalogue[b.itemId]!)
          .compareTo(a.massKg(catalogue[a.itemId]!));
      return byMass != 0 ? byMass : a.itemId.compareTo(b.itemId);
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
                child: Text(
                  worn == null ? emptyLabel : nameOf(worn.itemId),
                  style: TextStyle(
                    fontSize: 13,
                    color: worn == null ? colours.muted : colours.text,
                    fontStyle: worn == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
            if (definition != null)
              Text(
                '${worn!.massKg(definition).toStringAsFixed(1)} kg',
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
          value: '${massKg.toStringAsFixed(1)} / ${maxKg.toStringAsFixed(0)} kg',
          fraction: maxKg > 0 ? massKg / maxKg : 0,
          markAt: maxKg > 0 ? comfortKg / maxKg : null,
          warning: massKg > comfortKg,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _Gauge(
          label: bulkLabel,
          value:
              '${volumeL.toStringAsFixed(1)} / ${capacityL.toStringAsFixed(0)} l',
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
    this.onDetails,
    this.action,
    this.usingLine,
    this.onCancelAction,
  });

  final CarriedItem line;
  final ItemDefinition definition;
  final String name;

  /// §5.6.3: what is on this weapon, and what those parts are called.
  final List<ItemDefinition> attachments;
  final List<String> attachmentNames;

  final String kind;
  final L10n l10n;

  final void Function(CarriedItem, int)? onDrop;
  final void Function(CarriedItem)? onWear;
  final void Function(CarriedItem)? onUse;
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

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final line = widget.line;
    final l10n = widget.l10n;

    final mass = line.massKg(widget.definition);
    final volume = line.volumeL(widget.definition);
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
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    '${mass.toStringAsFixed(mass < 1 ? 2 : 1)} kg  \u00b7  '
                    '${volume.toStringAsFixed(volume < 1 ? 2 : 1)} l',
                    style: TextStyle(fontSize: 11, color: colours.data),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (usable && widget.onUse != null)
                        _RowAction(
                          icon: Icons.restaurant,
                          tooltip: l10n.inventoryUse,
                          onPressed: () => widget.onUse!(line),
                          colours: colours,
                        ),
                      if (wearable && widget.onWear != null)
                        _RowAction(
                          icon: Icons.checkroom,
                          tooltip: l10n.inventoryWear,
                          onPressed: () => widget.onWear!(line),
                          colours: colours,
                        ),
                      if (line.noteId != null && widget.onRead != null)
                        _RowAction(
                          icon: Icons.description_outlined,
                          tooltip: l10n.noteRead,
                          onPressed: () => widget.onRead!(line),
                          colours: colours,
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
          if (widget.action != null)
            ValueListenableBuilder<CarriedItem?>(
              // Listened to as well as read: which piece is in hand changes
              // when a use ends, and a bar left behind by a finished action is
              // a bar that never goes away.
              valueListenable: widget.usingLine ?? const _NoLine(),
              builder: (context, using, _) => ValueListenableBuilder<Search?>(
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
  }

  /// Whether the running action belongs to this row.
  ///
  /// By identity where the screen was told which piece is in hand, and by item
  /// id only as a fallback — which is right for a caller that has no way to
  /// say, and wrong the moment two rows share an id.
  bool _isMine(Search running, CarriedItem? using) {
    if (using != null) return identical(using, widget.line);
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

    return parts.join(' · ');
  }
}

/// A listenable that is always null, for a screen told nothing about which
/// piece is in hand — every test that predates part-used items, and the dev
/// tools. Const, so it costs nothing to hand out.
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
    color: colours.text,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  );
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
