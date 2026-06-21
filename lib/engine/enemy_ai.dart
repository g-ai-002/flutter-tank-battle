import 'dart:math';
import '../models/game_enums.dart';
import '../models/tank.dart';
import '../models/game_map.dart';
import '../utils/constants.dart';
import 'collision_detector.dart';

class EnemyAI {
  final Random _random = Random();
  double _dirChangeTimer = 0;
  double _shootTimer = 0;

  void update(Tank enemy, Tank? player, GameMap map, double dt) {
    if (player == null) return;

    _dirChangeTimer -= dt;
    _shootTimer -= dt;

    // 随机改变方向
    if (_dirChangeTimer <= 0) {
      _dirChangeTimer = 0.5 + _random.nextDouble() * 1.5;
      final dx = player.centerX - enemy.centerX;
      final dy = player.centerY - enemy.centerY;

      if (_random.nextDouble() < 0.4) {
        // 朝向玩家
        if (dx.abs() > dy.abs()) {
          enemy.direction = dx > 0 ? Direction.right : Direction.left;
        } else {
          enemy.direction = dy > 0 ? Direction.down : Direction.up;
        }
      } else {
        // 随机方向
        enemy.direction = Direction.values[_random.nextInt(4)];
      }
    }

    // 移动
    enemy.move(dt);
    if (CollisionDetector.tankHitsTile(enemy, map)) {
      enemy.moveBack(dt);
      enemy.direction = Direction.values[_random.nextInt(4)];
    }

    // 边界检查
    final maxX = (map.cols - 1) * AppConstants.tileSize;
    final maxY = (map.rows - 1) * AppConstants.tileSize;
    enemy.x = enemy.x.clamp(AppConstants.tileSize, maxX - AppConstants.tileSize);
    enemy.y = enemy.y.clamp(AppConstants.tileSize, maxY - AppConstants.tileSize);

    // 射击
    if (_shootTimer <= 0) {
      _shootTimer = 0.8 + _random.nextDouble() * 1.2;
    }
  }

  bool shouldShoot() {
    if (_shootTimer <= 0) {
      _shootTimer = 0.8 + _random.nextDouble() * 1.2;
      return true;
    }
    return false;
  }
}
