import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/enemy_spawner.dart';
import 'package:arls_za/combat/hotspot.dart' show kNightCrowdShare;
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/marker_motion.dart';
import 'package:test/test.dart';

/// NOC, HAŁAS I PŁYNNOŚĆ (§17.4, §5.6.1, §3.3).
///
/// Trzy zgłoszenia z jednego spaceru: po zmroku ma być ich więcej, własny hałas
/// ma być widoczny, a ruch przeciwnika blisko gracza ma być płynny.
void main() {
  const here = GeoPoint(52.4064, 16.9252);

  group('§17.4: po zmroku ulica jest gęstsza', () {
    int capacityAt(double darkness) => SpawnOrigin.ambient(
      centre: here,
      radiusM: 600,
      darkness: darkness,
    ).capacity;

    test('w dzień tyle, ile mówi §6.4', () {
      // Dwa na kilometr kwadratowy, na kole o promieniu sześciuset metrów.
      expect(capacityAt(0), (pi * 600 * 600 / 1e6 * 2).floor());
    });

    test('a w nocy o połowę więcej', () {
      // ⚠️ **Strefy Rozkładu miały to od początku, a strużka §6.4 nie.** Noc
      // dokładała przeciwników wyłącznie tam, gdzie i tak było ich najwięcej.
      expect(
        capacityAt(1),
        (pi * 600 * 600 / 1e6 * 2 * (1 + kNightCrowdShare)).floor(),
      );
      expect(capacityAt(1), greaterThan(capacityAt(0)));
    });

    test('i to jest ta sama noc, którą liczą strefy', () {
      // Jedna stała na jedną noc: gdyby były dwie, zmierzch znaczyłby co innego
      // na ulicy i co innego w strefie. Na większym kole widać to bez zaokrągleń
      // — przy sześciuset metrach cała strużka to dwie sztuki i pół zmierzchu
      // gubi się w podłodze.
      int wide(double darkness) => SpawnOrigin.ambient(
        centre: here,
        radiusM: 2000,
        darkness: darkness,
      ).capacity;

      expect(wide(0.5), greaterThan(wide(0)));
      expect(wide(0.5), lessThan(wide(1)));
    });
  });

  test('§3.3: płynność do siedemdziesięciu pięciu metrów', () {
    // Tyle wynosi najdłuższy zasięg wzroku w grze (Skakun) — wewnątrz tego
    // kręgu wszystko, co widać, może już iść po gracza.
    expect(kSmoothWithinM, 75);

    // ⚠️ I to jest powyżej piętnastu klatek, o które prosiło zgłoszenie.
    expect(kMarkerFps, greaterThanOrEqualTo(15));
  });

  test('§5.6.1: i mapa naprawdę rysuje własny krok', () {
    // ⚠️ Test źródłowy: pasek mówi „hałas 15 m", a to jest liczba, której nie
    // da się użyć bez okręgu — piętnaście metrów wygląda inaczej przy każdym
    // zbliżeniu.
    final main = File('lib/main.dart').readAsStringSync();
    final surface = File('lib/ui/maplibre_surface.dart').readAsStringSync();

    expect(main.contains('footfallM: playerNoiseM('), isTrue);
    expect(surface.contains('_FootfallPainter('), isTrue);
    expect(
      surface.contains('_closeBy(centre)'),
      isTrue,
      reason:
          'poślizg markerów działa też przy słabej baterii, jeśli są blisko',
    );
  });
}
