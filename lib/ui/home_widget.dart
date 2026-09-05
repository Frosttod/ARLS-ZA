/// The home-screen widget, from the Dart side (§13.1, §12).
///
/// The launcher holds four numbers and a line of text; this decides what the
/// text says and hands the lot to Android. Two decisions worth stating:
///
/// * **The words are formatted here, not in Kotlin.** The game is translated
///   in `app_*.arb` and nowhere else — a second copy of "Krwawienie" in
///   `strings.xml` is a copy that goes stale the first time somebody rewords
///   the game's own. Kotlin receives finished strings and draws them.
/// * **The bars are numbers.** Percentages travel as integers so that the
///   widget can render a real progress bar rather than a picture of one, and
///   so a stale reading still shows the *right* level rather than nothing.
///
/// ⚠️ **Pushed on a throttle, not on every tick.** The loop publishes about
/// once a second; a launcher redraw at that rate is a battery complaint with a
/// widget attached. Nothing is sent unless a figure a player can see has
/// actually changed, or [kWidgetHeartbeat] has passed — see [HomeWidget.push].
library;

import 'package:flutter/services.dart';

import '../game/home_status.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';

/// The same channel the storage bridge uses. One handler in `MainActivity`,
/// because two channels for six methods is filing rather than architecture.
const String kWidgetChannel = 'com.raidodevelopment.arlsza/storage';

/// How often an unchanged reading is resent.
///
/// Not zero: the widget draws "how long ago" from the timestamp, and a figure
/// that stops arriving looks identical to a game that stopped running. Five
/// minutes is far below [kFreshFor], so the widget never goes stale merely
/// because nothing about the body changed.
const Duration kWidgetHeartbeat = Duration(minutes: 5);

/// Hands the current reading to the launcher.
class HomeWidget {
  HomeWidget({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(kWidgetChannel);

  final MethodChannel _channel;

  /// What was last sent, so an unchanged reading costs nothing.
  Map<String, Object?>? _last;
  DateTime? _sentAt;

  /// Sends [status], unless the launcher already shows exactly this.
  ///
  /// Returns whether anything was actually sent — for tests, and for anybody
  /// wondering whether the throttle is doing its job.
  Future<bool> push(HomeStatus status, L10n l10n) async {
    final payload = wireOf(status, l10n);
    final now = status.at;

    final same = _last != null && _sameAs(payload, _last!);
    final quiet =
        _sentAt != null && now.difference(_sentAt!) < kWidgetHeartbeat;
    if (same && quiet) return false;

    _last = payload;
    _sentAt = now;

    try {
      await _channel.invokeMethod<void>('widget.push', payload);
      return true;
    } on PlatformException {
      // A launcher that refused the update, or a widget nobody has placed.
      // Neither is worth interrupting a walk over.
      return false;
    } on MissingPluginException {
      // A desktop developer build, or a test with no platform behind it.
      return false;
    }
  }

  /// ⚠️ Compares everything except the timestamp. The clock changes every
  /// tick; if it counted as a change the throttle would never fire once.
  static bool _sameAs(Map<String, Object?> a, Map<String, Object?> b) {
    for (final key in a.keys) {
      if (key == 'at') continue;
      if ('${a[key]}' != '${b[key]}') return false;
    }
    return true;
  }
}

/// The reading as Android wants it: four numbers, three labels, one line of
/// what is wrong, and when it was true.
Map<String, Object?> wireOf(HomeStatus status, L10n l10n) {
  final shown = status.shown(now: status.at);
  final over = status.over(now: status.at);

  return {
    'water': status.waterPct,
    'kcal': status.kcalPct,
    'sleep': status.sleepPct,
    'bpm': status.bpm,
    'waterLabel': l10n.hudWater,
    'kcalLabel': l10n.hudCalories,
    'sleepLabel': l10n.hudSleep,
    // Empty means "nothing wrong", which the widget draws as a calm line
    // rather than as a blank — see the Kotlin side.
    'ailments': effects([
      for (final ailment in shown) ailmentText(ailment, l10n),
      if (over > 0) '+$over',
    ], gap: kTightGap),
    'ok': shown.isEmpty ? l10n.widgetNothingWrong : '',
    'at': status.at.millisecondsSinceEpoch,
  };
}

/// One thing that is wrong, in as few words as a launcher allows.
String ailmentText(Ailment ailment, L10n l10n) => switch (ailment) {
  Ailment.bleeding => l10n.widgetBleeding,
  Ailment.shock => l10n.widgetShock,
  Ailment.enemy => l10n.widgetEnemy,
  Ailment.microsleeps => l10n.widgetMicrosleeps,
  Ailment.wasting => l10n.widgetWasting,
  Ailment.thirsty => l10n.widgetThirsty,
  Ailment.starving => l10n.widgetStarving,
  Ailment.sleepless => l10n.widgetSleepless,
};
