import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/models/game_enums.dart';
import 'package:flutter_tank_battle/models/tank.dart';
import 'package:flutter_tank_battle/models/bullet.dart';
import 'package:flutter_tank_battle/models/game_map.dart';
import 'package:flutter_tank_battle/models/game_state.dart';
import 'package:flutter_tank_battle/engine/collision_detector.dart';
import 'package:flutter_tank_battle/utils/constants.dart';

void main() {
  group('Tank', () {
    test('创建玩家坦克', () {
      final tank = Tank(x: 100, y: 200, type: TankType.player);
      expect(tank.type, TankType.player);
      expect(tank.x, 100);
      expect(tank.y, 200);
      expect(tank.direction, Direction.up);
      expect(tank.lives, 1);
    });

    test('坦克移动', () {
      final tank = Tank(x: 100, y: 200, type: TankType.player, speed: 100);
      tank.move(1.0);
      expect(tank.y, 100);
    });

    test('坦克后退', () {
      final tank = Tank(x: 100, y: 200, type: TankType.player, speed: 100);
      tank.move(1.0);
      tank.moveBack(1.0);
      expect(tank.y, 200);
    });

    test('坦克中心坐标', () {
      final tank = Tank(x: 100, y: 200, type: TankType.player);
      expect(tank.centerX, 112);
      expect(tank.centerY, 212);
    });
  });

  group('Bullet', () {
    test('创建子弹', () {
      final bullet = Bullet(x: 50, y: 60, direction: Direction.up, fromPlayer: true);
      expect(bullet.active, true);
      expect(bullet.fromPlayer, true);
      expect(bullet.direction, Direction.up);
    });

    test('子弹移动', () {
      final bullet = Bullet(x: 50, y: 60, direction: Direction.up, speed: 200, fromPlayer: true);
      bullet.update(1.0);
      expect(bullet.y, 60 - 200);
    });
  });

  group('GameMap', () {
    test('创建关卡地图', () {
      final map = GameMap.createLevel(1);
      expect(map.cols, 26);
      expect(map.rows, 26);
      // 边界是 steel
      expect(map.tileAt(0, 0), TileType.steel);
      expect(map.tileAt(25, 25), TileType.steel);
    });

    test('基地位置', () {
      final map = GameMap.createLevel(1);
      expect(map.tileAt(12, 24), TileType.base);
      expect(map.tileAt(13, 24), TileType.base);
    });

    test('越界返回 steel', () {
      final map = GameMap.createLevel(1);
      expect(map.tileAt(-1, 0), TileType.steel);
      expect(map.tileAt(0, 99), TileType.steel);
    });
  });

  group('CollisionDetector', () {
    test('矩形重叠检测', () {
      expect(CollisionDetector.rectsOverlap(0, 0, 10, 10, 5, 5, 10, 10), true);
      expect(CollisionDetector.rectsOverlap(0, 0, 10, 10, 20, 20, 10, 10), false);
    });

    test('坦克撞砖墙', () {
      final map = GameMap(cols: 10, rows: 10);
      map.setTile(2, 2, TileType.brick);
      final tank = Tank(x: 2 * AppConstants.tileSize, y: 2 * AppConstants.tileSize, type: TankType.player);
      expect(CollisionDetector.tankHitsTile(tank, map), true);
    });

    test('坦克不撞空地', () {
      final map = GameMap(cols: 10, rows: 10);
      final tank = Tank(x: 2 * AppConstants.tileSize, y: 2 * AppConstants.tileSize, type: TankType.player);
      expect(CollisionDetector.tankHitsTile(tank, map), false);
    });

    test('子弹撞砖墙', () {
      final map = GameMap(cols: 10, rows: 10);
      map.setTile(2, 2, TileType.brick);
      final bullet = Bullet(
        x: 2 * AppConstants.tileSize + 2,
        y: 2 * AppConstants.tileSize + 2,
        direction: Direction.up,
        fromPlayer: true,
      );
      expect(CollisionDetector.bulletHitsTile(bullet, map), true);
    });

    test('子弹撞坦克', () {
      final tank = Tank(x: 100, y: 100, type: TankType.enemy);
      final bullet = Bullet(x: 102, y: 102, direction: Direction.up, fromPlayer: true);
      expect(CollisionDetector.bulletHitsTank(bullet, tank), true);
    });

    test('子弹越界检测', () {
      final map = GameMap(cols: 10, rows: 10);
      final bullet = Bullet(x: -10, y: 0, direction: Direction.up, fromPlayer: true);
      expect(CollisionDetector.isOutOfBounds(bullet, map), true);
    });
  });

  group('GameState', () {
    test('初始状态', () {
      final state = GameState();
      expect(state.status, GameStatus.idle);
      expect(state.score, 0);
      expect(state.level, 1);
      expect(state.lives, 3);
    });

    test('获取玩家坦克', () {
      final state = GameState();
      state.tanks.add(Tank(x: 100, y: 100, type: TankType.player));
      state.tanks.add(Tank(x: 200, y: 200, type: TankType.enemy));
      expect(state.playerTank, isNotNull);
      expect(state.enemyTanks.length, 1);
    });
  });
}
