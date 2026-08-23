/// Where a crash goes when nobody is holding a laptop (§16.1).
///
/// ⚠️ **This game is tested by walking around a city with it.** That is the
/// point of it and it is also why every crash so far has been reported as a
/// sentence: "nie można jeść, crash". There was nowhere for a stack trace to
/// go. `main` installed no `FlutterError.onError`, no
/// `PlatformDispatcher.onError` and no zone, so a thrown exception in an
/// `unawaited` handler went to the console of a machine that was not there.
///
/// So it goes to a file, on the external files directory where a phone plugged
/// into a computer shows it without root and without `adb`, and it goes into
/// the app as a red strip the tester can copy from. Both, because a walk that
/// produces a bug and no evidence has to be walked again.
///
/// ⚠️ **Nothing in here may throw.** A crash reporter that crashes turns one
/// lost bug into a launch that never starts, and it runs at precisely the
/// moment the app is already known to be in a bad state. Every path is
/// wrapped, and every failure is silent.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show ErrorWidget;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// One thing that went wrong.
@immutable
class CrashReport {
  const CrashReport({
    required this.at,
    required this.error,
    required this.stack,
    required this.where,
    required this.trail,
  });

  final DateTime at;
  final String error;
  final String stack;

  /// Which mechanism caught it: the framework, the platform, or the zone.
  final String where;

  /// §16.1: what the player was doing just before, in order.
  final List<String> trail;

  String get text =>
      '── ${at.toIso8601String()}  [$where]\n'
      '$error\n'
      '${trail.isEmpty ? '' : 'ostatnie kroki: ${trail.join(' → ')}\n'}'
      '$stack';
}

/// The recorder. One per process, and it is fine for it to be static: there is
/// one process, one player, and one thing that can go wrong at a time.
abstract final class CrashLog {
  /// How many breadcrumbs are kept.
  ///
  /// Twenty is about one action's worth of steps. A longer trail is a longer
  /// file for no more information — what matters is the last thing that
  /// happened, not the last hundred.
  static const int _trailLength = 20;

  /// The cap on the file. Older entries are dropped from the front.
  ///
  /// ⚠️ A phone carried for hours can produce the same crash a thousand times.
  /// Filling the card with it would be a second bug on top of the first.
  static const int _maxBytes = 64 * 1024;

  static const String fileName = 'arlsza-crash.log';

  /// §16.1: where the player had got to, kept through a hang.
  ///
  /// ⚠️ **A separate file, and it exists because a freeze is not a crash.**
  /// Reported from the field as SIGQUIT and a tombstone — Android's own words
  /// for "this app stopped answering". Nothing was thrown, so [reports] stayed
  /// empty and the crash log had nothing to say.
  ///
  /// A hang leaves no exception. What it leaves is the last thing that
  /// happened before the main thread stopped, and that is only useful if it
  /// reached the disk *before* everything stopped. So the trail is flushed as
  /// it is written, and read back on the next launch.
  static const String stepsFileName = 'arlsza-steps.log';

  /// What has gone wrong this session, newest last. Watched by the strip.
  static final ValueNotifier<List<CrashReport>> reports = ValueNotifier(
    const [],
  );

  static final List<String> _trail = [];

  static File? _file;
  static File? _steps;
  static bool _installed = false;

  /// The trail the previous run ended on, or null when it ended cleanly.
  ///
  /// Read once at startup. Non-null here means the last session stopped
  /// without clearing up after itself — a kill, or a hang. Watched rather than
  /// read, because it arrives from a file after the first frame is drawn.
  static final ValueNotifier<String?> lastRun = ValueNotifier(null);

  /// ⚠️ Debounced, because a heartbeat that writes to flash every tick is a
  /// second performance bug bolted to the diagnosis of the first. One write a
  /// second is far below anything that matters and far above the resolution
  /// needed to see which step it stopped on.
  static DateTime? _flushedAt;
  static bool _flushing = false;

  /// §16.1: notes what the player just did, for the trail on the next crash.
  ///
  /// Deliberately a plain string rather than a structured event: it is read by
  /// a person trying to work out where to look, never by code.
  static void note(String step) {
    _trail.add(step);
    if (_trail.length > _trailLength) _trail.removeAt(0);

    _flushTrail();
  }

  /// §16.1: the heartbeat, for anything that runs on a clock.
  ///
  /// The same as [note] except that it replaces the previous beat rather than
  /// adding to the trail — a meal that ticks seventy-five times would
  /// otherwise push everything that led up to it out of a twenty-step ring.
  /// What is wanted is "it was still alive at second forty", not forty lines
  /// saying so.
  static void beat(String step) {
    if (_trail.isNotEmpty && _trail.last.startsWith('~')) {
      _trail.removeLast();
    }
    note('~$step');
  }

  /// Puts the trail where a hang cannot take it with it.
  static void _flushTrail() {
    if (_flushing) return;

    final now = DateTime.now();
    final last = _flushedAt;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _flushedAt = now;
    _flushing = true;

    unawaited(() async {
      try {
        final file = _steps ?? await _openSteps();
        await file?.writeAsString(
          '${now.toIso8601String()}\n${_trail.join('\n')}\n',
          flush: true,
        );
      } on Object {
        // Nothing.
      } finally {
        _flushing = false;
      }
    }());
  }

