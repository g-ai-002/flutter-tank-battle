import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/overlays/tank_overlays.dart';
import '../game/tank_game.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import '../widgets/game_hud.dart';

/// 桌面端用键盘操控；移动端左下摇杆与右下射击按钮由 Flame 绘制。
/// 游玩页锁定横屏并进入沉浸全屏，菜单页仍跟随系统方向。
bool get _isMobile =>
    !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();
  GameProvider? _game;
  TankGame? _flame;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame();
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameProvider>();
    _game = game;
    _flame ??= TankGame(
      provider: game,
      onCanvasTap: _focusGame,
      isMobile: _isMobile,
      onResume: () {
        game.resumeGame();
        _focusGame();
      },
      onExit: () => Navigator.pop(context),
      onNextLevel: game.nextLevel,
    );
  }

  @override
  void dispose() {
    _game?.stopAllMoving();
    if (_isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _focusGame() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final s = game.state;
    final flame = _flame;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: flame == null
                ? const SizedBox.expand()
                : GameWidget<TankGame>(
                    game: flame,
                    focusNode: _focusNode,
                    overlayBuilderMap: {
                      TankGame.pauseOverlayId: (context, _) => TankPauseOverlay(
                            onResume: () {
                              game.resumeGame();
                              _focusGame();
                            },
                          ),
                      TankGame.gameOverOverlayId: (context, _) =>
                          TankResultOverlay(
                            title: '游戏结束',
                            subtitle: '得分: ${game.state.score}',
                            actionLabel: '返回',
                            onAction: () => Navigator.pop(context),
                          ),
                      TankGame.levelCompleteOverlayId: (context, _) =>
                          TankResultOverlay(
                            title: '第 ${game.state.level} 关通过!',
                            subtitle: '得分: ${game.state.score}',
                            actionLabel: '下一关',
                            onAction: game.nextLevel,
                          ),
                      TankGame.victoryOverlayId: (context, _) => TankResultOverlay(
                            title: '恭喜通关!',
                            subtitle: '最终得分: ${game.state.score}',
                            actionLabel: '返回',
                            onAction: () => Navigator.pop(context),
                          ),
                    },
                  ),
          ),
          GameHUD(
            state: s,
            highScore: game.highScore,
            leading: _circleNavButton(
              Icons.arrow_back,
              () => _confirmExit(game),
            ),
            trailing: _circleNavButton(
              s.status == GameStatus.paused ? Icons.play_arrow : Icons.pause,
              () => _togglePause(game),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(GameProvider game) {
    game.pauseGame();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.resumeGame();
              _focusGame();
            },
            child: const Text('继续游戏'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _togglePause(GameProvider game) {
    final status = game.state.status;
    if (status == GameStatus.playing) {
      game.pauseGame();
    } else if (status == GameStatus.paused) {
      game.resumeGame();
      _focusGame();
    }
  }

  /// 半透明圆形悬浮按钮，风格与摇杆底座一致
  Widget _circleNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}
