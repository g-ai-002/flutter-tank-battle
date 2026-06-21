import 'package:flutter/material.dart';
import '../models/game_enums.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

class GamePainter extends CustomPainter {
  final GameState state;

  GamePainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    _drawMap(canvas);
    _drawPowerUps(canvas);
    _drawBullets(canvas);
    _drawTanks(canvas);
  }

  void _drawMap(Canvas canvas) {
    final tileSize = AppConstants.tileSize;
    for (int r = 0; r < state.map.rows; r++) {
      for (int c = 0; c < state.map.cols; c++) {
        final tile = state.map.tileAt(c, r);
        final rect = Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize);

        switch (tile) {
          case TileType.empty:
            final bgPaint = Paint()..color = const Color(0xFF1A1A1A);
            canvas.drawRect(rect, bgPaint);
          case TileType.brick:
            _drawBrick(canvas, rect, c, r, tileSize);
          case TileType.steel:
            _drawSteel(canvas, rect);
          case TileType.water:
            final waterPaint = Paint()..color = const Color(0xFF1565C0);
            canvas.drawRect(rect, waterPaint);
          case TileType.base:
            _drawBase(canvas, rect, c, r, tileSize);
        }
      }
    }
  }

  void _drawBrick(Canvas canvas, Rect rect, int c, int r, double tileSize) {
    final brickPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRect(rect, brickPaint);
    final linePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(c * tileSize, r * tileSize + tileSize / 2),
      Offset((c + 1) * tileSize, r * tileSize + tileSize / 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(c * tileSize + tileSize / 2, r * tileSize),
      Offset(c * tileSize + tileSize / 2, (r + 1) * tileSize),
      linePaint,
    );
  }

  void _drawSteel(Canvas canvas, Rect rect) {
    final steelPaint = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawRect(rect, steelPaint);
    final borderPaint = Paint()
      ..color = const Color(0xFF616161)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawBase(Canvas canvas, Rect rect, int c, int r, double tileSize) {
    final basePaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawRect(rect, basePaint);
    final eaglePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(
      Offset(c * tileSize + tileSize / 2, r * tileSize + tileSize / 2),
      6,
      eaglePaint,
    );
  }

  void _drawTanks(Canvas canvas) {
    for (final tank in state.tanks) {
      final isPlayer = tank.type == TankType.player;
      final bodyColor = isPlayer ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
      final trackColor = isPlayer ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);

      canvas.save();
      final cx = tank.x + AppConstants.tileSize / 2;
      final cy = tank.y + AppConstants.tileSize / 2;
      canvas.translate(cx, cy);

      double angle;
      switch (tank.direction) {
        case Direction.up:
          angle = 0;
        case Direction.right:
          angle = 1.5708;
        case Direction.down:
          angle = 3.14159;
        case Direction.left:
          angle = -1.5708;
      }
      canvas.rotate(angle);

      final half = AppConstants.tileSize / 2;

      // 履带
      final trackPaint = Paint()..color = trackColor;
      canvas.drawRect(Rect.fromLTWH(-half, -half, 5, AppConstants.tileSize), trackPaint);
      canvas.drawRect(Rect.fromLTWH(half - 5, -half, 5, AppConstants.tileSize), trackPaint);

      // 车身
      final bodyPaint = Paint()..color = bodyColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-half + 5, -half + 3, AppConstants.tileSize - 10, AppConstants.tileSize - 6),
          const Radius.circular(3),
        ),
        bodyPaint,
      );

      // 炮管
      final barrelPaint = Paint()
        ..color = isPlayer ? const Color(0xFF81C784) : const Color(0xFFEF9A9A)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, 0), Offset(0, -half - 2), barrelPaint);

      // 护盾效果
      if (tank.shielded) {
        final shieldPaint = Paint()
          ..color = const Color(0x4000BCD4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset.zero, half + 4, shieldPaint);
      }

      canvas.restore();
    }
  }

  void _drawBullets(Canvas canvas) {
    for (final bullet in state.bullets) {
      if (!bullet.active) continue;
      final paint = Paint()
        ..color = bullet.fromPlayer ? const Color(0xFFFFEB3B) : const Color(0xFFFF9800);
      canvas.drawCircle(Offset(bullet.x + 2, bullet.y + 2), 3, paint);
    }
  }

  void _drawPowerUps(Canvas canvas) {
    for (final pu in state.powerUps) {
      if (!pu.active) continue;
      Color color;
      String label;
      switch (pu.type) {
        case PowerUpType.shield:
          color = const Color(0xFF00BCD4);
          label = 'S';
        case PowerUpType.speed:
          color = const Color(0xFF8BC34A);
          label = '>';
        case PowerUpType.firepower:
          color = const Color(0xFFFF5722);
          label = 'F';
      }

      final bgPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pu.x, pu.y, 20, 20),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(pu.x + 10 - tp.width / 2, pu.y + 10 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
