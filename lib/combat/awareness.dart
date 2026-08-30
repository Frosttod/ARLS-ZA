/// Co przeciwnik widzi, co słyszy, i kiedy stoisz za jego plecami (§6.2, §5.6).
///
/// ⚠️ **Wykrycie było promieniem, a promień nie ma tyłu.** Kroczący zauważał
/// gracza tak samo zza pleców jak na wprost, więc jedyną odpowiedzią na
/// przeciwnika była broń albo dystans. Podchodzenie nie istniało jako
/// możliwość, bo nie było czego podejść.
///
/// Trzy reguły, i każda z nich jest widoczna dla gracza, zanim go ukarze:
///
///   * **patrzy albo nie patrzy** — stożek [kFieldOfViewDeg] wokół kierunku,
///     w którym idzie; poza nim nie widzi nic, choćby stał metr dalej;
///   * **słyszy według tego, jak szybko idziesz** — postój jest bezgłośny,
///     wolny krok słychać z ośmiu metrów, marsz z piętnastu, bieg z
///     czterdziestu (§5.6.1);
///   * **usłyszane to nie zobaczone** — dźwięk robi z niego czujnego, a
///     czujny idzie *w stronę hałasu*, nie do gracza (§5.6.2).
///
/// ⚠️ **Kierunek patrzenia musi być narysowany na mapie.** Stożek, którego nie
/// widać, jest niewidzialną karą, a nie mechaniką — i to był powód, dla
/// którego tego nie było. Dopóki marker nie pokazuje, w którą stronę patrzy,
/// nic tutaj nie ma prawa działać.
library;

import 'dart:math';

import 'ballistics.dart' show HitLocation, rollHitLocation;
import '../items/item.dart';
import 'enemy.dart';
import 'melee.dart';

/// §5.5.3: kanały obrażeń są częścią tej samej odpowiedzi co [meleeOutcome] —
/// kto pyta o jeden zamach, pyta o oba naraz.
export 'melee.dart';
import 'noise.dart';
import '../map/geometry.dart';

/// §6.2: ile świata widzi naraz, w stopniach, licząc łącznie.
///
/// Sto dwadzieścia stopni to pole widzenia człowieka, w którym cokolwiek
/// rozpoznaje — nie sto osiemdziesiąt, bo skrajem oka widać ruch, a nie
/// sylwetkę. Zostawia sześćdziesiąt stopni czystego tyłu z każdej strony.
const double kFieldOfViewDeg = 120;

/// §5.6.1: ile hałasu robi gracz, idąc z tą prędkością.
///
/// ⚠️ **To jest cała skradanka.** Gra mierzy prawdziwy ruch prawdziwego
/// człowieka (§0), więc nie ma przycisku „kucnij" i nigdy nie będzie —
/// jedynym, co gracz może zrobić ciszej, jest iść wolniej. I to działa w obie
/// strony: pościg zmusza do biegu, a bieg słychać z czterdziestu metrów.
double playerNoiseM(double speedKmh) {
  if (speedKmh < kStillKmh) return 0;
  if (speedKmh < kCarefulKmh) return kCarefulNoiseM;
  if (speedKmh < kRunningKmh) return NoiseKind.walking.baseM;
  return NoiseKind.running.baseM;
}

/// Poniżej tego gracz stoi. Ta sama granica, której używa §10.2's stillness.
const double kStillKmh = 0.5;

/// Wolny, uważny krok. Powyżej tego idzie się normalnie.
const double kCarefulKmh = 3.2;

/// Od tego zaczyna się bieg (§2.2's trucht).
const double kRunningKmh = 6.4;

/// Ile słychać wolny krok. Mniej niż marsz, więcej niż nic — ostatnie metry
/// podejścia są ryzykiem, i o to chodzi.
const double kCarefulNoiseM = 8;

/// §6.2: czy [at] leży w polu widzenia przeciwnika.
///
/// Bez kierunku patrzenia — świeżo postawiony, jeszcze nieruszony — widzi
/// dookoła. To jest właściwa odpowiedź, a nie ślepota: nie wiadomo, w którą
/// stronę stoi, więc założenie, że akurat tyłem, byłoby prezentem.
bool inFieldOfView(Enemy enemy, GeoPoint at) {
  final heading = enemy.headingDeg;
  if (heading == null) return true;

  return _offAxisDeg(enemy, at, heading) <= kFieldOfViewDeg / 2;
}

