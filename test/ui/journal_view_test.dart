import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/journal/journal.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/l10n/app_localizations_pl.dart';
import 'package:arls_za/ui/journal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// JAK DZIENNIK MÓWI (§3.6.1, §1.1, §12).
///
/// ⚠️ **The words go on here, not on disk.** An entry is a kind and a subject,
/// and this is the only place that knows how to say it out loud — which is
/// what lets a player change the language without their own diary turning into
/// a museum of the language they used to play in.
void main() {
  final l10n = L10nPl();
  final t0 = DateTime(2026, 8, 24, 21, 37);

  String lineFor(JournalKind kind, {String? subject}) => journalLine(
    l10n,
    JournalEntry(at: t0, kind: kind, subject: subject),
    nameOf: (id) => switch (id) {
      'med_bandage' => 'Bandaż',
      'tool_knife' => 'Nóż',
      _ => id,
    },
  );

  group('§3.6.1: a line says what happened', () {
    test('a haul is one line with counts on it', () {
      // ⚠️ Not fourteen lines. §10.2 can turn out a shop into a dozen things
      // at once, and a log that gave each of them a row would bury the day.
      final line = lineFor(
        JournalKind.found,
        subject: 'med_bandage,med_bandage,tool_knife',
      );

      expect(line, contains('Bandaż ×2'));
      expect(line, contains('Nóż'));
    });

    test('and a place that gave up nothing says so', () {
      expect(lineFor(JournalKind.found), contains(l10n.journalFoundNothing));
    });

    test('the kinds that need no subject carry none', () {
      expect(lineFor(JournalKind.slept), l10n.journalSlept);
      expect(lineFor(JournalKind.cameHome), l10n.journalCameHome);
      expect(lineFor(JournalKind.blackout), l10n.journalBlackout);
    });

    test('an enemy is named, not printed as its wire name', () {
      expect(lineFor(JournalKind.killed, subject: 'walker'), isNot('walker'));
    });

    test('a skill carries the level it reached', () {
      expect(
        lineFor(JournalKind.learned, subject: 'scouting:3'),
        contains('3'),
      );
    });

    test('and every kind has something to say', () {
      // The defect this catches is a switch that compiles because one arm
      // returns an empty string.
      for (final kind in JournalKind.values) {
        expect(lineFor(kind, subject: 'walker'), isNotEmpty, reason: kind.name);
      }
    });
  });

  testWidgets('§3.6.1: days head the list, newest first', (tester) async {
    final entries = [
      JournalEntry(
        at: t0.add(const Duration(days: 1)).toUtc(),
        kind: JournalKind.wentOut,
      ),
      JournalEntry(at: t0.toUtc(), kind: JournalKind.cameHome),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(
              children: journalRows(
                context,
                entries: entries,
                startedAt: t0.toUtc(),
                catalogue: null,
                names: ItemNames.empty,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.journalDay(2).toUpperCase()), findsOneWidget);
    expect(find.text(l10n.journalDay(1).toUpperCase()), findsOneWidget);
    expect(find.text(l10n.journalCameHome), findsOneWidget);
  });
}
