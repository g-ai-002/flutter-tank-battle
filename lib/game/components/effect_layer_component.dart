import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// 爆炸/炮口闪光层。
class EffectLayerComponent extends PositionComponent {
  EffectLayerComponent({int? priority})
      : super(
          priority: priority,
          size: Vector2(
            AppConstants.mapCols * AppConstants.tileSize,
            AppConstants.mapRows * AppConstants.tileSize,
          ),
        );

  final List<_Spark> _sparks = [];
  final List<_Smoke> _smoke = [];
  final math.Random _random = math.Random();
  final Paint _paint = Paint();

  void muzzle(Offset at) {
    for (var i = 0; i < 3; i++) {
      _sparks.add(
        _Spark(
          position: Vector2(at.dx, at.dy),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 90,
            (_random.nextDouble() - 0.5) * 90,
          ),
          color: const Color(0xFFFFF176),
          life: 0.14 + _random.nextDouble() * 0.1,
          radius: 2,
        ),
      );
    }
  }

  void explode(Offset at, {bool large = false}) {
    final count = large ? 26 : 16;
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = (large ? 130 : 90) * (0.4 + _random.nextDouble());
      _sparks.add(
        _Spark(
          position: Vector2(at.dx, at.dy),
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          color: _random.nextBool()
              ? const Color(0xFFFF7043)
              : const Color(0xFFFFD54F),
          life: 0.26 + _random.nextDouble() * 0.24,
          radius: large ? 3.4 : 2.6,
        ),
      );
    }
    _smoke.add(
      _Smoke(
        position: Vector2(at.dx, at.dy),
        life: large ? 0.7 : 0.5,
        radius: large ? 22 : 15,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final spark in _sparks) {
      spark.life -= dt;
      spark.position += spark.velocity * dt;
      spark.velocity *= math.pow(0.08, dt).toDouble();
    }
    _sparks.removeWhere((spark) => spark.life <= 0);

    for (final smoke in _smoke) {
      smoke.life -= dt;
    }
    _smoke.removeWhere((smoke) => smoke.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final smoke in _smoke) {
      final t = (smoke.life / smoke.maxLife).clamp(0.0, 1.0).toDouble();
      _paint.color = Colors.grey.withValues(alpha: 0.32 * t);
      canvas.drawCircle(
        Offset(smoke.position.x, smoke.position.y),
        smoke.radius * (1.3 - 0.5 * t),
        _paint,
      );
    }
    for (final spark in _sparks) {
      final t = (spark.life / spark.maxLife).clamp(0.0, 1.0).toDouble();
      _paint.color = spark.color.withValues(alpha: t);
      canvas.drawCircle(
        Offset(spark.position.x, spark.position.y),
        spark.radius * (0.6 + 0.6 * t),
        _paint,
      );
    }
  }
}

class _Spark {
  _Spark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.radius,
  }) : maxLife = life;

  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double maxLife;
  final double radius;
  double life;
}

class _Smoke {
  _Smoke({required this.position, required this.life, required this.radius})
      : maxLife = life;

  final Vector2 position;
  final double maxLife;
  final double radius;
  double life;
}
