import 'package:flutter/material.dart';

/// 暂停浮层。
class TankPauseOverlay extends StatelessWidget {
  const TankPauseOverlay({
    super.key,
    required this.onResume,
    this.hint = '按 P 键或点击继续',
  });

  final VoidCallback onResume;

  /// 平台自适应的继续提示，由调用方按桌面/触屏传入。
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '游戏暂停',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(hint),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onResume, child: const Text('继续游戏')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 结束/过关/通关浮层。
class TankResultOverlay extends StatelessWidget {
  const TankResultOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
