import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/location/position_fix.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:arls_za/ui/map_view.dart';
import 'package:arls_za/ui/player_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// §3.6. The tile surface is a platform view and does not exist in a widget
/// test, so it is injected — which leaves exactly the parts that are this
/// screen's own responsibility: where the player is drawn, when the camera
/// stops following, the bottom menu, and the fact that nothing here is knowable
/// by colour alone (§12).
void main() {
  final fix = PositionFix(
    latitude: 52.4064,
    longitude: 16.9252,
    accuracyM: 6,
    timestamp: DateTime.utc(2026, 8, 12, 12),
  );

  /// Records what the screen asked the surface to draw.
  late List<({bool following, List<MapMarker> markers, bool economy})> asked;
  late void Function() panned;

  setUp(() {
    asked = [];
  });

  Widget surface(
    BuildContext context, {
    required PositionFix? centre,
    required List<MapMarker> markers,
    required bool following,
    required bool economy,
    required void Function() onUserPanned,
  }) {
    asked.add((following: following, markers: markers, economy: economy));
    panned = onUserPanned;
    return const ColoredBox(color: Color(0xFF0B0D0E));
  }

  Future<void> pumpMap(
    WidgetTester tester, {
    PositionFix? at,
    double? heading,
    List<MapMarker> markers = const [],
    bool hasPack = true,
    bool economy = false,
    void Function(MapMenuEntry)? onMenu,
    Locale locale = const Locale('pl'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: MapScreen(
          tileBuilder: surface,
          fix: at,
          headingDeg: heading,
          markers: markers,
          hasPack: hasPack,
          economy: economy,
          onMenu: onMenu,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the player', () {
    testWidgets('is drawn in the middle while the camera follows', (
      tester,
    ) async {
      await pumpMap(tester, at: fix, heading: 45);

      expect(find.byType(PlayerPin), findsOneWidget);

      final centre = tester.getCenter(find.byType(PlayerPin));
      final screen = tester.getCenter(find.byType(MapScreen));
      expect(centre.dx, closeTo(screen.dx, 1));
      expect(centre.dy, closeTo(screen.dy, 1));
    });

    testWidgets('is not drawn before the first fix', (tester) async {
      // The map still draws — a player waiting for a lock should see the
      // region, not a spinner.
      await pumpMap(tester);

      expect(find.byType(PlayerPin), findsNothing);
    });

    testWidgets('carries a label for the screen reader (§12)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMap(tester, at: fix, heading: 90);

      expect(find.bySemanticsLabel('Ty'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('has no cone while standing still', (tester) async {
      // A cone left pointing the last way travelled is a lie a player acts on.
      await pumpMap(tester, at: fix);

      final pin = tester.widget<PlayerPin>(find.byType(PlayerPin));
      expect(pin.headingDeg, isNull);
    });
  });

  group('following the player', () {
    testWidgets('starts on, and the recentre button is absent', (tester) async {
      await pumpMap(tester, at: fix);

      expect(asked.last.following, isTrue);
      expect(find.text('Wróć do siebie'), findsNothing);
    });

    testWidgets('a drag stops it and offers the way back', (tester) async {
      await pumpMap(tester, at: fix);

      panned();
      await tester.pumpAndSettle();

      expect(asked.last.following, isFalse);
      expect(
        find.text('Wróć do siebie'),
        findsOneWidget,
        reason: 'a map that snaps back cannot be read ahead of you',
      );
      expect(
        find.byType(PlayerPin),
        findsNothing,
        reason: 'once dragged, the middle of the screen is not where they are',
      );
    });

    testWidgets('the button turns it back on and takes itself away', (
      tester,
    ) async {
      await pumpMap(tester, at: fix);
      panned();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wróć do siebie'));
      await tester.pumpAndSettle();

      expect(asked.last.following, isTrue);
      expect(find.text('Wróć do siebie'), findsNothing);
      expect(find.byType(PlayerPin), findsOneWidget);
    });
  });

  group('the bottom menu (§3.6)', () {
    testWidgets('has the four entries §3.6 names, in order', (tester) async {
      await pumpMap(tester, at: fix);

      for (final label in ['PROFIL', 'EKWIPUNEK', 'SCHRON', 'USTAWIENIA']) {
        expect(find.text(label), findsOneWidget);
      }

      final xs = [
        for (final label in ['PROFIL', 'EKWIPUNEK', 'SCHRON', 'USTAWIENIA'])
          tester.getCenter(find.text(label)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('reports which entry was tapped', (tester) async {
      MapMenuEntry? chosen;
      await pumpMap(tester, at: fix, onMenu: (entry) => chosen = entry);

      await tester.tap(find.text('SCHRON'));
      await tester.pumpAndSettle();

      expect(chosen, MapMenuEntry.shelter);
    });
  });

  group('markers', () {
    const markers = [
      MapMarker(id: 'a', kind: MarkerKind.loot, at: GeoPoint(52.41, 16.93)),
      MapMarker(id: 'b', kind: MarkerKind.shelter, at: GeoPoint(52.40, 16.92)),
    ];

    testWidgets('are handed to the surface unchanged', (tester) async {
      await pumpMap(tester, at: fix, markers: markers);

      expect(asked.last.markers, hasLength(2));
      expect(asked.last.markers.first.id, 'a');
    });

    testWidgets('every kind has a word as well as a colour (§12)', (
      tester,
    ) async {
      await pumpMap(tester, at: fix);
      final l10n = L10n.of(tester.element(find.byType(MapScreen)));

      for (final kind in MarkerKind.values) {
        final label = markerLabel(
          l10n,
          MapMarker(id: 'x', kind: kind, at: const GeoPoint(0, 0)),
        );
        expect(label, isNotEmpty, reason: '$kind');
        expect(kMarkerColours.containsKey(kind), isTrue, reason: '$kind');
      }
    });

    test('the colour code is the one §3.6 fixes', () {
      // Green is the player and is deliberately not in the marker table: the
      // player is what everything else is measured from.
      expect(kMarkerColours[MarkerKind.enemy], 0xFFD93A2B);
      expect(kMarkerColours[MarkerKind.loot], 0xFFE8B33A);
      expect(kMarkerColours[MarkerKind.dropped], 0xFF8C8F92);
      expect(kMarkerColours[MarkerKind.shelter], 0xFF3A7BD9);
      expect(kMarkerColours.values, isNot(contains(kPlayerColour)));
    });
  });

  testWidgets('no pack for this area says so on the map (§16.6)', (
    tester,
  ) async {
    await pumpMap(tester, at: fix, hasPack: false);

    expect(find.text('Brak mapy dla tej okolicy'), findsOneWidget);
  });

  testWidgets('economy mode is passed down, not decided here (§3.3)', (
    tester,
  ) async {
    await pumpMap(tester, at: fix, economy: true);

    expect(asked.last.economy, isTrue);
  });

  testWidgets('reads in English too', (tester) async {
    await pumpMap(tester, at: fix, locale: const Locale('en'));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('SHELTER'), findsOneWidget);
  });
}
