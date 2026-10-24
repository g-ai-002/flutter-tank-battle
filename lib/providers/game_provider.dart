import 'package:flutter/foundation.dart';
import '../models/game_enums.dart';
import '../models/game_state.dart';
import '../engine/game_engine.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  late GameEngine _engine;
  GameState get state => _engine.state;
  GameEngine get engine => _engine;

  double _accumulator = 0;
  double _notifyAccumulator = 0;
  GameStatus _lastNotifiedStatus = GameStatus.idle;
  int _highScore = 0;
  AudioService? _audio;
  int _prevEnemiesKilled = 0;
  int _prevPowerUpCount = 0;
  bool _endHandled = false;
  final List<Direction> _heldDirections = [];

  GameProvider(this._storage) {
    _engine = GameEngine(GameState());
    _highScore = _storage.highScore;
  }

  int get highScore => _highScore;

  Future<void> _initAudio() async {
    _audio = await AudioService.instance;
  }

  Future<void> startGame() async {
    LogService.info('开始新游戏');
    _heldDirections.clear();
    _accumulator = 0;
    _engine = GameEngine(GameState(lives: AppConstants.initialLives));
    _engine.initLevel(1);
    _engine.state.status = GameStatus.playing;
    _prevEnemiesKilled = 0;
    _prevPowerUpCount = 0;
    _endHandled = false;
    await _initAudio();
    await _audio?.startBgm();
    notifyListeners();
  }

  void nextLevel() {
    final nextLvl = _engine.state.level + 1;
    LogService.info('进入第 $nextLvl 关');
    _heldDirections.clear();
    _accumulator = 0;
    _engine.state.lives = _engine.state.lives;
    _engine.initLevel(nextLvl);
    _engine.state.status = GameStatus.playing;
    _prevEnemiesKilled = 0;
    _prevPowerUpCount = 0;
    _endHandled = false;
    notifyListeners();
  }

  void pauseGame() {
    if (_engine.state.status == GameStatus.playing) {
      _engine.state.status = GameStatus.paused;
      _heldDirections.clear();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_engine.state.status == GameStatus.paused) {
      _engine.state.status = GameStatus.playing;
      _heldDirections.clear();
      _accumulator = 0;
      notifyListeners();
    }
  }

  void startMoving(Direction dir) {
    if (_heldDirections.contains(dir)) return;
    _heldDirections.add(dir);
  }

  void stopMoving(Direction dir) {
    _heldDirections.remove(dir);
  }

  void stopAllMoving() {
    _heldDirections.clear();
  }

  void playerShoot() {
    if (_engine.state.status != GameStatus.playing) return;
    final player = _engine.state.playerTank;
    if (player == null || player.shootTimer > 0) return;
    _engine.playerShoot();
    _audio?.playShoot();
    notifyListeners();
  }

  /// 由 Flame 的游戏循环每帧调用，替代原来的 16ms Timer。
  ///
  /// 使用固定 1/60 秒步长推进物理，保证不同刷新率下手感一致。
  void advance(double dt) {
    final status = _engine.state.status;
    if (status != GameStatus.playing) {
      _heldDirections.clear();
      _checkEndConditions();
      if (status != _lastNotifiedStatus) {
        _lastNotifiedStatus = status;
        notifyListeners();
      }
      return;
    }

    _accumulator += dt;
    const step = 1.0 / AppConstants.gameTickRate;
    var steps = 0;
    while (_accumulator >= step && steps < 4) {
      _accumulator -= step;
      steps++;
      if (_heldDirections.isNotEmpty) {
        _engine.movePlayer(_heldDirections.last, step);
      }
      _engine.update(step);
      _checkAudioEvents();
      _checkEndConditions();
      if (_engine.state.status != GameStatus.playing) {
        break;
      }
    }
    if (steps == 0) {
      return;
    }
    if (steps >= 4) {
      _accumulator = 0;
    }
    if (_engine.state.status != GameStatus.playing) {
      _heldDirections.clear();
    }

    // HUD 只需约 10Hz 的刷新；比赛画面由 Flame 每帧自绘，不受影响。
    _notifyAccumulator += dt;
    final after = _engine.state.status;
    if (after != _lastNotifiedStatus || _notifyAccumulator >= 0.1) {
      _lastNotifiedStatus = after;
      _notifyAccumulator = 0;
      notifyListeners();
    }
  }

  void _checkAudioEvents() {
    final s = _engine.state;

    if (s.enemiesKilled > _prevEnemiesKilled) {
      _audio?.playExplosion();
      _prevEnemiesKilled = s.enemiesKilled;
    }

    final activePowerUps = s.powerUps.where((p) => p.active).length;
    if (activePowerUps < _prevPowerUpCount) {
      _audio?.playPowerUp();
    }
    _prevPowerUpCount = activePowerUps;
  }

  void _checkEndConditions() {
    final s = _engine.state;
    if (s.status == GameStatus.gameOver) {
      if (!_endHandled) {
        _endHandled = true;
        _audio?.stopBgm();
        _audio?.playGameOver();
      }
      if (s.score > _highScore) {
        _highScore = s.score;
        _storage.setHighScore(_highScore);
      }
    }
    if (s.status == GameStatus.levelComplete) {
      if (!_endHandled) {
        _endHandled = true;
        _audio?.playLevelComplete();
      }
    }
    if (s.status == GameStatus.victory) {
      if (!_endHandled) {
        _endHandled = true;
        _audio?.stopBgm();
        _audio?.playLevelComplete();
      }
      if (s.score > _highScore) {
        _highScore = s.score;
        _storage.setHighScore(_highScore);
      }
    }
  }

  @override
  void dispose() {
    _audio?.stopBgm();
    _audio?.dispose();
    super.dispose();
  }
}
