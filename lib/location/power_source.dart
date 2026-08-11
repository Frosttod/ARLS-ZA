/// What the battery is doing (design doc §3.3).
///
/// An interface rather than a direct plugin call, for the same reason the
/// position has one: the game loop must be drivable from a test without a
/// phone, and a session recorded in the field has to replay with the battery
/// levels it actually had.
library;

/// A battery reading.
class PowerState {
  const PowerState({required this.percent, required this.charging});

  /// Full and plugged in. Used when nothing is reporting, so a missing reader
  /// never pushes the game into economy mode by accident.
  static const PowerState unknown = PowerState(percent: 100, charging: true);

  final int percent;
  final bool charging;
}

abstract class PowerSource {
  Future<PowerState> read();
}

/// Always reports a full, charging battery. The default for tests and for the
/// simulator, where power is not what is being studied.
class ConstantPowerSource implements PowerSource {
  const ConstantPowerSource([this.state = PowerState.unknown]);

  final PowerState state;

  @override
  Future<PowerState> read() async => state;
}
