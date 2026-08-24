/// The journal, on its own (§3.6.1, §12).
///
/// ⚠️ **It was at the bottom of the profile, under everything else.** Six
/// sections of body, sleep debt, skills and shooting stand between the top of
/// that screen and the one part of it a player opens after a walk — so the log
/// was a thing to be found rather than a thing to be read. It has its own
/// screen and its own scroll now, and the profile carries a button to it next
/// to the character's name.
///
/// A week of it, not the run. Four hundred entries is what is kept (§3.6.1);
/// a month of them on one list is something nobody reaches the bottom of.
library;

import 'package:flutter/material.dart';

import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../journal/journal.dart';
import '../l10n/app_localizations.dart';
import 'journal_view.dart';

Future<void> showJournal(
  BuildContext context, {
  required List<JournalEntry> entries,
  required DateTime startedAt,
  required ItemCatalogue? catalogue,
  required ItemNames names,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => JournalScreen(
      entries: entries,
      startedAt: startedAt,
      catalogue: catalogue,
      names: names,
    ),
  ),
);

class JournalScreen extends StatelessWidget {
  const JournalScreen({
    required this.entries,
    required this.startedAt,
    required this.catalogue,
    required this.names,
    super.key,
  });

  final List<JournalEntry> entries;
  final DateTime startedAt;
  final ItemCatalogue? catalogue;
  final ItemNames names;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(L10n.of(context).journalTitle)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: journalRows(
        context,
        entries: entries,
        startedAt: startedAt,
        catalogue: catalogue,
        names: names,
      ),
    ),
  );
}
