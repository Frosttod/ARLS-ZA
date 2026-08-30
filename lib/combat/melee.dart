/// Drugi kanał obrażeń: czym się bije, a nie tylko ile krwi z tego leci
/// (§5.5.1, §5.5.3).
///
/// ⚠️ **Wszystko w zwarciu robiło dotąd jedną rzecz — upuszczało krew.** Młotek
/// nie tnie, a mimo to jedyną różnicą między nim a maczetą było dwieście
/// mililitrów. `damage_type` leżało w danych wszystkich jedenastu broni białych
/// — `cutting`, `piercing`, `blunt` — i nie czytał go nikt. Piętnasty raz ta
/// sama klasa usterki w tym projekcie.
///
/// Dwa kanały, i to jest cała decyzja przed wyjściem z domu:
///
///   * **sieczna i kolna** — krwawienie. Zabija z czasem, zostawia trupa;
///   * **obuchowa** — oszołomienie. Zabiera następny cios i tnie budżet
///     sprintu, czyli **kupuje dystans teraz**.
///
/// Trzecią odpowiedzią jest cios w plecy (§5.5.1): uciszyć. Zabić, odejść albo
/// uciszyć — trzy wyjścia z jednego spotkania.
library;

import '../items/item.dart';

/// §5.5.1: jak przedmiot rani. Prosto z `damage_type` w danych.
enum DamageType {
  cutting('cutting'),
  piercing('piercing'),
  blunt('blunt');

  const DamageType(this.wire);

  final String wire;

  static DamageType? fromWire(Object? value) {
    for (final known in values) {
      if (known.wire == value) return known;
    }
    return null;
  }

  static DamageType? of(ItemDefinition? item) =>
      item == null ? null : fromWire(item.props['damage_type']);
}

/// §5.5.3: ile sekund oszołomienia daje jeden cios tym.
///
/// ⚠️ **Wyprowadzone z masy, nie dopisane do danych.** Kilogram żelaza na końcu
/// kija robi to, co robi, i nie potrzebuje osobnej liczby, która mogłaby się z
/// masą rozjechać: młotek 0,7 s, pałka 0,9 s, łom 1,6 s, maczuga 1,7 s,
/// łopata 1,9 s.
///
/// Zero dla wszystkiego, co tnie i kłuje — nóż wbity w kark nie przewraca
/// nikogo, tylko wykrwawia.
double staggerSecondsOf(ItemDefinition? item) =>
    DamageType.of(item) == DamageType.blunt ? item!.weightKg : 0;

/// §5.5.3: co oszołomienie robi z budżetem sprintu (§6.1).
///
/// Sekunda oszołomienia zabiera dwie sekundy biegu. To jest ta połowa
/// mechaniki, dla której warto nieść łopatę: ciało, które nie ma czym gonić,
/// jest ciałem, od którego da się odejść — a odejście jest w tej grze zwykle
/// lepsze od wygranej.
const double kStaggerSprintCost = 2;

/// §5.5.3: **długość baseballowego kija to zero.** Wszystko dłuższe pomaga w
/// pojedynkę i przeszkadza w tłoku, wszystko krótsze odwrotnie.
const double kReachBaselineM = 0.9;

/// O ile zasięg przesuwa szansę trafienia, przy tylu przeciwnikach w zwarciu.
///
/// ⚠️ **Włócznia nie może być po prostu lepsza.** Metr dziewięćdziesiąt drzewca
/// trzyma Kroczącego na dystans, kiedy jest jeden — i jest kijem, kiedy trzech
/// stoi dookoła. Nóż nie ma czym trzymać na dystans i nie ma czym zawadzać:
/// w tłoku jest tym, czym był.
///
/// Bez tego `reach_m` (0,3–1,8 m) byłby drugim polem, które leży w danych i nic
/// go nie czyta — a włócznia (290 ml, gorsza od maczety) nie miałaby powodu
/// istnienia.
double reachEdge({required double? reachM, required int crowd}) {
  final over = (reachM ?? kReachBaselineM) - kReachBaselineM;
  if (over == 0) return 0;

  // W tłoku długa broń traci półtora raza tyle, ile dawała w pojedynkę. Krótka
  // nic nie traci — jej przewaga *jest* tłokiem.
  final edge = crowd <= 1
      ? over * 0.12
      : over > 0
      ? over * -0.18
      : over * -0.12;

  return edge.clamp(-0.15, 0.15);
}

/// §5.5.2: ile trwa jeden zamach tym. Domyślnie 1,4 s — tyle co pałką.
///
/// ⚠️ **Cena obucha jest w tej liczbie.** Łopata oszałamia na dwie sekundy i
/// bierze zamach przez dwie: kto bije ciężkim, ten bije rzadziej, i to jest
/// jedyny powód, dla którego maczeta dalej ma sens.
Duration swingTimeOf(ItemDefinition? item) => Duration(
  milliseconds:
      (((item?.props['swing_seconds'] as num?)?.toDouble() ?? 1.4) * 1000)
          .round(),
);
