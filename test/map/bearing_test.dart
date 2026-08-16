import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// Which way one point lies from another (§3.6).
///
/// The sign of this is the kind of thing that is wrong silently: a cone drawn
/// a quarter turn out points at nothing in particular and looks plausible
/// doing it.
void main() {
  const here = GeoPoint(52.4084, 16.9342);

  GeoPoint offset({double north = 0, double east = 0}) => GeoPoint(
    here.latitude + north / metresPerDegreeLat,
    here.longitude + east / metresPerDegreeLon(here.latitude),
  );

  test('north is zero', () {
    expect(here.bearingTo(offset(north: 100)), closeTo(0, 0.1));
  });

  test('east is ninety', () {
    expect(here.bearingTo(offset(east: 100)), closeTo(90, 0.1));
  });

  test('south is a hundred and eighty', () {
    expect(here.bearingTo(offset(north: -100)), closeTo(180, 0.1));
  });

  test('west is two hundred and seventy, not minus ninety', () {
    // Compass bearings do not go negative, and a painter handed -90 draws a
    // cone pointing somewhere nobody is.
    expect(here.bearingTo(offset(east: -100)), closeTo(270, 0.1));
  });

  test('north-east is forty-five', () {
    expect(
      here.bearingTo(offset(north: 100, east: 100)),
      closeTo(45, 0.5),
    );
  });

  test('a point on top of itself has no bearing worth arguing about', () {
    expect(here.bearingTo(here), 0);
  });
}
