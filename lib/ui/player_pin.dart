/// The player, drawn over the middle of the map (§3.6).
///
/// A green dot with a cone showing which way they are moving. Painted as a
/// Flutter overlay rather than as a map symbol for three reasons: symbols need
/// image assets, the map style deliberately ships no sprite sheet (§3.1), and
/// the camera follows the player anyway — so the dot belongs where the screen
/// centre is and never needs to be projected.
///
/// The cone is the honest part. It is drawn only when there is a direction to
/// draw: standing still has no heading, and a cone left pointing at the last
/// direction of travel is a lie a player will act on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_markers.dart';

class PlayerPin extends StatelessWidget {
  const PlayerPin({
    required this.headingDeg,
    this.accuracyRadius = 0,
    this.size = 96,
    super.key,
  });

  /// Course over ground, 0 = north, clockwise. Null while stationary or before
  /// the first movement — the cone is then not drawn at all.
  final double? headingDeg;

  /// Radius of the accuracy circle in logical pixels, or zero to omit it. The
  /// map knows the metres; converting them to pixels is the caller's job,
  /// because only it knows the zoom.
  final double accuracyRadius;

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PlayerPainter(
            headingDeg: headingDeg,
            accuracyRadius: accuracyRadius,
          ),
        ),
      ),
    );
  }
}

class _PlayerPainter extends CustomPainter {
  const _PlayerPainter({
    required this.headingDeg,
    required this.accuracyRadius,
  });

  final double? headingDeg;
  final double accuracyRadius;

  /// How wide the cone opens. Sixty degrees is wide enough to read at a glance
  /// and narrow enough not to claim more precision than a phone compass has.
  static const double coneSpreadDeg = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    const player = Color(kPlayerColour);

    if (accuracyRadius > 0) {
      canvas.drawCircle(
        centre,
        accuracyRadius,
        Paint()..color = player.withValues(alpha: 0.12),
      );
    }

    final heading = headingDeg;
    if (heading != null) {
      final reach = size.width / 2;
      // Screen coordinates put zero degrees to the east and y downwards, so a
      // compass bearing is rotated a quarter turn anticlockwise.
      final start = _radians(heading - coneSpreadDeg / 2 - 90);

      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..arcTo(
            Rect.fromCircle(center: centre, radius: reach),
            start,
            _radians(coneSpreadDeg),
            false,
          )
          ..close(),
        Paint()
          ..shader = RadialGradient(
            colors: [
              player.withValues(alpha: 0.55),
              player.withValues(alpha: 0.05),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: reach)),
      );

      // ⚠️ Grot na końcu klina. Sam gradient gaśnie dokładnie tam, gdzie ma
      // powiedzieć „w tę stronę" — zgłoszone z terenu jako „widać, ale słabo".
      // Trójkąt czyta się jednym spojrzeniem, także w słońcu.
      final tip = Offset(
        centre.dx + reach * 0.82 * math.cos(_radians(heading - 90)),
        centre.dy + reach * 0.82 * math.sin(_radians(heading - 90)),
      );
      final left = Offset(
        centre.dx + reach * 0.42 * math.cos(_radians(heading - 90 - 28)),
        centre.dy + reach * 0.42 * math.sin(_radians(heading - 90 - 28)),
      );
      final right = Offset(
        centre.dx + reach * 0.42 * math.cos(_radians(heading - 90 + 28)),
        centre.dy + reach * 0.42 * math.sin(_radians(heading - 90 + 28)),
      );

      canvas
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close(),
          Paint()..color = player.withValues(alpha: 0.95),
        )
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close(),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFF0B0F12).withValues(alpha: 0.6),
        );
    }

    // The dot last, so it sits over the cone rather than under it.
    canvas
      ..drawCircle(
        centre,
        9,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawCircle(centre, 7, Paint()..color = player);
  }

  @override
  bool shouldRepaint(_PlayerPainter old) =>
      old.headingDeg != headingDeg || old.accuracyRadius != accuracyRadius;
}

double _radians(double degrees) => degrees * math.pi / 180;
