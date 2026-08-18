import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:arls_za/ui/marker_motion.dart';
import 'package:test/test.dart';

/// PŁYNNY RUCH ZNACZNIKÓW (§3.6).
///
/// The tick is 1 Hz, so everything the map knows arrives in steps. Nothing is
/// wrong with the simulation — it is the drawing that reports it too
/// literally. These tests are about the glide that fixes that, and about the
/// two things it must never do: invent a journey for something that just
/// appeared, and snap backwards when a position changes mid-glide.
void main() {
  final t0 = DateTime.utc(2026, 8, 18, 12);

  const a = GeoPoint(52.4084, 16.9342);
  const b = GeoPoint(52.4094, 16.9342);

  List<MapMarker> at(GeoPoint where, {String id = 'walker.1'}) => [
    MapMarker(id: id, kind: MarkerKind.enemy, at: where),
  ];

  test('something newly seen is drawn where it is, not slid in', () {
    // A Walker coming into range has nowhere to come from. Gliding it in from
    // anywhere would be the map inventing a journey nobody took.
    final motion = MarkerMotion();
    motion.update(at(a), t0);

    expect(motion.positionAt('walker.1', t0), a);
    expect(motion.movingAt(t0), isFalse);
  });

  test('a reported move is spread across the tick', () {
    final motion = MarkerMotion();
    motion.update(at(a), t0);
    motion.update(at(b), t0);

    final half = motion.positionAt(
      'walker.1',
      t0.add(const Duration(milliseconds: 500)),
    )!;

    expect(
      half.latitude,
      closeTo((a.latitude + b.latitude) / 2, 1e-9),
      reason: 'half way at half a second',
    );
    expect(motion.movingAt(t0.add(const Duration(milliseconds: 500))), isTrue);
  });

  test('and has arrived by the time the next one is due', () {
    final motion = MarkerMotion();
    motion.update(at(a), t0);
    motion.update(at(b), t0);

    final arrived = t0.add(const Duration(seconds: 1));

    expect(motion.positionAt('walker.1', arrived), b);
    expect(
      motion.movingAt(arrived),
      isFalse,
      reason: 'a still street costs no frames',
    );
  });

  test('a move reported mid-glide carries on from where it is drawn', () {
    // ⚠️ The failure this guards: starting the new leg from the last
    // *reported* point snaps the marker backwards and sets off again, which
    // reads worse than no interpolation at all.
    final motion = MarkerMotion();
    motion.update(at(a), t0);
    motion.update(at(b), t0);

    final midway = t0.add(const Duration(milliseconds: 500));
    final drawnBefore = motion.positionAt('walker.1', midway)!;

    const c = GeoPoint(52.4104, 16.9342);
    motion.update(at(c), midway);

    final drawnAfter = motion.positionAt('walker.1', midway)!;

    expect(drawnAfter.latitude, closeTo(drawnBefore.latitude, 1e-9));
  });

  test('a marker that goes away stops being tracked', () {
    final motion = MarkerMotion();
    motion.update(at(a), t0);
    motion.update(const [], t0);

    expect(motion.positionAt('walker.1', t0), isNull);
  });

  test('a position that has not really changed starts no glide', () {
    // Floating-point noise on an unmoved marker would otherwise keep the whole
    // layer repainting over nothing.
    final motion = MarkerMotion();
    motion.update(at(a), t0);
    motion.update(
      at(GeoPoint(a.latitude + 1e-9, a.longitude), id: 'walker.1'),
      t0,
    );

    expect(motion.movingAt(t0.add(const Duration(milliseconds: 100))), isFalse);
  });

  test('two markers glide independently', () {
    final motion = MarkerMotion();
    motion.update([...at(a), ...at(a, id: 'walker.2')], t0);
    motion.update([...at(b), ...at(a, id: 'walker.2')], t0);

    final midway = t0.add(const Duration(milliseconds: 500));

    expect(motion.positionAt('walker.2', midway), a, reason: 'stood still');
    expect(
      motion.positionAt('walker.1', midway)!.latitude,
      greaterThan(a.latitude),
    );
  });
}
