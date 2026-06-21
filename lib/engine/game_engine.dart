import 'dart:math';
import '../models/game_enums.dart';
import '../models/tank.dart';
import '../models/bullet.dart';
import '../models/game_map.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import 'collision_detector.dart';
import 'enemy_ai.dart';
import 'power_up_manager.dart';

class GameEngine {
  final GameState state;
  final Map<Tank, EnemyAI> _enemyAIs = {};
  final Random _random = Random();
  final PowerUpManager _powerUpManager = PowerUpManager();

  GameEngine(this.state);

  void initLevel(int level) {
    state.map = GameMap.createLevel(level);
    state.level = level;
    state.enemiesRemaining = AppConstants.enemiesPerLevel;
    state.enemiesKilled = 0;
    state.bullets.clear();
    state.powerUps.clear();
    state.enemySpawnTimer = 0.0;
    state.elapsedTime = 0;
    _enemyAIs.clear();
    _powerUpManager.reset();

    final player = Tank(
      x: 12 * AppConstants.tileSize,
      y: 24 * AppConstants.tileSize,
      direction: Direction.up,
      type: TankType.player,
      lives: state.lives,
      speed: AppConstants.tankSpeed,
    );
    state.tanks.clear();
    state.tanks.add(player);

    _spawnEnemy();
    _spawnEnemy();
  }

  void update(double dt) {
    if (state.status != GameStatus.playing) return;

    state.elapsedTime += dt;
    _powerUpManager.update(state, dt);

    state.enemySpawnTimer -= dt;
    if (state.enemySpawnTimer <= 0 && state.enemiesRemaining > 0) {
      final activeEnemies = state.enemyTanks.length;
      if (activeEnemies < 3) {
        _spawnEnemy();
        state.enemySpawnTimer = 3.0;
      }
    }

    for (final tank in state.tanks) {
      tank.shootTimer = (tank.shootTimer - dt).clamp(0.0, 999.0).toDouble();
    }

    final player = state.playerTank;
    for (final tank in state.tanks) {
      if (tank.type != TankType.enemy) continue;
      final ai = _enemyAIs[tank];
      if (ai == null) continue;
      ai.update(tank, player, state.map, dt);
      if (ai.shouldShoot() && tank.shootTimer <= 0) {
        _shoot(tank);
      }
    }

    for (final bullet in state.bullets) {
      bullet.update(dt);
    }

    _checkCollisions();

    state.bullets.removeWhere((b) => CollisionDetector.isOutOfBounds(b, state.map) || !b.active);

    _checkGameEnd();
  }

  void movePlayer(Direction dir) {
    if (state.status != GameStatus.playing) return;
    final player = state.playerTank;
    if (player == null) return;

    player.direction = dir;
    player.move(1.0 / AppConstants.gameTickRate);

    if (CollisionDetector.tankHitsTile(player, state.map)) {
      player.moveBack(1.0 / AppConstants.gameTickRate);
    }

    for (final other in state.tanks) {
      if (other != player && CollisionDetector.tankHitsTank(player, other)) {
        player.moveBack(1.0 / AppConstants.gameTickRate);
        break;
      }
    }

    final maxX = (state.map.cols - 1) * AppConstants.tileSize;
    final maxY = (state.map.rows - 1) * AppConstants.tileSize;
    player.x = player.x.clamp(AppConstants.tileSize, maxX - AppConstants.tileSize);
    player.y = player.y.clamp(AppConstants.tileSize, maxY - AppConstants.tileSize);

    for (final pu in state.powerUps) {
      if (pu.active && CollisionDetector.tankHitsPowerUp(player, pu.x, pu.y)) {
        _powerUpManager.applyPowerUp(player, pu);
        pu.active = false;
      }
    }
    state.powerUps.removeWhere((p) => !p.active);
  }

  void playerShoot() {
    if (state.status != GameStatus.playing) return;
    final player = state.playerTank;
    if (player == null || player.shootTimer > 0) return;
    _shoot(player);
  }

