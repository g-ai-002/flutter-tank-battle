import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final s = StorageService._();
    s._prefs = await SharedPreferences.getInstance();
    _instance = s;
    return s;
  }

  static StorageService? get instanceSync => _instance;

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
