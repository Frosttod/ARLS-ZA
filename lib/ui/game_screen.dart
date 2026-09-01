/// The game itself: a map, a panel, and whatever is running (§3.6).
///
/// ⚠️ **The last of `_buildGame`.** The entry point's build method was the
/// largest in the codebase and this was most of it — a map screen of thirteen
/// arguments, a menu switch, and a developer overlay, assembled in the middle
/// of five other branches about title screens and permission gates. What the
/// game looks like while it is being *played* is one thing and deserves to be
/// one file.
///
/// Nothing here decides anything. Every argument is a value or a callback the
/// caller worked out, which is what keeps this a screen rather than a second
/// place where the rules live.
library;

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../location/position_fix.dart';
import 'map_markers.dart';
import 'map_view.dart';
import 'notices.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({
    required this.tileBuilder,
    required this.fix,
    required this.markers,
    required this.onMarkerTap,
    required this.noise,
    this.footfallM,
    required this.progress,
    required this.searchPanel,
    required this.economy,
    this.darkness = 0,
    required this.hud,
    required this.notices,
    required this.onMenu,
    this.overlay,
    super.key,
  });

  final TileSurfaceBuilder tileBuilder;

  /// §17.4: ile jest ciemno, zero w południe i jeden w nocy.
  final double darkness;

  /// §3.2: where the player is, or null while nothing has passed the gate.
  final PositionFix? fix;

  final List<MapMarker> markers;
  final void Function(MapMarker?) onMarkerTap;

  /// §5.6.5: what the last shot woke up, drawn at the radius it carried.
  final NoiseWave? noise;

  /// §5.6.1: jak daleko niesie się własny krok gracza, albo null w bezruchu.
  final double? footfallM;

  /// §2.1a, §12: everything with a clock on it, and every line with a way out.
  ///
  /// ⚠️ One slot used to show whichever of two things it liked best. A
  /// magazine change had its bar at the bottom of the screen and a dismantling
  /// had one on a screen the player was not looking at — which is the same
  /// failure three field reports described as "it does not work": it was
  /// working, and there was no way to tell.
  final Widget? progress;

  /// §5.5.1, §10.2: the fight when there is one, and what can be done standing
  /// here either way.
  final Widget? searchPanel;

  final bool economy;
  final Widget? hud;
  final ValueListenable<List<Notice>> notices;
  final void Function(MapMenuEntry) onMenu;

  /// §15.3's developer panel, when it is running.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      MapScreen(
        tileBuilder: tileBuilder,
        fix: fix,
        markers: markers,
        onMarkerTap: onMarkerTap,
        noise: noise,
        footfallM: footfallM,
        progress: progress,
        searchPanel: searchPanel,
        headingDeg: fix?.headingDeg,
        // §17.4: mapa gaśnie razem z niebem.
        darkness: darkness,
        economy: economy,

        // There is always a map here — this screen is only built with a
        // source. Whether the player has walked off its *edge* is the coverage
        // question of §16.6, and it arrives with 3.12.
        hasPack: true,
        hud: hud,
        notices: NoticeStack(notices: notices),
        onMenu: onMenu,
      ),
      ?overlay,
    ],
  );
}
