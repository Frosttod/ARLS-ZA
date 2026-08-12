/// The real GPS, behind the same interface as the simulator (§3.3, §11.2).
///
/// Everything platform-specific stops here. The rest of the game sees a
/// [PositionSource] and cannot tell whether the fixes came from a chip on a
/// phone or from a GPX file being replayed at ×3600.
///
/// Two things this class is careful about:
///
/// * **The foreground service.** A walk lasts an hour with the screen off.
///   Without a foreground service Android stops delivering fixes within
///   minutes, and the session goes on ticking against a position that stopped
///   moving — the worst possible failure, because it looks like the player
///   stood still (§3.3).
/// * **Nothing is filtered here.** The accuracy gate, the Kalman filter and the
///   stationary test live in `FixFilter`, so they apply to the simulator too. A
///   source that quietly cleaned its own output would make the simulator a
///   different code path, which is exactly what §11.2 forbids.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_access.dart';
import 'position_fix.dart';
import 'position_source.dart';

/// Text for the persistent notification the foreground service requires.
///
/// Passed in rather than looked up, because this class has no business
/// reaching into the widget tree for a localisation delegate.
class ForegroundNotice {
  const ForegroundNotice({required this.title, required this.body});

  final String title;
  final String body;
}

class DevicePositionSource extends BasePositionSource {
  DevicePositionSource({required this.notice, super.signalTimeout});

  final ForegroundNotice notice;

  StreamSubscription<Position>? _sub;
  PositionCadence _cadence = PositionCadence.moving;
  LocationAccess _access = LocationAccess.denied;

  /// What the operating system last told us. Reads as [LocationAccess.denied]
  /// until something has actually asked.
  LocationAccess get access => _access;

  /// Whether the foreground service may run. With foreground-only permission
  /// the stream still works, but Android stops it when the app leaves the
  /// screen — which is precisely the behaviour §16.1 describes, so it is left
  /// to happen rather than worked around.
  bool get allowBackground => _access == LocationAccess.granted;

  /// Opens the page the player actually needs: the device location settings
  /// when the service is off, this app's permission page otherwise.
  Future<void> openRelevantSettings() async {
    if (_access == LocationAccess.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    await Geolocator.openAppSettings();
  }

  @override
  bool get isSimulated => false;

  @override
  PositionCadence get currentCadence =>
      _sub == null ? PositionCadence.off : _cadence;

  /// Only with the foreground service, which only runs on the background
  /// permission. With foreground-only access Android stops delivering fixes
  /// when the app leaves the screen (§16.1).
  @override
  bool get tracksInBackground => allowBackground && _sub != null;

  /// Asks the platform where it stands, prompting once if that could help.
  ///
  /// Returns without prompting when the service is off or the refusal is
  /// permanent: a prompt that the system will never show looks to the player
  /// like the game ignoring them.
  Future<LocationAccess> requestAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    var access = resolveAccess(
      serviceEnabled: serviceEnabled,
      permission: _translate(await Geolocator.checkPermission()),
    );

    if (access.isAskable) {
      access = resolveAccess(
        serviceEnabled: serviceEnabled,
        permission: _translate(await Geolocator.requestPermission()),
      );
    }

    _access = access;
    return access;
  }

  @override
  Future<void> start({PositionCadence cadence = PositionCadence.moving}) async {
    _cadence = cadence;

    final access = await requestAccess();
    if (!access.canPlay) {
      markUnavailable();
      return;
    }

    await _listen();
  }

  @override
  Future<void> setCadence(PositionCadence cadence) async {
    if (_cadence == cadence) return;
    _cadence = cadence;

    if (_sub == null) return;
    if (cadence.interval <= Duration.zero) {
      // Shelter occupations run with the GPS off entirely — the character is
      // not moving, so the position is not needed and the radio is the single
      // most expensive thing on the device (§2.1a.4, §3.3).
      await stop();
      return;
    }
    await _listen();
  }

  Future<void> _listen() async {
    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(_onPosition, onError: (_) => emitSignalLoss());
  }

  void _onPosition(Position position) => emitFix(_toFix(position));

  AndroidSettings _settings() => AndroidSettings(
    accuracy: switch (_cadence) {
      // Combat is decided by distance, so pay for the best fix available.
      PositionCadence.combat => LocationAccuracy.best,
      PositionCadence.moving => LocationAccuracy.high,
      // Standing still does not need metres; it needs to know the player is
      // still where they were.
      PositionCadence.resting => LocationAccuracy.medium,
      PositionCadence.off => LocationAccuracy.lowest,
    },
    intervalDuration: _cadence.interval,

    // Zero: the game decides for itself what counts as movement (§3.2). A
    // platform distance filter would silently suppress the very samples the
    // stationary test needs in order to recognise standing still.
    distanceFilter: 0,
    foregroundNotificationConfig: allowBackground
        ? ForegroundNotificationConfig(
            notificationTitle: notice.title,
            notificationText: notice.body,

            // The walk has to keep counting with the screen off. Without the
            // wake lock the fixes stop arriving and the simulation credits the
            // player with standing still (§3.3).
            enableWakeLock: true,
          )
        : null,
  );

  PositionFix _toFix(Position position) => PositionFix(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracyM: position.accuracy,
    timestamp: position.timestamp.toUtc(),
    speedMps: position.speed,
    headingDeg: position.heading,
    altitudeM: position.altitude,

    // Passed through untouched. The decision about what a mocked fix means
    // belongs to `MovementIntegrity` (§3.4), not to the source.
    isMocked: position.isMocked,
  );

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    markUnavailable();
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await super.dispose();
  }
}

PlatformPermission _translate(LocationPermission permission) =>
    switch (permission) {
      LocationPermission.always => PlatformPermission.always,
      LocationPermission.whileInUse => PlatformPermission.whileInUse,
      LocationPermission.denied => PlatformPermission.denied,
      LocationPermission.deniedForever => PlatformPermission.deniedForever,
      LocationPermission.unableToDetermine =>
        PlatformPermission.unableToDetermine,
    };
