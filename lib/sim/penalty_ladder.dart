/// Co się stanie, zanim się stanie (§2.3, §2.5.4, §12).
///
/// ⚠️ **Gra karała za wodę, jedzenie i sen, i nigdzie nie mówiła jak.** Kary
/// były policzone, opisane w komentarzach i widoczne dopiero wtedy, gdy już
/// bolały — a §12 stoi na tym, że gracz ma widzieć cenę **przed** decyzją, a
/// nie po niej. „Zostało mi pół butelki" jest liczbą; „przy dwóch procentach
/// masy ciała celność spada o piętnaście" jest decyzją.
///
/// ⚠️ **Szczeble są *generowane z tych samych funkcji*, które karzą.** Wpisane
/// ręcznie rozjechałyby się z modelem przy pierwszej zmianie progu, a ekran,
/// który kłamie o karach, jest gorszy od ekranu, który milczy — to jest ta sama
/// zasada, dla której katalog przedmiotów na stronie jest generowany z danych
/// gry, a nie przepisany.
library;

import 'physiology.dart';

/// Jeden szczebel: od jakiej wartości obowiązuje i co robi.
class Rung {
  const Rung({
    required this.at,
    required this.accuracy,
    required this.actionTime,
    required this.extraMoa,
    required this.learning,
  });

  /// Wartość progu w jednostce tej witalności — patrz [PenaltyLadder.unit].
  final double at;

  /// Mnożnik celności; 1 to bez zmian.
  final double accuracy;

  /// Mnożnik czasu czynności; 1 to bez zmian.
  final double actionTime;

  /// Ile dochodzi do `MOA_total` (§5.1.1) — czyli o ile szerzej się strzela.
  final double extraMoa;

  /// Mnożnik tempa nauki (§7.2).
  final double learning;

  bool get isClean =>
      accuracy == 1 && actionTime == 1 && extraMoa == 0 && learning == 1;

  /// Czy ten szczebel mówi to samo co [other] — po skutkach, nie po progu.
  bool sameAs(Rung other) =>
      accuracy == other.accuracy &&
      actionTime == other.actionTime &&
      extraMoa == other.extraMoa &&
      learning == other.learning;
}

/// W czym mierzy się próg tej witalności.
enum LadderUnit {
  /// Ubytek wody jako ułamek masy ciała (§2.3's skala kliniczna).
  bodyMassShare,

  /// Zapas dobowy jako ułamek (§2.3).
  dailyShare,

  /// Godziny długu (§2.5.4).
  hours,
}

/// Drabinka kar jednej witalności, od najłagodniejszej do najostrzejszej.
class PenaltyLadder {
  const PenaltyLadder({
    required this.unit,
    required this.rungs,
    required this.now,
  });

  final LadderUnit unit;

  /// Szczeble **z karą**, w kolejności, w jakiej się je spotyka. Szczebel bez
  /// kary nie jest szczeblem — to jest stan zdrowy i mówi o nim [reached].
  final List<Rung> rungs;

  /// Gdzie gracz stoi teraz, w tej samej jednostce co [Rung.at].
  final double now;

  /// Czy ten szczebel już obowiązuje.
  bool reached(Rung rung) => now >= rung.at;

  /// Ostatni obowiązujący szczebel, albo null — nic jeszcze nie boli.
  Rung? get current {
    Rung? found;
    for (final rung in rungs) {
      if (reached(rung)) found = rung;
    }
    return found;
  }
}

/// §2.3: woda. Próg mierzony ubytkiem jako ułamkiem masy ciała.
PenaltyLadder waterLadder({
  required double waterMl,
  required double dailyMl,
  required double bodyMassKg,
}) {
  if (dailyMl <= 0 || bodyMassKg <= 0) {
    return const PenaltyLadder(
      unit: LadderUnit.bodyMassShare,
      rungs: [],
      now: 0,
    );
  }

  Rung rungAt(double share) {
    final state = thirstState(
      waterMl: dailyMl - share * bodyMassKg * 1000,
      dailyMl: dailyMl,
      bodyMassKg: bodyMassKg,
    );

    return Rung(
      at: share,
      accuracy: state.accuracyPenalty,
      actionTime: state.actionTimeMultiplier,
      extraMoa: 0,
      learning: 1,
    );
  }

  final deficit = ((dailyMl - waterMl) / 1000) / bodyMassKg;
  return PenaltyLadder(
    unit: LadderUnit.bodyMassShare,
    rungs: _steps(0, 0.12, 0.001, rungAt),
    now: deficit < 0 ? 0 : deficit,
  );
}

/// §2.3: jedzenie. Próg mierzony zapasem dobowym.
///
/// ⚠️ Drabinka biegnie **w dół**: sto procent zapasu to stan zdrowy, zero to
/// dno. Próg jest więc „poniżej tylu procent", a `now` jest tym, ile brakuje —
/// inaczej porównanie `now >= at` mówiłoby dokładną odwrotność.
PenaltyLadder foodLadder({
  required double caloriesKcal,
  required double dailyKcal,
}) {
  if (dailyKcal <= 0) {
    return const PenaltyLadder(unit: LadderUnit.dailyShare, rungs: [], now: 0);
  }

  Rung rungAt(double missing) {
    final state = hungerState(
      caloriesKcal: (1 - missing) * dailyKcal,
      dailyKcal: dailyKcal,
    );

    return Rung(
      at: missing,
      accuracy: state.precisionPenalty,
      actionTime: state.actionTimeMultiplier,
      extraMoa: 0,
      learning: 1,
    );
  }

  final left = (caloriesKcal / dailyKcal).clamp(0.0, 1.0);
  return PenaltyLadder(
    unit: LadderUnit.dailyShare,
    rungs: _steps(0, 1, 0.001, rungAt),
    now: 1 - left,
  );
}

/// §2.5.4: sen. Próg mierzony godzinami długu.
PenaltyLadder sleepLadder(Duration debt) {
  Rung rungAt(double hours) {
    final state = sleepState(Duration(minutes: (hours * 60).round()));

    return Rung(
      at: hours,
      accuracy: 1,
      actionTime: state.actionTimeMultiplier,
      extraMoa: state.extraMoa,
      learning: state.learningRateMultiplier,
    );
  }

  return PenaltyLadder(
    unit: LadderUnit.hours,
    rungs: _steps(0, 30, 0.25, rungAt),
    now: debt.inMinutes / 60,
  );
}

/// Przechodzi dziedzinę i wypuszcza szczebel wszędzie tam, gdzie kara się
/// zmienia.
///
/// ⚠️ To jest cała sztuczka tego pliku: progi nie są tu wpisane, tylko
/// **znajdowane**. Zmiana pięciu procent na sześć w `physiology.dart` przesuwa
/// drabinkę bez dotykania niczego tutaj.
List<Rung> _steps(
  double from,
  double to,
  double step,
  Rung Function(double) at,
) {
  final found = <Rung>[];
  var previous = at(from);

  // ⚠️ **Licznikiem całkowitym, nie dodawaniem kroku.** Sto dodawań po 0,001
  // daje 0,05000000000000001, a próg, który minimalnie przekracza swoją własną
  // wartość, jest progiem, na którym gracz nigdy nie stanie: porównanie
  // `now >= at` mówi wtedy „jeszcze nie" dokładnie w punkcie kary.
  final steps = ((to - from) / step).round();
  for (var index = 1; index <= steps; index++) {
    final rung = at(from + index * step);
    if (rung.sameAs(previous)) continue;

    previous = rung;
    if (!rung.isClean) found.add(rung);
  }

  return found;
}
