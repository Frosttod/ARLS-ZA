import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:test/test.dart';

/// WARSZTAT STOI, KIEDY NIKOGO PRZY NIM NIE MA (§2.1a.3, §18.4, §18.6).
///
/// ⚠️ **`readyAt` był zegarem ściennym i nie wiedział, gdzie stoi postać.**
/// Obecność sprawdzana była raz, przy odpalaniu roboty, i nigdy więcej — więc
/// plecak wojskowy dało się zostawić na warsztacie, przejść pół miasta i
/// odebrać go w terenie. §2.1a.3 wymienia crafting wśród zajęć schronowych, a
/// te tykają **w strefie schronu lub obozu**.
///
/// Budowa tę regułę miała od początku (`Shelter.worked` zalicza czas tylko na
/// placu). Imadło nie — i to jest jedyna różnica, którą ten plik zamyka.
void main() {
  final start = DateTime.utc(2026, 8, 30, 12);

  CraftJob jobOf({Duration work = const Duration(minutes: 60)}) => CraftJob(
    recipeId: 'pack_military',
    startedAt: start,
    readyAt: start.add(work),
  );

  group('§2.1a.3: wyjście ze strefy zatrzymuje zegar', () {
    test('praca odłożona nie posuwa się dalej', () {
      final away = jobOf().suspended(
        at: start.add(const Duration(minutes: 20)),
      );

      // Czterdzieści minut później na zegarze ściennym, i dalej te same
      // czterdzieści minut roboty do końca.
      final later = start.add(const Duration(minutes: 60));

      expect(away.isPaused, isTrue);
      expect(away.remainingAt(later), const Duration(minutes: 40));
      expect(away.isDoneAt(later), isFalse);
    });

    test('a pasek stoi razem z nią', () {
      // §12: pasek liczący do `readyAt` sunąłby dalej po wyjściu i doszedłby
      // do końca, po którym nic by się nie stało.
      final away = jobOf().suspended(
        at: start.add(const Duration(minutes: 15)),
      );

      expect(away.progressAt(start.add(const Duration(minutes: 55))), 0.25);
      expect(
        away.creditedAt(start.add(const Duration(hours: 5))),
        const Duration(minutes: 15),
      );
    });

    test('i drugie wyjście niczego nie przestawia', () {
      // Odczyty GPS przychodzą co kilkanaście sekund; każdy z nich woła tę samą
      // funkcję. Gdyby każdy przesuwał stempel, praca zamarłaby na zawsze.
      final away = jobOf().suspended(
        at: start.add(const Duration(minutes: 20)),
      );
      final again = away.suspended(at: start.add(const Duration(minutes: 21)));

      expect(again.pausedAt, away.pausedAt);
    });
  });

  group('§2.1a.3: powrót ją podejmuje', () {
    test('termin przesuwa się o czas nieobecności', () {
      // ⚠️ Zamrożenie, nie utrata: robota ma zostać dokładnie tam, gdzie ją
      // zostawiono, a nie cofnąć się do początku ani przeskoczyć do końca.
      final away = jobOf().suspended(
        at: start.add(const Duration(minutes: 20)),
      );
      final back = away.resumed(at: start.add(const Duration(hours: 3)));

      expect(back.isPaused, isFalse);
      expect(
        back.remainingAt(start.add(const Duration(hours: 3))),
        const Duration(minutes: 40),
      );
    });

    test('a postęp jest ten sam po obu stronach przerwy', () {
      final away = jobOf().suspended(
        at: start.add(const Duration(minutes: 30)),
      );
      final back = away.resumed(at: start.add(const Duration(days: 1)));

      expect(back.progressAt(start.add(const Duration(days: 1))), 0.5);
    });

    test('powrót do pracy, która nie stała, nic nie zmienia', () {
      final job = jobOf();

      expect(job.resumed(at: start.add(const Duration(minutes: 5))), same(job));
    });

    test('i godzina spędzona w schronie kończy godzinną robotę', () {
      // Reguła w drugą stronę: obecność ma **wystarczać**. Praca, która stoi
      // mimo obecności, jest gorsza od pracy, która idzie mimo nieobecności.
      final job = jobOf();

      expect(job.isDoneAt(start.add(const Duration(minutes: 60))), isTrue);
    });
  });

  test('§2.1a.3: i tick naprawdę o to pyta', () {
    // ⚠️ Test źródłowy, bo ta usterka jest z tej samej rodziny co jedenaście
    // poprzednich: reguła może być poprawna i niewołana. Model umiał odkładać
    // pracę — nikt go o to nie prosił.
    final main = File('lib/main.dart').readAsStringSync();
    final bench = File(
      'lib/game/controllers/craft_controller.dart',
    ).readAsStringSync();

    expect(main.contains('_workbench.presence('), isTrue);
    expect(
      bench.contains('shelterAt(at, shelters, now: now)'),
      isTrue,
      reason: 'ta sama odpowiedź, którą warsztat daje, oferując robotę (§8.5)',
    );
  });
}
