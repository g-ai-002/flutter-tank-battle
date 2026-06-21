import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';
import 'log_service.dart';

class AudioService {
  static AudioService? _instance;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _initialized = false;
  bool _bgmPlaying = false;

  AudioService._();

  static Future<AudioService> get instance async {
    _instance ??= AudioService._();
    if (!_instance!._initialized) {
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.3);
    _sfxPlayer.setVolume(0.7);
    _initialized = true;
    LogService.info('AudioService 已初始化');
  }

  bool get _soundEnabled {
    try {
      return StorageService.instanceSync?.soundEnabled ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> playShoot() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/shoot.wav'));
    } catch (e) {
      LogService.warning('播放射击音效失败: $e');
    }
  }

  Future<void> playExplosion() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/explosion.wav'));
    } catch (e) {
      LogService.warning('播放爆炸音效失败: $e');
    }
  }

  Future<void> playPowerUp() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/powerup.wav'));
    } catch (e) {
      LogService.warning('播放道具音效失败: $e');
    }
  }

  Future<void> playLevelComplete() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/level_complete.wav'));
    } catch (e) {
      LogService.warning('播放过关音效失败: $e');
    }
  }

  Future<void> playGameOver() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/game_over.wav'));
    } catch (e) {
      LogService.warning('播放失败音效失败: $e');
    }
  }

  Future<void> startBgm() async {
    if (!_soundEnabled || _bgmPlaying) return;
    try {
      await _bgmPlayer.play(AssetSource('audio/bgm.wav'));
      _bgmPlaying = true;
    } catch (e) {
      LogService.warning('播放背景音乐失败: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _bgmPlaying = false;
    } catch (e) {
      LogService.warning('停止背景音乐失败: $e');
    }
  }

  static Future<void> stopBgmGlobal() async {
    if (_instance != null) {
      await _instance!.stopBgm();
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
    _instance = null;
    _initialized = false;
  }
}
