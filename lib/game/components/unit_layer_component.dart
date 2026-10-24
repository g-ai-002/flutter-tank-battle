import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/game_enums.dart';
import '../../models/tank.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';

/// 单位层：道具、子弹与坦克。
class UnitLayerComponent extends PositionComponent {
  UnitLayerComponent({
    required this.provider,
    int? priority,
  }) : super(
          priority: priority,
          size: Vector2(
            AppConstants.mapCols * AppConstants.tileSize,
            AppConstants.mapRows * AppConstants.tileSize,
          ),
        );

  final GameProvider provider;

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Map<PowerUpType, TextPainter> _labels = {};

  double get _tile => AppConstants.tileSize;

  @override
  void render(Canvas canvas) {
    _drawPowerUps(canvas);
    _drawBullets(canvas);
    _drawTanks(canvas);
  }

  void _drawPowerUps(Canvas canvas) {
    for (final powerUp in provider.state.powerUps) {
      if (!powerUp.active) {
        continue;
      }
      final color = switch (powerUp.type) {
        PowerUpType.shield => const Color(0xFF00BCD4),
        PowerUpType.speed => const Color(0xFF8BC34A),
        PowerUpType.firepower => const Color(0xFFFF5722),
      };
      final label = switch (powerUp.type) {
        PowerUpType.shield => 'S',
        PowerUpType.speed => '>',
        PowerUpType.firepower => 'F',
      };

      _fill.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(powerUp.x, powerUp.y, 20, 20),
          const Radius.circular(4),
        ),
        _fill,
      );

      final painter = _labels.putIfAbsent(
        powerUp.type,
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      painter.paint(
        canvas,
        Offset(
          powerUp.x + 10 - painter.width / 2,
          powerUp.y + 10 - painter.height / 2,
        ),
      );
    }
  }

  void _drawBullets(Canvas canvas) {
    for (final bullet in provider.state.bullets) {
      if (!bullet.active) {
        continue;
      }
      _fill.color = bullet.fromPlayer
          ? const Color(0xFFFFEB3B)
          : const Color(0xFFFF9800);
      canvas.drawCircle(Offset(bullet.x + 2, bullet.y + 2), 3, _fill);
    }
  }

  void _drawTanks(Canvas canvas) {
    for (final tank in provider.state.tanks) {
      _drawTank(canvas, tank);
    }
  }

  void _drawTank(Canvas canvas, Tank tank) {
    final isPlayer = tank.type == TankType.player;
    final bodyColor =
        isPlayer ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final trackColor =
        isPlayer ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);

    canvas.save();
    canvas.translate(tank.x + _tile / 2, tank.y + _tile / 2);

    final angle = switch (tank.direction) {
      Direction.up => 0.0,
      Direction.right => 1.5708,
      Direction.down => 3.14159,
      Direction.left => -1.5708,
    };
    canvas.rotate(angle);

    final half = _tile / 2;

    _fill.color = trackColor;
    canvas.drawRect(Rect.fromLTWH(-half, -half, 5, _tile), _fill);
    canvas.drawRect(Rect.fromLTWH(half - 5, -half, 5, _tile), _fill);

    _fill.color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-half + 5, -half + 3, _tile - 10, _tile - 6),
        const Radius.circular(3),
      ),
      _fill,
    );

    final barrel = Paint()
      ..color = isPlayer ? const Color(0xFF81C784) : const Color(0xFFEF9A9A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, -half - 2), barrel);

    if (tank.shielded) {
      _stroke
        ..color = const Color(0x4000BCD4)
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, half + 4, _stroke);
    }

    canvas.restore();
  }
}
