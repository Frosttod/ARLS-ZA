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

import 'map_view.dart' show TileSurfaceBuilder;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../location/position_fix.dart';
import '../combat/awareness.dart';
import '../map/geometry.dart';
import '../map/map_source.dart';
import '../map/map_style.dart';
import 'map_markers.dart';
import 'marker_motion.dart';

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

/// The surface, as the builder [MapView] asks for.
///
/// ⚠️ Here rather than on the screen that pushes the map. Which arguments a
/// tile surface needs is a fact about the surface, and a nine-line closure in
/// the middle of a widget tree is nine lines nobody reads — it was sitting in
/// the largest build method in the codebase, which is the one place a reader
/// is already lost.
TileSurfaceBuilder tilesFrom(MapSource source, {GeoPoint? fallbackCentre}) =>
    (
      context, {
      required centre,
      required markers,
      required economy,
      onMarkerTap,
      noise,
      footfallM,
      darkness = 0.0,
    }) => MapLibreSurface(
      source: source,
      centre: centre,
      markers: markers,
      economy: economy,
      onMarkerTap: onMarkerTap,
      footfallM: footfallM,
      noise: noise,
      darkness: darkness,
      fallbackCentre: fallbackCentre,
    );

/// §17.4, §12: jak ciemna robi się mapa w pełnej nocy.
///
/// Sześćdziesiąt procent, nie sto: mapa ma dalej być mapą. To jest różnica,
/// którą widać kątem oka, a nie ekran, przez który trzeba się przebić.
const double kNightTintMax = 0.6;

