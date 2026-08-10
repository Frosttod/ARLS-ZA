/// Wires developer mode into the running app (design doc §11.2).
///
/// One place where the whole subsystem is constructed, behind one
/// `if (kDevTools)`. Everything it touches — the simulator, the recorder, the
/// panels — is reachable only from here, which is what lets the compiler drop
/// the lot from a release build.
///
/// ⚠️ [attach] must stay the only entry point. A second call site that forgets
/// the guard would put the GPS simulator in players' hands, and
/// `tool/check_release_strip.dart` is what catches that.
library;

import '../core/deterministic_rng.dart';
import '../core/game_clock.dart';
import '../core/scaled_wall_clock.dart';
import '../sim/tick.dart';
import 'dev_console.dart';
import 'dev_mode.dart';
import 'dev_overlay.dart';
import 'session_recorder.dart';
import 'simulated_position_source.dart';

/// Everything developer mode owns for the lifetime of the app.
class DevSession {
  DevSession._({
    required this.clock,
    required this.source,
    required this.console,
    required this.gameClock,
  });

  final ScaledWallClock clock;
  final SimulatedPositionSource source;
  final DevConsole console;

  /// The game clock reading [clock], handed to the tick engine in place of the
  /// real-time one.
  final GameClock gameClock;

  /// Builds the developer session, or returns null in a build without devtools.
  ///
  /// The null return is what makes the call site collapse: in release,
  /// `kDevTools` is a const false, so the whole body and everything it
  /// references becomes unreachable.
  static DevSession? attach({
    required SimConstants constants,
    int rngSeed = 20260810,
  }) {
    if (!kDevTools) return null;

    final clock = ScaledWallClock();
    final source = SimulatedPositionSource(
      clock: clock,
      rng: DeterministicRng(seed: rngSeed).stream(RngStream.world),
    );

    return DevSession._(
      clock: clock,
      source: source,
      console: DevConsole(clock: clock, source: source, constants: constants),
      gameClock: GameClock(wallClock: clock),
    );
  }

  /// Starts the simulated GPS.
  Future<void> start() => source.start();

  /// Begins recording, so a session can be replayed later (§11.2).
  void record(SimState initialState, {String? note}) {
    console.startRecording(
      RecordingHeader(
        version: kRecordingVersion,
        rngSeed: console.constants.hashCode,
        startedAt: clock.nowUtc(),
        constants: console.constants,
        initialState: initialState,
        note: note,
      ),
    );
  }

  /// A one-line description used by the diagnostic overlay. Also the only live
  /// reference to [kDevToolsMarker], which is how the release-strip check has
  /// something to look for.
  String describe() => describeDevTools(gameClock);

  Future<void> dispose() async {
    console.dispose();
    await source.dispose();
  }
}
