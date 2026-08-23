/// The shelves of a shelter, and the pack beside them (§18.2, §8.5.1).
///
/// Two lists on one screen rather than a sheet over the inventory, because the
/// decision being made is a comparison: what is worth the kilogram on a walk
/// against what is worth keeping for a walk that has not happened yet. Reading
/// that off two screens, one at a time, is how a player ends up carrying a
/// spare rifle around a city for a week.
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../inventory/body_slots.dart';
import '../inventory/inventory.dart';
import '../inventory/item_use.dart';
import '../items/item.dart';
import '../craft/craft_job.dart';
import 'action_strip.dart';
import 'inventory_screen.dart' show PackAction, PackOrder;
import '../items/item_catalogue.dart';
import '../shelter/stash.dart';
import 'fonts.dart';
import 'units.dart';
import 'hud.dart' show HudColors;
import '../l10n/app_localizations.dart';
import 'effects.dart';

class StashScreen extends StatelessWidget {
  const StashScreen({
    required this.title,
    required this.stash,
    required this.pack,
    required this.catalogue,
    required this.nameOf,
    required this.onStore,
    required this.onTake,
    required this.order,
    this.job,
    this.jobLabel,
    this.onStopJob,
    this.onAct,
    this.onDetails,
    this.canDismantle,
    this.refusalOf,
    super.key,
  });

  final String title;

  /// Both sides are notifiers rather than values: putting something down
  /// changes the other list too, and two screens' worth of state that can
  /// disagree is the bug this whole codebase keeps finding.
  final ValueListenable<Stash> stash;
  final ValueListenable<Inventory> pack;

  final ItemCatalogue catalogue;
  final String Function(String itemId) nameOf;

  /// Moving a line from the pack onto the shelves, and back.
  final void Function(CarriedItem line) onStore;
  final void Function(int index) onTake;

  /// ⚠️ Shared with the pack screen, and owned by the caller.
  ///
  /// One order for both screens, because they are one decision seen twice —
  /// and a choice held inside a pushed route is a choice forgotten every time
  /// the player closes it, which is the bug class this codebase has now found
  /// six times.
  final ValueNotifier<PackOrder> order;

  /// §18.2: doing something to a piece **on a shelf**, by its index.
  ///
  /// The index rather than the line, because the caller picks it up first and
  /// needs to know which one to take. Everything a player does to something on
  /// a shelf is the same motion in the world — reaching for it.
  final void Function(int index, PackAction action)? onAct;

  /// §5.6.3: the numbers, and the attachment slots with them.
  final void Function(int index)? onDetails;

  /// §18.6: whether anything would come out of this piece.
  final bool Function(CarriedItem line)? canDismantle;

  /// §12: why an action would not work right now, or null.
  final String? Function(CarriedItem line, PackAction action)? refusalOf;

