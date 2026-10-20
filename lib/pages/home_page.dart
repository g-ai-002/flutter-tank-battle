import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'game_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highScore = context.select<GameProvider, int>((g) => g.highScore);
    final darkMode = context.select<SettingsProvider, bool>((s) => s.darkMode);
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: darkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: () => settings.setDarkMode(!darkMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_esports,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '坦克大战',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '经典坦克大战 Flutter 复刻版',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePage()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      '开始游戏',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showInstructions(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('操作说明'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '最高分: $highScore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '关卡: ${AppConstants.maxLevels}  |  生命: ${AppConstants.initialLives}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('操作说明'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _instructionRow(theme, '方向键 / WASD', '移动坦克'),
              _instructionRow(theme, '空格 / 点击射击', '发射子弹'),
              _instructionRow(theme, 'P 键', '暂停 / 继续'),
              _instructionRow(theme, '消灭所有敌人', '过关'),
              _instructionRow(theme, '保护基地', '避免被摧毁'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  Widget _instructionRow(ThemeData theme, String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
