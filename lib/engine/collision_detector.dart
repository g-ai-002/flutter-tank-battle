import 'dart:math';
import '../models/game_enums.dart';
import '../models/tank.dart';
import '../models/bullet.dart';
import '../models/game_map.dart';
import '../utils/constants.dart';

class CollisionDetector {
  static bool rectsOverlap(
    double x1, double y1, double w1, double h1,
    double x2, double y2, double w2, double h2,
  ) {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
  }

  static bool tankHitsTile(Tank tank, GameMap map) {
    final tileSize = AppConstants.tileSize;
    final left = tank.x;
    final top = tank.y;
    final right = tank.x + tileSize;
    final bottom = tank.y + tileSize;

    final startCol = (left / tileSize).floor().clamp(0, map.cols - 1);
    final endCol = ((right - 0.01) / tileSize).floor().clamp(0, map.cols - 1);
    final startRow = (top / tileSize).floor().clamp(0, map.rows - 1);
    final endRow = ((bottom - 0.01) / tileSize).floor().clamp(0, map.rows - 1);

    for (int r = startRow; r <= endRow; r++) {
      for (int c = startCol; c <= endCol; c++) {
        final tile = map.tileAt(c, r);
        if (tile == TileType.brick || tile == TileType.steel || tile == TileType.water || tile == TileType.base) {
          return true;
        }
      }
    }
    return false;
  }

  static bool bulletHitsTile(Bullet bullet, GameMap map) {
    final tileSize = AppConstants.tileSize;
    final bx = bullet.x;
    final by = bullet.y;
    final bw = 4.0;
    final bh = 4.0;

    final col = ((bx + bw / 2) / tileSize).floor();
    final row = ((by + bh / 2) / tileSize).floor();

    if (col < 0 || col >= map.cols || row < 0 || row >= map.rows) return true;

    final tile = map.tileAt(col, row);
    return tile == TileType.brick || tile == TileType.steel || tile == TileType.base;
  }

  static bool bulletHitsTank(Bullet bullet, Tank tank) {
    return rectsOverlap(
      bullet.x, bullet.y, 4, 4,
      tank.x, tank.y, AppConstants.tileSize, AppConstants.tileSize,
    );
  }

  static bool tankHitsTank(Tank a, Tank b) {
    return rectsOverlap(
      a.x, a.y, AppConstants.tileSize, AppConstants.tileSize,
      b.x, b.y, AppConstants.tileSize, AppConstants.tileSize,
    );
  }

  static bool tankHitsPowerUp(Tank tank, double px, double py) {
    return rectsOverlap(
      tank.x, tank.y, AppConstants.tileSize, AppConstants.tileSize,
      px, py, 20, 20,
    );
  }

  static bool isOutOfBounds(Bullet bullet, GameMap map) {
    final maxX = map.cols * AppConstants.tileSize;
    final maxY = map.rows * AppConstants.tileSize;
    return bullet.x < 0 || bullet.y < 0 || bullet.x > maxX || bullet.y > maxY;
  }
}
