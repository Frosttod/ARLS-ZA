/// What the operating system is willing to tell us about where we are (§16.1).
///
/// Kept away from the plugin on purpose. The mapping from Android's permission
/// states to what the game may do is a policy decision, and policy that lives
/// inside a plugin call cannot be tested without a phone.
///
/// The design document is explicit that refusing background location is not a
/// failure state: foreground-only is a full variant of the game, with the
/// session paused while the app is away rather than the player being nagged
/// (§16.1). What does stop play is having no location at all: refused, refused
/// permanently, or switched off device-wide.
library;

/// How much location access the game currently has.
enum LocationAccess {
  /// Background location granted: a walk keeps counting with the screen off.
  granted,

  /// Foreground only. The session runs while the app is on screen and pauses
  /// when it is not — a full variant of the game, not a broken one (§16.1).
  foregroundOnly,

  /// Asked and refused, but askable again.
  denied,

  /// Refused permanently, or blocked by policy. Only the system settings screen
  /// can change this, so that is what the game offers.
  deniedForever,

  /// Location is switched off device-wide. Nothing to do with this app, and the
  /// player has to be told that rather than shown a permission prompt that will
  /// never appear.
  serviceDisabled,
}

extension LocationAccessRules on LocationAccess {
  /// Whether fixes will arrive at all.
  bool get canPlay =>
      this == LocationAccess.granted || this == LocationAccess.foregroundOnly;

  /// Whether the session has to stop when the app leaves the screen.
  bool get pausesInBackground => this == LocationAccess.foregroundOnly;

  /// Whether asking again could change the answer. When it cannot, the game
  /// sends the player to the system settings instead of prompting.
  bool get isAskable => this == LocationAccess.denied;

  /// Whether the problem is the device rather than this app.
  bool get needsSystemSettings =>
      this == LocationAccess.deniedForever ||
      this == LocationAccess.serviceDisabled;
}

/// The permission states the platform reports, named so the mapping below can
/// be read and tested without the plugin.
///
/// These mirror `geolocator`'s `LocationPermission`. The duplication is
/// deliberate: it is the seam that keeps the policy testable.
enum PlatformPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

/// Turns the platform's answer into what the game may do.
///
/// A disabled location service outranks everything: with it off, a granted
/// permission produces no fixes, and showing the player a permission screen
/// would send them to the wrong settings page.
LocationAccess resolveAccess({
  required bool serviceEnabled,
  required PlatformPermission permission,
}) {
  if (!serviceEnabled) return LocationAccess.serviceDisabled;

  return switch (permission) {
    PlatformPermission.always => LocationAccess.granted,
    PlatformPermission.whileInUse => LocationAccess.foregroundOnly,
    PlatformPermission.denied => LocationAccess.denied,
    PlatformPermission.deniedForever => LocationAccess.deniedForever,
    // Some devices cannot answer until asked once. Treat that as askable
    // rather than as a refusal; the worst case is one prompt the player
    // dismisses.
    PlatformPermission.unableToDetermine => LocationAccess.denied,
  };
}
