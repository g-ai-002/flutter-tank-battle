import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '坦克大战',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '经典坦克大战 Flutter 复刻版',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GamePage()),
                    );
                  },
                  child: const Text('开始游戏', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '最高分: ${game.highScore}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              _buildInstructions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作说明', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _instructionRow('方向键 / WASD', '移动坦克'),
            _instructionRow('空格 / 点击射击', '发射子弹'),
            _instructionRow('P 键', '暂停 / 继续'),
            _instructionRow('消灭所有敌人', '过关'),
            _instructionRow('保护基地', '避免被摧毁'),
          ],
        ),
      ),
    );
  }

  Widget _instructionRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
        ],
      ),
    );
  }
}
