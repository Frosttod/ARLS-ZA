/// The channel that is not the screen (§12, §14.4).
///
/// §12 asks for vibration as an alternative to audio signals. Until §14's
/// positional audio exists, that phrasing understates it: the motor is the
/// **only** channel the game has that is not the screen, and the screen is in a
/// pocket for most of a walk. A player who is told something only in pixels is
/// told it only if they happen to be looking.
///
/// ⚠️ **Three signals, and no more.** A phone that buzzes at everything is a
/// phone somebody turns off, and then the one buzz that mattered is gone with
/// the rest. What is here is what §5.5.3 and §9.2 make expensive: something hit
/// you, you went down, something started hunting you. Everything else the game
/// says is a line under the HUD.
library;

import 'package:flutter/services.dart';

/// What a signal is worth, in the only vocabulary the platform has.
///
/// Deliberately mapped rather than passed through: `HapticFeedback` speaks in
/// impact weights, and the game speaks in events. Naming the events here means
/// the mapping can be argued about in one place.
enum Buzz {
  /// §5.5.3: teeth and nails landed. The heaviest thing the platform offers,
  /// because it is the one signal a player must feel through a coat.
  hit,

  /// §9.2: the ground. Long, and unlike anything else — this one is not a
  /// notification, it is the run possibly ending.
  down,

  /// §5.6.2: something is coming. Lighter than a hit, because it is a warning
  /// rather than a cost, and it can repeat.
  hunted,
}

/// Speaks through the motor, when the player has left that switched on.
///
/// ⚠️ Not static. The setting is read at the moment of the buzz rather than
/// captured, so turning it off in the menu is felt on the next signal instead
/// of the next restart.
class Haptics {
  const Haptics(this.enabled);

  /// Read fresh each time — see the class note.
  final bool Function() enabled;

  /// For tests and for a screen with no settings behind it yet.
  static const Haptics off = Haptics(_never);

  void call(Buzz what) {
    if (!enabled()) return;

    switch (what) {
      case Buzz.hit:
        HapticFeedback.heavyImpact();
      case Buzz.down:
        // Not an impact. `vibrate` is the platform's "something serious
        // happened" and is the only one long enough to be felt while falling.
        HapticFeedback.vibrate();
      case Buzz.hunted:
        HapticFeedback.mediumImpact();
    }
  }

  static bool _never() => false;
}
