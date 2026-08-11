/// The real battery, behind [PowerSource] (§3.3).
///
/// Thin on purpose: every decision made from these two numbers lives in
/// `SamplingPolicy`, where it can be tested.
library;

import 'package:battery_plus/battery_plus.dart';

import 'power_source.dart';

class DevicePowerSource implements PowerSource {
  DevicePowerSource();

  final Battery _battery = Battery();

  @override
  Future<PowerState> read() async {
    try {
      final percent = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      return PowerState(
        percent: percent,
        charging: state == BatteryState.charging || state == BatteryState.full,
      );
    } on Object {
      // Some devices refuse to answer. Reporting a full battery is the safe
      // failure: the game keeps sampling normally rather than dropping into
      // economy mode because a platform channel misbehaved.
      return PowerState.unknown;
    }
  }
}
