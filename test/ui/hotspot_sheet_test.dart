import 'dart:io';

import 'package:arls_za/combat/hotspot.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/l10n/app_localizations_pl.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/hotspot_sheet.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// OGNISKO MÓWI, CZYM JEST (§6.5.6, §12).
///
/// ⚠️ **A red ring was a warning nobody could ask a question of.** It said the
/// ground was hostile and nothing else: not how hostile, not how many were in
/// there, and above all not what to do about it — while §6.5.4's answer is a
/// procedure, and a procedure nobody has been told is a wall.
void main() {
  const centre = GeoPoint(52.4084, 16.9342);
  final t0 = DateTime.utc(2026, 8, 24, 20);

  GeoPoint north(double metres) =>
      GeoPoint(centre.latitude + metres / metresPerDegreeLat, centre.longitude);

  Hotspot at(int level) => Hotspot(
    id: '1.0',
    seed: 7,
    centre: centre,
    level: level,
    integrity: integrityMaxAt(level).toDouble(),
    bornAt: t0,
    nextLevelAt: t0.add(const Duration(hours: 8)),
  );

  Future<void> open(WidgetTester tester, Hotspot spot, {double? distanceM}) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pl'),
          localizationsDelegates: const [
            L10n.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: HotspotSheet(
              spot: spot,
              now: t0,
              distanceM: distanceM ?? spot.radiusM + 300,
            ),
          ),
        ),
      );

  testWidgets('it says which level it is, out of how many', (tester) async {
    await open(tester, at(4));

    expect(find.textContaining('4'), findsWidgets);
    expect(find.textContaining('${kHotspotLevels.length}'), findsWidgets);
  });

  testWidgets('and how many are in there at once', (tester) async {
    final spot = at(6);
    await open(tester, spot);

    expect(find.text('${spot.enemyCapAt(t0)}'), findsOneWidget);
  });

  testWidgets('standing in it says so, rather than nought metres', (
    tester,
  ) async {
    // ⚠️ "0 m" reads as an arrival. Being *inside* the circle is the one fact
    // on this sheet that changes what the player should do next.
    final spot = at(3);
    await open(tester, spot, distanceM: 20);

    expect(find.text(L10nPl().hotspotInside), findsOneWidget);
  });

  testWidgets('fury is said loudly while it lasts (§6.5.4)', (tester) async {
    final angry = at(5).demoted(at: t0, restFor: const Duration(hours: 24));
    await open(tester, angry);

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('and quietly not said when it does not', (tester) async {
    await open(tester, at(5));

    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
  });

  group('§6.5.6: the circle is the target, not the dot in the middle', () {
    MapMarker markerFor(Hotspot spot) => MapMarker(
      id: hotspotMarkerId(spot),
      kind: MarkerKind.hotspot,
      at: spot.centre,
      reachM: spot.radiusM,
    );

    test('a tap anywhere inside it opens the hotspot', () {
      // ⚠️ A hotspot is an area. Requiring the centre would make a level-ten
      // circle two hundred metres across a target the player has to walk into
      // the middle of to ask a question about.
      final spot = at(8);
      final metres = metresPerPixel(16, centre.latitude);

      final found = markerAtOffset(
        [markerFor(spot)],
        Offset(0, -(spot.radiusM * 0.8) / metres),
        centre: centre,
        zoom: 16,
      );

      expect(found?.id, hotspotMarkerId(spot));
    });

    test('and outside it, nothing', () {
      final spot = at(8);
      final metres = metresPerPixel(16, centre.latitude);

      final found = markerAtOffset(
        [markerFor(spot)],
        Offset(0, -(spot.radiusM + 200) / metres),
        centre: centre,
        zoom: 16,
      );

      expect(found, isNull);
    });

    test('but anything standing in the circle still wins the tap', () {
      // The fallback is checked last, deliberately: a body or a pile inside a
      // hotspot is a thing the player wants to open, and the circle is the
      // ground it is lying on.
      final spot = at(8);
      final loot = MapMarker(
        id: 'pile',
        kind: MarkerKind.loot,
        at: north(spot.radiusM * 0.5),
      );

      final found = markerAtOffset(
        [markerFor(spot), loot],
        Offset(0, -(spot.radiusM * 0.5) / metresPerPixel(16, centre.latitude)),
        centre: centre,
        zoom: 16,
      );

      expect(found?.id, 'pile');
    });
  });

  test('§6.5.6: and the game actually opens it', () {
    // ⚠️ Source-level, because the sheet and the marker id could both be
    // perfect and the tap still fall through to nothing — which is the state
    // every hotspot on the map was in when stage 6 faza C landed.
    final main = File('lib/main.dart').readAsStringSync();
    final markers = File('lib/ui/map_markers.dart').readAsStringSync();

    expect(main.contains('showHotspotFor('), isTrue);
    expect(
      markers.contains('hotspotMarkerId('),
      isTrue,
      reason: 'the map and the tap would name the same hotspot differently',
    );
  });
}
