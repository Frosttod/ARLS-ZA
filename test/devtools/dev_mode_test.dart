import 'package:arls_za/devtools/dev_mode.dart';
import 'package:test/test.dart';

/// The gate itself. Whether it actually removes code from a release binary is
/// checked against the built APK by `tool/check_release_strip.dart`, because a
/// unit test cannot see inside a compiled artifact.
void main() {
  group('kDevTools', () {
    test('is on under the test runner, which is a debug VM', () {
      expect(
        kDevTools,
        isTrue,
        reason:
            'tests exercise devtools code; a false here means the '
            'dart.vm.product define leaked into the test VM',
      );
    });

    test('assertDevTools passes when devtools are compiled in', () {
      expect(() => assertDevTools('test'), returnsNormally);
    });

    test('whenDevTools runs the body', () {
      expect(whenDevTools(() => 42), 42);
    });

    test('the marker is distinctive enough to grep for in a binary', () {
      expect(kDevToolsMarker, startsWith('ARLS_DEVTOOLS_PRESENT_'));
      expect(
        kDevToolsMarker.length,
        greaterThanOrEqualTo(24),
        reason: 'a short marker would collide with unrelated bytes',
      );
      expect(
        RegExp(r'^[A-Za-z0-9_]+$').hasMatch(kDevToolsMarker),
        isTrue,
        reason: 'must survive as a plain ASCII string constant',
      );
    });
  });
}
