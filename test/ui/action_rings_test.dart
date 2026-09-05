import 'package:arls_za/loot/obstacle.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:test/test.dart';

/// §5.6.1, §10.2.2: co słychać i co widać, dopóki czynność trwa.
///
/// Strzał ma falę — jedno zdarzenie, półtorej sekundy, koniec. Wyważanie drzwi
/// jest **stanem**: dwanaście sekund, przez które sto pięćdziesiąt metrów ulicy
/// to słyszy, a gracz właśnie decyduje, czy ciągnąć dalej.
void main() {
  const here = GeoPoint(52.4064, 16.9252);
  final now = DateTime.utc(2026, 9, 5, 21);

  test('bez czynności nie ma żadnego okręgu', () {
    expect(ringsFor(search: null, sightM: 120), isEmpty);
  });

  test('wyważanie drzwi rysuje dokładnie tyle, ile niesie (§19.3)', () {
    final force = Barrier.door.force!;
    final search = Search.breach(at: here, now: now, poiId: 'p', breach: force);

    final rings = ringsFor(search: search, sightM: 120);

    expect(rings, hasLength(1));
    expect(rings.single.kind, ActionRingKind.noise);
    expect(
      rings.single.radiusM,
      force.noiseM,
      reason: 'okrąg pokazujący inną liczbę niż reguła uczy nieufności',
    );
    expect(force.noiseM, 200);
  });

  test('a wytrychy — dziesięć razy mniej, i to jest cała ta decyzja', () {
    final quiet = Barrier.door.quiet!;
    final rings = ringsFor(
      search: Search.breach(at: here, now: now, poiId: 'p', breach: quiet),
      sightM: 120,
    );

    expect(rings.single.radiusM, quiet.noiseM);
    expect(quiet.noiseM, 20);
  });

  test('rozpoznanie pokazuje zasięg wzroku, nie hałas (§10.2.2)', () {
    // Stanie i rozglądanie się nie niesie nic — i dlatego jest jedyną czynnością
    // z okręgiem w drugim kolorze.
    final rings = ringsFor(
      search: Search.area(at: here, now: now),
      sightM: 220,
    );

    expect(rings, hasLength(1));
    expect(rings.single.kind, ActionRingKind.sight);
    expect(rings.single.radiusM, 220);
  });

  test(
    'przeszukanie miejsca niesie osiemdziesiąt metrów i nic nie odsłania',
    () {
      final rings = ringsFor(
        search: Search.object(
          at: here,
          now: now,
          poiId: 'p',
          depth: SearchDepth.thorough,
        ),
        sightM: 220,
      );

      expect(rings, hasLength(1));
      expect(rings.single.kind, ActionRingKind.noise);
      expect(rings.single.radiusM, kSearchNoiseM);
    },
  );

  test('czynność skończona przestaje rysować cokolwiek', () {
    final done = Search.area(
      at: here,
      now: now,
    ).advance(const Duration(minutes: 5), at: here, speedKmh: 0);

    expect(done.isRunning, isFalse);
    expect(ringsFor(search: done, sightM: 220), isEmpty);
  });

  group('oddech, nie miganie', () {
    final ring = ActionRing(
      radiusM: 150,
      kind: ActionRingKind.noise,
      startedAt: now,
    );

    test('idzie w górę i wraca w tym samym rytmie', () {
      expect(ring.breathAt(now), closeTo(0, 0.01));
      expect(ring.breathAt(now.add(ActionRing.pulse ~/ 2)), closeTo(1, 0.01));
      expect(ring.breathAt(now.add(ActionRing.pulse)), closeTo(0, 0.01));
    });

    test('i promień się przy tym nie rusza', () {
      // ⚠️ Rosnący okrąg czyta się jako fala, która się rozchodzi. Cała rzecz
      // w tym, że ta czynność **trwa** — zmienia się krycie, nie zasięg.
      expect(ring.radiusM, 150);
    });
  });
}