class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({
    required this.source,
    required this.centre,
    required this.markers,
    this.noise,
    this.footfallM,
    this.onMarkerTap,
    this.darkness = 0,
    required this.economy,
    this.fallbackCentre,
    super.key,
  });

  /// Where the tiles come from: a verified pack on the device, or the same
  /// archive streamed by byte range from its host (§16.6).
  final MapSource source;

  final PositionFix? centre;

  /// §17.4: ile jest ciemno, zero w południe i jeden w nocy.
  ///
  /// ⚠️ **Mapa wyglądała tak samo o czternastej i o drugiej w nocy.** §17.4
  /// liczyła ten indeks od dawna i czytał go wyłącznie model — wykrywanie
  /// przeciwników i promień przeszukania. Gracz nie miał na ekranie niczego,
  /// co mówiłoby, że właśnie zapadła noc, a noc jest tym, przed czym ta gra
  /// każe wracać do schronu.
  final double darkness;

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

  /// §5.6.1: jak daleko niesie się **własny krok** gracza, albo null w bezruchu.
  ///
  /// ⚠️ **Liczba na pasku nie jest odległością.** HUD pisze „hałas 15 m" i to
  /// jest prawda, której nie da się użyć: piętnaście metrów to na mapie coś
  /// zupełnie innego przy zbliżeniu ulicy niż przy zbliżeniu dzielnicy, a
  /// pytanie brzmi „czy ten Szwędacz stoi w środku, czy poza". Okrąg odpowiada
  /// na nie bez liczenia.
  final double? footfallM;

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

  /// §3.6: where each marker is *on its way to*, so a 1 Hz simulation does not
  /// have to look like one.
  final _motion = MarkerMotion();

  /// §6.1a: czy cokolwiek żywego stoi bliżej niż [kSmoothWithinM].
  bool _closeBy(PositionFix? centre) {
    if (centre == null) return false;

    final here = GeoPoint(centre.latitude, centre.longitude);
    for (final marker in widget.markers) {
      if (marker.kind != MarkerKind.enemy) continue;
      if (marker.at.distanceTo(here) <= kSmoothWithinM) return true;
    }
    return false;
  }

  /// §3.6: the drawing clock, rounded down to [kMarkerFps].
  ///
  /// Quantising here rather than throttling the ticker keeps the pulse and the
  /// glide on one clock: two layers advancing on different rounding is two
  /// layers that disagree about where the same Walker is.
  DateTime _frameClock() {
    final now = DateTime.now();
    const step = 1000 ~/ kMarkerFps;

    return now.subtract(
      Duration(milliseconds: now.millisecondsSinceEpoch % step),
    );
  }

  /// How long the camera should take to reach a newly reported centre.
  ///
  /// ⚠️ Measured rather than chosen. Fixes arrive every second in a fight and
  /// every five seconds on a walk (§3.3), and a glide shorter than the gap
  /// spends four of those five seconds perfectly still — which is the
  /// stuttering, not the moving. Timing the last gap and gliding across the
  /// next one means the camera arrives exactly as the next fix lands.
  Duration _cameraGlide = const Duration(milliseconds: 600);
  DateTime? _lastCentreAt;
  GeoPoint? _lastCentre;

  @override
  Widget build(BuildContext context) {
    final centre = widget.centre;
    final palette = Theme.of(context).brightness == Brightness.dark
        ? MapPalette.dark
        : MapPalette.light;

    final map = MapLibreMap(
      // ⚠️ **No key on the palette, and that is the fix for a reported hang.**
      // This used to be keyed on the brightness, on the belief that the style
      // is baked into the platform view at creation. It is not: the plugin
      // diffs its options in `didUpdateWidget` and `styleString` is one of
      // them, so a new string reloads the style in place, natively.
      //
      // With the key, changing the palette threw the platform view away and
      // built another one — which on a phone means tearing down the renderer
      // and reading a 235 MB pack's tiles again. Reported from the field as
      // the game hanging when the visual mode is switched, and it happens by
      // itself at dusk: `ThemeChoice.daylight` is the default, so the freeze
      // arrived unprompted, in the street, at the worst hour of the day.
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

        // §3.6: leaned back, always by the same amount.
        //
        // Fixed rather than a gesture, and the tilt gesture stays off below.
        // A map read while walking has to be the same map every time it is
        // glanced at — and one angle means the perspective the markers are
        // drawn with is worked out once and cannot drift from the tiles.
        tilt: kMapTiltDeg,
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
    // ⚠️ Positions taken here, in build, rather than in didUpdateWidget: the
    // zoom and the centre both change without the marker list changing, and a
    // glide that only started on a new list would freeze mid-step whenever the
    // player pinched.
    // §3.3: płynność jest luksusem — do siedemdziesięciu pięciu metrów (§6.2).
    // Bliżej niż to jest różnica między „idzie w moją stronę" a „stoi", i tego
    // nie odczytuje się z markera skaczącego raz na sekundę.
    final smooth = !widget.economy || _closeBy(centre);

    if (smooth) _motion.update(widget.markers, DateTime.now());

    _keepPulse(
      wanted:
          spreading != null ||
          (smooth && _motion.movingAt(DateTime.now())) ||
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
    final zones = zonesOf(widget.markers);
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
        // §3.6: every overlay is drawn through the same lean as the tiles. The
        // height comes from the layout rather than a constant because the
        // strength of a perspective depends on how far the camera stands back,
        // and MapLibre sets that from the viewport.
        final overlayTilt = mapTilt(constraints.maxHeight);

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
                            tilt: overlayTilt,
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
                            tilt: overlayTilt,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // §5.6.1: własny krok gracza, wokół gracza — czyli wokół środka,
            // bo mapa zawsze go tam trzyma.
            if ((widget.footfallM ?? 0) > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FootfallPainter(
                      radiusPx:
                          widget.footfallM! /
                          metresPerPixel(_zoom, centre.latitude),
                    ),
                  ),
                ),
              ),

            // §8.1: the ground a shelter holds, drawn where the shelter is.
            if (zones.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ZonePainter(
                      zones: [
                        for (final zone in zones)
                          (
                            at: offsetOf(
                              zone.at,
                              centre: GeoPoint(
                                centre.latitude,
                                centre.longitude,
                              ),
                              zoom: _zoom,
                              tilt: overlayTilt,
                            ),
                            radiusPx:
                                zone.radiusM /
                                metresPerPixel(_zoom, centre.latitude),
                            danger: zone.danger,
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
                      // Null in economy mode: §3.3 buys no frames, and a
                      // marker that jumps is still a marker in the right
                      // place.
                      motion: widget.economy ? null : _motion,
                      // ⚠️ Quantised to 30 fps, and read once for the whole
                      // layer so every dot on one frame is drawn at one
                      // instant.
                      //
                      // The ticker runs at the display rate — 90 or 120 Hz on
                      // the phones §3.3's high-refresh mode asks for — and
                      // repainting sixty-five markers that often is most of
                      // what made the map stutter. Half of thirty is a metre
                      // of walking; nobody can see the difference, and the
                      // frames go to the tiles instead.
                      now: _frameClock(),
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
                                tilt: overlayTilt,
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
                              tilt: overlayTilt,
                            ),
                            headingDeg: marker.headingDeg!,
                            // §6.2: tak daleko, jak naprawdę widzi. Klin
                            // dwudziestosześciopikselowy był rysowany pod
                            // markerem i przez to niewidoczny — a stożek,
                            // którego nie widać, jest niewidzialną karą.
                            reachPx:
                                (marker.reachM ?? 0) /
                                metresPerPixel(_zoom, centre.latitude),
                            colour: Color(kMarkerColours[marker.kind]!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // §17.4: i noc, którą widać.
            //
            // ⚠️ Na samej górze, nad wszystkim, bo to jest światło, a nie
            // warstwa danych — ale bez markerów pod spodem gaszonych do
            // nieczytelności. Granatowy, nie czarny: czerń wygląda jak wygaszony
            // ekran, a o to, żeby telefon wyglądał na działający, gra dba
            // osobno (§12).
            if (widget.darkness > 0.02)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1A2B).withValues(
                        alpha: kNightTintMax * widget.darkness.clamp(0.0, 1.0),
                      ),
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
      tilt: mapTilt(size.height),
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
    // ⚠️ Remembered, not dropped. Found on a phone: the map stopped zooming
    // while the markers carried on scaling, because a frame that arrived mid
    // flight was thrown away *after* `_zoom` had already moved — so our own
    // painters were at one scale and the tiles at another, for good.
    _wantedZoom = zoom;
    if (_zooming) return;
    _zooming = true;

    try {
      var next = _wantedZoom;
      while (next != null) {
        _wantedZoom = null;
        await _applyZoom(controller, next);
        next = _wantedZoom;
      }
    } finally {
      _zooming = false;
    }
  }

  /// The last zoom a gesture asked for, waiting for the camera to catch up.
  double? _wantedZoom;

  Future<void> _applyZoom(MapLibreMapController controller, double zoom) async {
    final clamped = zoom.clamp(
      _widestZoom(context, widget.centre),
      kClosestZoom,
    );
    if ((clamped - _zoom).abs() < 0.001) return;

    final centre = widget.centre;
    final target = centre != null
        ? LatLng(centre.latitude, centre.longitude)
        : controller.cameraPosition?.target;
    if (target == null) return;

    // ⚠️ The camera first, and only then our own scale. The other order left
    // the two able to disagree for ever: `_zoom` is what every painter on our
    // side measures in, so moving it before the tiles move means one failed
    // channel call and the map is at one zoom and the markers at another.
    // ⚠️ The whole camera position, not just the target and zoom. A bare
    // `newLatLngZoom` leaves the tilt to whatever the platform decides to keep,
    // and a map that flattens itself on the first pinch is worse than a map
    // that was never tilted.
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: clamped, tilt: kMapTiltDeg),
      ),
    );
    _zoom = clamped;

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

  /// Learns how long the camera should take, from how long the last one took.
  ///
  /// ⚠️ Measured, not chosen. A fix arrives every second in a fight and every
  /// five on a walk (§3.3), and the plugin's default glide is a fraction of a
  /// second — so the map covered five seconds of pavement in a blink and then
  /// held perfectly still. That reads as stuttering, and no fixed number fixes
  /// both cadences. Timing the gap and gliding across the next one of the same
  /// length means the camera is always moving and always arrives just as the
  /// next fix lands.
  ///
  /// Bounded at both ends: below a third of a second there is nothing to
  /// smooth, and above six the camera would be visibly somewhere the player is
  /// not.
  void _timeTheGap(GeoPoint centre) {
    final now = DateTime.now();
    final last = _lastCentre;
    final at = _lastCentreAt;

    // The same place reported twice is not a gap — it is a rebuild, a zoom, or
    // a theme change, and timing it would collapse the glide to nothing.
    if (last != null &&
        at != null &&
        (last.latitude - centre.latitude).abs() +
                (last.longitude - centre.longitude).abs() >
            1e-7) {
      final gap = now.difference(at);
      _cameraGlide = gap < const Duration(milliseconds: 300)
          ? const Duration(milliseconds: 300)
          : gap > const Duration(seconds: 6)
          ? const Duration(seconds: 6)
          : gap;
    }

    _lastCentre = centre;
    _lastCentreAt = now;
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
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(centre.latitude, centre.longitude),
          zoom: _zoom,
          tilt: kMapTiltDeg,
        ),
      ),
    );
  }

  Future<void> _syncCamera(MapLibreMapController controller) async {
    final centre = widget.centre;
    if (centre == null) return;

    _timeTheGap(GeoPoint(centre.latitude, centre.longitude));

    final target = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(centre.latitude, centre.longitude),
        zoom: _zoom,
        tilt: kMapTiltDeg,
      ),
    );

    // A glide is nicer and costs frames. §3.3 says a low battery buys none of
    // that.
    if (widget.economy) {
      await controller.moveCamera(target);
    } else {
      await controller.animateCamera(target, duration: _cameraGlide);
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
    required this.motion,
    required this.now,
  });

  final List<MapMarker> markers;
  final GeoPoint centre;
  final double zoom;

  /// §3.6: where each marker is on its way to, or null to draw the reported
  /// position exactly — which is what §3.3's economy mode asks for.
  final MarkerMotion? motion;

  /// One instant for the whole frame, so every dot is drawn at the same time.
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      final at =
          middle +
          offsetOf(
            motion?.positionAt(marker.id, now) ?? marker.at,
            centre: centre,
            zoom: zoom,
            tilt: mapTilt(size.height),
          );

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
      final colour = Color(
        marker.spent ? kSpentColour : kMarkerColours[marker.kind]!,
      );

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
      !identical(old.markers, markers) ||
      // Gliding: the data has not changed, where it is drawn has.
      (motion != null && old.now != now);
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

