class AppConstants {
  AppConstants._();

  static const String appName = '坦克大战';
  static const String version = '0.1.2';

  // 游戏地图尺寸（格子数）
  static const int mapCols = 26;
  static const int mapRows = 26;

  // 每个格子的像素大小
  static const double tileSize = 24.0;

  // 坦克移动速度（像素/秒）
  static const double tankSpeed = 120.0;

  // 子弹速度（像素/秒）
  static const double bulletSpeed = 300.0;

  // 射击冷却时间（秒）
  static const double shootCooldown = 0.5;

  // 玩家初始生命数
  static const int initialLives = 3;

  // 每关敌人数量
  static const int enemiesPerLevel = 10;

  // 最大关卡数
  static const int maxLevels = 5;

  // 游戏循环帧率
  static const double gameTickRate = 60.0;

  // 道具持续时间（秒）
  static const double powerUpDuration = 10.0;
}
