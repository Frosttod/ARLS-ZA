/// The evening, read back (§3.6.1, §12).
///
/// ⚠️ **The words are put on here, not on disk.** An entry is a kind and a
/// subject — an item id, an enemy kind, a shop's name off the map — and this
/// is the only place that knows how to say it out loud. That is what lets a
/// player change the language without their own diary turning into a museum of
/// the language they used to play in (§1.1).
///
/// Newest first, in both directions: a log on a phone is read the way a call
/// list is read.
library;

import 'package:flutter/material.dart';

import '../combat/enemy.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../journal/journal.dart';
import '../l10n/app_localizations.dart';
import '../shelter/shelter.dart';
import '../skills/skill.dart';
import 'combat_panel.dart' show enemyKindName;
import 'fonts.dart';
import 'hud.dart' show HudColors;
import 'map_markers.dart' show placeName;
import 'names.dart';
import 'shelter_screen.dart' show moduleName;

/// Turns one entry into the line a player reads.
///
/// [nameOf] resolves an item id; everything else is decided here.
String journalLine(
  L10n l10n,
  JournalEntry entry, {
  required String Function(String itemId) nameOf,
}) {
  String enemy() {
    final kind = EnemyKind.values
        .where((each) => each.name == entry.subject)
        .firstOrNull;
    return kind == null ? (entry.subject ?? '') : enemyKindName(l10n, kind);
  }

  String module() {
    final found = ShelterModule.values
        .where((each) => each.name == entry.subject)
        .firstOrNull;
    return found == null ? (entry.subject ?? '') : moduleName(l10n, found);
  }

  String skill() {
    // "scouting:3" — the level is part of the record, because a skill that
    // only said its name would say the same thing at every level.
    final parts = (entry.subject ?? '').split(':');
    final found = Skill.values
        .where((each) => each.wire == parts.first)
        .firstOrNull;
    if (found == null) return entry.subject ?? '';

    final name = skillName(l10n, found);
    return parts.length < 2 ? name : '$name ${parts[1]}';
  }

  /// §10.2: what the place is called — its own name off the map when it has
  /// one, and what kind of place it is when it has not. The table id is never
  /// shown: "Przeszukanie: proc_waste" is a defect report, not a diary.
  String place() {
    final found = placeSubject(entry.subject);
    return found.name ?? placeName(l10n, found.tableId);
  }

  /// §10.2: a haul is a list with counts on it, never fourteen separate lines.
  String haul() {
    final counted = <String, int>{};
    for (final id in entry.subjects) {
      counted[id] = (counted[id] ?? 0) + 1;
    }
    if (counted.isEmpty) return l10n.journalFoundNothing;

    return [
      for (final row in counted.entries)
        row.value == 1
            ? nameOf(row.key)
            : l10n.journalCount(nameOf(row.key), row.value),
    ].join(', ');
  }

  return switch (entry.kind) {
    JournalKind.searched => l10n.journalSearched(place()),
    JournalKind.found => counted(l10n, haul()),
    JournalKind.opened => l10n.journalOpened(entry.subject ?? ''),
    JournalKind.fought => l10n.journalFought(enemy()),
    JournalKind.killed => l10n.journalKilled(enemy()),
    JournalKind.hurt => l10n.journalHurt(enemy()),
    JournalKind.ate => l10n.journalAte(nameOf(entry.subject ?? '')),
    JournalKind.drank => l10n.journalDrank(nameOf(entry.subject ?? '')),
    JournalKind.treated => l10n.journalTreated(nameOf(entry.subject ?? '')),
    JournalKind.slept => l10n.journalSlept,
    JournalKind.woke => l10n.journalWoke,
    JournalKind.read => l10n.journalRead(entry.subject ?? ''),
    JournalKind.startedBuild => l10n.journalStartedBuild(module()),
    JournalKind.built => l10n.journalBuilt(module()),
    JournalKind.startedCraft => l10n.journalStartedCraft(haul()),
    JournalKind.startedSalvage => l10n.journalStartedSalvage(haul()),
    JournalKind.crafted => l10n.journalCrafted(haul()),
    JournalKind.salvaged => l10n.journalSalvaged(haul()),
    JournalKind.cameHome => l10n.journalCameHome,
    JournalKind.wentOut => l10n.journalWentOut,
    JournalKind.learned => l10n.journalLearned(skill()),
    JournalKind.blackout => l10n.journalBlackout,
  };
}

/// The haul, said as a find. Split out only so the switch above stays a table.
String counted(L10n l10n, String haul) => l10n.journalFound(haul);

/// §3.6.1: the log itself, as rows a profile screen can drop into a list.
List<Widget> journalRows(
  BuildContext context, {
  required List<JournalEntry> entries,
  required DateTime startedAt,
  required ItemCatalogue? catalogue,
  required ItemNames names,
}) {
  final l10n = L10n.of(context);
  final colours = HudColors.of(context);
  final language = Localizations.localeOf(context).languageCode;

  String nameOf(String itemId) {
    final definition = catalogue?[itemId];
    if (definition == null) return itemId;

    return definition.name.resolve(
      language: language,
      lookup: names.forLanguage(language),
    );
  }

  if (entries.isEmpty) {
    return [
      Text(
        l10n.journalEmpty,
        style: TextStyle(fontSize: 12, color: colours.muted),
      ),
    ];
  }

  return [
    for (final day in journalDays(entries, startedAt: startedAt)) ...[
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          l10n.journalDay(day.day).toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: colours.muted,
          ),
        ),
      ),
      for (final entry in day.entries)
        _Entry(
          at: entry.at.toLocal(),
          text: journalLine(l10n, entry, nameOf: nameOf),
          colours: colours,
        ),
    ],
  ];
}

class _Entry extends StatelessWidget {
  const _Entry({required this.at, required this.text, required this.colours});

  final DateTime at;
  final String text;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 12,
            color: colours.muted,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: colours.text),
          ),
        ),
      ],
    ),
  );
}
