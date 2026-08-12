/// Compile-time gate for developer mode (design doc §11.2).
///
/// Developer mode can force GPS positions, multiply time by 3600 and set any
/// physiological value. Shipping that to players would make every balance
/// figure and every survival streak meaningless, so it must be **absent from
/// the release binary**, not merely hidden behind a menu.
///
/// The gate is a `const bool`, which is what makes it work: Dart's AOT
/// compiler treats `if (kDevTools) { ... }` with a const false condition as
/// dead code and removes the branch and everything only it reaches.
///
/// Default: on in debug and profile builds, off in release. Override either
/// way from the command line:
///
/// ```bash
/// flutter build apk --release --dart-define=arls.devtools=true   # opt in
/// flutter run --dart-define=arls.devtools=false                  # opt out
/// ```
///
/// `test/devtools/release_strip_test.dart` and the `devtools-stripped` CI job
/// check the actual artifact rather than trusting this comment.
library;

/// Explicit override, when the caller passed `--dart-define=arls.devtools=...`.
const bool _override = bool.fromEnvironment(_overrideKey, defaultValue: false);
const bool _overrideSet = bool.hasEnvironment(_overrideKey);
const String _overrideKey = 'arls.devtools';

/// True in a release build.
///
/// Read straight from the VM define rather than through
/// `package:flutter/foundation.dart`. Importing Flutter here would drag
/// `dart:ui` into the position simulator and the recorder, which have to stay
/// loadable from `dart test` and from an isolate — the same trap the
/// persistence layer hit in stage 0.
const bool _isReleaseBuild = bool.fromEnvironment('dart.vm.product');

/// Whether developer mode is compiled in.
///
/// Must stay `const` — a runtime `bool` would keep every devtools class alive
/// in the release binary.
const bool kDevTools = _overrideSet ? _override : !_isReleaseBuild;

/// Marker string used to prove the stripping worked.
///
/// Unique enough to grep for, and reachable only from code guarded by
/// [kDevTools]. If this shows up in a release APK, the gate leaked and the
/// build is not shippable.
const String kDevToolsMarker = 'ARLS_DEVTOOLS_PRESENT_7f3a91c4';

/// Throws when devtools code is reached in a build that should not contain it.
///
/// Belt and braces: the compile-time gate is the real defence, this catches a
/// mistake where someone calls into devtools without checking [kDevTools].
void assertDevTools([String? what]) {
  if (!kDevTools) {
    throw StateError(
      'Developer-mode code reached in a build without devtools'
      '${what == null ? '' : ' ($what)'}. This is a build configuration bug.',
    );
  }
}

/// Runs [body] only when devtools are compiled in.
///
/// Prefer a plain `if (kDevTools)` at the call site where the whole block
/// should vanish; use this where a value is needed inline.
T? whenDevTools<T>(T Function() body) => kDevTools ? body() : null;

/// Whether the developer simulator is driving the position (§11.2).
///
/// Stored as a player setting rather than decided by the build, because a
/// debug build has two jobs and they want opposite sources. Balancing §2 needs
/// a GPX track at ×3600; walking the streets to test §3.2 needs the chip. A
/// build that silently picks the simulator makes the second job look broken —
/// no permission prompt, and a position somewhere the player has never been.
///
/// Default off. The simulator is opted into, never fallen into. Release builds
/// ignore this entirely: [kDevTools] is false and there is no simulator to
/// reach.
const String kSimulatorSettingKey = 'dev.simulator';

bool simulatorEnabled(String? storedValue) =>
    kDevTools && storedValue == 'true';
