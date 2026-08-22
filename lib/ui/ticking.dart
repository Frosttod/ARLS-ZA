/// One second, once, for every bar in the game (§2.1a.3, §3.3).
///
/// ⚠️ **A clock that runs in a pocket is the battery.** This game is carried
/// for hours by design; §3.3 spends a whole section on what the receiver may
/// and may not do while nobody is looking, and then four widgets each made
/// their own `Timer.periodic(1s)` and none of them ever stopped. An empty
/// action strip woke the app three thousand six hundred times an hour to
/// rebuild a `SizedBox.shrink()`.
///
/// Nothing is lost by stopping. Everything these draw is a **deadline** — the
/// search knows when it ends, the bench knows when it ends, the countdown
/// knows when it ends — so coming back settles against the wall clock, which
/// is what opening the app after a night already does.
///
/// Mix in, and say when it is worth ticking.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

mixin Ticking<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Timer? _tick;
  bool _awake = true;

  /// Whether there is anything worth redrawing a second from now.
  ///
  /// Read on every rebuild and on every change of lifecycle, so a widget with
  /// nothing running costs nothing.
  bool get ticking;

  /// How often. A second for anything a person reads; less for a bar that has
  /// to look smooth under a thumb.
  Duration get tickEvery => const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    retime();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    retime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ⚠️ `inactive` is not a background. It is a dialog over the app, the
    // recents view, a call arriving — the screen is still the player's, and a
    // bar that froze behind a permission sheet would read as the game hanging.
    _awake =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;

    retime();
    if (_awake && mounted) setState(() {});
  }

  /// Starts or stops the clock to match [ticking]. Cheap enough to call from
  /// anywhere that changes the answer.
  void retime() {
    final wanted = ticking && _awake;
    if (wanted == (_tick != null)) return;

    _tick?.cancel();
    _tick = wanted
        ? Timer.periodic(tickEvery, (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }
}
