/// The controllers, reachable from anywhere below them.
///
/// ⚠️ **Not a state-management framework, and deliberately not.** This
/// codebase already has its idiom — `ValueNotifier` read through
/// `ValueListenableBuilder`, nineteen hundred tests built on it, and two
/// controllers ([PositionController], [ActionRunner]) already written to that
/// shape. What was missing was not a framework: it was somewhere to put the
/// controllers so that a screen can find one without being handed it through
/// six constructors.
///
/// So: an `InheritedWidget`, which is what a framework would have wrapped
/// anyway, and nothing else.
library;

import 'package:flutter/widgets.dart';

import 'game_controllers.dart';

class GameScope extends InheritedWidget {
  const GameScope({
    required this.controllers,
    required super.child,
    super.key,
  });

  final GameControllers controllers;

  /// The controllers for the running game.
  ///
  /// ⚠️ Throws rather than returning null. A screen that needs the game and is
  /// built outside it is a wiring mistake, and a null that travels five frames
  /// before it fails is a wiring mistake nobody can find.
  static GameControllers of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'No GameScope above this widget');
    return scope!.controllers;
  }

  /// The controllers, or null outside a running game.
  ///
  /// For the few things that are drawn both inside and outside — a notice, a
  /// settings sheet — rather than as a way to avoid thinking about which.
  static GameControllers? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()?.controllers;

  @override
  bool updateShouldNotify(GameScope oldWidget) =>
      controllers != oldWidget.controllers;
}
