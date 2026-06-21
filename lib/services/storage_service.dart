import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<StorageService>? _initFuture;
  SharedPreferences? _prefs;
  bool _initialized = false;

  StorageService._();

  static Future<StorageService> get instance {
    final cached = _initFuture;
    if (cached != null) return cached;
    final f = _bootstrap();
    _initFuture = f;
    return f;
  }

  static Future<StorageService> _bootstrap() async {
    final s = StorageService._();
    await s._init();
    return s;
  }

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) throw StateError('StorageService 尚未初始化');
    return p;
  }

  static const String _kHighScore = 'high_score';
  static const String _kSoundEnabled = 'sound_enabled';
  static const String _kDarkMode = 'dark_mode';

  int get highScore => _p.getInt(_kHighScore) ?? 0;
  Future<void> setHighScore(int v) => _p.setInt(_kHighScore, v);

  bool get soundEnabled => _p.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool v) => _p.setBool(_kSoundEnabled, v);

  bool get darkMode => _p.getBool(_kDarkMode) ?? false;
  Future<void> setDarkMode(bool v) => _p.setBool(_kDarkMode, v);
}