/// §5.5.1: czy gracz stoi za jego plecami.
///
/// Nie jest to odwrotność [inFieldOfView] przez przypadek — tył jest węższy
/// niż „nie przód". Cios w plecy wymaga stania *za* czymś, nie z boku, i ta
/// różnica jest tym, co odróżnia podejście od wejścia w zwarcie bokiem.
bool isBehind(Enemy enemy, GeoPoint at) {
  final heading = enemy.headingDeg;
  if (heading == null) return false;

  return _offAxisDeg(enemy, at, heading) >= 180 - kBackArcDeg / 2;
}

/// Ile stopni z tyłu liczy się jako plecy, łącznie.
const double kBackArcDeg = 120;

/// Jak daleko od kierunku patrzenia leży [at], w stopniach, 0–180.
double _offAxisDeg(Enemy enemy, GeoPoint at, double heading) {
  final bearing = enemy.position.bearingTo(at);
  final delta = (bearing - heading).abs() % 360;
  return delta > 180 ? 360 - delta : delta;
}

/// §6.2, §5.6: czy ten przeciwnik ma teraz powód, żeby ruszyć na gracza.
///
/// [sightM] to promień z §6.2 po wszystkich modyfikatorach — Zwiad, ciemność —
/// policzony przez [Enemy.sightAgainst]. Tutaj rozstrzyga się tylko to, czy
/// przeciwnik jest zwrócony we właściwą stronę.
///
/// ⚠️ Ścigający widzi wszystko. Kiedy już biegnie, obracanie się za graczem
/// jest tym, co robi — a przeciwnik, którego da się zgubić obchodząc go w
/// pół sekundy, nie jest zagrożeniem, tylko przeszkodą.
bool seesPlayer(Enemy enemy, GeoPoint at, {required double sightM}) {
  if (enemy.isDead) return false;
  if (enemy.position.distanceTo(at) > sightM) return false;

  return switch (enemy.state) {
    EnemyState.chase || EnemyState.spent || EnemyState.alert => true,
    EnemyState.idle || EnemyState.returning => inFieldOfView(enemy, at),
  };
}

/// §5.6.1: czy słychać stąd gracza idącego z tą prędkością.
///
/// Słuch nie ma kierunku — to jest różnica między nim a wzrokiem i powód, dla
/// którego bieg jest karą, której nie da się obejść ustawieniem się z tyłu.
bool hearsPlayer(Enemy enemy, GeoPoint at, {required double noiseM}) =>
    !enemy.isDead && noiseM > 0 && enemy.position.distanceTo(at) <= noiseM;

/// §5.5.1: czy ten cios jest ciosem w plecy kogoś, kto o niczym nie wie.
///
/// Trzy warunki naraz, i każdy z nich gracz może sprawdzić wzrokiem na mapie:
/// przeciwnik nie jest wzbudzony, stoisz za nim, i jesteś na wyciągnięcie ręki
/// — nie w pasmie zwarcia, które ma dwadzieścia metrów, tylko *przy nim*.
/// ⚠️ **Brutala się nie ucisza.** §6.2 daje mu sześć do ośmiu litrów krwi i
/// kark, którego nie da się przeciąć nożem w jednym ruchu — a mechanika, w
/// której najgroźniejsza rzecz w grze pada od jednego dotknięcia od tyłu,
/// zamienia elitę w cel treningowy. Na niego trzeba mieć broń albo pomysł.
bool canTakeDown(Enemy enemy, GeoPoint at) =>
    !enemy.isDead &&
    enemy.kind != EnemyKind.brute &&
    !enemy.isAware &&
    isBehind(enemy, at) &&
    enemy.position.distanceTo(at) <= kTakeDownM;

/// Na wyciągnięcie ręki. Ostatnie trzy metry są tym, co się kupuje wolnym
/// podejściem, i jedyną odległością, z której da się kogoś uciszyć.
const double kTakeDownM = 3;

/// §5.6.1: ile słychać samo uciszenie. Cicho, ale nie bezgłośnie — ciało pada.
const double kTakeDownNoiseM = 12;

