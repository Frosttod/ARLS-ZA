/// 1 Hz tick engine running in an isolate (design doc §11).
///
/// The simulation is kept off the UI isolate for two reasons. Frame drops
/// during combat are the obvious one; the other is that the engine keeps
/// ticking through a catch-up of hundreds of thousands of seconds after a long
/// absence, and that must not block the map.
///
/// The isolate owns no I/O. It receives state, advances it, and posts the
/// result back; persisting is the main isolate's job through `SaveWriter`.
/// That keeps the engine replayable from a seed plus an event stream (§11.2).
library;

import 'dart:async';
import 'dart:isolate';

import '../core/game_clock.dart';
import 'tick.dart';

/// Message from the host to the engine isolate.
sealed class _EngineCommand {
  const _EngineCommand();
}

class _StartCommand extends _EngineCommand {
  const _StartCommand(this.state, this.constants);

  final SimState state;
  final SimConstants constants;
}

class _AdvanceCommand extends _EngineCommand {
  const _AdvanceCommand({required this.elapsed, required this.offline});

  final Duration elapsed;
  final bool offline;
}

class _SetZoneCommand extends _EngineCommand {
  const _SetZoneCommand(this.zone);

  final MetabolicZone zone;
}

class _StopCommand extends _EngineCommand {
  const _StopCommand();
}

/// State published by the engine after every advance.
class EngineUpdate {
  const EngineUpdate({
    required this.state,
    required this.secondsApplied,
    required this.floored,
    required this.catchUp,
  });

  final SimState state;
  final int secondsApplied;
  final bool floored;

  /// True when this update came from a catch-up rather than the live cadence.
  final bool catchUp;
}

/// Drives the simulation. Owns the isolate, the 1 Hz timer and the clock.
///
/// Lifecycle:
/// ```dart
/// final engine = TickEngine(clock: GameClock());
/// await engine.start(state: loaded, constants: constants);
/// engine.updates.listen(writer.stageHot);   // persist on the host side
/// ...
/// await engine.dispose();
/// ```
class TickEngine {
  TickEngine({
    GameClock? clock,
    this.cadence = const Duration(seconds: 1),
    this.catchUpChunk = const Duration(hours: 1),
  }) : clock = clock ?? GameClock();

  final GameClock clock;

  /// Live tick interval. 1 Hz per §11; developer mode multiplies the elapsed
  /// time rather than this, so the engine never learns about time travel.
  final Duration cadence;

  /// Granularity used when replaying a long absence, so a two-week gap does
  /// not become one giant arithmetic step.
  final Duration catchUpChunk;

  final _updates = StreamController<EngineUpdate>.broadcast();
  Isolate? _isolate;
  SendPort? _toEngine;
  ReceivePort? _fromEngine;
  StreamSubscription<dynamic>? _engineSub;
  Timer? _timer;
  SimState? _latest;
  var _running = false;

  Stream<EngineUpdate> get updates => _updates.stream;

  /// Most recent state the engine published, or null before the first tick.
  SimState? get latest => _latest;

  bool get isRunning => _running;

  /// Spawns the isolate, replays the time missed since [state]`.lastUpdate`
  /// and starts the 1 Hz cadence.
  ///
  /// The catch-up is the first thing that happens, so the player never sees a
  /// stale body for a frame before it corrects (§2.1.1).
  Future<void> start({
    required SimState state,
    required SimConstants constants,
  }) async {
    if (_running) {
      throw StateError('TickEngine already running');
    }

    _latest = state;
    clock.restore(state.lastUpdate);

    final fromEngine = ReceivePort();
    _fromEngine = fromEngine;
    _isolate = await Isolate.spawn(
      _engineMain,
      fromEngine.sendPort,
      debugName: 'arls-za-sim',
    );

    final handshake = Completer<SendPort>();
    _engineSub = fromEngine.listen((message) {
      if (message is SendPort) {
        handshake.complete(message);
        return;
      }
      if (message is EngineUpdate) {
        _latest = message.state;
        if (!_updates.isClosed) _updates.add(message);
      }
    });

    _toEngine = await handshake.future;
    _toEngine!.send(_StartCommand(state, constants));
    _running = true;

    // Catch-up before the live cadence begins.
    final advance = clock.advance(state.lastUpdate);
    if (advance.elapsed > Duration.zero) {
      _toEngine!.send(_AdvanceCommand(elapsed: advance.elapsed, offline: true));
    }

    _timer = Timer.periodic(cadence, (_) => _tick());
  }

  void _tick() {
    final port = _toEngine;
    final state = _latest;
    if (port == null || state == null) return;

    final advance = clock.advance(state.lastUpdate);
    if (advance.isZero) return; // clock rolled back or no whole second yet
    port.send(_AdvanceCommand(elapsed: advance.elapsed, offline: false));
  }

  /// Tells the engine which metabolic zone the character is in (§2.1).
  void setZone(MetabolicZone zone) => _toEngine?.send(_SetZoneCommand(zone));

  /// Forces a catch-up now, for example when the app returns to the foreground.
  void catchUpNow({bool offline = true}) {
    final state = _latest;
    final port = _toEngine;
    if (state == null || port == null) return;
    final advance = clock.advance(state.lastUpdate);
    if (advance.isZero) return;
    port.send(_AdvanceCommand(elapsed: advance.elapsed, offline: offline));
  }

  /// Stops the cadence but keeps the isolate alive, so returning to the
  /// foreground does not pay for a respawn.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (!_running || _timer != null) return;
    catchUpNow();
    _timer = Timer.periodic(cadence, (_) => _tick());
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    _toEngine?.send(const _StopCommand());
    await _engineSub?.cancel();
    _fromEngine?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _running = false;
    await _updates.close();
  }
}

/// Isolate entry point. Holds the current state and answers commands.
void _engineMain(SendPort toHost) {
  final fromHost = ReceivePort();
  toHost.send(fromHost.sendPort);

  SimState? state;
  SimConstants? constants;

  fromHost.listen((message) {
    switch (message) {
      case _StartCommand(state: final initial, constants: final consts):
        state = initial;
        constants = consts;

      case _SetZoneCommand(:final zone):
        state = state?.copyWith(zone: zone);

      case _AdvanceCommand(:final elapsed, :final offline):
        final current = state;
        final consts = constants;
        if (current == null || consts == null) return;

        final outcome = elapsed > const Duration(hours: 1)
            ? advanceInChunks(
                state: current,
                constants: consts,
                elapsed: elapsed,
                offline: offline,
              )
            : advance(
                state: current,
                constants: consts,
                elapsed: elapsed,
                offline: offline,
              );

        state = outcome.state;
        toHost.send(
          EngineUpdate(
            state: outcome.state,
            secondsApplied: outcome.secondsApplied,
            floored: outcome.floored,
            catchUp: offline,
          ),
        );

      case _StopCommand():
        fromHost.close();
    }
  });
}
