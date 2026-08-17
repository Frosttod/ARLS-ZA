/// The MapLibre tile surface (§3.1, §3.6).
///
/// The only file in the project that touches the map plugin. Everything above
/// it sees [TileSurfaceBuilder]; everything below it is a PMTiles archive on
/// disk. Kept apart so `MapScreen` can be tested — a platform view does not
/// exist in a widget test — and so swapping the renderer later touches one
/// file.
///
/// ⚠️ **MapLibre draws the tiles and nothing else.** Every marker, ring, cone,
/// glyph and wave is painted by us on top of it. That is not a style choice:
/// annotations cost a platform-channel round trip each, up to sixty-five of
/// them, rewritten whenever anything moved — which cost a pinch its frame rate
/// and cost a cold start its markers entirely. It also means the dots and the
/// taps are computed from one piece of arithmetic ([offsetOf]) rather than
/// two, so they cannot drift apart.
///
/// No sprite sheet either (§3.1): the shapes are drawn, and the type glyphs
/// come out of the icon font that is already in the binary.
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
    this.noise,
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

  /// §5.6.5: a sound spreading, or null when the street is quiet.
  final NoiseWave? noise;

  /// What to do when the player taps one, or taps nothing — the empty tap
  /// arrives as null, because letting go of a target is a thing a player does
  /// by pointing somewhere else. Null where the map is decoration, as in the
  /// region picker's preview.
  final void Function(MapMarker? marker)? onMarkerTap;

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

  /// One camera move at a time, and never a dropped one.
  final SyncGate _gate = SyncGate();

  /// One camera move at a time, for the same reason.
  bool _zooming = false;

  /// Where and when the finger went down, for telling a tap from a drag
  /// without going through the gesture arena.
  Offset? _pressedAt;
  Duration? _pressedWhen;

  /// A tap waiting to see whether it is the first half of a double tap.
  Timer? _pendingTap;

  /// §6.1a: drives the pulse on anything hunting the player.
  ///
  /// ⚠️ One controller for the life of the state, started and stopped rather
  /// than made and thrown away. Found on a phone, as a red screen after the
  /// display was locked and woken: a SingleTickerProviderStateMixin may create
  /// exactly one ticker ever, and disposing the controller does not give the
  /// permission back. It still runs only while something is actually hunting —
  /// a heartbeat under an empty street is a frame a second spent on nothing.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

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

    final facing = [
      for (final marker in widget.markers)
        if (marker.headingDeg != null) marker,
    ];

    final alerted = [
      for (final marker in widget.markers)
        if (marker.alert != null) marker,
    ];
    final bodies = [
      for (final marker in widget.markers)
        if (marker.kind == MarkerKind.remains) marker,
    ];
    final wave = widget.noise;
    final spreading = wave?.progressAt(DateTime.now());
    _keepPulse(
      wanted:
          spreading != null ||
          alerted.any((marker) => marker.alert == MarkerAlert.hunting),
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
    if (centre == null ||
        (widget.markers.isEmpty && rings.isEmpty && spreading == null)) {
      return gestures;
    }

    // Everything above the tiles is drawn on our side of the platform view,
    // from the same geometry the tap handling uses: the player is always
    // centred, so an offset from the middle is all it takes. That is what
    // stops a dot and the finger that hits it from ever disagreeing.
    return LayoutBuilder(
      builder: (context, constraints) {
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

            // §5.6.5: what the last shot woke up, at the radius it actually
            // carried. A number nobody was shown is not a consequence.
            if (wave != null && spreading != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final now = DateTime.now();
                      final reached = wave.progressAt(now);
                      if (reached == null) return const SizedBox.shrink();

                      return CustomPaint(
                        painter: _NoisePainter(
                          at: offsetOf(
                            wave.at,
                            centre: GeoPoint(centre.latitude, centre.longitude),
                            zoom: _zoom,
                          ),
                          radiusPx:
                              wave.radiusM *
                              reached /
                              metresPerPixel(_zoom, centre.latitude),
                          fade: 1 - reached,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // §10.3: a skull where something went down, so a body reads as a
            // body rather than as another grey dot to walk past.
            if (bodies.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RemainsPainter(
                      at: [
                        for (final marker in bodies)
                          offsetOf(
                            marker.at,
                            centre: GeoPoint(centre.latitude, centre.longitude),
                            zoom: _zoom,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // §3.6: every dot on the map, in one pass. See [_MarkerPainter]
            // for why this is not sixty-five platform-channel calls any more.
            if (widget.markers.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MarkerPainter(
                      markers: widget.markers,
                      centre: GeoPoint(centre.latitude, centre.longitude),
                      zoom: _zoom,
                    ),
                  ),
                ),
              ),

            // §6.1a: a question mark for something looking for the player, an
            // exclamation for something that has found them. Nothing at all
            // for the ones that have noticed nobody.
            if (alerted.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulse,
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
                        pulse: _pulse.value,
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
    // A tap on nothing is still an answer: it lets go of whatever was held.
    handler(marker);
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
    _pulse.dispose();
    super.dispose();
  }

  /// Starts or stops the pulse to match what is on the map.
  ///
  /// Idempotent, because it is called from build: asking a running controller
  /// to run again is nothing, and so is stopping a stopped one.
  void _keepPulse({required bool wanted}) {
    if (wanted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!wanted && _pulse.isAnimating) {
      _pulse.stop();
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
    if (!_gate.enter()) return;

    await _syncCamera(controller);

    if (_gate.leave()) await _sync();
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
}

/// Every marker on the map, in one pass (§3.6).
///
/// ⚠️ This used to be MapLibre circle annotations, one platform-channel round
/// trip each, up to sixty-five of them, rewritten every time anything moved.
/// A pinch fired that on every frame and the game stopped answering; a cold
/// start dropped the one update that carried the markers and the map came up
/// empty. Both were the same mistake — asking another process to draw a dot we
/// already know the screen position of.
///
/// Now it is one `paint()` per frame with the same arithmetic the tap handler
/// already uses ([offsetOf]), so a dot and the finger that hits it can no
/// longer disagree, and nothing crosses a channel at all.
class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({
    required this.markers,
    required this.centre,
    required this.zoom,
  });

  final List<MapMarker> markers;
  final GeoPoint centre;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      final at = middle + offsetOf(marker.at, centre: centre, zoom: zoom);

      // Off screen and not worth a single instruction more.
      if (at.dx < -40 ||
          at.dy < -40 ||
          at.dx > size.width + 40 ||
          at.dy > size.height + 40) {
        continue;
      }

      // §10.3: a body is drawn as a skull and nothing else. A dot under it
      // read as a second thing lying there — and grey is what dropped kit is,
      // so it read as exactly the wrong one.
      if (marker.kind == MarkerKind.remains) continue;

      final radius = kMarkerRadius[marker.kind]!;
      final colour = Color(kMarkerColours[marker.kind]!);

      // A dark rim, because §12 will not let a dot be legible only by its
      // colour and a pale one on a pale street is no dot at all.
      canvas
        ..drawCircle(
          at,
          radius + 0.75,
          Paint()..color = const Color(0xE6000000),
        )
        ..drawCircle(
          at,
          radius,
          Paint()..color = colour.withValues(alpha: 0.9),
        );

      final glyph = marker.icon;
      if (glyph != null) _drawGlyph(canvas, at, glyph);

      if (marker.count > 1) _drawCount(canvas, at, marker.count);
    }
  }

  /// §3.6: what kind of place it is, inside the dot.
  ///
  /// Inside rather than beside: a badge next to a marker drifts away from it
  /// the moment the map moves, and this map moves constantly.
  void _drawGlyph(Canvas canvas, Offset at, PlaceIcon glyph) {
    final icon = _iconFor(glyph);

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 11,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFF0B0D0E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  void _drawCount(Canvas canvas, Offset at, int count) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B0D0E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_MarkerPainter old) =>
      old.zoom != zoom ||
      old.centre != centre ||
      old.markers.length != markers.length ||
      !identical(old.markers, markers);
}

/// The seven shapes of §3.6, as glyphs.
///
/// Const, so the icon tree-shaker can still do its job.
IconData _iconFor(PlaceIcon icon) => switch (icon) {
  PlaceIcon.medical => Icons.local_hospital,
  PlaceIcon.guarded => Icons.local_police,
  PlaceIcon.food => Icons.restaurant,
  PlaceIcon.tools => Icons.handyman,
  PlaceIcon.weapons => Icons.gps_fixed,
  PlaceIcon.books => Icons.menu_book,
  PlaceIcon.home => Icons.home,
  PlaceIcon.vehicle => Icons.directions_car,
  PlaceIcon.waste => Icons.delete_outline,
};

/// One job at a time, and never a job thrown away.
///
/// ⚠️ Dropped work, not deferred work, was the bug this exists for. A marker
/// sync that arrived while another was in flight used to be discarded — and on
/// a cold start the style, the first fix and the first loot spawn all land
/// within a few frames of each other, so the one update that actually carried
/// the markers was the one that got swallowed. The map stayed empty until the
/// next restart, when the markers already existed before the style loaded.
class SyncGate {
  bool _busy = false;
  bool _again = false;

  /// True if the caller may run. False means somebody else is running and this
  /// request has been remembered for them.
  bool enter() {
    if (_busy) {
      _again = true;
      return false;
    }
    _busy = true;
    return true;
  }

  /// True if the work has to be done once more.
  bool leave() {
    _busy = false;
    if (!_again) return false;

    _again = false;
    return true;
  }
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

/// A mark beside anything paying attention to the player (§6.1a).
///
/// ⚠️ A glyph rather than a ring. A ring around a dot reads as part of the
/// dot — on a phone at arm's length it is a slightly thicker marker and
/// nothing more. A question mark and an exclamation mark are read rather than
/// noticed, which is what this has to be: whether something is looking for you
/// or has found you is the difference between walking on and running.
///
/// §12: the colour is a shortcut, never the message. The HUD says the same in
/// words and the cone says which way it is walking.
/// A skull on every body (§10.3, §12).
class _RemainsPainter extends CustomPainter {
  const _RemainsPainter({required this.at});

  final List<Offset> at;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final offset in at) {
      final centre = middle + offset;
      if (centre.dx < -30 ||
          centre.dy < -30 ||
          centre.dx > size.width + 30 ||
          centre.dy > size.height + 30) {
        continue;
      }

      final painter = TextPainter(
        text: const TextSpan(
          text: '☠',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF2B2B2B),
            shadows: [Shadow(color: Color(0xFFFFFFFF), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        centre - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RemainsPainter old) =>
      old.at.length != at.length ||
      [for (var i = 0; i < at.length; i++) old.at[i] != at[i]].contains(true);
}

class _AlertPainter extends CustomPainter {
  const _AlertPainter({required this.markers, required this.pulse});

  final List<({Offset at, MarkerAlert alert})> markers;

  /// 0 to 1 and back, so the one that has found the player will not sit still.
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      // Nothing at all for something that has not noticed anybody: a map
      // marked everywhere is a map marked nowhere.
      if (marker.alert == MarkerAlert.calm) continue;

      final centre = middle + marker.at;
      if (centre.dx < -30 ||
          centre.dy < -30 ||
          centre.dx > size.width + 30 ||
          centre.dy > size.height + 30) {
        continue;
      }

      final hunting = marker.alert == MarkerAlert.hunting;
      final painter = TextPainter(
        text: TextSpan(
          text: hunting ? '!' : '?',
          style: TextStyle(
            fontSize: hunting ? 20 + 3 * pulse : 18,
            fontWeight: FontWeight.bold,
            color: Color(
              kAlertColours[marker.alert]!,
            ).withValues(alpha: hunting ? 1 - 0.25 * pulse : 0.95),
            shadows: const [Shadow(color: Color(0xFFFFFFFF), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Above and to the right of the dot, where it does not sit on the thing
      // it is about.
      painter.paint(canvas, centre + Offset(6, -10 - painter.height / 2));
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

/// The circle a shot pushes out across the map (§5.6.5).
class _NoisePainter extends CustomPainter {
  const _NoisePainter({
    required this.at,
    required this.radiusPx,
    required this.fade,
  });

  final Offset at;
  final double radiusPx;

  /// 1 at the moment of the shot, 0 as the wave dies.
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (radiusPx <= 1) return;

    final centre = Offset(size.width / 2, size.height / 2) + at;
    canvas.drawCircle(
      centre,
      radiusPx,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFA82D17).withValues(alpha: 0.55 * fade),
    );
  }

  @override
  bool shouldRepaint(_NoisePainter old) =>
      old.radiusPx != radiusPx || old.fade != fade || old.at != at;
}
