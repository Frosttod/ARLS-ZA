import 'dart:io';

import 'package:arls_za/journal/chronicle.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/chronicle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// KRONIKA (§13.1, §9.3).
///
/// ⚠️ **Wiersze były zapisywane od pierwszego dnia i nikt ich nigdy nie
/// przeczytał.** Baza wypełnia `chronicle_entries` przy każdej śmierci, a
/// `chronicleFor` nie miał w grze ani jednego wołającego — czternasty raz ta
/// sama klasa usterki w tym projekcie.
///
/// §13.1 mówi wprost, po co hardcore istnieje: passa, która padła, ma zostać
/// na czymś zapisana. Licznik dni, którego po śmierci nie da się zobaczyć, jest
/// licznikiem donikąd.
void main() {
  PastRun run({
    required int days,
    String cause = 'blood_loss',
    bool hardcore = true,
    int endedDay = 10,
  }) => PastRun(
    days: days,
    startedAt: DateTime.utc(2026, 8, 1),
    endedAt: DateTime.utc(2026, 8, endedDay),
    cause: cause,
    hardcore: hardcore,
  );

  Future<void> pump(WidgetTester tester, List<PastRun> runs) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: ChronicleScreen(runs: runs),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§13.1: passa, która padła, zostaje zapisana', () {
    testWidgets('każdy bieg mówi, ile trwał i co go skończyło', (tester) async {
      await pump(tester, [run(days: 12)]);

      expect(find.text('12 dni'), findsOneWidget);
      expect(find.textContaining('hardcore'), findsOneWidget);
    });

    testWidgets('rekord stoi na górze, osobno', (tester) async {
      // ⚠️ To jest ta jedna liczba, o którą chodzi w całej grze. Szukanie jej
      // wzrokiem po liście byłoby zadaniem.
      await pump(tester, [run(days: 4), run(days: 31), run(days: 9)]);

      expect(find.text('Najdłuższa passa: 31 dni'), findsOneWidget);
    });

    testWidgets('a rekord jest liczony z listy, nie zapisany obok niej', (
      tester,
    ) async {
      // Jedna liczba wyliczana z listy nie może się z tą listą rozjechać.
      await pump(tester, [run(days: 2)]);

      expect(find.text('Najdłuższa passa: 2 dni'), findsOneWidget);
    });

    testWidgets('pusta kronika mówi, że to dobrze', (tester) async {
      // §12: „brak danych" na ekranie, którego pustka jest dobrą wiadomością,
      // czyta się jak usterka.
      await pump(tester, const []);

      expect(find.textContaining('Jeszcze żadna passa'), findsOneWidget);
      expect(find.textContaining('Najdłuższa'), findsNothing);
    });

    testWidgets('softcore nie udaje hardcore', (tester) async {
      // ⚠️ Tryb jest zapisany przy śmierci, nie odczytany z profilu dzisiaj:
      // passa hardcore przemianowana po fakcie byłaby kłamstwem o jedynej
      // rzeczy, którą ten ekran mierzy.
      await pump(tester, [run(days: 3, hardcore: false)]);

      expect(find.textContaining('softcore'), findsOneWidget);
    });
  });

  test('§13.1: i ktoś te wiersze naprawdę czyta', () {
    // ⚠️ Test źródłowy. Ekran może być doskonały i nieosiągalny — dokładnie
    // tym były te wiersze przez czternaście wersji schematu.
    final main = File('lib/main.dart').readAsStringSync();
    final profile = File('lib/ui/profile_screen.dart').readAsStringSync();
    final store = File('lib/journal/chronicle_store.dart').readAsStringSync();
    final diary = File(
      'lib/game/controllers/journal_controller.dart',
    ).readAsStringSync();

    expect(store.contains('db.chronicleFor('), isTrue);
    expect(diary.contains('ChronicleStore(_db).load('), isTrue);
    expect(main.contains('_diary.pastRuns()'), isTrue);
    expect(
      profile.contains('showChronicle('),
      isTrue,
      reason: 'kronika ma drzwi obok licznika dni, bo to ten sam licznik',
    );
  });
}
