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

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../location/position_fix.dart';
import '../map/map_source.dart';
import '../map/map_style.dart';
import 'map_markers.dart';

/// Zoom the map opens at: close enough to see which side of the street the
/// player is on, wide enough to see the next junction.
const double kStreetZoom = 16.5;

class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({
    required this.source,
    required this.centre,
    required this.markers,
    required this.following,
    required this.economy,
    required this.onUserPanned,
    super.key,
  });

  /// Where the tiles come from: a verified pack on the device, or the same
  /// archive streamed by byte range from its host (§16.6).
  final MapSource source;

  final PositionFix? centre;
  final List<MapMarker> markers;
  final bool following;

  /// §3.3: no animation, so the camera jumps rather than glides.
  final bool economy;

  final VoidCallback onUserPanned;

  @override
  State<MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<MapLibreSurface> {
  MapLibreMapController? _controller;

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

    return MapLibreMap(
      // The style is baked into the platform view when it is created, so a
      // change of palette has to build a new one. Keying on the brightness is
      // what makes switching the theme actually repaint the map rather than
      // leaving a black city under a white interface.
      key: ValueKey(palette == MapPalette.dark),
      styleString: mapStyleJson(source: widget.source, palette: palette),
      initialCameraPosition: CameraPosition(
        target: centre == null
            ? const LatLng(52.0, 19.0)
            : LatLng(centre.latitude, centre.longitude),
        zoom: kStreetZoom,
      ),
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: () => unawaited(_sync()),

      // The player is drawn by MapScreen as an overlay; MapLibre's own dot
      // would be a second, differently-placed truth.
      myLocationEnabled: false,

      // Nothing on this map is worth a compass rose or an attribution button
      // over the HUD. Attribution for OpenStreetMap belongs in the settings
      // screen, where it can be read (§16.7).
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,

      onCameraTrackingDismissed: widget.onUserPanned,
    );
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

  Future<void> _syncCamera(MapLibreMapController controller) async {
    final centre = widget.centre;
    if (!widget.following || centre == null) return;

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
      if (wanted.containsKey(id)) continue;
      await controller.removeCircle(_circles.remove(id)!);
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
