import 'dart:io';

import 'package:arls_za/combat/awareness.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/loot/search.dart';
import 'package:test/test.dart';

/// STRONY W BIEGU NIE CZYTA NIKT (§4.6.1, §4.7, §2.1a.3).
///
/// ⚠️ **Lektura tykała tak samo w fotelu, jak w sprincie.** Strona jest
/// czynnością „użycia" (§4.7), a te celowo nie wymagają bezruchu — kanapkę da
/// się zjeść w marszu i tak ma zostać. Tyle że ta sama reguła przepuszczała
/// czterdzieści stron przeczytanych podczas ucieczki przed Brutalem.
///
/// Rozwiązanie jest progiem, nie wyjątkiem: czynność może nieść prędkość,
/// powyżej której się urywa. Lektura ma sześć i cztery dziesiąte (§2.2's
/// trucht), reszta §4.7 nie ma żadnej.
void main() {
  const here = GeoPoint(52.4064, 16.9252);
  final now = DateTime.utc(2026, 8, 30, 12);

  Search page() => Search.using(
    at: here,
    now: now,
    itemId: 'book_first_aid',
    duration: const Duration(seconds: 76),
    label: 'strona',
    ruinedAboveKmh: kRunningKmh,
  );

  Search sandwich() => Search.using(
    at: here,
    now: now,
    itemId: 'food_canned_meat',
    duration: const Duration(seconds: 75),
    label: 'jedzenie',
  );

  group('§4.6.1: bieg urywa stronę', () {
    test('a marsz jej nie rusza', () {
      // §4.7: książkę czyta się w marszu — to jest ta sama zgoda, którą ma
      // kanapka, i nie o nią tu chodzi. 4,5 km/h to swobodny marsz.
      final after = page().advance(
        const Duration(seconds: 10),
        at: here,
        speedKmh: 4.5,
      );

      expect(after.isRunning, isTrue);
    });

    test('a bieg tak', () {
      final after = page().advance(
        const Duration(seconds: 10),
        at: here,
        speedKmh: kRunningKmh,
      );

      expect(after.isRunning, isFalse);
      expect(after.state, SearchState.cancelledByMovement);
    });

    test('i próg jest progiem, nie „ponad"', () {
      // ⚠️ 7,2 km/h to prędkość przejścia chód→bieg (§2.2) i **jedyna** taka
      // liczba w grze. Przez jakiś czas były dwie — 6,4 przy hałasie i 8 przy
      // rękach — więc między nimi gracz był jednocześnie biegnącym i nie.
      expect(
        page()
            .advance(const Duration(seconds: 5), at: here, speedKmh: 7.19)
            .isRunning,
        isTrue,
      );
      expect(
        page()
            .advance(const Duration(seconds: 5), at: here, speedKmh: 7.2)
            .isRunning,
        isFalse,
      );
    });
  });

  group('§4.7: i nic poza lekturą tego nie dostaje', () {
    test('kanapkę je się w biegu', () {
      // ⚠️ Jedzenie i opatrunek są marszem **spowalniane**, nie przerywane —
      // kiedyś były przerywane i jeden krok wyrzucał cały posiłek.
      final after = sandwich().advance(
        const Duration(seconds: 10),
        at: here,
        speedKmh: 12,
      );

      expect(after.isRunning, isTrue);
    });

    test('a przeszukanie ma swoją własną regułę, bezruchu', () {
      // Nie prędkość, tylko odległość od kotwicy: pół sklepu przewrócone zza
      // ulicy nie jest wolniejszym przeszukaniem, tylko żadnym.
      var search = Search.object(
        at: here,
        now: now,
        poiId: 'p',
        depth: SearchDepth.shallow,
      );
      for (var strike = 0; strike < kStillnessStrikes; strike++) {
        search = search.advance(
          const Duration(seconds: 1),
          at: here.offsetBy(metres: 400, bearingDeg: 0),
          speedKmh: 0,
        );
      }

      expect(search.state, SearchState.cancelledByMovement);
    });
  });

  test('§4.6.1: i lektura naprawdę ten próg dostaje', () {
    // ⚠️ Test źródłowy: pole może być poprawne i nieustawiane przez nikogo —
    // czternaście razy w tym projekcie tak właśnie było.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('ruinedAboveKmh: kRunningKmh'), isTrue);
    expect(
      main.contains('speedKmh: snapshot?.speedKmh'),
      isTrue,
      reason: 'próg bez prędkości jest progiem, o który nikt nie pyta',
    );
  });
}
