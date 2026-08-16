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
///
/// ⚠️ This figure only became true when the tile convention was corrected:
/// MapLibre serves 512-pixel tiles, so every "metres across the screen" the
/// game asked for was coming out half as wide. Three kilometres used to mean
/// fifteen hundred metres.
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

class _MapLibreSurfaceState extends State<MapLibreSurface>
    with SingleTickerProviderStateMixin {
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

  /// What each circle was last written as, so an unchanged one costs nothing.
  final Map<String, String> _drawn = {};

  /// One reconciliation at a time. The calls are asynchronous and a pinch can
  /// start a second pass while the first is still talking to the platform.
  bool _syncing = false;

  /// One camera move at a time, for the same reason.
  bool _zooming = false;

  /// Where and when the finger went down, for telling a tap from a drag
  /// without going through the gesture arena.
  Offset? _pressedAt;
  Duration? _pressedWhen;

  /// A tap waiting to see whether it is the first half of a double tap.
  Timer? _pendingTap;

  /// §6.1a: drives the pulse on anything hunting the player. Runs only while
  /// something is — a heartbeat under an empty street is a frame a second
  /// spent on nothing.
  AnimationController? _pulse;

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

    final facing = [
      for (final marker in widget.markers)
        if (marker.headingDeg != null) marker,
    ];

    final alerted = [
      for (final marker in widget.markers)
        if (marker.alert != null) marker,
    ];
    _keepPulse(
      wanted: alerted.any((marker) => marker.alert == MarkerAlert.hunting),
    );

    final gestures = Listener(
      // ⚠️ Taps come from raw pointer events rather than from the detector
      // below. Found on a phone: a tap on a marker did nothing at all, because
      // the scale recognizer — which exists for the pinch — claims a single
      // pointer as a one-finger pan the moment it moves a pixel, and wins the
      // arena from the tap. Every real tap moves a pixel. A Listener does not
      // enter the arena at all, so this sees the press whatever the
      // recognizers decide between themselves.
      onPointerDown: (event) {
        // A second finger down inside the double-tap window means the first
        // press was half of a zoom, not a tap on anything.
        _pendingTap?.cancel();
        _pendingTap = null;

        _pressedAt = event.localPosition;
        _pressedWhen = event.timeStamp;
      },
      onPointerUp: (event) {
        final from = _pressedAt;
        final when = _pressedWhen;
        _pressedAt = null;
        _pressedWhen = null;
        if (from == null || when == null) return;

        // A press that travelled or lingered was a drag or a hold, and this
        // map answers neither.
        if ((event.localPosition - from).distance > 16) return;
        if (event.timeStamp - when > const Duration(milliseconds: 400)) return;

        // Held back just long enough to see whether a second tap follows.
        // Opening a sheet under a double-tap zoom is worse than a moment's
        // wait.
        final at = event.localPosition;
        _pendingTap = Timer(const Duration(milliseconds: 260), () {
          _pendingTap = null;
          _tapAt(at);
        });
      },
      child: GestureDetector(
        // Opaque, so the gestures reach here rather than the platform view.
        // The markers are circles the platform view draws, so finding which
        // one was touched is ours to do.
        behavior: HitTestBehavior.opaque,
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
      ),
    );

    final rings = reachRingsOf(widget.markers);
    if ((counted.isEmpty &&
            rings.isEmpty &&
            facing.isEmpty &&
            alerted.isEmpty) ||
        centre == null) {
      return gestures;
    }

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

            // §10.2, §4.8: how close is close enough, drawn around the player
            // rather than around every marker. Reach is symmetric, so it is
            // the same statement — and one painter costs nothing next to
            // sixty-five circles going over a platform channel.
            if (rings.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ReachPainter(
                      radiiPx: [
                        for (final metres in rings)
                          metres / metresPerPixel(_zoom, centre.latitude),
                      ],
                      colour: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF7A8B8F)
                          : const Color(0xFF4A5A5E),
                    ),
                  ),
                ),
              ),

            // §6.1a: how much attention each of them is paying. Green has
            // not noticed, amber heard something, red is coming — and red
            // pulses, because that one is a clock.
            if (alerted.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulse ?? const AlwaysStoppedAnimation(0),
                    builder: (context, _) => CustomPaint(
                      painter: _AlertPainter(
                        markers: [
                          for (final marker in alerted)
                            (
                              at: offsetOf(
                                marker.at,
                                centre: GeoPoint(
                                  centre.latitude,
                                  centre.longitude,
                                ),
                                zoom: _zoom,
                              ),
                              alert: marker.alert!,
                            ),
                        ],
                        pulse: _pulse?.value ?? 0,
                      ),
                    ),
                  ),
                ),
              ),

            // §3.6: which way each of them is walking. Drawn on our side
            // because a MapLibre circle has no direction, and from the same
            // geometry as everything else here.
            if (facing.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FacingPainter(
                      markers: [
                        for (final marker in facing)
                          (
                            at: offsetOf(
                              marker.at,
                              centre: GeoPoint(
                                centre.latitude,
                                centre.longitude,
                              ),
                              zoom: _zoom,
                            ),
                            headingDeg: marker.headingDeg!,
                            colour: Color(kMarkerColours[marker.kind]!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

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
  void _tapAt(Offset position) {
    final handler = widget.onMarkerTap;
    final centre = widget.centre;
    if (handler == null || centre == null) return;

    final size = context.size;
    if (size == null) return;

    final marker = markerAtOffset(
      widget.markers,
      position - Offset(size.width / 2, size.height / 2),
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

    // A pinch fires this on every frame of the gesture and each one is a
    // camera move over the platform channel. Dropping the ones that arrive
    // while the last is still travelling keeps the gesture smooth: the finger
    // is still on the screen, so the next frame carries the same intent.
    if (_zooming) return;
    _zooming = true;

    try {
      await _applyZoom(controller, zoom);
    } finally {
      _zooming = false;
    }
  }

  Future<void> _applyZoom(MapLibreMapController controller, double zoom) async {
    final clamped = zoom.clamp(
      _widestZoom(context, widget.centre),
      kClosestZoom,
    );
    if ((clamped - _zoom).abs() < 0.001) return;
    _zoom = clamped;

    final centre = widget.centre;
    final target = centre != null
        ? LatLng(centre.latitude, centre.longitude)
        : controller.cameraPosition?.target;
    if (target == null) return;

    await controller.moveCamera(CameraUpdate.newLatLngZoom(target, clamped));

    // The overlays drawn on our side — the reach rings and the counts on a
    // stack — are metres measured in pixels, so a zoom moves all of them. The
    // circles themselves are geographic and MapLibre has already placed them.
    if (mounted) setState(() {});
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
  void dispose() {
    _pendingTap?.cancel();
    _pulse?.dispose();
    super.dispose();
  }

  /// Starts or stops the pulse to match what is on the map.
  void _keepPulse({required bool wanted}) {
    if (wanted && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
    } else if (!wanted && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

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

  /// Reconciles the dots on the map with what the game says is there.
  ///
  /// ⚠️ Every call here is a platform channel round trip, and there can be
  /// sixty-five markers. Found on a phone: a pinch fired this on every frame
  /// of the gesture and the game stopped answering. So it does the least it
  /// can — a circle is only written when what it should look like has
  /// actually changed, and a zoom does not touch it at all, because MapLibre
  /// already knows where a geographic point belongs on screen.
  Future<void> _syncMarkers(MapLibreMapController controller) async {
    if (_syncing) return;
    _syncing = true;

    try {
      final wanted = {for (final marker in widget.markers) marker.id: marker};

      for (final id in _circles.keys.toList()) {
        if (wanted.containsKey(id)) continue;
        await controller.removeCircle(_circles.remove(id)!);
        _drawn.remove(id);
      }

      for (final marker in wanted.values) {
        // What this circle should look like, as one comparable value. Two
        // dots of the same kind in the same place are the same request, and
        // the second one is a channel call for nothing.
        final shape =
            '${marker.at.latitude},${marker.at.longitude},${marker.kind.name}';
        if (_drawn[marker.id] == shape) continue;

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
        _drawn[marker.id] = shape;
      }
    } finally {
      _syncing = false;
    }
  }

  /// MapLibre wants `#rrggbb`; the colour code is stored as ARGB so it can be
  /// used by Flutter painters too.
  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// The rings that say what is within reach, drawn around the middle.
class _ReachPainter extends CustomPainter {
  const _ReachPainter({required this.radiiPx, required this.colour});

  final List<double> radiiPx;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.45);

    for (final radius in radiiPx) {
      // A ring smaller than the pin or wider than the screen says nothing and
      // costs a path.
      if (radius < 4 || radius > size.longestSide) continue;
      canvas.drawCircle(middle, radius, stroke);
    }
  }

  @override
  bool shouldRepaint(_ReachPainter old) {
    if (old.colour != colour || old.radiiPx.length != radiiPx.length) {
      return true;
    }
    for (var i = 0; i < radiiPx.length; i++) {
      if ((old.radiiPx[i] - radiiPx[i]).abs() > 0.5) return true;
    }
    return false;
  }
}

/// Which way each marker is walking (§3.6).
///
/// ⚠️ A direction of travel, never a field of view. §6.2 gives an enemy a
/// detection radius and nothing directional, so a cone that read as vision
/// would be a lie the player would plan around — the same reason the player's
/// own cone disappears when they stop rather than pointing the last way they
/// went.
class _FacingPainter extends CustomPainter {
  const _FacingPainter({required this.markers});

  final List<({Offset at, double headingDeg, Color colour})> markers;

  /// Narrow enough to read as a direction rather than as a searchlight.
  static const double spreadDeg = 50;
  static const double reachPx = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      final centre = middle + marker.at;
      if (centre.dx < -reachPx ||
          centre.dy < -reachPx ||
          centre.dx > size.width + reachPx ||
          centre.dy > size.height + reachPx) {
        continue;
      }

      // Screen coordinates put zero degrees east and y downwards, so a compass
      // bearing turns a quarter turn anticlockwise.
      final start = (marker.headingDeg - spreadDeg / 2 - 90) * math.pi / 180;

      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..arcTo(
            Rect.fromCircle(center: centre, radius: reachPx),
            start,
            spreadDeg * math.pi / 180,
            false,
          )
          ..close(),
        Paint()
          ..shader = RadialGradient(
            colors: [
              marker.colour.withValues(alpha: 0.45),
              marker.colour.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: reachPx)),
      );
    }
  }

  @override
  bool shouldRepaint(_FacingPainter old) {
    if (old.markers.length != markers.length) return true;
    for (var i = 0; i < markers.length; i++) {
      if ((old.markers[i].at - markers[i].at).distance > 0.5) return true;
      if ((old.markers[i].headingDeg - markers[i].headingDeg).abs() > 1) {
        return true;
      }
    }
    return false;
  }
}

/// The ring that says how much attention something is paying (§6.1a).
class _AlertPainter extends CustomPainter {
  const _AlertPainter({required this.markers, required this.pulse});

  final List<({Offset at, MarkerAlert alert})> markers;

  /// 0 to 1 and back, driving the ring on anything hunting the player.
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      final centre = middle + marker.at;
      if (centre.dx < -30 ||
          centre.dy < -30 ||
          centre.dx > size.width + 30 ||
          centre.dy > size.height + 30) {
        continue;
      }

      final hunting = marker.alert == MarkerAlert.hunting;
      final radius = hunting ? 11 + 5 * pulse : 11.0;

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hunting ? 2.5 : 1.8
          ..color = Color(
            kAlertColours[marker.alert]!,
          ).withValues(alpha: hunting ? 0.9 - 0.3 * pulse : 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_AlertPainter old) =>
      old.pulse != pulse ||
      old.markers.length != markers.length ||
      !_sameMarkers(old.markers, markers);

  static bool _sameMarkers(
    List<({Offset at, MarkerAlert alert})> a,
    List<({Offset at, MarkerAlert alert})> b,
  ) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].alert != b[i].alert) return false;
      if ((a[i].at - b[i].at).distance > 0.5) return false;
    }
    return true;
  }
}
