import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/journal/chronicle.dart';
import 'package:arls_za/journal/journal.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/l10n/app_localizations_pl.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/player_stats.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:arls_za/skills/skill.dart';
import 'package:arls_za/ui/journal_screen.dart';
import 'package:arls_za/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// DZIENNIK POD RĘKĄ (§3.6.1, §12).
///
/// ⚠️ **It was at the bottom of the profile, under everything else.** Six
/// sections of body, sleep debt, skills and shooting stood between the top of
/// that screen and the one part of it a player opens after a walk. A log that
/// has to be hunted for is a log nobody reads.
void main() {
  final t0 = DateTime.utc(2026, 8, 17, 20);
  final now = t0.add(const Duration(days: 7, hours: 1));

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('pl'),
    localizationsDelegates: const [
      L10n.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: L10n.supportedLocales,
    home: child,
  );

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 40, heightCm: 180, weightKg: 80),
  );

  final state = SimState.fresh(
    at: now,
    constants: body.toSimConstants(),
    massKg: body.spec.weightKg,
  );

  Widget profile({
    List<JournalEntry> journal = const [],
    List<PastRun> chronicle = const [],
  }) => wrap(
    ProfileScreen(
      name: 'Marek',
      body: body,
      state: state,
      status: statusOf(state: state, constants: body.toSimConstants()),
      skills: const SkillSet({}),
      stats: PlayerStats.empty,
      aliveFor: now.difference(t0),
      weaponMoa: null,
      journal: journal,
      chronicle: chronicle,
      startedAt: t0,
      catalogue: null,
      names: ItemNames.empty,
    ),
  );

  testWidgets('the button sits next to the name', (tester) async {
    await tester.pumpWidget(profile());

    expect(find.text('Marek'), findsOneWidget);
    expect(find.byIcon(Icons.history_edu_outlined), findsOneWidget);
  });

  testWidgets('and one tap is the whole journey to the log', (tester) async {
    await tester.pumpWidget(
      profile(
        journal: [JournalEntry(at: now, kind: JournalKind.cameHome)],
      ),
    );

    await tester.tap(find.byIcon(Icons.history_edu_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(JournalScreen), findsOneWidget);
    expect(find.text(L10nPl().journalCameHome), findsOneWidget);
  });

  testWidgets('§3.6.1: the streak says the same day the journal heads with', (
    tester,
  ) async {
    // ⚠️ Reported from the field: "moja postać żyje 7 dni i 1 godzinę, dziennik
    // pokazuje dzień 8". Both were right — DZIEŃ 1 is the day the run started,
    // so seven full days puts a character in DZIEŃ 8 — but a screen saying one
    // number while another says a different one reads as a bug either way.
    await tester.pumpWidget(
      profile(
        journal: [JournalEntry(at: now, kind: JournalKind.woke)],
      ),
    );

    expect(find.textContaining(L10nPl().journalDay(8)), findsOneWidget);
  });
}
