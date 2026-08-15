/// The map screen (design doc §3.6).
///
/// Structure worth explaining, because it is not the obvious one:
///
/// * **The camera is locked to the player, and the player is a Flutter overlay
///   in the middle of the screen.** Nothing has to be projected from
///   coordinates to pixels, and the dot cannot drift out of view. The map
///   cannot be dragged at all: it is not a chart read from above but what the
///   character can see from where they stand. Zoom belongs to the player, the
///   position does not — and it is clamped, because a survivor with a phone
///   does not have a satellite.
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
      required bool economy,
      void Function(MapMarker marker)? onMarkerTap,
    });

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.tileBuilder,
    required this.fix,
    this.headingDeg,
    this.markers = const [],
    this.onMarkerTap,
    this.economy = false,
    this.hasPack = true,
    this.hud,
    this.onMenu,
    this.searchPanel,
    super.key,
  });

  final TileSurfaceBuilder tileBuilder;

  /// Where the player is, of whatever accuracy (§3.2 gates movement, not
  /// drawing). Null only before anything at all has arrived.
  final PositionFix? fix;

  /// Course over ground. Null while stationary, and then no cone is drawn:
  /// a cone left pointing the last way travelled is a lie a player acts on.
  final double? headingDeg;

  final List<MapMarker> markers;

  /// What the player wants to know about, tapped on the map: what is in a
  /// place, or what is lying in the street.
  final void Function(MapMarker marker)? onMarkerTap;

  /// §3.3 economy mode: no animations. The camera jumps instead of gliding.
  final bool economy;

  /// False when there is no pack for where the player is standing (§16.6).
  final bool hasPack;

  /// The HUD of §3.6, laid over the top of the map.
  final Widget? hud;

  final void Function(MapMenuEntry)? onMenu;

  /// The searching controls of §10.2 and §19.3, above the menu. Null where
  /// there is nothing to search — without a map pack there is no loot layer.
  final Widget? searchPanel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    // No position, no map. Drawing a city the player is not standing in is
    // worse than saying nothing: it looks like the game is lost rather than
    // waiting, and the first thing they do is doubt the map. A phone indoors
    // still knows roughly where it is, so this window is short.
    if (widget.fix == null) {
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      l10n.mapWaitingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mapWaitingBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.hud != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(child: widget.hud!),
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.tileBuilder(
              context,
              centre: widget.fix,
              markers: widget.markers,
              economy: widget.economy,
              onMarkerTap: widget.onMarkerTap,
            ),
          ),

          // Always the middle of the screen: the camera cannot be moved away
          // from the player, so the middle is always where they are.
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

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.searchPanel != null) widget.searchPanel!,
                _BottomMenu(onSelected: widget.onMenu),
              ],
            ),
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