  /// §18.4, §12: what the bench is doing, said here too.
  ///
  /// ⚠️ The shelves are where somebody stands while they are waiting on the
  /// bench — they came in to put things away *because* a spear is being made —
  /// so this screen answers the question rather than sending them back out to
  /// the map to read the strip.
  final ValueListenable<CraftJob?>? job;
  final String Function(CraftJob job)? jobLabel;
  final VoidCallback? onStopJob;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder<Stash>(
        valueListenable: stash,
        builder: (context, shelves, _) => ValueListenableBuilder<Inventory>(
          valueListenable: pack,
          builder: (context, carried, _) => ValueListenableBuilder<PackOrder>(
            valueListenable: order,
            builder: (context, _, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _Gauges(stash: shelves, catalogue: catalogue, colours: colours),

                if (job != null)
                  ValueListenableBuilder<CraftJob?>(
                    valueListenable: job!,
                    builder: (context, running, _) => running == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ActionStrip(
                              actions: [
                                RunningAction(
                                  icon: Icons.handyman,
                                  label:
                                      jobLabel?.call(running) ??
                                      l10n.craftTitle,
                                  startedAt: running.startedAt,
                                  readyAt: running.readyAt,
                                  onStop: onStopJob,
                                ),
                              ],
                            ),
                          ),
                  ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _Heading(
                        label: l10n.stashOnTheShelves,
                        colours: colours,
                      ),
                    ),
                    // The same cycling control the pack has, on the same
                    // notifier: two screens, one decision, one order.
                    TextButton(
                      onPressed: () => order.value = switch (order.value) {
                        PackOrder.kind => PackOrder.name,
                        PackOrder.name => PackOrder.mass,
                        PackOrder.mass => PackOrder.kind,
                      },
                      child: Text(switch (order.value) {
                        PackOrder.kind => l10n.packOrderKind,
                        PackOrder.name => l10n.packOrderName,
                        PackOrder.mass => l10n.packOrderMass,
                      }, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),

                if (shelves.lines.isEmpty)
                  _Nothing(text: l10n.stashEmpty, colours: colours)
                else
                  // ⚠️ Sorted for reading, acted on by original index. The
                  // shelf is a list the caller indexes into, and handing it
                  // the position on screen would take the wrong thing off it
                  // the moment the order is anything but the stored one.
                  for (final (index, line) in _sorted(shelves.lines).indexed)
                    _Line(
                      key: ValueKey('shelf.$index.${line.itemId}'),
                      line: line,
                      name: nameOf(line.itemId),
                      catalogue: catalogue,
                      colours: colours,
                      action: l10n.stashTake,
                      nameOf: nameOf,
                      onTap: () => onTake(shelves.lines.indexOf(line)),
                      onDetails: onDetails == null
                          ? null
                          : () => onDetails!(shelves.lines.indexOf(line)),
                      onAct: onAct == null
                          ? null
                          : (action) =>
                                onAct!(shelves.lines.indexOf(line), action),
                      canDismantle: canDismantle?.call(line) ?? false,
                      refusalOf: refusalOf,
                      l10n: l10n,
                    ),

                const SizedBox(height: 24),
                _Heading(label: l10n.stashInThePack, colours: colours),
                if (carried.carried.isEmpty)
                  _Nothing(text: l10n.stashPackEmpty, colours: colours)
                else
                  for (final line in _sorted(carried.carried))
                    _Line(
                      line: line,
                      name: nameOf(line.itemId),
                      catalogue: catalogue,
                      colours: colours,
                      action: l10n.stashStore,
                      nameOf: nameOf,
                      // §18.2: the shelf refuses what will not fit, and says
                      // so rather than silently keeping it in the pack.
                      enabled: shelves.fits(line.copyWith(count: 1), catalogue),
                      onTap: () => onStore(line.copyWith(count: 1)),
                      l10n: l10n,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The same three orders the pack offers, over whichever list (§18.1a).
  List<CarriedItem> _sorted(List<CarriedItem> lines) {
    final sorted = [...lines];

    int byName(CarriedItem a, CarriedItem b) => nameOf(
      a.itemId,
    ).toLowerCase().compareTo(nameOf(b.itemId).toLowerCase());

    sorted.sort((a, b) {
      final left = catalogue[a.itemId];
      final right = catalogue[b.itemId];
      if (left == null || right == null) return 0;

      switch (order.value) {
        case PackOrder.kind:
          final byKind = left.kind.index.compareTo(right.kind.index);
          return byKind != 0 ? byKind : byName(a, b);

        case PackOrder.mass:
          final byMass = b
              .massKg(right, catalogue: catalogue)
              .compareTo(a.massKg(left, catalogue: catalogue));
          return byMass != 0 ? byMass : byName(a, b);

        case PackOrder.name:
          return byName(a, b);
      }
    });

    return sorted;
  }
}

/// §18.1a: both limits, because either one is the one that runs out.
class _Gauges extends StatelessWidget {
  const _Gauges({
    required this.stash,
    required this.catalogue,
    required this.colours,
  });

  final Stash stash;
  final ItemCatalogue catalogue;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Gauge(
        share: stash.massShare(catalogue),
        value: outOfKg(stash.massKg(catalogue), stash.capacityKg),
        colours: colours,
      ),
      const SizedBox(height: 6),
      _Gauge(
        share: stash.volumeShare(catalogue),
        value: outOfL(stash.volumeL(catalogue), stash.capacityL),
        colours: colours,
      ),
    ],
  );
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.share,
    required this.value,
    required this.colours,
  });

  final double share;
  final String value;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final clamped = share.clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 5,
            backgroundColor: colours.muted.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation(
              clamped >= 0.999 ? colours.alert : colours.data,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: colours.text,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatefulWidget {
  const _Line({
    required this.line,
    required this.name,
    required this.catalogue,
    required this.colours,
    required this.action,
    required this.onTap,
    required this.nameOf,
    required this.l10n,
    this.enabled = true,
    this.onAct,
    this.onDetails,
    this.canDismantle = false,
    this.refusalOf,
    super.key,
  });

  final CarriedItem line;
  final String name;

  /// For the attachment names under it: an item id is not a thing to read.
  final String Function(String itemId) nameOf;
  final ItemCatalogue catalogue;
  final HudColors colours;
  final String action;
  final VoidCallback onTap;
  final bool enabled;
  final L10n l10n;

  /// §18.2: eating, wearing or taking apart something that is on a shelf.
  final void Function(PackAction action)? onAct;
  final VoidCallback? onDetails;
  final bool canDismantle;
  final String? Function(CarriedItem line, PackAction action)? refusalOf;

  @override
  State<_Line> createState() => _LineState();
}

class _LineState extends State<_Line> {
  /// The last thing this row would not do, and why (§12).
  String? _refused;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final catalogue = widget.catalogue;
    final colours = widget.colours;
    final nameOf = widget.nameOf;
    final name = widget.name;
    final enabled = widget.enabled;
    final l10n = widget.l10n;

    final definition = catalogue[line.itemId];
    if (definition == null) return const SizedBox.shrink();

    final mass = line.massKg(definition, catalogue: catalogue);
    final volume = line.volumeL(definition, catalogue: catalogue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.count > 1 ? '$name  ×${line.count}' : name,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? colours.text : colours.muted,
                  ),
                ),

                // §5.6.3: what is bolted to this one, because it is why this
                // rifle is not the other rifle.
                if (line.attachments.isNotEmpty)
                  Text(
                    effects(line.attachments.map(nameOf)),
                    style: TextStyle(fontSize: 11, color: colours.data),
                  ),
                const SizedBox(height: 2),
                Text(
                  effects([kilograms(mass), litres(volume)]),
                  style: TextStyle(
                    fontSize: 11,
                    color: colours.muted,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),

                // §12: the last thing this row would not do, under the row
                // that would not do it.
                if (_refused case final reason?) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: TextStyle(fontSize: 11, color: colours.alert),
                  ),
                ],
              ],
            ),
          ),
          // §18.2: what can be done with it without moving it first.
          //
          // ⚠️ The same glyphs the pack row uses, in the same order, and each
          // of them picks the piece up before doing anything. Eating off a
          // shelf and eating out of a bag are the same motion in the world;
          // making them the same motion here means the carry limits, the
          // dismantling lock and the attachment slots all go on applying.
          if (widget.onAct != null) ...[
            if (useOf(definition) != null)
              _ShelfAction(
                icon: Icons.restaurant,
                tooltip: l10n.inventoryUse,
                action: PackAction.use,
                line: line,
                onAct: widget.onAct!,
                refusalOf: widget.refusalOf,
                onRefused: _sayNo,
                colours: colours,
              ),
            if (BodySlot.fromWire(wearSlotOf(definition)) != null ||
                definition.kind == ItemKind.backpack)
              _ShelfAction(
                icon: Icons.checkroom,
                tooltip: l10n.inventoryWear,
                action: PackAction.wear,
                line: line,
                onAct: widget.onAct!,
                refusalOf: widget.refusalOf,
                onRefused: _sayNo,
                colours: colours,
              ),
            if (widget.canDismantle)
              _ShelfAction(
                icon: Icons.handyman,
                tooltip: l10n.craftTakeApart,
                action: PackAction.dismantle,
                line: line,
                onAct: widget.onAct!,
                refusalOf: widget.refusalOf,
                onRefused: _sayNo,
                colours: colours,
              ),
          ],
          if (widget.onDetails != null)
            IconButton(
              onPressed: widget.onDetails,
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: l10n.itemDetails,
              color: colours.muted,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),

          TextButton(
            onPressed: enabled ? widget.onTap : null,
            child: Text(widget.action),
          ),
        ],
      ),
    );
  }

  void _sayNo(String reason) => setState(() => _refused = reason);
}

/// One thing that can be done to a piece on a shelf (§18.2, §12).
class _ShelfAction extends StatelessWidget {
  const _ShelfAction({
    required this.icon,
    required this.tooltip,
    required this.action,
    required this.line,
    required this.onAct,
    required this.onRefused,
    required this.colours,
    this.refusalOf,
  });

  final IconData icon;
  final String tooltip;
  final PackAction action;
  final CarriedItem line;
  final void Function(PackAction action) onAct;
  final void Function(String reason) onRefused;
  final String? Function(CarriedItem line, PackAction action)? refusalOf;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final no = refusalOf?.call(line, action);

    return IconButton(
      onPressed: no == null ? () => onAct(action) : () => onRefused(no),
      icon: Icon(icon, size: 18),
      tooltip: no ?? tooltip,
      color: no == null ? colours.text : colours.muted.withValues(alpha: 0.55),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label, required this.colours});

  final String label;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: colours.muted),
    ),
  );
}

class _Nothing extends StatelessWidget {
  const _Nothing({required this.text, required this.colours});

  final String text;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: TextStyle(fontSize: 12, color: colours.muted)),
  );
}
