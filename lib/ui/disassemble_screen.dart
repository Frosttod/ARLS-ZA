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

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../craft/craft_job.dart';
import '../craft/salvage_batch.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';
import 'fonts.dart';
import 'hud.dart' show HudColors;
import 'salvage_running_view.dart';
import 'units.dart';

class DisassembleScreen extends StatefulWidget {
  const DisassembleScreen({
    required this.offers,
    required this.catalogue,
    required this.nameOf,
    required this.onStart,
    required this.yieldsOf,
    this.job,
    this.onStop,
    super.key,
  });

  /// §18.6: the sitting already on the bench, if there is one.
  ///
  /// ⚠️ **This screen used to refuse to open while one was running**, so the
  /// only place a player could see their own sitting was the *making* screen —
  /// a bar at the top of a list of recipes, which is the wrong list. Now the
  /// screen shows whichever of its two jobs applies: pick a sitting, or watch
  /// the one that is going.
  final ValueListenable<CraftJob?>? job;

  /// §12: every running action is stoppable, from where it is drawn.
  final VoidCallback? onStop;

  /// §18.6: what one piece of a running sitting gives back.
  ///
  /// ⚠️ Handed in rather than worked out here. §18.6's share depends on the
  /// workshop and on skills, and a screen has no business knowing about
  /// either — the caller already holds the bench.
  final Map<String, int> Function(SalvageStep step) yieldsOf;

  /// Everything worth opening, pack and shelves together, already worked out
  /// by the caller against the same bench the single-item path uses.
  final List<SalvageOffer> offers;

  final ItemCatalogue catalogue;
  final String Function(String itemId) nameOf;

  /// The sitting, in the order it was agreed to, with how many of each.
  final void Function(List<SalvagePick> picked) onStart;

  @override
  State<DisassembleScreen> createState() => _DisassembleScreenState();
}

class _DisassembleScreenState extends State<DisassembleScreen> {
  /// ⚠️ Held by uid, not by item id and not by index — and it holds a
  /// **number**, not a tick.
  ///
  /// §11.1's lesson: two rifles are two rifles, and picking the worn one is a
  /// different decision from picking the good one. An index would be worse
  /// still — the lists behind this screen are rebuilt by anything that touches
  /// the pack.
  ///
  /// ⚠️ The number is the second half of the same lesson, reported from a
  /// walk: three of a thing are one row with a count on it, and a tick can
  /// only ever ask for one of them. So a row that stands for several pieces
  /// keeps how many of them were asked for.
  final Map<String, int> _picked = {};

  List<SalvagePick> get _chosen => [
    for (final offer in widget.offers)
      if (_countOf(offer) case final count when count > 0)
        SalvagePick(offer, count),
  ];

  int _countOf(SalvageOffer offer) {
    final uid = offer.line.uid;
    if (uid == null) return 0;

    // Clamped on the way out rather than on the way in: the pack behind this
    // screen can shrink while it is open, and a number remembered from before
    // that must never ask for more pieces than are there.
    final asked = _picked[uid] ?? 0;
    return asked > offer.available ? offer.available : asked;
  }

  bool _isPicked(SalvageOffer offer) => _countOf(offer) > 0;

  void _toggle(SalvageOffer offer) {
    final uid = offer.line.uid;

    // ⚠️ Shown and refused, never hidden. A control that disappears cannot
    // explain itself — a rifle in the player's hands is not an absent option,
    // it is an option with one step in front of it.
    if (uid == null || offer.isBlocked) return;

    setState(() {
      if (_countOf(offer) > 0) {
        _picked.remove(uid);
      } else {
        _picked[uid] = 1;
      }
    });
  }

