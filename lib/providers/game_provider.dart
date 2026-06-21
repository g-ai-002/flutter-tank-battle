import 'dart:async';
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

  Timer? _gameLoop;
  int _highScore = 0;
  AudioService? _audio;
  int _prevEnemiesKilled = 0;
  int _prevPowerUpCount = 0;
  bool _endHandled = false;

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
    _engine = GameEngine(GameState(lives: AppConstants.initialLives));
    _engine.initLevel(1);
    _engine.state.status = GameStatus.playing;
    _prevEnemiesKilled = 0;
    _prevPowerUpCount = 0;
    _endHandled = false;
    await _initAudio();
    await _audio?.startBgm();
    _startLoop();
    notifyListeners();
  }

  void nextLevel() {
    final nextLvl = _engine.state.level + 1;
    LogService.info('进入第 $nextLvl 关');
    _engine.state.lives = _engine.state.lives;
    _engine.initLevel(nextLvl);
    _engine.state.status = GameStatus.playing;
    _prevEnemiesKilled = 0;
    _prevPowerUpCount = 0;
    _endHandled = false;
    _startLoop();
    notifyListeners();
  }

  void pauseGame() {
    if (_engine.state.status == GameStatus.playing) {
      _engine.state.status = GameStatus.paused;
      _stopLoop();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_engine.state.status == GameStatus.paused) {
      _engine.state.status = GameStatus.playing;
      _startLoop();
      notifyListeners();
    }
  }

  void movePlayer(Direction dir) {
    _engine.movePlayer(dir);
    notifyListeners();
  }

  void playerShoot() {
    if (_engine.state.status != GameStatus.playing) return;
    final player = _engine.state.playerTank;
    if (player == null || player.shootTimer > 0) return;
    _engine.playerShoot();
    _audio?.playShoot();
    notifyListeners();
  }

  void _startLoop() {
    _stopLoop();
    const tick = Duration(milliseconds: 16);
    _gameLoop = Timer.periodic(tick, (_) {
      if (_engine.state.status != GameStatus.playing) {
        _stopLoop();
        _checkEndConditions();
        notifyListeners();
        return;
      }
      _engine.update(16.0 / 1000.0);
      _checkAudioEvents();
      _checkEndConditions();
      notifyListeners();
    });
  }

  void _stopLoop() {
    _gameLoop?.cancel();
    _gameLoop = null;
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
      _stopLoop();
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
      _stopLoop();
    }
    if (s.status == GameStatus.victory) {
      if (!_endHandled) {
        _endHandled = true;
        _audio?.stopBgm();
        _audio?.playLevelComplete();
      }
      _stopLoop();
      if (s.score > _highScore) {
        _highScore = s.score;
        _storage.setHighScore(_highScore);
      }
    }
  }

  @override
  void dispose() {
    _stopLoop();
    _audio?.stopBgm();
    _audio?.dispose();
    super.dispose();
  }
}
