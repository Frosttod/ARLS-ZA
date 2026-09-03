import 'dart:math' as math;

import 'package:arls_za/location/fix_filter.dart';
import 'package:arls_za/combat/awareness.dart' show kRunningKmh;
import 'package:arls_za/location/position_fix.dart';
import 'package:test/test.dart';

/// §3.2, written as a test.
///
/// The whole filter answers one question: did the person move, or did only the
/// number move? Both wrong answers cost the player something real — credited
/// scatter burns calories that were never spent, and swallowed slow walking
/// means an hour of carrying a heavy pack counts for nothing.
void main() {
  final t0 = DateTime.utc(2026, 8, 11, 12);
  const origin = PositionFix2(52.2297, 21.0122);

  PositionFix fixAt({
    required int seconds,
    double north = 0,
    double east = 0,
    double accuracyM = 6,
    bool mocked = false,
  }) {
    final base = PositionFix(
      latitude: origin.lat,
      longitude: origin.lon,
      accuracyM: accuracyM,
      timestamp: t0.add(Duration(seconds: seconds)),
      isMocked: mocked,
    );
    if (north == 0 && east == 0) return base;

    final metres = math.sqrt(north * north + east * east);
    final bearing = math.atan2(east, north) * 180 / math.pi;
    return base
        .offset(metres: metres, bearingDeg: bearing)
        .copyWith(
          timestamp: base.timestamp,
          accuracyM: accuracyM,
          isMocked: mocked,
        );
  }

  group('what gets thrown away', () {
    test('a fix worse than the 25 m gate is dropped, not smoothed', () {
      final filter = FixFilter();
      final outcome = filter.accept(fixAt(seconds: 0, accuracyM: 40));

      expect(outcome, isA<FixDropped>());
      expect((outcome as FixDropped).reason, FixRejection.accuracy);
      expect(
        filter.estimate,
        isNull,
        reason: 'a rejected fix must not move the estimate',
      );
    });

    test('a mocked fix is dropped before anything else looks at it', () {
      final outcome = FixFilter().accept(fixAt(seconds: 0, mocked: true));

      expect((outcome as FixDropped).reason, FixRejection.mocked);
    });

    test('a fix that is not newer than the last one is dropped', () {
      final filter = FixFilter();
      filter.accept(fixAt(seconds: 10));

      expect(
        (filter.accept(fixAt(seconds: 10)) as FixDropped).reason,
        FixRejection.outOfOrder,
        reason: 'a zero interval would divide by zero on the way to a speed',
      );
    });
  });

  group('a phone standing still', () {
    /// Scatter that goes nowhere: points drawn uniformly inside a circle around
    /// one spot, seeded so the test is deterministic. Every step it takes it
    /// also takes back, which is what separates it from walking.
    List<PositionFix> scatter({
      required int count,
      required int seed,
      double radiusM = 4,
    }) {
      final random = math.Random(seed);
      return List.generate(count, (i) {
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = radiusM * math.sqrt(random.nextDouble());
        return fixAt(
          seconds: i * 5,
          north: distance * math.cos(angle),
          east: distance * math.sin(angle),
        );
      });
    }

    double creditOver(List<PositionFix> fixes) {
      final filter = FixFilter();
      var credited = 0.0;
      for (final fix in fixes) {
        final outcome = filter.accept(fix);
        if (outcome is FixAccepted) credited += outcome.movedM;
      }
      return credited;
    }

    test('leaks under a metre per ten minutes, whatever the noise does', () {
      // One seed proves nothing about a filter that judges the shape of noise,
      // so this walks twelve different ten-minute sequences. Scatter credited
      // as movement is calories nobody spent — over a night in a shelter a
      // leaky filter is worth several kilometres.
      for (var seed = 1; seed <= 12; seed++) {
        final credited = creditOver(scatter(count: 120, seed: seed));
        expect(credited, lessThan(1.0), reason: 'seed $seed');
      }
    });

    test('reports itself as stationary, so §2.2 sees MET 1.0', () {
      final filter = FixFilter();
      late FixAccepted last;

      for (final fix in scatter(count: 20, seed: 3)) {
        final outcome = filter.accept(fix);
        if (outcome is FixAccepted) last = outcome;
      }

      expect(last.stationary, isTrue);
      expect(last.speedMps, 0);
    });
  });

  group('a phone on a worktop, indoors (§3.2)', () {
    // Found at a kitchen table: indoors the receiver reports fifteen to
    // twenty-five metres of accuracy and wanders about that much, which
    // cleared the fixed eight-metre gate. A sitting player was charged for a
    // walk — heart rate, water and calories, all for a phone on a worktop.
    test('scatter the size of the error bar is not movement', () {
      final filter = FixFilter();
      var moved = 0.0;

      for (var i = 0; i < 12; i++) {
        final outcome = filter.accept(
          fixAt(
            seconds: i * 5,
            north: i.isEven ? 9 : -9,
            east: i % 3 == 0 ? 8 : -7,
            accuracyM: 18,
          ),
        );
        if (outcome is FixAccepted) moved += outcome.movedM;
      }

      expect(moved, 0);
    });

    test('and the same scatter on a clear sky is', () {
      // Six metres of accuracy and nine of movement is somebody moving.
      final filter = FixFilter();
      var moved = 0.0;

      for (var i = 0; i < 12; i++) {
        final outcome = filter.accept(
          fixAt(
            seconds: i * 5,
            north: i.isEven ? 9 : -9,
            east: i % 3 == 0 ? 8 : -7,
            accuracyM: 6,
          ),
        );
        if (outcome is FixAccepted) moved += outcome.movedM;
      }

      expect(moved, greaterThan(0));
    });

    test('a real walk still counts through a poor fix', () {
      // The gate rises with the uncertainty; it does not close. Sixty metres
      // in a straight line is a walk whatever the receiver thinks of itself.
      final filter = FixFilter();
      var moved = 0.0;

      for (var i = 0; i < 8; i++) {
        final outcome = filter.accept(
          fixAt(seconds: i * 10, north: i * 20.0, accuracyM: 20),
        );
        if (outcome is FixAccepted) moved += outcome.movedM;
      }

      // Smoothing keeps some of it back on the way up to speed; what matters
      // is that a walk through a poor fix is still a walk.
      expect(moved, greaterThan(60));
    });
  });

  group('a person actually walking', () {
    /// A straight line at [speedMps], sampled every five seconds, with the same
    /// scatter on top that the stationary fixtures use. A noiseless walk would
    /// flatter the filter.
    List<PositionFix> walk({
      required int count,
      required double speedMps,
      int seed = 7,
      double noiseM = 3,
      double accuracyM = 6,
    }) {
      final random = math.Random(seed);
      return List.generate(count, (i) {
        final seconds = i * 5;
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = noiseM * math.sqrt(random.nextDouble());
        return fixAt(
          seconds: seconds,
          north: speedMps * seconds + distance * math.cos(angle),
          east: distance * math.sin(angle),
          accuracyM: accuracyM,
        );
      });
    }

    double creditOver(List<PositionFix> fixes) {
      final filter = FixFilter();
      var credited = 0.0;
      for (final fix in fixes) {
        final outcome = filter.accept(fix);
        if (outcome is FixAccepted) credited += outcome.movedM;
      }
      return credited;
    }

    test('a normal walk loses only the warm-up, not a share of the walk', () {
      // Ten minutes at 1.4 m/s is 840 m. The filter spends its first seven
      // fixes deciding whether this is a walk at all, which costs about 40 m
      // once per session — a fixed price, not a percentage.
      final credited = creditOver(walk(count: 121, speedMps: 1.4));

      expect(credited, greaterThan(780));
      expect(
        credited,
        lessThan(900),
        reason: 'noise must not be credited as extra distance either',
      );
    });

    test('half a metre a second still counts (§2.2 has a band for it)', () {
      // 60 m of real walking, no ten seconds of which covers the 8 m dead
      // zone. A filter that judged distance alone would swallow all of it.
      for (var seed = 1; seed <= 12; seed++) {
        final credited = creditOver(walk(count: 25, speedMps: 0.5, seed: seed));
        expect(
          credited,
          greaterThan(40),
          reason: 'seed $seed: a slow walk under load is movement, not drift',
        );
      }
    });

    test('speed comes out near the truth once the filter has warmed up', () {
      final filter = FixFilter();
      final speeds = <double>[];

      for (final fix in walk(count: 60, speedMps: 1.4)) {
        final outcome = filter.accept(fix);
        if (outcome is FixAccepted && !outcome.stationary) {
          speeds.add(outcome.speedMps);
        }
      }

      final settled = speeds.skip(speeds.length ~/ 2).toList();
      final mean = settled.reduce((a, b) => a + b) / settled.length;
      expect(mean, closeTo(1.4, 0.2));
    });
  });

  test('smoothing pulls a single wild fix back towards the estimate', () {
    final filter = FixFilter();
    for (var i = 0; i < 6; i++) {
      filter.accept(fixAt(seconds: i * 5));
    }

    // One fix 20 m off, still inside the accuracy gate.
    final outcome =
        filter.accept(fixAt(seconds: 30, north: 20, accuracyM: 20))
            as FixAccepted;

    final offBy = outcome.fix.distanceTo(
      PositionFix(
        latitude: origin.lat,
        longitude: origin.lon,
        accuracyM: 6,
        timestamp: t0,
      ),
    );
    expect(
      offBy,
      lessThan(20),
      reason: 'the estimate should not jump the whole way to a poor fix',
    );
  });

  group('§5.6.1: prędkość jest uśredniona, nie jednym odczytem', () {
    /// Rześki marsz — 6 km/h, próbkowany co pięć sekund, tak jak kadencja
    /// „moving" naprawdę odpytuje.
    List<PositionFix> briskWalk({int count = 13, double accuracyM = 8}) {
      const speedMps = 6 / 3.6;
      return List.generate(
        count,
        (i) => fixAt(
          seconds: i * 5,
          north: speedMps * (i * 5),
          accuracyM: accuracyM,
        ),
      );
    }

    test(
      'zgłoszenie z terenu: stałe tempo, jeden odczyt kłamie o dokładności — '
      'bez skoku w bieg',
      () {
        // ⚠️ To jest dokładnie to zgłoszenie: „idę stałym tempem, licznik
        // hałasu pokazuje 40 m". Winny nie jest zwykły szum w granicach
        // zgłaszanej dokładności — sprawdzone osobno, że taki nie przepycha
        // marszu przez próg. Winny jest odczyt, który **kłamie o własnej
        // dokładności**: zgłasza osiem metrów, mając naprawdę dwadzieścia
        // pięć — dokładnie to, co robi odbiornik, kiedy traci wielotorowość
        // pod drzewami na chwilę i dogania własną ocenę błędu odczyt później.
        final filter = FixFilter();
        final fixes = briskWalk();
        fixes[9] = fixAt(
          seconds: 9 * 5,
          north: (6 / 3.6) * 9 * 5 + 25,
          accuracyM: 8, // zgłoszona dokładność, nie prawdziwy błąd
        );

        FixAccepted? bad;
        for (var i = 0; i < fixes.length; i++) {
          final outcome = filter.accept(fixes[i]);
          // Ten jeden odczyt, na którym wyszła kłamliwa dokładność — dalsze są
          // już powrotem do prawdy i nie mają nic do udowodnienia.
          if (i == 9 && outcome is FixAccepted) bad = outcome;
        }

        final unsmoothedKmh = bad!.movedM / bad.interval.inSeconds * 3.6;
        final smoothedKmh = bad.speedMps * 3.6;

        // Nieuśredniona różnica dwóch punktów naprawdę przekraczałaby próg
        // biegu — dowód, że test odtwarza usterkę, a nie coś innego.
        expect(unsmoothedKmh, greaterThan(kRunningKmh));

        // A uśredniona zostaje pod progiem: rześki marsz nie pokazuje biegu.
        expect(smoothedKmh, lessThan(kRunningKmh));
      },
    );

    test('a zwykły szum w granicach zgłaszanej dokładności nic nie robi', () {
      // ⚠️ Rozróżnienie, które uzasadnia całą diagnozę: odczyt uczciwie
      // zgłaszający swój błąd — nawet spory, nawet przesunięty wzdłuż trasy —
      // nie przepycha marszu przez próg biegu. Filtr pozycji sam sobie z tym
      // radzi; problemem jest wyłącznie odczyt, który kłamie.
      final filter = FixFilter();
      final fixes = briskWalk(accuracyM: 20);
      fixes[9] = fixAt(
        seconds: 9 * 5,
        north: (6 / 3.6) * 9 * 5 + 15,
        accuracyM: 20,
      );

      for (final fix in fixes) {
        final outcome = filter.accept(fix);
        if (outcome is FixAccepted && !outcome.stationary) {
          expect(outcome.speedMps * 3.6, lessThan(kRunningKmh));
        }
      }
    });

    test(
      'a prawdziwa zmiana tempa dochodzi w kilkanaście sekund, nie ginie',
      () {
        // ⚠️ Uśrednianie nie ma prawa schować prawdziwego biegu na stałe —
        // sprawdzone osobno, żeby poprawka jednego zgłoszenia nie stworzyła
        // drugiego („uciekam, a gra tego nie widzi").
        final filter = FixFilter();
        const walkMps = 5 / 3.6;
        const runMps = 12 / 3.6;

        FixAccepted? last;
        var seconds = 0;
        for (var i = 0; i < 7; i++) {
          seconds += 5;
          last =
              filter.accept(fixAt(seconds: seconds, north: walkMps * seconds))
                  as FixAccepted;
        }
        final before = last!.speedMps * 3.6;

        var distance = walkMps * seconds;
        for (var i = 0; i < 4; i++) {
          seconds += 5;
          distance += runMps * 5;
          last =
              filter.accept(fixAt(seconds: seconds, north: distance))
                  as FixAccepted;
        }

        expect(before, lessThan(kRunningKmh));
        expect(
          last!.speedMps * 3.6,
          greaterThan(kRunningKmh),
          reason: 'cztery odczyty biegu (dwadzieścia sekund) muszą wystarczyć',
        );
      },
    );

    test(
      'zwolnienie po biegu przechodzi od razu, tłumione są tylko wzrosty',
      () {
        // ⚠️ Test źródłowy dla poprawki poprawki: symetryczne tłumienie
        // dokładało spowolnienie do spowolnienia filtra pozycji i cofnięcie
        // kadencji próbkowania (§3.3) po zatrzymaniu przestawało mieścić się
        // w oknie, w którym dotąd się mieściło. Zejście w dół ma przechodzić
        // przez uśredniacz od razu, tak jak przechodziłoby bez niego.
        final filter = FixFilter();
        const runMps = 12 / 3.6;

        var seconds = 0;
        for (var i = 0; i < 7; i++) {
          seconds += 5;
          filter.accept(fixAt(seconds: seconds, north: runMps * seconds));
        }
        final frozenAt = runMps * seconds;

        // Sama pierwsza klatka po zatrzymaniu — jeszcze zanim `stationary`
        // zdąży się przełączyć — ma już wolniej, nie tyle samo co przed chwilą.
        seconds += 5;
        final firstAfterStop =
            filter.accept(fixAt(seconds: seconds, north: frozenAt))
                as FixAccepted;

        expect(
          firstAfterStop.speedMps,
          lessThan(runMps * 0.9),
          reason: 'zwolnienie nie czeka na uśrednianie, tylko przechodzi',
        );
      },
    );

    test(
      'po przerwie (§11.2) pierwszy odczyt nie dziedziczy starej prędkości',
      () {
        // ⚠️ Uśredniacz jest zerowany przy [FixFilter.reset] razem z resztą
        // stanu — inaczej pierwszy krok po wznowieniu sesji byłby liczony
        // razem z prędkością sprzed przerwy i przez chwilę kłamałby w tę albo
        // w drugą stronę, zależnie od tego, kto biegł, zanim gra zgasła.
        final filter = FixFilter();
        const runMps = 12 / 3.6;

        var seconds = 0;
        for (var i = 0; i < 7; i++) {
          seconds += 5;
          filter.accept(fixAt(seconds: seconds, north: runMps * seconds));
        }

        filter.reset();

        // Nowa sesja, nowe tempo — marsz, od zera, w zupełnie innym miejscu.
        const walkMps = 5 / 3.6;
        var seconds2 = 100;
        FixAccepted? last;
        for (var i = 0; i < 7; i++) {
          seconds2 += 5;
          last =
              filter.accept(
                    fixAt(seconds: seconds2, north: walkMps * (seconds2 - 100)),
                  )
                  as FixAccepted;
        }

        expect(
          last!.speedMps * 3.6,
          lessThan(kRunningKmh),
          reason: 'nie zostaje podbite biegiem sprzed przerwy',
        );
      },
    );
  });

  test('reset forgets the estimate across a pause', () {
    final filter = FixFilter();
    filter.accept(fixAt(seconds: 0));
    filter.reset();

    expect(filter.estimate, isNull);
    expect(
      filter.accept(fixAt(seconds: 0)),
      isA<FixAccepted>(),
      reason: 'after a reset the old timestamp is no longer out of order',
    );
  });
}

/// A latitude and longitude, so the fixtures read as coordinates rather than as
/// two loose doubles.
class PositionFix2 {
  const PositionFix2(this.lat, this.lon);
  final double lat;
  final double lon;
}
