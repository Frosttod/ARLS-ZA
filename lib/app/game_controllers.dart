/// Everything that owns a piece of the game, in one place (§2.1a, §11.1).
///
/// ⚠️ **Empty on purpose, for now.**
///
/// `_TitleScreenState` is six and a half thousand lines and owns forty fields:
/// the pack, the shelves, the shelters, the loot, the fight, five clocks and
/// the screen they are all drawn on. That is why crediting a meal could reach
/// the game loop, come back through a snapshot listener and credit the meal
/// again — three hops between layers that are, in the file, one class.
///
/// The way out is one controller per thing that has state, and this is the bag
/// they go in. It exists before any of them do so that the first extraction
/// carries one decision — *what moves* — instead of two.
///
/// **The rules the bag exists to keep:**
///
///   - `ui → controllers → {sim, data}`. A controller that imports
///     `material.dart` is the God class again with a smaller file name.
///   - Controllers do not know each other. Where one genuinely needs another
///     — taking a thing apart reaches for a shelf — it is given a narrow
///     interface, never a neighbour.
///   - One clock. `ActionController` will own the only `Timer`; everything
///     else is credited by it. Five racing timers is what the meal bug was
///     made of.
///   - Every controller must be constructible in a test with a memory
///     database and no widgets at all.
library;

import 'package:flutter/foundation.dart';

/// Holds the controllers for one running game, and shuts them down together.
///
/// One object rather than a dozen fields on a widget, because the lifecycle is
/// the thing that keeps going wrong: a notifier nobody disposes is a listener
/// that outlives its screen, and a game carried in a pocket for hours notices.
class GameControllers {
  GameControllers();

  /// Everything that has to be told when the game ends.
  final List<ChangeNotifier> _owned = [];

  /// Registers [controller] for disposal, and hands it straight back.
  ///
  /// Written this way so that a controller is adopted on the line that creates
  /// it — a registration that happens somewhere else is a registration
  /// somebody eventually forgets.
  T adopt<T extends ChangeNotifier>(T controller) {
    _owned.add(controller);
    return controller;
  }

  void dispose() {
    for (final controller in _owned.reversed) {
      controller.dispose();
    }
    _owned.clear();
  }
}
