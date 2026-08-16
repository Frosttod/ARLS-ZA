/// The MapLibre tile surface (§3.1, §3.6).
///
/// The only file in the project that touches the map plugin. Everything above
/// it sees [TileSurfaceBuilder]; everything below it is a PMTiles archive on
/// disk. Kept apart so `MapScreen` can be tested — a platform view does not
/// exist in a widget test — and so swapping the renderer later touches one
/// file.
///
/// Markers are circles rather than symbols: symbols need image assets, and the
/// style deliberately ships no sprite sheet (§3.1). A circle carries the colour
/// code of §3.6 without a byte of art.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../location/position_fix.dart';
import '../map/geometry.dart';
import '../map/map_source.dart';
import '../map/map_style.dart';
import 'map_markers.dart';

/// Zoom the map opens at: close enough to see which side of the street the
/// player is on, wide enough to see the next junction.
const double kStreetZoom = 17.5;

/// The widest view the game allows, in metres across the screen (§3.6).
///
/// Three kilometres. §3.6 argues for a kilometre — the character knows their
/// street and the next junction, not the district — and that was the limit
/// until a walk showed the contradiction it created: reconnaissance reveals
/// places, the spawner puts them up to two kilometres out (§10), and the map
/// then refused to show the player where any of them were. A marker the game
/// placed and will not display is worse than a wide view.
///
/// Three kilometres covers the spawn radius with a margin, and nothing else
/// changes: the map still cannot be dragged, so a player can only ever pull
/// back around themselves.
const double kWidestViewM = 3000;

/// The closest the map goes. Past this the tiles have nothing more to say —
/// the packs are built to zoom 15 and everything beyond is the renderer
/// stretching what it has.
const double kClosestZoom = 19;

/// The furthest out the game lets a player pull, given the width of their
/// screen in **logical** pixels.
///
/// The unit is the whole point. A web-mercator zoom level is defined against a
/// 256-pixel tile in the device-independent units MapLibre lays out in, so
/// handing this physical pixels makes the limit about three times tighter than
/// §3.6 asks for: on a phone at three times density, a "kilometre across" came
/// out as 330 metres.
double widestGameZoom({
  required double logicalWidth,
  required double latitude,
}) => zoomForWidth(
  metresAcross: kWidestViewM,
  pixelWidth: logicalWidth,
  latitude: latitude,
);