/// §5.5.1, §2.6, §5.6.1: co robi jeden zamach — walkę, albo jej koniec.
///
/// Jedno miejsce, bo to są trzy liczby, które muszą się zgadzać ze sobą: ile
/// krwi, jak szybko leci, i ile przy tym słychać. Rozdzielone po ekranie
/// rozjechałyby się przy pierwszej zmianie któregokolwiek z progów.
///
/// [bladeBloodMl] to `blood_ml_per_hit` z przedmiotu w ręce, albo null dla
/// gołych rąk — a gołymi rękami nikogo się nie ucisza.
///
/// ⚠️ Losowanie jest w środku, bo uciszenie **nie chybia**: rzut na trafienie
/// zrobiony na zewnątrz i tak trzeba by tu zignorować, a dwa miejsca, z
/// których jedno czasem ignoruje drugie, to jedno miejsce za dużo.
///
/// [blade] to przedmiot w ręce, albo null dla gołych rąk — gołymi rękami nikogo
/// się nie ucisza i nikogo się nie przewraca.
///
/// [crowd] to ilu ich stoi w zwarciu: §5.5.3's tłok, ten sam, który liczy
/// [flankingMultiplier]. Decyduje o tym, czy zasięg pomaga, czy zawadza.
({
  double bloodMl,
  double bleeding,
  double noiseM,
  HitLocation where,
  double staggerSeconds,
})
meleeOutcome({
  required Enemy target,
  required GeoPoint at,
  required ItemDefinition? blade,
  required double chance,
  required Random random,
  int crowd = 1,
}) {
  final bladeBloodMl = (blade?.props['blood_ml_per_hit'] as num?)?.toDouble();
  final armed = bladeBloodMl != null;

  if (armed && canTakeDown(target, at)) {
    // Cała objętość: to nie jest rana, tylko koniec. I ciszej, bo jedyne, co
    // słychać, to ciało.
    // Głowa, bo dziennik i pasek walki mówią wtedy „egzekucja" — a to jest
    // dokładnie to, co się właśnie stało.
    return (
      bloodMl: target.bloodMl,
      bleeding: 5,
      noiseM: kTakeDownNoiseM,
      where: HitLocation.head,
      // Nie ma czego oszałamiać: to jest koniec, a nie przerwa.
      staggerSeconds: 0.0,
    );
  }

  final where = rollHitLocation(random.nextDouble());

  // §5.5.3: zasięg pomaga w pojedynkę i zawadza w tłoku (`reachEdge`), a obuch
  // działa **tylko wtedy, gdy cios wyszedł** — kij minięty obok niczego nie
  // przewraca.
  final landed =
      random.nextDouble() <
      (chance +
              reachEdge(
                reachM: (blade?.props['reach_m'] as num?)?.toDouble(),
                crowd: crowd,
              ))
          .clamp(0.0, 1.0);

  return (
    bloodMl: landed
        ? (bladeBloodMl ?? kBareHandsBloodMl) * where.multiplier
        : 0,
    staggerSeconds: landed ? staggerSecondsOf(blade) : 0.0,
    bleeding: switch (where) {
      HitLocation.head => 5,
      HitLocation.torso => 3,
      _ => 1,
    },
    noiseM: NoiseKind.melee.baseM,
    where: where,
  );
}

/// §5.5.3: co robi pięść. Mało, i o to chodzi — broń biała jest decyzją.
const double kBareHandsBloodMl = 40;

/// §3.3, §12: jak blisko musi być przeciwnik, żeby gra przestała oszczędzać.
///
/// ⚠️ **Ekonomia baterii wygrywała z walką.** Decyzja o tempie brała
/// `inCombat: false` wpisane na sztywno — z komentarzem „walka przyjdzie w
/// etapie 5" — więc przy trzech Kroczących pod nosem GPS chodził w tempie
/// spaceru, ekran w oszczędnym, a markery skakały zamiast płynąć. Dokładnie
/// wtedy, kiedy z kierunku ich patrzenia odczytuje się, czy się da przejść.
const double kFightPaceM = 150;

/// §5.5.2, §12: jak blisko coś stoi, w progach, które gracz widzi na pasku.
///
/// ⚠️ **Ostrzeżenie przychodziło za późno, i to jest zgłoszenie z terenu.**
/// Pasek liczył wyłącznie tych, którzy **już** ruszyli — czujnych i biegnących
/// — więc Kroczący stojący osiemdziesiąt metrów dalej, jeszcze nieświadomy, nie
/// istniał na ekranie. Gracz dowiadywał się o nim w chwili, w której było już
/// za późno na cokolwiek poza biegiem.
///
/// Cztery progi, bo to są cztery różne decyzje: **daleko** (idź dalej),
/// **sto siedemdziesiąt pięć** (zwolnij, popatrz na stożki), **sto
/// pięćdziesiąt** (zdecyduj: obejść czy wracać), **sto** (już nie ma obejścia —
/// albo cicho w bok, albo do broni).
enum ThreatBand {
  none(double.infinity),
  watch(175),
  close(150),
  onYou(100);

  const ThreatBand(this.metres);

  /// Górna granica pasma.
  final double metres;

  /// Pasmo dla najbliższego, cokolwiek robi.
  static ThreatBand of(double? nearestM) {
    if (nearestM == null) return ThreatBand.none;
    if (nearestM <= ThreatBand.onYou.metres) return ThreatBand.onYou;
    if (nearestM <= ThreatBand.close.metres) return ThreatBand.close;
    if (nearestM <= ThreatBand.watch.metres) return ThreatBand.watch;
    return ThreatBand.none;
  }
}