  /// Reads what the last run was doing, and starts a clean trail.
  ///
  /// Called once, on the way up. An empty file means the last session put its
  /// own trail away — see [settled].
  static Future<void> readLastRun() async {
    try {
      final file = _steps ?? await _openSteps();
      if (file == null || !file.existsSync()) return;

      final text = await file.readAsString();
      lastRun.value = text.trim().isEmpty ? null : text.trim();

      await file.writeAsString('');
    } on Object {
      // Nothing.
    }
  }

  /// Says the app is going down on purpose, so the next launch does not
  /// report the last step as the place it hung.
  static Future<void> settled() async {
    _trail.clear();

    try {
      final file = _steps ?? await _openSteps();
      if (file != null && file.existsSync()) await file.writeAsString('');
    } on Object {
      // Nothing.
    }
  }

  /// Catches everything Flutter has a hook for.
  ///
  /// ⚠️ Must be called **inside** the zone that [guard] establishes, so that
  /// the three mechanisms all end up in the same place.
  static void install() {
    if (_installed) return;
    _installed = true;

    final wasFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      record(
        details.exception,
        details.stack,
        where: 'flutter',
        context: details.context?.toDescription(),
      );
      wasFlutter?.call(details);
    };

    // Errors from platform callbacks and from futures nobody awaited that the
    // zone does not see.
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, where: 'platform');
      return true;
    };

    // ⚠️ A build that throws paints a red box and takes its message with it.
    // Recorded here so the strip can say what it was, then handed on to the
    // default so the screen still looks the way Flutter intended.
    final wasWidget = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      record(
        details.exception,
        details.stack,
        where: 'build',
        context: details.context?.toDescription(),
      );
      return wasWidget(details);
    };

    unawaited(_openFile());
  }

  /// Runs [body] in a zone that catches whatever escapes an `unawaited` call.
  ///
  /// That is most of this codebase's async surface: a tap handler is
  /// `unawaited(_use(line))`, and its error has nowhere else to go.
  static void guard(void Function() body) {
    runZonedGuarded(body, (error, stack) {
      record(error, stack, where: 'zone');
    });
  }

  /// Writes one down. Never throws, whatever is handed to it.
  static void record(
    Object error,
    StackTrace? stack, {
    required String where,
    String? context,
  }) {
    try {
      final report = CrashReport(
        at: DateTime.now(),
        error: context == null ? '$error' : '$error\n  ($context)',
        stack: '${stack ?? StackTrace.current}',
        where: where,
        trail: List.unmodifiable(_trail),
      );

      // ⚠️ In memory first. The file is a future and the app may not survive
      // long enough for it to complete; the strip only needs this list.
      reports.value = [...reports.value, report];

      if (kDebugMode) {
        debugPrint('CRASH [$where] $error');
      }

      unawaited(_append(report));
    } on Object {
      // Deliberately nothing. See the note at the top of the library.
    }
  }

  /// Everything on disk, or null when there is nothing or it cannot be read.
  static Future<String?> readAll() async {
    try {
      final file = _file ?? await _openFile();
      if (file == null || !file.existsSync()) return null;

      final text = await file.readAsString();
      return text.isEmpty ? null : text;
    } on Object {
      return null;
    }
  }

  /// Where the tester will find it with a USB cable.
  static Future<String?> path() async {
    final file = _file ?? await _openFile();
    return file?.path;
  }

  /// Throws the lot away, on disk and in memory.
  static Future<void> clear() async {
    reports.value = const [];
    lastRun.value = null;
    _trail.clear();

    try {
      final file = _file ?? await _openFile();
      if (file != null && file.existsSync()) await file.writeAsString('');

      final steps = _steps ?? await _openSteps();
      if (steps != null && steps.existsSync()) await steps.writeAsString('');
    } on Object {
      // Nothing. A log that will not clear is not worth a crash.
    }
  }

  static Future<File?> _openSteps() async {
    if (_steps != null) return _steps;

    final directory = await _directory();
    if (directory == null) return null;

    try {
      final file = File(p.join(directory.path, stepsFileName));
      if (!file.existsSync()) await file.create(recursive: true);
      return _steps = file;
    } on Object {
      return null;
    }
  }

  static Future<Directory?> _directory() async {
    try {
      // ⚠️ External files first, and only on Android. That directory shows up
      // over USB in any file manager, which is the difference between a tester
      // who can hand over a trace and one who cannot.
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      return directory ?? await getApplicationSupportDirectory();
    } on Object {
      return null;
    }
  }

  static Future<File?> _openFile() async {
    if (_file != null) return _file;

    final directory = await _directory();
    if (directory == null) return null;

    try {
      final file = File(p.join(directory.path, fileName));
      if (!file.existsSync()) await file.create(recursive: true);

      return _file = file;
    } on Object {
      return null;
    }
  }

  static Future<void> _append(CrashReport report) async {
    try {
      final file = _file ?? await _openFile();
      if (file == null) return;

      await file.writeAsString(
        '${report.text}\n\n',
        mode: FileMode.append,
        flush: true,
      );

      // Trimmed after the write rather than before: the newest entry is the
      // one somebody is waiting for, and it goes down first.
      final length = await file.length();
      if (length > _maxBytes) {
        final text = await file.readAsString();
        await file.writeAsString(text.substring(text.length - _maxBytes ~/ 2));
      }
    } on Object {
      // Nothing.
    }
  }
}
