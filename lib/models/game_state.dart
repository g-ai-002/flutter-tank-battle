import 'game_enums.dart';
import 'tank.dart';
import 'bullet.dart';
import 'power_up.dart';
import 'game_map.dart';

class GameState {
  GameStatus status;
  int score;
  int level;
  int lives;
  int enemiesRemaining;
  int enemiesKilled;
  final List<Tank> tanks;
  final List<Bullet> bullets;
  final List<PowerUp> powerUps;
  GameMap map;
  double elapsedTime;
  double enemySpawnTimer;

  GameState({
    this.status = GameStatus.idle,
    this.score = 0,
    this.level = 1,
    this.lives = 3,
    this.enemiesRemaining = 10,
    this.enemiesKilled = 0,
    List<Tank>? tanks,
    List<Bullet>? bullets,
    List<PowerUp>? powerUps,
    GameMap? map,
    this.elapsedTime = 0.0,
    this.enemySpawnTimer = 0.0,
  })  : tanks = tanks ?? [],
        bullets = bullets ?? [],
        powerUps = powerUps ?? [],
        map = map ?? GameMap.createLevel(1);

  Tank? get playerTank {
    for (final t in tanks) {
      if (t.type == TankType.player) return t;
    }
    return null;
  }

  List<Tank> get enemyTanks {
    return tanks.where((t) => t.type == TankType.enemy).toList();
  }
}
