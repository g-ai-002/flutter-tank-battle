import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换深色/浅色主题'),
            value: settings.darkMode,
            onChanged: (v) => settings.setDarkMode(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('音效'),
            subtitle: const Text('开启/关闭游戏音效'),
            value: settings.soundEnabled,
            onChanged: (v) => settings.setSoundEnabled(v),
          ),
          const Divider(height: 1),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '版本 ${AppConstants.version}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
