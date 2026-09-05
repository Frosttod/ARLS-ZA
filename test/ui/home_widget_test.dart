import 'package:arls_za/game/home_status.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/l10n/app_localizations_pl.dart';
import 'package:arls_za/ui/effects.dart';
import 'package:arls_za/ui/home_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// §13.1. The widget lives on a launcher that redraws when told to, so what
/// matters here is what is sent and — much more — how often.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final L10n l10n = L10nPl();
  final t0 = DateTime.utc(2026, 9, 4, 21);

  HomeStatus statusOf({
    int water = 80,
    int bpm = 70,
    List<Ailment> ailments = const [],
    DateTime? at,
  }) => HomeStatus(
    waterPct: water,
    kcalPct: 90,
    sleepPct: 60,
    bpm: bpm,
    ailments: ailments,
    at: at ?? t0,
  );

  group('what the launcher is handed', () {
    test('four numbers, three labels, and one line of what is wrong', () {
      final wire = wireOf(
        statusOf(ailments: const [Ailment.bleeding, Ailment.enemy]),
        l10n,
      );

      expect(wire['water'], 80);
      expect(wire['kcal'], 90);
      expect(wire['sleep'], 60);
      expect(wire['bpm'], 70);
      expect(wire['waterLabel'], l10n.hudWater);
      expect(
        wire['ailments'],
        '${l10n.widgetBleeding}$kTightGap${l10n.widgetEnemy}',
      );
      expect(wire['at'], t0.millisecondsSinceEpoch);
    });

    test('and when nothing is wrong it says so, rather than nothing', () {
      // ⚠️ A blank line reads as a broken widget. "Nic nie dolega" reads as a
      // game that is still counting.
      final wire = wireOf(statusOf(), l10n);

      expect(wire['ailments'], '');
      expect(wire['ok'], l10n.widgetNothingWrong);
    });

    test('a fourth complaint is counted, not listed', () {
      final wire = wireOf(
        statusOf(
          ailments: const [
            Ailment.bleeding,
            Ailment.enemy,
            Ailment.microsleeps,
            Ailment.thirsty,
            Ailment.sleepless,
          ],
        ),
        l10n,
      );

      expect(wire['ailments'], endsWith('+2'));
    });
  });

  group('the throttle, which is the whole reason this class exists', () {
    late List<MethodCall> sent;
    late HomeWidget widget;

    setUp(() {
      sent = [];
      const channel = MethodChannel(kWidgetChannel);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            sent.add(call);
            return null;
          });
      widget = HomeWidget(channel: channel);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(kWidgetChannel), null);
    });

    test('the first reading always goes', () async {
      expect(await widget.push(statusOf(), l10n), isTrue);
      expect(sent.single.method, 'widget.push');
    });

    test('and a second identical one does not', () async {
      // The loop publishes about once a second. A launcher redraw at that rate
      // is a battery complaint with a widget attached.
      await widget.push(statusOf(), l10n);
      final again = await widget.push(
        statusOf(at: t0.add(const Duration(seconds: 1))),
        l10n,
      );

      expect(again, isFalse);
      expect(sent, hasLength(1));
    });

    test('a figure the player can see changing does go', () async {
      await widget.push(statusOf(bpm: 70), l10n);
      final beating = await widget.push(
        statusOf(bpm: 118, at: t0.add(const Duration(seconds: 1))),
        l10n,
      );

      expect(beating, isTrue);
      expect(sent, hasLength(2));
    });

    test('and an unchanged reading is resent on the heartbeat', () async {
      // ⚠️ Otherwise a game that is running looks exactly like one that
      // stopped: the widget draws "how long ago" from the timestamp, so the
      // timestamp has to keep arriving.
      await widget.push(statusOf(), l10n);
      final later = await widget.push(
        statusOf(at: t0.add(kWidgetHeartbeat + const Duration(seconds: 1))),
        l10n,
      );

      expect(later, isTrue);
      expect(sent, hasLength(2));
    });
  });

  test('a platform with no widget behind it is not an error', () async {
    // A desktop developer build, or a launcher that refused. Neither is worth
    // interrupting a walk over.
    const channel = MethodChannel(kWidgetChannel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    expect(await HomeWidget(channel: channel).push(statusOf(), l10n), isFalse);
  });
}