  /// §18.6: how many of a stack go into the sitting.
  ///
  /// Nought is the same as not picking it, so the tick and the stepper are one
  /// control with two ends rather than two controls that can disagree.
  void _setCount(SalvageOffer offer, int count) {
    final uid = offer.line.uid;
    if (uid == null || offer.isBlocked) return;

    setState(() {
      if (count <= 0) {
        _picked.remove(uid);
      } else {
        _picked[uid] = count > offer.available ? offer.available : count;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    if (job == null) return _picker(context);

    return ValueListenableBuilder<CraftJob?>(
      valueListenable: job,
      builder: (context, running, _) => running == null || !running.isSalvage
          ? _picker(context)
          : _running(context, running),
    );
  }

  /// §18.6, §12: the sitting that is going, with a bar for every piece of it.
  Widget _running(BuildContext context, CraftJob job) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salvageTitle)),
      body: SalvageRunningView(
        job: job,
        nameOf: widget.nameOf,
        yieldsOf: widget.yieldsOf,
        onStop: widget.onStop,
      ),
      bottomNavigationBar: widget.onStop == null
          ? null
          : Material(
              color: colours.panel,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: widget.onStop,
                        icon: const Icon(Icons.stop),
                        label: Text(l10n.craftStop),
                      ),
                      const SizedBox(height: 4),
                      // §12: said where the button is. Stopping here is not
                      // what "cancel" means anywhere else in this game.
                      Text(
                        l10n.craftStopKeepsWork,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: colours.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _picker(BuildContext context) {
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
                      count: _countOf(offer),
                      picked: _isPicked(offer),
                      definition: widget.catalogue[offer.line.itemId],
                      name: widget.nameOf(offer.line.itemId),
                      nameOf: widget.nameOf,
                      onTap: () => _toggle(offer),
                      onCount: (value) => _setCount(offer, value),
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
                      count: _countOf(offer),
                      picked: _isPicked(offer),
                      definition: widget.catalogue[offer.line.itemId],
                      name: widget.nameOf(offer.line.itemId),
                      nameOf: widget.nameOf,
                      onTap: () => _toggle(offer),
                      onCount: (value) => _setCount(offer, value),
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

  Future<void> _confirm(List<SalvagePick> chosen) async {
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
    required this.count,
    required this.picked,
    required this.definition,
    required this.name,
    required this.nameOf,
    required this.onTap,
    required this.onCount,
    required this.colours,
    required this.l10n,
  });

  final SalvageOffer offer;

  /// §18.6: how many of this line are going into the sitting. Nought when the
  /// row is not picked at all.
  final int count;

  final bool picked;
  final ItemDefinition? definition;
  final String name;
  final String Function(String itemId) nameOf;
  final VoidCallback onTap;
  final ValueChanged<int> onCount;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final line = offer.line;
    final condition = line.condition;

    final blocked = offer.isBlocked;

    // §18.6: what this row actually costs and gives — one piece, or all the
    // pieces asked for. A row quoting the price of one while three of them go
    // into the sitting is the bug this was reported as.
    final pick = SalvagePick(offer, count < 1 ? 1 : count);

    return Card(
      // ⚠️ Dimmed rather than removed (§12). The player has to be able to see
      // that the rifle *is* worth taking apart and that one step stands in
      // front of it — a row that is simply not there teaches nothing.
      color: blocked ? colours.panel.withValues(alpha: 0.5) : colours.panel,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: blocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: picked,
                onChanged: blocked ? null : (_) => onTap(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // ⚠️ The count is on the name, because that is
                            // where a player reads "how many have I got".
                            offer.available > 1
                                ? '$name  ×${offer.available}'
                                : name,
                            style: TextStyle(
                              fontSize: 15,
                              color: blocked ? colours.muted : colours.text,
                            ),
                          ),
                        ),
                        Text(
                          remaining(pick.takes),
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
                        effects([
                          if (condition != null) '${amount(condition)}%',
                          if (line.isPartlyDismantled) l10n.craftPartlyApart,
                        ]),
                        style: TextStyle(
                          fontSize: 11,
                          color: colours.muted,
                          fontFamily: kDataFont,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),
                    SalvageYields(
                      yields: pick.yields,
                      nameOf: nameOf,
                      colours: colours,
                    ),

                    // §18.6, §12: how many of the stack, where the stack is.
                    //
                    // ⚠️ Only where there is a choice to make — a stepper
                    // beside a single vest is a control with one setting, and
                    // §12's rule about controls that cannot do anything is the
                    // same rule that hid the dead buttons elsewhere.
                    if (!blocked && offer.available > 1) ...[
                      const SizedBox(height: 6),
                      _HowMany(
                        value: count,
                        max: offer.available,
                        onChanged: onCount,
                        colours: colours,
                        l10n: l10n,
                      ),
                    ],

                    // §12: the reason goes under the thing it is about, not in
                    // a message four seconds after a tap that did nothing.
                    if (offer.blocked case final reason?) ...[
                      const SizedBox(height: 4),
                      Text(switch (reason) {
                        SalvageBlock.worn => l10n.salvageWornFirst,
                      }, style: TextStyle(fontSize: 11, color: colours.alert)),
                    ],
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

/// §18.6: how many of a stack go into the sitting.
///
/// ⚠️ **A row that stands for three pieces needs a number, not a tick.**
/// Reported from a walk: three of a thing showed as one row reading "×3", the
/// row quoted the time for one, and there was no way to ask for the other two.
///
/// Nought is not a setting here — dropping to nought unticks the row, so the
/// checkbox and this control are two ends of one decision rather than two
/// controls that can disagree about whether the thing is in the sitting.
class _HowMany extends StatelessWidget {
  const _HowMany({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.colours,
    required this.l10n,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // Unticked rows read as one, because one is what the next tap asks for.
    final shown = value < 1 ? 1 : value;

    return Row(
      children: [
        _Step(
          icon: Icons.remove,
          onPressed: value <= 0 ? null : () => onChanged(value - 1),
          colours: colours,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l10n.salvageHowMany(shown, max),
            style: TextStyle(
              fontSize: 12,
              color: value > 0 ? colours.data : colours.muted,
              fontFamily: kDataFont,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Step(
          icon: Icons.add,
          onPressed: shown >= max ? null : () => onChanged(shown + 1),
          colours: colours,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.onPressed,
    required this.colours,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton(
      padding: EdgeInsets.zero,
      iconSize: 18,
      onPressed: onPressed,
      icon: Icon(icon),
      color: colours.text,
      disabledColor: colours.muted.withValues(alpha: 0.4),
    ),
  );
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

  final List<SalvagePick> chosen;
  final String Function(String itemId) nameOf;
  final VoidCallback? onConfirm;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Pieces, not rows. One row asking for three of a stack is three
    // pieces, three lots of minutes and three lots of materials — quoting it
    // as one is exactly what was reported from a walk.
    final work = totalTime(chosen);
    final pieces = chosen.fold(0, (sum, pick) => sum + pick.count);

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
                      l10n.salvageChosen(pieces),
                      style: TextStyle(fontSize: 13, color: colours.text),
                    ),
                  ),
                  Text(
                    worked(work),
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
                SalvageYields(
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

  final List<SalvagePick> chosen;
  final String Function(String itemId) nameOf;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Worked out first, not inside the list. A running total accumulated
    // during build is a total that doubles the second time Flutter builds the
    // same frame, and it will.
    //
    // ⚠️ One entry per **piece**, not per row. Three of a stack come apart one
    // after another and the summary is where somebody with twenty minutes
    // reads off how far they will get — a single line saying "×3" with one
    // clock beside it hides two of the three answers.
    final lines = <({String name, Duration byThen})>[];
    var running = Duration.zero;
    for (final pick in chosen) {
      for (var i = 0; i < pick.count; i++) {
        running += pick.offer.takes;
        lines.add((name: nameOf(pick.offer.line.itemId), byThen: running));
      }
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
            for (final (index, line) in lines.indexed)
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
                        line.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      remaining(line.byThen),
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
            SalvageYields(
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

/// §18.6: the price of one piece, read before it is paid.
///
/// ⚠️ **Which of them, when the row stands for several.** Reported from a
/// walk: a pack row reading "×3" opened a dialog quoting the minutes for one,
/// with nothing on it to say that the other two were staying put. The glyph
/// takes one piece — [DisassembleScreen] is where a whole stack is asked for
/// — and the dialog says so now.
Future<bool> askDismantle(
  BuildContext context, {
  required String name,
  required String gives,
  required Duration work,
  required int inStack,
}) async {
  final l10n = L10n.of(context);
  final warning = l10n.craftDismantleWarning(gives, work.inMinutes);

  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.craftTakingApart(name)),
      content: Text(
        inStack > 1 ? '$warning\n\n${l10n.salvageOnePiece(inStack)}' : warning,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.shelterCancelKeep),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.craftMake),
        ),
      ],
    ),
  );

  return answer ?? false;
}
