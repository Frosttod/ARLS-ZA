/// Verifies that developer-mode code is absent from a release artifact.
///
/// Stage 1's exit criterion says the release build must not contain a single
/// line of developer code (design doc §11.2). A comment claiming that is worth
/// nothing; this reads the actual file.
///
/// The check looks for [kDevToolsMarker], a string constant reachable only
/// from code guarded by `kDevTools`. If Dart's tree shaker did its job the
/// marker is gone, along with the GPS simulator, the time accelerator and the
/// physiology panel.
///
/// ```bash
/// flutter build apk --release
/// dart run tool/check_release_strip.dart build/app/outputs/flutter-apk/app-release.apk
/// ```
///
/// Exit code 0 when clean, 1 when the marker was found, 2 on a usage error.
library;

import 'dart:io';

import 'package:arls_za/devtools/dev_mode.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/check_release_strip.dart <artifact>\n'
      '  artifact: an .apk, .aab or a raw libapp.so',
    );
    exit(2);
  }

  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('not found: ${file.path}');
    exit(2);
  }

  final bytes = await file.readAsBytes();
  final needle = kDevToolsMarker.codeUnits;
  final at = _indexOf(bytes, needle);

  final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);

  if (at >= 0) {
    stderr.writeln(
      'FAIL: found "$kDevToolsMarker" at offset $at in ${file.path} '
      '($sizeMb MB).\n'
      'Developer mode leaked into a release build. Something reaches devtools '
      'code without an `if (kDevTools)` guard, or the gate stopped being const.',
    );
    exit(1);
  }

  stdout.writeln(
    'OK: no devtools marker in ${file.path} ($sizeMb MB). '
    'Developer mode is stripped.',
  );
}

/// Plain byte search. The artifact is tens of megabytes, so this runs once and
/// nobody cares that it is not Boyer–Moore.
int _indexOf(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || needle.length > haystack.length) return -1;
  final first = needle.first;
  final limit = haystack.length - needle.length;

  outer:
  for (var i = 0; i <= limit; i++) {
    if (haystack[i] != first) continue;
    for (var j = 1; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
