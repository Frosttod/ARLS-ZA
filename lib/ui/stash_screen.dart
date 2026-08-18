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

import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';
import '../shelter/stash.dart';
import 'fonts.dart';
import 'hud.dart' show HudColors;
import '../l10n/app_localizations.dart';

class StashScreen extends StatelessWidget {
  const StashScreen({
    required this.title,
    required this.stash,
    required this.pack,
    required this.catalogue,
    required this.nameOf,
    required this.onStore,
    required this.onTake,
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
          builder: (context, carried, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Gauges(stash: shelves, catalogue: catalogue, colours: colours),
              const SizedBox(height: 18),

              _Heading(label: l10n.stashOnTheShelves, colours: colours),
              if (shelves.lines.isEmpty)
                _Nothing(text: l10n.stashEmpty, colours: colours)
              else
                for (var i = 0; i < shelves.lines.length; i++)
                  _Line(
                    line: shelves.lines[i],
                    name: nameOf(shelves.lines[i].itemId),
                    catalogue: catalogue,
                    colours: colours,
                    action: l10n.stashTake,
                    nameOf: nameOf,
                    onTap: () => onTake(i),
                  ),

              const SizedBox(height: 24),
              _Heading(label: l10n.stashInThePack, colours: colours),
              if (carried.carried.isEmpty)
                _Nothing(text: l10n.stashPackEmpty, colours: colours)
              else
                for (final line in carried.carried)
                  _Line(
                    line: line,
                    name: nameOf(line.itemId),
                    catalogue: catalogue,
                    colours: colours,
                    action: l10n.stashStore,
                    nameOf: nameOf,
                    // §18.2: the shelf refuses what will not fit, and says so
                    // rather than silently keeping it in the pack.
                    enabled: shelves.fits(line.copyWith(count: 1), catalogue),
                    onTap: () => onStore(line.copyWith(count: 1)),
                  ),
            ],
          ),
        ),
      ),
    );
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
        value:
            '${stash.massKg(catalogue).toStringAsFixed(1)} / '
            '${stash.capacityKg.toStringAsFixed(0)} kg',
        colours: colours,
      ),
      const SizedBox(height: 6),
      _Gauge(
        share: stash.volumeShare(catalogue),
        value:
            '${stash.volumeL(catalogue).toStringAsFixed(1)} / '
            '${stash.capacityL.toStringAsFixed(0)} l',
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

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.name,
    required this.catalogue,
    required this.colours,
    required this.action,
    required this.onTap,
    required this.nameOf,
    this.enabled = true,
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

  @override
  Widget build(BuildContext context) {
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
                    line.attachments.map(nameOf).join(' · '),
                    style: TextStyle(fontSize: 11, color: colours.data),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${mass.toStringAsFixed(mass < 1 ? 2 : 1)} kg  ·  '
                  '${volume.toStringAsFixed(volume < 1 ? 2 : 1)} l',
                  style: TextStyle(
                    fontSize: 11,
                    color: colours.muted,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: enabled ? onTap : null, child: Text(action)),
        ],
      ),
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
