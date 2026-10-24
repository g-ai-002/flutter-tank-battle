import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/game_enums.dart';
import '../../providers/game_provider.dart';
import '../input/joystick_geometry.dart';

/// 移动端左下动态摇杆（屏幕空间）。
class JoystickInputComponent extends PositionComponent with DragCallbacks {
  JoystickInputComponent({required this.provider, super.priority});

  final GameProvider provider;

  static const double baseRadius = 56;
  static const double knobRadius = 24;

  final Paint _basePaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
  final Paint _baseBorder = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.white.withValues(alpha: 0.3);
  final Paint _knobPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);

  Offset _base = Offset.zero;
  Offset _delta = Offset.zero;
  bool _active = false;
  Direction? _direction;

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    if (game == null || game.size.x <= 0) {
      return;
    }
    final area = joystickAreaFor(Size(game.size.x, game.size.y));
    if (size.x != area.width || size.y != area.height) {
      size = Vector2(area.width, area.height);
      position = Vector2(0, game.size.y - area.height);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _active = true;
    _delta = Offset.zero;
    _base = JoystickGeometry.clampBase(
      Offset(event.localPosition.x, event.localPosition.y),
      Size(size.x, size.y),
      baseRadius,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_active) {
      return;
    }
    _delta += Offset(event.localDelta.x, event.localDelta.y);
    _updateDirection();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _release();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _release();
  }

  void _updateDirection() {
    final next = JoystickGeometry.directionFor(_delta);
    if (next == _direction) {
      return;
    }
    if (_direction != null) {
      provider.stopMoving(_direction!);
    }
    _direction = next;
    if (next != null) {
      provider.startMoving(next);
    }
  }

  void _release() {
    if (_direction != null) {
      provider.stopMoving(_direction!);
      _direction = null;
    }
    _active = false;
    _delta = Offset.zero;
  }

  @override
  void render(Canvas canvas) {
    final idleBase = Offset(baseRadius + 16, size.y - baseRadius - 18);
    final base = _active ? _base : idleBase;
    canvas.drawCircle(base, baseRadius, _basePaint);
    canvas.drawCircle(base, baseRadius, _baseBorder);

    final knob = base + JoystickGeometry.clampKnob(_delta, baseRadius);
    canvas.drawCircle(knob, knobRadius, _knobPaint);
  }
}

/// 右下射击按钮（屏幕空间）。
class ShootButtonComponent extends PositionComponent with TapCallbacks {
  ShootButtonComponent({required this.onShoot, int? priority})
      : super(priority: priority, size: Vector2.all(96));

  final VoidCallback onShoot;

  final Paint _fill = Paint()..color = Colors.white.withValues(alpha: 0.12);
  final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.white.withValues(alpha: 0.35);

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    if (game != null && game.size.x > 0) {
      position = Vector2(game.size.x - 16 - 96, game.size.y - 16 - 96);
    }
  }

  @override
  void onTapDown(TapDownEvent event) => onShoot();

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, _fill);
    canvas.drawCircle(center, size.x / 2, _border);
    final painter = TextPainter(
      text: const TextSpan(
        text: '射击',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}

/// 摇杆活动区尺寸换算（供组件与测试共用）。
Size joystickAreaFor(Size screen) =>
    Size(screen.width * 0.5, screen.height * 0.55);
