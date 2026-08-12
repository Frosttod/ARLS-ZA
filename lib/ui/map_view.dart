/// The map screen (design doc §3.6).
///
/// Structure worth explaining, because it is not the obvious one:
///
/// * **The camera follows the player, and the player is a Flutter overlay in
///   the middle of the screen.** Nothing has to be projected from coordinates
///   to pixels, and the dot cannot drift out of view. When the player drags the
///   map, following stops and a "back to me" button appears — a map that snaps
///   back the moment you let go cannot be read ahead of you.
/// * **The tile map is injected.** `MapLibreMap` is a platform view and does
///   not exist in a widget test, so [MapScreen] takes a builder. The real app
///   passes the MapLibre one; tests pass a coloured box and check everything
///   that is actually theirs: the menu, the recentre button, the labels, the
///   marker colour code.
/// * **Markers are circles, not symbols.** Symbols need image assets and the
///   style deliberately ships no sprite sheet (§3.1). Circles carry the colour
///   code of §3.6 without shipping a single byte of art.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../location/position_fix.dart';
import 'map_markers.dart';
import 'player_pin.dart';

/// Which bottom-menu entry is being asked for (§3.6).
enum MapMenuEntry { profile, inventory, shelter, settings }

/// Builds the tile surface. Injected so the screen is testable.
typedef TileSurfaceBuilder =
    Widget Function(
      BuildContext context, {
      required PositionFix? centre,
      required List<MapMarker> markers,
      required bool following,
      required bool economy,
      required void Function() onUserPanned,
    });

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.tileBuilder,
    required this.fix,
    this.headingDeg,
    this.markers = const [],
    this.economy = false,
    this.hasPack = true,
    this.hud,
    this.onMenu,
    super.key,
  });

  final TileSurfaceBuilder tileBuilder;

  /// Where the player is. Null before the first fix — the map still draws, so
  /// the player sees the region rather than a blank screen with a spinner.
  final PositionFix? fix;

  /// Course over ground. Null while stationary, and then no cone is drawn:
  /// a cone left pointing the last way travelled is a lie a player acts on.
  final double? headingDeg;

  final List<MapMarker> markers;

  /// §3.3 economy mode: no animations. The camera jumps instead of gliding.
  final bool economy;

  /// False when there is no pack for where the player is standing (§16.6).
  final bool hasPack;

  /// The HUD of §3.6, laid over the top of the map.
  final Widget? hud;

  final void Function(MapMenuEntry)? onMenu;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// True while the camera tracks the player. Dragging the map turns it off;
  /// only the button turns it back on.
  bool _following = true;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.tileBuilder(
              context,
              centre: widget.fix,
              markers: widget.markers,
              following: _following,
              economy: widget.economy,
              onUserPanned: () {
                if (_following) setState(() => _following = false);
              },
            ),
          ),

          // The player sits in the middle of the screen only while the camera
          // is following. Once the map has been dragged, the middle of the
          // screen is not where they are.
          if (_following && widget.fix != null)
            Center(
              child: Semantics(
                label: l10n.mapPlayerLabel,
                child: PlayerPin(headingDeg: widget.headingDeg),
              ),
            ),

          if (widget.hud != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: widget.hud!),
            ),

          if (!widget.hasPack)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: _Banner(text: l10n.mapNoPack),
            ),

          if (!_following)
            Positioned(
              right: 16,
              bottom: 96,
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _following = true),
                icon: const Icon(Icons.my_location),
                label: Text(l10n.mapRecentre),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomMenu(onSelected: widget.onMenu),
          ),
        ],
      ),
    );
  }
}

/// PROFIL · EKWIPUNEK · SCHRON · USTAWIENIA (§3.6).
class _BottomMenu extends StatelessWidget {
  const _BottomMenu({this.onSelected});

  final void Function(MapMenuEntry)? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    final entries = <(MapMenuEntry, String, IconData)>[
      (MapMenuEntry.profile, l10n.menuProfile, Icons.person_outline),
      (MapMenuEntry.inventory, l10n.menuInventory, Icons.backpack_outlined),
      (MapMenuEntry.shelter, l10n.menuShelter, Icons.home_outlined),
      (MapMenuEntry.settings, l10n.menuSettings, Icons.settings_outlined),
    ];

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final (entry, label, icon) in entries)
              Expanded(
                child: InkWell(
                  onTap: onSelected == null ? null : () => onSelected!(entry),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 22),
                        const SizedBox(height: 4),
                        Text(label, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          left: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}

/// The label a screen reader reads for a marker (§12).
///
/// Colour is never the only carrier: §3.6 assigns hues, and this assigns words
/// to the same things.
String markerLabel(L10n l10n, MapMarker marker) =>
    marker.label ??
    switch (marker.kind) {
      MarkerKind.enemy => l10n.mapMarkerEnemy,
      MarkerKind.loot => l10n.mapMarkerLoot,
      MarkerKind.dropped => l10n.mapMarkerDropped,
      MarkerKind.shelter => l10n.mapMarkerShelter,
    };
