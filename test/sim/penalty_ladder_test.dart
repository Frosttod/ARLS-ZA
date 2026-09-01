import 'package:arls_za/sim/penalty_ladder.dart';
import 'package:test/test.dart';

/// DRABINKA KAR (§2.3, §2.5.4, §12).
///
/// ⚠️ **Gra karała za wodę, jedzenie i sen, i nigdzie nie mówiła jak.** §12
/// stoi na tym, że cenę widać przed decyzją, a nie po niej.
///
/// Szczeble są generowane z tych samych funkcji, które karzą — ten plik pilnuje,
/// że generowanie znajduje te progi, które model naprawdę ma.
void main() {
  group('§2.3: woda', () {
    final ladder = waterLadder(waterMl: 2905, dailyMl: 2905, bodyMassKg: 83);

    test('trzy szczeble, dokładnie te z §2.3', () {
      expect(ladder.rungs, hasLength(3));
      expect(ladder.rungs.map((r) => (r.at * 100).round()), [2, 5, 10]);
    });

    test('dwa procent masy ciała to celność ×0,85', () {
      expect(ladder.rungs.first.accuracy, closeTo(0.85, 0.001));
      expect(ladder.rungs.first.actionTime, 1);
    });

    test('a pięć i dziesięć to czas czynności', () {
      expect(ladder.rungs[1].actionTime, closeTo(1.30, 0.001));
      expect(ladder.rungs[2].actionTime, closeTo(1.60, 0.001));
    });

    test('napojony nie stoi na żadnym', () {
      expect(ladder.current, isNull);
    });

    test('a odwodniony stoi na tym, który go boli', () {
      // Pięć procent z osiemdziesięciu trzech kilogramów to 4,15 litra ubytku.
      final dry = waterLadder(waterMl: 0, dailyMl: 4150, bodyMassKg: 83);

      expect(dry.current, isNotNull);
      expect(dry.current!.actionTime, closeTo(1.30, 0.001));
    });
  });

  group('§2.3: jedzenie', () {
    final ladder = foodLadder(caloriesKcal: 2413, dailyKcal: 2413);

    test('dwa szczeble: połowa zapasu i jedna piąta', () {
      expect(ladder.rungs, hasLength(2));
      expect(ladder.rungs.map((r) => (r.at * 100).round()), [50, 80]);
    });

    test(
      'poniżej połowy drżą ręce, poniżej piątej części wszystko wolniej',
      () {
        expect(ladder.rungs.first.accuracy, closeTo(0.90, 0.001));
        expect(ladder.rungs[1].actionTime, closeTo(1.20, 0.001));
      },
    );

    test('a próg liczy brak, nie zapas', () {
      // ⚠️ Drabinka biegnie w dół. Gdyby `now` liczyło zapas, porównanie
      // mówiłoby dokładną odwrotność: najedzony byłby konający.
      final half = foodLadder(caloriesKcal: 1000, dailyKcal: 2413);

      expect(half.now, closeTo(0.586, 0.01));
      expect(half.current, isNotNull);
      expect(half.current!.accuracy, closeTo(0.90, 0.001));
    });
  });

  group('§2.5.4: sen', () {
    final ladder = sleepLadder(Duration.zero);

    test('dwa szczeble: cztery godziny i dwanaście', () {
      expect(ladder.rungs, hasLength(2));
      expect(ladder.rungs.map((r) => r.at.round()), [4, 12]);
    });

    test('cztery godziny to jedna MOA, dwanaście to trzy i połowa czasu', () {
      expect(ladder.rungs.first.extraMoa, 1);
      expect(ladder.rungs[1].extraMoa, 3);
      expect(ladder.rungs[1].actionTime, closeTo(1.50, 0.001));
      expect(ladder.rungs[1].learning, closeTo(0.80, 0.001));
    });

    test('trzy godziny długu nie kosztują jeszcze nic', () {
      // Dokładnie ten przypadek ze zgłoszenia: pasek pokazywał dług, a profil
      // mówił „nic Cię nie kosztuje" — i to była prawda, której nie dało się
      // sprawdzić.
      expect(sleepLadder(const Duration(hours: 3)).current, isNull);
    });

    test('a pięć już tak', () {
      expect(sleepLadder(const Duration(hours: 5)).current?.extraMoa, 1);
    });
  });
}
