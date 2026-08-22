/// Everything the operating system has to allow before the game can measure
/// anything (§3.3, §16.1).
///
/// Three separate switches, and a player who has granted one often assumes they
/// have granted all three:
///
/// * **Location.** Without it there is no game.
/// * **Location in the background.** Without it the simulation stops when the
///   screen does — a supported way to play (§16.1), but the player should know
///   they chose it.
/// * **Battery optimisation.** The quiet one. Android throttles a background
///   app it considers idle, the fixes stop arriving, and nothing announces it:
///   the walk simply does not count. This is the setting that makes a foreground
///   service actually keep running, and no permission dialog ever mentions it.
///
/// Reported together because they fail together, and a screen that shows only
/// the first two would leave the third to be discovered after an hour's walk
/// that recorded nothing.
library;

import 'device_position_source.dart';
import 'package:flutter/services.dart';

import 'location_access.dart';

/// What the system currently allows.
class SystemPermissions {
  const SystemPermissions({
    required this.location,
    required this.batteryOptimised,
  });

  final LocationAccess location;

  /// True when Android may still throttle the app in the background. Null when
  /// the platform would not say — treated as "probably fine" rather than
  /// warned about, since a false alarm here teaches players to ignore it.
  final bool? batteryOptimised;

  /// Whether a walk with the screen off will actually be counted.
  bool get backgroundWorks =>
      location == LocationAccess.granted && batteryOptimised != true;

  /// Whether anything is worth asking the player about.
  bool get hasSomethingToFix =>
      !location.canPlay ||
      location == LocationAccess.foregroundOnly ||
      batteryOptimised == true;
}

/// Reads and opens the system settings the game depends on.
class SystemSettings {
  const SystemSettings();

  static const MethodChannel _channel = MethodChannel(
    'com.raidodevelopment.arlsza/storage',
  );

  Future<bool?> isBatteryOptimised() async {
    try {
      return await _channel.invokeMethod<bool>('isBatteryOptimised');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // A desktop developer build.
      return null;
    }
  }

  /// Opens the system list of apps exempt from battery optimisation.
  ///
  /// The list rather than the direct request dialog: that needs a permission
  /// Google restricts to apps whose core function cannot work without it, and
  /// a rejected listing is worse than one extra tap.
  Future<void> openBatterySettings() => _invoke('openBatterySettings');

  Future<void> openAppSettings() => _invoke('openAppSettings');

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // Nothing useful to do: the player is already looking at a screen that
      // says what is wrong.
    } on MissingPluginException {
      // Desktop.
    }
  }
}

/// What the operating system will say about us, behind one seam (§16.1).
///
/// ⚠️ Exists so the game screen can be built in a test. `_boot` awaits the
/// location permission and the battery setting, and both are platform
/// channels — in a test they never answer, so the whole screen stayed blank
/// and the orchestration in `main.dart` had no test at all. That was not a
/// missing test; it was a missing seam.
///
/// The default is the real device. Nothing in the game passes anything else.
abstract class SystemProbe {
  const SystemProbe();

  Future<SystemPermissions> read();
}

/// The real one.
class DeviceSystemProbe extends SystemProbe {
  const DeviceSystemProbe();

  @override
  Future<SystemPermissions> read() async => SystemPermissions(
    // checkPermission only; asking here would fire a prompt every time the
    // settings screen is opened.
    location: await currentLocationAccess(),
    batteryOptimised: await const SystemSettings().isBatteryOptimised(),
  );
}
