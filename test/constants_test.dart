import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/utils/constants.dart';

void main() {
  test('常量定义正确', () {
    expect(AppConstants.appName, '坦克大战');
    expect(AppConstants.version, '0.1.2');
    expect(AppConstants.mapCols, 26);
    expect(AppConstants.mapRows, 26);
    expect(AppConstants.tileSize, 24.0);
    expect(AppConstants.tankSpeed, 120.0);
    expect(AppConstants.bulletSpeed, 300.0);
    expect(AppConstants.initialLives, 3);
    expect(AppConstants.enemiesPerLevel, 10);
    expect(AppConstants.maxLevels, 5);
  });
}
