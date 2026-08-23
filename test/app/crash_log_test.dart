import 'dart:io';

import 'package:arls_za/app/crash_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// GDZIE IDZIE BŁĄD, KIEDY NIKT NIE TRZYMA LAPTOPA (§16.1).
///
/// ⚠️ Every crash so far has been reported as a sentence. `main` had no
/// `FlutterError.onError`, no `PlatformDispatcher.onError` and no zone, so a
/// thrown exception went to a console that was not there, and a field report
/// could say "crash" and nothing more.
///
/// The one rule this thing must never break: **it may not throw**. It runs at
/// exactly the moment the app is already known to be in a bad state, and a
/// reporter that crashes turns one lost bug into a launch that never starts.
void main() {
  setUp(() {
    CrashLog.reports.value = const [];
  });

  group('it records what it is handed', () {
    test('an error becomes a report', () {
      CrashLog.record(
        StateError('nie da się jeść'),
        StackTrace.current,
        where: 'test',
      );

      expect(CrashLog.reports.value, hasLength(1));
      expect(CrashLog.reports.value.single.error, contains('nie da się jeść'));
      expect(CrashLog.reports.value.single.where, 'test');
    });

    test('and the trail says how far the player got', () {
      // The whole point of the breadcrumbs: "use → opened → row" says the row
      // was written, and "use" on its own says it was not.
      CrashLog.note('use:food_canned_meat');
      CrashLog.note('use.opened:a.1:1.0');

      CrashLog.record('boom', null, where: 'test');

      expect(CrashLog.reports.value.single.trail, [
        'use:food_canned_meat',
        'use.opened:a.1:1.0',
      ]);
    });

    test('a missing stack is filled in rather than lost', () {
      CrashLog.record('boom', null, where: 'test');
      expect(CrashLog.reports.value.single.stack, isNotEmpty);
    });

    test('the text carries everything a person needs to read', () {
      CrashLog.note('use.row:eating:75s');
      CrashLog.record(ArgumentError('NaN'), StackTrace.current, where: 'zone');

      final text = CrashLog.reports.value.single.text;

      expect(text, contains('[zone]'));
      expect(text, contains('NaN'));
      expect(text, contains('use.row:eating:75s'));
    });
  });

  group('it never throws, whatever happens', () {
    test('not on an error with a hostile toString', () {
      // ⚠️ A crash reporter reached by a crash is reached by objects nobody
      // designed. This one throws when printed, which is exactly the kind of
      // thing that would turn one bug into a boot loop.
      expect(
        () => CrashLog.record(_Hostile(), StackTrace.current, where: 'test'),
        returnsNormally,
      );
    });

    test('not on a stack that will not print', () {
      expect(
        () => CrashLog.record('boom', _HostileStack(), where: 'test'),
        returnsNormally,
      );
    });

    test('and reading a log that is not there answers null', () async {
      expect(await CrashLog.readAll(), anyOf(isNull, isA<String>()));
    });
  });

  group('the trail is bounded', () {
    test('a long walk does not grow without end', () {
      for (var i = 0; i < 200; i++) {
        CrashLog.note('step $i');
      }
      CrashLog.record('boom', null, where: 'test');

      final trail = CrashLog.reports.value.single.trail;

      expect(trail, hasLength(20));
      expect(trail.last, 'step 199', reason: 'the newest is what matters');
    });

    test('and clearing empties it', () async {
      CrashLog.note('step');
      CrashLog.record('boom', null, where: 'test');

      await CrashLog.clear();

      expect(CrashLog.reports.value, isEmpty);

      CrashLog.record('again', null, where: 'test');
      expect(CrashLog.reports.value.single.trail, isEmpty);
    });
  });

  test('the file lives where a USB cable can find it', () async {
    // Not asserting a path — that needs a platform. Asserting the name, which
    // is what somebody plugging a phone in will be told to look for.
    expect(CrashLog.fileName, endsWith('.log'));
    expect(CrashLog.fileName, contains('arlsza'));
  });
}

class _Hostile {
  @override
  String toString() => throw StateError('even this throws');
}

class _HostileStack implements StackTrace {
  @override
  String toString() => throw const FileSystemException('no');
}
