/// How often the screen is allowed to redraw (§3.3, §3.6).
///
/// Android phones ship at 60 Hz and idle there even when the panel can do 90
/// or 120: the higher modes are opt-in per app. A map that is panned and
/// zoomed while walking is exactly the kind of thing the higher mode was made
/// for, and asking for it costs one call.
///
/// ⚠️ But it is not free, and this game is the wrong one to be careless about
/// it. A walk is hours long, the phone is the only clock the character has,
/// and §3.3 already spends real effort slowing the position cadence down to
/// keep it alive. Doubling the frame rate for the whole of that would take
/// back what §3.3 saved.
///
/// So it rides on the decision that already exists. [SamplingDecision.economy]
/// is raised when the battery is low and nothing is charging; it already means
/// "stop animating, the map may jump" (§3.3). Smoothness is the same kind of
/// luxury as an animation, so it goes at the same moment — no second setting,
/// no second idea for the player to hold.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Asks the platform for a refresh rate, and only when the answer changes.
class ScreenRefresh {
  ScreenRefresh({Future<void> Function({required bool high})? apply})
    : _apply = apply ?? _platform;

  final Future<void> Function({required bool high}) _apply;

  /// What was last asked for, or null if nothing has been asked yet — which is
  /// also what a failed attempt resets to, so a phone that refused once is
  /// asked again rather than left at whatever it happened to be.
  bool? _high;

  Future<void> want({required bool economy}) async {
    final high = !economy;
    if (_high == high) return;
    _high = high;

    try {
      await _apply(high: high);
    } catch (_) {
      // A display that will not be told is not an error worth showing anybody:
      // the game is entirely playable at whatever rate the panel chose. Only
      // the memory of having asked is dropped.
      _high = null;
    }
  }

  static Future<void> _platform({required bool high}) async {
    // Android only. The plugin is a no-op elsewhere, but the check keeps the
    // channel call itself off platforms that have nothing behind it.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await (high
        ? FlutterDisplayMode.setHighRefreshRate()
        : FlutterDisplayMode.setLowRefreshRate());
  }
}