/// §8.1: the ground a shelter holds, drawn around the shelter.
///
/// ⚠️ Not one of [_ReachPainter]'s rings. Reach is symmetric and so it is
/// drawn once around the player; a safe zone is a piece of ground and stays
/// where the building is. Drawing it round the player put a fifty-metre circle
/// on their feet that followed them down the street, which said the exact
/// opposite of what §8.1 means.
class _ZonePainter extends CustomPainter {
  const _ZonePainter({required this.zones});

  final List<({Offset at, double radiusPx, bool danger})> zones;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final zone in zones) {
      if (zone.radiusPx < 4 || zone.radiusPx > size.longestSide) continue;

      final at = middle + zone.at;

      // §12: never colour alone — but here the shape is identical and only the
      // meaning differs, so colour is carrying it. The dot at the centre is
      // what says which it is: a red ring is always around a red dot.
      final fill = zone.danger
          ? const Color(0x14A82D17)
          : const Color(0x143A7BD9);
      final edge = zone.danger
          ? const Color(0x80A82D17)
          : const Color(0x803A7BD9);

      canvas
        ..drawCircle(at, zone.radiusPx, Paint()..color = fill)
        ..drawCircle(
          at,
          zone.radiusPx,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = edge,
        );
    }
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.zones != zones;
}

