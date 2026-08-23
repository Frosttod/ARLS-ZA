/// The sitting that is going, one row per piece (§18.6, §12).
///
/// ⚠️ **One bar each, not one bar across the lot.**
///
/// A single bar answers the wrong question. What somebody standing at a bench
/// with twenty minutes to spare wants to know is *which of these will be
/// finished* — and a bar at forty per cent of an hour does not say that. So
/// each piece gets its own: the finished ones are full and struck through, the
/// one under the multitool is where it actually is, and the ones waiting sit
/// at nought with the time **their own turn begins**.
///
/// ⚠️ Begins, counted from now — not "ends, counted from the start of the
/// sitting", which is what it said first and what came back from a walk as an
/// absurd number. The third of four read eighteen minutes while the thing in
/// front of it had two and three quarters left, because the figure was adding
/// up minutes that had already been spent.
///
/// The waiting rows are deliberately not blank. Nought with a clock on it says
/// "yours starts in five minutes"; a blank row says nothing at all.
///
/// ⚠️ This lives here rather than on the making screen, which is where it used
/// to be. A bar about taking things apart, at the top of a list of recipes, is
/// the right information on the wrong list — reported from a walk as exactly
/// that.
library;

import 'package:flutter/material.dart';

import '../craft/craft_job.dart';
import '../craft/salvage_batch.dart';
import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'hud.dart' show HudColors;
import 'ticking.dart';
import 'units.dart';

class SalvageRunningView extends StatefulWidget {
  const SalvageRunningView({
    required this.job,
    required this.nameOf,
    required this.yieldsOf,
    required this.onStop,
    super.key,
  });

  final CraftJob job;
  final String Function(String itemId) nameOf;

  /// §18.6: what a piece of the sitting gives back.
  ///
  /// ⚠️ Handed in rather than worked out here, for the same reason [nameOf]
  /// is: §18.6's share depends on the workshop and on skills, and this view
  /// has no business knowing about either. The caller already holds the bench.
  final Map<String, int> Function(SalvageStep step) yieldsOf;

  final VoidCallback? onStop;

  @override
  State<SalvageRunningView> createState() => _SalvageRunningViewState();
}

class _SalvageRunningViewState extends State<SalvageRunningView>
    with WidgetsBindingObserver, Ticking<SalvageRunningView> {
  /// §3.3: only while there is something left to redraw. A sitting that has
  /// run out stops costing a wake-up a second.
  @override
  bool get ticking => !widget.job.isDoneAt(DateTime.now().toUtc());

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    final now = DateTime.now().toUtc();
    final rows = _sitting().progressAt(widget.job.creditedAt(now));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(
          l10n.salvageInOrder,
          style: TextStyle(fontSize: 12, color: colours.muted),
        ),
        const SizedBox(height: 10),

        for (final (index, row) in rows.indexed)
          _SittingRow(
            index: index,
            row: row,
            name: widget.nameOf(row.step.itemId),
            yields: widget.yieldsOf(row.step),
            nameOf: widget.nameOf,
            colours: colours,
            l10n: l10n,
          ),
      ],
    );
  }

  /// A job written before sittings existed is a sitting of one.
  SalvageBatch _sitting() {
    if (widget.job.batch.isNotEmpty) return widget.job.batch;

    return SalvageBatch([
      SalvageStep(
        itemId: widget.job.salvageItemId ?? '',
        condition: widget.job.salvageCondition ?? 100,
        takes: widget.job.readyAt.difference(widget.job.startedAt),
      ),
    ]);
  }
}

/// One piece of the sitting: where it is, and when its own turn ends.
class _SittingRow extends StatelessWidget {
  const _SittingRow({
    required this.index,
    required this.row,
    required this.name,
    required this.yields,
    required this.nameOf,
    required this.colours,
    required this.l10n,
  });

  final int index;
  final SalvageProgress row;
  final String name;

  /// §18.6: what this piece gives — or, once it is apart, what it gave.
  final Map<String, int> yields;

  final String Function(String itemId) nameOf;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // Three states, and the difference matters: done is over, running is now,
    // waiting is a promise about later.
    final tint = row.running ? colours.data : colours.muted;

    return Card(
      color: colours.panel,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      color: row.done ? colours.muted : colours.text,
                      decoration: row.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  row.done ? l10n.craftDone : remaining(row.left),
                  style: TextStyle(
                    fontSize: 13,
                    color: tint,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: row.fraction,
              minHeight: 4,
              backgroundColor: colours.muted.withValues(alpha: 0.25),
              color: tint,
            ),

            // ⚠️ §18.6: what came out of it, and the same line on every row.
            //
            // Reported from a walk: a finished piece said "Gotowe." and
            // nothing else, so the one moment a player most wants the answer —
            // *what did I actually get* — was the one moment the screen went
            // quiet about it.
            //
            // The same line on the rows still waiting, deliberately. Two rules
            // would be worse than one: on a finished piece it reads as what it
            // gave, on the others as what it will give, and a player scanning
            // the queue is asking the same question of all of them.
            if (yields.isNotEmpty) ...[
              const SizedBox(height: 6),
              SalvageYields(yields: yields, nameOf: nameOf, colours: colours),
            ],

            // ⚠️ A waiting row says when *its own turn begins*, counted from
            // now — not how far the sitting as a whole has got. Measured from
            // the start it read as an absurd number and was reported as one:
            // the third of four said eighteen minutes while the thing in front
            // of it had two and three quarters left, because the figure
            // included every minute already spent.
            if (row.waiting) ...[
              const SizedBox(height: 4),
              Text(
                l10n.salvageStartsIn(remaining(row.startsIn)),
                style: TextStyle(fontSize: 11, color: colours.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What comes back, said the same way everywhere it is said.
class SalvageYields extends StatelessWidget {
  const SalvageYields({
    required this.yields,
    required this.nameOf,
    required this.colours,
    super.key,
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
