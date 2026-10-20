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
    _focusNode.dispose();
    super.dispose();
  }

  static const Map<LogicalKeyboardKey, Direction> _moveKeys = {
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('坦克大战', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
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
            },
          ),
          actions: [
            IconButton(
              icon: Icon(s.status == GameStatus.paused ? Icons.play_arrow : Icons.pause),
              onPressed: () {
                if (s.status == GameStatus.playing) {
                  game.pauseGame();
                } else if (s.status == GameStatus.paused) {
                  game.resumeGame();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            GameHUD(state: s, highScore: game.highScore),
            Expanded(
              child: GestureDetector(
                // 点击画布射击（对应操作说明"点击射击"），并夺回键盘焦点
                onTap: () {
                  _focusNode.requestFocus();
                  game.playerShoot();
                },
                child: Stack(
                  children: [
                    GameRenderer(state: s),
                    if (s.status == GameStatus.paused)
                      GameOverlay(title: '游戏暂停', subtitle: '按 P 键或点击继续', onTap: () => game.resumeGame()),
                    if (s.status == GameStatus.gameOver)
                      GameOverlay(title: '游戏结束', subtitle: '得分: ${s.score}', onTap: () => Navigator.pop(context)),
                    if (s.status == GameStatus.levelComplete)
                      GameOverlay(title: '第 ${s.level} 关通过!', subtitle: '得分: ${s.score}', onTap: () => game.nextLevel()),
                    if (s.status == GameStatus.victory)
                      GameOverlay(title: '恭喜通关!', subtitle: '最终得分: ${s.score}', onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
            if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)
              VirtualJoystick(
                onMoveStart: (dir) => game.startMoving(dir),
                onMoveEnd: (dir) => game.stopMoving(dir),
                onShoot: () => game.playerShoot(),
              ),
          ],
        ),
      ),
    );
  }
}