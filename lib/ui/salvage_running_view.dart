/// The sitting that is going, one row per piece (§18.6, §12).
///
/// ⚠️ **One bar each, not one bar across the lot.**
///
/// A single bar answers the wrong question. What somebody standing at a bench
/// with twenty minutes to spare wants to know is *which of these will be
/// finished* — and a bar at forty per cent of an hour does not say that. So
/// each piece gets its own: the finished ones are full and struck through, the
/// one under the multitool is where it actually is, and the ones waiting sit
/// at nought with the time **their own turn** ends.
///
/// The waiting rows are deliberately not blank. Nought with a clock on it says
/// "yours is in eleven minutes"; a blank row says nothing at all.
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
    required this.onStop,
    super.key,
  });

  final CraftJob job;
  final String Function(String itemId) nameOf;
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
    required this.colours,
    required this.l10n,
  });

  final int index;
  final SalvageProgress row;
  final String name;
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

            // ⚠️ A waiting row says when *its* turn comes, not how far the
            // sitting as a whole has got. "Yours is in eleven minutes" is the
            // answer to the question somebody with twenty minutes is asking.
            if (row.waiting) ...[
              const SizedBox(height: 4),
              Text(
                l10n.salvageWaitingUntil(remaining(row.endsAfter)),
                style: TextStyle(fontSize: 11, color: colours.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