class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({
    required this.source,
    required this.centre,
    required this.markers,
    this.onMarkerTap,
    required this.economy,
    this.fallbackCentre,
    super.key,
  });

  /// Where the tiles come from: a verified pack on the device, or the same
  /// archive streamed by byte range from its host (§16.6).
  final MapSource source;

  final PositionFix? centre;

  /// Where to point the camera before the first fix arrives — the installed
  /// pack's own centre, read from its header.
  ///
  /// Without it the map opens at an arbitrary point and, if that point is
  /// outside the pack, draws nothing at all: a blank screen that looks like a
  /// broken renderer rather than a GPS that has not locked yet. Indoors, which
  /// is where a player first opens the game, that is the normal case.
  final GeoPoint? fallbackCentre;

  final List<MapMarker> markers;

  /// What to do when the player taps one. Null where the map is decoration —
  /// the region picker's preview, for instance.
  final void Function(MapMarker marker)? onMarkerTap;

  /// §3.3: no animation, so the camera jumps rather than glides.
  final bool economy;

  @override
  State<MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<MapLibreSurface> {
  MapLibreMapController? _controller;

  /// The camera's zoom, held here because the game drives it rather than
  /// MapLibre. Every change is applied together with the player's position, so
  /// there is no moment at which the two disagree.
  double _zoom = kStreetZoom;

  /// Where the zoom stood when the current pinch began.
  double? _zoomAtGestureStart;

  /// Circles currently on the map, by marker id. Kept so a marker that moved
  /// is updated rather than removed and re-added — a marker that blinks every
  /// second is one nobody can tap.
  final Map<String, Circle> _circles = {};

  @override
  Widget build(BuildContext context) {
    final centre = widget.centre;
    final palette = Theme.of(context).brightness == Brightness.dark
        ? MapPalette.dark
        : MapPalette.light;

    final map = MapLibreMap(
      // The style is baked into the platform view when it is created, so a
      // change of palette has to build a new one. Keying on the brightness is
      // what makes switching the theme actually repaint the map rather than
      // leaving a black city under a white interface.
      key: ValueKey(palette == MapPalette.dark),
      styleString: mapStyleJson(source: widget.source, palette: palette),
      initialCameraPosition: CameraPosition(
        target: centre != null
            ? LatLng(centre.latitude, centre.longitude)
            : widget.fallbackCentre != null
            ? LatLng(
                widget.fallbackCentre!.latitude,
                widget.fallbackCentre!.longitude,
              )
            // Nothing installed and no fix: the geometric centre of Poland is
            // as good a guess as any, and the region screen is already open.
            : const LatLng(52.0, 19.0),
        zoom: kStreetZoom,
      ),
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: () => unawaited(_sync()),

      // Belt and braces. MapLibre's own gestures are off, but a style reload
      // or a rotation can still leave the camera somewhere it was not put.
      onCameraIdle: () => unawaited(_recentre()),

      // The player is drawn by MapScreen as an overlay; MapLibre's own dot
      // would be a second, differently-placed truth.
      myLocationEnabled: false,

      // Nothing on this map is worth a compass rose or an attribution button
      // over the HUD. Attribution for OpenStreetMap belongs in the settings
      // screen, where it can be read (§16.7).
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,

      // The map cannot be dragged (§3.6). It is not a chart the player reads
      // from above — it is what the character can see from where they stand,
      // and it stays under them. Zoom is theirs; the position is not.
      scrollGesturesEnabled: false,
      dragEnabled: false,

      // ⚠️ MapLibre's own zoom is off, and the game does it instead.
      //
      // Both of its zoom gestures anchor on the fingers: a pinch scales about
      // the midpoint between them, a double tap about the tap. Either one
      // slides the ground out from under the player, who is drawn at the middle
      // of the screen and does not move. `doubleClickZoomEnabled` would only
      // help on the web. Driving the camera ourselves is the only way the pin
      // stays where the player is, which is the one promise this view makes.
      zoomGesturesEnabled: false,

      // Nothing claimed on behalf of the platform view, so the detector above
      // wins the arena rather than competing with the embedded map for the
      // same fingers.
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      minMaxZoomPreference: MinMaxZoomPreference(
        _widestZoom(context, centre),
        kClosestZoom,
      ),
    );

    final counted = [
      for (final marker in widget.markers)
        if (marker.count > 1) marker,
    ];

    final gestures = GestureDetector(
      // Opaque, so the gestures reach here rather than the platform view. The
      // markers are circles the platform view draws, so their taps are ours to
      // find: the gesture arena is won here and the plugin never sees a finger.
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTap,
      onDoubleTap: () => unawaited(_zoomBy(1)),
      onScaleStart: (_) => _zoomAtGestureStart = _zoom,
      onScaleUpdate: (details) {
        final start = _zoomAtGestureStart;
        // A scale of 1 is a drag, not a pinch, and dragging does nothing here.
        if (start == null || details.scale == 1.0) return;
        unawaited(_zoomTo(start + math.log(details.scale) / math.ln2));
      },
      onScaleEnd: (_) => _zoomAtGestureStart = null,
      child: map,
    );

    if (counted.isEmpty || centre == null) return gestures;

    // §4.8: the number on a stack of dropped kit. Drawn on our side of the
    // platform view because a MapLibre circle has no text, and computed from
    // the same geometry as the tap handling — the player is always centred, so
    // an offset from the middle is all it takes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final middle = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        return Stack(
          children: [
            Positioned.fill(child: gestures),
            for (final marker in counted)
              Builder(
                builder: (context) {
                  final at =
                      middle +
                      offsetOf(
                        marker.at,
                        centre: GeoPoint(centre.latitude, centre.longitude),
                        zoom: _zoom,
                      );

                  return Positioned(
                    left: at.dx - 12,
                    top: at.dy - 9,
                    child: IgnorePointer(
                      child: Container(
                        alignment: Alignment.center,
                        width: 24,
                        height: 18,
                        child: Text(
                          '${marker.count}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B0D0E),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// A tap on the map: whatever marker is under the finger, if any.
  ///
  /// Worked out here rather than asked of the platform. The player is always
  /// at the centre of this widget (that is what the whole camera arrangement
  /// exists for), so the offset from the middle is all the geometry needed —
  /// and it stays in logical pixels, which is the unit MapLibre's zoom is
  /// defined in.
  void _handleTap(TapUpDetails details) {
    final handler = widget.onMarkerTap;
    final centre = widget.centre;
    if (handler == null || centre == null) return;

    final size = context.size;
    if (size == null) return;

    final marker = markerAtOffset(
      widget.markers,
      details.localPosition - Offset(size.width / 2, size.height / 2),
      centre: GeoPoint(centre.latitude, centre.longitude),
      zoom: _zoom,
    );
    if (marker != null) handler(marker);
  }

  /// Applies a zoom, always about the player.
  ///
  /// Position and zoom go in one camera update rather than two: sending them
  /// separately gives a frame where the map has scaled but not yet moved, which
  /// is exactly the jump this whole arrangement exists to prevent.
  Future<void> _zoomTo(double zoom) async {
    final controller = _controller;
    if (controller == null) return;

    final clamped = zoom.clamp(_widestZoom(context, widget.centre), kClosestZoom);
    if ((clamped - _zoom).abs() < 0.001) return;
    _zoom = clamped;

    final centre = widget.centre;
    final target = centre != null
        ? LatLng(centre.latitude, centre.longitude)
        : controller.cameraPosition?.target;
    if (target == null) return;

    await controller.moveCamera(CameraUpdate.newLatLngZoom(target, clamped));

    // The reach rings are metres drawn in pixels, so a zoom changes all of
    // them. Redrawn here rather than on the idle callback: a ring that lags
    // the map by a frame reads as the reach itself moving.
    await _syncMarkers(controller);
  }

  Future<void> _zoomBy(double steps) => _zoomTo(_zoom + steps);

  /// The zoom at which a kilometre fills the screen here.
  ///
  /// Computed rather than hard-coded because a zoom number means a different
  /// distance on a small phone than a large one, and a different one in Gdańsk
  /// than in Zakopane.
  ///
  /// ⚠️ Logical pixels, not physical ones. A web-mercator zoom level is defined
  /// against a 256-pixel tile in the units MapLibre lays out in, which are
  /// device-independent. Multiplying by the pixel ratio here made the widest
  /// allowed view about three times narrower than §3.6 asks for — a "kilometre"
  /// that was really 330 metres on any modern phone.
  double _widestZoom(BuildContext context, PositionFix? centre) =>
      widestGameZoom(
        logicalWidth: MediaQuery.sizeOf(context).width,
        latitude: centre?.latitude ?? 52,
      );

  @override
  void didUpdateWidget(MapLibreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_sync());
  }

  Future<void> _sync() async {
    final controller = _controller;
    if (controller == null) return;

    await _syncCamera(controller);
    await _syncMarkers(controller);
  }

  /// Puts the player back under the pin after a zoom.
  ///
  /// Only when the camera has actually drifted: MapLibre reports idle after
  /// every camera move including our own, and moving again inside that callback
  /// would be a loop. A tenth of a second of arc is about three metres, which
  /// is inside GPS noise and well inside a marker.
  Future<void> _recentre() async {
    final controller = _controller;
    final centre = widget.centre;
    if (controller == null || centre == null) return;

    final camera = controller.cameraPosition?.target;
    if (camera == null) return;

    const tolerance = 0.00003;
    if ((camera.latitude - centre.latitude).abs() < tolerance &&
        (camera.longitude - centre.longitude).abs() < tolerance) {
      return;
    }

    // Never animated. The player did not ask to travel — the map slipped, and
    // gliding it back would draw attention to the slip.
    await controller.moveCamera(
      CameraUpdate.newLatLng(LatLng(centre.latitude, centre.longitude)),
    );
  }

  Future<void> _syncCamera(MapLibreMapController controller) async {
    final centre = widget.centre;
    if (centre == null) return;

    final target = CameraUpdate.newLatLng(
      LatLng(centre.latitude, centre.longitude),
    );

    // A glide is nicer and costs frames. §3.3 says a low battery buys none of
    // that.
    if (widget.economy) {
      await controller.moveCamera(target);
    } else {
      await controller.animateCamera(target);
    }
  }

  Future<void> _syncMarkers(MapLibreMapController controller) async {
    final wanted = {for (final marker in widget.markers) marker.id: marker};

    for (final id in _circles.keys.toList()) {
      if (wanted.containsKey(id.replaceAll('.reach', ''))) continue;
      await controller.removeCircle(_circles.remove(id)!);
    }

    // The reach rings first, so a marker is never hidden under its own ring.
    for (final marker in wanted.values) {
      final reach = marker.reachM;
      final id = '${marker.id}.reach';

      if (reach == null) {
        final stale = _circles.remove(id);
        if (stale != null) await controller.removeCircle(stale);
        continue;
      }

      // Metres, drawn in pixels: a ring that stayed the same size on screen
      // would say nothing about how far away anything is.
      final options = CircleOptions(
        geometry: LatLng(marker.at.latitude, marker.at.longitude),
        circleRadius: reach / metresPerPixel(_zoom, marker.at.latitude),
        circleColor: _hex(kMarkerColours[marker.kind]!),
        circleOpacity: 0.10,
        circleStrokeColor: _hex(kMarkerColours[marker.kind]!),
        circleStrokeWidth: 1,
        circleStrokeOpacity: 0.5,
      );

      final existing = _circles[id];
      if (existing == null) {
        _circles[id] = await controller.addCircle(options);
      } else {
        await controller.updateCircle(existing, options);
      }
    }

    for (final marker in wanted.values) {
      final options = CircleOptions(
        geometry: LatLng(marker.at.latitude, marker.at.longitude),
        circleRadius: kMarkerRadius[marker.kind],
        circleColor: _hex(kMarkerColours[marker.kind]!),
        circleStrokeColor: '#000000',
        circleStrokeWidth: 1.5,
        circleOpacity: 0.9,
      );

      final existing = _circles[marker.id];
      if (existing == null) {
        _circles[marker.id] = await controller.addCircle(options);
      } else {
        await controller.updateCircle(existing, options);
      }
    }
  }

  /// MapLibre wants `#rrggbb`; the colour code is stored as ARGB so it can be
  /// used by Flutter painters too.
  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
