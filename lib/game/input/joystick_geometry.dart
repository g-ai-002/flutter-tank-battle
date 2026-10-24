import 'dart:ui';

import '../../models/game_enums.dart';

/// 摇杆的纯数学部分：死区方向判定与底座钳制，便于单测。
class JoystickGeometry {
  static const double deadZone = 18;

  static Direction? directionFor(Offset delta, {double threshold = 18}) {
    if (delta.distance < threshold) {
      return null;
    }
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? Direction.right : Direction.left;
    }
    return delta.dy > 0 ? Direction.down : Direction.up;
  }

  static Offset clampBase(Offset point, Size area, double radius) {
    return Offset(
      point.dx.clamp(radius, area.width - radius).toDouble(),
      point.dy.clamp(radius, area.height - radius).toDouble(),
    );
  }

  static Offset clampKnob(Offset delta, double maxDistance) {
    if (delta.distance <= maxDistance) {
      return delta;
    }
    final scale = maxDistance / delta.distance;
    return Offset(delta.dx * scale, delta.dy * scale);
  }
}
