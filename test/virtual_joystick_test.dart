import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/game/input/joystick_geometry.dart';
import 'package:flutter_tank_battle/models/game_enums.dart';

void main() {
  group('JoystickGeometry.directionFor', () {
    test('死区内不产生方向', () {
      expect(JoystickGeometry.directionFor(Offset.zero), isNull);
      expect(JoystickGeometry.directionFor(const Offset(10, 10)), isNull);
    });

    test('按主分量判定四个方向', () {
      expect(
        JoystickGeometry.directionFor(const Offset(40, 10)),
        Direction.right,
      );
      expect(
        JoystickGeometry.directionFor(const Offset(-40, 10)),
        Direction.left,
      );
      expect(
        JoystickGeometry.directionFor(const Offset(5, 40)),
        Direction.down,
      );
      expect(
        JoystickGeometry.directionFor(const Offset(5, -40)),
        Direction.up,
      );
    });

    test('自定义死区阈值生效', () {
      expect(
        JoystickGeometry.directionFor(const Offset(25, 0), threshold: 30),
        isNull,
      );
      expect(
        JoystickGeometry.directionFor(const Offset(35, 0), threshold: 30),
        Direction.right,
      );
    });
  });

  group('JoystickGeometry 钳制', () {
    test('底座中心不越出触控区', () {
      const area = Size(200, 300);
      expect(
        JoystickGeometry.clampBase(const Offset(5, 5), area, 56),
        const Offset(56, 56),
      );
      expect(
        JoystickGeometry.clampBase(const Offset(195, 295), area, 56),
        const Offset(144, 244),
      );
    });

    test('把手位移限制在半径内', () {
      final clamped = JoystickGeometry.clampKnob(const Offset(100, 0), 50);
      expect(clamped.dx, closeTo(50, 1e-9));
      expect(clamped.dy, closeTo(0, 1e-9));
    });
  });
}
