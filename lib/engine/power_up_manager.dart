import 'dart:math';
import '../models/game_enums.dart';
import '../models/tank.dart';
import '../models/power_up.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

class PowerUpManager {
  final Random _random = Random();
  double _spawnTimer = 0;
  double _shieldTimer = 0;
  double _speedTimer = 0;
  double _firepowerTimer = 0;

  void reset() {
    _spawnTimer = 0;
    _shieldTimer = 0;
    _speedTimer = 0;
    _firepowerTimer = 0;
  }

  void update(GameState state, double dt) {
    _updateTimers(state, dt);

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && state.powerUps.length < 2) {
      _spawnTimer = 15.0 + _random.nextDouble() * 15.0;
      _spawnPowerUp(state);
    }
  }

  void _updateTimers(GameState state, double dt) {
    final player = state.playerTank;
    if (player == null) return;

    _shieldTimer -= dt;
    if (_shieldTimer <= 0 && player.shielded) {
      player.shielded = false;
    }

    _speedTimer -= dt;
    if (_speedTimer <= 0 && player.speed > AppConstants.tankSpeed) {
      player.speed = AppConstants.tankSpeed;
    }

    _firepowerTimer -= dt;
    if (_firepowerTimer <= 0 && player.firepower > 1) {
      player.firepower = 1;
    }
  }

  void _spawnPowerUp(GameState state) {
    final types = PowerUpType.values;
    final type = types[_random.nextInt(types.length)];
    final tileSize = AppConstants.tileSize;

    double px = 0, py = 0;
    int attempts = 0;
    bool found = false;
    while (attempts < 20) {
      final col = 2 + _random.nextInt(state.map.cols - 4);
      final row = 2 + _random.nextInt(state.map.rows - 4);
      px = col * tileSize + 2;
      py = row * tileSize + 2;
      if (state.map.tileAt(col, row) == TileType.empty) {
        found = true;
        break;
      }
      attempts++;
    }

    if (found) {
      state.powerUps.add(PowerUp(x: px, y: py, type: type));
    }
  }

  void applyPowerUp(Tank tank, PowerUp pu) {
    switch (pu.type) {
      case PowerUpType.shield:
        tank.shielded = true;
        _shieldTimer = AppConstants.powerUpDuration;
        break;
      case PowerUpType.speed:
        tank.speed = AppConstants.tankSpeed * 1.5;
        _speedTimer = AppConstants.powerUpDuration;
        break;
      case PowerUpType.firepower:
        tank.firepower = 2;
        _firepowerTimer = AppConstants.powerUpDuration;
        break;
    }
  }
}
