import 'package:arls_za/devtools/gpx.dart';
import 'package:test/test.dart';

const _sample = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="test">
  <trk>
    <name>Spacer po Naramowicach</name>
    <trkseg>
      <trkpt lat="52.40640" lon="16.92520">
        <ele>85.2</ele>
        <time>2026-08-10T10:00:00Z</time>
      </trkpt>
      <trkpt lat="52.40820" lon="16.92520">
        <ele>85.6</ele>
        <time>2026-08-10T10:02:30Z</time>
      </trkpt>
      <trkpt lat="52.40820" lon="16.92900"/>
    </trkseg>
  </trk>
</gpx>
''';

void main() {
  group('parseGpx', () {
    test('reads points, name, elevation and time', () {
      final track = parseGpx(_sample);

      expect(track.name, 'Spacer po Naramowicach');
      expect(track.points, hasLength(3));
      expect(track.points.first.latitude, closeTo(52.4064, 1e-9));
      expect(track.points.first.elevationM, 85.2);
      expect(track.points.first.time, DateTime.utc(2026, 8, 10, 10));
      expect(
        track.points.last.time,
        isNull,
        reason: 'self-closing trkpt has no children',
      );
    });

    test('computes track length', () {
      final track = parseGpx(_sample);

      // 0.0018° of latitude ≈ 199 m, then 0.0038° of longitude at 52.4°N
      // ≈ 258 m.
      expect(track.lengthM, closeTo(457, 5));
    });

    test('rejects a document with too few points', () {
      expect(
        () => parseGpx('<gpx><trkpt lat="1" lon="2"/></gpx>'),
        throwsA(isA<GpxParseException>()),
      );
      expect(() => parseGpx('nonsense'), throwsA(isA<GpxParseException>()));
    });

    test('rejects out-of-range coordinates', () {
      expect(
        () => parseGpx(
          '<gpx><trkpt lat="91" lon="0"/><trkpt lat="0" lon="0"/></gpx>',
        ),
        throwsA(isA<GpxParseException>()),
      );
    });

    test('falls back to a name when the document has none', () {
      final track = parseGpx(
        '<gpx><trkpt lat="52.0" lon="16.0"/><trkpt lat="52.001" lon="16.0"/></gpx>',
        fallbackName: 'bez nazwy',
      );

      expect(track.name, 'bez nazwy');
    });
  });

  group('pointAt', () {
    test('start and end land on the endpoints', () {
      final track = parseGpx(_sample);

      final start = track.pointAt(0);
      expect(start.latitude, closeTo(track.points.first.latitude, 1e-9));

      final end = track.pointAt(track.lengthM, loop: false);
      expect(end.latitude, closeTo(track.points.last.latitude, 1e-6));
      expect(end.longitude, closeTo(track.points.last.longitude, 1e-6));
    });

    test('interpolates inside a segment', () {
      final track = parseGpx(_sample);
      final firstLegM = 199.0;

      final mid = track.pointAt(firstLegM / 2);

      expect(mid.latitude, closeTo((52.40640 + 52.40820) / 2, 1e-4));
      expect(mid.bearingDeg, closeTo(0, 1), reason: 'first leg runs north');
    });

    test('wraps so a simulated walk can run indefinitely', () {
      final track = parseGpx(_sample);

      final once = track.pointAt(50);
      final looped = track.pointAt(50 + track.lengthM);

      expect(looped.latitude, closeTo(once.latitude, 1e-9));
      expect(looped.longitude, closeTo(once.longitude, 1e-9));
    });

    test('clamps instead of wrapping when asked', () {
      final track = parseGpx(_sample);

      final past = track.pointAt(track.lengthM * 3, loop: false);

      expect(past.latitude, closeTo(track.points.last.latitude, 1e-6));
    });

    test('durationAt matches length over speed', () {
      final track = parseGpx(_sample);

      // Walking pace from §2.2, 4.8 km/h.
      final duration = track.durationAt(1.3);

      expect(duration.inSeconds, closeTo(track.lengthM / 1.3, 1));
      expect(track.durationAt(0), Duration.zero);
    });
  });

  test('the built-in loop is usable without any file', () {
    final track = defaultTestLoop();

    expect(track.points.length, greaterThanOrEqualTo(4));
    expect(track.lengthM, greaterThan(500));
    expect(
      track.pointAt(0).latitude,
      closeTo(track.pointAt(track.lengthM).latitude, 1e-6),
      reason: 'the loop closes',
    );
  });
}
