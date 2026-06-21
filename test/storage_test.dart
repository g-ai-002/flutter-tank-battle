import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/services/storage_service.dart';

void main() {
  test('StorageService 单例', () async {
    final s1 = await StorageService.instance;
    final s2 = await StorageService.instance;
    expect(identical(s1, s2), true);
  });
}
