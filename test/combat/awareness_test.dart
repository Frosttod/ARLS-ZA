import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/awareness.dart';
import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/combat/noise.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// PATRZY, SŁYSZY, ALBO NIE WIE (§6.2, §5.6, §5.5.1).
///
/// ⚠️ **Wykrycie było promieniem, a promień nie ma tyłu.** Kroczący zauważał
/// gracza tak samo zza pleców jak na wprost, więc jedyną odpowiedzią na
/// przeciwnika była broń albo dystans — podchodzenie nie istniało, bo nie było
/// czego podejść.
///
/// Wszystko poniżej opiera się na kierunku, który przeciwnicy mają od zawsze:
/// [advanceEnemy] obraca ich stopniowo w stronę, w którą idą. Brakowało
/// jedynie tego, żeby wzrok o ten kierunek pytał.
void main() {
  const here = GeoPoint(52.4084, 16.9342);

  /// Przeciwnik stojący w [here] i patrzący na północ.
  Enemy facingNorth({
    EnemyState state = EnemyState.idle,
    double? heading = 0,
    GeoPoint? heardAt,
  }) => Enemy.spawn(
    id: 'w',
    kind: EnemyKind.walker,
    at: here,
    home: here,
    random: Random(3),
  ).copyWith(state: state, headingDeg: heading, heardAt: heardAt);

  /// Punkt [metres] od przeciwnika, w podanym kierunku.
  GeoPoint at(double bearingDeg, double metres) =>
      here.offsetBy(metres: metres, bearingDeg: bearingDeg);

  group('§6.2: pole widzenia ma tył', () {
    test('na wprost widzi', () {
      expect(inFieldOfView(facingNorth(), at(0, 20)), isTrue);
    });

    test('skrajem oka jeszcze widzi', () {
      // Pięćdziesiąt stopni w bok, przy stożku sto dwadzieścia.
      expect(inFieldOfView(facingNorth(), at(50, 20)), isTrue);
    });

    test('z boku już nie', () {
      expect(inFieldOfView(facingNorth(), at(90, 20)), isFalse);
    });

    test('i zza pleców na pewno nie', () {
      expect(inFieldOfView(facingNorth(), at(180, 5)), isFalse);
    });

    test('symetrycznie w obie strony', () {
      expect(
        inFieldOfView(facingNorth(), at(300, 20)),
        inFieldOfView(facingNorth(), at(60, 20)),
      );
    });

    test('świeżo postawiony rozgląda się dookoła', () {
      // ⚠️ Nie ślepota, tylko brak informacji: nie wiadomo, w którą stronę
      // stoi, więc założenie, że akurat tyłem, byłoby prezentem.
      final fresh = facingNorth(heading: null);

      expect(inFieldOfView(fresh, at(180, 5)), isTrue);
    });
  });

  group('§6.2: co z tego wynika dla wykrycia', () {
    test('stojący tyłem nie widzi, choćby był metr dalej', () {
      expect(seesPlayer(facingNorth(), at(180, 1), sightM: 80), isFalse);
    });

    test('a na wprost widzi na cały promień', () {
      expect(seesPlayer(facingNorth(), at(0, 70), sightM: 80), isTrue);
    });

    test('poza promieniem nie widzi, choćby patrzył wprost', () {
      expect(seesPlayer(facingNorth(), at(0, 90), sightM: 80), isFalse);
    });

    test('ale ścigający widzi wszystko', () {
      // ⚠️ Przeciwnik, którego da się zgubić obchodząc go w pół sekundy, nie
      // jest zagrożeniem, tylko przeszkodą.
      final chasing = facingNorth(state: EnemyState.chase);

      expect(seesPlayer(chasing, at(180, 10), sightM: 80), isTrue);
    });

    test('i czujny też — już się rozgląda', () {
      final alert = facingNorth(state: EnemyState.alert);

      expect(seesPlayer(alert, at(180, 10), sightM: 80), isTrue);
    });

    test('trup nie widzi nic', () {
      final dead = facingNorth().copyWith(bloodLostMl: 99999);

      expect(dead.isDead, isTrue);
      expect(seesPlayer(dead, at(0, 2), sightM: 80), isFalse);
    });
  });

  group('§5.6.1: słuch nie ma kierunku', () {
    test('postój jest bezgłośny', () {
      expect(playerNoiseM(0), 0);
      expect(playerNoiseM(0.3), 0);
    });

    test('wolny krok słychać z ośmiu metrów', () {
      expect(playerNoiseM(2), kCarefulNoiseM);
    });

    test('marsz z piętnastu', () {
      expect(playerNoiseM(5), 15);
    });

    test('a bieg z czterdziestu', () {
      expect(playerNoiseM(9), 40);
      expect(playerNoiseM(14), 40);
    });

    test('i słychać zza pleców tak samo jak z przodu', () {
      // ⚠️ To jest powód, dla którego bieg jest karą, której nie da się obejść
      // ustawieniem się z tyłu.
      final behind = at(180, 20);

      expect(hearsPlayer(facingNorth(), behind, noiseM: 40), isTrue);
      expect(hearsPlayer(facingNorth(), behind, noiseM: 15), isFalse);
    });

    test('a stojącego nie słychać wcale', () {
      expect(hearsPlayer(facingNorth(), at(0, 1), noiseM: 0), isFalse);
    });
  });

  group('§5.5.1: cios w plecy', () {
    test('za plecami, na wyciągnięcie ręki, i nic nie wie', () {
      expect(canTakeDown(facingNorth(), at(180, 2)), isTrue);
    });

    test('z boku nie — to jest zwarcie, nie podejście', () {
      expect(canTakeDown(facingNorth(), at(90, 2)), isFalse);
    });

    test('z czterech metrów nie', () {
      // Pasmo zwarcia ma dwadzieścia metrów; uciszenie ma trzy.
      expect(canTakeDown(facingNorth(), at(180, 4)), isFalse);
    });

    test('i nie na kimś, kto już wie', () {
      for (final state in [
        EnemyState.alert,
        EnemyState.chase,
        EnemyState.spent,
      ]) {
        expect(
          canTakeDown(facingNorth(state: state), at(180, 2)),
          isFalse,
          reason: state.name,
        );
      }
    });

    test('ani na kimś, kto właśnie idzie sprawdzić hałas', () {
      // ⚠️ Wzbudzony jest wzbudzony. Ktoś, kto idzie na dźwięk, rozgląda się —
      // podejście mu od tyłu jest zakładem, a nie egzekucją.
      final searching = facingNorth(heardAt: at(0, 30));

      expect(searching.isAware, isTrue);
      expect(canTakeDown(searching, at(180, 2)), isFalse);
    });

    test('i nigdy na Brutalu (§6.2)', () {
      // ⚠️ Sześć do ośmiu litrów krwi i kark, którego nie da się przeciąć
      // nożem w jednym ruchu. Mechanika, w której najgroźniejsza rzecz w grze
      // pada od dotknięcia od tyłu, zamienia elitę w cel treningowy.
      final brute = Enemy.spawn(
        id: 'b',
        kind: EnemyKind.brute,
        at: here,
        home: here,
        random: Random(3),
      ).copyWith(headingDeg: 0);

      expect(canTakeDown(brute, at(180, 2)), isFalse);
    });

    test('ani na kimś świeżo postawionym, który patrzy dookoła', () {
      expect(canTakeDown(facingNorth(heading: null), at(180, 2)), isFalse);
    });
  });

  group('§5.6: dwie drogi, i to nie są te same drzwi', () {
    test('można stać metr za nim i pozostać niezauważonym, stojąc', () {
      // Cała obietnica skradanki w jednym zdaniu.
      final walker = facingNorth();
      final spot = at(180, 1);

      expect(seesPlayer(walker, spot, sightM: 80), isFalse);
      expect(hearsPlayer(walker, spot, noiseM: playerNoiseM(0)), isFalse);
      expect(canTakeDown(walker, spot), isTrue);
    });

    test('ale nie da się do niego dobiec', () {
      // Czterdzieści metrów hałasu: usłyszy na długo przed tym, zanim dojdziesz
      // na trzy metry.
      final walker = facingNorth();
      final spot = at(180, 20);

      expect(seesPlayer(walker, spot, sightM: 80), isFalse);
      expect(hearsPlayer(walker, spot, noiseM: playerNoiseM(9)), isTrue);
    });

    test('a wolny krok kupuje ostatnie metry', () {
      final walker = facingNorth();

      expect(
        hearsPlayer(walker, at(180, 12), noiseM: playerNoiseM(2)),
        isFalse,
      );
      expect(hearsPlayer(walker, at(180, 12), noiseM: playerNoiseM(5)), isTrue);
    });
  });

  group('§5.5.1: co robi jeden zamach', () {
    final always = Random(1);

    test('uciszenie zabiera całą krew i nie chybia', () {
      final walker = facingNorth();
      final blow = meleeOutcome(
        target: walker,
        at: at(180, 2),
        bladeBloodMl: 180,
        // Zero szans na trafienie: uciszenie nie jest rzutem.
        chance: 0,
        random: always,
      );

      expect(blow.bloodMl, walker.bloodMl);
      expect(blow.where, HitLocation.head);
      expect(blow.noiseM, kTakeDownNoiseM);
    });

    test('a zwykły cios jest głośniejszy niż uciszenie', () {
      final blow = meleeOutcome(
        target: facingNorth(),
        // Z przodu: to jest walka, nie podejście.
        at: at(0, 2),
        bladeBloodMl: 180,
        chance: 1,
        random: always,
      );

      expect(blow.noiseM, greaterThan(kTakeDownNoiseM));
      expect(blow.bloodMl, lessThan(facingNorth().bloodMl));
    });

    test('gołymi rękami nikogo się nie ucisza', () {
      // ⚠️ Inaczej nóż nie byłby decyzją, tylko ozdobą.
      final blow = meleeOutcome(
        target: facingNorth(),
        at: at(180, 2),
        bladeBloodMl: null,
        chance: 1,
        random: always,
      );

      expect(blow.bloodMl, lessThan(facingNorth().bloodMl));
      expect(blow.noiseM, NoiseKind.melee.baseM);
    });

    test('chybiony cios nie zabiera nic, ale i tak jest słychać', () {
      final blow = meleeOutcome(
        target: facingNorth(),
        at: at(0, 2),
        bladeBloodMl: 180,
        chance: 0,
        random: always,
      );

      expect(blow.bloodMl, 0);
      expect(blow.noiseM, NoiseKind.melee.baseM);
    });
  });

  test('§6.2, §12: a stożek na mapie jest tym samym stożkiem', () {
    // ⚠️ Klin narysowany węziej niż pole widzenia to kłamstwo, na którym gracz
    // opiera decyzję: obchodzi coś, co wygląda na skraj widzenia, i zostaje
    // zauważony bez wyjaśnienia na ekranie.
    final surface = File('lib/ui/maplibre_surface.dart').readAsStringSync();

    expect(surface.contains('spreadDeg = kFieldOfViewDeg'), isTrue);
  });

  group('§5.5.2, §12: progi ostrzeżenia', () {
    test('daleko to nic', () {
      expect(ThreatBand.of(null), ThreatBand.none);
      expect(ThreatBand.of(300), ThreatBand.none);
      expect(ThreatBand.of(176), ThreatBand.none);
    });

    test('sto siedemdziesiąt pięć: popatrz na stożki', () {
      expect(ThreatBand.of(175), ThreatBand.watch);
      expect(ThreatBand.of(151), ThreatBand.watch);
    });

    test('sto pięćdziesiąt: obejść czy wracać', () {
      expect(ThreatBand.of(150), ThreatBand.close);
      expect(ThreatBand.of(101), ThreatBand.close);
    });

    test('sto: nie ma już obejścia', () {
      expect(ThreatBand.of(100), ThreatBand.onYou);
      expect(ThreatBand.of(3), ThreatBand.onYou);
    });

    test('progi idą w jedną stronę i nie zachodzą na siebie', () {
      // ⚠️ Zgłoszone z terenu: ostrzeżenie zapalało się dopiero wtedy, gdy coś
      // już szło — czyli w chwili, w której zostawał sam bieg. Progi liczą się
      // od odległości, nie od tego, czy przeciwnik już wie.
      expect(ThreatBand.onYou.metres, lessThan(ThreatBand.close.metres));
      expect(ThreatBand.close.metres, lessThan(ThreatBand.watch.metres));
    });
  });
}
