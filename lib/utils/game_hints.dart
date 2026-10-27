import 'platform_info.dart';

/// 各界面展示的玩法提示：桌面端讲键盘，移动端/浏览器讲触屏。
class GameHints {
  GameHints._();

  /// 移动坦克。
  static String get movement => isDesktopPlatform
      ? '方向键 / WASD 移动坦克'
      : '左下角摇杆拖动移动坦克';

  /// 射击。
  static String get shoot => isDesktopPlatform
      ? '空格键或点击战场开火'
      : '点右下角射击按钮开火';

  /// 暂停与继续。
  static String get pause => isDesktopPlatform
      ? 'P 键或顶部按钮暂停，再按一次继续'
      : '点顶部暂停按钮，再点一次继续';

  /// 暂停浮层里的继续方式。
  static String get resume =>
      isDesktopPlatform ? '按 P 键或点击下面按钮继续' : '点击下面按钮继续';

  /// 首页操作说明里的一行汇总。
  static String get summary => isDesktopPlatform
      ? '方向键 / WASD 移动 · 空格射击 · P 暂停'
      : '摇杆移动 · 射击按钮开火 · 顶部按钮暂停';
}
