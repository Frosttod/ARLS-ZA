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

  /// What has gone wrong this session, newest last. Watched by the strip.
  static final ValueNotifier<List<CrashReport>> reports = ValueNotifier(
    const [],
  );

  static final List<String> _trail = [];

  static File? _file;
  static bool _installed = false;

  /// §16.1: notes what the player just did, for the trail on the next crash.
  ///
  /// Deliberately a plain string rather than a structured event: it is read by
  /// a person trying to work out where to look, never by code.
  static void note(String step) {
    _trail.add(step);
    if (_trail.length > _trailLength) _trail.removeAt(0);
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
    _trail.clear();

    try {
      final file = _file ?? await _openFile();
      if (file != null && file.existsSync()) await file.writeAsString('');
    } on Object {
      // Nothing. A log that will not clear is not worth a crash.
    }
  }

  static Future<File?> _openFile() async {
    if (_file != null) return _file;

    try {
      // ⚠️ External files first, and only on Android. That directory shows up
      // over USB in any file manager, which is the difference between a tester
      // who can hand over a stack trace and one who cannot.
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      directory ??= await getApplicationSupportDirectory();

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
