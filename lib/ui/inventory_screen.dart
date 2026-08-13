/// EKWIPUNEK, the second entry of §3.6's bottom menu.
///
/// The screen answers one question — what am I carrying and what is it costing
/// me — so the two limits of §18.1a are at the top, above everything else, and
/// every line carries its own mass and bulk. A player deciding what to leave
/// behind needs both figures per item; a total alone says something must go
/// without saying what.
///
/// Worn kit is listed apart from packed kit, because they cost differently: a
/// coat on your back counts against mass and not against the pack (§18.1a).
library;

import 'package:flutter/material.dart';

import '../devtools/dev_mode.dart';
import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../l10n/app_localizations.dart';
import '../sim/body.dart';
import 'hud.dart' show HudColors;

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    required this.inventory,
    required this.catalogue,
    required this.names,
    required this.body,
    this.onDrop,
    this.onDevFill,
    super.key,
  });

  final Inventory inventory;
  final ItemCatalogue catalogue;
  final ItemNames names;
  final BodyProfile body;

  /// Null while there is nowhere for a dropped item to go. §4.8 puts it on the
  /// map for 24 hours, and that arrives with the loot layer.
  final void Function(CarriedItem line)? onDrop;

  /// Fills the pack with a sample kit. Developer builds only, and only until
  /// the loot layer of §10 gives the game a real way to hand out items — until
  /// then this screen has nothing to show and no way to be tried on a phone.
  final VoidCallback? onDevFill;

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFE8B33A),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _PackLine(
            label: l10n.inventoryBackpack,
            value: inventory.packId == null
                ? l10n.inventoryNoBackpack
                : _nameOf(inventory.packId!, language),
            colours: colours,
          ),
          if (inventory.worn.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(label: l10n.inventoryWorn, colours: colours),
            for (final line in inventory.worn)
              _ItemRow(
                line: line,
                definition: catalogue[line.itemId]!,
                name: _nameOf(line.itemId, language),
                kind: kindName(l10n, catalogue[line.itemId]!.kind),
                onDrop: null,
              ),
          ],
          const SizedBox(height: 20),
          _SectionHeader(label: l10n.inventoryPack, colours: colours),
          if (inventory.carried.isEmpty)
            _Empty(
              title: l10n.inventoryEmpty,
              hint: l10n.inventoryEmptyHint,
              colours: colours,
            )
          else
            for (final line in _sorted(inventory.carried))
              _ItemRow(
                line: line,
                definition: catalogue[line.itemId]!,
                name: _nameOf(line.itemId, language),
                kind: kindName(l10n, catalogue[line.itemId]!.kind),
                onDrop: onDrop == null ? null : () => onDrop!(line),
                dropLabel: l10n.inventoryDrop,
              ),
        ],
      ),
    );
  }

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
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.4,
        color: colours.muted,
      ),
    ),
  );
}

class _PackLine extends StatelessWidget {
  const _PackLine({
    required this.label,
    required this.value,
    required this.colours,
  });

  final String label;
  final String value;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: colours.muted),
      ),
      Text(value, style: TextStyle(fontSize: 13, color: colours.text)),
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
  ItemKind.crafting => l10n.kindCrafting,
  ItemKind.ammo => l10n.kindAmmo,
  ItemKind.material => l10n.kindMaterial,
  ItemKind.misc => l10n.kindMisc,
};

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.line,
    required this.definition,
    required this.name,
    required this.kind,
    required this.onDrop,
    this.dropLabel,
  });

  final CarriedItem line;
  final ItemDefinition definition;
  final String name;

  /// Translated, and passed in rather than looked up here: a row should not
  /// need a localisation context to know what it is showing.
  final String kind;
  final VoidCallback? onDrop;
  final String? dropLabel;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final mass = line.massKg(definition);
    final volume = line.volumeL(definition);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.count > 1 ? '$name  ×${line.count}' : name,
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
          Text(
            '${mass.toStringAsFixed(mass < 1 ? 2 : 1)} kg\n'
            '${volume.toStringAsFixed(volume < 1 ? 2 : 1)} l',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: colours.data,
            ),
          ),
          if (onDrop != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: onDrop,
                child: Text(dropLabel ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  /// What the line is, plus whatever per-piece state it carries: how worn it
  /// is, or how far through a book the player has read (§4.6.3).
  String _subtitle() {
    final parts = <String>[kind];

    final condition = line.condition;
    if (condition != null) parts.add('${condition.round()}%');

    final pages = line.pagesTotal;
    if (pages != null) parts.add('${line.pagesRead} / $pages');

    return parts.join(' · ');
  }
}

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
