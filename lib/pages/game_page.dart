import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import '../widgets/game_renderer.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_overlay.dart';
import '../widgets/virtual_joystick.dart';

/// 桌面端用键盘操控；移动端显示虚拟摇杆，并锁定横屏沉浸全屏游玩。
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

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      // 游玩页固定横屏并进入沉浸全屏（隐藏系统栏），菜单页仍跟随系统方向
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
    _game = context.read<GameProvider>();
  }

  @override
  void dispose() {
    _game?.stopAllMoving();
    if (_isMobile) {
      // 恢复 main.dart 中的应用级方向偏好与可见的系统栏
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

  static final Map<LogicalKeyboardKey, Direction> _moveKeys = {
    LogicalKeyboardKey.arrowUp: Direction.up,
    LogicalKeyboardKey.keyW: Direction.up,
    LogicalKeyboardKey.arrowDown: Direction.down,
    LogicalKeyboardKey.keyS: Direction.down,
    LogicalKeyboardKey.arrowLeft: Direction.left,
    LogicalKeyboardKey.keyA: Direction.left,
    LogicalKeyboardKey.arrowRight: Direction.right,
    LogicalKeyboardKey.keyD: Direction.right,
  };

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final game = context.read<GameProvider>();
    final dir = _moveKeys[event.logicalKey];

    if (event is KeyUpEvent) {
      if (dir == null) return KeyEventResult.ignored;
      game.stopMoving(dir);
      return KeyEventResult.handled;
    }

    // 按住期间由游戏循环按帧推进，系统按键重复事件直接吞掉
    if (event is KeyRepeatEvent) {
      return dir == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (dir != null) {
      game.startMoving(dir);
      return KeyEventResult.handled;
    }

    final s = game.state;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        game.playerShoot();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyP:
        if (s.status == GameStatus.playing) {
          game.pauseGame();
        } else if (s.status == GameStatus.paused) {
          game.resumeGame();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final s = game.state;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      // 失焦（切窗口、点到按钮）时清空按住的方向，避免坦克自走
      onFocusChange: (hasFocus) {
        if (!hasFocus) game.stopAllMoving();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // 顶部导航栏与信息栏会占用上下方向的画布空间，改为
        // 由 GameHUD 悬挂在两侧上方，画布铺满全屏
        body: Stack(
          children: [
            // 点击画布射击（对应操作说明"点击射击"），并夺回键盘焦点
            GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
                game.playerShoot();
              },
              child: GameRenderer(state: s),
            ),
            // 摇杆与射击按钮悬浮在画布上
            if (_isMobile)
              Align(
                alignment: Alignment.bottomCenter,
                child: VirtualJoystick(
                  onMoveStart: (dir) => game.startMoving(dir),
                  onMoveEnd: (dir) => game.stopMoving(dir),
                  onShoot: () => game.playerShoot(),
                ),
              ),
            if (s.status == GameStatus.paused)
              GameOverlay(title: '游戏暂停', subtitle: '按 P 键或点击继续', onTap: () => game.resumeGame()),
            if (s.status == GameStatus.gameOver)
              GameOverlay(title: '游戏结束', subtitle: '得分: ${s.score}', onTap: () => Navigator.pop(context)),
            if (s.status == GameStatus.levelComplete)
              GameOverlay(title: '第 ${s.level} 关通过!', subtitle: '得分: ${s.score}', onTap: () => game.nextLevel()),
            if (s.status == GameStatus.victory)
              GameOverlay(title: '恭喜通关!', subtitle: '最终得分: ${s.score}', onTap: () => Navigator.pop(context)),
            GameHUD(
              state: s,
              highScore: game.highScore,
              leading: _circleNavButton(Icons.arrow_back, () => _confirmExit(game)),
              trailing: _circleNavButton(
                s.status == GameStatus.paused ? Icons.play_arrow : Icons.pause,
                () => _togglePause(game),
              ),
            ),
          ],
        ),
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