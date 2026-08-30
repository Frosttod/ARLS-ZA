import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/awareness.dart';
import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// DWA KANAŁY OBRAŻEŃ (§5.5.1, §5.5.3).
///
/// ⚠️ **Wszystko w zwarciu robiło jedną rzecz — upuszczało krew.** Młotek nie
/// tnie, a mimo to jedyną różnicą między nim a maczetą było dwieście
/// mililitrów. `damage_type` leżało w danych wszystkich jedenastu broni białych
/// i nie czytał go nikt; `reach_m` tak samo. Piętnasty i szesnasty przypadek tej
/// samej klasy usterki.
///
/// Teraz: sieczna i kolna wykrwawiają, obuchowa zatrzymuje. Zabić, odejść albo
/// uciszyć — trzy wyjścia z jednego spotkania.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  const home = GeoPoint(52.4064, 16.9252);

  Enemy walker({EnemyKind kind = EnemyKind.walker}) => Enemy(
    id: 'w1',
    kind: kind,
    position: home,
    home: home,
    bloodMl: 3400,
    walkKmh: 3.5,
    runKmh: 16,
    headingDeg: 0,
  );

  group('§5.5.3: obuch zatrzymuje, ostrze wykrwawia', () {
    test('łopata oszałamia na tyle sekund, ile waży', () {
      // ⚠️ Wyprowadzone z masy, nie dopisane do danych: kilogram żelaza na
      // końcu kija robi to, co robi.
      expect(staggerSecondsOf(catalogue['melee_shovel']), 1.9);
      expect(staggerSecondsOf(catalogue['melee_hammer']), 0.7);
      expect(staggerSecondsOf(catalogue['melee_crowbar']), 1.6);
    });

    test('a maczeta i nóż nie oszałamiają wcale', () {
      // Nóż wbity w kark nikogo nie przewraca — wykrwawia.
      expect(staggerSecondsOf(catalogue['melee_machete']), 0);
      expect(staggerSecondsOf(catalogue['melee_knife']), 0);
      expect(staggerSecondsOf(catalogue['melee_spear']), 0);
    });

    test('gołe ręce też nie', () {
      expect(staggerSecondsOf(null), 0);
    });

    test('i typ obrażeń jest czytany z danych, nie zgadywany z nazwy', () {
      expect(DamageType.of(catalogue['melee_bat']), DamageType.blunt);
      expect(DamageType.of(catalogue['melee_axe']), DamageType.cutting);
      expect(DamageType.of(catalogue['melee_spike']), DamageType.piercing);
    });
  });

  group('§5.5.3: co oszołomienie robi ciału', () {
    test('oszołomiony stoi, zamiast iść', () {
      final hit = CombatSession(
        seed: 1,
        enemies: [walker()],
      ).staggered('w1', 1.5);

      final after = advanceEnemy(
        hit.enemies.single,
        playerAt: home.offsetBy(metres: 30, bearingDeg: 0),
        elapsed: const Duration(seconds: 1),
      );

      expect(after.isStaggered, isTrue);
      expect(after.position.distanceTo(home), lessThan(0.5));
    });

    test('i traci dwie sekundy biegu za każdą sekundę stania', () {
      // §6.1: bez tego obuch byłby przerwą, a nie ceną.
      final before = walker();
      final hit = CombatSession(
        seed: 1,
        enemies: [before],
      ).staggered('w1', 1.5);

      expect(
        hit.enemies.single.budget,
        before.budget - const Duration(seconds: 3),
      );
    });

    test('a kiedy minie, rusza dalej', () {
      final hit = CombatSession(
        seed: 1,
        enemies: [walker()],
      ).staggered('w1', 0.5);

      var enemy = hit.enemies.single;
      for (var tick = 0; tick < 3; tick++) {
        enemy = advanceEnemy(
          enemy,
          playerAt: home.offsetBy(metres: 30, bearingDeg: 0),
          elapsed: const Duration(seconds: 1),
        );
      }

      expect(enemy.isStaggered, isFalse);
      expect(enemy.position.distanceTo(home), greaterThan(0.5));
    });

    test('Brutala obuch bierze o połowę słabiej', () {
      // ⚠️ Ta sama zasada, dla której nie da się go uciszyć od tyłu (§5.5.1).
      // Elita ma zostać elitą przy każdym kanale, nie tylko przy jednym.
      final brute = CombatSession(
        seed: 1,
        enemies: [walker(kind: EnemyKind.brute)],
      ).staggered('w1', 2);

      expect(brute.enemies.single.staggerLeft, const Duration(seconds: 1));
    });

    test('a trupa się nie oszałamia', () {
      final dead = walker().hit(9999);
      final after = CombatSession(
        seed: 1,
        enemies: [dead],
      ).staggered(dead.id, 2);

      expect(after.enemies.single.isStaggered, isFalse);
    });
  });

  group('§5.5.3: zasięg pomaga w pojedynkę i zawadza w tłoku', () {
    test('włócznia trzyma na dystans, kiedy jest jeden', () {
      expect(reachEdge(reachM: 1.8, crowd: 1), greaterThan(0));
    });

    test('i jest kijem, kiedy stoją dookoła', () {
      // ⚠️ Bez tego włócznia byłaby po prostu lepsza, a to nie jest decyzja.
      expect(reachEdge(reachM: 1.8, crowd: 3), lessThan(0));
    });

    test('nóż nie ma czym trzymać na dystans ani czym zawadzać', () {
      // Krótka broń traci w pojedynkę i **odzyskuje** to w tłoku: jej przewaga
      // jest tłokiem.
      expect(reachEdge(reachM: 0.4, crowd: 1), lessThan(0));
      expect(reachEdge(reachM: 0.4, crowd: 3), greaterThan(0));
    });

    test('a pałka jest miarą zera', () {
      expect(reachEdge(reachM: kReachBaselineM, crowd: 1), 0);
      expect(reachEdge(reachM: kReachBaselineM, crowd: 4), 0);
    });

    test('i nic nie przesuwa szansy o więcej niż piętnaście punktów', () {
      for (final crowd in [1, 5]) {
        for (final reach in [0.1, 0.9, 3.0]) {
          expect(reachEdge(reachM: reach, crowd: crowd).abs(), lessThan(0.16));
        }
      }
    });
  });

  test('§5.5.3: i zamach naprawdę oba kanały wypuszcza', () {
    final blow = meleeOutcome(
      target: walker(),
      // Z przodu: to jest walka, nie podejście.
      at: home.offsetBy(metres: 2, bearingDeg: 0),
      blade: catalogue['melee_shovel'],
      chance: 1,
      random: Random(1),
    );

    expect(blow.staggerSeconds, 1.9);
    expect(blow.bloodMl, greaterThan(0));
  });

  test('§5.5.3: chybiony obuch nikogo nie przewraca', () {
    // Kij minięty obok niczego nie przewraca — oszołomienie jest skutkiem
    // trafienia, nie zamachu.
    final blow = meleeOutcome(
      target: walker(),
      at: home.offsetBy(metres: 2, bearingDeg: 0),
      blade: catalogue['melee_shovel'],
      chance: 0,
      random: Random(1),
    );

    expect(blow.bloodMl, 0);
    expect(blow.staggerSeconds, 0);
  });

  test('§5.5.3: i gra naprawdę o to pyta', () {
    // ⚠️ Test źródłowy: `damage_type` i `reach_m` były poprawne, kompletne i
    // niewołane. To jest ta jedna rzecz, którą ten projekt łapie raz po raz.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('_combat.staggered('), isTrue);
    expect(
      main.contains('crowd: _combat.near(here).length'),
      isTrue,
      reason: 'zasięg bez tłoku jest przewagą bez ceny',
    );
  });
}