/// §5.6.1: dokąd niesie się własny krok gracza.
///
/// ⚠️ **Kreskowany, i to nie jest ozdoba.** Pozostałe okręgi na tej mapie mówią
/// o gruncie: strefa schronu jest tam, gdzie jest, a zasięg wzroku Szwędacza
/// należy do Szwędacza. Ten nie jest miejscem — jest dźwiękiem, który za chwilę
/// ucichnie, bo wystarczy zwolnić. Ciągła linia obiecywałaby trwałość, której
/// tu nie ma.
class _FootfallPainter extends CustomPainter {
  const _FootfallPainter({required this.radiusPx});

  final double radiusPx;

  @override
  void paint(Canvas canvas, Size size) {
    if (radiusPx < 6 || radiusPx > size.longestSide) return;

    final middle = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x99E8B33A);

    // Kreski liczone z obwodu, żeby przy każdym promieniu były tej samej
    // długości na ekranie — okrąg z czterema kreskami i okrąg z czterdziestoma
    // czyta się jako dwie różne rzeczy.
    const dash = 10.0;
    final steps = (2 * math.pi * radiusPx / (dash * 2)).round().clamp(8, 96);
    final step = 2 * math.pi / steps;

    for (var i = 0; i < steps; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: middle, radius: radiusPx),
        i * step,
        step / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FootfallPainter old) => old.radiusPx != radiusPx;
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

  final List<({Offset at, double headingDeg, double reachPx, Color colour})>
  markers;

  /// §6.2: exactly the cone the game checks against.
  ///
  /// ⚠️ **It was fifty degrees because it meant nothing.** A wedge drawn
  /// narrower than the field of view is a lie a player acts on: they walk
  /// round what looks like the edge of its vision and are seen, and nothing
  /// on screen explains why. Now that [seesPlayer] asks about this cone, the
  /// picture and the rule have to be the same number.
  static const double spreadDeg = kFieldOfViewDeg;

  /// Ile najmniej, żeby klin dało się w ogóle zobaczyć przy dalekim zoomie.
  static const double minimumPx = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);

    for (final marker in markers) {
      final centre = middle + marker.at;
      final reachPx = marker.reachPx < minimumPx ? minimumPx : marker.reachPx;
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
              marker.colour.withValues(alpha: 0.55),
              marker.colour.withValues(alpha: 0.06),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: reachPx)),
      );

      // ⚠️ Obrys, bo o krawędź tego klina rozbija się cała decyzja. Wypełnienie
      // gaśnie ku końcowi — tam, gdzie gracz najbardziej potrzebuje wiedzieć,
      // czy jeszcze jest w środku — więc granica musi być narysowana linią, a
      // nie końcem gradientu.
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
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = marker.colour.withValues(alpha: 0.75),
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
      if ((old.markers[i].reachPx - markers[i].reachPx).abs() > 1) return true;
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
