/// The page shown after a long absence (§16.3).
///
/// One dialog, once, and only when the hours actually cost something — see
/// [AwaySummary.worthShowing]. What it must never become is a greeting: a box
/// that appears every time the app is opened is a box people dismiss without
/// reading, and then the one that mattered goes with it.
library;

import 'package:flutter/material.dart';

import '../game/away_summary.dart';
import '../l10n/app_localizations.dart';
import 'units.dart';

Future<void> showAwaySummary(BuildContext context, AwaySummary summary) {
  final l10n = L10n.of(context);

  final lines = <String>[
    l10n.awayFor(span(summary.away)),
    if (summary.waterLostMl >= 1)
      l10n.awayWater(summary.waterLostMl.round().toString()),
    if (summary.kcalLost >= 1)
      l10n.awayKcal(summary.kcalLost.round().toString()),
    // §2.5: the debt moves both ways. A night in a shelter pays it down while
    // nobody is watching, and saying so is the difference between a summary
    // and a list of complaints.
    if (summary.sleepOwed.inMinutes > 0)
      l10n.awaySleep(span(summary.sleepOwed))
    else if (summary.sleepOwed.inMinutes < 0)
      l10n.awaySlept(span(-summary.sleepOwed)),
    if (summary.zonesGrown > 0)
      l10n.awayZones(summary.zonesGrown, summary.highestZone)
    else
      l10n.awayNothingGrew,
  ];

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.awayTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    ),
  );
}
