/// Taking several things apart in one sitting (§18.6, §2.1a, §18.2).
///
/// ⚠️ **The price is read before it is paid, and it is read once.**
///
/// §18.6 destroys what it opens. The single-item path asks for one thing with
/// a dialog, which is honest for one thing and unbearable for five: five
/// dialogs in a row is not consent, it is a rhythm, and a player taps through
/// a rhythm without reading it. So a sitting is picked out first — from the
/// pack and the shelves together, because §18.2 makes those one pile at a
/// bench — and then agreed to once, against a summary that says what will be
/// destroyed, what will come back, and how long it takes.
///
/// The order on the summary is the order it happens in (§18.6). Somebody who
/// only has twenty minutes can read off which of their five will be done.
library;

import 'package:flutter/material.dart';

import '../craft/salvage_batch.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'hud.dart' show HudColors;
import 'units.dart';

class DisassembleScreen extends StatefulWidget {
  const DisassembleScreen({
    required this.offers,
    required this.catalogue,
    required this.nameOf,
    required this.onStart,
    super.key,
  });

  /// Everything worth opening, pack and shelves together, already worked out
  /// by the caller against the same bench the single-item path uses.
  final List<SalvageOffer> offers;

  final ItemCatalogue catalogue;
  final String Function(String itemId) nameOf;

  /// The sitting, in the order it was agreed to.
  final void Function(List<SalvageOffer> picked) onStart;

  @override
  State<DisassembleScreen> createState() => _DisassembleScreenState();
}

class _DisassembleScreenState extends State<DisassembleScreen> {
  /// ⚠️ Held by uid, not by item id and not by index.
  ///
  /// §11.1's lesson: two rifles are two rifles, and picking the worn one is a
  /// different decision from picking the good one. An index would be worse
  /// still — the lists behind this screen are rebuilt by anything that touches
  /// the pack.
  final Set<String> _picked = {};

  List<SalvageOffer> get _chosen => [
    for (final offer in widget.offers)
      if (_isPicked(offer)) offer,
  ];

  bool _isPicked(SalvageOffer offer) {
    final uid = offer.line.uid;
    return uid != null && _picked.contains(uid);
  }

  void _toggle(SalvageOffer offer) {
    final uid = offer.line.uid;
    if (uid == null) return;

    setState(() {
      if (!_picked.remove(uid)) _picked.add(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    final fromPack = [
      for (final offer in widget.offers)
        if (!offer.fromShelf) offer,
    ];
    final fromShelf = [
      for (final offer in widget.offers)
        if (offer.fromShelf) offer,
    ];

    final chosen = _chosen;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salvageTitle)),
      body: widget.offers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.salvageNothingWorth,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colours.muted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                Text(
                  l10n.salvagePick,
                  style: TextStyle(fontSize: 12, color: colours.muted),
                ),
                const SizedBox(height: 8),

                // §18.2: two piles, because reaching for something on a shelf
                // and taking it out of the pack are different motions — and
                // because a player deciding what to keep is deciding about one
                // pile at a time.
                if (fromPack.isNotEmpty) ...[
                  _Heading(label: l10n.stashInThePack, colours: colours),
                  for (final offer in fromPack)
                    _OfferRow(
                      offer: offer,
                      picked: _isPicked(offer),
                      definition: widget.catalogue[offer.line.itemId],
                      name: widget.nameOf(offer.line.itemId),
                      nameOf: widget.nameOf,
                      onTap: () => _toggle(offer),
                      colours: colours,
                      l10n: l10n,
                    ),
                ],

                if (fromShelf.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Heading(label: l10n.stashOnTheShelves, colours: colours),
                  for (final offer in fromShelf)
                    _OfferRow(
                      offer: offer,
                      picked: _isPicked(offer),
                      definition: widget.catalogue[offer.line.itemId],
                      name: widget.nameOf(offer.line.itemId),
                      nameOf: widget.nameOf,
                      onTap: () => _toggle(offer),
                      colours: colours,
                      l10n: l10n,
                    ),
                ],
              ],
            ),

      // The running total, always on screen. The decision being made is "is
      // this worth a quarter of an hour", and that is not a question anybody
      // can answer from a column of ticks.
      bottomNavigationBar: widget.offers.isEmpty
          ? null
          : _Total(
              chosen: chosen,
              nameOf: widget.nameOf,
              onConfirm: chosen.isEmpty ? null : () => _confirm(chosen),
              colours: colours,
              l10n: l10n,
            ),
    );
  }

  Future<void> _confirm(List<SalvageOffer> chosen) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => _SummaryDialog(
        chosen: chosen,
        nameOf: widget.nameOf,
        colours: HudColors.of(context),
        l10n: L10n.of(context),
      ),
    );

    if (go != true || !mounted) return;
    widget.onStart(chosen);
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
      style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: colours.muted),
    ),
  );
}

