import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_enums.dart';
import '../models/game_state.dart';
import '../engine/game_engine.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;
  late GameEngine _engine;
  GameState get state => _engine.state;
  GameEngine get engine => _engine;

  Timer? _gameLoop;
  int _highScore = 0;

  GameProvider(this._storage) {
    _engine = GameEngine(GameState());
    _highScore = _storage.highScore;
  }

  int get highScore => _highScore;

  void startGame() {
    LogService.info('开始新游戏');
    _engine = GameEngine(GameState(lives: AppConstants.initialLives));
    _engine.initLevel(1);
    _engine.state.status = GameStatus.playing;
    _startLoop();
    notifyListeners();
  }

  void nextLevel() {
    final nextLvl = _engine.state.level + 1;
    LogService.info('进入第 $nextLvl 关');
    _engine.state.lives = _engine.state.lives;
    _engine.initLevel(nextLvl);
    _engine.state.status = GameStatus.playing;
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
    _engine.playerShoot();
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
      _checkEndConditions();
      notifyListeners();
    });
  }

  void _stopLoop() {
    _gameLoop?.cancel();
    _gameLoop = null;
  }

  void _checkEndConditions() {
    final s = _engine.state;
    if (s.status == GameStatus.gameOver || s.status == GameStatus.victory) {
      _stopLoop();
      if (s.score > _highScore) {
        _highScore = s.score;
        _storage.setHighScore(_highScore);
      }
    }
    if (s.status == GameStatus.levelComplete) {
      _stopLoop();
    }
  }

  @override
  void dispose() {
    _stopLoop();
    super.dispose();
  }
}
