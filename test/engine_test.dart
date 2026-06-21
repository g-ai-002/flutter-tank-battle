import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/models/game_enums.dart';
import 'package:flutter_tank_battle/models/tank.dart';
import 'package:flutter_tank_battle/models/game_map.dart';
import 'package:flutter_tank_battle/models/game_state.dart';
import 'package:flutter_tank_battle/engine/enemy_ai.dart';
import 'package:flutter_tank_battle/engine/game_engine.dart';
import 'package:flutter_tank_battle/utils/constants.dart';

void main() {
  group('EnemyAI', () {
    test('创建 EnemyAI', () {
      final ai = EnemyAI();
      expect(ai, isNotNull);
    });

    test('shouldShoot 返回布尔值', () {
      final ai = EnemyAI();
      final result = ai.shouldShoot();
      expect(result, isA<bool>());
    });

    test('update 不抛出异常', () {
      final ai = EnemyAI();
      final enemy = Tank(x: 100, y: 100, type: TankType.enemy);
      final player = Tank(x: 200, y: 200, type: TankType.player);
      final map = GameMap.createLevel(1);

      expect(() => ai.update(enemy, player, map, 0.016), returnsNormally);
    });

    test('update 无玩家时不抛出异常', () {
      final ai = EnemyAI();
      final enemy = Tank(x: 100, y: 100, type: TankType.enemy);
      final map = GameMap.createLevel(1);

      expect(() => ai.update(enemy, null, map, 0.016), returnsNormally);
    });

    test('AI 坦克移动后位置变化', () {
      final ai = EnemyAI();
      final map = GameMap(cols: 10, rows: 10);
      final enemy = Tank(x: 48, y: 48, type: TankType.enemy, speed: 100);
      final player = Tank(x: 96, y: 96, type: TankType.player);

      final oldX = enemy.x;
      final oldY = enemy.y;
      ai.update(enemy, player, map, 1.0);

      expect(enemy.x != oldX || enemy.y != oldY, true);
    });
  });

  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine(GameState(lives: AppConstants.initialLives));
    });

    test('initLevel 初始化关卡', () {
      engine.initLevel(1);
      final s = engine.state;

      expect(s.level, 1);
      expect(s.enemiesRemaining, AppConstants.enemiesPerLevel);
      expect(s.enemiesKilled, 0);
      expect(s.bullets, isEmpty);
      expect(s.powerUps, isEmpty);
      expect(s.playerTank, isNotNull);
      expect(s.enemyTanks.length, greaterThanOrEqualTo(1));
    });

    test('initLevel 不同关卡', () {
      engine.initLevel(3);
      expect(engine.state.level, 3);
    });

    test('update 在非 playing 状态不执行', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.paused;
      final bulletsBefore = engine.state.bullets.length;
      engine.update(0.016);
      expect(engine.state.bullets.length, bulletsBefore);
    });

    test('movePlayer 在非 playing 状态不执行', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.paused;
      final player = engine.state.playerTank!;
      final oldY = player.y;
      engine.movePlayer(Direction.up);
      expect(player.y, oldY);
    });

    test('movePlayer 移动玩家坦克', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;
      final player = engine.state.playerTank!;
      // 移到空地
      player.x = 6 * AppConstants.tileSize;
      player.y = 6 * AppConstants.tileSize;
      final oldY = player.y;
      engine.movePlayer(Direction.up);
      expect(player.y, lessThan(oldY));
    });

    test('playerShoot 发射子弹', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;
      final bulletsBefore = engine.state.bullets.length;
      engine.playerShoot();
      expect(engine.state.bullets.length, greaterThan(bulletsBefore));
    });

    test('playerShoot 冷却时间内不发射', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;
      engine.playerShoot();
      final bulletsAfterFirst = engine.state.bullets.length;
      engine.playerShoot();
      expect(engine.state.bullets.length, bulletsAfterFirst);
    });

    test('update 推进游戏逻辑', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;
      final timeBefore = engine.state.elapsedTime;
      engine.update(0.016);
      expect(engine.state.elapsedTime, greaterThan(timeBefore));
    });

    test('子弹击中砖墙后消失', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;

      // 在砖墙位置发射子弹
      final player = engine.state.playerTank!;
      player.x = 2 * AppConstants.tileSize;
      player.y = 3 * AppConstants.tileSize;
      player.direction = Direction.down;

      engine.playerShoot();
      final bulletsBefore = engine.state.bullets.length;

      // 推进足够时间让子弹碰到砖墙
      for (int i = 0; i < 60; i++) {
        engine.update(0.016);
      }

      expect(engine.state.bullets.length, lessThan(bulletsBefore));
    });

    test('游戏结束条件', () {
      engine.initLevel(1);
      engine.state.status = GameStatus.playing;
      engine.state.enemiesRemaining = 0;
      engine.state.tanks.removeWhere((t) => t.type == TankType.enemy);
      engine.update(0.016);
      expect(engine.state.status, GameStatus.levelComplete);
    });

    test('通关条件', () {
      engine.initLevel(AppConstants.maxLevels);
      engine.state.status = GameStatus.playing;
      engine.state.enemiesRemaining = 0;
      engine.state.tanks.removeWhere((t) => t.type == TankType.enemy);
      engine.update(0.016);
      expect(engine.state.status, GameStatus.victory);
    });
  });
}
