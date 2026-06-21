import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tank_battle/services/storage_service.dart';
import 'package:flutter_tank_battle/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('StorageService instanceSync 在初始化后非空', () async {
    final s = await StorageService.instance;
    expect(StorageService.instanceSync, isNotNull);
    expect(identical(StorageService.instanceSync, s), true);
  });

  test('AudioService 单例', () async {
    await StorageService.instance;
    final a1 = await AudioService.instance;
    final a2 = await AudioService.instance;
    expect(identical(a1, a2), true);
  });

  test('AudioService 初始化后 soundEnabled 默认 true', () async {
    final storage = await StorageService.instance;
    expect(storage.soundEnabled, true);
  });
}
