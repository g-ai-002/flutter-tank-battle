import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// 悬浮于画布两侧上方的信息栏。
///
/// 横屏下方形地图按高度适配、左右必然留黑，把导航按钮与
/// 关卡/分数等信息竖排到两侧上方，即可落在留黑区内，
/// 画布纵向空间全部留给地图。
/// 左列：返回按钮 + 关卡/分数/最高分；右列：暂停按钮 + 生命/剩余敌人。
class GameHUD extends StatelessWidget {
  final GameState state;
  final int highScore;
  final Widget leading;
  final Widget trailing;

  const GameHUD({
    super.key,
    required this.state,
    required this.highScore,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // 独立重绘层：HUD 约 10Hz 刷新时不会连带重绘下方的战场画布
      child: RepaintBoundary(
        // 沉浸模式下上下无系统栏，bottom 不留白；左右留白防横屏开孔屏挡住按钮
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading,
                    const SizedBox(height: 10),
                    _text('第 ${state.level} 关', Colors.white),
                    _text('分数: ${state.score}', const Color(0xFFFFC107)),
                    _text(
                      '最高: $highScore',
                      const Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    trailing,
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFE53935),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.lives}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    _text(
                      '剩余: ${state.enemiesRemaining}',
                      const Color(0xFFEF9A9A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(String text, Color color, {double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