/// One thing that could go into the sitting, with what it gives and costs.
class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.offer,
    required this.picked,
    required this.definition,
    required this.name,
    required this.nameOf,
    required this.onTap,
    required this.colours,
    required this.l10n,
  });

  final SalvageOffer offer;
  final bool picked;
  final ItemDefinition? definition;
  final String name;
  final String Function(String itemId) nameOf;
  final VoidCallback onTap;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final line = offer.line;
    final condition = line.condition;

    return Card(
      color: colours.panel,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: picked, onChanged: (_) => onTap()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(fontSize: 15, color: colours.text),
                          ),
                        ),
                        Text(
                          remaining(offer.takes),
                          style: TextStyle(
                            fontSize: 13,
                            color: colours.muted,
                            fontFamily: kDataFont,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),

                    // §18.6: the two things that change what comes out — how
                    // worn it is, and how much of it is already undone.
                    if (condition != null || line.isPartlyDismantled) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (condition != null) '${amount(condition)}%',
                          if (line.isPartlyDismantled) l10n.craftPartlyApart,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 11,
                          color: colours.muted,
                          fontFamily: kDataFont,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),
                    _Gives(
                      yields: offer.yields,
                      nameOf: nameOf,
                      colours: colours,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What comes back, said the same way everywhere it is said.
class _Gives extends StatelessWidget {
  const _Gives({
    required this.yields,
    required this.nameOf,
    required this.colours,
  });

  final Map<String, int> yields;
  final String Function(String itemId) nameOf;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Sorted by name, so the same sitting always reads the same way. A map
    // that comes out in insertion order reorders itself the moment somebody
    // ticks a different box first.
    final entries = yields.entries.toList()
      ..sort((a, b) => nameOf(a.key).compareTo(nameOf(b.key)));

    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        for (final entry in entries)
          Text(
            '${nameOf(entry.key)} ×${entry.value}',
            style: TextStyle(
              fontSize: 12,
              color: colours.data,
              fontFamily: kDataFont,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

/// The running total, and the way out of the screen.
class _Total extends StatelessWidget {
  const _Total({
    required this.chosen,
    required this.nameOf,
    required this.onConfirm,
    required this.colours,
    required this.l10n,
  });

  final List<SalvageOffer> chosen;
  final String Function(String itemId) nameOf;
  final VoidCallback? onConfirm;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final work = chosen.fold(Duration.zero, (sum, offer) => sum + offer.takes);

    return Material(
      color: colours.panel,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.salvageChosen(chosen.length),
                      style: TextStyle(fontSize: 13, color: colours.text),
                    ),
                  ),
                  Text(
                    remaining(work),
                    style: TextStyle(
                      fontSize: 13,
                      color: colours.data,
                      fontFamily: kDataFont,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (chosen.isNotEmpty) ...[
                const SizedBox(height: 4),
                _Gives(
                  yields: totalYield(chosen),
                  nameOf: nameOf,
                  colours: colours,
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.handyman),
                  label: Text(l10n.craftTakeApart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §18.6: the price, read once, before anything is destroyed.
class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({
    required this.chosen,
    required this.nameOf,
    required this.colours,
    required this.l10n,
  });

  final List<SalvageOffer> chosen;
  final String Function(String itemId) nameOf;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Worked out first, not inside the list. A running total accumulated
    // during build is a total that doubles the second time Flutter builds the
    // same frame, and it will.
    final byThen = <Duration>[];
    var running = Duration.zero;
    for (final offer in chosen) {
      running += offer.takes;
      byThen.add(running);
    }

    return AlertDialog(
      title: Text(l10n.salvageSummaryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              l10n.salvageGone,
              style: TextStyle(fontSize: 12, color: colours.alert),
            ),
            const SizedBox(height: 6),

            // ⚠️ Numbered, and the number is the order it happens in. The
            // clock beside each is when *that one* is done, so somebody with
            // twenty minutes can read off where they will get to.
            for (final (index, offer) in chosen.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colours.muted,
                          fontFamily: kDataFont,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        nameOf(offer.line.itemId),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      remaining(byThen[index]),
                      style: TextStyle(
                        fontSize: 12,
                        color: colours.muted,
                        fontFamily: kDataFont,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 20),
            Text(
              l10n.salvageYouGet,
              style: TextStyle(fontSize: 12, color: colours.muted),
            ),
            const SizedBox(height: 4),
            _Gives(
              yields: totalYield(chosen),
              nameOf: nameOf,
              colours: colours,
            ),

            const SizedBox(height: 10),
            Text(
              l10n.salvageTakes(remaining(running)),
              style: TextStyle(
                fontSize: 12,
                color: colours.text,
                fontFamily: kDataFont,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 6),
            Text(
              l10n.salvageInOrder,
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.shelterCancelKeep),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.craftTakeApart),
        ),
      ],
    );
  }
}
