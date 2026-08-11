import 'package:arls_za/location/location_access.dart';
import 'package:test/test.dart';

/// §16.1. The point of this table is which answers stop the game — and that
/// refusing background location is not one of them.
void main() {
  LocationAccess access(bool serviceEnabled, PlatformPermission permission) =>
      resolveAccess(serviceEnabled: serviceEnabled, permission: permission);

  test('background permission is the only one that unlocks a dark screen', () {
    expect(access(true, PlatformPermission.always), LocationAccess.granted);
    expect(LocationAccess.granted.pausesInBackground, isFalse);
  });

  test('foreground only is a full variant of the game, not a failure', () {
    const result = LocationAccess.foregroundOnly;

    expect(access(true, PlatformPermission.whileInUse), result);
    expect(result.canPlay, isTrue);
    expect(result.pausesInBackground, isTrue);
    expect(
      result.needsSystemSettings,
      isFalse,
      reason: 'nothing to fix — §16.1 treats this as a supported way to play',
    );
  });

  test('a disabled location service outranks any permission', () {
    // With location off device-wide, a granted permission produces no fixes,
    // and a permission screen would send the player to the wrong page.
    expect(
      access(false, PlatformPermission.always),
      LocationAccess.serviceDisabled,
    );
    expect(
      access(false, PlatformPermission.denied),
      LocationAccess.serviceDisabled,
    );
    expect(LocationAccess.serviceDisabled.needsSystemSettings, isTrue);
  });

  test('a refusal that can be reversed is asked again, not routed away', () {
    expect(access(true, PlatformPermission.denied), LocationAccess.denied);
    expect(LocationAccess.denied.isAskable, isTrue);
    expect(LocationAccess.denied.needsSystemSettings, isFalse);
  });

  test('a permanent refusal is never asked again', () {
    const result = LocationAccess.deniedForever;

    expect(access(true, PlatformPermission.deniedForever), result);
    expect(
      result.isAskable,
      isFalse,
      reason: 'a prompt the system will never show reads as being ignored',
    );
    expect(result.needsSystemSettings, isTrue);
  });

  test('a device that cannot answer yet is asked, not refused', () {
    expect(
      access(true, PlatformPermission.unableToDetermine),
      LocationAccess.denied,
      reason: 'the worst case is one prompt the player dismisses',
    );
  });

  test('refusing background access is not among the states that stop play', () {
    final blocked = LocationAccess.values
        .where((value) => !value.canPlay)
        .toSet();

    expect(blocked, {
      LocationAccess.denied,
      LocationAccess.deniedForever,
      LocationAccess.serviceDisabled,
    });
  });
}