  void _shoot(Tank tank) {
    tank.shootTimer = AppConstants.shootCooldown;
    final cx = tank.centerX - 2;
    final cy = tank.centerY - 2;

    final bullets = <Bullet>[];
    bullets.add(Bullet(
      x: cx,
      y: cy,
      direction: tank.direction,
      fromPlayer: tank.type == TankType.player,
    ));

    if (tank.firepower >= 2) {
      final offset = 8.0;
      switch (tank.direction) {
        case Direction.up:
        case Direction.down:
          bullets.add(Bullet(x: cx - offset, y: cy, direction: tank.direction, fromPlayer: tank.type == TankType.player));
          bullets.add(Bullet(x: cx + offset, y: cy, direction: tank.direction, fromPlayer: tank.type == TankType.player));
          break;
        case Direction.left:
        case Direction.right:
          bullets.add(Bullet(x: cx, y: cy - offset, direction: tank.direction, fromPlayer: tank.type == TankType.player));
          bullets.add(Bullet(x: cx, y: cy + offset, direction: tank.direction, fromPlayer: tank.type == TankType.player));
          break;
      }
    }

    state.bullets.addAll(bullets);
  }

  void _checkCollisions() {
    final bulletsToRemove = <Bullet>[];
    final tanksToRemove = <Tank>[];
    bool playerDied = false;

    for (final bullet in state.bullets) {
      if (!bullet.active) continue;

      if (CollisionDetector.bulletHitsTile(bullet, state.map)) {
        final tileSize = AppConstants.tileSize;
        final col = ((bullet.x + 2) / tileSize).floor();
        final row = ((bullet.y + 2) / tileSize).floor();
        final tile = state.map.tileAt(col, row);

        if (tile == TileType.brick) {
          state.map.setTile(col, row, TileType.empty);
        } else if (tile == TileType.base) {
          bullet.active = false;
          bulletsToRemove.add(bullet);
          state.status = GameStatus.gameOver;
          return;
        }
        bullet.active = false;
        bulletsToRemove.add(bullet);
        continue;
      }

      for (final tank in state.tanks) {
        if (!CollisionDetector.bulletHitsTank(bullet, tank)) continue;

        final bulletFromPlayer = bullet.fromPlayer;
        final tankIsPlayer = tank.type == TankType.player;

        if (bulletFromPlayer == tankIsPlayer) continue;

        if (tank.shielded) {
          tank.shielded = false;
          bullet.active = false;
          bulletsToRemove.add(bullet);
          break;
        }

        tank.lives--;
        bullet.active = false;
        bulletsToRemove.add(bullet);

        if (tank.lives <= 0) {
          tanksToRemove.add(tank);
          if (tankIsPlayer) {
            playerDied = true;
          } else {
            state.enemiesKilled++;
            state.enemiesRemaining--;
            state.score += 100;
          }
        }
        break;
      }
    }

    state.bullets.removeWhere((b) => bulletsToRemove.contains(b));
    for (final t in tanksToRemove) {
      _enemyAIs.remove(t);
      state.tanks.remove(t);
    }

    if (playerDied) {
      state.lives--;
      if (state.lives <= 0) {
        state.status = GameStatus.gameOver;
      } else {
        _respawnPlayer();
      }
    }
  }

  void _respawnPlayer() {
    final existing = state.playerTank;
    if (existing != null) {
      state.tanks.remove(existing);
    }
    final player = Tank(
      x: 12 * AppConstants.tileSize,
      y: 24 * AppConstants.tileSize,
      direction: Direction.up,
      type: TankType.player,
      lives: 1,
      speed: AppConstants.tankSpeed,
    );
    state.tanks.insert(0, player);
  }

  void _spawnEnemy() {
    final spawnPoints = [
      (1 * AppConstants.tileSize, 0.0),
      (12 * AppConstants.tileSize, 0.0),
      (23 * AppConstants.tileSize, 0.0),
    ];

    final (sx, sy) = spawnPoints[_random.nextInt(spawnPoints.length)];

    final enemy = Tank(
      x: sx,
      y: sy + AppConstants.tileSize,
      direction: Direction.down,
      type: TankType.enemy,
      speed: AppConstants.tankSpeed * (0.6 + _random.nextDouble() * 0.4),
    );

    for (final t in state.tanks) {
      if (CollisionDetector.tankHitsTank(enemy, t)) return;
    }

    state.tanks.add(enemy);
    _enemyAIs[enemy] = EnemyAI();
  }

  void _checkGameEnd() {
    if (state.enemiesRemaining <= 0 && state.enemyTanks.isEmpty) {
      if (state.level >= AppConstants.maxLevels) {
        state.status = GameStatus.victory;
      } else {
        state.status = GameStatus.levelComplete;
      }
    }
  }
}
